namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

type SkyrimSetupComponentView =
    { Id: string
      Name: string
      Status: string
      Detail: string
      Installed: bool
      Ready: bool
      Active: bool
      Blocked: bool }

type internal SkyrimSetupView =
    { Phase: SkyrimSetupPhase
      Status: string
      Detail: string
      Components: SkyrimSetupComponentView list
      Selection: ModConductor.Persistence.SetupSelection
      CanStart: bool
      CanContinue: bool
      Active: bool
      CanCancel: bool
      Ready: bool }

type internal SkyrimSetupDependencies =
    { ReadSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      StartSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      RemoveSkse: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<SkseView>
      CancelSkse: Guid -> Guid -> System.Threading.Tasks.Task<SkseView>
      ReadEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      RemoveEnb: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<EnbView>
      SelectEnb:
          Guid
              -> Guid
              -> Guid
              -> string
              -> CancellationToken
              -> System.Threading.Tasks.Task<EnbView>
      CancelEnb: Guid -> Guid -> System.Threading.Tasks.Task<EnbView>
      RecoverEnb: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<EnbView>
      ReadFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      InstallFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      UpdateFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      RemoveFnis: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<FnisView>
      CancelFnis: Guid -> Guid -> System.Threading.Tasks.Task<FnisView>
      RecoverFnis: Guid -> Guid -> CancellationToken -> System.Threading.Tasks.Task<FnisView>
      InspectFnis:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      RunFnis:
          ModConductor.Fnis.FnisRunRequest
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      CancelFnisRun:
          Guid -> Guid -> System.Threading.Tasks.Task<Result<FnisInspection, FnisExecutionError>>
      ReadLaunch:
          Guid
              -> Guid
              -> System.Threading.Tasks.Task<
                  Result<ModConductor.GameLaunching.GameLaunchState, ExecutableError>
               >
      PluginPreflight:
          Guid
              -> Guid
              -> CancellationToken
              -> System.Threading.Tasks.Task<Result<unit, ProfileDataError>> }

module internal SkyrimSetupDependencies =
    let production
        (skse: SkseCoordinator)
        (enb: EnbCoordinator)
        (fnis: FnisCoordinator)
        (execution: IFnisExecution)
        (launches: IGameLaunching)
        (pluginOrders: IProfilePluginOrders)
        =
        { ReadSkse = fun workspace profile -> skse.Read(workspace, profile)
          StartSkse = fun workspace profile -> skse.Start(workspace, profile)
          RemoveSkse = fun workspace profile token -> skse.Remove(workspace, profile, token)
          CancelSkse = fun workspace profile -> skse.Cancel(workspace, profile)
          ReadEnb = fun workspace profile -> enb.Read(workspace, profile)
          RemoveEnb = fun workspace profile token -> enb.Remove(workspace, profile, token, runtimeOnly = true)
          SelectEnb =
            fun workspace profile operation path token ->
                enb.SelectRuntimeArchive(workspace, profile, operation, path, token)
          CancelEnb = fun workspace profile -> enb.Cancel(workspace, profile)
          RecoverEnb = fun workspace profile token -> enb.Recover(workspace, profile, token)
          ReadFnis = fun workspace profile -> fnis.Read(workspace, profile)
          InstallFnis = fun workspace profile -> fnis.Install(workspace, profile)
          UpdateFnis = fun workspace profile -> fnis.Update(workspace, profile)
          RemoveFnis = fun workspace profile token -> fnis.Remove(workspace, profile, token)
          CancelFnis = fun workspace profile -> fnis.Cancel(workspace, profile)
          RecoverFnis = fun workspace profile token -> fnis.Recover(workspace, profile, token)
          InspectFnis = fun workspace profile token -> execution.Inspect(workspace, profile, token)
          RunFnis = fun request token -> execution.Run(request, token)
          CancelFnisRun = fun workspace profile -> execution.Cancel(workspace, profile)
          ReadLaunch = fun workspace profile -> launches.Read(workspace, profile)
          PluginPreflight =
            fun workspace profile token ->
                pluginOrders.PreflightForLaunch(workspace, profile, token) }

