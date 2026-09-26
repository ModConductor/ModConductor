namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal SkseComponentInstaller
    (
        database: StateDatabase,
        artifacts: ArtifactStore,
        installations: InstallationStore,
        skseLoaders: SkseLoaderStore
    ) =
    member internal _.Install
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Skse.SkseRelease,
            requestedArtifact: ModConductor.ArtifactLibrary.Artifact,
            token: Threading.CancellationToken
        ) =
        task {
            let fail detail = raise (IO.IOException detail)

            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, requestedArtifact.Id)

            let artifact =
                currentArtifact
                |> Result.defaultWith (fun _ -> fail "The verified SKSE archive is unavailable.")

            if
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
            then
                fail "The verified SKSE archive is not ready."

            let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                { WorkspaceId = workspace
                  Id = artifact.Id
                  Revision = artifact.Revision }

            let! reusable =
                skseLoaders.ReusableVersion(
                    workspace,
                    profile,
                    artifact.Id,
                    artifact.Sha256.Value,
                    release
                )

            let! modId, versionId, importedPlan =
                task {
                    match reusable with
                    | Some(modId, versionId) -> return modId, versionId, None
                    | None ->
                        let! draft = installations.Prepare(reference, token)

                        let plan =
                            ModConductor.Skse.SkseArchiveLayout.review release draft.Manifest
                            |> Result.defaultWith (ModConductor.Skse.SkseProblem.message >> fail)

                        let draft =
                            if
                                draft.Installer = ModConductor.ArchiveInstallation.InstallationMode.Manual
                            then
                                draft
                            else
                                installations.UseInstaller(
                                    workspace,
                                    draft.Id,
                                    draft.Revision,
                                    ModConductor.ArchiveInstallation.InstallationMode.Manual
                                )

                        let reviewed =
                            installations.SelectReviewed(
                                workspace,
                                draft.Id,
                                draft.Revision,
                                "Skyrim Script Extender",
                                string release.ComponentVersion,
                                plan.Files
                            )

                        let installationId = Guid.NewGuid()

                        let started =
                            installations.Start(
                                workspace,
                                reviewed.Id,
                                reviewed.Revision,
                                installationId
                            )

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
                            fail (
                                installed.Problem
                                |> Option.defaultValue
                                    "SKSE installation did not complete. No component was published."
                            )

                        return installed.ModId.Value, installed.VersionId.Value, Some plan
                }

            let! version =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null versionId 0 20001
                    |> Option.map (fun value -> { value with NextOffset = None }))

            let version =
                version
                |> Option.defaultWith (fun () -> fail "The installed SKSE version is unavailable.")

            let componentFiles, loader =
                match importedPlan with
                | Some plan -> plan.ComponentFiles, plan.Loader
                | None ->
                    version.Entries
                    |> List.map _.Path
                    |> ModConductor.Skse.SkseArchiveLayout.imported

            return artifact, modId, versionId, version, componentFiles, loader
        }
