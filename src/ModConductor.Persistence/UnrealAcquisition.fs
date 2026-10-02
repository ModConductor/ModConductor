namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Unreal
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.ModLibrary

type UnrealAcquisition
    internal
    (
        database: StateDatabase,
        loaders: UnrealStore,
        downloads: DownloadSession,
        artifacts: ArtifactStore,
        installations: InstallationStore,
        library: ModLibraryStore
    ) =
    let gate = obj ()
    let active = System.Collections.Generic.HashSet<Guid>()

    member _.Acquire
        (
            workspace,
            profile,
            contextRevision,
            archivePath: string,
            observe: UnrealProgress -> Task,
            token: CancellationToken
        ) =
        task {
            let admitted = lock gate (fun () -> active.Add workspace)

            if not admitted then
                return Error "Wait for the current loader acquisition."
            else
                let mutable downloading: Guid option = None
                let mutable installing: Guid option = None

                let stop () =
                    task {
                        match downloading with
                        | Some id ->
                            let! _ = downloads.Control(workspace, id, DownloadAction.Pause)
                            ()
                        | None -> ()

                        match installing with
                        | Some id ->
                            let! _ = installations.Cancel(workspace, id)
                            ()
                        | None -> ()
                    }

                let artifactLibrary = artifacts :> IArtifactLibrary

                let run () =
                    task {
                        let! selected = loaders.Read(workspace, profile)

                        match selected with
                        | Error detail -> return Error detail
                        | Ok selected when selected.ContextRevision <> contextRevision ->
                            return
                                Error
                                    "The game installation changed. Read the loader selection again."
                        | Ok selected ->
                            let! archive =
                                task {
                                    if archivePath <> "" then
                                        let! result =
                                            artifactLibrary.Add(
                                                { Id = Guid.NewGuid()
                                                  WorkspaceId = workspace
                                                  Path = archivePath
                                                  Storage = ArtifactStorage.Reference },
                                                token
                                            )

                                        return
                                            result
                                            |> Result.mapError (fun _ ->
                                                "The selected loader archive is unavailable.")
                                    else
                                        match selected.Declaration.Download with
                                        | None ->
                                            return
                                                Error(
                                                    "Choose the "
                                                    + selected.Declaration.Name
                                                    + " archive."
                                                )
                                        | Some url ->
                                            let! result =
                                                downloads.Start
                                                    { Id = Guid.NewGuid()
                                                      WorkspaceId = workspace
                                                      Name =
                                                        selected.Declaration.Name
                                                        + "-"
                                                        + selected.Declaration.Version
                                                        + ".zip"
                                                      Sources = [ DownloadSource.Url url ]
                                                      ExpectedLength = None
                                                      ExpectedSha256 = None }

                                            match result with
                                            | Error _ ->
                                                return Error "The loader download could not start."
                                            | Ok artifact ->
                                                downloading <- Some artifact.Id

                                                let! result =
                                                    UnrealArchiveInstallation.waitDownload
                                                        downloads
                                                        artifactLibrary
                                                        observe
                                                        token
                                                        artifact

                                                if Result.isOk result then
                                                    downloading <- None

                                                return result
                                }

                            match archive with
                            | Error detail -> return Error detail
                            | Ok archive ->
                                let! started =
                                    UnrealArchiveInstallation.start
                                        installations
                                        selected.Declaration
                                        archive
                                        token

                                match started with
                                | Error detail -> return Error detail
                                | Ok status ->
                                    installing <- Some status.Id

                                    let! added =
                                        UnrealArchiveInstallation.waitInstall
                                            installations
                                            observe
                                            token
                                            status

                                    match added with
                                    | Error detail -> return Error detail
                                    | Ok modId ->
                                        installing <- None

                                        let! row =
                                            database.Enqueue(fun () ->
                                                LibraryRows.find database.Connection null modId)

                                        let row = row.Value.Entry

                                        let! tagged =
                                            (library :> IModLibrary)
                                                .Edit(
                                                    modId,
                                                    row.Revision,
                                                    { row.Metadata with
                                                        Source =
                                                            LoaderSource.encode selected.Declaration }
                                                )

                                        match tagged with
                                        | Error _ ->
                                            return
                                                Error
                                                    "The archive is installed, but its loader metadata changed. Check it in Mods."
                                        | Ok _ ->
                                            do!
                                                observe
                                                    { Stage = "added"
                                                      Bytes = status.TotalBytes
                                                      Total = Some status.TotalBytes
                                                      Mod = Some modId }

                                            return!
                                                loaders.Select(
                                                    workspace,
                                                    profile,
                                                    contextRevision,
                                                    modId
                                                )
                    }

                try
                    let! result =
                        task {
                            try
                                return! run ()
                            with :? OperationCanceledException ->
                                return
                                    Error
                                        "The loader acquisition stopped. Completed files remain in the library."
                        }

                    do! stop ()
                    return result
                finally
                    lock gate (fun () -> active.Remove workspace |> ignore)
        }
