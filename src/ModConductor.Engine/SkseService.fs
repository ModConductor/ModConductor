namespace ModConductor.Engine

open System
open System.Collections.Concurrent
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse

type SkseView =
    { Phase: SksePhase
      GameVersion: string
      ComponentVersion: string
      Status: string
      Detail: string
      FileId: int64 option }

type SkseCoordinator
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        games: IGameContexts,
        store: OperationStore,
        handoff: IOAuthHandoff
    ) =
    let lifetime = new CancellationTokenSource()
    let workers = ConcurrentDictionary<Guid * Guid, CancellationTokenSource>()

    let phaseName (value: SksePhase) =
        match value with
        | SksePhase.Available -> "available"
        | SksePhase.WaitingForNexus -> "waiting"
        | SksePhase.Downloading -> "downloading"
        | SksePhase.Installing -> "installing"
        | SksePhase.Ready -> "current"
        | SksePhase.Failed -> "failed"
        | SksePhase.UpdateAvailable -> "update"
        | SksePhase.Incompatible -> "incompatible"
        | SksePhase.SourceUnavailable -> "source-unavailable"
        | _ -> "unavailable"

    let phase (value: string) =
        match value with
        | "available" -> SksePhase.Available
        | "waiting" -> SksePhase.WaitingForNexus
        | "downloading" -> SksePhase.Downloading
        | "installing" -> SksePhase.Installing
        | "current" -> SksePhase.Ready
        | "failed" -> SksePhase.Failed
        | "update" -> SksePhase.UpdateAvailable
        | "incompatible" -> SksePhase.Incompatible
        | "source-unavailable" -> SksePhase.SourceUnavailable
        | _ -> SksePhase.Unavailable

    let fromStored (value: StoredSkseStatus) : SkseView =
        { Phase = phase value.Phase
          GameVersion = value.GameVersion
          ComponentVersion = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          FileId = value.NexusFileId }

    let persist (workspace, profile) (value: SkseView) =
        task {
            do!
                store.SkseLoaders.SaveStatus
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = phaseName value.Phase
                      GameVersion = value.GameVersion
                      ComponentVersion = value.ComponentVersion
                      Status = value.Status
                      Detail = value.Detail
                      NexusFileId = value.FileId
                      CheckedAt = DateTimeOffset.UtcNow }

            return value
        }

    let unavailable key problem =
        persist
            key
            { Phase = SksePhase.Unavailable
              GameVersion = ""
              ComponentVersion = ""
              Status = SkseProblem.message problem
              Detail = ""
              FileId = None }

    let failed key game componentVersion file status detail =
        persist
            key
            { Phase = SksePhase.Failed
              GameVersion = game
              ComponentVersion = componentVersion
              Status = status
              Detail = detail
              FileId = file }

    let facts (context: ModConductor.GameContexts.GameContextState) =
        let executable = context.Binding.Value.Evidence.Executable.Value
        executable.FileVersion, executable.Sha256

    let storedSelection
        workspace
        profile
        (context: ModConductor.GameContexts.GameContextState)
        (selection: SkseSelection)
        : StoredSkseSelection =
        let gameVersion, gameSha256 = facts context

        { ArtifactId = None
          WorkspaceId = workspace
          ProfileId = Some profile
          AccountId = nexus.Status.Account.Value.Subject
          GameVersion = gameVersion
          GameSha256 = gameSha256
          Selection = selection
          CheckedAt = DateTimeOffset.UtcNow }

    let resolve workspace profile =
        task {
            let! context = games.Read workspace

            match context with
            | Error _ -> return Error SkseProblem.GameUnavailable
            | Ok context ->
                let! source = nexus.ReadMod("skyrimspecialedition", SkseResolver.NexusModId)

                return
                    source
                    |> Result.mapError (NexusProblem.message >> SkseProblem.SourceUnavailable)
                    |> Result.bind (fun source ->
                        SkseResolver.select
                            context
                            (SkseResolver.releases source)
                            nexus.Status.Account)
                    |> Result.map (fun selection ->
                        context, storedSelection workspace profile context selection)
        }

    let reference (selection: StoredSkseSelection) keyed =
        let release = selection.Selection.Release

        { Account = selection.AccountId
          Game = "skyrimspecialedition"
          ModId = release.ModId
          FileId = release.File.Id
          Keyed = keyed
          Version = Some release.File.Version }

    let cacheFor (context: ModConductor.GameContexts.GameContextState) workspace =
        task {
            match nexus.Status.Account with
            | None -> return None
            | Some account ->
                let _, gameSha256 = facts context
                return! store.SkseLoaders.Cached(workspace, account.Subject, gameSha256)
        }

    let saveArtifact artifact selection =
        store.SkseLoaders.SaveArtifactSelection(
            artifact,
            { selection with
                ArtifactId = Some artifact.Id }
        )

    let monitor
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        (artifact: Artifact)
        =
        let local = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)

        if workers.TryAdd(key, local) then
            (task {
                let gameVersion, _ = facts context
                let release = selection.Selection.Release

                try
                    let waitForArtifact () =
                        Task.Run(fun () ->
                            let mutable current = artifact
                            let mutable waiting = true

                            while waiting do
                                local.Token.ThrowIfCancellationRequested()

                                match current.State, current.Download with
                                | (ArtifactState.Ready | ArtifactState.Installed), _ ->
                                    waiting <- false
                                | ArtifactState.Incomplete, Some download when
                                    download.State = DownloadState.Failed
                                    || download.State = DownloadState.Paused
                                    ->
                                    raise (
                                        IO.IOException(
                                            current.Problem
                                            |> Option.defaultValue "The SKSE download stopped."
                                        )
                                    )
                                | _ ->
                                    Task.Delay(100, local.Token).GetAwaiter().GetResult()

                                    current <-
                                        store.Artifacts
                                            .Read(fst key, current.Id)
                                            .GetAwaiter()
                                            .GetResult()
                                        |> Result.defaultWith (fun _ ->
                                            raise (
                                                IO.IOException "The SKSE archive is unavailable."
                                            ))

                            current)

                    let! current = waitForArtifact ()

                    if not local.IsCancellationRequested then
                        do! saveArtifact current selection

                        let! _ =
                            persist
                                key
                                { Phase = SksePhase.Installing
                                  GameVersion = gameVersion
                                  ComponentVersion = string release.ComponentVersion
                                  Status = "Installing SKSE"
                                  Detail = ""
                                  FileId = Some release.File.Id }

                        let! _ =
                            store.InstallSkse(
                                fst key,
                                snd key,
                                release,
                                current,
                                selection.CheckedAt,
                                local.Token
                            )

                        let! _ =
                            persist
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
                    failed
                        key
                        gameVersion
                        (string release.ComponentVersion)
                        (Some release.File.Id)
                        "SKSE setup failed"
                        error.Message
                    |> fun pending -> pending.GetAwaiter().GetResult() |> ignore

                let mutable removed = Unchecked.defaultof<CancellationTokenSource>
                workers.TryRemove(key, &removed) |> ignore
                local.Dispose()
            }
            :> Task)
            |> ignore
        else
            local.Dispose()

    let prepareArtifact
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        (artifact: Artifact)
        (label: string)
        =
        task {
            do! saveArtifact artifact selection
            let gameVersion, _ = facts context

            let! view =
                persist
                    key
                    { Phase = SksePhase.Downloading
                      GameVersion = gameVersion
                      ComponentVersion = string selection.Selection.Release.ComponentVersion
                      Status = label
                      Detail = ""
                      FileId = Some selection.Selection.Release.File.Id }

            monitor key context selection artifact
            return view
        }

    let installedState
        key
        (context: ModConductor.GameContexts.GameContextState)
        (loader: StoredSkseLoader)
        =
        task {
            let gameVersion, gameSha256 = facts context
            let! current = resolve (fst key) (snd key)

            match current with
            | Error SkseProblem.UnknownCompatibility ->
                return!
                    persist
                        key
                        { Phase = SksePhase.Incompatible
                          GameVersion = gameVersion
                          ComponentVersion = loader.Loader.ComponentVersion
                          Status = "Installed SKSE is incompatible"
                          Detail =
                            "No author release declares support for the checked Skyrim version. The working setup was not replaced."
                          FileId = Some loader.NexusFileId }
            | Error problem ->
                return!
                    persist
                        key
                        { Phase = SksePhase.SourceUnavailable
                          GameVersion = gameVersion
                          ComponentVersion = loader.Loader.ComponentVersion
                          Status = "SKSE update check unavailable"
                          Detail =
                            SkseProblem.message problem + " The installed setup was not replaced."
                          FileId = Some loader.NexusFileId }
            | Ok(_, selection) when loader.Loader.GameSha256 <> gameSha256 ->
                return!
                    persist
                        key
                        { Phase = SksePhase.Incompatible
                          GameVersion = gameVersion
                          ComponentVersion = loader.Loader.ComponentVersion
                          Status = "Skyrim changed"
                          Detail =
                            "The installed SKSE loader was validated for a different game build. The working setup was not replaced."
                          FileId = Some loader.NexusFileId }
            | Ok(_, selection) when
                selection.Selection.Release.File.Id <> loader.NexusFileId
                || string selection.Selection.Release.ComponentVersion
                   <> loader.Loader.ComponentVersion
                ->
                return!
                    persist
                        key
                        { Phase = SksePhase.UpdateAvailable
                          GameVersion = gameVersion
                          ComponentVersion = string selection.Selection.Release.ComponentVersion
                          Status = "SKSE update available"
                          Detail =
                            "The installed version remains selected until you choose Set up SKSE."
                          FileId = Some selection.Selection.Release.File.Id }
            | Ok _ ->
                return!
                    persist
                        key
                        { Phase = SksePhase.Ready
                          GameVersion = gameVersion
                          ComponentVersion = loader.Loader.ComponentVersion
                          Status = "SKSE is current"
                          Detail = "Play uses the installed SKSE loader."
                          FileId = Some loader.NexusFileId }
        }

    member _.Read(workspace, profile) =
        task {
            let key = workspace, profile
            let! contextResult = games.Read workspace
            let! deployed = store.Deployments.Read profile

            match contextResult, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! saved = store.SkseLoaders.ReadStatus(workspace, profile)

                match saved with
                | Some status when status.Phase = "waiting" || status.Phase = "failed" ->
                    return fromStored status
                | _ ->
                    let! loader =
                        store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                    match loader with
                    | Some loader -> return! installedState key context loader
                    | None ->
                        let! resolved = resolve workspace profile

                        match resolved with
                        | Ok(context, selection) ->
                            let! existing =
                                downloads.FindNexus(workspace, reference selection false)

                            match existing with
                            | Some artifact ->
                                return!
                                    prepareArtifact key context selection artifact "Preparing SKSE"
                            | None ->
                                let gameVersion, _ = facts context

                                return!
                                    persist
                                        key
                                        { Phase = SksePhase.Available
                                          GameVersion = gameVersion
                                          ComponentVersion =
                                            string selection.Selection.Release.ComponentVersion
                                          Status = "Matching SKSE found"
                                          Detail =
                                            if
                                                selection.Selection.Acquisition = SkseAcquisition.Direct
                                            then
                                                "Download and setup can finish in Mod Conductor."
                                            else
                                                "Nexus Mods requires Mod Manager Download before setup can continue."
                                          FileId = Some selection.Selection.Release.File.Id }
                        | Error liveProblem ->
                            let! cached = cacheFor context workspace

                            match cached with
                            | Some cached ->
                                let! artifact =
                                    store.Artifacts.Read(workspace, cached.ArtifactId.Value)

                                match artifact with
                                | Ok artifact ->
                                    return!
                                        prepareArtifact
                                            key
                                            context
                                            { cached with ProfileId = Some profile }
                                            artifact
                                            "Installing cached SKSE"
                                | Error _ -> return! unavailable key liveProblem
                            | None -> return! unavailable key liveProblem
            | _ -> return! unavailable key SkseProblem.GameUnavailable
        }

    member _.Start(workspace, profile) =
        task {
            let key = workspace, profile
            let! resolved = resolve workspace profile

            match resolved with
            | Error liveProblem ->
                let! context = games.Read workspace

                match context with
                | Ok context when context.Binding.IsSome ->
                    let! cached = cacheFor context workspace

                    match cached with
                    | Some cached ->
                        let! artifact = store.Artifacts.Read(workspace, cached.ArtifactId.Value)

                        match artifact with
                        | Ok artifact ->
                            return!
                                prepareArtifact
                                    key
                                    context
                                    { cached with ProfileId = Some profile }
                                    artifact
                                    "Installing cached SKSE"
                        | Error _ -> return! unavailable key liveProblem
                    | None -> return! unavailable key liveProblem
                | _ -> return! unavailable key liveProblem
            | Ok(context, selection) ->
                let release = selection.Selection.Release
                let! existing = downloads.FindNexus(workspace, reference selection false)

                match existing with
                | Some artifact ->
                    return! prepareArtifact key context selection artifact "Preparing SKSE"
                | None when selection.Selection.Acquisition = SkseAcquisition.NexusPage ->
                    try
                        do!
                            handoff.Open(
                                Uri(
                                    "https://www.nexusmods.com/skyrimspecialedition/mods/"
                                    + string release.ModId
                                    + "?tab=files&file_id="
                                    + string release.File.Id
                                ),
                                lifetime.Token
                            )

                        do! store.SkseLoaders.SavePending selection
                        let gameVersion, _ = facts context

                        return!
                            persist
                                key
                                { Phase = SksePhase.WaitingForNexus
                                  GameVersion = gameVersion
                                  ComponentVersion = string release.ComponentVersion
                                  Status = "Waiting for Nexus Mods"
                                  Detail = "Select Mod Manager Download for the matching SKSE file."
                                  FileId = Some release.File.Id }
                    with error ->
                        return!
                            failed
                                key
                                selection.GameVersion
                                (string release.ComponentVersion)
                                (Some release.File.Id)
                                "Nexus Mods could not be opened"
                                error.Message
                | None ->
                    let! lease =
                        nexus.Resolve(
                            "skyrimspecialedition",
                            release.ModId,
                            release.File.Id,
                            selection.AccountId
                        )

                    match lease with
                    | Error problem ->
                        return!
                            failed
                                key
                                selection.GameVersion
                                (string release.ComponentVersion)
                                (Some release.File.Id)
                                "SKSE source unavailable"
                                (NexusProblem.message problem)
                    | Ok _ ->
                        let! started =
                            downloads.Start
                                { Id = Guid.NewGuid()
                                  WorkspaceId = workspace
                                  Name = release.File.Name
                                  Sources = [ DownloadSource.Nexus(reference selection false) ]
                                  ExpectedLength = release.File.Bytes
                                  ExpectedSha256 = None }

                        match started with
                        | Error problem ->
                            return!
                                failed
                                    key
                                    selection.GameVersion
                                    (string release.ComponentVersion)
                                    (Some release.File.Id)
                                    "SKSE download could not start"
                                    (string problem)
                        | Ok artifact ->
                            return!
                                prepareArtifact key context selection artifact "Downloading SKSE"
        }

    member this.Cancel(workspace, profile) =
        task {
            let key = workspace, profile

            match workers.TryGetValue key with
            | true, cancellation -> cancellation.Cancel()
            | _ -> ()

            let deadline = DateTime.UtcNow.AddSeconds 5.

            while workers.ContainsKey key && DateTime.UtcNow < deadline do
                do! Task.Delay 10

            do! store.SkseLoaders.RemovePending profile
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Ok deployed ->
                let! installed =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some loader ->
                    let! context = games.Read workspace

                    match context with
                    | Ok context -> return! installedState key context loader
                    | Error _ -> return! this.Read(workspace, profile)
                | None ->
                    return!
                        persist
                            key
                            { Phase = SksePhase.Available
                              GameVersion = ""
                              ComponentVersion = ""
                              Status = "SKSE setup was cancelled"
                              Detail = "No active profile generation was changed."
                              FileId = None }
            | Error _ -> return! this.Read(workspace, profile)
        }

    member _.AcceptNxm(id: Guid) =
        Task.Run(fun () ->
            task {
                let! pending = store.SkseLoaders.Pending()

                let failPending title detail (values: StoredSkseSelection list) =
                    task {
                        for selection in values do
                            let key = selection.WorkspaceId, selection.ProfileId.Value

                            let! _ =
                                failed
                                    key
                                    selection.GameVersion
                                    (string selection.Selection.Release.ComponentVersion)
                                    (Some selection.Selection.Release.File.Id)
                                    title
                                    detail

                            do! store.SkseLoaders.RemovePending(selection.ProfileId.Value)
                    }

                match nexus.ReadNxm id with
                | Error problem -> do! failPending problem.Title problem.Detail pending
                | Ok file ->
                    let matches =
                        pending
                        |> List.filter (fun selection ->
                            let release = selection.Selection.Release

                            file.Game = "skyrimspecialedition"
                            && file.ModId = release.ModId
                            && file.FileId = release.File.Id)

                    match matches, nexus.Status.Account with
                    | [], _ ->
                        do!
                            failPending
                                "This Nexus link is not the expected SKSE file"
                                "Use Mod Manager Download for the matching SKSE file shown by Mod Conductor."
                                pending
                    | _, None ->
                        do!
                            failPending
                                "Sign in to Nexus Mods"
                                "Use the Nexus account that started this SKSE setup."
                                matches
                    | _, Some account ->
                        match nexus.AdmitNxm(id, account.Subject) with
                        | Error problem -> do! failPending problem.Title problem.Detail matches
                        | Ok admitted ->
                            use admitted = admitted
                            let selection = matches.Head
                            let key = selection.WorkspaceId, selection.ProfileId.Value
                            let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

                            match metadata with
                            | Error problem ->
                                do!
                                    failPending
                                        "SKSE file details are unavailable"
                                        (NexusProblem.message problem)
                                        matches
                            | Ok metadata ->
                                let selection =
                                    { selection with
                                        Selection =
                                            { selection.Selection with
                                                Release =
                                                    { selection.Selection.Release with
                                                        File = metadata } }
                                        CheckedAt = DateTimeOffset.UtcNow }

                                let! started =
                                    downloads.Start
                                        { Id = Guid.NewGuid()
                                          WorkspaceId = selection.WorkspaceId
                                          Name = metadata.Name
                                          Sources =
                                            [ DownloadSource.Nexus(reference selection file.Keyed) ]
                                          ExpectedLength = metadata.Bytes
                                          ExpectedSha256 = None }

                                match started with
                                | Error problem ->
                                    do!
                                        failPending
                                            "SKSE download could not start"
                                            (string problem)
                                            matches
                                | Ok artifact ->
                                    admitted.Complete()
                                    do! store.SkseLoaders.RemovePending(selection.ProfileId.Value)
                                    let! context = games.Read selection.WorkspaceId

                                    match context with
                                    | Ok context when context.Binding.IsSome ->
                                        let! _ =
                                            prepareArtifact
                                                key
                                                context
                                                selection
                                                artifact
                                                "Downloading SKSE"

                                        ()
                                    | _ ->
                                        let! _ =
                                            failed
                                                key
                                                selection.GameVersion
                                                (string
                                                    selection.Selection.Release.ComponentVersion)
                                                (Some selection.Selection.Release.File.Id)
                                                "Skyrim is unavailable"
                                                "Refresh the selected Skyrim installation."

                                        ()
            }
            :> Task)
        |> ignore

    member _.CheckBeforePlay(workspace, profile) =
        task {
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Error _ -> return Ok()
            | Ok deployed ->
                let! loader =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match loader with
                | None -> return Ok()
                | Some loader ->
                    let! context = games.Read workspace

                    match context with
                    | Error _ ->
                        return Error "Refresh the selected Skyrim installation before Play."
                    | Ok context ->
                        let! state = installedState (workspace, profile) context loader

                        return
                            if state.Phase = SksePhase.Ready then
                                Ok()
                            else
                                Error(state.Status + ". " + state.Detail)
        }

    interface IDisposable with
        member _.Dispose() =
            lifetime.Cancel()

            for worker in workers.Values do
                try
                    worker.Cancel()
                with :? ObjectDisposedException ->
                    ()

            lifetime.Dispose()

type internal SkseService(coordinator: SkseCoordinator) =
    inherit SkseOperations.SkseOperationsBase()

    let ids (request: SkseRequest) =
        ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.ProfileId

    let wire value =
        let reply =
            SkseState(
                Phase = value.Phase,
                GameVersion = value.GameVersion,
                ComponentVersion = value.ComponentVersion,
                Status = value.Status,
                Detail = value.Detail
            )

        value.FileId |> Option.iter (fun id -> reply.NexusFileId <- id)
        reply

    override _.ReadSkse(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Read(workspace, profile)
            return wire value
        }

    override _.StartSkse(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.Start(workspace, profile)
            return wire value
        }
