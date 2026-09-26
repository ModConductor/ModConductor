namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence

type internal SkseNxmIngress
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        games: IGameContexts,
        store: OperationStore,
        sources: SkseSources,
        monitor: SkseSetupMonitor,
        status: SkseStatusStore
    ) =
    let failPending title detail (values: StoredSkseSelection list) =
        task {
            for selection in values do
                let key = selection.WorkspaceId, selection.ProfileId.Value

                let! _ =
                    status.Failed
                        key
                        selection.GameVersion
                        (string selection.Selection.Release.ComponentVersion)
                        (Some selection.Selection.Release.File.Id)
                        title
                        detail

                do! store.SkseLoaders.RemovePending(selection.ProfileId.Value)
        }

    let installSelected (selection: StoredSkseSelection) (artifact: Artifact) =
        task {
            let key = selection.WorkspaceId, selection.ProfileId.Value
            let! context = games.Read key

            match context with
            | Ok context when context.Binding.IsSome ->
                let! _ =
                    monitor.PrepareArtifact(key, context, selection, artifact, "Downloading SKSE")

                return ()
            | _ ->
                let! _ =
                    status.Failed
                        key
                        selection.GameVersion
                        (string selection.Selection.Release.ComponentVersion)
                        (Some selection.Selection.Release.File.Id)
                        "Skyrim is unavailable"
                        "Refresh the selected Skyrim installation."

                return ()
        }

    let downloadSelected (file: NxmFile) (selection: StoredSkseSelection) =
        task {
            let! metadata = nexus.ReadFile(file.Game, file.ModId, file.FileId)

            match metadata with
            | Error problem ->
                return Error("SKSE file details are unavailable", NexusProblem.message problem)
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
                            [ DownloadSource.Nexus(sources.Reference(selection, file.Keyed)) ]
                          ExpectedLength = metadata.Bytes
                          ExpectedSha256 = None }

                return
                    started
                    |> Result.map (fun artifact -> selection, artifact)
                    |> Result.mapError (fun problem ->
                        "SKSE download could not start", string problem)
        }

    let acceptAdmitted file (matches: StoredSkseSelection list) (admitted: NxmAdmission) =
        task {
            use admitted = admitted
            let! downloaded = downloadSelected file matches.Head

            match downloaded with
            | Error(title, detail) -> do! failPending title detail matches
            | Ok(selection, artifact) ->
                admitted.Complete()
                do! store.SkseLoaders.RemovePending(selection.ProfileId.Value)
                do! installSelected selection artifact
        }

    let acceptFile id (file: NxmFile) (pending: StoredSkseSelection list) =
        task {
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
                | Ok admitted -> do! acceptAdmitted file matches admitted
        }

    member _.Accept(id: Guid) =
        Task.Run(fun () ->
            task {
                let! pending = store.SkseLoaders.Pending()

                match nexus.ReadNxm id with
                | Error problem -> do! failPending problem.Title problem.Detail pending
                | Ok file -> do! acceptFile id file pending
            }
            :> Task)
        |> ignore
