namespace ModConductor.Engine

open System
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1

type SkyrimSetupComponentView =
    { Name: string
      Status: string
      Detail: string
      Ready: bool
      Active: bool
      Blocked: bool }

type SkyrimSetupChangeView = { Title: string; Detail: string }

type SkyrimSetupView =
    { Phase: SkyrimSetupPhase
      Status: string
      Detail: string
      PlanToken: string
      Changes: SkyrimSetupChangeView list
      Components: SkyrimSetupComponentView list
      IncludeFnis: bool
      ConsentRecorded: bool
      CanStart: bool
      CanContinue: bool
      CanSelectEnbArchive: bool
      Active: bool
      Ready: bool }

type SkyrimSetupCoordinator
    (
        store: OperationStore,
        skse: SkseCoordinator,
        enb: EnbCoordinator,
        fnis: FnisCoordinator,
        execution: IFnisExecution,
        launches: IGameLaunching,
        pluginOrders: IProfilePluginOrders
    ) =
    let firstRunInstruction =
        "Start Skyrim once through Steam. Close it, then select Refresh."

    let planToken
        (workspace: Guid)
        (profile: Guid)
        includeFnis
        contextRevision
        (deployment: DeploymentStatus)
        =
        let input =
            String.concat
                ":"
                [ "mc-skyrim-setup-v1"
                  workspace.ToString("N")
                  profile.ToString("N")
                  string includeFnis
                  string contextRevision
                  SourceIdentity.token deployment.Sources
                  deployment.ActiveGeneration
                  |> Option.map (fun id -> id.ToString("N"))
                  |> Option.defaultValue "" ]

        SHA256.HashData(Encoding.UTF8.GetBytes input) |> Convert.ToHexStringLower

    let componentView name status detail ready active blocked =
        { Name = name
          Status = status
          Detail = detail
          Ready = ready
          Active = active
          Blocked = blocked }

    let changes includeFnis hasDeployment =
        [ if not hasDeployment then
              { Title = "Prepare the first deployment"
                Detail =
                  "Create and activate the initial owned deployment before component files are installed." }

          { Title = "Set up SKSE"
            Detail = "Install the matching SKSE version in the selected profile." }
          { Title = "Set up Lean ENB"
            Detail =
              "Wait for the ENBSeries archive that you download from the author page, then install Lean ENB and its companion." }

          if includeFnis then
              { Title = "Set up and run FNIS"
                Detail =
                  "Install FNIS and update the active profile output when its animation inputs are stale." }

          { Title = "Check Play readiness"
            Detail =
              "Use the selected installation, deployment, plugin order and launch checks. Other profiles, foreign files and saves stay unchanged." } ]

    let view
        phase
        status
        detail
        token
        planned
        components
        includeFnis
        consent
        start
        continueSetup
        select
        active
        ready
        =
        { Phase = phase
          Status = status
          Detail = detail
          PlanToken = token
          Changes = planned
          Components = components
          IncludeFnis = includeFnis
          ConsentRecorded = consent
          CanStart = start
          CanContinue = continueSetup
          CanSelectEnbArchive = select
          Active = active
          Ready = ready }

    let unavailable includeFnis status detail =
        view
            SkyrimSetupPhase.Unavailable
            status
            detail
            ""
            []
            [ componentView "Skyrim installation" status detail false false true ]
            includeFnis
            false
            false
            false
            false
            false
            false

    let missingFirstRun (binding: GameBinding) =
        let missing =
            function
            | Location.Located(_, false) -> true
            | _ -> false

        match binding.Evidence.Platform with
        | ContextPlatform.Windows ->
            missing binding.Evidence.Locations.Documents
            && missing binding.Evidence.Locations.LocalAppData
        | ContextPlatform.Proton ->
            binding.Proton.IsSome
            && (binding.Evidence.Proton.IsNone
                || (binding.NeedsCheck
                    && binding.Failure
                       |> Option.exists (fun detail ->
                           detail.Contains("prefix", StringComparison.OrdinalIgnoreCase)
                           || detail.Contains("Proton data", StringComparison.OrdinalIgnoreCase)
                           || detail.Contains("user folder", StringComparison.OrdinalIgnoreCase))))

    let deploymentError =
        function
        | DeploymentError.NotFound -> "The deployment is unavailable."
        | DeploymentError.Busy -> "Wait for the current deployment operation, then select Continue."
        | DeploymentError.Stale -> "The profile changed. Select Refresh and review the new plan."
        | DeploymentError.Cancelled -> "Setup stopped. Select Continue to recover it."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> detail

    let initialDeployment (deployment: DeploymentStatus) token =
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
                let preparedId = Guid.NewGuid()

                let! prepared =
                    store.Deployments.Prepare(preparedId, deployment.Sources, ignore, token)

                match prepared with
                | Error error -> return Error(deploymentError error)
                | Ok prepared ->
                    let! activated =
                        store.Deployments.Activate(prepared.Id, deployment.Sources, ignore, token)

                    return activated |> Result.map ignore |> Result.mapError deploymentError
            | None -> return Ok()
        }

    let inspect workspace profile includeFnis consent token =
        task {
            let! contextResult = (store.GameContexts :> IGameContexts).Read workspace

            match contextResult with
            | Error _ ->
                return
                    unavailable
                        includeFnis
                        "Skyrim setup is unavailable"
                        "Select and refresh the Skyrim Special Edition Steam installation."
            | Ok context ->
                match context.Binding with
                | Some binding when missingFirstRun binding ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim needs its first Steam run"
                            firstRunInstruction
                | None ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim setup is unavailable"
                            "Select and refresh the Skyrim Special Edition Steam installation."
                | Some binding when
                    binding.NeedsCheck
                    || not binding.Evidence.Valid
                    || binding.Evidence.DefinitionId <> Skyrim.definition.Id
                    ->
                    return
                        unavailable
                            includeFnis
                            "Skyrim setup is unavailable"
                            "Refresh the selected Skyrim Special Edition Steam installation."
                | Some _ ->
                    let! deployed = store.Deployments.Read profile

                    match deployed with
                    | Error error ->
                        return
                            unavailable
                                includeFnis
                                "The deployment is unavailable"
                                (deploymentError error)
                    | Ok deployed when deployed.WorkspaceId <> workspace ->
                        return
                            unavailable
                                includeFnis
                                "The selected profile is unavailable"
                                "Select a profile from this workspace."
                    | Ok deployed ->
                        let tokenValue =
                            planToken workspace profile includeFnis context.Revision deployed

                        let planned = changes includeFnis deployed.ActiveGeneration.IsSome

                        if deployed.ActiveGeneration.IsNone then
                            return
                                view
                                    (if consent then
                                         SkyrimSetupPhase.PreparingDeployment
                                     else
                                         SkyrimSetupPhase.NeedsConsent)
                                    (if deployed.PendingReceipt.IsSome then
                                         "The first deployment needs recovery"
                                     elif consent then
                                         "The first deployment is ready to prepare"
                                     else
                                         "Review the Skyrim setup changes")
                                    (if deployed.PendingReceipt.IsSome then
                                         "Select Continue to finish the recorded deployment."
                                     else
                                         "Mod Conductor prepares the owned deployment before it installs component files.")
                                    tokenValue
                                    planned
                                    [ componentView
                                          "Deployment"
                                          (if deployed.PendingReceipt.IsSome then
                                               "Recovery required"
                                           else
                                               "Not prepared")
                                          "The active profile needs an owned deployment."
                                          false
                                          false
                                          deployed.PendingReceipt.IsSome ]
                                    includeFnis
                                    consent
                                    (not consent && deployed.PendingReceipt.IsNone)
                                    consent
                                    false
                                    false
                                    false
                        else
                            let! skseState = skse.Read(workspace, profile)
                            let skseReady = skseState.Phase = SksePhase.Ready

                            let skseActive =
                                skseState.Phase = SksePhase.Downloading
                                || skseState.Phase = SksePhase.Installing

                            let skseBlocked =
                                skseState.Phase = SksePhase.Failed
                                || skseState.Phase = SksePhase.Incompatible
                                || skseState.Phase = SksePhase.SourceUnavailable
                                || skseState.Phase = SksePhase.Unavailable

                            let skseComponent =
                                componentView
                                    "SKSE"
                                    skseState.Status
                                    skseState.Detail
                                    skseReady
                                    skseActive
                                    skseBlocked

                            if not skseReady then
                                let phase =
                                    if skseBlocked then SkyrimSetupPhase.Failed
                                    elif skseActive then SkyrimSetupPhase.SettingUpSkse
                                    else SkyrimSetupPhase.WaitingForSkse

                                return
                                    view
                                        (if consent then phase else SkyrimSetupPhase.NeedsConsent)
                                        skseState.Status
                                        skseState.Detail
                                        tokenValue
                                        planned
                                        [ skseComponent ]
                                        includeFnis
                                        consent
                                        (not consent)
                                        (consent
                                         && (skseState.Phase = SksePhase.Available
                                             || skseState.Phase = SksePhase.UpdateAvailable
                                             || skseState.Phase = SksePhase.Failed))
                                        false
                                        skseActive
                                        false
                            else
                                let! enbState = enb.Read(workspace, profile)
                                let enbReady = enbState.Phase = EnbPhase.Ready

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
                                    componentView
                                        "Lean ENB"
                                        enbState.Status
                                        enbState.Detail
                                        enbReady
                                        enbActive
                                        enbBlocked

                                if not enbReady then
                                    let waiting = enbState.Phase = EnbPhase.WaitingForArchive

                                    return
                                        view
                                            (if consent then
                                                 if waiting then
                                                     SkyrimSetupPhase.WaitingForEnbArchive
                                                 else
                                                     SkyrimSetupPhase.SettingUpEnb
                                             else
                                                 SkyrimSetupPhase.NeedsConsent)
                                            enbState.Status
                                            enbState.Detail
                                            tokenValue
                                            planned
                                            [ skseComponent; enbComponent ]
                                            includeFnis
                                            consent
                                            (not consent)
                                            (consent
                                             && (enbState.Phase = EnbPhase.Available
                                                 || (enbState.Phase = EnbPhase.Failed
                                                     && deployed.PendingReceipt.IsSome)))
                                            (consent
                                             && (waiting || enbState.Phase = EnbPhase.Failed))
                                            enbActive
                                            false
                                else
                                    let baseComponents = [ skseComponent; enbComponent ]

                                    let! fnisState, output =
                                        if includeFnis then
                                            task {
                                                let! value = fnis.Read(workspace, profile)

                                                if
                                                    value.Phase = FnisPhase.Ready
                                                    || value.Phase = FnisPhase.UpdateAvailable
                                                    || value.Phase = FnisPhase.SourceUnavailable
                                                then
                                                    let! inspected =
                                                        execution.Inspect(workspace, profile, token)

                                                    return Some value, Result.toOption inspected
                                                else
                                                    return Some value, None
                                            }
                                        else
                                            task { return None, None }

                                    let fnisReady =
                                        match fnisState, output with
                                        | None, _ -> true
                                        | Some state, Some output ->
                                            state.Phase = FnisPhase.Ready
                                            && output.Phase = ModConductor.Fnis.FnisOutputPhase.Current
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
                                            @ [ componentView
                                                    "FNIS"
                                                    status
                                                    detail
                                                    fnisReady
                                                    fnisActive
                                                    fnisBlocked ]

                                    if not fnisReady then
                                        let stale =
                                            output
                                            |> Option.exists (fun value ->
                                                value.Phase
                                                <> ModConductor.Fnis.FnisOutputPhase.Current
                                                && value.Phase
                                                   <> ModConductor.Fnis.FnisOutputPhase.Running)

                                        return
                                            view
                                                (if consent then
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
                                                     SkyrimSetupPhase.NeedsConsent)
                                                (components |> List.last).Status
                                                (components |> List.last).Detail
                                                tokenValue
                                                planned
                                                components
                                                includeFnis
                                                consent
                                                (not consent)
                                                (consent && not fnisActive)
                                                false
                                                fnisActive
                                                false
                                    else
                                        let! pluginPreflight =
                                            pluginOrders.PreflightForLaunch(
                                                workspace,
                                                profile,
                                                token
                                            )

                                        let! launch = launches.Read(workspace, profile)

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
                                                "The selected deployment, plugin order and "
                                                + state.Runtime
                                                + " launch context passed their checks."
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
                                                     "Play uses the checked SKSE, ENB, optional FNIS output and selected runtime."
                                                 else
                                                     launchDetail)
                                                tokenValue
                                                planned
                                                components
                                                includeFnis
                                                consent
                                                false
                                                false
                                                false
                                                false
                                                launchReady
        }

    let advance workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let! before = inspect workspace profile intent.IncludeFnis true token

            match before.Phase with
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
                    let! result = initialDeployment deployment token

                    match result with
                    | Error detail ->
                        return
                            { before with
                                Phase = SkyrimSetupPhase.Failed
                                Status = "The first deployment could not be prepared"
                                Detail = detail
                                Active = false
                                CanContinue = true }
                    | Ok() -> return! inspect workspace profile intent.IncludeFnis true token
            | SkyrimSetupPhase.WaitingForSkse when before.CanContinue ->
                let! _ = skse.Start(workspace, profile)
                return! inspect workspace profile intent.IncludeFnis true token
            | SkyrimSetupPhase.SettingUpEnb when before.CanContinue ->
                let! _ = enb.OpenAuthorPage(workspace, profile)
                return! inspect workspace profile intent.IncludeFnis true token
            | SkyrimSetupPhase.SettingUpFnis when before.CanContinue ->
                let! current = fnis.Read(workspace, profile)

                let! _ =
                    if current.Phase = FnisPhase.UpdateAvailable then
                        fnis.Update(workspace, profile)
                    elif current.Phase = FnisPhase.RecoveryRequired then
                        fnis.Recover(workspace, profile, token)
                    else
                        fnis.Install(workspace, profile)

                return! inspect workspace profile intent.IncludeFnis true token
            | SkyrimSetupPhase.FnisStale when before.CanContinue ->
                let! _ =
                    execution.Run(
                        { Id = Guid.NewGuid()
                          WorkspaceId = workspace
                          ProfileId = profile },
                        token
                    )

                return! inspect workspace profile intent.IncludeFnis true token
            | SkyrimSetupPhase.Failed when before.CanContinue ->
                let! deployment = store.Deployments.Read profile
                let! enbState = enb.Read(workspace, profile)
                let! fnisState = fnis.Read(workspace, profile)
                let! skseState = skse.Read(workspace, profile)

                if
                    deployment |> Result.toOption |> Option.bind _.PendingReceipt |> Option.isSome
                    && (enbState.Phase = EnbPhase.Failed || enbState.Phase = EnbPhase.Conflict)
                then
                    let! _ = enb.Recover(workspace, profile, token)
                    return! inspect workspace profile intent.IncludeFnis true token
                elif fnisState.Phase = FnisPhase.RecoveryRequired then
                    let! _ = fnis.Recover(workspace, profile, token)
                    return! inspect workspace profile intent.IncludeFnis true token
                elif
                    skseState.Phase = SksePhase.Failed
                    || skseState.Phase = SksePhase.UpdateAvailable
                then
                    let! _ = skse.Start(workspace, profile)
                    return! inspect workspace profile intent.IncludeFnis true token
                elif fnisState.Phase = FnisPhase.Failed then
                    let! _ = fnis.Install(workspace, profile)
                    return! inspect workspace profile intent.IncludeFnis true token
                else
                    return before
            | SkyrimSetupPhase.Ready ->
                do! store.SkyrimSetups.Remove(workspace, profile)
                return { before with ConsentRecorded = false }
            | _ -> return before
        }

    member _.Read(workspace, profile, includeFnis, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)
            let selected = intent |> Option.map _.IncludeFnis |> Option.defaultValue includeFnis
            let! current = inspect workspace profile selected intent.IsSome token

            if current.Ready && intent.IsSome then
                do! store.SkyrimSetups.Remove(workspace, profile)
                return { current with ConsentRecorded = false }
            else
                return current
        }

    member _.Start(workspace, profile, includeFnis, expectedPlan, confirmed, token) =
        task {
            let! existing = store.SkyrimSetups.Read(workspace, profile)

            match existing with
            | Some intent -> return! advance workspace profile intent token
            | None ->
                let! planned = inspect workspace profile includeFnis false token

                if not confirmed || planned.PlanToken = "" || planned.PlanToken <> expectedPlan then
                    return
                        { planned with
                            Status = "Review the current change plan"
                            Detail =
                                "Setup did not start because the confirmed plan is missing or out of date."
                            CanStart = planned.PlanToken <> "" }
                else
                    let intent =
                        { WorkspaceId = workspace
                          ProfileId = profile
                          IncludeFnis = includeFnis
                          PlanToken = expectedPlan
                          RequestedAt = DateTimeOffset.UtcNow }

                    do! store.SkyrimSetups.Save intent
                    return! advance workspace profile intent token
        }

    member _.Continue(workspace, profile, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | Some value -> return! advance workspace profile value token
            | None -> return! inspect workspace profile false false token
        }

    member _.SelectEnbArchive(workspace, profile, operation, path, token) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | None -> return! inspect workspace profile false false token
            | Some intent ->
                let! _ = enb.SelectArchive(workspace, profile, operation, path, token)
                return! inspect workspace profile intent.IncludeFnis true token
        }

