namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Thunderstore

type ThunderstoreProgress =
    { Reference: VersionReference
      Stage: string
      Bytes: int64
      Total: int64 option
      Completed: int
      Packages: int
      ModId: Guid option }

module internal ThunderstoreTransfers =
    let private problem error = Problem.Acquisition("The package archive is unavailable: " + string error)
    let private resume (downloads: DownloadSession) (artifact: Artifact) =
        match artifact.Download with
        | Some info when info.State = DownloadState.Paused || info.State = DownloadState.Failed ->
            downloads.Control(artifact.WorkspaceId, artifact.Id, if info.RestartRequired then DownloadAction.Restart else DownloadAction.Resume)
        | _ -> Task.FromResult(Ok artifact)

    let start (downloads: DownloadSession) workspace (package: PackageDetails) = task {
        let! started = downloads.Start
                            { Id = Guid.NewGuid(); WorkspaceId = workspace
                              Name = VersionReference.label package.Reference + ".zip"
                              Sources = [DownloadSource.Thunderstore {Reference = package.Reference; Url = package.Download.AbsoluteUri}]
                              ExpectedLength = Some package.Bytes; ExpectedSha256 = None }
        match started with
        | Error error -> return Error(problem error)
        | Ok artifact ->
            let! resumed = resume downloads artifact
            return resumed |> Result.mapError problem
    }

    let rec wait (downloads: DownloadSession) (artifacts: IArtifactLibrary) (artifact: Artifact) (observe: Artifact -> Task) (token: CancellationToken) = task {
        do! observe artifact
        match artifact.Download with
        | Some info when info.State = DownloadState.Complete -> return Ok artifact
        | Some info when info.State = DownloadState.Failed || info.State = DownloadState.Paused ->
            return Error(Problem.Acquisition(defaultArg artifact.Problem "The package download stopped."))
        | Some _ ->
            do! downloads.WaitForChange(artifact.WorkspaceId, [artifact.Id, artifact.Revision], token)
            let! next = artifacts.Read(artifact.WorkspaceId, artifact.Id)
            match next with
            | Ok next -> return! wait downloads artifacts next observe token
            | Error error -> return Error(problem error)
        | None -> return Error(Problem.Acquisition "The package has no download state.")
    }
