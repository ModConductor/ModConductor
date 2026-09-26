namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Protocol.V1
open SkyrimSetupViews

type private SkyrimSetupPending
    (store: OperationStore, dependencies: SkyrimSetupDependencies, workerActive: Guid * Guid -> bool)
    =
    let preview = SkyrimSetupPreview(store, dependencies)
    let components = SkyrimSetupComponents(store, dependencies)

    let inspect
        workspace
        profile
        selection
        (intent: StoredSkyrimSetupIntent option)
        (deployed: DeploymentStatus)
        running
        token
        =
        task {
            let recorded = intent |> Option.filter (fun value -> not value.Cancelled)
            let mutable stage = recorded |> Option.map _.Stage |> Option.defaultValue ""

            let! skseWhilePending =
                if
                    stage = "skse"
                    && deployed.ActiveGeneration.IsSome
                    && deployed.PendingReceipt.IsSome
                    && not (intent |> Option.exists _.CancelRequested)
                then
                    task {
                        let! state = dependencies.ReadSkse workspace profile
                        return Some state
                    }
                else
                    Task.FromResult None

            let! enbWhilePending =
                if
                    stage = "enb"
                    && deployed.ActiveGeneration.IsSome
                    && deployed.PendingReceipt.IsSome
                    && not (intent |> Option.exists _.CancelRequested)
                then
                    task {
                        let! state = dependencies.ReadEnb workspace profile
                        return Some state
                    }
                else
                    Task.FromResult None

            let! fnisWhilePending =
                if
                    stage = "fnis-install"
                    && deployed.ActiveGeneration.IsSome
                    && deployed.PendingReceipt.IsSome
                    && not (intent |> Option.exists _.CancelRequested)
                then
                    task {
                        let! state = dependencies.ReadFnis workspace profile
                        return Some state
                    }
                else
                    Task.FromResult None

            let sksePendingActive =
                skseWhilePending
                |> Option.exists (fun state ->
                    state.Phase = SksePhase.Downloading || state.Phase = SksePhase.Installing)

            let enbPendingActive =
                enbWhilePending
                |> Option.exists (fun state ->
                    state.Phase = EnbPhase.Validating
                    || state.Phase = EnbPhase.Acquiring
                    || state.Phase = EnbPhase.Installing)

            let fnisPendingActive =
                fnisWhilePending
                |> Option.exists (fun state ->
                    state.Phase = FnisPhase.Downloading || state.Phase = FnisPhase.Installing)

            let! deployed =
                if
                    (skseWhilePending.IsSome && not sksePendingActive)
                    || (enbWhilePending.IsSome && not enbPendingActive)
                    || (fnisWhilePending.IsSome && not fnisPendingActive)
                then
                    task {
                        let! latest = store.Deployments.Read profile
                        return latest |> Result.defaultValue deployed
                    }
                else
                    Task.FromResult deployed

            if intent |> Option.exists _.CancelRequested then
                let pending = intent.Value

                return
                    { view
                          SkyrimSetupPhase.RecoveryRequired
                          "Skyrim setup cancellation needs completion"
                          (if String.IsNullOrWhiteSpace pending.CancelDetail then
                               "Select Continue to finish cancelling."
                           else
                               pending.CancelDetail)
                          [ componentView
                                "Setup"
                                "Cancellation recorded"
                                "Cancellation is not complete."
                                false
                                false
                                true ]
                          selection
                          running
                          false
                          true
                          false
                          false with
                        CanCancel = false }
            elif intent |> Option.exists _.Cancelled then
                let cancelled = intent.Value

                let! current = preview.Preview workspace profile selection deployed token

                return
                    { current with
                        Phase = SkyrimSetupPhase.Cancelled
                        Status = "Skyrim setup is cancelled"
                        Detail =
                            if String.IsNullOrWhiteSpace cancelled.CancelDetail then
                                "Select components to try again."
                            else
                                cancelled.CancelDetail }
            elif sksePendingActive then
                let state = skseWhilePending.Value

                let! installed =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                return
                    view
                        SkyrimSetupPhase.SettingUpSkse
                        state.Status
                        state.Detail
                        [ { componentView "SKSE" state.Status state.Detail false true false with
                              Id = "skse"
                              Installed = installed.IsSome } ]
                        selection
                        running
                        false
                        false
                        true
                        false
            elif enbPendingActive then
                let state = enbWhilePending.Value

                let! installed =
                    store.EnbSetups.Components(workspace, profile, deployed.ActiveGeneration)

                return
                    view
                        SkyrimSetupPhase.SettingUpEnb
                        state.Status
                        state.Detail
                        [ { componentView "ENBSeries" state.Status state.Detail false true false with
                              Id = "enb"
                              Installed =
                                  installed |> List.exists (fun item -> item.Kind = "runtime") } ]
                        selection
                        running
                        false
                        false
                        true
                        false
            elif fnisPendingActive then
                let state = fnisWhilePending.Value

                let! installed =
                    store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

                return
                    view
                        SkyrimSetupPhase.SettingUpFnis
                        state.Status
                        state.Detail
                        [ { componentView "FNIS" state.Status state.Detail false true false with
                              Id = "fnis"
                              Installed = installed.IsSome } ]
                        selection
                        running
                        false
                        false
                        true
                        false
            elif deployed.ActiveGeneration.IsSome && deployed.PendingReceipt.IsSome then
                return
                    { view
                          SkyrimSetupPhase.RecoveryRequired
                          "The deployment needs recovery"
                          "Finish the current operation before changing a component."
                          [ componentView
                                "Deployment"
                                "Recovery required"
                                "The profile is unchanged."
                                false
                                false
                                true ]
                          selection
                          running
                          false
                          running
                          false
                          false with
                        CanCancel = false }
            elif deployed.ActiveGeneration.IsNone then
                return
                    view
                        SkyrimSetupPhase.PreparingDeployment
                        (if deployed.PendingReceipt.IsSome then
                             "The first deployment needs recovery"
                         else
                             "Preparing the profile")
                        (if deployed.PendingReceipt.IsSome then
                             "Select Continue to finish this step."
                         else
                             "The profile must be ready before components are installed.")
                        [ componentView
                              "Deployment"
                              (if deployed.PendingReceipt.IsSome then
                                   "Recovery required"
                               else
                                   "Not prepared")
                              "The profile is not ready."
                              false
                              false
                              deployed.PendingReceipt.IsSome ]
                        selection
                        running
                        false
                        running
                        false
                        false
            elif workerActive (workspace, profile) then
                let workerPhase, workerName, workerStatus, workerDetail =
                    match stage with
                    | "fnis-run" -> SkyrimSetupPhase.FnisRunning, "FNIS", "Updating FNIS output", ""
                    | _ -> SkyrimSetupPhase.SettingUpEnb, "ENBSeries", "Setting up", ""

                let workerComponent =
                    componentView workerName workerStatus workerDetail false true false

                return
                    view
                        workerPhase
                        workerStatus
                        workerDetail
                        [ workerComponent ]
                        selection
                        running
                        false
                        false
                        true
                        false
            else
                return!
                    components.Inspect
                        workspace
                        profile
                        selection
                        running
                        recorded
                        deployed
                        stage
                        token
        }

    member _.Inspect workspace profile selection intent deployed running token =
        inspect workspace profile selection intent deployed running token

