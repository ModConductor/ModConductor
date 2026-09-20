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

type internal SkseView =
    { Phase: SksePhase
      GameVersion: string
      ComponentVersion: string
      Status: string
      Detail: string
      FileId: int64 option }

type internal SkseCoordinator
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        games: IGameContexts,
        store: OperationStore,
        handoff: IOAuthHandoff
    ) =
    let lifetime = new CancellationTokenSource()
    let phases = ConcurrentDictionary<Guid * Guid, SkseView>()
    let workers = ConcurrentDictionary<Guid * Guid, Task>()
    let pending =
        ConcurrentDictionary<Guid * Guid, ModConductor.GameContexts.GameContextState * SkseRelease>()

    let unavailable problem =
        { Phase = SksePhase.Unavailable
          GameVersion = ""
          ComponentVersion = ""
          Status = SkseProblem.message problem
          Detail = ""
          FileId = None }

    let resolve workspace =
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
                        SkseResolver.select context (SkseResolver.releases source) nexus.Status.Account
                        |> Result.map (fun selection -> context, selection))
        }

    let monitor
        key
        (context: ModConductor.GameContexts.GameContextState)
        (release: SkseRelease)
        (artifact: Artifact)
        =
        workers.GetOrAdd(
            key,
            fun _ ->
                task {
                    try
                        let workspace, profile = key
                        let mutable current = artifact
                        let mutable waiting = true

                        while waiting && not lifetime.IsCancellationRequested do
                            match current.State, current.Download with
                            | ArtifactState.Ready, _ -> waiting <- false
                            | ArtifactState.Incomplete, Some download when
                                download.State = DownloadState.Failed
                                || download.State = DownloadState.Paused
                                ->
                                waiting <- false
                                raise (IO.IOException(current.Problem |> Option.defaultValue "The SKSE download stopped."))
                            | _ ->
                                do! Task.Delay(100, lifetime.Token)
                                let! read = (store.Artifacts).Read(workspace, current.Id)
                                current <-
                                    read
                                    |> Result.defaultWith (fun _ ->
                                        raise (IO.IOException "The SKSE archive is unavailable."))

                        if not lifetime.IsCancellationRequested then
                            phases[key] <-
                                { Phase = SksePhase.Installing
                                  GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                  ComponentVersion = string release.ComponentVersion
                                  Status = "Installing SKSE"
                                  Detail = ""
                                  FileId = Some release.File.Id }
                            pending.TryRemove key |> ignore

                            let! _ = store.InstallSkse(workspace, profile, release, current, lifetime.Token)

                            phases[key] <-
                                { Phase = SksePhase.Ready
                                  GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                  ComponentVersion = string release.ComponentVersion
                                  Status = "SKSE is ready"
                                  Detail = "Play uses the installed SKSE loader."
                                  FileId = Some release.File.Id }
                    with
                    | :? OperationCanceledException when lifetime.IsCancellationRequested -> ()
                    | error ->
                        phases[key] <-
                            { Phase = SksePhase.Failed
                              GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                              ComponentVersion = string release.ComponentVersion
                              Status = "SKSE setup failed"
                              Detail = error.Message
                              FileId = Some release.File.Id }
                        pending.TryRemove key |> ignore
                    workers.TryRemove key |> ignore
                }
                :> Task
        )
        |> ignore

    member _.Read(workspace, profile) =
        task {
            match phases.TryGetValue((workspace, profile)) with
            | true, value -> return value
            | _ ->
                let! contextResult = games.Read workspace
                let! deployed = store.Deployments.Read profile

                match contextResult with
                | Ok context when context.Binding.IsSome ->
                    let! loader =
                        (store.SkseLoaders :> ModConductor.GameLaunching.IComponentLoaderSelection).Read(
                            workspace,
                            profile,
                            deployed |> Result.toOption |> Option.bind _.ActiveGeneration
                        )

                    match loader with
                    | Some loader when loader.GameSha256 = context.Binding.Value.Evidence.Executable.Value.Sha256 ->
                        return
                            { Phase = SksePhase.Ready
                              GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                              ComponentVersion = loader.ComponentVersion
                              Status = "SKSE is ready"
                              Detail = "Play uses the installed SKSE loader."
                              FileId = None }
                    | _ ->
                        let! resolved = resolve workspace

                        match resolved with
                        | Error problem -> return unavailable problem
                        | Ok(context, selection) ->
                            let account = nexus.Status.Account.Value
                            let release = selection.Release
                            let! existing =
                                downloads.FindNexus(
                                    workspace,
                                    { Account = account.Subject
                                      Game = "skyrimspecialedition"
                                      ModId = release.ModId
                                      FileId = release.File.Id
                                      Keyed = false
                                      Version = Some release.File.Version }
                                )

                            match existing with
                            | Some artifact ->
                                monitor (workspace, profile) context release artifact
                                return
                                    { Phase = SksePhase.Downloading
                                      GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                      ComponentVersion = string release.ComponentVersion
                                      Status = "Preparing SKSE"
                                      Detail = ""
                                      FileId = Some release.File.Id }
                            | None ->
                                return
                                    { Phase = SksePhase.Available
                                      GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                      ComponentVersion = string release.ComponentVersion
                                      Status = "Matching SKSE found"
                                      Detail =
                                        if selection.Acquisition = SkseAcquisition.Direct then
                                            "Download and setup can finish in Mod Conductor."
                                        else
                                            "Nexus Mods requires Mod Manager Download before setup can continue."
                                      FileId = Some release.File.Id }
                | _ -> return unavailable SkseProblem.GameUnavailable
        }

    member _.Start(workspace, profile) =
        task {
            let! resolved = resolve workspace

            match resolved with
            | Error problem -> return unavailable problem
            | Ok(context, selection) ->
                let account = nexus.Status.Account.Value
                let release = selection.Release
                let reference =
                    { Account = account.Subject
                      Game = "skyrimspecialedition"
                      ModId = release.ModId
                      FileId = release.File.Id
                      Keyed = false
                      Version = Some release.File.Version }

                let! existing = downloads.FindNexus(workspace, reference)

                match existing with
                | Some artifact ->
                    monitor (workspace, profile) context release artifact
                    return
                        { Phase = SksePhase.Downloading
                          GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                          ComponentVersion = string release.ComponentVersion
                          Status = "Preparing SKSE"
                          Detail = ""
                          FileId = Some release.File.Id }
                | None when selection.Acquisition = SkseAcquisition.NexusPage ->
                    do!
                        handoff.Open(
                            Uri("https://www.nexusmods.com/skyrimspecialedition/mods/" + string release.ModId + "?tab=files&file_id=" + string release.File.Id),
                            lifetime.Token
                        )

                    let value =
                        { Phase = SksePhase.WaitingForNexus
                          GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                          ComponentVersion = string release.ComponentVersion
                          Status = "Waiting for Nexus Mods"
                          Detail = "Select Mod Manager Download for the matching SKSE file."
                          FileId = Some release.File.Id }

                    phases[(workspace, profile)] <- value
                    pending[(workspace, profile)] <- context, release
                    return value
                | None ->
                    let! lease = nexus.Resolve("skyrimspecialedition", release.ModId, release.File.Id, account.Subject)

                    match lease with
                    | Error problem -> return unavailable (SkseProblem.SourceUnavailable(NexusProblem.message problem))
                    | Ok _ ->
                        let! started =
                            downloads.Start
                                { Id = Guid.NewGuid()
                                  WorkspaceId = workspace
                                  Name = release.File.Name
                                  Sources = [ DownloadSource.Nexus reference ]
                                  ExpectedLength = release.File.Bytes
                                  ExpectedSha256 = None }

                        match started with
                        | Error _ -> return unavailable (SkseProblem.TransferFailed "The SKSE download could not start.")
                        | Ok artifact ->
                            monitor (workspace, profile) context release artifact
                            return
                                { Phase = SksePhase.Downloading
                                  GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                  ComponentVersion = string release.ComponentVersion
                                  Status = "Downloading SKSE"
                                  Detail = ""
                                  FileId = Some release.File.Id }
        }

    member _.AcceptNxm(id: Guid) =
        Task.Run(fun () ->
            task {
                match nexus.Status.Account, nexus.ReadNxm id with
                | Some account, Ok file ->
                    match
                        pending
                        |> Seq.tryFind (fun entry ->
                            let _, release = entry.Value
                            file.Game = "skyrimspecialedition"
                            && file.ModId = release.ModId
                            && file.FileId = release.File.Id)
                    with
                    | None -> ()
                    | Some entry ->
                        match nexus.AdmitNxm(id, account.Subject) with
                        | Error _ -> ()
                        | Ok admitted ->
                            use admitted = admitted
                            let context, release = entry.Value
                            let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

                            match metadata with
                            | Error _ -> ()
                            | Ok metadata ->
                                let! started =
                                    downloads.Start
                                        { Id = Guid.NewGuid()
                                          WorkspaceId = fst entry.Key
                                          Name = metadata.Name
                                          Sources =
                                            [ DownloadSource.Nexus
                                                  { Account = account.Subject
                                                    Game = file.Game
                                                    ModId = file.ModId
                                                    FileId = file.FileId
                                                    Keyed = file.Keyed
                                                    Version = Some metadata.Version } ]
                                          ExpectedLength = metadata.Bytes
                                          ExpectedSha256 = None }

                                match started with
                                | Ok artifact ->
                                    admitted.Complete()
                                    phases[entry.Key] <-
                                        { Phase = SksePhase.Downloading
                                          GameVersion = context.Binding.Value.Evidence.Executable.Value.FileVersion
                                          ComponentVersion = string release.ComponentVersion
                                          Status = "Downloading SKSE"
                                          Detail = ""
                                          FileId = Some release.File.Id }
                                    monitor entry.Key context release artifact
                                | Error _ -> ()
                | _ -> ()
            }
            :> Task)
        |> ignore

    interface IDisposable with
        member _.Dispose() = lifetime.Cancel(); lifetime.Dispose()

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
