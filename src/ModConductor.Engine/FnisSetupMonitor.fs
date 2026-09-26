namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.HttpDownloads
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal FnisSetupMonitor
    (
        store: OperationStore,
        downloads: DownloadSession,
        sources: FnisSources,
        persist: Guid -> Guid -> FnisView -> Task<FnisView>,
        signal: Guid * Guid -> unit
    ) =
    let lifetime = new CancellationTokenSource()

    let workers =
        ConcurrentDictionary<Guid * Guid, CancellationTokenSource * TaskCompletionSource>()

    let waitForReady key (artifact: Artifact) (token: CancellationToken) =
        task {
            let mutable current = artifact
            let mutable result = None

            while result.IsNone do
                token.ThrowIfCancellationRequested()

                match current.State, current.Download with
                | (ArtifactState.Ready | ArtifactState.Installed), _ -> result <- Some(Ok current)
                | ArtifactState.Incomplete, Some download when
                    download.State = DownloadState.Failed || download.State = DownloadState.Paused
                    ->
                    result <-
                        Some(
                            Error(
                                current.Problem |> Option.defaultValue "The FNIS download stopped."
                            )
                        )
                | _ ->
                    do! downloads.WaitForChange(fst key, [ current.Id, current.Revision ], token)
                    let! latest = store.Artifacts.Read(fst key, current.Id)

                    match latest with
                    | Ok artifact -> current <- artifact
                    | Error _ -> result <- Some(Error "The FNIS archive is unavailable.")

            return result.Value
        }

    let persistFailure key (selection: StoredFnisSelection) (artifact: Artifact) detail =
        task {
            let! pending = store.Deployments.Read(snd key)

            let recovery =
                match pending with
                | Ok state when state.PendingReceipt.IsSome -> true
                | _ -> false

            let release = selection.Selection.Release

            let! _ =
                persist
                    (fst key)
                    (snd key)
                    { Phase =
                        if recovery then
                            FnisPhase.RecoveryRequired
                        else
                            FnisPhase.Failed
                      Version = string release.ComponentVersion
                      Status =
                        if recovery then
                            "FNIS setup needs recovery"
                        else
                            "FNIS setup failed"
                      Detail = detail
                      FileId = Some release.File.Id
                      ArtifactId = Some artifact.Id }

            ()
        }

    let monitor key (selection: StoredFnisSelection) (artifact: Artifact) =
        let local = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        let finished =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        if workers.TryAdd(key, (local, finished)) then
            let work: Task =
                task {
                    try
                        let! ready = waitForReady key artifact local.Token

                        match ready with
                        | Error detail -> do! persistFailure key selection artifact detail
                        | Ok current ->
                            let release = selection.Selection.Release
                            do! sources.SaveArtifact(current, selection)

                            let! _ =
                                persist
                                    (fst key)
                                    (snd key)
                                    { Phase = FnisPhase.Installing
                                      Version = string release.ComponentVersion
                                      Status = "Installing FNIS"
                                      Detail =
                                        "The active profile stays unchanged until the new generation is ready."
                                      FileId = Some release.File.Id
                                      ArtifactId = Some current.Id }

                            let! installed =
                                store.InstallFnis(fst key, snd key, release, current, local.Token)

                            match installed with
                            | Error detail -> do! persistFailure key selection current detail
                            | Ok _ ->
                                let! _ =
                                    persist
                                        (fst key)
                                        (snd key)
                                        { Phase = FnisPhase.Ready
                                          Version = string release.ComponentVersion
                                          Status = "FNIS is ready"
                                          Detail =
                                            "The Windows generator is registered for this profile. Running it is a separate step."
                                          FileId = Some release.File.Id
                                          ArtifactId = Some current.Id }

                                ()
                    with
                    | :? OperationCanceledException when local.IsCancellationRequested -> ()
                    | error -> do! persistFailure key selection artifact error.Message
                }

            work.ContinueWith(fun (_: Task) ->
                let mutable removed =
                    Unchecked.defaultof<CancellationTokenSource * TaskCompletionSource>

                workers.TryRemove(key, &removed) |> ignore
                local.Dispose()
                finished.TrySetResult() |> ignore
                signal key)
            |> ignore
        else
            local.Dispose()

    member _.PrepareArtifact(key, selection, artifact, label) =
        task {
            let! artifact = sources.Resume(fst key, artifact)
            do! sources.SaveArtifact(artifact, selection)

            let! view =
                persist
                    (fst key)
                    (snd key)
                    { Phase = FnisPhase.Downloading
                      Version = string selection.Selection.Release.ComponentVersion
                      Status = label
                      Detail = "The archive and installation state are durable across restart."
                      FileId = Some selection.Selection.Release.File.Id
                      ArtifactId = Some artifact.Id }

            monitor key selection artifact
            return view
        }


    member _.Token = lifetime.Token
    member _.IsActive key = workers.ContainsKey key

    member _.Cancel(key) =
        task {
            match workers.TryGetValue key with
            | true, (cancellation, finished) ->
                try
                    cancellation.Cancel()
                with :? ObjectDisposedException ->
                    ()

                try
                    do! finished.Task.WaitAsync(TimeSpan.FromSeconds 5.)
                with :? TimeoutException ->
                    ()
            | _ -> ()
        }

    member _.Wait(key, token: CancellationToken) =
        task {
            match workers.TryGetValue key with
            | true, (_, finished) -> do! finished.Task.WaitAsync(token)
            | _ -> ()
        }

    member _.Stop() =
        task {
            lifetime.Cancel()

            let running =
                [| for _, finished in workers.Values do
                       finished.Task |]

            do! Task.WhenAll running
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()
            lifetime.Dispose()
