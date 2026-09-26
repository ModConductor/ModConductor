namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbOperationLoop
    (
        downloads: DownloadSession,
        store: OperationStore,
        acquisition: EnbAcquisition,
        defaultView: unit -> EnbView,
        changed: Guid * Guid -> unit
    ) =
    let lifetime = new CancellationTokenSource()

    let operations =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let wakeGate = obj ()
    let wakes = Dictionary<Guid * Guid, int64 * TaskCompletionSource>()

    let wakeState key =
        lock wakeGate (fun () ->
            match wakes.TryGetValue key with
            | true, value -> value
            | _ ->
                let value =
                    0L, TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

                wakes.Add(key, value)
                value)

    let signal key =
        lock wakeGate (fun () ->
            let revision, waiting = wakeState key

            wakes[key] <-
                revision + 1L,
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            waiting.TrySetResult() |> ignore)

    let awaitSignal key revision (token: CancellationToken) =
        let pending =
            lock wakeGate (fun () ->
                let current, waiting = wakeState key

                if current <> revision then
                    Task.CompletedTask
                else
                    waiting.Task)

        pending.WaitAsync(token)

    member _.Token = lifetime.Token
    member _.Contains key = operations.ContainsKey key
    member _.Signal key = signal key

    member _.CancelActive key =
        match operations.TryGetValue key with
        | true, (cancellation, _) ->
            try
                cancellation.Cancel()
            with :? ObjectDisposedException ->
                ()
        | _ -> ()

    member _.CancelAndWait key =
        task {
            match operations.TryGetValue key with
            | true, (cancellation, finished) ->
                try
                    cancellation.Cancel()
                with :? ObjectDisposedException ->
                    ()

                try
                    do! finished.Task.WaitAsync(TimeSpan.FromSeconds 10.)
                with :? TimeoutException ->
                    ()
            | _ -> ()
        }

    member _.RunAdvance workspace profile =
        task {
            let key = workspace, profile
            let cancellation = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

            let finished =
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            let! saved = store.EnbSetups.ReadStatus(workspace, profile)

            if operations.TryAdd(key, (cancellation, finished)) then
                Task.Run(fun () ->
                    task {
                        try
                            try
                                let mutable acquiring = true

                                while acquiring do
                                    let revision = fst (wakeState key)

                                    let! current =
                                        acquisition.Advance workspace profile cancellation.Token

                                    if current.Phase = EnbPhase.Acquiring then
                                        let! pending = acquisition.PendingFor profile

                                        let! artifacts =
                                            pending
                                            |> List.map (fun source ->
                                                downloads.FindNexus(
                                                    workspace,
                                                    acquisition.Reference
                                                        source.AccountId
                                                        source.NexusModId
                                                        source.File
                                                        false
                                                ))
                                            |> Task.WhenAll

                                        let waiting =
                                            artifacts
                                            |> Array.choose (
                                                Option.bind (fun artifact ->
                                                    if
                                                        artifact.State = ArtifactState.Ready
                                                        || artifact.State = ArtifactState.Installed
                                                    then
                                                        None
                                                    else
                                                        Some(artifact.Id, artifact.Revision))
                                            )
                                            |> Array.toList

                                        if pending.IsEmpty then
                                            acquiring <- false
                                        elif current.Status = "Waiting for Nexus Mods" then
                                            do! awaitSignal key revision cancellation.Token
                                        elif not waiting.IsEmpty then
                                            do!
                                                downloads.WaitForChange(
                                                    workspace,
                                                    waiting,
                                                    cancellation.Token
                                                )
                                    else
                                        acquiring <- false
                            with :? OperationCanceledException when
                                cancellation.IsCancellationRequested ->
                                ()
                        finally
                            match operations.TryRemove key with
                            | true, (owned, _) -> owned.Dispose()
                            | _ -> ()

                            finished.TrySetResult() |> ignore
                            changed key
                    }
                    :> Task)
                |> ignore
            else
                cancellation.Dispose()

            return saved |> Option.map EnbPresentation.fromStored |> Option.defaultWith defaultView
        }

    member this.Select
        workspace
        profile
        (token: CancellationToken)
        (select: CancellationToken -> Task<EnbView>)
        (read: unit -> Task<EnbView>)
        =
        task {
            let key = workspace, profile

            use cancellation =
                CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token, token)

            let finished =
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            if operations.TryAdd(key, (cancellation, finished)) then
                let! selected =
                    task {
                        try
                            return! select cancellation.Token
                        finally
                            match operations.TryRemove key with
                            | true, (owned, _) -> owned.Dispose()
                            | _ -> ()

                            finished.TrySetResult() |> ignore
                    }

                if selected.Phase = EnbPhase.Acquiring then
                    let! _ = this.RunAdvance workspace profile
                    ()

                return selected
            else
                return! read ()
        }

    member _.Stop() =
        task {
            lifetime.Cancel()

            let running =
                [| for _, finished in operations.Values do
                       finished.Task |]

            do! Task.WhenAll running
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()
            lifetime.Dispose()
