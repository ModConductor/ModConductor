namespace ModConductor.HttpDownloads

open System
open System.Collections.Generic
open System.IO
open System.Net
open System.Net.Http
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary

type DownloadSession(repository: IDownloadRepository, ?policy: DownloadPolicy) =
    let policy = defaultArg policy DownloadPolicy.Default
    let shutdown = new CancellationTokenSource()
    let gate = new SemaphoreSlim(1, 1)
    let wake = new SemaphoreSlim(0, policy.Workers)

    let active =
        Dictionary<Guid, CancellationTokenSource * TaskCompletionSource<unit>>()

    let mutable closing = false

    let handler =
        new SocketsHttpHandler(
            ConnectTimeout = policy.ConnectTimeout,
            AutomaticDecompression = DecompressionMethods.None,
            UseCookies = false,
            MaxAutomaticRedirections = 5
        )

    let client = new HttpClient(handler, Timeout = Timeout.InfiniteTimeSpan)

    let signal () =
        try
            wake.Release() |> ignore
        with :? SemaphoreFullException ->
            ()

    let guarded action =
        task {
            do! gate.WaitAsync()

            try
                return! action ()
            finally
                gate.Release() |> ignore
        }

    let outcome (work: DownloadWork) (error: exn) (token: CancellationToken) =
        if token.IsCancellationRequested then
            DownloadOutcome.Paused
        else
            let retry, restart, after, message =
                match error with
                | :? TransferFailure as failure ->
                    failure.Retry, failure.Restart, failure.RetryAt, failure.Message
                | :? HttpRequestException ->
                    true, false, None, "The connection failed. The partial copy is saved."
                | :? OperationCanceledException ->
                    true, false, None, "The download timed out. The partial copy is saved."
                | :? HttpIOException ->
                    true, false, None, "The connection ended before the file was complete."
                | :? IOException ->
                    false, false, None, "The partial copy cannot be read or written."
                | :? UnauthorizedAccessException ->
                    false, false, None, "The library folder cannot be accessed."
                | _ -> raise error

            if retry && work.Attempt < policy.Attempts then
                let delay = policy.RetryDelay * float (pown 2 (work.Attempt - 1))

                let at =
                    max (DateTimeOffset.UtcNow + delay) (defaultArg after DateTimeOffset.MinValue)

                let source =
                    if work.Bytes = 0L then
                        (work.SourceIndex + 1) % work.Request.Sources.Length
                    else
                        work.SourceIndex

                DownloadOutcome.Retry(at, source)
            else
                DownloadOutcome.Failed(message, restart, after)

    let take () =
        guarded (fun () ->
            task {
                if closing then
                    return None
                else
                    let! work = repository.Take()

                    return
                        work
                        |> Option.map (fun work ->
                            let token =
                                CancellationTokenSource.CreateLinkedTokenSource shutdown.Token

                            let stopped =
                                TaskCompletionSource<unit>(
                                    TaskCreationOptions.RunContinuationsAsynchronously
                                )

                            active.Add(work.Request.Id, (token, stopped))
                            work, token, stopped)
            })

    let worker () =
        task {
            try
                while not shutdown.IsCancellationRequested do
                    let! next = take ()

                    match next with
                    | None ->
                        let! due = repository.NextDue()

                        let delay =
                            due
                            |> Option.map (fun at ->
                                max
                                    1
                                    (int (
                                        min 60000. (at - DateTimeOffset.UtcNow).TotalMilliseconds
                                    )))
                            |> Option.defaultValue 60000

                        let! _ = wake.WaitAsync(delay, shutdown.Token)
                        ()
                    | Some(work, token, stopped) ->
                        try
                            try
                                do! HttpTransfer.run client policy repository work token.Token
                            with error ->
                                do! repository.Finish(work, outcome work error token.Token)
                        finally
                            gate.Wait()

                            try
                                active.Remove work.Request.Id |> ignore
                            finally
                                gate.Release() |> ignore

                            token.Dispose()
                            stopped.TrySetResult() |> ignore
                            signal ()
            with :? OperationCanceledException when shutdown.IsCancellationRequested ->
                ()
        }

    let workers = Array.init policy.Workers (fun _ -> worker ())

    member _.Failed =
        task {
            let! ended = Task.WhenAny workers
            return! ended
        }

    member _.Start request =
        guarded (fun () ->
            task {
                if closing then
                    return Error ArtifactError.Busy
                else
                    let! result = repository.Start request
                    signal ()
                    return result
            })

    member _.Control(workspace, id, action) =
        task {
            let! result, stopped =
                guarded (fun () ->
                    task {
                        if closing then
                            return Error ArtifactError.Busy, Task.CompletedTask
                        else
                            let! result = repository.Control(workspace, id, action)

                            let stopped =
                                if Result.isOk result && action = DownloadAction.Pause then
                                    match active.TryGetValue id with
                                    | true, (token, completion) ->
                                        token.Cancel()
                                        completion.Task :> Task
                                    | _ -> Task.CompletedTask
                                else
                                    Task.CompletedTask

                            signal ()
                            return result, stopped
                    })

            do! stopped

            if Result.isOk result && action = DownloadAction.Pause then
                return! repository.Read(workspace, id)
            else
                return result
        }

    member _.Stop() =
        task {
            do!
                guarded (fun () ->
                    task {
                        closing <- true
                        shutdown.Cancel()
                    })

            let! _ = Task.WhenAll workers
            return ()
        }

    member _.TryClose() =
        gate.Wait()

        try
            if active.Count > 0 then
                false
            else
                closing <- true
                shutdown.Cancel()
                true
        finally
            gate.Release() |> ignore

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()
            client.Dispose()
            shutdown.Dispose()
            wake.Dispose()
            gate.Dispose()
