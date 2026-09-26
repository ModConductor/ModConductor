namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

type internal SkyrimSetupCoordinator
    (
        store: OperationStore,
        dependencies: SkyrimSetupDependencies,
        ?childChanges: IObservable<Guid * Guid> list
    ) =
    let lifetime = new CancellationTokenSource()

    let workers =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let progression =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let failed =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let notificationGate = obj ()
    let notifications = Dictionary<Guid * Guid, int64 * TaskCompletionSource>()

    let notification key =
        lock notificationGate (fun () ->
            match notifications.TryGetValue key with
            | true, value -> value
            | _ ->
                let value =
                    0L, TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

                notifications.Add(key, value)
                value)

    let notify key =
        lock notificationGate (fun () ->
            let revision, waiting = notification key

            notifications[key] <-
                revision + 1L,
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            waiting.TrySetResult() |> ignore)

    let subscriptions =
        defaultArg childChanges []
        |> List.map (fun source -> source.Subscribe(fun key -> notify key))

    let startWorker workspace profile (action: CancellationToken -> Task) =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        let finished =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        if workers.TryAdd(key, (cancellation, finished)) then
            Task.Run(fun () ->
                task {
                    try
                        try
                            let! _ = action cancellation.Token
                            ()
                        with
                        | :? OperationCanceledException when cancellation.IsCancellationRequested ->
                            ()
                        | error -> failed.TrySetException error |> ignore
                    finally
                        match workers.TryRemove key with
                        | true, (owned, _) -> owned.Dispose()
                        | _ -> ()

                        finished.TrySetResult() |> ignore
                        notify key
                }
                :> Task)
            |> ignore

            true
        else
            cancellation.Dispose()
            false

    let inspection =
        SkyrimSetupInspection(store, dependencies, fun key -> workers.ContainsKey key)

    let recovery = SkyrimSetupRecovery(store, dependencies)

    let actions =
        SkyrimSetupActions(store, dependencies, inspection, recovery, startWorker)

    let cancellation =
        SkyrimSetupCancellation(
            store,
            dependencies,
            inspection,
            recovery,
            fun key ->
                match workers.TryGetValue key with
                | true, (worker, _) -> worker.Cancel()
                | _ -> ()
        )

    let inspect = inspection.Inspect
    let advance = actions.Advance
    let completeCancellation = cancellation.Complete
    let unavailable = inspection.Unavailable

    let waitForChange key revision (token: CancellationToken) =
        let pending =
            lock notificationGate (fun () ->
                let current, waiting = notification key

                if current <> revision then
                    Task.CompletedTask
                else
                    waiting.Task)

        pending.WaitAsync(token)

    let startProgression workspace profile =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        let finished =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        if not failed.Task.IsCompleted && progression.TryAdd(key, (cancellation, finished)) then
            Task.Run(fun () ->
                task {
                    try
                        try
                            let mutable active = true

                            while active && not cancellation.IsCancellationRequested do
                                let revision = fst (notification key)
                                let! intent = store.SkyrimSetups.Read(workspace, profile)

                                match intent with
                                | Some value when
                                    not value.Cancelled
                                    && not value.Completed
                                    && not value.CancelRequested
                                    ->
                                    let! before =
                                        inspect
                                            workspace
                                            profile
                                            value.Selection
                                            intent
                                            cancellation.Token

                                    if
                                        before.CanContinue
                                        && before.Phase <> SkyrimSetupPhase.Failed
                                        && before.Phase <> SkyrimSetupPhase.WaitingForEnbArchive
                                    then
                                        let! after =
                                            advance
                                                workspace
                                                profile
                                                value
                                                false
                                                cancellation.Token

                                        if after <> before then
                                            notify key
                                        else
                                            do! waitForChange key revision cancellation.Token
                                    elif before.Active then
                                        do! waitForChange key revision cancellation.Token
                                    else
                                        active <- false
                                | _ -> active <- false
                        with
                        | :? OperationCanceledException when cancellation.IsCancellationRequested ->
                            ()
                        | error ->
                            failed.TrySetException error |> ignore
                            notify key
                    finally
                        match progression.TryRemove key with
                        | true, (owned, _) -> owned.Dispose()
                        | _ -> ()

                        finished.TrySetResult() |> ignore
                }
                :> Task)
            |> ignore
        else
            cancellation.Dispose()

    new
        (
            store: OperationStore,
            skse: SkseCoordinator,
            enb: EnbCoordinator,
            fnis: FnisCoordinator,
            execution: IFnisExecution,
            launches: IGameLaunching,
            pluginOrders: IProfilePluginOrders
        ) =
        new SkyrimSetupCoordinator(
            store,
            SkyrimSetupDependencies.production skse enb fnis execution launches pluginOrders,
            childChanges = [ skse.Changed; enb.Changed; fnis.Changed ]
        )

    member _.CurrentRevision(workspace, profile) = fst (notification (workspace, profile))

    member _.Failed = failed.Task

    member _.WaitForChange(workspace, profile, revision, token) =
        waitForChange (workspace, profile) revision token

    member _.Read(workspace, profile, (selection: ModConductor.Persistence.SetupSelection), token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            let selected =
                intent
                |> Option.filter (fun item -> not item.Completed && not item.Cancelled)
                |> Option.map _.Selection
                |> Option.defaultValue selection

            let! current = inspect workspace profile selected intent token

            if
                (intent
                 |> Option.exists (fun value ->
                     not value.Completed && not value.Cancelled && not value.CancelRequested))
                && (current.Active || current.CanContinue)
                && current.Phase <> SkyrimSetupPhase.Failed
                && current.Phase <> SkyrimSetupPhase.WaitingForEnbArchive
            then
                startProgression workspace profile

            return current
        }

    member _.Start
        (workspace, profile, (selection: ModConductor.Persistence.SetupSelection), token)
        =
        task {
            let! existing = store.SkyrimSetups.Read(workspace, profile)

            match existing with
            | Some intent when intent.CancelRequested ->
                return! inspect workspace profile intent.Selection (Some intent) token
            | Some intent when
                not intent.Cancelled && not intent.Completed && selection = intent.Selection
                ->
                let! current = advance workspace profile intent true token
                notify (workspace, profile)
                startProgression workspace profile
                return current
            | _ ->
                let! current =
                    match existing with
                    | Some intent when not intent.Cancelled && not intent.Completed ->
                        inspect workspace profile intent.Selection (Some intent) token
                    | _ -> inspect workspace profile selection existing token

                if current.Active || current.Phase = SkyrimSetupPhase.RecoveryRequired then
                    if current.Active then
                        startProgression workspace profile

                    return current
                else
                    let! available = inspect workspace profile selection None token

                    if not available.CanStart then
                        return available
                    else
                        let! deployed = store.Deployments.Read profile

                        match deployed with
                        | Error error ->
                            return
                                unavailable
                                    selection
                                    "The deployment is unavailable"
                                    (SkyrimSetupDeployment.error error)
                        | Ok deployment when deployment.WorkspaceId <> workspace ->
                            return
                                unavailable
                                    selection
                                    "The selected profile is unavailable"
                                    "Select a profile from this workspace."
                        | Ok deployment ->
                            let initialStage =
                                if deployment.ActiveGeneration.IsNone then
                                    "deployment"
                                else
                                    "skse-start"

                            let next =
                                { WorkspaceId = workspace
                                  ProfileId = profile
                                  Selection = selection
                                  Cancelled = false
                                  Completed = false
                                  Stage = initialStage
                                  ActionId = None
                                  CancelRequested = false
                                  CancelDetail = ""
                                  RequestedAt = DateTimeOffset.UtcNow }

                            do! store.SkyrimSetups.Save next
                            let! current = advance workspace profile next true token
                            notify (workspace, profile)
                            startProgression workspace profile
                            return current
        }

    member _.Continue(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            let! current =
                match intent with
                | Some value when progression.ContainsKey((workspace, profile)) ->
                    inspect workspace profile value.Selection intent token
                | Some value when value.CancelRequested ->
                    completeCancellation workspace profile value token
                | Some value -> advance workspace profile value false token
                | None ->
                    inspect
                        workspace
                        profile
                        ModConductor.Persistence.SetupSelection.none
                        None
                        token

            notify (workspace, profile)
            startProgression workspace profile
            return current
        }

    member _.Cancel(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | None ->
                return!
                    inspect
                        workspace
                        profile
                        ModConductor.Persistence.SetupSelection.none
                        None
                        token
            | Some intent when intent.Cancelled || intent.Completed ->
                return!
                    inspect
                        workspace
                        profile
                        ModConductor.Persistence.SetupSelection.none
                        (Some intent)
                        token
            | Some intent ->
                let requested =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = "Cancellation was requested." }

                do! store.SkyrimSetups.Save requested

                match progression.TryGetValue((workspace, profile)) with
                | true, (cancellation, finished) ->
                    cancellation.Cancel()
                    do! finished.Task
                | _ -> ()

                let! latest = store.SkyrimSetups.Read(workspace, profile)

                let requested =
                    { (latest |> Option.defaultValue requested) with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = "Cancellation was requested." }

                do! store.SkyrimSetups.Save requested
                let! current = completeCancellation workspace profile requested token
                notify (workspace, profile)
                return current
        }

    member internal _.Stop() =
        task {
            lifetime.Cancel()

            let running =
                [| for _, finished in workers.Values do
                       finished.Task
                   for _, finished in progression.Values do
                       finished.Task |]

            do! Task.WhenAll running
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()

            for subscription in subscriptions do
                subscription.Dispose()

            lifetime.Dispose()
