namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.HttpDownloads
open ModConductor.Thunderstore

// Owns only the currently active transfer/installation for one acquisition.
type internal ThunderstoreAcquisitionWork
    (
        downloads: DownloadSession,
        artifacts: IArtifactLibrary,
        installations: InstallationStore,
        inventory: ThunderstoreInventory,
        workspace: Guid,
        observe: ThunderstoreProgress -> Task,
        token: CancellationToken
    ) =
    let mutable download: Artifact option = None
    let mutable installation: Installation option = None
    let mutable completed, count = 0, 0
    let installed = ResizeArray<InstalledThunderstorePackage>()

    let progress reference stage bytes total modId =
        observe
            { Reference = reference
              Stage = stage
              Bytes = bytes
              Total = total
              Completed = completed
              Packages = count
              ModId = modId }

    let install package archive =
        task {
            let! started = ThunderstoreInstallation.start installations package archive token

            match started with
            | Error error -> return Error error
            | Ok status ->
                installation <- Some status

                let observed (status: Installation) =
                    progress package.Reference "install" status.Bytes (Some status.TotalBytes) None

                let! result = ThunderstoreInstallation.wait installations status observed token

                if Result.isOk result then
                    installation <- None

                return result
        }

    let transfer (package: PackageDetails) =
        task {
            let! started = ThunderstoreTransfers.start downloads workspace package

            match started with
            | Error error -> return Error error
            | Ok artifact ->
                download <- Some artifact

                let observed (artifact: Artifact) =
                    let info = artifact.Download.Value
                    progress package.Reference "download" info.Bytes info.Total None

                let! ready = ThunderstoreTransfers.wait downloads artifacts artifact observed token

                match ready with
                | Error error -> return Error error
                | Ok archive ->
                    download <- None
                    return! install package archive
        }

    let acquire (package: PackageDetails) =
        task {
            let! existing = inventory.Read(workspace, package.Reference.Package)

            match existing |> List.tryFind (fun item -> item.Reference = package.Reference) with
            | Some item -> return Ok item.ModId
            | None -> return! transfer package
        }

    let stop () =
        task {
            match download with
            | Some value ->
                let! _ = downloads.Control(workspace, value.Id, DownloadAction.Pause)
                ()
            | None -> ()

            match installation with
            | Some value ->
                let! _ = installations.Cancel(workspace, value.Id)
                ()
            | None -> ()
        }

    let addAll packages =
        task {
            count <- List.length packages
            let mutable problem = None

            for package in packages do
                if problem.IsNone then
                    token.ThrowIfCancellationRequested()
                    let! result = acquire package

                    match result with
                    | Error error -> problem <- Some error
                    | Ok modId ->
                        completed <- completed + 1

                        installed.Add
                            { Reference = package.Reference
                              ModId = modId }

                        do!
                            progress
                                package.Reference
                                "added"
                                package.Bytes
                                (Some package.Bytes)
                                (Some modId)

            match problem with
            | Some error ->
                do! stop ()
                return Error error
            | None -> return Ok(Seq.toList installed)
        }

    member _.Run(reader, reference) =
        task {
            try
                do! progress reference "resolve" 0L None None
                let! resolved = Dependencies.resolve reader reference token

                match resolved with
                | Error error -> return Error error
                | Ok packages -> return! addAll packages
            with :? OperationCanceledException ->
                do! stop ()
                return Error Problem.Cancelled
        }
