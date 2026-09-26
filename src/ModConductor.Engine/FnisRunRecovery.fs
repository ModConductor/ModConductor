namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.Persistence

module internal FnisRunRecovery =
    let restorePending (store: OperationStore) profile run =
        task {
            let! state = store.Deployments.Read profile

            match state with
            | Ok state when state.PendingReceipt = Some run ->
                let! receipt = store.Deployments.Receipt run

                match receipt with
                | Error _ -> return false
                | Ok receipt ->
                    let! restored =
                        store.Deployments.Recover(
                            run,
                            receipt.Revision,
                            true,
                            ignore,
                            CancellationToken.None
                        )

                    return Result.isOk restored
            | Ok _ -> return true
            | Error _ -> return false
        }

    let reconcile (store: OperationStore) workspace profile =
        task {
            let! interrupted = store.FnisExecution.Interrupted profile

            match interrupted with
            | None -> ()
            | Some run ->
                let! _ = restorePending store profile run

                let! state = store.Deployments.Read profile
                let! receipt = store.Deployments.Receipt run

                match state, receipt with
                | Ok state, _ when state.PendingReceipt = Some run -> ()
                | Ok state, Ok receipt when
                    state.WorkspaceId = workspace
                    && receipt.Phase = ModConductor.Deployment.DeploymentPhase.Complete
                    && state.ActiveGeneration = Some receipt.Proposed
                    ->
                    do! store.FnisExecution.Complete run
                    let! _ = store.FnisExecution.PrunePrevious run
                    do! store.FnisExecution.MarkCurrent run
                    ()
                | _ ->
                    let! _ = store.FnisExecution.PruneCandidate run
                    ()
        }

    let inspect
        (store: OperationStore)
        (workspace: Guid)
        (profile: Guid)
        (token: CancellationToken)
        =
        task {
            token.ThrowIfCancellationRequested()
            do! reconcile store workspace profile
            let! deployment = store.Deployments.Read profile

            match deployment with
            | Error _ -> return Error FnisExecutionError.NotFound
            | Ok deployment when deployment.WorkspaceId <> workspace ->
                return Error FnisExecutionError.NotFound
            | Ok deployment ->
                match deployment.ActiveGeneration with
                | None -> return Error FnisExecutionError.NotFound
                | Some generation ->
                    return! store.FnisExecution.Inspect(workspace, profile, generation)
        }
