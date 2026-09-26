namespace ModConductor.Engine

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks

type internal SkyrimSetupSignals(changes: IObservable<Guid * Guid> list) =
    let gate = obj ()
    let notifications = Dictionary<Guid * Guid, int64 * TaskCompletionSource>()

    let current key =
        match notifications.TryGetValue key with
        | true, value -> value
        | _ ->
            let value =
                0L, TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            notifications.Add(key, value)
            value

    let notify key =
        lock gate (fun () ->
            let revision, waiting = current key

            notifications[key] <-
                revision + 1L,
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            waiting.TrySetResult() |> ignore)

    let subscriptions = changes |> List.map (fun source -> source.Subscribe notify)

    member _.Revision key =
        lock gate (fun () -> current key |> fst)

    member _.Notify key = notify key

    member _.WaitForChange key revision (token: CancellationToken) =
        let pending =
            lock gate (fun () ->
                let currentRevision, waiting = current key

                if currentRevision <> revision then
                    Task.CompletedTask
                else
                    waiting.Task)

        pending.WaitAsync(token)

    interface IDisposable with
        member _.Dispose() =
            for subscription in subscriptions do
                subscription.Dispose()
