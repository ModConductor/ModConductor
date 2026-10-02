namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.HttpDownloads
open ModConductor.GameContexts

type UnrealProgress =
    { Stage: string
      Bytes: int64
      Total: int64 option
      Mod: Guid option }

module internal UnrealArchiveInstallation =
    let rec waitDownload
        (downloads: DownloadSession)
        (artifacts: IArtifactLibrary)
        (observe: UnrealProgress -> Task)
        (token: CancellationToken)
        (artifact: Artifact)
        =
        task {
            let info = artifact.Download.Value

            do!
                (observe: UnrealProgress -> Task)
                    { Stage = "download"
                      Bytes = info.Bytes
                      Total = info.Total
                      Mod = None }

            match info.State with
            | DownloadState.Complete -> return Ok artifact
            | DownloadState.Failed
            | DownloadState.Paused ->
                return Error(defaultArg artifact.Problem "The loader download stopped.")
            | _ ->
                do!
                    downloads.WaitForChange(
                        artifact.WorkspaceId,
                        [ artifact.Id, artifact.Revision ],
                        token
                    )

                let! next = artifacts.Read(artifact.WorkspaceId, artifact.Id)

                match next with
                | Error _ -> return Error "The loader archive is unavailable."
                | Ok artifact -> return! waitDownload downloads artifacts observe token artifact
        }

    let rec waitInstall
        (store: InstallationStore)
        (observe: UnrealProgress -> Task)
        (token: CancellationToken)
        (status: Installation)
        =
        task {
            do!
                (observe: UnrealProgress -> Task)
                    { Stage = "install"
                      Bytes = status.Bytes
                      Total = Some status.TotalBytes
                      Mod = None }

            match status.State with
            | InstallationState.Complete -> return Ok status.ModId.Value
            | InstallationState.Stopped
            | InstallationState.Discarded ->
                return Error(defaultArg status.Problem "The loader installation stopped.")
            | InstallationState.Running ->
                do! store.WaitForChange(status.WorkspaceId, status.Id, status, token)
                let! next = store.Read(status.WorkspaceId, status.Id)

                match next with
                | Error detail -> return Error detail
                | Ok status -> return! waitInstall store observe token status
        }

    let start
        (store: InstallationStore)
        (declaration: UnrealLoaderDeclaration)
        (archive: Artifact)
        token
        =
        task {
            let! prepared =
                store.PreparePackage(
                    { WorkspaceId = archive.WorkspaceId
                      Id = archive.Id
                      Revision = archive.Revision },
                    token
                )

            match prepared with
            | Error detail -> return Error detail
            | Ok draft ->
                try
                    token.ThrowIfCancellationRequested()

                    return
                        store.Change(
                            archive.WorkspaceId,
                            draft.Id,
                            draft.Revision,
                            LayoutChange.Root []
                        )
                        |> Result.bind (fun draft ->
                            store.Change(
                                archive.WorkspaceId,
                                draft.Id,
                                draft.Revision,
                                LayoutChange.Metadata(declaration.Name, declaration.Version)
                            ))
                        |> Result.bind (fun draft ->
                            store.Start(
                                archive.WorkspaceId,
                                draft.Id,
                                draft.Revision,
                                Guid.NewGuid()
                            ))
                finally
                    store.CloseDraft(archive.WorkspaceId, draft.Id)
        }
