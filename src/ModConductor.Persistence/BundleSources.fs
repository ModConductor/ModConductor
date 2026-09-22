namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInspection
open ModConductor.BundleInstallation

module internal BundleFiles =
    let name (id: Guid) =
        "bundle-" + id.ToString("N") + ".archive"

// This receipt owns temporary archive copies, never installed mod payloads.
type internal BundleSources(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let operations = ArtifactAccess(database, access)
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait

    let fail error = raise (ArtifactException error)

    let claim workspace id action =
        db (fun () ->
            use transaction = connection.BeginTransaction(deferred = false)
            let work = BundleRows.work connection transaction workspace id

            if work.Busy <> 0 then
                fail ArtifactError.Busy

            Sqlite.execute
                connection
                transaction
                "UPDATE bundle_work SET busy=busy+1,owner=$owner WHERE id=$id AND (busy=0 OR owner=$owner)"
                [ "$id", box (string id); "$owner", box database.OwnerId ]

            if Sqlite.number connection transaction "SELECT changes()" [] <> 1L then
                fail ArtifactError.Busy

            transaction.Commit())

        try
            action ()
        finally
            db (fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE bundle_work SET busy=busy-1 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box database.OwnerId ])

    let result outcome =
        match outcome with
        | Ok value -> value
        | Error ArtifactError.Cancelled -> raise (OperationCanceledException())
        | Error ArtifactError.Busy ->
            BundleRows.refuse "The bundle is busy. Wait for its current operation."
        | Error _ ->
            BundleRows.refuse
                "The temporary archive cannot be read or written. Check the workspace folder and available space."


    member _.Exclusive(workspace, bundle, action) =
        operations.Run(fun () ->
            claim workspace bundle (fun () ->
                use directory = operations.Library workspace in action directory))

    member _.ClearIncomplete(workspace, bundle, source) =
        operations.Run(fun () ->
            claim workspace bundle (fun () ->
                let source = db (fun () -> BundleRows.source connection null bundle source)

                if source.Digest.IsNone then
                    use directory = operations.Library workspace
                    ArtifactFiles.remove directory (BundleFiles.name source.Id) source.Identity

                    db (fun () ->
                        Sqlite.execute
                            connection
                            null
                            "UPDATE bundle_sources SET identity=NULL,length=NULL,problem=NULL WHERE id=$id"
                            [ "$id", box (string source.Id) ]

                        BundleRows.touch connection null bundle)))

    member this.Materialize
        (workspace, bundle, sourceId, inspection: Inspection, token: CancellationToken)
        =
        task {
            let source, work =
                db (fun () ->
                    BundleRows.source connection null bundle sourceId,
                    BundleRows.work connection null workspace bundle)

            match source.Digest with
            | Some digest ->
                return
                    { BundleId = bundle
                      SourceId = sourceId
                      Sha256 = digest }
            | None ->
                if source.Identity.IsSome then
                    BundleRows.refuse "Delete the incomplete archive copy before trying again."

                let! parent =
                    match source.Parent with
                    | None -> Task.FromResult None
                    | Some parent ->
                        task {
                            let! input =
                                this.Materialize(workspace, bundle, parent, inspection, token)

                            return Some input
                        }

                let! outcome =
                    operations.Run(fun () ->
                        claim workspace bundle (fun () ->
                            let artifact = operations.Read(workspace, work.ArtifactId).Artifact

                            if parent.IsNone && artifact.Sha256 <> Some work.Digest then
                                BundleRows.refuse
                                    "The bundle archive changed. Close this checklist and review the fresh archive."

                            let reference: ArtifactRef =
                                { WorkspaceId = workspace
                                  Id = artifact.Id
                                  Revision = artifact.Revision }

                            use directory = operations.Library workspace

                            try
                                let readParent consume =
                                    match parent with
                                    | None ->
                                        inspection.WithContents(reference, token, consume)
                                        |> wait
                                        |> result
                                    | Some input ->
                                        let stored =
                                            db (fun () ->
                                                BundleRows.source
                                                    connection
                                                    null
                                                    bundle
                                                    input.SourceId)

                                        let file, _ =
                                            directory.Read(
                                                BundleFiles.name stored.Id,
                                                stored.Identity
                                            )

                                        use file = file

                                        ArtifactFiles.verify
                                            token
                                            stored.Length
                                            stored.Digest
                                            file

                                        file.Position <- 0L

                                        inspection.WithOwnedStream(
                                            input.Sha256,
                                            file,
                                            token,
                                            consume
                                        )

                                let copied =
                                    readParent (fun contents ->
                                        let entry =
                                            contents.Manifest.Entries
                                            |> List.tryFind (fun e ->
                                                e.Index = source.Index
                                                && e.Path = source.Path
                                                && e.Size = source.ExpectedLength
                                                && not e.Directory)

                                        if entry.IsNone then
                                            BundleRows.refuse
                                                "The archive in this bundle changed. Review the fresh archive."

                                        db (fun () ->
                                            BundleRows.sources connection null bundle
                                            |> BundleRows.budget)

                                        let output, identity =
                                            directory.Create(BundleFiles.name source.Id)

                                        use output = output

                                        db (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "UPDATE bundle_sources SET identity=$identity WHERE id=$id"
                                                [ "$id", box (string source.Id)
                                                  "$identity",
                                                  box (LibraryEncoding.identity identity) ])

                                        use hash =
                                            IncrementalHash.CreateHash(HashAlgorithmName.SHA256)

                                        let buffer = Array.zeroCreate<byte> 65536
                                        let mutable digest = None

                                        try
                                            contents.ReadEntry(
                                                source.Index,
                                                fun input ->
                                                    let mutable more = true

                                                    while more do
                                                        token.ThrowIfCancellationRequested()

                                                        let count =
                                                            input.Read(buffer, 0, buffer.Length)

                                                        if count = 0 then
                                                            more <- false
                                                        else
                                                            output.Write(buffer, 0, count)
                                                            hash.AppendData(buffer, 0, count)
                                            )

                                            output.Flush(true)

                                            if output.Length <> source.ExpectedLength then
                                                raise (
                                                    InvalidDataException
                                                        "Incomplete nested archive"
                                                )

                                            digest <-
                                                Some(
                                                    hash.GetHashAndReset()
                                                    |> Convert.ToHexStringLower
                                                )
                                        finally
                                            db (fun () ->
                                                Sqlite.execute
                                                    connection
                                                    null
                                                    "UPDATE bundle_sources SET length=$length,digest=$digest WHERE id=$id"
                                                    [ "$id", box (string source.Id)
                                                      "$length", box output.Length
                                                      "$digest",
                                                      digest
                                                      |> Option.map box
                                                      |> Option.defaultValue (box DBNull.Value) ])

                                        digest.Value)

                                db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "UPDATE bundle_sources SET problem=NULL WHERE id=$id"
                                        [ "$id", box (string source.Id) ]

                                    BundleRows.touch connection null bundle)

                                { BundleId = bundle
                                  SourceId = sourceId
                                  Sha256 = copied }
                            with error ->
                                let message =
                                    ArchiveFailure.message error
                                    |> Option.defaultValue error.Message

                                db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "UPDATE bundle_sources SET problem=$problem WHERE id=$id"
                                        [ "$id", box (string source.Id)
                                          "$problem", box message ]

                                    BundleRows.touch connection null bundle)

                                reraise ()))

                return result outcome
        }

    interface INestedArchiveSource with
        member _.ReadVerified(workspace, input, token, consume) =
            task {
                let! outcome =
                    operations.Run(fun () ->
                        claim workspace input.BundleId (fun () ->
                            let source =
                                db (fun () ->
                                    BundleRows.source
                                        connection
                                        null
                                        input.BundleId
                                        input.SourceId)

                            if source.Digest <> Some input.Sha256 then
                                fail ArtifactError.Stale

                            use directory = operations.Library workspace

                            let file, _ =
                                directory.Read(BundleFiles.name source.Id, source.Identity)

                            use file = file
                            ArtifactFiles.verify token source.Length source.Digest file
                            file.Position <- 0L

                            try
                                Choice1Of2(consume (file :> Stream))
                            with error ->
                                Choice2Of2 error))

                return
                    match outcome with
                    | Ok(Choice1Of2 value) -> Ok value
                    | Ok(Choice2Of2 error) ->
                        System.Runtime.ExceptionServices.ExceptionDispatchInfo
                            .Capture(error)
                            .Throw()

                        Unchecked.defaultof<_>
                    | Error error -> Error error
            }
