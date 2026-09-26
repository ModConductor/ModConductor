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
        let fail detail = raise (IO.IOException detail)

        task {
            let! current =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, artifact.Id)

            let artifact =
                current
                |> Result.defaultWith (fun _ -> fail (pin.Name + " archive is unavailable."))

            if
                artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed
            then
                fail (pin.Name + " archive is not ready.")

            let hash =
                artifact.Sha256
                |> Option.defaultWith (fun () -> fail (pin.Name + " archive has no verified hash."))

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
                |> Result.defaultWith (ModConductor.Enb.EnbProblem.message >> fail)

            let reviewed =
                installations.SelectReviewed(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    pin.Name,
                    pin.Version,
                    layout.Files
                )

            let installationId = Guid.NewGuid()

            let mutable installed =
                installations.Start(workspace, reviewed.Id, reviewed.Revision, installationId)

            while installed.State = ModConductor.ArchiveInstallation.InstallationState.Running do
                do! installations.WaitForChange(workspace, installationId, installed, token)
                let! current = installations.Read(workspace, installationId)
                installed <- current

            do! installations.WaitForWorker(installationId, token)

            if
                installed.State <> ModConductor.ArchiveInstallation.InstallationState.Complete
                || installed.ModId.IsNone
                || installed.VersionId.IsNone
            then
                fail (
                    installed.Problem
                    |> Option.defaultValue (pin.Name + " installation did not complete.")
                )

            let! version =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null installed.VersionId.Value 0 20001
                    |> Option.map (fun value -> { value with NextOffset = None }))

            let version =
                version
                |> Option.defaultWith (fun () ->
                    fail (pin.Name + " installed version is unavailable."))

            let reviewedComponent =
                ModConductor.DeploymentPlanning.ComponentManifests.review
                    workspace
                    gameRoot
                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                    { ModId = installed.ModId.Value
                      Version = version
                      Priority = 0
                      Files = layout.ComponentFiles }
                |> Result.defaultWith (fun _ ->
                    fail (pin.Name + " no longer matches its reviewed archive layout."))

            let stored: StoredEnbComponent =
                { Kind =
                    match pin.Kind with
                    | ModConductor.Enb.EnbComponentKind.Runtime -> "runtime"
                    | ModConductor.Enb.EnbComponentKind.Preset -> "preset"
                    | ModConductor.Enb.EnbComponentKind.Companion ->
                        "companion:"
                        + (pin.NexusModId |> Option.map string |> Option.defaultValue pin.Name)
                  ModId = installed.ModId.Value
                  VersionId = installed.VersionId.Value
                  Version = pin.Version
                  Sha256 = hash
                  NexusModId = pin.NexusModId
                  NexusFileId = fileId
                  Source = pin.Source.AbsoluteUri
                  Terms = pin.Terms.AbsoluteUri
                  CheckedAt = DateTimeOffset.UtcNow }

            return reviewedComponent, stored
        }
