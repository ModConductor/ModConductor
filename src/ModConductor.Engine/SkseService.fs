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
    let changed = Event<Guid * Guid>()

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

    let storedStatus (workspace, profile) (value: SkseView) =
        { WorkspaceId = workspace
          ProfileId = profile
          Phase = phaseName value.Phase
          GameVersion = value.GameVersion
          ComponentVersion = value.ComponentVersion
          Status = value.Status
          Detail = value.Detail
          NexusFileId = value.FileId
          CheckedAt = DateTimeOffset.UtcNow }

    let persist key (value: SkseView) =
        task {
            do! store.SkseLoaders.SaveStatus(storedStatus key value)
            changed.Trigger key
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

    let resolveContext workspace profile context =
        task {
            let! source = nexus.ReadMod("skyrimspecialedition", SkseResolver.NexusModId)

            return
                source
                |> Result.mapError (NexusProblem.message >> SkseProblem.SourceUnavailable)
                |> Result.bind (fun source ->
                    SkseResolver.select context (SkseResolver.releases source) nexus.Status.Account)
                |> Result.map (fun selection ->
                    context, storedSelection workspace profile context selection)
        }

    let resolve workspace profile =
        task {
            let! context = games.Read(workspace, profile)

            match context with
            | Error _ -> return Error SkseProblem.GameUnavailable
            | Ok context -> return! resolveContext workspace profile context
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

    let retainedArchive workspace profile =
        task {
            let! context = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match context, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! installed =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some _ -> return None
                | None ->
                    let! cached = cacheFor context workspace

                    match cached with
                    | None -> return None
                    | Some selection ->
                        let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)
                        return artifact |> Result.toOption |> Option.map (fun value -> context, selection, value)
            | _ -> return None
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
        (local: CancellationTokenSource)
        =
        (task {
            let gameVersion, _ = facts context
            let release = selection.Selection.Release

            try
                let mutable current = artifact
                let mutable waiting = true

                while waiting do
                    local.Token.ThrowIfCancellationRequested()

                    match current.State, current.Download with
                    | (ArtifactState.Ready | ArtifactState.Installed), _ -> waiting <- false
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
                        do!
                            downloads.WaitForChange(
                                fst key,
                                [ current.Id, current.Revision ],
                                local.Token
                            )

                        let! latest = store.Artifacts.Read(fst key, current.Id)

                        current <-
                            latest
                            |> Result.defaultWith (fun _ ->
                                raise (IO.IOException "The SKSE archive is unavailable."))

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
            changed.Trigger key
        }
        :> Task)
        |> ignore

    let prepareArtifact
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        (artifact: Artifact)
        (label: string)
        =
        task {
            let local = CancellationTokenSource.CreateLinkedTokenSource(lifetime.Token)
            let gameVersion, _ = facts context

            let downloading =
                { Phase = SksePhase.Downloading
                  GameVersion = gameVersion
                  ComponentVersion = string selection.Selection.Release.ComponentVersion
                  Status = label
                  Detail = ""
                  FileId = Some selection.Selection.Release.File.Id }

            if workers.TryAdd(key, local) then
                try
                    do! saveArtifact artifact selection
                    let! view = persist key downloading
                    monitor key context selection artifact local
                    return view
                with error ->
                    let mutable removed = Unchecked.defaultof<CancellationTokenSource>
                    workers.TryRemove(key, &removed) |> ignore
                    local.Dispose()
                    return raise error
            else
                local.Dispose()
                let! status = store.SkseLoaders.ReadStatus(fst key, snd key)
                return status |> Option.map fromStored |> Option.defaultValue downloading
        }

    let newerVersion (offered: string) (installed: string) =
        match Version.TryParse offered, Version.TryParse installed with
        | (true, latest), (true, current) -> latest > current
        | _ -> false

    let installedState
        (context: ModConductor.GameContexts.GameContextState)
        (loader: StoredSkseLoader)
        (saved: StoredSkseStatus option)
        =
        let gameVersion, gameSha256 = facts context

        if loader.Loader.GameSha256 <> gameSha256 then
            { Phase = SksePhase.Incompatible
              GameVersion = gameVersion
              ComponentVersion = loader.Loader.ComponentVersion
              Status = "Skyrim changed"
              Detail = "The installed SKSE loader is for a different Skyrim build."
              FileId = Some loader.NexusFileId }
        else
            match saved with
            | Some status when
                status.Phase = "update"
                && status.GameVersion = gameVersion
                && newerVersion status.ComponentVersion loader.Loader.ComponentVersion
                ->
                fromStored status
            | _ ->
                { Phase = SksePhase.Ready
                  GameVersion = gameVersion
                  ComponentVersion = loader.Loader.ComponentVersion
                  Status = "SKSE is installed"
                  Detail = ""
                  FileId = Some loader.NexusFileId }

    member _.Read(workspace, profile) =
        task {
            let key = workspace, profile
            let! contextResult = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match contextResult, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! saved = store.SkseLoaders.ReadStatus(workspace, profile)

                match saved with
                | Some status when status.Phase = "waiting" || status.Phase = "failed" ->
                    return fromStored status
                | Some status when status.Phase = "downloading" || status.Phase = "installing" ->
                    if workers.ContainsKey key then
                        return fromStored status
                    else
                        return!
                            failed
                                key
                                status.GameVersion
                                status.ComponentVersion
                                status.NexusFileId
                                "SKSE setup stopped"
                                "Select Try again to install the downloaded archive."
                | _ ->
                    let! loader =
                        store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                    match loader with
                    | Some loader -> return installedState context loader saved
                    | None ->
                        let gameVersion, _ = facts context

                        return
                            { Phase = SksePhase.Available
                              GameVersion = gameVersion
                              ComponentVersion = ""
                              Status = "SKSE is not installed"
                              Detail = ""
                              FileId = None }
            | _ -> return! unavailable key SkseProblem.GameUnavailable
        }

    member this.CheckUpdate(workspace, profile) =
        task {
            let! context = games.Read(workspace, profile)
            let! deployed = store.Deployments.Read profile

            match context, deployed with
            | Ok context, Ok deployed when
                context.Binding.IsSome && deployed.WorkspaceId = workspace
                ->
                let! loader =
                    store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match loader with
                | None ->
                    return
                        { Phase = SksePhase.Available
                          GameVersion = fst (facts context)
                          ComponentVersion = ""
                          Status = "SKSE is not installed"
                          Detail = ""
                          FileId = None }
                | Some loader ->
                    let! saved = store.SkseLoaders.ReadStatus(workspace, profile)

                    match saved with
                    | Some state when
                        state.Phase = "waiting"
                        || state.Phase = "downloading"
                        || state.Phase = "installing"
                        -> return fromStored state
                    | _ ->
                        let! resolved = resolveContext workspace profile context

                        match resolved with
                        | Error _ -> return! this.Read(workspace, profile)
                        | Ok(_, selection) ->
                            let! current = store.Deployments.Read profile

                            let! active =
                                store.SkseLoaders.ReadStored(
                                    workspace,
                                    profile,
                                    current |> Result.toOption |> Option.bind _.ActiveGeneration
                                )

                            let! latestStatus = store.SkseLoaders.ReadStatus(workspace, profile)

                            let sameLoader =
                                active
                                |> Option.exists (fun value ->
                                    value.VersionId = loader.VersionId
                                    && value.Loader.GenerationId = loader.Loader.GenerationId)

                            let busyOrFailed =
                                latestStatus
                                |> Option.exists (fun state ->
                                    state.Phase = "waiting"
                                    || state.Phase = "downloading"
                                    || state.Phase = "installing"
                                    || state.Phase = "failed")

                            if workers.ContainsKey(workspace, profile) || not sameLoader || busyOrFailed then
                                return! this.Read(workspace, profile)
                            else
                                let latest = selection.Selection.Release.ComponentVersion

                                let newer =
                                    newerVersion (string latest) loader.Loader.ComponentVersion

                                let state =
                                    if newer then
                                        { Phase = SksePhase.UpdateAvailable
                                          GameVersion = fst (facts context)
                                          ComponentVersion = string latest
                                          Status = "SKSE update available"
                                          Detail = ""
                                          FileId = Some selection.Selection.Release.File.Id }
                                    else installedState context loader None

                                let! published =
                                    store.SkseLoaders.SaveCheckedUpdateStatus(
                                        loader.Loader.GenerationId,
                                        loader.VersionId,
                                        saved,
                                        storedStatus (workspace, profile) state
                                    )

                                if published then return state
                                else return! this.Read(workspace, profile)
            | _ ->
                return
                    { Phase = SksePhase.Unavailable
                      GameVersion = ""
                      ComponentVersion = ""
                      Status = "SKSE is unavailable"
                      Detail = ""
                      FileId = None }
        }

    member _.Start(workspace, profile) =
        task {
            let key = workspace, profile
            let! retained = retainedArchive workspace profile
            let! resolved =
                match retained with
                | Some(context, selection, _) -> Task.FromResult(Ok(context, selection))
                | None -> resolve workspace profile

            match resolved with
            | Error liveProblem ->
                let! context = games.Read(workspace, profile)

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
                let! existing =
                    match retained with
                    | Some(_, _, artifact) -> Task.FromResult(Some artifact)
                    | None -> downloads.FindNexus(workspace, reference selection false)

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
                    let! context = games.Read(workspace, profile)

                    match context with
                    | Ok context when context.Binding.IsSome ->
                        return installedState context loader None
                    | Ok _
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

    member _.Changed = changed.Publish

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
                                    let! context =
                                        games.Read(selection.WorkspaceId, selection.ProfileId.Value)

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
                    let! context = games.Read(workspace, profile)

                    match context with
                    | Error _ ->
                        return Error "Refresh the selected Skyrim installation before Play."
                    | Ok context when context.Binding.IsSome ->
                        let _, gameSha256 = facts context

                        return
                            if loader.Loader.GameSha256 = gameSha256 then
                                Ok()
                            else
                                Error "The installed SKSE loader is for a different Skyrim build."
                    | Ok _ -> return Error "Refresh the selected Skyrim installation before Play."
        }

    member this.Remove(workspace, profile, token) =
        task {
            let! _ = store.RemoveSkse(workspace, profile, token)
            return! this.Read(workspace, profile)
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

    override _.CheckSkseUpdate(request, _) =
        task {
            let workspace, profile = ids request
            let! value = coordinator.CheckUpdate(workspace, profile)
            return wire value
        }
