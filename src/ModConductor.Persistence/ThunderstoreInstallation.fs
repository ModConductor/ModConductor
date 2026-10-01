namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.Thunderstore

module internal ThunderstoreInstallation =
    let private layout (store: InstallationStore) (package: PackageDetails) (draft: InstallationDraft) =
        let manual =
            if draft.Installer = InstallationMode.Manual then Ok draft
            else store.UseInstaller(draft.Artifact.WorkspaceId, draft.Id, draft.Revision, InstallationMode.Manual)
        manual
        |> Result.bind (fun draft -> store.Change(draft.Artifact.WorkspaceId, draft.Id, draft.Revision, LayoutChange.Root []))
        |> Result.bind (fun draft -> store.Change(draft.Artifact.WorkspaceId, draft.Id, draft.Revision,
                                                  LayoutChange.Metadata(PackageReference.label package.Reference.Package, package.Reference.Version)))

    let start (store: InstallationStore) (package: PackageDetails) (artifact: Artifact) token = task {
        let reference = {WorkspaceId = artifact.WorkspaceId; Id = artifact.Id; Revision = artifact.Revision}
        let! prepared = store.PreparePackage(reference, token)
        match prepared with
        | Error error -> return Error(Problem.Acquisition error)
        | Ok draft ->
            try
                token.ThrowIfCancellationRequested()
                return layout store package draft
                       |> Result.bind (fun draft -> store.Start(draft.Artifact.WorkspaceId, draft.Id, draft.Revision, Guid.NewGuid()))
                       |> Result.mapError Problem.Acquisition
            finally store.CloseDraft(draft.Artifact.WorkspaceId, draft.Id)
    }

    let rec wait (store: InstallationStore) (status: Installation) (observe: Installation -> Task) (token: CancellationToken) = task {
        do! observe status
        match status.State with
        | InstallationState.Complete -> return Ok status.ModId.Value
        | InstallationState.Stopped | InstallationState.Discarded ->
            return Error(Problem.Acquisition(defaultArg status.Problem "The package installation stopped."))
        | InstallationState.Running ->
            do! store.WaitForChange(status.WorkspaceId, status.Id, status, token)
            let! current = store.Read(status.WorkspaceId, status.Id)
            match current with
            | Error error -> return Error(Problem.Acquisition error)
            | Ok current -> return! wait store current observe token
    }
