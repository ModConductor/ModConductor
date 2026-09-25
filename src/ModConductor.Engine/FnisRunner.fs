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
    { Id: Guid
      Cancellation: CancellationTokenSource
      Completion: TaskCompletionSource<unit> }

type private FnisPathMetadata =
    { LastAccessUtc: DateTime
      LastWriteUtc: DateTime
      Attributes: FileAttributes
      UnixMode: UnixFileMode option }

type private FnisLogFileSnapshot =
    { Content: byte array
      Metadata: FnisPathMetadata }

type private FnisLogSnapshot =
    { Directory: string
      DirectoryMetadata: FnisPathMetadata
      TemporaryDirectoryMetadata: FnisPathMetadata option
      Files: Map<string, FnisLogFileSnapshot> }

type FnisRunner
    (
        store: OperationStore,
        ?timeout: TimeSpan,
        ?publicationCheckpoint: FnisRunRequest -> unit,
        ?candidateCheckpoint: FnisRunRequest -> unit,
        ?activationCheckpoint: FnisRunRequest -> unit
    ) =
    let active = ConcurrentDictionary<Guid * Guid, ActiveFnisRun>()
    let lifetime = obj ()
    let mutable closing = false
    let timeout = defaultArg timeout (TimeSpan.FromMinutes 5.)
    let publicationCheckpoint = defaultArg publicationCheckpoint ignore
    let candidateCheckpoint = defaultArg candidateCheckpoint ignore
    let activationCheckpoint = defaultArg activationCheckpoint ignore
    let logLimit = 256 * 1024

    let restorePending profile run =
        task {
            let! state = store.Deployments.Read profile

            match state with
            | Ok state when state.PendingReceipt = Some run ->
                let! receipt = store.Deployments.Receipt run

                match receipt with
                | Error _ -> return false
                | Ok receipt ->
                    let! restored =
                        store.Deployments.Recover(
                            run,
                            receipt.Revision,
                            true,
                            ignore,
                            CancellationToken.None
                        )

                    return Result.isOk restored
            | Ok _ -> return true
            | Error _ -> return false
        }

    let reconcile workspace profile =
        task {
            let! interrupted = store.FnisExecution.Interrupted profile

            match interrupted with
            | None -> ()
            | Some run ->
                let! _ = restorePending profile run

                let! state = store.Deployments.Read profile
                let! receipt = store.Deployments.Receipt run

                match state, receipt with
                | Ok state, _ when state.PendingReceipt = Some run -> ()
                | Ok state, Ok receipt when
                    state.WorkspaceId = workspace
                    && receipt.Phase = ModConductor.Deployment.DeploymentPhase.Complete
                    && state.ActiveGeneration = Some receipt.Proposed
                    ->
                    do! store.FnisExecution.Complete run
                    let! _ = store.FnisExecution.PrunePrevious run
                    do! store.FnisExecution.MarkCurrent run
                    ()
                | _ ->
                    let! _ = store.FnisExecution.PruneCandidate run
                    ()
        }

    let inspect (workspace: Guid) (profile: Guid) (token: CancellationToken) =
        task {
            token.ThrowIfCancellationRequested()
            do! reconcile workspace profile
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

    let metadata (path: string) =
        { LastAccessUtc = File.GetLastAccessTimeUtc path
          LastWriteUtc = File.GetLastWriteTimeUtc path
          Attributes = File.GetAttributes path
          UnixMode =
            if OperatingSystem.IsWindows() then
                None
            else
                Some(File.GetUnixFileMode path) }

    let makeWritable (path: string) (directory: bool) =
        if OperatingSystem.IsWindows() then
            let attributes = File.GetAttributes path

            if attributes.HasFlag FileAttributes.ReadOnly then
                File.SetAttributes(path, attributes &&& (~~~FileAttributes.ReadOnly))
        else
            let required =
                if directory then
                    UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
                else
                    UnixFileMode.UserRead ||| UnixFileMode.UserWrite

            File.SetUnixFileMode(path, File.GetUnixFileMode(path) ||| required)

    let restoreMetadata (path: string) (value: FnisPathMetadata) =
        if value.Attributes.HasFlag FileAttributes.Directory then
            Directory.SetLastAccessTimeUtc(path, value.LastAccessUtc)
            Directory.SetLastWriteTimeUtc(path, value.LastWriteUtc)
        else
            File.SetLastAccessTimeUtc(path, value.LastAccessUtc)
            File.SetLastWriteTimeUtc(path, value.LastWriteUtc)

        if OperatingSystem.IsWindows() then
            File.SetAttributes(path, value.Attributes)
        else
            value.UnixMode |> Option.iter (fun mode -> File.SetUnixFileMode(path, mode))

    let restoreLogMetadata (before: FnisLogSnapshot) =
        for KeyValue(path, value) in before.Files do
            if File.Exists path then
                restoreMetadata path value.Metadata

        before.TemporaryDirectoryMetadata
        |> Option.iter (fun value ->
            let path = Path.Combine(before.Directory, "temporary_logs")
            if Directory.Exists path then restoreMetadata path value)

        if Directory.Exists before.Directory then
            restoreMetadata before.Directory before.DirectoryMetadata

    let logPaths (generator: string) =
        let directory = Path.GetDirectoryName generator

        let logLike (path: string) =
            let name = Path.GetFileName path
            let extension = Path.GetExtension path

            name.Contains("log", StringComparison.OrdinalIgnoreCase)
            || String.Equals(extension, ".log", StringComparison.OrdinalIgnoreCase)

        let direct =
            Directory.EnumerateFiles(directory, "*", SearchOption.TopDirectoryOnly)
            |> Seq.filter logLike
            |> Seq.toList

        let temporary = Path.Combine(directory, "temporary_logs")

        let nested =
            if Directory.Exists temporary then
                Directory.EnumerateFiles(temporary, "*", SearchOption.TopDirectoryOnly)
                |> Seq.toList
            else
                []

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
        let directoryMetadata = metadata directory
        let temporaryMetadata =
            if Directory.Exists temporary then Some(metadata temporary) else None

        try
            let paths = logPaths generator

            if paths.Length > 32 then
                raise (InvalidDataException "FNIS has more than 32 temporary logs.")

            let fileMetadata = paths |> List.map (fun path -> path, metadata path) |> Map.ofList

            try
                let mutable remaining = logLimit

                let files =
                    paths
                    |> List.map (fun path ->
                        let content = readBounded path remaining
                        remaining <- remaining - content.Length

                        path,
                        { Content = content
                          Metadata = fileMetadata[path] })
                    |> Map.ofList

                { Directory = directory
                  DirectoryMetadata = directoryMetadata
                  TemporaryDirectoryMetadata = temporaryMetadata
                  Files = files }
            finally
                for KeyValue(path, value) in fileMetadata do
                    restoreMetadata path value
        finally
            temporaryMetadata |> Option.iter (fun value -> restoreMetadata temporary value)
            restoreMetadata directory directoryMetadata

    let captureAndRestoreLogs (generator: string) (before: FnisLogSnapshot) =
        let temporary = Path.Combine(before.Directory, "temporary_logs")
        let builder = StringBuilder()
        let mutable remaining = logLimit
        let mutable afterPaths = []
        let mutable cleanupError: exn option = None

        let attempt action =
            try
                action ()
            with error ->
                if cleanupError.IsNone then
                    cleanupError <- Some error

        try
            makeWritable before.Directory true

            if Directory.Exists temporary then
                makeWritable temporary true

            afterPaths <- logPaths generator

            for path in afterPaths do
                makeWritable path false

            for path in afterPaths |> List.truncate 32 do
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
                | None -> attempt (fun () -> File.Delete path)
                | Some prior -> attempt (fun () -> File.WriteAllBytes(path, prior.Content))

            for KeyValue(path, prior) in before.Files do
                if not (File.Exists path) then
                    let parent = Path.GetDirectoryName path
                    attempt (fun () -> Directory.CreateDirectory parent |> ignore)

                    if Directory.Exists parent then
                        attempt (fun () -> makeWritable parent true)

                    attempt (fun () -> File.WriteAllBytes(path, prior.Content))

                if File.Exists path then
                    attempt (fun () -> restoreMetadata path prior.Metadata)

            match before.TemporaryDirectoryMetadata with
            | Some value ->
                if not (Directory.Exists temporary) then
                    attempt (fun () -> Directory.CreateDirectory temporary |> ignore)

                if Directory.Exists temporary then
                    attempt (fun () -> restoreMetadata temporary value)
            | None when Directory.Exists temporary ->
                attempt (fun () -> makeWritable temporary true)
                attempt (fun () -> Directory.Delete(temporary, true))
            | None -> ()

            attempt (fun () -> restoreMetadata before.Directory before.DirectoryMetadata)

        cleanupError |> Option.iter raise

        let bytes = Encoding.UTF8.GetBytes(builder.ToString())
        if bytes.Length <= logLimit then bytes else bytes[.. logLimit - 1]

    let execute (stage: FnisRunStage) (run: ActiveFnisRun) =
        task {
            let mutable stdout = Array.empty<byte>
            let mutable stderr = Array.empty<byte>
            let mutable runLog = Array.empty<byte>
            let mutable candidatePublished = false

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
                        let beforeLogs = logSnapshot projected.ToolExecutable

                        let! result =
                            task {
                                try
                                    makeWritable beforeLogs.Directory true

                                    let temporary = Path.Combine(beforeLogs.Directory, "temporary_logs")

                                    if Directory.Exists temporary then
                                        makeWritable temporary true

                                    return!
                                        NativeToolLaunch.runIn
                                            stage.Directory
                                            projected.Launch
                                            Array.empty
                                            { InputBytes = 1
                                              OutputBytes = 256 * 1024
                                              ErrorBytes = 256 * 1024
                                              Timeout = timeout }
                                            run.Cancellation.Token
                                finally
                                    runLog <- captureAndRestoreLogs projected.ToolExecutable beforeLogs
                            }

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
                            | Ok() ->
                                candidatePublished <- true
                                candidateCheckpoint stage.Request
                                let! deployment =
                                    store.Deployments.Read stage.Request.ProfileId

                                let! refreshed =
                                    match deployment with
                                    | Error _ ->
                                        Task.FromResult(
                                            Error ModConductor.Deployment.DeploymentError.Stale
                                        )
                                    | Ok state ->
                                        store.Deployments.RefreshFnis(
                                            stage.Request.Id,
                                            state.Sources,
                                            stage.Request.Id,
                                            ignore,
                                            run.Cancellation.Token
                                        )

                                match refreshed with
                                | Ok _ ->
                                    activationCheckpoint stage.Request
                                    do! store.FnisExecution.Complete stage.Request.Id
                                    let! _ = store.FnisExecution.PrunePrevious stage.Request.Id
                                    do! store.FnisExecution.MarkCurrent stage.Request.Id
                                    ()
                                | Error error ->
                                    let! restored =
                                        restorePending stage.Request.ProfileId stage.Request.Id

                                    if not restored then
                                        do! store.FnisExecution.Defer stage.Request.Id

                                    let detail =
                                        match error with
                                        | ModConductor.Deployment.DeploymentError.Cancelled ->
                                            "FNIS output activation was cancelled. The previous output remains active."
                                        | _ ->
                                            "FNIS output could not be activated. The previous output remains active."

                                    if restored then
                                        let! _ =
                                            failure
                                                stage.Request.Id
                                                (if error = ModConductor.Deployment.DeploymentError.Cancelled then
                                                     FnisOutputPhase.Cancelled
                                                 else
                                                     FnisOutputPhase.Failed)
                                                (Some result.ExitCode)
                                                stdout
                                                stderr
                                                runLog
                                                detail

                                        let! _ = store.FnisExecution.PruneCandidate stage.Request.Id
                                        ()

                                    ()
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

                        restoreLogMetadata beforeLogs
                with
                | :? OperationCanceledException ->
                    if candidatePublished then
                        do! store.FnisExecution.Defer stage.Request.Id
                    else
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
                    if candidatePublished then
                        do! store.FnisExecution.Defer stage.Request.Id
                    else
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
        member _.WaitForRun(request, token) =
            task {
                let! observed = inspect request.WorkspaceId request.ProfileId token

                match observed with
                | Error error -> return Error error
                | Ok value when value.LatestRunId <> Some request.Id ->
                    return Error FnisExecutionError.NotFound
                | Ok value when value.Phase <> FnisOutputPhase.Running -> return Ok value
                | Ok _ ->
                    let key = request.WorkspaceId, request.ProfileId

                    match active.TryGetValue key with
                    | true, run when run.Id = request.Id ->
                        do! run.Completion.Task.WaitAsync token
                    | _ -> ()

                    let! completed = inspect request.WorkspaceId request.ProfileId token

                    return
                        match completed with
                        | Ok value when value.LatestRunId <> Some request.Id ->
                            Error FnisExecutionError.NotFound
                        | Ok value when value.Phase = FnisOutputPhase.Running ->
                            Error(FnisExecutionError.Unavailable "The FNIS run is not active.")
                        | other -> other
            }

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
                                    { Id = request.Id
                                      Cancellation = new CancellationTokenSource()
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
