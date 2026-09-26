namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type FnisCoordinator
    (nexus: NexusSession, downloads: DownloadSession, store: OperationStore, handoff: IOAuthHandoff)
    =
    let status = FnisStatusStore(store)

    let sources = FnisSources(nexus, downloads, store)

    let monitor =
        new FnisSetupMonitor(store, downloads, sources, status.Persist, status.Signal)

    let reader =
        FnisSetupReader(
            store,
            downloads,
            sources,
            status.Persist,
            status.Unavailable,
            status.Failed,
            (fun key selection artifact label ->
                monitor.PrepareArtifact(key, selection, artifact, label)),
            monitor.IsActive
        )

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

            try
                do!
                    handoff.Open(
                        Uri(FnisCatalogue.Source + "?tab=files&file_id=" + string release.File.Id),
                        monitor.Token
                    )

                do! store.FnisSetups.SavePending selection

                return!
                    status.Persist
                        workspace
                        profile
                        { Phase = FnisPhase.WaitingForNexus
                          Version = string release.ComponentVersion
                          Status = "Waiting for Nexus Mods"
                          Detail = "Select Mod Manager Download for FNIS Behavior SE 7.6."
                          FileId = Some release.File.Id
                          ArtifactId = None }
            with error ->
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

    let restoredState workspace profile =
        task {
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Error _ -> return! reader.Read(workspace, profile)
            | Ok deployed ->
                let! installed =
                    store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some installed -> return! reader.InstalledState(workspace, profile, installed)
                | None ->
                    return!
                        status.Persist
                            workspace
                            profile
                            { Phase = FnisPhase.Available
                              Version = FnisCatalogue.SupportedVersion
                              Status = "The previous FNIS setup was restored"
                              Detail = "No active FNIS generator is registered."
                              FileId = None
                              ArtifactId = None }
        }

    let recoverReceipt
        workspace
        profile
        (receipt: ModConductor.Deployment.DeploymentReceipt)
        token
        =
        task {
            let! recovered =
                store.Deployments.Recover(receipt.Id, receipt.Revision, true, ignore, token)

            match recovered with
            | Ok _ -> return! restoredState workspace profile
            | Error problem ->
                return!
                    status.Failed(
                        workspace,
                        profile,
                        FnisCatalogue.SupportedVersion,
                        None,
                        None,
                        "FNIS recovery failed",
                        string problem
                    )
        }

    let recover workspace profile token =
        task {
            do! monitor.Wait((workspace, profile), token)
            let! state = store.Deployments.Read profile

            match state with
            | Ok state when state.WorkspaceId = workspace && state.PendingReceipt.IsSome ->
                let! receipt = store.Deployments.Receipt(state.PendingReceipt.Value)

                match receipt with
                | Ok receipt -> return! recoverReceipt workspace profile receipt token
                | Error problem ->
                    return!
                        status.Failed(
                            workspace,
                            profile,
                            FnisCatalogue.SupportedVersion,
                            None,
                            None,
                            "FNIS recovery is unavailable",
                            string problem
                        )
            | _ -> return! reader.Read(workspace, profile)
        }

    member _.Changed = status.Changed

    member _.Read(workspace, profile) = reader.Read(workspace, profile)

    member _.Install(workspace, profile) =
        task {
            let! selected = sources.Resolve(workspace, profile)

            match selected with
            | Error problem -> return! installCached workspace profile problem
            | Ok selection -> return! installSelected workspace profile selection
        }

    member this.Cancel(workspace, profile) =
        task {
            let key = workspace, profile

            do! monitor.Cancel key

            let! saved = store.FnisSetups.ReadStatus(workspace, profile)

            match saved |> Option.bind _.ArtifactId with
            | Some artifact ->
                let! _ = downloads.Control(workspace, artifact, DownloadAction.Pause)
                ()
            | None -> ()

            do! store.FnisSetups.RemovePending profile
            let! deployed = store.Deployments.Read profile

            match deployed with
            | Ok deployed ->
                let! installed =
                    store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

                match installed with
                | Some installed -> return! reader.InstalledState(workspace, profile, installed)
                | None ->
                    return!
                        status.Persist
                            workspace
                            profile
                            { Phase = FnisPhase.Available
                              Version = FnisCatalogue.SupportedVersion
                              Status = "FNIS setup was cancelled"
                              Detail = "No active profile generation was changed."
                              FileId = None
                              ArtifactId = None }
            | Error _ -> return! this.Read(workspace, profile)
        }

    member this.Update(workspace, profile) = this.Install(workspace, profile)

    member this.Remove(workspace, profile, token) =
        task {
            try
                let! _ = store.RemoveFnis(workspace, profile, token)
                do! store.FnisSetups.RemovePending profile

                return!
                    status.Persist
                        workspace
                        profile
                        { Phase = FnisPhase.Available
                          Version = FnisCatalogue.SupportedVersion
                          Status = "FNIS was removed"
                          Detail =
                            "Foreign game files and retained component versions were preserved."
                          FileId = None
                          ArtifactId = None }
            with error ->
                let! state = store.Deployments.Read profile

                let recovery =
                    match state with
                    | Ok value -> value.PendingReceipt.IsSome
                    | Error _ -> false

                return!
                    status.Persist
                        workspace
                        profile
                        { Phase =
                            if recovery then
                                FnisPhase.RecoveryRequired
                            else
                                FnisPhase.Failed
                          Version = FnisCatalogue.SupportedVersion
                          Status =
                            if recovery then
                                "FNIS removal needs recovery"
                            else
                                "FNIS removal failed"
                          Detail = error.Message
                          FileId = None
                          ArtifactId = None }
        }

    member _.Recover(workspace, profile, token: CancellationToken) = recover workspace profile token

    member _.AcceptNxm(id: Guid) =
        FnisNxmIngress.accept
            nexus
            downloads
            store
            sources
            status.Failed
            (fun key selection artifact label ->
                monitor.PrepareArtifact(key, selection, artifact, label))
            id

    member internal _.Stop() = monitor.Stop()

    interface IDisposable with
        member _.Dispose() = (monitor :> IDisposable).Dispose()
