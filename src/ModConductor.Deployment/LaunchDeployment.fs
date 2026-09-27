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
            let! read = repository.Read expected.ProfileId

            match read with
            | Error error -> return Error(DeploymentReports.error error)
            | Ok(sources, context) ->
                if sources.Stamp <> expected then
                    return Error DeploymentError.Stale
                elif context |> Option.exists (fun value -> value.Pending.IsSome) then
                    return Error DeploymentError.Busy
                else
                    token.ThrowIfCancellationRequested()

                    match GameProcesses.validate sources.Context with
                    | Error detail -> return Error(DeploymentError.Unavailable detail)
                    | Ok _ ->
                        let! preparation =
                            match candidate with
                            | Some run ->
                                repository.PrepareTransient(
                                    id,
                                    sources,
                                    context,
                                    run,
                                    progress,
                                    token
                                )
                            | None -> repository.Prepare(id, sources, context, progress, token)

                        match preparation with
                        | Error error -> return Error(DeploymentReports.error error)
                        | Ok prepared ->
                            let mutable durable = false

                            try
                                let! current = repository.Current expected

                                let! contextResult =
                                    repository.Context(expected.WorkspaceId, expected.ProfileId)

                                let contextCheck =
                                    contextResult
                                    |> Result.mapError DeploymentReports.error
                                    |> Result.bind (fun context ->
                                        token.ThrowIfCancellationRequested()

                                        if not current || context <> prepared.Context then
                                            Error DeploymentError.Stale
                                        else
                                            GameProcesses.validate context
                                            |> Result.mapError DeploymentError.Unavailable)

                                match contextCheck with
                                | Error error -> return Error error
                                | Ok _ ->
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
