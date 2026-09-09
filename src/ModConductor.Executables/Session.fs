namespace ModConductor.Executables

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type private RunOwner(initial: ExecutableRun) =
    member val Gate = new SemaphoreSlim(1, 1)
    member val Snapshot = initial with get, set
    member val Native: INativeRun option = None with get, set
    member val Completion: Task = Task.CompletedTask with get, set

type ExecutableSession(repository: IExecutableRepository) =
    let gate = obj ()
    let runs = Dictionary<Guid, RunOwner>()
    let roots = HashSet<Task<int>>()
    let mutable closing = false
    let admission = new SemaphoreSlim(1, 1)

    let failed =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let record (owner: RunOwner) value =
        task {
            let! saved = repository.Update value
            owner.Snapshot <- saved
            return saved
        }

    let watch (owner: RunOwner) =
        task {
            do! owner.Gate.WaitAsync()

            try
                let! current =
                    repository.Read(owner.Snapshot.Request.WorkspaceId, owner.Snapshot.Request.Id)

                match current with
                | Error _ -> ()
                | Ok value when ExecutablePolicy.terminal value.Phase -> owner.Snapshot <- value
                | Ok value ->
                    owner.Snapshot <- value

                    if lock gate (fun () -> closing) then
                        let! _ =
                            record
                                owner
                                { value with
                                    Phase = RunPhase.TrackingUnavailable
                                    Problem = Some "The app closed before launch was confirmed." }

                        ()
                    else
                        try
                            let native = NativeProcessLaunch.start value.Preset.Launch
                            owner.Native <- Some native
                            lock gate (fun () -> roots.Add native.RootExit |> ignore)

                            let! _ =
                                record
                                    owner
                                    { value with
                                        Phase = RunPhase.Running
                                        ProcessId = Some native.ProcessId
                                        Scope = Some native.Scope }

                            ()
                        with error ->
                            let phase =
                                if Option.isSome owner.Native then
                                    RunPhase.TrackingUnavailable
                                else
                                    RunPhase.Failed

                            let! _ =
                                record
                                    owner
                                    { owner.Snapshot with
                                        Phase = phase
                                        Problem = Some error.Message }

                            ()
            finally
                owner.Gate.Release() |> ignore

            let mutable watching = not (ExecutablePolicy.terminal owner.Snapshot.Phase)

            while watching do
                do! Task.Delay 200
                do! owner.Gate.WaitAsync()

                try
                    if
                        lock gate (fun () -> closing)
                        || ExecutablePolicy.terminal owner.Snapshot.Phase
                    then
                        watching <- false
                    else
                        match owner.Native with
                        | None -> watching <- false
                        | Some native ->
                            try
                                let observation = native.Observe()

                                let phase =
                                    if Option.isNone observation.RootExitCode then
                                        RunPhase.Running
                                    elif not observation.ScopeEnded then
                                        RunPhase.WaitingForChildren
                                    else
                                        RunPhase.Finished

                                if
                                    owner.Snapshot.Phase <> phase
                                    || owner.Snapshot.RootExitCode <> observation.RootExitCode
                                    || owner.Snapshot.ActiveProcesses <> observation.ActiveProcesses
                                then
                                    let! _ =
                                        record
                                            owner
                                            { owner.Snapshot with
                                                Phase = phase
                                                RootExitCode = observation.RootExitCode
                                                ActiveProcesses = observation.ActiveProcesses }

                                    ()

                                watching <- not (ExecutablePolicy.terminal phase)
                            with error ->
                                let! _ =
                                    record
                                        owner
                                        { owner.Snapshot with
                                            Phase = RunPhase.TrackingUnavailable
                                            ActiveProcesses = None
                                            Problem = Some error.Message }

                                watching <- false
                finally
                    owner.Gate.Release() |> ignore

            do! owner.Gate.WaitAsync()

            try
                owner.Native |> Option.iter _.Dispose()
                owner.Native <- None
            finally
                owner.Gate.Release() |> ignore

            lock gate (fun () -> runs.Remove owner.Snapshot.Request.Id |> ignore)
        }

    let launch (owner: RunOwner) =
        task {
            try
                try
                    do! watch owner
                with _ ->
                    failed.TrySetResult() |> ignore
            finally
                owner.Native |> Option.iter _.Dispose()
                owner.Native <- None
                lock gate (fun () -> runs.Remove owner.Snapshot.Request.Id |> ignore)
        }

    let beginRun request =
        task {
            do! admission.WaitAsync()

            try
                let admitted =
                    lock gate (fun () ->
                        roots.RemoveWhere(fun root -> root.IsCompleted) |> ignore
                        not closing && runs.Count < 32 && roots.Count < 32)

                if lock gate (fun () -> closing) then
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
                        | Ok value when value.Request = request -> Task.FromResult(Ok(value, false))
                        | Ok _ -> Task.FromResult(Error ExecutableError.IdentityConflict)
                        | Error ExecutableError.NotFound when not admitted ->
                            Task.FromResult(Error ExecutableError.Capacity)
                        | Error ExecutableError.NotFound -> repository.Begin request
                        | Error problem -> Task.FromResult(Error problem)

                    match result with
                    | Error problem -> return Error problem
                    | Ok(snapshot, false) -> return Ok snapshot
                    | Ok(snapshot, true) ->
                        let owner = RunOwner snapshot
                        lock gate (fun () -> runs.Add(request.Id, owner))
                        owner.Completion <- launch owner
                        return Ok snapshot
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
                    return Ok saved
            finally
                owner |> Option.iter (fun value -> value.Gate.Release() |> ignore)
        }

    let unavailable () =
        ExecutableError.Unavailable "The executable owner is closing."

    member _.Failed = failed.Task

    member _.Close() =
        task {
            do! admission.WaitAsync()

            let pending =
                lock gate (fun () ->
                    closing <- true
                    runs.Values |> Seq.toArray)

            admission.Release() |> ignore
            do! Task.WhenAll(pending |> Array.map _.Completion)
        }

    interface IExecutables with
        member _.List(workspace, after) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.List(workspace, after)

        member _.ReadPreset(workspace, id) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.ReadPreset(workspace, id)

        member _.Save value =
            task {
                if lock gate (fun () -> closing) then
                    return Error(unavailable ())
                else
                    match ExecutablePolicy.validate value with
                    | Error problem -> return Error problem
                    | Ok() -> return! repository.Save value
            }

        member _.Delete(workspace, id, revision) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Delete(workspace, id, revision)

        member _.Begin request = beginRun request

        member _.Read(workspace, id) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Read(workspace, id)

        member _.Recent(workspace, after) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                repository.Recent(workspace, after)

        member _.StopWaiting(workspace, id) =
            if lock gate (fun () -> closing) then
                Task.FromResult(Error(unavailable ()))
            else
                stop workspace id