type internal SkyrimSetupCoordinator(store: OperationStore, dependencies: SkyrimSetupDependencies) =
    let lifetime = new CancellationTokenSource()
    let workers = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()

    let startWorker workspace profile action =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        if workers.TryAdd(key, cancellation) then
            Task.Run(fun () ->
                task {
                    try
                        try
                            let! _ = action cancellation.Token
                            ()
                        with :? OperationCanceledException when
                            cancellation.IsCancellationRequested ->
                            ()
                    finally
                        match workers.TryRemove key with
                        | true, owned -> owned.Dispose()
                        | _ -> ()
                }
                :> Task)
            |> ignore

            true
        else
            cancellation.Dispose()
            false

    let firstRunInstruction =
        "Start Skyrim once through Steam. Close it, then select Refresh."

    let componentView (name: string) status detail ready active blocked =
        { Id = name.ToLowerInvariant()
          Name = name
          Status = status
          Detail = detail
          Installed = ready
          Ready = ready
          Active = active
          Blocked = blocked }

    let view phase status detail components selection running start continueSetup active ready =
        { Phase = phase
          Status = status
          Detail = detail
          Components = components
          Selection = selection
          CanStart = start
          CanContinue = continueSetup
          Active = active
          CanCancel = running && not ready
          Ready = ready }

    let unavailable selection status detail =
        view
            SkyrimSetupPhase.Unavailable
            status
            detail
            [ componentView "Skyrim installation" status detail false false true ]
            selection
            false
            false
            false
            false
            false

    let preview workspace profile (selection: ModConductor.Persistence.SetupSelection) (deployed: DeploymentStatus) =
        task {
            let! skse = store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)
            let! enb = store.EnbSetups.Components(workspace, profile, deployed.ActiveGeneration)
            let! fnis = store.FnisSetups.ReadExact(workspace, profile, deployed.ActiveGeneration)
            let installed = [ skse.IsSome; enb |> List.exists (fun item -> item.Kind = "runtime"); fnis.IsSome ]
            let actions = [ selection.Skse; selection.Enb; selection.Fnis ]

            let valid =
                List.zip actions installed
                |> List.forall (fun (action, present) ->
                    match action with
                    | SetupAction.Unchanged -> true
                    | SetupAction.Install -> not present
                    | SetupAction.Update
                    | SetupAction.Remove -> present
                    | _ -> false)

            let archiveRequired =
                selection.Enb = SetupAction.Install || selection.Enb = SetupAction.Update

            let archiveSupplied =
                not archiveRequired
                || (selection.EnbArchive |> Option.exists (not << String.IsNullOrWhiteSpace))

            let canStart =
                ModConductor.Persistence.SetupSelection.hasChange selection
                && valid
                && archiveSupplied
                && deployed.PendingReceipt.IsNone
                && (deployed.ActiveGeneration.IsSome || actions |> List.exists (fun action -> action = SetupAction.Install))

            let components =
                [ "SKSE", "skse", installed[0]
                  "ENBSeries", "enb", installed[1]
                  "FNIS", "fnis", installed[2] ]
                |> List.map (fun (name, id, present) ->
                    { Id = id
                      Name = name
                      Status = if present then "Installed" else "Not installed"
                      Detail = ""
                      Installed = present
                      Ready = present
                      Active = false
                      Blocked = false })

            return
                view
                    SkyrimSetupPhase.Available
                    (if not archiveSupplied then "Choose an ENBSeries archive" elif not valid then "Check the selected components" else "")
                    ""
                    components
                    selection
                    false
                    canStart
                    false
                    false
                    false
        }

    let missingFirstRun (binding: GameBinding) =
        let explicitlyMissing =
            binding.NeedsCheck
            && binding.Failure
               |> Option.exists (fun detail ->
                   detail.Contains("first run", StringComparison.OrdinalIgnoreCase))

        match binding.Evidence.Platform with
        | ContextPlatform.Windows -> explicitlyMissing
        | ContextPlatform.Proton ->
            explicitlyMissing
            || (binding.NeedsCheck
                && binding.Failure
                   |> Option.exists (fun detail ->
                       detail.Contains("prefix", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("Proton data", StringComparison.OrdinalIgnoreCase)
                       || detail.Contains("user folder", StringComparison.OrdinalIgnoreCase)))

    let deploymentError =
        function
        | DeploymentError.NotFound -> "The deployment is unavailable."
        | DeploymentError.Busy -> "Wait for the current deployment operation, then select Continue."
        | DeploymentError.Stale -> "The profile changed. Select Refresh and review the new plan."
        | DeploymentError.Cancelled -> "Setup stopped. Select Continue to recover it."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> detail

    let initialDeployment (deployment: DeploymentStatus) action token =
        task {
            match deployment.PendingReceipt with
            | Some id ->
                let! receipt = store.Deployments.Receipt id

                match receipt with
                | Error error -> return Error(deploymentError error)
                | Ok receipt ->
                    let! recovered =
                        store.Deployments.Recover(
                            receipt.Id,
                            receipt.Revision,
                            false,
                            ignore,
                            token
                        )

                    return recovered |> Result.map ignore |> Result.mapError deploymentError
            | None when deployment.ActiveGeneration.IsNone ->
                let! prepared = store.Deployments.Prepare(action, deployment.Sources, ignore, token)

                match prepared with
                | Error error -> return Error(deploymentError error)
                | Ok prepared ->
                    let! activated =
                        store.Deployments.Activate(prepared.Id, deployment.Sources, ignore, token)

                    return activated |> Result.map ignore |> Result.mapError deploymentError
            | None -> return Ok()
        }

    let recoverPending workspace profile (deployment: DeploymentStatus) token =
        task {
            let! enbOperation = store.EnbSetups.ConfigurationOperation(workspace, profile)
            let! fnisStatus = store.FnisSetups.ReadStatus(workspace, profile)

            match enbOperation, fnisStatus with
            | Some _, _ ->
                let! result = dependencies.RecoverEnb workspace profile token

                return
                    if result.Phase = EnbPhase.Failed || result.Phase = EnbPhase.Conflict then
                        Error(result.Status + ". " + result.Detail)
                    else
                        Ok()
            | None, Some status when status.Phase = "recovery" ->
                let! result = dependencies.RecoverFnis workspace profile token

                return
                    if
                        result.Phase = FnisPhase.RecoveryRequired || result.Phase = FnisPhase.Failed
                    then
                        Error(result.Status + ". " + result.Detail)
                    else
                        Ok()
            | None, _ ->
                match deployment.PendingReceipt with
                | None -> return Ok()
                | Some id ->
                    let! receipt = store.Deployments.Receipt id

                    match receipt with
                    | Error error -> return Error(deploymentError error)
                    | Ok receipt ->
                        let! recovered =
                            store.Deployments.Recover(
                                receipt.Id,
                                receipt.Revision,
                                true,
                                ignore,
                                token
                            )

                        return recovered |> Result.map ignore |> Result.mapError deploymentError
        }

    let inspect workspace profile selection (intent: StoredSkyrimSetupIntent option) token =
        task {
            let running =
                intent
                |> Option.exists (fun value -> not value.Cancelled && not value.Completed)

            let! contextResult =
                (store.GameContexts :> IGameContexts).Read(workspace, profile)

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
                        unavailable
                            selection
                            "Skyrim needs its first Steam run"
                            firstRunInstruction
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
                                (deploymentError error)
                    | Ok deployed when deployed.WorkspaceId <> workspace ->
                        return
                            unavailable
                                selection
                                "The selected profile is unavailable"
                                "Select a profile from this workspace."
                    | Ok deployed when not running && not (intent |> Option.exists _.Cancelled) ->
                        return! preview workspace profile selection deployed
                    | Ok deployed ->
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

                        let! deployed =
                            match skseWhilePending with
                            | Some state when
                                state.Phase <> SksePhase.Downloading
                                && state.Phase <> SksePhase.Installing
                                ->
                                task {
                                    let! latest = store.Deployments.Read profile
                                    return latest |> Result.defaultValue deployed
                                }
                            | _ -> Task.FromResult deployed

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
                            let! current = preview workspace profile selection deployed

                            return
                                { current with
                                    Phase = SkyrimSetupPhase.Cancelled
                                    Status = "Skyrim setup is cancelled"
                                    Detail =
                                        if String.IsNullOrWhiteSpace cancelled.CancelDetail then
                                            "Select components to try again."
                                        else
                                            cancelled.CancelDetail }
                        elif
                            skseWhilePending
                            |> Option.exists (fun state ->
                                state.Phase = SksePhase.Downloading
                                || state.Phase = SksePhase.Installing)
                        then
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
                        elif workers.ContainsKey((workspace, profile)) then
                            let workerPhase, workerName, workerStatus, workerDetail =
                                match stage with
                                | "fnis-run" ->
                                    SkyrimSetupPhase.FnisRunning,
                                    "FNIS",
                                    "Updating FNIS output",
                                    ""
                                | _ ->
                                    SkyrimSetupPhase.SettingUpEnb,
                                    "ENBSeries",
                                    "Setting up",
                                    ""

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
                            match recorded with
                            | Some value when stage = "deployment-running" ->
                                let! receipt =
                                    match value.ActionId with
                                    | Some action -> store.Deployments.Receipt action
                                    | None -> Task.FromResult(Error DeploymentError.NotFound)

                                match receipt, deployed.ActiveGeneration with
                                | Ok receipt, Some active when
                                    receipt.Phase = ModConductor.Deployment.DeploymentPhase.Complete
                                    && receipt.Proposed = active
                                    ->
                                    do!
                                        store.SkyrimSetups.Save
                                            { value with
                                                Stage = "skse-start"
                                                ActionId = None }

                                    stage <- "skse-start"
                                | _ -> ()
                            | _ -> ()

                            let! skseState = dependencies.ReadSkse workspace profile
                            let skseReady = skseState.Phase = SksePhase.Ready
                            let! skseStored =
                                store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                            let skseDone =
                                match selection.Skse with
                                | SetupAction.Unchanged -> true
                                | SetupAction.Install -> skseReady
                                | SetupAction.Update -> stage <> "skse-start" && skseReady
                                | SetupAction.Remove -> skseStored.IsNone
                                | _ -> false

                            let skseActive =
                                skseState.Phase = SksePhase.Downloading
                                || skseState.Phase = SksePhase.Installing

                            let skseBlocked =
                                skseState.Phase = SksePhase.Failed
                                || skseState.Phase = SksePhase.Incompatible
                                || skseState.Phase = SksePhase.SourceUnavailable
                                || skseState.Phase = SksePhase.Unavailable

                            let skseComponent =
                                { componentView
                                    "SKSE"
                                    skseState.Status
                                    skseState.Detail
                                    skseReady
                                    skseActive
                                    skseBlocked with
                                    Id = "skse"
                                    Installed = skseStored.IsSome }

                            if not skseDone then
                                let phase =
                                    if skseBlocked && selection.Skse <> SetupAction.Remove then SkyrimSetupPhase.Failed
                                    elif skseActive then SkyrimSetupPhase.SettingUpSkse
                                    else SkyrimSetupPhase.WaitingForSkse

                                return
                                    view
                                        phase
                                        skseState.Status
                                        skseState.Detail
                                        [ skseComponent ]
                                        selection
                                        running
                                        false
                                        (running
                                         && not skseActive
                                         && (selection.Skse = SetupAction.Remove
                                             || skseState.Phase = SksePhase.Available
                                             || skseState.Phase = SksePhase.UpdateAvailable
                                             || skseState.Phase = SksePhase.Failed
                                             || selection.Skse = SetupAction.Update))
                                        skseActive
                                        false
                            else
                                match recorded with
                                | Some value when stage = "skse" || stage = "skse-remove" || stage = "skse-start" ->
                                    do! store.SkyrimSetups.Save { value with Stage = "enb-start" }
                                    stage <- "enb-start"
                                | _ -> ()

                                let! enbStored =
                                    store.EnbSetups.Components(workspace, profile, deployed.ActiveGeneration)

                                let enbInstalled = enbStored |> List.exists (fun item -> item.Kind = "runtime")

                                let! enbState =
                                    if selection.Enb = SetupAction.Unchanged then
                                        Task.FromResult
                                            { Phase = if enbInstalled then EnbPhase.Ready else EnbPhase.Available
                                              Status = if enbInstalled then "Installed" else "Not installed"
                                              Detail = ""
                                              RuntimeVersion = ""
                                              PresetVersion = "" }
                                    else dependencies.ReadEnb workspace profile

                                let enbReady = enbState.Phase = EnbPhase.Ready

                                let enbDone =
                                    match selection.Enb with
                                    | SetupAction.Unchanged -> true
                                    | SetupAction.Install -> enbReady
                                    | SetupAction.Update -> stage <> "enb-start" && enbReady
                                    | SetupAction.Remove -> not enbInstalled
                                    | _ -> false

                                let enbActive =
                                    enbState.Phase = EnbPhase.Validating
                                    || enbState.Phase = EnbPhase.Acquiring
                                    || enbState.Phase = EnbPhase.Installing

                                let enbBlocked =
                                    enbState.Phase = EnbPhase.Blocked
                                    || enbState.Phase = EnbPhase.Failed
                                    || enbState.Phase = EnbPhase.Conflict
                                    || enbState.Phase = EnbPhase.Unavailable

                                let enbComponent =
                                    { componentView
                                        "ENBSeries"
                                        enbState.Status
                                        enbState.Detail
                                        enbReady
                                        enbActive
                                        enbBlocked with
                                        Id = "enb"
                                        Installed = enbInstalled }

                                if not enbDone then
                                    let waiting = enbState.Phase = EnbPhase.WaitingForArchive

                                    return
                                        view
                                            (if waiting then
                                                 SkyrimSetupPhase.WaitingForEnbArchive
                                             else
                                                 SkyrimSetupPhase.SettingUpEnb)
                                            enbState.Status
                                            enbState.Detail
                                            [ skseComponent; enbComponent ]
                                            selection
                                            running
                                            false
                                            (running
                                             && not enbActive
                                             && (selection.Enb = SetupAction.Remove
                                                 || selection.Enb = SetupAction.Update
                                                 || enbState.Phase = EnbPhase.Available
                                                 || enbState.Phase = EnbPhase.Failed))
                                            enbActive
                                            false
                                else
                                    match recorded with
                                    | Some value when stage = "enb" || stage = "enb-remove" || stage = "enb-start" ->
                                        let nextStage =
                                            if selection.Fnis <> SetupAction.Unchanged then "fnis-start" else "readiness"

                                        do! store.SkyrimSetups.Save { value with Stage = nextStage }
                                        stage <- nextStage
                                    | _ -> ()

                                    let baseComponents = [ skseComponent; enbComponent ]

                                    let! fnisStored =
                                        store.FnisSetups.ReadExact(workspace, profile, deployed.ActiveGeneration)

                                    let! fnisState, output =
                                        if selection.Fnis <> SetupAction.Unchanged then
                                            task {
                                                let! value = dependencies.ReadFnis workspace profile

                                                if
                                                    selection.Fnis <> SetupAction.Remove
                                                    && (value.Phase = FnisPhase.Ready
                                                        || value.Phase = FnisPhase.UpdateAvailable
                                                        || value.Phase = FnisPhase.SourceUnavailable)
                                                then
                                                    let! inspected =
                                                        dependencies.InspectFnis
                                                            workspace
                                                            profile
                                                            token

                                                    return Some value, Result.toOption inspected
                                                else
                                                    return Some value, None
                                            }
                                        else
                                            task { return None, None }

                                    let fnisReady =
                                        if selection.Fnis = SetupAction.Unchanged then true
                                        elif selection.Fnis = SetupAction.Remove then fnisStored.IsNone
                                        elif selection.Fnis = SetupAction.Update && stage = "fnis-start" then false
                                        else
                                            match fnisState, output with
                                            | Some state, Some output ->
                                                state.Phase = FnisPhase.Ready
                                                && output.Phase = ModConductor.Fnis.FnisOutputPhase.Current
                                                && (stage <> "fnis-run"
                                                    || (recorded
                                                        |> Option.bind _.ActionId
                                                        |> Option.exists (fun action ->
                                                            output.LatestRunId = Some action)))
                                            | _ -> false

                                    let fnisActive =
                                        match fnisState, output with
                                        | Some state, _ when
                                            state.Phase = FnisPhase.Downloading
                                            || state.Phase = FnisPhase.Installing
                                            ->
                                            true
                                        | _, Some output when
                                            output.Phase = ModConductor.Fnis.FnisOutputPhase.Running
                                            ->
                                            true
                                        | _ -> false

                                    let fnisBlocked =
                                        match fnisState, output with
                                        | Some state, _ ->
                                            state.Phase = FnisPhase.Failed
                                            || state.Phase = FnisPhase.RecoveryRequired
                                            || state.Phase = FnisPhase.SourceUnavailable
                                            || state.Phase = FnisPhase.Unavailable
                                            || (output
                                                |> Option.exists (fun value ->
                                                    value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed
                                                    || value.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
                                                    || value.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned))
                                        | None, _ -> false

                                    let components =
                                        match fnisState with
                                        | None -> baseComponents
                                        | Some state ->
                                            let status, detail =
                                                match output with
                                                | Some output -> output.Status, output.Detail
                                                | None -> state.Status, state.Detail

                                            baseComponents
                                            @ [ { componentView
                                                    "FNIS"
                                                    status
                                                    detail
                                                    fnisReady
                                                    fnisActive
                                                    fnisBlocked with
                                                    Id = "fnis"
                                                    Installed = fnisStored.IsSome } ]

                                    let fnisSetupReady =
                                        if selection.Fnis = SetupAction.Remove then fnisStored.IsNone
                                        else
                                            fnisState
                                            |> Option.exists (fun value -> value.Phase = FnisPhase.Ready)

                                    let nextFnisStage =
                                        if selection.Fnis = SetupAction.Remove || fnisReady then "readiness"
                                        else "fnis-run"

                                    match recorded with
                                    | Some value when
                                        (stage = "fnis-install" || stage = "fnis-remove")
                                        && fnisSetupReady
                                        ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    Stage = nextFnisStage
                                                    ActionId = None }

                                        stage <- nextFnisStage
                                    | Some value when stage = "fnis-run" && fnisReady ->
                                        do!
                                            store.SkyrimSetups.Save
                                                { value with
                                                    Stage = "readiness"
                                                    ActionId = None }

                                        stage <- "readiness"
                                    | _ -> ()

                                    if not fnisReady then
                                        let stale =
                                            (stage = "fnis-run" && not fnisReady)
                                            || (output
                                                |> Option.exists (fun value ->
                                                    value.Phase
                                                    <> ModConductor.Fnis.FnisOutputPhase.Current
                                                    && value.Phase
                                                       <> ModConductor.Fnis.FnisOutputPhase.Running))

                                        return
                                            view
                                                (if running then
                                                     if
                                                         output
                                                         |> Option.exists (fun value ->
                                                             value.Phase = ModConductor.Fnis.FnisOutputPhase.Running)
                                                     then
                                                         SkyrimSetupPhase.FnisRunning
                                                     elif fnisBlocked then
                                                         SkyrimSetupPhase.Failed
                                                     elif stale then
                                                         SkyrimSetupPhase.FnisStale
                                                     else
                                                         SkyrimSetupPhase.SettingUpFnis
                                                 else
                                                     SkyrimSetupPhase.Available)
                                                (components |> List.last).Status
                                                (components |> List.last).Detail
                                                components
                                                selection
                                                running
                                                (not running)
                                                (running && not fnisActive)
                                                fnisActive
                                                false
                                    else
                                        let! pluginPreflight =
                                            dependencies.PluginPreflight workspace profile token

                                        let! launch = dependencies.ReadLaunch workspace profile

                                        let launchReady, launchStatus, launchDetail =
                                            match pluginPreflight, launch with
                                            | Error(ProfileDataError.Invalid detail), _
                                            | Error(ProfileDataError.Unavailable detail), _
                                            | Error(ProfileDataError.Conflict detail), _ ->
                                                false, "Plugin order needs attention", detail
                                            | Error ProfileDataError.Busy, _ ->
                                                false,
                                                "Plugin order is busy",
                                                "Wait for the current profile operation, then select Refresh."
                                            | Error _, _ ->
                                                false,
                                                "Plugin order needs attention",
                                                "Refresh the plugins before playing."
                                            | Ok(), Ok state when
                                                state.Problem.IsNone && state.Runtime <> ""
                                                ->
                                                true,
                                                "Play is ready",
                                                ""
                                            | Ok(), Ok state ->
                                                false,
                                                "Play needs attention",
                                                state.Problem
                                                |> Option.defaultValue
                                                    "Refresh the selected launch context."
                                            | Ok(), Error(ExecutableError.Unavailable detail)
                                            | Ok(), Error(ExecutableError.Invalid detail) ->
                                                false, "Play needs attention", detail
                                            | Ok(), Error _ ->
                                                false,
                                                "Play needs attention",
                                                "Refresh the selected deployment and launch context."

                                        let components =
                                            components
                                            @ [ componentView
                                                    "Play"
                                                    launchStatus
                                                    launchDetail
                                                    launchReady
                                                    false
                                                    (not launchReady) ]

                                        return
                                            view
                                                (if launchReady then
                                                     SkyrimSetupPhase.Ready
                                                 else
                                                     SkyrimSetupPhase.Failed)
                                                (if launchReady then
                                                     "Skyrim setup is ready"
                                                 else
                                                     launchStatus)
                                                (if launchReady then
                                                     ""
                                                 else
                                                     launchDetail)
                                                components
                                                selection
                                                running
                                                false
                                                (running && launchReady)
                                                false
                                                launchReady
        }

    let completeCancellation workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let key = workspace, profile

            match workers.TryGetValue key with
            | true, cancellation -> cancellation.Cancel()
            | _ -> ()

            let! childResult =
                task {
                    match intent.Stage with
                    | "enb-start"
                    | "enb-wait"
                    | "enb" ->
                        let! result = dependencies.CancelEnb workspace profile

                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = EnbPhase.Validating
                                || result.Phase = EnbPhase.Acquiring
                                || result.Phase = EnbPhase.Installing
                                || result.Phase = EnbPhase.Failed
                                || result.Phase = EnbPhase.Conflict
                            then
                                Error detail
                            else
                                Ok detail
                    | "skse-start"
                    | "skse" ->
                        let! result = dependencies.CancelSkse workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = SksePhase.Downloading
                                || result.Phase = SksePhase.Installing
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-install" ->
                        let! result = dependencies.CancelFnis workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = FnisPhase.Downloading
                                || result.Phase = FnisPhase.Installing
                                || result.Phase = FnisPhase.RecoveryRequired
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-run" ->
                        let! result = dependencies.CancelFnisRun workspace profile

                        return
                            match result with
                            | Ok value when value.Phase = ModConductor.Fnis.FnisOutputPhase.Running ->
                                Error(value.Status + ". " + value.Detail)
                            | Ok value -> Ok(value.Status + ". " + value.Detail)
                            | Error error -> Error("FNIS cancellation result: " + string error)
                    | _ -> return Ok "No child operation remained active."
                }

            let! deployed = store.Deployments.Read profile

            let! recovered =
                match deployed with
                | Ok value when value.PendingReceipt.IsSome ->
                    recoverPending workspace profile value token
                | _ -> Task.FromResult(Ok())

            match childResult, recovered with
            | Error childDetail, Error recoveryDetail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = childDetail + " " + recoveryDetail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.Selection (Some pending) token
            | Error detail, Ok()
            | Ok _, Error detail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = detail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.Selection (Some pending) token
            | Ok childDetail, Ok() ->
                let cancelled =
                    { intent with
                        CancelRequested = false
                        Cancelled = true
                        Completed = false
                        Stage = "cancelled"
                        ActionId = None
                        Selection = { intent.Selection with EnbArchive = None }
                        CancelDetail = childDetail }

                do! store.SkyrimSetups.Save cancelled
                return! inspect workspace profile ModConductor.Persistence.SetupSelection.none (Some cancelled) token
        }

    let advance workspace profile (intent: StoredSkyrimSetupIntent) retryFailed token =
        task {
            let! before = inspect workspace profile intent.Selection (Some intent) token

            match before.Phase with
            | SkyrimSetupPhase.Failed when not retryFailed -> return before
            | SkyrimSetupPhase.PreparingDeployment
            | SkyrimSetupPhase.RecoveryRequired ->
                let! deployment = store.Deployments.Read profile

                match deployment with
                | Error error ->
                    return
                        { before with
                            Phase = SkyrimSetupPhase.Failed
                            Status = "The first deployment could not be prepared"
                            Detail = deploymentError error
                            Active = false
                            CanContinue = true }
                | Ok deployment ->
                    let running =
                        if deployment.ActiveGeneration.IsNone then
                            { intent with
                                Stage = "deployment-running"
                                ActionId = Some(intent.ActionId |> Option.defaultWith Guid.NewGuid) }
                        else
                            intent

                    if deployment.ActiveGeneration.IsNone then
                        do! store.SkyrimSetups.Save running

                    let! result =
                        if deployment.ActiveGeneration.IsNone then
                            initialDeployment deployment running.ActionId.Value token
                        else
                            recoverPending workspace profile deployment token

                    match result with
                    | Error detail ->
                        return
                            { before with
                                Phase = SkyrimSetupPhase.Failed
                                Status = "The first deployment could not be prepared"
                                Detail = detail
                                Active = false
                                CanContinue = true }
                    | Ok() ->
                        return! inspect workspace profile intent.Selection (Some running) token
            | SkyrimSetupPhase.WaitingForSkse when before.CanContinue ->
                let running =
                    { intent with
                        Stage = if intent.Selection.Skse = SetupAction.Remove then "skse-remove" else "skse" }

                do! store.SkyrimSetups.Save running

                let! _ =
                    if intent.Selection.Skse = SetupAction.Remove then
                        dependencies.RemoveSkse workspace profile token
                    else
                        dependencies.StartSkse workspace profile

                return! inspect workspace profile running.Selection (Some running) token
            | SkyrimSetupPhase.SettingUpEnb when before.CanContinue ->
                if intent.Selection.Enb = SetupAction.Remove then
                    let running = { intent with Stage = "enb-remove" }
                    do! store.SkyrimSetups.Save running
                    let! _ = dependencies.RemoveEnb workspace profile token
                    return! inspect workspace profile running.Selection (Some running) token
                else
                    let archive =
                        intent.Selection.EnbArchive
                        |> Option.defaultWith (fun () -> invalidOp "Choose an ENBSeries archive.")

                    let operation = Guid.NewGuid()
                    let running =
                        { intent with
                            Stage = "enb"
                            ActionId = Some operation }

                    do! store.SkyrimSetups.Save running
                    startWorker workspace profile (fun childToken ->
                        dependencies.SelectEnb workspace profile operation archive childToken)
                    |> ignore

                    return! inspect workspace profile running.Selection (Some running) token
            | SkyrimSetupPhase.SettingUpFnis when before.CanContinue ->
                let running =
                    { intent with
                        Stage = if intent.Selection.Fnis = SetupAction.Remove then "fnis-remove" else "fnis-install" }

                do! store.SkyrimSetups.Save running

                let! _ =
                    if intent.Selection.Fnis = SetupAction.Remove then
                        dependencies.RemoveFnis workspace profile token
                    elif intent.Selection.Fnis = SetupAction.Update then
                        dependencies.UpdateFnis workspace profile
                    else
                        task {
                            let! current = dependencies.ReadFnis workspace profile

                            if current.Phase = FnisPhase.RecoveryRequired then
                                return! dependencies.RecoverFnis workspace profile token
                            else
                                return! dependencies.InstallFnis workspace profile
                        }

                return! inspect workspace profile running.Selection (Some running) token
            | SkyrimSetupPhase.FnisStale when before.CanContinue ->
                let run = Guid.NewGuid()

                let running =
                    { intent with
                        Stage = "fnis-run"
                        ActionId = Some run }

                do! store.SkyrimSetups.Save running

                startWorker workspace profile (fun childToken ->
                    dependencies.RunFnis
                        { Id = run
                          WorkspaceId = workspace
                          ProfileId = profile }
                        childToken)
                |> ignore

                return! inspect workspace profile intent.Selection (Some running) token
            | SkyrimSetupPhase.Failed when before.CanContinue ->
                let! deployment = store.Deployments.Read profile

                let! output =
                    if intent.Selection.Fnis <> SetupAction.Unchanged then
                        task {
                            let! inspected = dependencies.InspectFnis workspace profile token
                            return Result.toOption inspected
                        }
                    else
                        task { return None }

                let! enbState = dependencies.ReadEnb workspace profile
                let! fnisState = dependencies.ReadFnis workspace profile
                let! skseState = dependencies.ReadSkse workspace profile

                if
                    output
                    |> Option.exists (fun value ->
                        value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
                        || value.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned)
                then
                    let run = Guid.NewGuid()

                    let running =
                        { intent with
                            Stage = "fnis-run"
                            ActionId = Some run }

                    do! store.SkyrimSetups.Save running

                    startWorker workspace profile (fun childToken ->
                        dependencies.RunFnis
                            { Id = run
                              WorkspaceId = workspace
                              ProfileId = profile }
                            childToken)
                    |> ignore

                    return! inspect workspace profile intent.Selection (Some running) token
                elif
                    deployment |> Result.toOption |> Option.bind _.PendingReceipt |> Option.isSome
                    && (enbState.Phase = EnbPhase.Failed || enbState.Phase = EnbPhase.Conflict)
                then
                    let! _ = dependencies.RecoverEnb workspace profile token
                    return! inspect workspace profile intent.Selection (Some intent) token
                elif fnisState.Phase = FnisPhase.RecoveryRequired then
                    let! _ = dependencies.RecoverFnis workspace profile token
                    return! inspect workspace profile intent.Selection (Some intent) token
                elif
                    skseState.Phase = SksePhase.Failed
                    || skseState.Phase = SksePhase.UpdateAvailable
                then
                    let! _ = dependencies.StartSkse workspace profile
                    return! inspect workspace profile intent.Selection (Some intent) token
                elif fnisState.Phase = FnisPhase.Failed then
                    let! _ = dependencies.InstallFnis workspace profile
                    return! inspect workspace profile intent.Selection (Some intent) token
                else
                    return before
            | SkyrimSetupPhase.Ready ->
                do!
                    store.SkyrimSetups.Save
                        { intent with
                            Completed = true
                            Stage = "complete"
                            ActionId = None
                            Selection = { intent.Selection with EnbArchive = None }
                            CancelRequested = false
                            CancelDetail = "" }

                return
                    { before with
                        CanCancel = false }
            | _ -> return before
        }

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
            SkyrimSetupDependencies.production skse enb fnis execution launches pluginOrders
        )

    member _.Read(workspace, profile, (selection: ModConductor.Persistence.SetupSelection), token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)
            let selected = intent |> Option.filter (fun item -> not item.Completed && not item.Cancelled) |> Option.map _.Selection |> Option.defaultValue selection
            let! current = inspect workspace profile selected intent token

            return current
        }

    member _.Start(workspace, profile, (selection: ModConductor.Persistence.SetupSelection), token) =
        task {
            let! existing = store.SkyrimSetups.Read(workspace, profile)

            match existing with
            | Some intent when intent.CancelRequested ->
                return! inspect workspace profile intent.Selection (Some intent) token
            | Some intent when
                not intent.Cancelled
                && not intent.Completed
                && selection = intent.Selection
                ->
                return! advance workspace profile intent true token
            | _ ->
                let! current =
                    match existing with
                    | Some intent when not intent.Cancelled && not intent.Completed ->
                        inspect workspace profile intent.Selection (Some intent) token
                    | _ -> inspect workspace profile selection existing token

                if current.Active || current.Phase = SkyrimSetupPhase.RecoveryRequired then
                    return current
                else
                    let! available = inspect workspace profile selection None token

                    if not available.CanStart then
                        return available
                    else
                        let! deployed = store.Deployments.Read profile

                        match deployed with
                        | Error error ->
                            return unavailable selection "The deployment is unavailable" (deploymentError error)
                        | Ok deployment when deployment.WorkspaceId <> workspace ->
                            return unavailable selection "The selected profile is unavailable" "Select a profile from this workspace."
                        | Ok deployment ->
                            let initialStage =
                                if deployment.ActiveGeneration.IsNone then "deployment" else "skse-start"

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
                            return! advance workspace profile next true token
        }

    member _.Continue(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | Some value when value.CancelRequested ->
                return! completeCancellation workspace profile value token
            | Some value -> return! advance workspace profile value false token
            | None -> return! inspect workspace profile ModConductor.Persistence.SetupSelection.none None token
        }

    member _.Cancel(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | None -> return! inspect workspace profile ModConductor.Persistence.SetupSelection.none None token
            | Some intent when intent.Cancelled || intent.Completed ->
                return! inspect workspace profile ModConductor.Persistence.SetupSelection.none (Some intent) token
            | Some intent ->
                let requested =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = "Cancellation was requested." }

                do! store.SkyrimSetups.Save requested
                return! completeCancellation workspace profile requested token
        }

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()

            for key in workers.Keys do
                match workers.TryRemove key with
                | true, cancellation ->
                    cancellation.Cancel()
                    cancellation.Dispose()
                | _ -> ()

            lifetime.Dispose()

