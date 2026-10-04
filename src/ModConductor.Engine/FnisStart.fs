namespace ModConductor.Engine

open System
open ModConductor.Fnis
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal FnisStart
    (
        nexus: NexusSession,
        downloads: DownloadSession,
        store: OperationStore,
        handoff: IOAuthHandoff,
        sources: FnisSources,
        monitor: FnisSetupMonitor,
        reader: FnisSetupReader,
        status: FnisStatusStore
    ) =
    let installCached workspace profile problem =
        task {
            let! cached = sources.Cached(workspace, profile)

            match cached with
            | None -> return! status.Unavailable workspace profile problem
            | Some selection ->
                let! artifact = store.Artifacts.Read(workspace, selection.ArtifactId.Value)

                match artifact with
                | Ok artifact ->
                    return!
                        monitor.PrepareArtifact(
                            (workspace, profile),
                            selection,
                            artifact,
                            "Installing cached FNIS"
                        )
                | Error _ -> return! status.Unavailable workspace profile problem
        }

    let openNexusPage workspace profile (selection: StoredFnisSelection) =
        task {
            let release = selection.Selection.Release

            let waiting =
                { Phase = FnisPhase.WaitingForNexus
                  Version = string release.ComponentVersion
                  Status = "Waiting for Nexus Mods"
                  Detail = "Select Mod Manager Download for FNIS Behavior SE 7.6."
                  FileId = Some release.File.Id
                  ArtifactId = None }

            let! claimed = store.FnisSetups.SavePending selection

            if not claimed then
                return waiting
            else
                try
                    let! view = status.Persist workspace profile waiting

                    do!
                        handoff.Open(
                            NexusWebLinks.fileDownload
                                "skyrimspecialedition"
                                release.ModId
                                release.File.Id,
                            monitor.Token
                        )

                    return view
                with error ->
                    do! store.FnisSetups.RemovePending profile

                    return!
                        status.Failed(
                            workspace,
                            profile,
                            string release.ComponentVersion,
                            Some release.File.Id,
                            None,
                            "Nexus Mods could not be opened",
                            error.Message
                        )
        }

    let startDirect workspace profile (selection: StoredFnisSelection) =
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
                    status.Failed(
                        workspace,
                        profile,
                        string release.ComponentVersion,
                        Some release.File.Id,
                        None,
                        "FNIS source unavailable",
                        NexusProblem.message problem
                    )
            | Ok _ ->
                let! started =
                    downloads.Start
                        { Id = Guid.NewGuid()
                          WorkspaceId = workspace
                          Name = release.File.Name
                          Sources = [ DownloadSource.Nexus(sources.Reference(selection, false)) ]
                          ExpectedLength = release.File.Bytes
                          ExpectedSha256 = None }

                match started with
                | Error problem ->
                    return!
                        status.Failed(
                            workspace,
                            profile,
                            string release.ComponentVersion,
                            Some release.File.Id,
                            None,
                            "FNIS download could not start",
                            string problem
                        )
                | Ok artifact ->
                    return!
                        monitor.PrepareArtifact(
                            (workspace, profile),
                            selection,
                            artifact,
                            "Downloading FNIS"
                        )
        }

    let installSelected workspace profile (selection: StoredFnisSelection) =
        task {
            let! existing = downloads.FindNexus(workspace, sources.Reference(selection, false))

            match existing with
            | Some artifact ->
                return!
                    monitor.PrepareArtifact(
                        (workspace, profile),
                        selection,
                        artifact,
                        "Preparing FNIS"
                    )
            | None when selection.Selection.Acquisition = FnisAcquisition.NexusPage ->
                return! openNexusPage workspace profile selection
            | None -> return! startDirect workspace profile selection
        }

    member _.Install(workspace, profile) =
        task {
            let! saved = store.FnisSetups.ReadStatus(workspace, profile)

            match saved with
            | Some value when
                value.Phase = "waiting"
                || value.Phase = "downloading"
                || value.Phase = "installing"
                ->
                return! reader.Read(workspace, profile)
            | _ ->
                let! selected = sources.Resolve(workspace, profile)

                match selected with
                | Error problem -> return! installCached workspace profile problem
                | Ok selection -> return! installSelected workspace profile selection
        }
