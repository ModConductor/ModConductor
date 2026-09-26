namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal SkseSetupMonitor
    (
        downloads: DownloadSession,
        store: OperationStore,
        sources: SkseSources,
        status: SkseStatusStore
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
                                current.Problem |> Option.defaultValue "The SKSE download stopped."
                            )
                        )
                | _ ->
                    do! downloads.WaitForChange(fst key, [ current.Id, current.Revision ], token)
                    let! latest = store.Artifacts.Read(fst key, current.Id)

                    match latest with
                    | Ok artifact -> current <- artifact
                    | Error _ -> result <- Some(Error "The SKSE archive is unavailable.")

            return result.Value
        }

    let monitor
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        (artifact: Artifact)
        (local: CancellationTokenSource)
        (finished: TaskCompletionSource)
        =
        let work: Task =
            task {
                let gameVersion, _ = SkseStatus.facts context
                let release = selection.Selection.Release

                try
                    let! ready = waitForReady key artifact local.Token

                    match ready with
                    | Error detail ->
                        let! _ =
                            status.Failed
                                key
                                gameVersion
                                (string release.ComponentVersion)
                                (Some release.File.Id)
                                "SKSE setup failed"
                                detail

                        ()
                    | Ok current ->
                        if not local.IsCancellationRequested then
                            do! sources.SaveArtifact(current, selection)

                            let! _ =
                                status.Persist
                                    key
                                    { Phase = SksePhase.Installing
                                      GameVersion = gameVersion
                                      ComponentVersion = string release.ComponentVersion
                                      Status = "Installing SKSE"
                                      Detail = ""
                                      FileId = Some release.File.Id }

                            let! installed =
                                store.InstallSkse(
                                    fst key,
                                    snd key,
                                    release,
                                    current,
                                    selection.CheckedAt,
                                    local.Token
                                )

                            match installed with
                            | Error detail ->
                                let! _ =
                                    status.Failed
                                        key
                                        gameVersion
                                        (string release.ComponentVersion)
                                        (Some release.File.Id)
                                        "SKSE setup failed"
                                        detail

                                ()
                            | Ok _ ->
                                let! _ =
                                    status.Persist
                                        key
                                        { Phase = SksePhase.Ready
                                          GameVersion = gameVersion
                                          ComponentVersion = string release.ComponentVersion
                                          Status = "SKSE is current"
                                          Detail = "Play uses the installed SKSE loader."
                                          FileId = Some release.File.Id }

                                ()
                with
                | :? OperationCanceledException when local.IsCancellationRequested -> ()
                | error ->
                    let! _ =
                        status.Failed
                            key
                            gameVersion
                            (string release.ComponentVersion)
                            (Some release.File.Id)
                            "SKSE setup failed"
                            error.Message

                    ()
            }

        work.ContinueWith(fun (_: Task) ->
            let mutable removed =
                Unchecked.defaultof<CancellationTokenSource * TaskCompletionSource>

            workers.TryRemove(key, &removed) |> ignore
            local.Dispose()
            finished.TrySetResult() |> ignore
            status.Signal key)
        |> ignore

    member _.PrepareArtifact
        (
            key,
            context: ModConductor.GameContexts.GameContextState,
            selection: StoredSkseSelection,
            artifact: Artifact,
            label
        ) =
        task {
            let local = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

            let finished =
                TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

            let gameVersion, _ = SkseStatus.facts context

            let downloading =
                { Phase = SksePhase.Downloading
                  GameVersion = gameVersion
                  ComponentVersion = string selection.Selection.Release.ComponentVersion
                  Status = label
                  Detail = ""
                  FileId = Some selection.Selection.Release.File.Id }

            if workers.TryAdd(key, (local, finished)) then
                try
                    do! sources.SaveArtifact(artifact, selection)
                    let! view = status.Persist key downloading
                    monitor key context selection artifact local finished
                    return view
                with error ->
                    let mutable removed =
                        Unchecked.defaultof<CancellationTokenSource * TaskCompletionSource>

                    workers.TryRemove(key, &removed) |> ignore
                    local.Dispose()
                    finished.TrySetResult() |> ignore
                    return raise error
            else
                local.Dispose()
                let! current = store.SkseLoaders.ReadStatus(fst key, snd key)

                return
                    current |> Option.map SkseStatus.fromStored |> Option.defaultValue downloading
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
