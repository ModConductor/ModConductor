namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Fnis
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal SkyrimSetupActions
    (
        store: OperationStore,
        dependencies: SkyrimSetupDependencies,
        inspection: SkyrimSetupInspection,
        recovery: SkyrimSetupRecovery,
        startWorker: Guid -> Guid -> (CancellationToken -> Task) -> bool,
        recordFailure: Guid * Guid -> string -> unit
    ) =
    let inspect = inspection.Inspect
    let deploymentError = SkyrimSetupDeployment.error
    let initialDeployment = recovery.Initial
    let recoverPending = recovery.Pending

    let recordFnisResult workspace profile =
        function
        | Ok _ -> ()
        | Error error ->
            let detail =
                match error with
                | FnisExecutionError.Invalid detail
                | FnisExecutionError.Unavailable detail
                | FnisExecutionError.SourceInspectionFailed detail -> detail
                | FnisExecutionError.NotFound -> "The FNIS generator or run was not found."
                | FnisExecutionError.Busy -> "Another FNIS operation owns this profile."
                | FnisExecutionError.IdentityConflict -> "The FNIS run identity is already in use."
                | FnisExecutionError.Stale -> "The FNIS inputs changed. Select Apply to try again."
                | FnisExecutionError.Cancelled -> "FNIS was cancelled."

            recordFailure (workspace, profile) detail

    let waitForFnis (request: ModConductor.Fnis.FnisRunRequest) token =
        task {
            let! result = dependencies.WaitForFnisRun request token
            recordFnisResult request.WorkspaceId request.ProfileId result
        }

    let startFnisRun workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let request =
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  ProfileId = profile }

            let running =
                { intent with
                    Stage = "fnis-run"
                    ActionId = Some request.Id }

            do! store.SkyrimSetups.Save running

            startWorker workspace profile (fun childToken ->
                task {
                    let! admitted = dependencies.RunFnis request childToken

                    match admitted with
                    | Ok value when value.Phase = ModConductor.Fnis.FnisOutputPhase.Running ->
                        do! waitForFnis request childToken
                    | result -> recordFnisResult workspace profile result
                })
            |> ignore

            return! inspect workspace profile intent.Selection (Some running) token
        }

    let startEnbSelection workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
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
                dependencies.SelectEnb workspace profile operation archive childToken :> Task)
            |> ignore

            return! inspect workspace profile running.Selection (Some running) token
        }

    let success (operation: Task<SkyrimSetupView>) =
        task {
            let! value = operation
            return Ok value
        }

    let advance workspace profile (intent: StoredSkyrimSetupIntent) retryFailed token =
        task {
            let! before = inspect workspace profile intent.Selection (Some intent) token

            match before.Phase with
            | SkyrimSetupPhase.Failed when not retryFailed -> return Ok before
            | SkyrimSetupPhase.PreparingDeployment
            | SkyrimSetupPhase.RecoveryRequired ->
                let! deployment = store.Deployments.Read profile

                match deployment with
                | Error error ->
                    return
                        Ok
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
                            Ok
                                { before with
                                    Phase = SkyrimSetupPhase.Failed
                                    Status = "The first deployment could not be prepared"
                                    Detail = detail
                                    Active = false
                                    CanContinue = true }
                    | Ok() ->
                        return!
                            success (
                                inspect workspace profile intent.Selection (Some running) token
                            )
            | SkyrimSetupPhase.WaitingForSkse when before.CanContinue ->
                let running =
                    { intent with
                        Stage =
                            if intent.Selection.Skse = SetupAction.Remove then
                                "skse-remove"
                            else
                                "skse" }

                do! store.SkyrimSetups.Save running

                if intent.Selection.Skse = SetupAction.Remove then
                    let! removed = dependencies.RemoveSkse workspace profile token

                    match removed with
                    | Error detail -> return Error detail
                    | Ok _ ->
                        return!
                            success (
                                inspect workspace profile running.Selection (Some running) token
                            )
                else
                    let! _ = dependencies.StartSkse workspace profile

                    return!
                        success (inspect workspace profile running.Selection (Some running) token)
            | SkyrimSetupPhase.SettingUpEnb when before.CanContinue ->
                if intent.Selection.Enb = SetupAction.Remove then
                    let running = { intent with Stage = "enb-remove" }
                    do! store.SkyrimSetups.Save running
                    let! _ = dependencies.RemoveEnb workspace profile token

                    return!
                        success (inspect workspace profile running.Selection (Some running) token)
                else
                    return! success (startEnbSelection workspace profile intent token)
            | SkyrimSetupPhase.SettingUpFnis when before.CanContinue ->
                let running =
                    { intent with
                        Stage =
                            if intent.Selection.Fnis = SetupAction.Remove then
                                "fnis-remove"
                            else
                                "fnis-install" }

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

                return! success (inspect workspace profile running.Selection (Some running) token)
            | SkyrimSetupPhase.FnisStale when before.CanContinue ->
                return! success (startFnisRun workspace profile intent token)
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
                    return! success (startFnisRun workspace profile intent token)
                elif
                    deployment |> Result.toOption |> Option.bind _.PendingReceipt |> Option.isSome
                    && (enbState.Phase = EnbPhase.Failed || enbState.Phase = EnbPhase.Conflict)
                then
                    let! _ = dependencies.RecoverEnb workspace profile token
                    return! success (inspect workspace profile intent.Selection (Some intent) token)
                elif fnisState.Phase = FnisPhase.RecoveryRequired then
                    let! _ = dependencies.RecoverFnis workspace profile token
                    return! success (inspect workspace profile intent.Selection (Some intent) token)
                elif
                    skseState.Phase = SksePhase.Failed
                    || skseState.Phase = SksePhase.UpdateAvailable
                then
                    let! _ = dependencies.StartSkse workspace profile
                    return! success (inspect workspace profile intent.Selection (Some intent) token)
                elif
                    intent.Selection.Enb <> SetupAction.Unchanged
                    && enbState.Phase = EnbPhase.Failed
                then
                    return! success (startEnbSelection workspace profile intent token)
                elif fnisState.Phase = FnisPhase.Failed then
                    let! _ = dependencies.InstallFnis workspace profile
                    return! success (inspect workspace profile intent.Selection (Some intent) token)
                else
                    return Ok before
            | SkyrimSetupPhase.Ready ->
                do!
                    store.SkyrimSetups.Save
                        { intent with
                            Completed = true
                            Stage = "complete"
                            ActionId = None
                            Selection =
                                { intent.Selection with
                                    EnbArchive = None }
                            CancelRequested = false
                            CancelDetail = "" }

                return
                    Ok
                        { before with
                            CanCancel = false
                            CanContinue = false
                            Active = false }
            | _ -> return Ok before
        }



    member _.Advance workspace profile intent retryFailed token =
        advance workspace profile intent retryFailed token

    member _.ObserveFnisRun(workspace, profile, run) =
        startWorker workspace profile (fun token ->
            waitForFnis
                { Id = run
                  WorkspaceId = workspace
                  ProfileId = profile }
                token)
        |> ignore
