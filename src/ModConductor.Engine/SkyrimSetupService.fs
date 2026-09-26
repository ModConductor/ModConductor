namespace ModConductor.Engine

open System
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

    let failed =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let signals = new SkyrimSetupSignals(defaultArg childChanges [])
    let workers = SkyrimSetupWorkers(lifetime, failed, signals.Notify)

    let inspection =
        SkyrimSetupInspection(store, dependencies, fun key -> workers.Contains key)

    let recovery = SkyrimSetupRecovery(store, dependencies)

    let actions =
        SkyrimSetupActions(store, dependencies, inspection, recovery, workers.Start)

    let cancellation =
        SkyrimSetupCancellation(store, dependencies, inspection, recovery, workers.Cancel)

    let inspect = inspection.Inspect
    let advance = actions.Advance
    let completeCancellation = cancellation.Complete
    let unavailable = inspection.Unavailable

    let success (operation: Task<SkyrimSetupView>) =
        task {
            let! value = operation
            return Ok value
        }

    let progression =
        SkyrimSetupProgression(lifetime, failed, signals, store, inspect, advance)

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

    member _.CurrentRevision(workspace, profile) = signals.Revision(workspace, profile)

    member _.Failed = failed.Task

    member _.WaitForChange(workspace, profile, revision, token) =
        signals.WaitForChange (workspace, profile) revision token

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
                progression.Start workspace profile

            return current
        }

    member _.Start
        (workspace, profile, (selection: ModConductor.Persistence.SetupSelection), token)
        =
        task {
            let! existing = store.SkyrimSetups.Read(workspace, profile)

            match existing with
            | Some intent when intent.CancelRequested ->
                return! success (inspect workspace profile intent.Selection (Some intent) token)
            | Some intent when
                not intent.Cancelled && not intent.Completed && selection = intent.Selection
                ->
                let! current = advance workspace profile intent true token

                match current with
                | Error detail -> return Error detail
                | Ok current ->
                    signals.Notify(workspace, profile)
                    progression.Start workspace profile
                    return Ok current
            | _ ->
                let! current =
                    match existing with
                    | Some intent when not intent.Cancelled && not intent.Completed ->
                        inspect workspace profile intent.Selection (Some intent) token
                    | _ -> inspect workspace profile selection existing token

                if current.Active || current.Phase = SkyrimSetupPhase.RecoveryRequired then
                    if current.Active then
                        progression.Start workspace profile

                    return Ok current
                else
                    let! available = inspect workspace profile selection None token

                    if not available.CanStart then
                        return Ok available
                    else
                        let! deployed = store.Deployments.Read profile

                        match deployed with
                        | Error error ->
                            return
                                Ok(
                                    unavailable
                                        selection
                                        "The deployment is unavailable"
                                        (SkyrimSetupDeployment.error error)
                                )
                        | Ok deployment when deployment.WorkspaceId <> workspace ->
                            return
                                Ok(
                                    unavailable
                                        selection
                                        "The selected profile is unavailable"
                                        "Select a profile from this workspace."
                                )
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

                            match current with
                            | Error detail -> return Error detail
                            | Ok current ->
                                signals.Notify(workspace, profile)
                                progression.Start workspace profile
                                return Ok current
        }

    member _.Continue(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            let! current =
                match intent with
                | Some value when progression.Contains(workspace, profile) ->
                    success (inspect workspace profile value.Selection intent token)
                | Some value when value.CancelRequested ->
                    success (completeCancellation workspace profile value token)
                | Some value -> advance workspace profile value false token
                | None ->
                    success (
                        inspect
                            workspace
                            profile
                            ModConductor.Persistence.SetupSelection.none
                            None
                            token
                    )

            match current with
            | Error detail -> return Error detail
            | Ok current ->
                signals.Notify(workspace, profile)
                progression.Start workspace profile
                return Ok current
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

                do! progression.CancelAndWait(workspace, profile)

                let! latest = store.SkyrimSetups.Read(workspace, profile)

                let requested =
                    { (latest |> Option.defaultValue requested) with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = "Cancellation was requested." }

                do! store.SkyrimSetups.Save requested
                let! current = completeCancellation workspace profile requested token
                signals.Notify(workspace, profile)
                return current
        }

    member internal _.Stop() =
        task {
            lifetime.Cancel()

            do! Task.WhenAll(Array.append workers.Running progression.Running)
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()

            (signals :> IDisposable).Dispose()
            lifetime.Dispose()
