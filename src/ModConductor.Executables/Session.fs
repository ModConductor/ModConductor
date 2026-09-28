namespace ModConductor.Executables

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type ExecutableSession(repository: IExecutableRepository) =
    let state = ExecutionState()
    let gate, runs, roots = state.Gate, state.Runs, state.Roots
    let admission = new SemaphoreSlim(1, 1)
    let notifications = Dictionary<Guid, TaskCompletionSource>()

    let signal id =
        lock gate (fun () ->
            match notifications.TryGetValue id with
            | true, waiting ->
                notifications.Remove id |> ignore
                waiting.TrySetResult() |> ignore
            | _ -> ())

    let waiting id =
        lock gate (fun () ->
            match notifications.TryGetValue id with
            | true, current -> current.Task
            | _ ->
                let current = TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
                notifications.Add(id, current)
                current.Task)

    let failed =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let launch owner =
        RunLifecycle.start repository state failed signal owner

    let beginRun (request: RunRequest) =
        task {
            do! admission.WaitAsync()

            try
                let admitted =
                    lock gate (fun () ->
                        roots.RemoveWhere(fun root -> root.IsCompleted) |> ignore
                        not state.Closing && runs.Count < 32 && roots.Count < 32)

                if lock gate (fun () -> state.Closing) then
                    return Error(ExecutableError.Unavailable "The executable owner is closing.")
                elif
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || request.PresetId = Guid.Empty
                    || request.WorkspaceRevision < 0L
                    || request.PresetRevision < 1L
                then
                    return Error(ExecutableError.Invalid "The launch request identity is invalid.")
                else
                    let! existing = repository.Read(request.WorkspaceId, request.Id)

                    let! result =
                        match existing with
                        | Ok value when
                            (match value.Source with
                             | RunSource.Preset(previous, _) -> previous = request
                             | RunSource.Game _ -> false)
                            ->
                            Task.FromResult(Ok(value, false))
                        | Ok _ -> Task.FromResult(Error ExecutableError.IdentityConflict)
                        | Error ExecutableError.NotFound when not admitted ->
                            Task.FromResult(Error ExecutableError.Capacity)
                        | Error ExecutableError.NotFound -> repository.Begin request
                        | Error problem -> Task.FromResult(Error problem)

                    match result with
                    | Error problem -> return Error problem
                    | Ok(snapshot, false) -> return Ok snapshot
                    | Ok(snapshot, true) ->
                        signal snapshot.Id
                        let owner = RunOwner(snapshot, None)
                        lock gate (fun () -> runs.Add(request.Id, owner))
                        owner.Completion <- launch owner
                        return Ok snapshot
            finally
                admission.Release() |> ignore
        }

    let beginGame (game: GameRun) prepare =
        task {
            do! admission.WaitAsync()

            try
                let available =
                    lock gate (fun () ->
                        roots.RemoveWhere(fun root -> root.IsCompleted) |> ignore
                        not state.Closing && runs.Count < 32 && roots.Count < 32)

                let! existing = repository.Read(game.Request.WorkspaceId, game.Request.Id)

                let! result =
                    match existing with
                    | Ok value ->
                        match value.Source with
                        | RunSource.Game previous when previous.Request = game.Request ->
                            Task.FromResult(Ok(value, false))
                        | _ -> Task.FromResult(Error ExecutableError.IdentityConflict)
                    | Error ExecutableError.NotFound when available -> repository.BeginGame game
                    | Error ExecutableError.NotFound ->
                        Task.FromResult(Error ExecutableError.Capacity)
                    | Error problem -> Task.FromResult(Error problem)

                match result with
                | Error error -> return Error error
                | Ok(value, false) -> return Ok value
                | Ok(value, true) ->
                    signal value.Id
                    let owner = RunOwner(value, Some prepare)
                    lock gate (fun () -> runs.Add(value.Id, owner))
                    owner.Completion <- launch owner
                    return Ok value
            finally
                admission.Release() |> ignore
        }

    let stop workspace id =
        task {
            let owner =
                lock gate (fun () ->
                    match runs.TryGetValue id with
                    | true, value -> Some value
                    | _ -> None)

            match owner with
            | Some value -> do! value.Gate.WaitAsync()
            | None -> ()

            try
                let! current = repository.Read(workspace, id)

                match current with
                | Error problem -> return Error problem
                | Ok value when ExecutablePolicy.terminal value.Phase -> return Ok value
                | Ok value ->
                    let! saved =
                        repository.Update
                            { value with
                                Phase = RunPhase.Detached
                                Problem = None }

                    owner |> Option.iter (fun current -> current.Snapshot <- saved)
                    signal saved.Id
                    return Ok saved
            finally
                owner |> Option.iter (fun value -> value.Gate.Release() |> ignore)
        }

    let unavailable () =
        ExecutableError.Unavailable "The executable owner is closing."

    member _.Failed = failed.Task
    member _.LatestGame workspace = repository.LatestGame workspace
    member _.BeginGame(game, prepare) = beginGame game prepare

    member _.CancelGame(workspace, id) =
        task {
            let pending =
                lock gate (fun () ->
                    match runs.TryGetValue id with
                    | true, owner when
                        owner.Snapshot.WorkspaceId = workspace
                        && owner.Prepare.IsSome
                        && owner.Native.IsNone
                        ->
                        owner.Cancellation.Cancel()
                        Some owner.Completion
                    | _ -> None)

            match pending with
            | Some completion -> do! completion
            | None -> ()

            return! repository.Read(workspace, id)
        }


    member _.Close() =
        task {
            do! admission.WaitAsync()

            let pending =
                lock gate (fun () ->
                    state.Closing <- true

                    for owner in runs.Values do
                        owner.Cancellation.Cancel()

                    runs.Values |> Seq.toArray)

            admission.Release() |> ignore
            do! Task.WhenAll(pending |> Array.map _.Completion)
        }

    interface IExecutables with
        member _.HasActive() =
            lock gate (fun () ->
                roots.RemoveWhere(fun root -> root.IsCompleted) |> ignore
                roots.Count <> 0
                || (runs.Values
                    |> Seq.exists (fun owner ->
                        not (ExecutablePolicy.terminal owner.Snapshot.Phase))))

        member _.List(workspace, after) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.List(workspace, after)

        member _.ReadPreset(workspace, id) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.ReadPreset(workspace, id)

        member _.Save value =
            task {
                if lock gate (fun () -> state.Closing) then
                    return Error(unavailable ())
                else
                    match ExecutablePolicy.validate value with
                    | Error problem -> return Error problem
                    | Ok() -> return! repository.Save value
            }

        member _.Delete(workspace, id, revision) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Delete(workspace, id, revision)

        member _.Begin request = beginRun request

        member _.Read(workspace, id) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Read(workspace, id)

        member _.WaitForChange(workspace, id, revision, token) =
            task {
                let pending = waiting id
                let! current = repository.Read(workspace, id)

                match current with
                | Ok value when value.Revision = revision -> do! pending.WaitAsync(token)
                | _ -> ()
            } :> Task

        member _.Recent(workspace, after) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Recent(workspace, after)

        member _.StopWaiting(workspace, id) =
            if lock gate (fun () -> state.Closing) then
                Task.FromResult(Error(unavailable ()))
            else
                stop workspace id
