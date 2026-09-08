namespace ModConductor.GeneratedOutputs

open System
open System.IO
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type private OutputQuery =
    { Identity: string
      Entries: OutputObservation array
      Files: int
      Unreviewed: int }

type private CachedOutput =
    { Snapshot: OutputSnapshot
      Files: OutputObservation list
      Index: Map<Guid * LogicalPath, OutputObservation>
      Bytes: int64
      mutable Query: OutputQuery option }

type GeneratedOutputSession internal (repository: IOutputRepository) =
    let gate = obj ()
    let active = HashSet<Guid>()
    let snapshots = Dictionary<Guid, CachedOutput>()
    let order = Queue<Guid>()
    let mutable closed = false

    let mutable drained =
        new System.Threading.Tasks.TaskCompletionSource<unit>(
            System.Threading.Tasks.TaskCreationOptions.RunContinuationsAsynchronously
        )

    do drained.SetResult()


    let protect action =
        task {
            try
                return! action ()
            with
            | OutputException error -> return Error error
            | :? OperationCanceledException -> return Error OutputError.Cancelled
            | :? IOException as error -> return Error(OutputError.Unavailable error.Message)
            | :? UnauthorizedAccessException ->
                return Error(OutputError.Unavailable "Output storage cannot be accessed.")
        }

    let run workspace action =
        task {
            let entered =
                lock gate (fun () ->
                    if closed || active.Count >= 2 || active.Contains workspace then
                        false
                    else
                        if active.Count = 0 then
                            drained <-
                                new System.Threading.Tasks.TaskCompletionSource<unit>(
                                    System.Threading.Tasks.TaskCreationOptions.RunContinuationsAsynchronously
                                )

                        active.Add workspace)

            if not entered then
                return Error OutputError.Busy
            else
                try
                    return! protect action
                finally
                    lock gate (fun () ->
                        active.Remove workspace |> ignore

                        if active.Count = 0 then
                            drained.TrySetResult() |> ignore)
        }

    let required =
        function
        | Ok value -> value
        | Error error -> raise (OutputException error)

    let cached id =
        lock gate (fun () ->
            match snapshots.TryGetValue id with
            | true, value -> value
            | _ -> raise (OutputException OutputError.Stale))

    let remember value =
        lock gate (fun () ->
            let bytes () = snapshots.Values |> Seq.sumBy _.Bytes

            let count () =
                snapshots.Values
                |> Seq.filter (fun cached ->
                    cached.Snapshot.Scope.WorkspaceId = value.Snapshot.Scope.WorkspaceId)
                |> Seq.length

            while order.Count > 0
                  && (snapshots.Count >= 8
                      || count () >= 2
                      || bytes () + value.Bytes > OutputLimits.cache) do
                snapshots.Remove(order.Dequeue()) |> ignore

            snapshots.Add(value.Snapshot.Id, value)
            order.Enqueue value.Snapshot.Id)

    let execute (record: OutputActionRecord) (token: CancellationToken) afterPublication =
        task {
            try
                if not record.Result.Complete then
                    do! repository.CheckAction record
                    let mutable result = record.Result

                    match record.Action with
                    | OutputAction.MoveToMod _
                    | OutputAction.SaveCopyToMod _ ->
                        let! _ = repository.Publish(record, token)
                        afterPublication ()
                    | OutputAction.Keep
                    | OutputAction.Discard -> ()

                    for observation in record.Files do
                        token.ThrowIfCancellationRequested()

                        let selected =
                            { LocationId = observation.File.LocationId
                              Path = observation.File.Path }

                        let state = result.Entries |> List.find (fun value -> value.File = selected)

                        if state.Disposition = OutputDisposition.Pending then
                            let! disposition =
                                Task.Run(fun () ->
                                    let current = OutputFiles.current observation token

                                    if not current then
                                        OutputDisposition.Changed
                                    else
                                        match record.Action with
                                        | OutputAction.Keep -> OutputDisposition.Kept
                                        | OutputAction.SaveCopyToMod _ -> OutputDisposition.Copied
                                        | OutputAction.Discard
                                        | OutputAction.MoveToMod _ ->
                                            if OutputFiles.remove observation token then
                                                match record.Action with
                                                | OutputAction.Discard ->
                                                    OutputDisposition.Discarded
                                                | _ -> OutputDisposition.Moved
                                            else
                                                OutputDisposition.Changed)

                            let! saved = repository.SaveEntry(record.Id, selected, disposition)
                            result <- saved

                    return Ok result
                else
                    return Ok record.Result
            finally
                repository.Release(record.Id).GetAwaiter().GetResult()
        }

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active.Count <> 0 || not (next ()) then
                false
            else
                closed <- true
                snapshots.Clear()
                true)

    member internal _.ApplyAtCheckpoint(id, snapshot, selected, action, token, afterPublication) =
        protect (fun () ->
            task {
                let selected = OutputPolicy.selection selected |> required
                let! existing = repository.FindAction id

                match existing with
                | Some record when
                    record.SnapshotId = snapshot
                    && record.Action = action
                    && (record.Files
                        |> List.map (fun value ->
                            { LocationId = value.File.LocationId
                              Path = value.File.Path })) = selected
                    ->
                    return!
                        run record.Scope.WorkspaceId (fun () ->
                            task {
                                let! record = repository.Resume id
                                return! execute record token afterPublication
                            })
                | Some _ ->
                    return
                        Error(
                            OutputError.Invalid
                                "This action identity already belongs to another request."
                        )
                | None ->
                    let value = cached snapshot

                    return!
                        run value.Snapshot.Scope.WorkspaceId (fun () ->
                            task {
                                OutputPolicy.action value.Snapshot.Scope.Locations selected action
                                |> required

                                let files =
                                    selected
                                    |> List.map (fun selected ->
                                        value.Index
                                        |> Map.tryFind (selected.LocationId, selected.Path)
                                        |> Option.defaultWith (fun () ->
                                            raise (OutputException OutputError.Stale)))

                                if
                                    files |> List.exists (fun value -> value.File.Identity.IsNone)
                                then
                                    return
                                        Error(
                                            OutputError.Invalid "Select files that are present."
                                        )
                                else
                                    let! valid =
                                        Task.Run(fun () ->
                                            files
                                            |> List.forall (fun value ->
                                                OutputFiles.current value token))

                                    if not valid then
                                        return Error OutputError.Stale
                                    else
                                        let record =
                                            { Id = id
                                              SnapshotId = snapshot
                                              Scope = value.Snapshot.Scope
                                              Action = action
                                              Files = files
                                              Result =
                                                { Published = false
                                                  Id = id
                                                  VersionId = None
                                                  Entries =
                                                    selected
                                                    |> List.map (fun file ->
                                                        { File = file
                                                          Disposition = OutputDisposition.Pending })
                                                  Complete = false } }

                                        do! repository.CheckAction record
                                        let! record = repository.Claim record
                                        return! execute record token afterPublication
                            })
            })

    interface IGeneratedOutputs with
        member _.Read(workspace, context) =
            run workspace (fun () ->
                task {
                    let! scope, _ = repository.Read(workspace, context)
                    return Ok scope
                })

        member _.Add(id, expected, name, purpose) =
            run expected.WorkspaceId (fun () ->
                task {
                    let name = OutputPolicy.name name |> required
                    let! created = repository.Add(id, expected, name, purpose)
                    return Ok created
                })

        member _.StopUsing(id, revision) =
            protect (fun () ->
                task {
                    let! workspace = repository.Workspace id

                    return!
                        run workspace (fun () ->
                            task {
                                let! location = repository.StopUsing(id, revision)
                                return Ok location
                            })
                })

        member _.Observe(scope, progress, token) =
            run scope.WorkspaceId (fun () ->
                task {
                    let! current, backings =
                        repository.Read(scope.WorkspaceId, Some scope.ContextId)

                    if
                        current.Revision <> scope.Revision
                        || current.ContextRevision <> scope.ContextRevision
                    then
                        return Error OutputError.Stale
                    elif backings.Length <> current.Locations.Length then
                        return
                            Error(
                                OutputError.Unavailable
                                    "An output folder has no confirmed identity."
                            )
                    else
                        let! previous = repository.Previous scope
                        let! deployment = repository.ActiveDeployment scope

                        let! files, bytes =
                            Task.Run(fun () ->
                                OutputFiles.observe backings previous deployment progress token)

                        let! saved = repository.Observed(scope, files)

                        if not saved then
                            return Error OutputError.Stale
                        else
                            let snapshot =
                                { Id = Guid.NewGuid()
                                  Scope = current
                                  ObservedAt = DateTimeOffset.UtcNow
                                  Files =
                                    files
                                    |> List.filter (fun value -> value.File.Identity.IsSome)
                                    |> List.length
                                  Entries = files.Length
                                  Unreviewed =
                                    files
                                    |> List.filter (fun value ->
                                        value.File.State = OutputFileState.New
                                        || value.File.State = OutputFileState.Changed)
                                    |> List.length }

                            remember
                                { Snapshot = snapshot
                                  Files = files
                                  Index =
                                    files
                                    |> List.map (fun value ->
                                        (value.File.LocationId, value.File.Path), value)
                                    |> Map.ofList
                                  Bytes = bytes
                                  Query = None }

                            return Ok snapshot
                })

        member _.Page(id, view, cursor, filter) =
            protect (fun () ->
                task {
                    let value = cached id
                    let! current = repository.Current value.Snapshot.Scope

                    if not current then
                        return Error OutputError.Stale
                    else
                        let query = OutputPaging.query filter

                        let identity =
                            (match view with
                             | OutputView.ToolOutputs -> "tools:"
                             | OutputView.WritableFiles -> "writable:")
                            + query

                        let matching =
                            lock gate (fun () ->
                                match value.Query with
                                | Some previous when previous.Identity = identity -> previous
                                | _ ->
                                    let files =
                                        value.Files
                                        |> List.filter (fun value ->
                                            let included =
                                                match value.Backing.Location.Purpose, view with
                                                | OutputPurpose.ToolFolder,
                                                  OutputView.ToolOutputs
                                                | OutputPurpose.WritableFile _,
                                                  OutputView.WritableFiles -> true
                                                | _ -> false

                                            included
                                            && String
                                                .Join(
                                                    "/",
                                                    LogicalPath.components value.File.Path
                                                )
                                                .Contains(
                                                    query,
                                                    StringComparison.OrdinalIgnoreCase
                                                ))
                                        |> List.toArray

                                    let cached =
                                        { Identity = identity
                                          Entries = files
                                          Files =
                                            files
                                            |> Array.filter (fun value ->
                                                value.File.Identity.IsSome)
                                            |> Array.length
                                          Unreviewed =
                                            files
                                            |> Array.filter (fun value ->
                                                value.File.State = OutputFileState.New
                                                || value.File.State = OutputFileState.Changed)
                                            |> Array.length }

                                    value.Query <- Some cached
                                    cached)

                        return
                            Ok(
                                OutputPaging.page
                                    value.Snapshot
                                    matching.Entries
                                    matching.Identity
                                    matching.Files
                                    matching.Unreviewed
                                    cursor
                            )
                })

        member _.Preview(snapshot, selected, action) =
            protect (fun () ->
                task {
                    let selected = OutputPolicy.selection selected |> required
                    let value = cached snapshot
                    OutputPolicy.action value.Snapshot.Scope.Locations selected action |> required

                    let files =
                        selected
                        |> List.map (fun selected ->
                            value.Index.TryFind(selected.LocationId, selected.Path)
                            |> Option.defaultWith (fun () ->
                                raise (OutputException OutputError.Stale)))

                    if files |> List.exists (fun value -> value.File.Identity.IsNone) then
                        return Error(OutputError.Invalid "Select files that are present.")
                    else
                        let! result =
                            repository.Preview(
                                { Id = Guid.Empty
                                  SnapshotId = snapshot
                                  Scope = value.Snapshot.Scope
                                  Action = action
                                  Files = files
                                  Result =
                                    { Published = false
                                      Id = Guid.Empty
                                      VersionId = None
                                      Entries = []
                                      Complete = false } }
                            )

                        return Ok result
                })

        member this.Apply(id, snapshot, selected, action, token) =
            this.ApplyAtCheckpoint(id, snapshot, selected, action, token, ignore)

        member _.Action id =
            protect (fun () ->
                task {
                    let! value = repository.FindAction id

                    return
                        value
                        |> Option.map (fun value -> Ok value.Result)
                        |> Option.defaultValue (Error OutputError.NotFound)
                })

        member _.Resume(id, token) =
            protect (fun () ->
                task {
                    let! value = repository.FindAction id

                    match value with
                    | None -> return Error OutputError.NotFound
                    | Some value ->
                        return!
                            run value.Scope.WorkspaceId (fun () ->
                                task {
                                    let! record = repository.Resume id
                                    return! execute record token ignore
                                })
                })
