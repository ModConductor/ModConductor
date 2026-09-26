namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks

type internal SkyrimSetupWorkers
    (lifetime: CancellationTokenSource, failed: TaskCompletionSource, notify: Guid * Guid -> unit) =
    let workers =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let runAction (cancellation: CancellationTokenSource) (action: CancellationToken -> Task) =
        task {
            try
                let! _ = action cancellation.Token
                ()
            with
            | :? OperationCanceledException when cancellation.IsCancellationRequested -> ()
            | error -> failed.TrySetException error |> ignore
        }

    let run (key: Guid * Guid) cancellation (finished: TaskCompletionSource) action =
        task {
            try
                do! runAction cancellation action
            finally
                match workers.TryRemove key with
                | true, (owned, _) -> owned.Dispose()
                | _ -> ()

                finished.TrySetResult() |> ignore
                notify key
        }

    member _.Contains key = workers.ContainsKey key

    member _.Cancel key =
        match workers.TryGetValue key with
        | true, (worker, _) -> worker.Cancel()
        | _ -> ()

    member _.Running =
        [| for _, finished in workers.Values do
               finished.Task |]

    member _.Start workspace profile (action: CancellationToken -> Task) =
        let key = workspace, profile
        let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        let finished =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        if workers.TryAdd(key, (cancellation, finished)) then
            Task.Run(fun () -> run key cancellation finished action :> Task) |> ignore
            true
        else
            cancellation.Dispose()
            false
