namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse

type internal SkseStart
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        games: IGameContexts,
        store: OperationStore,
        handoff: IOAuthHandoff,
        sources: SkseSources,
        monitor: SkseSetupMonitor,
        status: SkseStatusStore
    ) =
    let cached workspace profile problem =
        task {
            let key = workspace, profile
            let! context = games.Read key

            match context with
            | Ok context when context.Binding.IsSome ->
                let! selection = sources.Cached(context, workspace)

                match selection with
                | None -> return! status.Unavailable key problem
                | Some selection ->
                    let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)

                    match artifact with
                    | Error _ -> return! status.Unavailable key problem
                    | Ok artifact ->
                        return!
                            monitor.PrepareArtifact(
                                key,
                                context,
                                { selection with
                                    ProfileId = Some profile },
                                artifact,
                                "Installing cached SKSE"
                            )
            | _ -> return! status.Unavailable key problem
        }

    let openNexusPage
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        =
        task {
            let release = selection.Selection.Release

            try
                do!
                    handoff.Open(
                        Uri(
                            "https://www.nexusmods.com/skyrimspecialedition/mods/"
                            + string release.ModId
                            + "?tab=files&file_id="
                            + string release.File.Id
                            + "&nmm=1"
                        ),
                        monitor.Token
                    )

                do! store.SkseLoaders.SavePending selection
                let gameVersion, _ = SkseStatus.facts context

                return!
                    status.Persist
                        key
                        { Phase = SksePhase.WaitingForNexus
                          GameVersion = gameVersion
                          ComponentVersion = string release.ComponentVersion
                          Status = "Waiting for Nexus Mods"
                          Detail = "Select Mod Manager Download for the matching SKSE file."
                          FileId = Some release.File.Id }
            with error ->
                return!
                    status.Failed
                        key
                        selection.GameVersion
                        (string release.ComponentVersion)
                        (Some release.File.Id)
                        "Nexus Mods could not be opened"
                        error.Message
        }

    let startDirect
        key
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        =
        task {
            let release = selection.Selection.Release

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
                    status.Failed
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
                          WorkspaceId = fst key
                          Name = release.File.Name
                          Sources = [ DownloadSource.Nexus(sources.Reference(selection, false)) ]
                          ExpectedLength = release.File.Bytes
                          ExpectedSha256 = None }

                match started with
                | Error problem ->
                    return!
                        status.Failed
                            key
                            selection.GameVersion
                            (string release.ComponentVersion)
                            (Some release.File.Id)
                            "SKSE download could not start"
                            (string problem)
                | Ok artifact ->
                    return!
                        monitor.PrepareArtifact(
                            key,
                            context,
                            selection,
                            artifact,
                            "Downloading SKSE"
                        )
        }

    let startSelected
        key
        retained
        (context: ModConductor.GameContexts.GameContextState)
        (selection: StoredSkseSelection)
        =
        task {
            let! existing =
                match retained with
                | Some(_, _, artifact) -> Task.FromResult(Some artifact)
                | None -> downloads.FindNexus(fst key, sources.Reference(selection, false))

            match existing with
            | Some artifact ->
                return! monitor.PrepareArtifact(key, context, selection, artifact, "Preparing SKSE")
            | None when selection.Selection.Acquisition = SkseAcquisition.NexusPage ->
                return! openNexusPage key context selection
            | None -> return! startDirect key context selection
        }

    member _.Start(workspace, profile, prepared: StoredSkseSelection option) =
        task {
            let! retained =
                match prepared with
                | Some _ -> Task.FromResult None
                | None -> sources.RetainedArchive(workspace, profile)

            let! resolved =
                match prepared, retained with
                | Some selection, _ ->
                    task {
                        let! context = games.Read(workspace, profile)

                        return
                            match context with
                            | Error _ -> Error SkseProblem.GameUnavailable
                            | Ok context when
                                context.Binding.IsSome
                                && SkseStatus.facts context = (selection.GameVersion,
                                                               selection.GameSha256)
                                ->
                                Ok(context, selection)
                            | Ok _ -> Error SkseProblem.StaleGame
                    }
                | None, Some(context, selection, _) -> Task.FromResult(Ok(context, selection))
                | None, None -> sources.Resolve(workspace, profile)

            match resolved with
            | Error problem when prepared.IsSome ->
                let selection = prepared.Value
                let release = selection.Selection.Release

                return!
                    status.Failed
                        (workspace, profile)
                        selection.GameVersion
                        (string release.ComponentVersion)
                        (Some release.File.Id)
                        "SKSE selection changed"
                        (SkseProblem.message problem)
            | Error problem -> return! cached workspace profile problem
            | Ok(context, selection) ->
                return! startSelected (workspace, profile) retained context selection
        }
