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
            let fail detail = raise (IO.IOException detail)

            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, requestedArtifact.Id)

            let artifact =
                currentArtifact
                |> Result.defaultWith (fun _ -> fail "The verified FNIS archive is unavailable.")

            if
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
            then
                fail "The verified FNIS archive is not ready."

            let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                { WorkspaceId = workspace
                  Id = artifact.Id
                  Revision = artifact.Revision }

            let! draft = installations.Prepare(reference, token)

            let plan =
                ModConductor.Fnis.FnisArchiveLayout.review draft
                |> Result.defaultWith (ModConductor.Fnis.FnisProblem.message >> fail)

            let reviewed =
                installations.SelectReviewed(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    "FNIS Behavior SE",
                    string release.ComponentVersion,
                    plan.Files
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
                    |> Option.defaultValue
                        "FNIS installation did not complete. No component was published."
                )

            let! version =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null installed.VersionId.Value 0 20001
                    |> Option.map (fun value -> { value with NextOffset = None }))

            let version =
                version
                |> Option.defaultWith (fun () -> fail "The installed FNIS version is unavailable.")

            return artifact, installed.ModId.Value, installed.VersionId.Value, version, plan
        }
