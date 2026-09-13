namespace ModConductor.Bethesda

open System
open System.IO
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning

/// One disposable read result. It is neither deployment input nor a persisted plugin inventory.
type PluginSession(repository: IFileCandidateRepository) =
    let gate = obj ()
    let stop = new CancellationTokenSource()
    let mutable closing = false
    let mutable active = false

    let mutable idle =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let mutable saved: PluginSnapshot option = None
    do idle.SetResult()

    let label (sources: PlanSources) source =
        match source with
        | CandidateSource.Pinned(SourcePin.Mod(modId, _, _)) ->
            let label = sources.Mods |> List.find (fun row -> row.Id = modId)

            { Source = source
              Name = label.Name
              Version = label.Version }
        | CandidateSource.Pinned(SourcePin.Snapshot _)
        | CandidateSource.Observed _ ->
            { Source = source
              Name = "Game folder"
              Version = "" }

    let readHeader workspace name source token =
        task {
            match source with
            | CandidateSource.Observed source ->
                try
                    use stream = CandidateFiles.openObserved source
                    return HeaderReader.read name stream token
                with
                | :? IOException as error -> return Error(HeaderError.Unavailable error.Message)
                | :? UnauthorizedAccessException ->
                    return Error(HeaderError.Unavailable "The plugin file cannot be read.")
            | CandidateSource.Pinned pin ->
                let! opened = repository.OpenManaged(workspace, pin, token)

                match opened with
                | Error FilePlanError.Cancelled -> return raise (OperationCanceledException(token))
                | Error _ ->
                    return
                        Error(
                            HeaderError.Unavailable
                                "The selected plugin source cannot be read. Refresh and try again."
                        )
                | Ok stream ->
                    use stream = stream
                    return HeaderReader.read name stream token
        }

    let acquire profile token =
        task {
            let! acquired =
                CandidateFiles.acquire repository profile SkyrimPlugins.isCandidate 100000 token

            match acquired with
            | Error error -> return Error error
            | Ok observation ->
                let sources = observation.Sources

                let files =
                    observation.Plan.Files
                    |> List.filter (fun row -> SkyrimPlugins.isCandidate row.Target.Path)

                let conflicts =
                    observation.Plan.Problems
                    |> List.filter (fun row -> SkyrimPlugins.isCandidate row.Target.Path)

                if files.Length + conflicts.Length > 100000 then
                    return
                        Error(
                            FilePlanError.LimitExceeded
                                "The plugin scan exceeds the 100,000 candidate read limit."
                        )
                else
                    let entries = ResizeArray<PluginEntry>()
                    let mutable bytes = 0L

                    let add (entry: PluginEntry) =
                        let text value =
                            int64 (Encoding.UTF8.GetByteCount(value: string))

                        bytes <- bytes + 256L + text entry.Name

                        for source in (entry.Winner |> Option.toList) @ entry.Alternatives do
                            bytes <- bytes + text source.Name + text source.Version + 256L

                        match entry.Header with
                        | Error _ -> bytes <- bytes + 512L
                        | Ok header ->
                            for value in
                                (header.Author |> Option.toList)
                                @ (header.Description |> Option.toList)
                                @ header.Masters do
                                bytes <- bytes + text value + 128L

                        if bytes > 16L * 1024L * 1024L then
                            raise (
                                IOException
                                    "The plugin scan exceeds the 16 MiB metadata read limit."
                            )

                        entries.Add entry

                    for file in files do
                        token.ThrowIfCancellationRequested()
                        let name = LogicalPath.display file.Target.Path

                        let! header =
                            readHeader sources.Stamp.WorkspaceId name file.Winner.Source token

                        add
                            { Name = name
                              Path = file.Target.Path
                              Winner = Some(label sources file.Winner.Source)
                              Alternatives =
                                file.Alternatives |> List.map (fun row -> label sources row.Source)
                              Header = header
                              Ambiguity = None
                              Masters = [] }

                    for conflict in conflicts do
                        add
                            { Name = LogicalPath.display conflict.Target.Path
                              Path = conflict.Target.Path
                              Winner = None
                              Alternatives =
                                conflict.Sources |> List.map (fun row -> label sources row.Source)
                              Header = Error(HeaderError.Unavailable conflict.Detail)
                              Ambiguity = Some conflict.Detail
                              Masters = [] }

                    let! current = repository.Current sources.Stamp

                    match current with
                    | Error error -> return Error error
                    | Ok current ->
                        return
                            Ok
                                { Id = Guid.NewGuid()
                                  Stamp = sources.Stamp
                                  ObservedAt = DateTimeOffset.UtcNow
                                  Stale = not current
                                  Entries = MasterGraph.resolve (List.ofSeq entries)
                                  Problems =
                                    observation.Plan.InputProblems
                                    |> List.map (function
                                        | PlanningIssue.MissingVersion _ ->
                                            "An enabled mod has no saved version. Open Mods to publish it."
                                        | issue -> Diagnostics.describe issue) }
        }

    member private _.ObserveCore(profile, token: CancellationToken, retain) =
        task {
            let entered =
                lock gate (fun () ->
                    if closing || active then
                        false
                    else
                        active <- true

                        idle <-
                            TaskCompletionSource(
                                TaskCreationOptions.RunContinuationsAsynchronously
                            )

                        true)

            if not entered then
                return Error FilePlanError.Busy
            else
                use linked = CancellationTokenSource.CreateLinkedTokenSource(token, stop.Token)

                try
                    try
                        let! result =
                            Task.Run<Result<PluginSnapshot, FilePlanError>>(
                                (fun () -> acquire profile linked.Token),
                                linked.Token
                            )

                        match result with
                        | Ok value when retain -> lock gate (fun () -> saved <- Some value)
                        | Ok _ -> ()
                        | Error _ -> ()

                        return result
                    with
                    | :? OperationCanceledException -> return Error FilePlanError.Cancelled
                    | :? IOException as error ->
                        return Error(FilePlanError.FileUnavailable error.Message)
                    | :? UnauthorizedAccessException ->
                        return
                            Error(
                                FilePlanError.FileUnavailable "The plugin sources cannot be read."
                            )
                finally
                    lock gate (fun () ->
                        active <- false
                        idle.TrySetResult() |> ignore)
        }

    member this.Scan(profile, token) = this.ObserveCore(profile, token, true)

    member this.Observe(profile, token) = this.ObserveCore(profile, token, false)

    member _.Read id =
        task {
            match lock gate (fun () -> saved |> Option.filter (fun value -> value.Id = id)) with
            | None -> return Error FilePlanError.Expired
            | Some value ->
                let! current = repository.Current value.Stamp
                return current |> Result.map (fun current -> { value with Stale = not current })
        }

    member _.TryClose() =
        lock gate (fun () ->
            if active then
                false
            else
                closing <- true
                saved <- None
                true)

    member _.Drain() =
        let wait =
            lock gate (fun () ->
                closing <- true
                idle.Task)

        stop.Cancel()
        wait
