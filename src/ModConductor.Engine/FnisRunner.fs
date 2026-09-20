namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Platform

type FnisRunner
    (
        store: OperationStore,
        ?timeout: TimeSpan,
        ?publicationCheckpoint: FnisRunRequest -> unit
    ) =
    let active = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()
    let timeout = defaultArg timeout (TimeSpan.FromMinutes 5.)
    let publicationCheckpoint = defaultArg publicationCheckpoint ignore
    let logLimit = 256 * 1024

    let inspect (workspace: Guid) (profile: Guid) (token: CancellationToken) =
        task {
            token.ThrowIfCancellationRequested()
            let! deployment = store.Deployments.Read profile

            match deployment with
            | Error _ -> return Error FnisExecutionError.NotFound
            | Ok deployment when deployment.WorkspaceId <> workspace ->
                return Error FnisExecutionError.NotFound
            | Ok deployment ->
                match deployment.ActiveGeneration with
                | None -> return Error FnisExecutionError.NotFound
                | Some generation -> return! store.FnisExecution.Inspect(workspace, profile, generation)
        }

    let failure id phase exitCode stdout stderr runLog detail =
        task {
            do! store.FnisExecution.Fail(id, phase, exitCode, stdout, stderr, runLog, detail)
            return Error(FnisExecutionError.Unavailable detail)
        }

    let logPaths (generator: string) =
        let directory = Path.GetDirectoryName generator

        if String.IsNullOrWhiteSpace directory || not (Directory.Exists directory) then
            []
        else
            let logLike (path: string) =
                let name = Path.GetFileName path
                let extension = Path.GetExtension path

                name.Contains("log", StringComparison.OrdinalIgnoreCase)
                || String.Equals(extension, ".log", StringComparison.OrdinalIgnoreCase)

            let direct =
                try
                    Directory.EnumerateFiles(directory, "*", SearchOption.TopDirectoryOnly)
                    |> Seq.filter logLike
                    |> Seq.toList
                with
                | :? IOException
                | :? UnauthorizedAccessException -> []

            let temporary = Path.Combine(directory, "temporary_logs")

            let nested =
                try
                    if Directory.Exists temporary then
                        Directory.EnumerateFiles(temporary, "*", SearchOption.TopDirectoryOnly)
                        |> Seq.toList
                    else
                        []
                with
                | :? IOException
                | :? UnauthorizedAccessException -> []

            direct @ nested
            |> List.distinct
            |> List.sortWith (fun left right -> StringComparer.OrdinalIgnoreCase.Compare(left, right))
            |> List.truncate 32

    let logSnapshot (generator: string) =
        logPaths generator
        |> List.choose (fun path ->
            try
                let info = FileInfo path
                Some(path, (info.Length, info.LastWriteTimeUtc.Ticks))
            with
            | :? IOException
            | :? UnauthorizedAccessException -> None)
        |> Map.ofList

    let captureLogs (generator: string) (before: Map<string, int64 * int64>) =
        let builder = StringBuilder()
        let mutable remaining = logLimit

        for path in logPaths generator do
            if remaining > 0 then
                try
                    let info = FileInfo path
                    let changed =
                        before
                        |> Map.tryFind path
                        |> Option.forall (fun previous -> previous <> (info.Length, info.LastWriteTimeUtc.Ticks))

                    if changed then
                        let header = "== " + Path.GetFileName path + " ==\n"
                        let headerBytes = Encoding.UTF8.GetBytes header
                        let headerCount = min remaining headerBytes.Length
                        builder.Append(Encoding.UTF8.GetString(headerBytes, 0, headerCount)) |> ignore
                        remaining <- remaining - headerCount

                        if remaining > 0 then
                            use stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite ||| FileShare.Delete)
                            let count = min remaining (int (min (int64 Int32.MaxValue) stream.Length))
                            let bytes = Array.zeroCreate<byte> count
                            let mutable offset = 0

                            while offset < count do
                                let read = stream.Read(bytes, offset, count - offset)
                                if read = 0 then offset <- count else offset <- offset + read

                            builder.Append(Encoding.UTF8.GetString(bytes, 0, offset)).Append('\n') |> ignore
                            remaining <- remaining - offset
                with
                | :? IOException
                | :? UnauthorizedAccessException -> ()

        let bytes = Encoding.UTF8.GetBytes(builder.ToString())
        if bytes.Length <= logLimit then bytes else bytes[.. logLimit - 1]

    let execute (stage: FnisRunStage) (local: CancellationTokenSource) =
        task {
            let mutable stdout = Array.empty<byte>
            let mutable stderr = Array.empty<byte>
            let mutable runLog = Array.empty<byte>

            try
                try
                    let arguments =
                        [ "RedirectFiles=" + stage.Directory
                          "InstantExecute=1" ]

                    let! projected =
                        store.ToolLaunching.Project(
                            stage.Request.WorkspaceId,
                            stage.Request.ProfileId,
                            stage.GenerationId,
                            stage.Generator,
                            arguments
                        )

                    match projected with
                    | Error problem ->
                        let detail =
                            match problem with
                            | ModConductor.Executables.ExecutableError.Unavailable detail
                            | ModConductor.Executables.ExecutableError.Invalid detail -> detail
                            | _ -> "The selected FNIS launch context changed."

                        let! _ =
                            failure
                                stage.Request.Id
                                FnisOutputPhase.Failed
                                None
                                stdout
                                stderr
                                runLog
                                detail

                        ()
                    | Ok projected ->
                        let beforeLogs = logSnapshot stage.Generator

                        let! result =
                            NativeToolLaunch.runIn
                                stage.Directory
                                projected.Launch
                                Array.empty
                                { InputBytes = 1
                                  OutputBytes = 256 * 1024
                                  ErrorBytes = 256 * 1024
                                  Timeout = timeout }
                                local.Token

                        runLog <- captureLogs stage.Generator beforeLogs

                        match result with
                        | Error NativeToolError.Cancelled ->
                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Cancelled
                                    None
                                    stdout
                                    stderr
                                    runLog
                                    "FNIS was cancelled. The previous generated output remains active."

                            ()
                        | Error NativeToolError.TimedOut ->
                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Failed
                                    None
                                    stdout
                                    stderr
                                    runLog
                                    "FNIS timed out. The previous generated output remains active."

                            ()
                        | Error NativeToolError.OutputLimit ->
                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Failed
                                    None
                                    stdout
                                    stderr
                                    runLog
                                    "FNIS standard output exceeded 256 KiB."

                            ()
                        | Error NativeToolError.ErrorLimit ->
                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Failed
                                    None
                                    stdout
                                    stderr
                                    runLog
                                    "FNIS standard error exceeded 256 KiB."

                            ()
                        | Error(NativeToolError.LaunchFailed detail) ->
                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Failed
                                    None
                                    stdout
                                    stderr
                                    runLog
                                    detail

                            ()
                        | Ok result when result.ExitCode <> 0 ->
                            stdout <- result.Output
                            stderr <- result.Error

                            let! _ =
                                failure
                                    stage.Request.Id
                                    FnisOutputPhase.Failed
                                    (Some result.ExitCode)
                                    stdout
                                    stderr
                                    runLog
                                    ("FNIS exited with code " + string result.ExitCode + ".")

                            ()
                        | Ok result ->
                            stdout <- result.Output
                            stderr <- result.Error
                            publicationCheckpoint stage.Request

                            let! published =
                                store.FnisExecution.Publish(
                                    stage,
                                    result.ExitCode,
                                    stdout,
                                    stderr,
                                    runLog,
                                    local.Token
                                )

                            match published with
                            | Ok() -> ()
                            | Error error ->
                                let detail =
                                    match error with
                                    | FnisExecutionError.Stale ->
                                        "FNIS inputs changed before the generated output could be selected. The previous generated output remains active."
                                    | FnisExecutionError.Cancelled ->
                                        "FNIS output publication was cancelled. The previous generated output remains active."
                                    | FnisExecutionError.Invalid detail
                                    | FnisExecutionError.Unavailable detail -> detail
                                    | _ -> "FNIS output could not be selected. The previous generated output remains active."

                                let! _ =
                                    failure
                                        stage.Request.Id
                                        (if error = FnisExecutionError.Cancelled then
                                             FnisOutputPhase.Cancelled
                                         else
                                             FnisOutputPhase.Failed)
                                        (Some result.ExitCode)
                                        stdout
                                        stderr
                                        runLog
                                        detail

                                ()
                with
                | :? OperationCanceledException ->
                    let! _ =
                        failure
                            stage.Request.Id
                            FnisOutputPhase.Cancelled
                            None
                            stdout
                            stderr
                            runLog
                            "FNIS was cancelled. The previous generated output remains active."

                    ()
                | error ->
                    let! _ =
                        failure
                            stage.Request.Id
                            FnisOutputPhase.Failed
                            None
                            stdout
                            stderr
                            runLog
                            (error.Message + " The previous generated output remains active.")

                    ()
            finally
                store.FnisExecution.CleanupStage stage.Request.Id
                let key = stage.Request.WorkspaceId, stage.Request.ProfileId
                let mutable removed = Unchecked.defaultof<CancellationTokenSource>
                active.TryRemove(key, &removed) |> ignore
                local.Dispose()
        }

    interface IFnisInspection with
        member _.Inspect(workspace, profile, token) = inspect workspace profile token

    interface IFnisExecution with
        member _.Run(request, token) =
            task {
                if
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || request.ProfileId = Guid.Empty
                then
                    return Error(FnisExecutionError.Invalid "The FNIS run identity is invalid.")
                else
                    token.ThrowIfCancellationRequested()
                    let! observed = inspect request.WorkspaceId request.ProfileId token

                    match observed with
                    | Error error -> return Error error
                    | Ok observed ->
                        let! generator =
                            store.FnisSetups.ReadStored(
                                request.WorkspaceId,
                                request.ProfileId,
                                Some observed.GenerationId
                            )

                        match generator with
                        | None -> return Error FnisExecutionError.NotFound
                        | Some generator ->
                            let! begun =
                                store.FnisExecution.Begin(request, generator, observed.Fingerprint)

                            match begun with
                            | Error error -> return Error error
                            | Ok(_, false, _) ->
                                return! inspect request.WorkspaceId request.ProfileId token
                            | Ok(stage, true, _) ->
                                let local = new CancellationTokenSource()
                                let key = request.WorkspaceId, request.ProfileId

                                if not (active.TryAdd(key, local)) then
                                    do!
                                        store.FnisExecution.Fail(
                                            request.Id,
                                            FnisOutputPhase.Failed,
                                            None,
                                            Array.empty,
                                            Array.empty,
                                            Array.empty,
                                            "Another FNIS run already owns this profile."
                                        )

                                    store.FnisExecution.CleanupStage request.Id
                                    local.Dispose()
                                    return Error FnisExecutionError.Busy
                                else
                                    Task.Run(fun () -> execute stage local :> Task) |> ignore
                                    return!
                                        inspect
                                            request.WorkspaceId
                                            request.ProfileId
                                            CancellationToken.None
            }

        member _.Cancel(workspace, profile) =
            task {
                match active.TryGetValue((workspace, profile)) with
                | true, cancellation -> cancellation.Cancel()
                | _ -> ()

                let deadline = DateTime.UtcNow.AddSeconds 10.

                while active.ContainsKey((workspace, profile)) && DateTime.UtcNow < deadline do
                    do! Task.Delay 20

                return! inspect workspace profile CancellationToken.None
            }