type internal SkyrimSetupInspection
    (
        store: OperationStore,
        dependencies: SkyrimSetupDependencies,
        workerActive: Guid * Guid -> bool,
        failureDetail: Guid * Guid -> string option
    ) =
    let preview = SkyrimSetupPreview(store, dependencies)
    let pending = SkyrimSetupPending(store, dependencies, workerActive)

    let inspect workspace profile selection (intent: StoredSkyrimSetupIntent option) token =
        task {
            let running =
                intent
                |> Option.exists (fun value -> not value.Cancelled && not value.Completed)

            let! contextResult = (store.GameContexts :> IGameContexts).Read(workspace, profile)

            match contextResult with
            | Error _ ->
                return
                    unavailable
                        selection
                        "Skyrim setup is unavailable"
                        "Select and refresh the Skyrim Special Edition Steam installation."
            | Ok context ->
                match context.Binding with
                | Some binding when
                    binding.Evidence.Platform = ContextPlatform.Proton
                    && binding.Evidence.DefinitionId = Skyrim.definition.Id
                    && binding.Proton.IsNone
                    ->
                    return
                        unavailable
                            selection
                            "Proton is not selected"
                            "Select Proton in the game installation. Then select Refresh."
                | Some binding when missingFirstRun binding ->
                    return
                        unavailable selection "Skyrim needs its first Steam run" firstRunInstruction
                | None ->
                    return
                        unavailable
                            selection
                            "Skyrim setup is unavailable"
                            "Select and refresh the Skyrim Special Edition Steam installation."
                | Some binding when
                    binding.NeedsCheck
                    || not binding.Evidence.Valid
                    || binding.Evidence.DefinitionId <> Skyrim.definition.Id
                    ->
                    return
                        unavailable
                            selection
                            "Skyrim setup is unavailable"
                            "Refresh the selected Skyrim Special Edition Steam installation."
                | Some _ ->
                    let! deployed = store.Deployments.Read profile

                    match deployed with
                    | Error error ->
                        return
                            unavailable
                                selection
                                "The deployment is unavailable"
                                (SkyrimSetupDeployment.error error)
                    | Ok deployed when deployed.WorkspaceId <> workspace ->
                        return
                            unavailable
                                selection
                                "The selected profile is unavailable"
                                "Select a profile from this workspace."
                    | Ok deployed when not running && not (intent |> Option.exists _.Cancelled) ->
                        return! preview.Preview workspace profile selection deployed token
                    | Ok deployed ->
                        return!
                            pending.Inspect
                                workspace
                                profile
                                selection
                                intent
                                deployed
                                running
                                token
        }


    member _.Inspect workspace profile selection intent token =
        task {
            let! current = inspect workspace profile selection intent token

            match
                intent
                |> Option.exists (fun value -> not value.Cancelled && not value.Completed),
                failureDetail (workspace, profile)
            with
            | true, Some detail when current.Phase <> SkyrimSetupPhase.Unavailable ->
                let components =
                    current.Components
                    |> List.map (fun item ->
                        if item.Id = "skse" then
                            { item with
                                Status = "Removal failed"
                                Detail = detail
                                Active = false
                                Blocked = true }
                        else
                            item)

                return
                    { current with
                        Phase = SkyrimSetupPhase.Failed
                        Status = "SKSE removal failed"
                        Detail = detail
                        Components = components
                        CanContinue = false
                        Active = false
                        Ready = false }
            | _ -> return current
        }

    member _.Unavailable selection status detail = unavailable selection status detail
