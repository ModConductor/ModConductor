namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.Persistence

type private ActiveFnisRun =
    { Id: Guid
      Cancellation: CancellationTokenSource
      Completion: TaskCompletionSource<unit> }

type FnisRunner
    (
        store: OperationStore,
        ?timeout: TimeSpan,
        ?publicationCheckpoint: FnisRunRequest -> unit,
        ?candidateCheckpoint: FnisRunRequest -> unit,
        ?activationCheckpoint: FnisRunRequest -> unit
    ) =
    let active = ConcurrentDictionary<Guid * Guid, ActiveFnisRun>()
    let lifetime = obj ()
    let mutable closing = false
    let timeout = defaultArg timeout (TimeSpan.FromMinutes 5.)
    let publicationCheckpoint = defaultArg publicationCheckpoint ignore
    let candidateCheckpoint = defaultArg candidateCheckpoint ignore
    let activationCheckpoint = defaultArg activationCheckpoint ignore
    let inspect = FnisRunRecovery.inspect store

    let execute (stage: FnisRunStage) (run: ActiveFnisRun) =
        task {
            try
                do!
                    FnisRunExecution.execute
                        store
                        timeout
                        publicationCheckpoint
                        candidateCheckpoint
                        activationCheckpoint
                        stage
                        run.Cancellation.Token
            finally
                store.FnisExecution.CleanupStage stage.Request.Id
                let key = stage.Request.WorkspaceId, stage.Request.ProfileId
                let mutable removed = Unchecked.defaultof<ActiveFnisRun>
                active.TryRemove(key, &removed) |> ignore
                run.Cancellation.Dispose()
                run.Completion.TrySetResult() |> ignore
        }

    let beginRun (request: FnisRunRequest) (token: CancellationToken) =
        task {
            token.ThrowIfCancellationRequested()
            let! observed = inspect request.WorkspaceId request.ProfileId token

            match observed with
            | Error error -> return Error error
            | Ok observed ->
                let! generator =
                    store.FnisSetups.ReadStored(
                        request.WorkspaceId,
                        request.ProfileId,
                        Some observed.GenerationId
                    )

                match generator with
                | None -> return Error FnisExecutionError.NotFound
                | Some generator ->
                    return! store.FnisExecution.Begin(request, generator, observed.Fingerprint)
        }

    let launch (stage: FnisRunStage) =
        task {
            let run =
                { Id = stage.Request.Id
                  Cancellation = new CancellationTokenSource()
                  Completion =
                    TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously) }

            let key = stage.Request.WorkspaceId, stage.Request.ProfileId
            let accepted = lock lifetime (fun () -> not closing && active.TryAdd(key, run))

            if not accepted then
                do!
                    store.FnisExecution.Fail(
                        stage.Request.Id,
                        FnisOutputPhase.Failed,
                        None,
                        Array.empty,
                        Array.empty,
                        Array.empty,
                        "Another FNIS run already owns this profile."
                    )

                store.FnisExecution.CleanupStage stage.Request.Id
                run.Cancellation.Dispose()

                return
                    Error(
                        if closing then
                            FnisExecutionError.Unavailable "The engine is stopping."
                        else
                            FnisExecutionError.Busy
                    )
            else
                Task.Run(fun () -> execute stage run :> Task) |> ignore

                return!
                    inspect stage.Request.WorkspaceId stage.Request.ProfileId CancellationToken.None
        }

    member _.Stop() =
        task {
            let runs =
                lock lifetime (fun () ->
                    closing <- true
                    active.Values |> Seq.toArray)

            for run in runs do
                run.Cancellation.Cancel()

            if runs.Length > 0 then
                let! _ = Task.WhenAll(runs |> Array.map _.Completion.Task)
                ()
        }

    interface IFnisInspection with
        member _.Inspect(workspace, profile, token) = inspect workspace profile token

    interface IFnisExecution with
        member _.WaitForRun(request, token) =
            task {
                let! observed = inspect request.WorkspaceId request.ProfileId token

                match observed with
                | Error error -> return Error error
                | Ok value when value.LatestRunId <> Some request.Id ->
                    return Error FnisExecutionError.NotFound
                | Ok value when value.Phase <> FnisOutputPhase.Running -> return Ok value
                | Ok _ ->
                    let key = request.WorkspaceId, request.ProfileId

                    match active.TryGetValue key with
                    | true, run when run.Id = request.Id -> do! run.Completion.Task.WaitAsync token
                    | _ -> ()

                    let! completed = inspect request.WorkspaceId request.ProfileId token

                    return
                        match completed with
                        | Ok value when value.LatestRunId <> Some request.Id ->
                            Error FnisExecutionError.NotFound
                        | Ok value when value.Phase = FnisOutputPhase.Running ->
                            Error(FnisExecutionError.Unavailable "The FNIS run is not active.")
                        | other -> other
            }

        member _.Run(request, token) =
            task {
                if
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || request.ProfileId = Guid.Empty
                then
                    return Error(FnisExecutionError.Invalid "The FNIS run identity is invalid.")
                else
                    let! begun = beginRun request token

                    match begun with
                    | Error error -> return Error error
                    | Ok(_, false, _) -> return! inspect request.WorkspaceId request.ProfileId token
                    | Ok(stage, true, _) -> return! launch stage
            }

        member _.Cancel(workspace, profile) =
            task {
                match active.TryGetValue((workspace, profile)) with
                | true, run ->
                    try
                        run.Cancellation.Cancel()
                    with :? ObjectDisposedException ->
                        ()

                    try
                        do! run.Completion.Task.WaitAsync(TimeSpan.FromSeconds 10.)
                    with :? TimeoutException ->
                        ()
                | _ -> ()

                return! inspect workspace profile CancellationToken.None
            }

    interface IDisposable with
        member this.Dispose() = this.Stop().GetAwaiter().GetResult()
