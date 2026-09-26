namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.Fnis
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Protocol.V1
open SkyrimSetupViews

type internal SkyrimSetupComponents(store: OperationStore, dependencies: SkyrimSetupDependencies) =
    let inspectReadiness workspace profile selection running components output token =
        task {
            let! pluginPreflight = dependencies.PluginPreflight workspace profile token

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
                    false, "Plugin order needs attention", "Refresh the plugins before playing."
                | Ok(), Ok state when state.Problem.IsNone && state.Runtime <> "" ->
                    true, "Play is ready", ""
                | Ok(), Ok state ->
                    false,
                    "Play needs attention",
                    state.Problem |> Option.defaultValue "Refresh the selected launch context."
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

            let readyStatus, readyDetail =
                fnisExitWarning output |> Option.defaultValue ("Skyrim setup is ready", "")

            return
                view
                    (if launchReady then
                         SkyrimSetupPhase.Ready
                     else
                         SkyrimSetupPhase.Failed)
                    (if launchReady then readyStatus else launchStatus)
                    (if launchReady then readyDetail else launchDetail)
                    components
                    selection
                    running
                    false
                    (running && launchReady)
                    false
                    launchReady
        }

    let inspectFnis
        workspace
        profile
        selection
        running
        (recorded: StoredSkyrimSetupIntent option)
        (deployed: DeploymentStatus)
        stage
        skseComponent
        enbComponent
        token
        =
        task {
            let mutable stage = stage

            match recorded with
            | Some value when stage = "enb" || stage = "enb-remove" || stage = "enb-start" ->
                let nextStage =
                    if selection.Fnis <> SetupAction.Unchanged then
                        "fnis-start"
                    else
                        "readiness"

                do! store.SkyrimSetups.Save { value with Stage = nextStage }
                stage <- nextStage
            | _ -> ()

            let baseComponents = [ skseComponent; enbComponent ]

            let! fnisStored =
                store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

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
                            let! inspected = dependencies.InspectFnis workspace profile token

                            return Some value, Result.toOption inspected
                        else
                            return Some value, None
                    }
                elif fnisStored.IsSome then
                    task {
                        let! inspected = dependencies.InspectFnis workspace profile token

                        return None, Result.toOption inspected
                    }
                else
                    task { return None, None }

            let fnisReady, fnisActive, fnisBlocked, fnisComponent =
                evaluateFnis
                    selection.Fnis
                    stage
                    (recorded |> Option.bind _.ActionId)
                    fnisStored.IsSome
                    fnisState
                    output

            let components = baseComponents @ Option.toList fnisComponent

            let fnisSetupReady =
                if selection.Fnis = SetupAction.Remove then
                    fnisStored.IsNone
                else
                    fnisState |> Option.exists (fun value -> value.Phase = FnisPhase.Ready)

            let nextFnisStage =
                if selection.Fnis = SetupAction.Remove || fnisReady then
                    "readiness"
                else
                    "fnis-run"

            match recorded with
            | Some value when (stage = "fnis-install" || stage = "fnis-remove") && fnisSetupReady ->
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
                            value.Phase <> ModConductor.Fnis.FnisOutputPhase.Current
                            && value.Phase <> ModConductor.Fnis.FnisOutputPhase.Running))

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
                return! inspectReadiness workspace profile selection running components output token
        }

    let inspectEnb
        workspace
        profile
        selection
        running
        (recorded: StoredSkyrimSetupIntent option)
        (deployed: DeploymentStatus)
        stage
        skseComponent
        token
        =
        task {
            let mutable stage = stage

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
                else
                    dependencies.ReadEnb workspace profile

            let enbDone, enbActive, enbBlocked, enbComponent =
                evaluateEnb selection.Enb stage enbState enbInstalled

            if not enbDone then
                let waiting = enbState.Phase = EnbPhase.WaitingForArchive

                return
                    view
                        (if enbBlocked && selection.Enb <> SetupAction.Remove then
                             SkyrimSetupPhase.Failed
                         elif waiting then
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
                return!
                    inspectFnis
                        workspace
                        profile
                        selection
                        running
                        recorded
                        deployed
                        stage
                        skseComponent
                        enbComponent
                        token
        }

    let inspect
        workspace
        profile
        selection
        running
        (recorded: StoredSkyrimSetupIntent option)
        (deployed: DeploymentStatus)
        stage
        token
        =
        task {
            let mutable stage = stage

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

            let! skseStored =
                store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

            let skseDone, skseActive, skseBlocked, skseComponent =
                evaluateSkse selection.Skse stage skseState skseStored.IsSome

            if not skseDone then
                let phase =
                    if skseBlocked && selection.Skse <> SetupAction.Remove then
                        SkyrimSetupPhase.Failed
                    elif skseActive then
                        SkyrimSetupPhase.SettingUpSkse
                    else
                        SkyrimSetupPhase.WaitingForSkse

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
                return!
                    inspectEnb
                        workspace
                        profile
                        selection
                        running
                        recorded
                        deployed
                        stage
                        skseComponent
                        token
        }


    member _.Inspect workspace profile selection running recorded deployed stage token =
        inspect workspace profile selection running recorded deployed stage token
