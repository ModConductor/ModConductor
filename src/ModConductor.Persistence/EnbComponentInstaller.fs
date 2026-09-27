namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbComponentInstaller
    (database: StateDatabase, artifacts: ArtifactStore, installations: InstallationStore) =
    member internal _.Install
        (
            workspace,
            gameRoot,
            pin: ModConductor.Enb.EnbComponentPin,
            fileId,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            token
        ) =
        task {
            let! current =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, artifact.Id)

            match current with
            | Error _ -> return Error(pin.Name + " archive is unavailable.")
            | Ok artifact when
                artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed
                ->
                return Error(pin.Name + " archive is not ready.")
            | Ok artifact when artifact.Sha256.IsNone ->
                return Error(pin.Name + " archive has no verified hash.")
            | Ok artifact ->
                let hash = artifact.Sha256.Value
                let pinned = ModConductor.Enb.EnbCatalogue.withHash hash pin

                let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                    { WorkspaceId = workspace
                      Id = artifact.Id
                      Revision = artifact.Revision }

                let! draft = installations.Prepare(reference, token)

                let layout =
                    match pin.Kind with
                    | ModConductor.Enb.EnbComponentKind.Runtime ->
                        ModConductor.Enb.EnbArchiveLayouts.runtime pinned draft.Manifest
                    | ModConductor.Enb.EnbComponentKind.Preset ->
                        ModConductor.Enb.EnbArchiveLayouts.leanPreset pinned draft.Manifest
                    | ModConductor.Enb.EnbComponentKind.Companion ->
                        ModConductor.Enb.EnbArchiveLayouts.dataCompanion pinned draft.Manifest

                match layout with
                | Error problem -> return Error(ModConductor.Enb.EnbProblem.message problem)
                | Ok layout ->
                    let installationId = Guid.NewGuid()

                    let started =
                        installations.SelectReviewed(
                            workspace,
                            draft.Id,
                            draft.Revision,
                            pin.Name,
                            pin.Version,
                            layout.Files
                        )
                        |> Result.bind (fun reviewed ->
                            installations.Start(
                                workspace,
                                reviewed.Id,
                                reviewed.Revision,
                                installationId
                            ))

                    match started with
                    | Error message -> return Error message
                    | Ok started ->
                        let mutable installed = started

                        while installed.State = ModConductor.ArchiveInstallation.InstallationState.Running do
                            do!
                                installations.WaitForChange(
                                    workspace,
                                    installationId,
                                    installed,
                                    token
                                )

                            let! current = installations.Read(workspace, installationId)
                            installed <- current

                        do! installations.WaitForWorker(installationId, token)

                        if
                            installed.State
                            <> ModConductor.ArchiveInstallation.InstallationState.Complete
                            || installed.ModId.IsNone
                            || installed.VersionId.IsNone
                        then
                            return
                                Error(
                                    installed.Problem
                                    |> Option.defaultValue (
                                        pin.Name + " installation did not complete."
                                    )
                                )
                        else
                            let! version =
                                database.Enqueue(fun () ->
                                    LibraryRows.version
                                        database.Connection
                                        null
                                        installed.VersionId.Value
                                        0
                                        20001
                                    |> Option.map (fun value -> { value with NextOffset = None }))

                            match version with
                            | None -> return Error(pin.Name + " installed version is unavailable.")
                            | Some version ->
                                let reviewedComponent =
                                    ModConductor.DeploymentPlanning.ComponentManifests.review
                                        workspace
                                        gameRoot
                                        ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                        { ModId = installed.ModId.Value
                                          Version = version
                                          Priority = 0
                                          Files = layout.ComponentFiles }

                                match reviewedComponent with
                                | Error _ ->
                                    return
                                        Error(
                                            pin.Name
                                            + " no longer matches its reviewed archive layout."
                                        )
                                | Ok reviewedComponent ->
                                    let stored: StoredEnbComponent =
                                        { Kind =
                                            match pin.Kind with
                                            | ModConductor.Enb.EnbComponentKind.Runtime -> "runtime"
                                            | ModConductor.Enb.EnbComponentKind.Preset -> "preset"
                                            | ModConductor.Enb.EnbComponentKind.Companion ->
                                                "companion:"
                                                + (pin.NexusModId
                                                   |> Option.map string
                                                   |> Option.defaultValue pin.Name)
                                          ModId = installed.ModId.Value
                                          VersionId = installed.VersionId.Value
                                          Version = pin.Version
                                          Sha256 = hash
                                          NexusModId = pin.NexusModId
                                          NexusFileId = fileId
                                          Source = pin.Source.AbsoluteUri
                                          Terms = pin.Terms.AbsoluteUri
                                          CheckedAt = DateTimeOffset.UtcNow }

                                    return Ok(reviewedComponent, stored)
        }
