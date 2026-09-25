namespace ModConductor.Deployment

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery

module internal LaunchDeployment =
    let prepare
        (repository: IDeploymentRepository)
        (execute:
            Receipt
                -> bool
                -> (DeploymentProgress -> unit)
                -> CancellationToken
                -> Task<Result<DeploymentReceipt, DeploymentError>>)
        id
        (expected: SourceStamp)
        candidate
        progress
        (token: CancellationToken)
        =
        task {
            let! sources, context = repository.Read expected.ProfileId

            if sources.Stamp <> expected then
                return Error DeploymentError.Stale
            elif context |> Option.exists (fun value -> value.Pending.IsSome) then
                return Error DeploymentError.Busy
            else
                token.ThrowIfCancellationRequested()
                GameProcesses.validate sources.Context |> ignore
                let! prepared =
                    match candidate with
                    | Some run ->
                        repository.PrepareTransient(id, sources, context, run, progress, token)
                    | None -> repository.Prepare(id, sources, context, progress, token)
                let mutable durable = false

                try
                    let! current = repository.Current expected
                    let! checkedContext =
                        repository.Context(expected.WorkspaceId, expected.ProfileId)
                    token.ThrowIfCancellationRequested()

                    if not current || checkedContext <> prepared.Context then
                        return Error DeploymentError.Stale
                    else
                        GameProcesses.validate checkedContext |> ignore
                        let! started = repository.Start(prepared, token)

                        match started with
                        | Error error -> return Error(DeploymentReports.error error)
                        | Ok receipt ->
                            durable <- true
                            let! finished = execute receipt false progress token

                            return
                                finished
                                |> Result.bind (fun receipt ->
                                    if receipt.Phase = DeploymentPhase.Complete then
                                        Ok(prepared.View, receipt)
                                    else
                                        Error(DeploymentError.Blocked receipt.Detail))
                finally
                    if not durable then
                        PreparedState.abandon prepared
        }
