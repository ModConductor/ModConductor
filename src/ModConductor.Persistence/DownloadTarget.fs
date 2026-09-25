namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.HttpDownloads
open ModConductor.Platform

type internal DownloadTarget
    (operations: ArtifactAccess, work: DownloadWork, directory: HeldDirectory, output: FileStream, changed: Guid -> unit) =
    let database = operations.Database
    let connection = database.Connection
    let id = work.Request.Id
    let parameter = [ "$id", box (string id) ]

    let execute sql args =
        database.EnqueueInternal(fun () -> Sqlite.execute connection null sql (parameter @ args))
        :> Task

    interface IDownloadTarget with
        member _.Stream = output

        member _.Observe observation =
            task {
                do!
                    execute
                        "UPDATE artifact_downloads SET total=$total,etag=$etag,effective_url=$url WHERE artifact_id=$id"
                        [ "$total", ArtifactRows.nullable observation.Total
                          "$etag", ArtifactRows.nullable observation.EntityTag
                          "$url", box observation.EffectiveUrl ]

                do!
                    execute
                        "UPDATE artifacts SET length=$total,revision=revision+1 WHERE id=$id"
                        [ "$total", ArtifactRows.nullable observation.Total ]
                changed id
            }

        member _.Checkpoint bytes =
            task {
                do!
                    execute
                        "UPDATE artifact_downloads SET bytes=$bytes WHERE artifact_id=$id"
                        [ "$bytes", box bytes ]

                do! execute "UPDATE artifacts SET revision=revision+1 WHERE id=$id" []
                changed id
            }

        member _.Publish(length, digest) =
            task {
                let row = operations.Read(work.Request.WorkspaceId, id)

                do!
                    database.EnqueueInternal(fun () ->
                        use transaction = connection.BeginTransaction(deferred = false)

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE artifacts SET phase=1,length=$length,sha256=$sha,problem=NULL,revision=revision+1 WHERE id=$id"
                            (parameter @ [ "$length", box length; "$sha", box digest ])

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE artifact_downloads SET checksum_matched=$matched WHERE artifact_id=$id"
                            (parameter @ [ "$matched", box work.Request.ExpectedSha256.IsSome ])

                        transaction.Commit())
                changed id

                ArtifactFiles.promote directory id row.StoredIdentity

                do!
                    database.EnqueueInternal(fun () ->
                        use transaction = connection.BeginTransaction(deferred = false)

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE artifacts SET phase=2,busy=0,revision=revision+1,problem=NULL WHERE id=$id"
                            parameter

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE artifact_downloads SET state=5,checksum_matched=$matched,retry_at=NULL,restart_required=0 WHERE artifact_id=$id"
                            (parameter @ [ "$matched", box work.Request.ExpectedSha256.IsSome ])

                        transaction.Commit())
                changed id
            }

        member _.Dispose() =
            output.Dispose()
            (directory :> IDisposable).Dispose()

    static member Open(operations: ArtifactAccess, work: DownloadWork, changed: Guid -> unit) =
        task {
            let root = operations.Root work.Request.WorkspaceId
            let! prepared = operations.LibraryAccess.PrepareLibrary(root, ignore)

            let library =
                prepared
                |> Result.defaultWith (fun _ ->
                    raise (IOException "The library folder cannot be opened."))

            let directory = LibraryFiles.openLibrary root library

            try
                let row = operations.Read(work.Request.WorkspaceId, work.Request.Id)

                if directory.InspectEntry(ArtifactFiles.final work.Request.Id) |> Option.isSome then
                    raise (IOException "The final archive path is occupied.")

                let name = ArtifactFiles.stage work.Request.Id

                let output, identity =
                    match row.StoredIdentity with
                    | Some expected -> directory.Write(name, expected), expected
                    | None -> directory.Create name

                try
                    if output.Length < work.Bytes then
                        raise (IOException "The partial copy is shorter than its saved size.")

                    if output.Length > work.Bytes then
                        output.SetLength work.Bytes
                        output.Flush true

                    output.Position <- work.Bytes

                    operations.Save
                        { row with
                            StoredIdentity = Some identity
                            Artifact =
                                { row.Artifact with
                                    Path =
                                        Path.Combine(
                                            HostPath.value root.Path,
                                            library.Name,
                                            ArtifactFiles.final work.Request.Id
                                        ) } }

                    return
                        new DownloadTarget(operations, work, directory, output, changed) :> IDownloadTarget
                with error ->
                    output.Dispose()
                    return raise error
            with error ->
                (directory :> IDisposable).Dispose()
                return raise error
        }
