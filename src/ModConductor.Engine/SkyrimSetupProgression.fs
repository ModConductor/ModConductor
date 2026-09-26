namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.Persistence
open ModConductor.Protocol.V1

type private ProgressionStep =
    | Stop
    | Wait
    | Again

type internal SkyrimSetupProgression
    (
        lifetime: CancellationTokenSource,
        failed: TaskCompletionSource,
        signals: SkyrimSetupSignals,
        store: OperationStore,
        inspect:
            Guid
                -> Guid
                -> SetupSelection
                -> StoredSkyrimSetupIntent option
                -> CancellationToken
                -> Task<SkyrimSetupView>,
        advance:
            Guid
                -> Guid
                -> StoredSkyrimSetupIntent
                -> bool
                -> CancellationToken
                -> Task<Result<SkyrimSetupView, string>>
    ) =
    let progression =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let activeIntent (intent: StoredSkyrimSetupIntent) =
        not intent.Cancelled && not intent.Completed && not intent.CancelRequested

    let canAdvance (view: SkyrimSetupView) =
        view.CanContinue
        && view.Phase <> SkyrimSetupPhase.Failed
        && view.Phase <> SkyrimSetupPhase.WaitingForEnbArchive

    let advanceOne workspace profile (token: CancellationToken) =
        task {
            let! intent = store.SkyrimSetups.Read(workspace, profile)

            match intent with
            | Some value when activeIntent value ->
                let! before = inspect workspace profile value.Selection intent token

                if canAdvance before then
                    let! outcome = advance workspace profile value false token

                    match outcome with
                    | Error detail ->
                        failed.TrySetException(InvalidOperationException detail) |> ignore
                        signals.Notify(workspace, profile)
                        return Stop
                    | Ok after when after <> before ->
                        signals.Notify(workspace, profile)
                        return Again
                    | Ok _ -> return Wait
                elif before.Active then
                    return Wait
                else
                    return Stop
            | _ -> return Stop
        }

    let runLoop key (cancellation: CancellationTokenSource) =
        task {
            try
                let workspace, profile = key
                let mutable active = true

                while active && not cancellation.IsCancellationRequested do
                    let revision = signals.Revision key
                    let! step = advanceOne workspace profile cancellation.Token

                    match step with
                    | Stop -> active <- false
                    | Wait -> do! signals.WaitForChange key revision cancellation.Token
                    | Again -> ()
            with
            | :? OperationCanceledException when cancellation.IsCancellationRequested -> ()
            | error ->
                failed.TrySetException error |> ignore
                signals.Notify key
        }

    let run (key: Guid * Guid) cancellation (finished: TaskCompletionSource) =
        task {
            try
                do! runLoop key cancellation
            finally
                match progression.TryRemove key with
                | true, (owned, _) -> owned.Dispose()
                | _ -> ()

                finished.TrySetResult() |> ignore
        }

    member _.Contains key = progression.ContainsKey key

    member _.Running =
        [| for _, finished in progression.Values do
               finished.Task |]

    member _.CancelAndWait key =
        task {
            match progression.TryGetValue key with
            | true, (cancellation, finished) ->
                cancellation.Cancel()
                do! finished.Task
            | _ -> ()
        }

    member _.Start workspace profile =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        let finished =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        if not failed.Task.IsCompleted && progression.TryAdd(key, (cancellation, finished)) then
            Task.Run(fun () -> run key cancellation finished :> Task) |> ignore
        else
            cancellation.Dispose()
