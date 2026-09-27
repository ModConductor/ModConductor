namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal FnisComponentInstaller
    (database: StateDatabase, artifacts: ArtifactStore, installations: InstallationStore) =
    member internal _.Install
        (
            workspace: Guid,
            release: ModConductor.Fnis.FnisRelease,
            requestedArtifact: ModConductor.ArtifactLibrary.Artifact,
            token: Threading.CancellationToken
        ) =
        task {
            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, requestedArtifact.Id)

            match currentArtifact with
            | Error _ -> return Error "The verified FNIS archive is unavailable."
            | Ok artifact when
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
                ->
                return Error "The verified FNIS archive is not ready."
            | Ok artifact ->
                let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                    { WorkspaceId = workspace
                      Id = artifact.Id
                      Revision = artifact.Revision }

                let! prepared = installations.Prepare(reference, token)

                match prepared with
                | Error why -> return Error why
                | Ok draft ->
                    match ModConductor.Fnis.FnisArchiveLayout.review draft with
                    | Error problem -> return Error(ModConductor.Fnis.FnisProblem.message problem)
                    | Ok plan ->
                        let installationId = Guid.NewGuid()

                        let started =
                            installations.SelectReviewed(
                                workspace,
                                draft.Id,
                                draft.Revision,
                                "FNIS Behavior SE",
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
                                            |> Option.defaultValue
                                                "FNIS installation did not complete. No component was published."
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
                                            |> Option.map (fun value ->
                                                { value with NextOffset = None }))

                                    match version with
                                    | None ->
                                        return Error "The installed FNIS version is unavailable."
                                    | Some version ->
                                        return
                                            Ok(
                                                artifact,
                                                installed.ModId.Value,
                                                installed.VersionId.Value,
                                                version,
                                                plan
                                            )
        }