type internal SkyrimSetupService(coordinator: SkyrimSetupCoordinator) =
    inherit SkyrimSetupOperations.SkyrimSetupOperationsBase()

    let ids workspace profile =
        ModLibraryWire.id workspace, ModLibraryWire.id profile

    let wire (value: SkyrimSetupView) =
        let result =
            SkyrimSetupState(
                Phase = value.Phase,
                Status = value.Status,
                Detail = value.Detail,
                PlanToken = value.PlanToken,
                IncludeFnis = value.IncludeFnis,
                ConsentRecorded = value.ConsentRecorded,
                CanStart = value.CanStart,
                CanContinue = value.CanContinue,
                CanSelectEnbArchive = value.CanSelectEnbArchive,
                Active = value.Active,
                Ready = value.Ready
            )

        result.Changes.AddRange(
            value.Changes
            |> Seq.map (fun change ->
                SkyrimSetupChange(Title = change.Title, Detail = change.Detail))
        )

        result.Components.AddRange(
            value.Components
            |> Seq.map (fun item ->
                SkyrimSetupComponent(
                    Name = item.Name,
                    Status = item.Status,
                    Detail = item.Detail,
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
                coordinator.Read(workspace, profile, request.IncludeFnis, context.CancellationToken)

            return wire value
        }

    override _.StartSkyrimSetup(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.Start(
                    workspace,
                    profile,
                    request.IncludeFnis,
                    request.PlanToken,
                    request.ChangePlanConfirmed,
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

    override _.SelectSkyrimSetupEnbArchive(request, context) =
        let workspace, profile = ids request.WorkspaceId request.ProfileId

        task {
            let! value =
                coordinator.SelectEnbArchive(
                    workspace,
                    profile,
                    ModLibraryWire.id request.OperationId,
                    request.Path,
                    context.CancellationToken
                )

            return wire value
        }