type internal SkyrimSetupService(coordinator: SkyrimSetupCoordinator) =
    inherit SkyrimSetupOperations.SkyrimSetupOperationsBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    let selectionFromWire (value: ModConductor.Protocol.V1.SkyrimSetupSelection) =
        let choice (action: ModConductor.Protocol.V1.SkyrimSetupAction) =
            match action with
            | ModConductor.Protocol.V1.SkyrimSetupAction.Install -> SetupAction.Install
            | ModConductor.Protocol.V1.SkyrimSetupAction.Remove -> SetupAction.Remove
            | ModConductor.Protocol.V1.SkyrimSetupAction.Update -> SetupAction.Update
            | _ -> SetupAction.Unchanged

        if isNull value then ModConductor.Persistence.SetupSelection.none
        else
            { Skse = choice value.Skse
              Enb = choice value.Enb
              Fnis = choice value.Fnis
              EnbArchive = if String.IsNullOrWhiteSpace value.EnbArchivePath then None else Some value.EnbArchivePath }

    let selectionWire (value: ModConductor.Persistence.SetupSelection) =
        ModConductor.Protocol.V1.SkyrimSetupSelection(
            Skse = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Skse),
            Enb = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Enb),
            Fnis = enum<ModConductor.Protocol.V1.SkyrimSetupAction> (int value.Fnis),
            EnbArchivePath = (value.EnbArchive |> Option.defaultValue "")
        )

    let wire (value: SkyrimSetupView) =
        let result =
            SkyrimSetupState(
                Phase = value.Phase,
                Status = value.Status,
                Detail = value.Detail,
                Selection = selectionWire value.Selection,
                CanStart = value.CanStart,
                CanContinue = value.CanContinue,
                Active = value.Active,
                CanCancel = value.CanCancel,
                Ready = value.Ready
            )

        result.Components.AddRange(
            value.Components
            |> Seq.map (fun item ->
                SkyrimSetupComponent(
                    Id = item.Id,
                    Name = item.Name,
                    Status = item.Status,
                    Detail = item.Detail,
                    Installed = item.Installed,
                    Ready = item.Ready,
                    Active = item.Active,
                    Blocked = item.Blocked
                ))
        )

        result

    override _.ReadSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Read(workspace, profile, selectionFromWire request.Selection, context.CancellationToken)

            return wire value
        }

    override _.StartSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Start(
                    workspace,
                    profile,
                    selectionFromWire request.Selection,
                    context.CancellationToken
                )

            return wire value
        }

    override _.ContinueSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Continue(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.CancelSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value = coordinator.Cancel(workspace, profile, context.CancellationToken)
            return wire value
        }

    override _.OpenSkyrimSetupPage(request, context) =
        task {
            let address =
                match request.ComponentId with
                | "skse" -> "https://skse.silverlock.org/"
                | "enb" -> ModConductor.Enb.EnbCatalogue.OfficialPage
                | "fnis" -> ModConductor.Fnis.FnisCatalogue.Source
                | _ -> invalidArg "component_id" "The selected component is unavailable."

            do! ModConductor.Desktop.WebLink.openBrowser(Uri address, context.CancellationToken)
            return SkyrimSetupPageReply(Opened = true)
        }
