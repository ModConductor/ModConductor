namespace ModConductor.GeneratedOutputs

open System
open System.IO
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type GeneratedOutputSession internal (repository: IOutputRepository) =
    let gate = obj ()
    let active = HashSet<Guid>()
    let cache = OutputSnapshotCache(gate)
    let actions = OutputActionExecution(repository)
    let observation = OutputObservationSession(repository, cache)
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

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active.Count <> 0 || not (next ()) then
                false
            else
                closed <- true
                cache.Clear()
                true)

    member internal _.ApplyAtCheckpoint(id, snapshot, selected, action, token, afterPublication) =
        protect (fun () ->
            actions.Apply(id, snapshot, selected, action, token, afterPublication, cache, run))

    interface IGeneratedOutputs with
        member _.Read(workspace, profile, context) =
            run workspace (fun () ->
                task {
                    let! scope, _ = repository.Read(workspace, profile, context)
                    return Ok scope
                })

        member _.Add(id, expected, name, purpose) =
            run expected.WorkspaceId (fun () ->
                task {
                    match OutputPolicy.name name with
                    | Error error -> return Error error
                    | Ok name ->
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
            run scope.WorkspaceId (fun () -> observation.Observe(scope, progress, token))

        member _.Page(id, view, cursor, filter) =
            protect (fun () ->
                task {
                    match cache.Find id with
                    | Error error -> return Error error
                    | Ok value ->
                        let! current = repository.Current value.Snapshot.Scope

                        if not current then
                            return Error OutputError.Stale
                        else
                            return cache.Page(value, view, cursor, filter)
                })

        member _.Preview(snapshot, selected, action) =
            protect (fun () ->
                task {
                    match cache.Select(snapshot, selected, action) with
                    | Error error -> return Error error
                    | Ok(value, files) ->
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

        member _.Action id = protect (fun () -> actions.Action id)

        member _.Resume(id, token) =
            protect (fun () -> actions.Resume(id, token, run))
