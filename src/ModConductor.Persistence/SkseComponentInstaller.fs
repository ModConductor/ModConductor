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
            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, requestedArtifact.Id)

            match currentArtifact with
            | Error _ -> return Error "The verified SKSE archive is unavailable."
            | Ok artifact when
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
                ->
                return Error "The verified SKSE archive is not ready."
            | Ok artifact ->
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

                let! imported =
                    task {
                        match reusable with
                        | Some(modId, versionId) -> return Ok(modId, versionId, None)
                        | None ->
                            let! prepared = installations.Prepare(reference, token)

                            match prepared with
                            | Error why -> return Error why
                            | Ok draft ->
                                match
                                    ModConductor.Skse.SkseArchiveLayout.review
                                        release
                                        draft.Manifest
                                with
                                | Error problem ->
                                    return Error(ModConductor.Skse.SkseProblem.message problem)
                                | Ok plan ->
                                    let selected =
                                        if
                                            draft.Installer = ModConductor.ArchiveInstallation.InstallationMode.Manual
                                        then
                                            Ok draft
                                        else
                                            installations.UseInstaller(
                                                workspace,
                                                draft.Id,
                                                draft.Revision,
                                                ModConductor.ArchiveInstallation.InstallationMode.Manual
                                            )

                                    match selected with
                                    | Error message -> return Error message
                                    | Ok draft ->
                                        let installationId = Guid.NewGuid()

                                        let started =
                                            installations.SelectReviewed(
                                                workspace,
                                                draft.Id,
                                                draft.Revision,
                                                "Skyrim Script Extender",
                                                string release.ComponentVersion,
                                                plan.Files
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
                                            let! observed =
                                                installations.UntilStopped(
                                                    workspace,
                                                    installationId,
                                                    started,
                                                    token
                                                )

                                            match observed with
                                            | Error why -> return Error why
                                            | Ok installed ->
                                                do!
                                                    installations.WaitForWorker(
                                                        installationId,
                                                        token
                                                    )

                                                if
                                                    installed.State
                                                    <> ModConductor.ArchiveInstallation.InstallationState.Complete
                                                    || installed.ModId.IsNone
                                                    || installed.VersionId.IsNone
                                                then
                                                    return
                                                        Error(
                                                            installed.Problem
                                                            |> Option.defaultValue
                                                                "SKSE installation did not complete. No component was published."
                                                        )
                                                else
                                                    return
                                                        Ok(
                                                            installed.ModId.Value,
                                                            installed.VersionId.Value,
                                                            Some plan
                                                        )
                    }

                match imported with
                | Error detail -> return Error detail
                | Ok(modId, versionId, importedPlan) ->
                    let! version =
                        database.Enqueue(fun () ->
                            LibraryRows.version database.Connection null versionId 0 20001
                            |> Option.map (fun value -> { value with NextOffset = None }))

                    match version with
                    | None -> return Error "The installed SKSE version is unavailable."
                    | Some version ->
                        let componentFiles, loader =
                            match importedPlan with
                            | Some plan -> plan.ComponentFiles, plan.Loader
                            | None ->
                                version.Entries
                                |> List.map _.Path
                                |> ModConductor.Skse.SkseArchiveLayout.imported

                        return Ok(artifact, modId, versionId, version, componentFiles, loader)
        }
