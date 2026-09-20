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

type private ActiveFnisRun =
    { Cancellation: CancellationTokenSource
      Completion: TaskCompletionSource<unit> }

type private FnisLogFileSnapshot =
    { Content: byte array
      LastWriteUtc: DateTime
      Attributes: FileAttributes
      UnixMode: UnixFileMode option }

type private FnisLogSnapshot =
    { Directory: string
      TemporaryDirectoryExisted: bool
      Files: Map<string, FnisLogFileSnapshot> }

type FnisRunner
    (
        store: OperationStore,
        ?timeout: TimeSpan,
        ?publicationCheckpoint: FnisRunRequest -> unit
    ) =
    let active = ConcurrentDictionary<Guid * Guid, ActiveFnisRun>()
    let lifetime = obj ()
    let mutable closing = false
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

    let readBounded path limit =
        use stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite ||| FileShare.Delete)

        if stream.Length > int64 limit then
            raise (InvalidDataException "FNIS temporary logs exceed 256 KiB.")

        let bytes = Array.zeroCreate<byte> (int stream.Length)
        let mutable offset = 0

        while offset < bytes.Length do
            let read = stream.Read(bytes, offset, bytes.Length - offset)
            if read = 0 then offset <- bytes.Length else offset <- offset + read

        bytes

    let readPrefix path limit =
        use stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite ||| FileShare.Delete)
        let bytes = Array.zeroCreate<byte> (min limit (int (min (int64 Int32.MaxValue) stream.Length)))
        let mutable offset = 0

        while offset < bytes.Length do
            let read = stream.Read(bytes, offset, bytes.Length - offset)
            if read = 0 then offset <- bytes.Length else offset <- offset + read

        bytes

    let logSnapshot (generator: string) =
        let directory = Path.GetDirectoryName generator
        let temporary = Path.Combine(directory, "temporary_logs")
        let mutable remaining = logLimit

        let paths = logPaths generator

        if paths.Length > 32 then
            raise (InvalidDataException "FNIS has more than 32 temporary logs.")

        let files =
            paths
            |> List.map (fun path ->
                let content = readBounded path remaining
                remaining <- remaining - content.Length

                path,
                { Content = content
                  LastWriteUtc = File.GetLastWriteTimeUtc path
                  Attributes = File.GetAttributes path
                  UnixMode =
                    if OperatingSystem.IsWindows() then
                        None
                    else
                        Some(File.GetUnixFileMode path) })
            |> Map.ofList

        { Directory = directory
          TemporaryDirectoryExisted = Directory.Exists temporary
          Files = files }

    let captureAndRestoreLogs (generator: string) (before: FnisLogSnapshot) =
        let builder = StringBuilder()
        let mutable remaining = logLimit
        let afterPaths = logPaths generator

        try
            for path in afterPaths do
                let existing = before.Files |> Map.tryFind path
                let length = FileInfo(path).Length
                let count = min remaining (int (min (int64 remaining) length))
                let content = readPrefix path count
                let changed =
                    existing
                    |> Option.forall (fun value ->
                        length <> int64 value.Content.Length
                        || readBounded path value.Content.Length <> value.Content)

                if changed && remaining > 0 then
                    let header = Encoding.UTF8.GetBytes("== " + Path.GetFileName path + " ==\n")
                    let headerCount = min remaining header.Length
                    builder.Append(Encoding.UTF8.GetString(header, 0, headerCount)) |> ignore
                    remaining <- remaining - headerCount

                    let contentCount = min remaining content.Length
                    builder.Append(Encoding.UTF8.GetString(content, 0, contentCount)).Append('\n')
                    |> ignore
                    remaining <- remaining - contentCount
        finally
            for path in afterPaths do
                match before.Files |> Map.tryFind path with
                | None -> File.Delete path
                | Some prior ->
                    let changed =
                        not (File.Exists path)
                        || FileInfo(path).Length <> int64 prior.Content.Length
                        || readBounded path prior.Content.Length <> prior.Content

                    if changed then
                        File.WriteAllBytes(path, prior.Content)

                    File.SetAttributes(path, prior.Attributes)
                    prior.UnixMode |> Option.iter (fun mode -> File.SetUnixFileMode(path, mode))
                    File.SetLastWriteTimeUtc(path, prior.LastWriteUtc)

            for KeyValue(path, prior) in before.Files do
                if not (File.Exists path) then
                    File.WriteAllBytes(path, prior.Content)
                    File.SetAttributes(path, prior.Attributes)
                    prior.UnixMode |> Option.iter (fun mode -> File.SetUnixFileMode(path, mode))
                    File.SetLastWriteTimeUtc(path, prior.LastWriteUtc)

            let temporary = Path.Combine(before.Directory, "temporary_logs")

            if
                not before.TemporaryDirectoryExisted
                && Directory.Exists temporary
                && (Directory.EnumerateFileSystemEntries temporary |> Seq.isEmpty)
            then
                Directory.Delete temporary

        let bytes = Encoding.UTF8.GetBytes(builder.ToString())
        if bytes.Length <= logLimit then bytes else bytes[.. logLimit - 1]

    let execute (stage: FnisRunStage) (run: ActiveFnisRun) =
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
                                run.Cancellation.Token

                        runLog <- captureAndRestoreLogs stage.Generator beforeLogs

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
                                    run.Cancellation.Token
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
                let mutable removed = Unchecked.defaultof<ActiveFnisRun>
                active.TryRemove(key, &removed) |> ignore
                run.Cancellation.Dispose()
                run.Completion.TrySetResult() |> ignore
        }

    member _.Stop() =
        task {
            let runs =
                lock lifetime (fun () ->
                    closing <- true
                    active.Values |> Seq.toArray)

            for run in runs do
                run.Cancellation.Cancel()

            if runs.Length > 0 then
                let! _ = Task.WhenAll(runs |> Array.map _.Completion.Task)
                ()
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
                                let run =
                                    { Cancellation = new CancellationTokenSource()
                                      Completion =
                                        TaskCompletionSource<unit>(
                                            TaskCreationOptions.RunContinuationsAsynchronously
                                        ) }

                                let key = request.WorkspaceId, request.ProfileId

                                let accepted =
                                    lock lifetime (fun () ->
                                        not closing && active.TryAdd(key, run))

                                if not accepted then
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
                                    run.Cancellation.Dispose()

                                    return
                                        Error(
                                            if closing then
                                                FnisExecutionError.Unavailable
                                                    "The engine is stopping."
                                            else
                                                FnisExecutionError.Busy
                                        )
                                else
                                    Task.Run(fun () -> execute stage run :> Task) |> ignore
                                    return!
                                        inspect
                                            request.WorkspaceId
                                            request.ProfileId
                                            CancellationToken.None
            }

        member _.Cancel(workspace, profile) =
            task {
                match active.TryGetValue((workspace, profile)) with
                | true, run -> run.Cancellation.Cancel()
                | _ -> ()

                let deadline = DateTime.UtcNow.AddSeconds 10.

                while active.ContainsKey((workspace, profile)) && DateTime.UtcNow < deadline do
                    do! Task.Delay 20

                return! inspect workspace profile CancellationToken.None
            }

    interface IDisposable with
        member this.Dispose() = this.Stop().GetAwaiter().GetResult()
