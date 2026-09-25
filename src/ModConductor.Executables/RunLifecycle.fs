namespace ModConductor.Executables

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

module internal RunLifecycle =
    let start
        (repository: IExecutableRepository)
        (state: ExecutionState)
        (failed: TaskCompletionSource)
        (changed: Guid -> unit)
        (owner: RunOwner)
        =
        let record (owner: RunOwner) value =
            task {
                let! saved = repository.Update value
                owner.Snapshot <- saved
                changed saved.Id
                return saved
            }

        let watch (owner: RunOwner) =
            task {
                do! owner.Gate.WaitAsync()

                try
                    let! current = repository.Read(owner.Snapshot.WorkspaceId, owner.Snapshot.Id)

                    match current with
                    | Error _ -> ()
                    | Ok value when ExecutablePolicy.terminal value.Phase -> owner.Snapshot <- value
                    | Ok value ->
                        owner.Snapshot <- value

                        if lock state.Gate (fun () -> state.Closing) then
                            let! _ =
                                record
                                    owner
                                    { value with
                                        Phase = RunPhase.TrackingUnavailable
                                        Problem = Some "The app closed before launch was confirmed." }

                            ()
                        else
                            try
                                use! preparation =
                                    task {
                                        match value.Source, owner.Prepare with
                                        | RunSource.Game game, Some prepare ->
                                            let progress current =
                                                task {
                                                    let! _ =
                                                        record
                                                            owner
                                                            { owner.Snapshot with
                                                                Source = RunSource.Game current }

                                                    return ()
                                                }

                                            let! prepared, lease =
                                                prepare game owner.Cancellation.Token progress

                                            try
                                                let! _ =
                                                    record
                                                        owner
                                                        { owner.Snapshot with
                                                            Source = RunSource.Game prepared }

                                                return lease
                                            with error ->
                                                lease.Dispose()
                                                return raise error
                                        | RunSource.Preset _, None ->
                                            return
                                                { new IDisposable with
                                                    member _.Dispose() = () }
                                        | _ ->
                                            return invalidOp "The run preparation is unavailable."
                                    }

                                let native =
                                    lock state.Gate (fun () ->
                                        owner.Cancellation.Token.ThrowIfCancellationRequested()

                                        if state.Closing then
                                            raise (OperationCanceledException())

                                        let native =
                                            NativeProcessLaunch.start owner.Snapshot.Launch

                                        owner.Native <- Some native
                                        native)

                                lock state.Gate (fun () ->
                                    state.Roots.Add native.RootExit |> ignore)

                                let! _ =
                                    record
                                        owner
                                        { owner.Snapshot with
                                            Phase = RunPhase.Running
                                            ProcessId = Some native.ProcessId
                                            Scope = Some native.Scope }

                                ()
                            with error ->
                                let phase =
                                    if Option.isSome owner.Native then
                                        RunPhase.TrackingUnavailable
                                    elif error :? OperationCanceledException then
                                        RunPhase.Cancelled
                                    else
                                        RunPhase.Failed

                                let! _ =
                                    record
                                        owner
                                        { owner.Snapshot with
                                            Phase = phase
                                            Problem =
                                                Some(
                                                    if error :? OperationCanceledException then
                                                        "Launch cancelled before the game started."
                                                    else
                                                        error.Message
                                                ) }

                                ()
                finally
                    owner.Gate.Release() |> ignore

                let mutable watching = not (ExecutablePolicy.terminal owner.Snapshot.Phase)

                while watching do
                    do! Task.Delay 200
                    do! owner.Gate.WaitAsync()

                    try
                        if
                            lock state.Gate (fun () -> state.Closing)
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
                                        || owner.Snapshot.ActiveProcesses
                                           <> observation.ActiveProcesses
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
                                                Problem =
                                                    Some(
                                                        if error :? OperationCanceledException then
                                                            "Launch cancelled before the game started."
                                                        else
                                                            error.Message
                                                    ) }

                                    watching <- false
                    finally
                        owner.Gate.Release() |> ignore

                do! owner.Gate.WaitAsync()

                try
                    owner.Native |> Option.iter _.Dispose()
                    owner.Native <- None
                finally
                    owner.Gate.Release() |> ignore

                lock state.Gate (fun () -> state.Runs.Remove owner.Snapshot.Id |> ignore)
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
                    lock state.Gate (fun () -> state.Runs.Remove owner.Snapshot.Id |> ignore)
            }

        launch owner
