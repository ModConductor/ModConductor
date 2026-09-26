namespace ModConductor.Engine

open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.Protocol.V1

module internal SkyrimSetupDeployment =
    let error =
        function
        | DeploymentError.NotFound -> "The deployment is unavailable."
        | DeploymentError.Busy -> "Wait for the current deployment operation, then select Continue."
        | DeploymentError.Stale -> "The profile changed. Select Refresh and review the new plan."
        | DeploymentError.Cancelled -> "Setup stopped. Select Continue to recover it."
        | DeploymentError.Blocked detail
        | DeploymentError.Unavailable detail -> detail

type internal SkyrimSetupRecovery(store: OperationStore, dependencies: SkyrimSetupDependencies) =
    let deploymentError = SkyrimSetupDeployment.error

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


    member _.Initial deployment action token =
        initialDeployment deployment action token

    member _.Pending workspace profile deployment token =
        recoverPending workspace profile deployment token
