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

type internal BundleClaimFailure =
    | Missing of string
    | Busy

type internal BundleSourceFailure =
    | Refused of string
    | AccessFailed of ArtifactError

// This receipt owns temporary archive copies, never installed mod payloads.
type internal BundleSources(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let operations = ArtifactAccess(database, access)
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait

    let claim workspace id mapError action =
        let acquired =
            db (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                BundleRows.work connection transaction workspace id
                |> Result.mapError Missing
                |> Result.bind (fun work ->
                    if work.Busy <> 0 then
                        Error Busy
                    else
                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE bundle_work SET busy=busy+1,owner=$owner WHERE id=$id AND (busy=0 OR owner=$owner)"
                            [ "$id", box (string id); "$owner", box database.OwnerId ]

                        if Sqlite.number connection transaction "SELECT changes()" [] <> 1L then
                            Error Busy
                        else
                            transaction.Commit()
                            Ok()))

        match acquired with
        | Error error -> Error(mapError error)
        | Ok() ->
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
        | Ok value -> Ok value
        | Error ArtifactError.Cancelled -> raise (OperationCanceledException())
        | Error ArtifactError.Busy -> Error "The bundle is busy. Wait for its current operation."
        | Error _ ->
            Error
                "The temporary archive cannot be read or written. Check the workspace folder and available space."

    let refusal =
        function
        | Missing message -> message
        | Busy -> "The bundle is busy. Wait for its current operation."

    let sourceFailure =
        function
        | Missing message -> Refused message
        | Busy -> AccessFailed ArtifactError.Busy

    member _.Exclusive(workspace, bundle, action) =
        task {
            let! outcome =
                operations.Run(fun () ->
                    Ok(
                        claim workspace bundle sourceFailure (fun () ->
                            operations.Library workspace
                            |> Result.mapError AccessFailed
                            |> Result.bind (fun directory ->
                                use directory = directory
                                action directory |> Result.mapError Refused))
                    ))

            return
                match outcome with
                | Ok value -> value
                | Error error -> Error(AccessFailed error)
        }

    member _.ClearIncomplete(workspace, bundle, source) =
        task {
            let! outcome =
                operations.Run(fun () ->
                    Ok(
                        claim workspace bundle sourceFailure (fun () ->
                            db (fun () -> BundleRows.source connection null bundle source)
                            |> Result.mapError Refused
                            |> Result.bind (fun source ->
                                if source.Digest.IsSome then
                                    Ok()
                                else
                                    operations.Library workspace
                                    |> Result.mapError AccessFailed
                                    |> Result.map (fun directory ->
                                        use directory = directory

                                        ArtifactFiles.remove
                                            directory
                                            (BundleFiles.name source.Id)
                                            source.Identity

                                        db (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "UPDATE bundle_sources SET identity=NULL,length=NULL,problem=NULL WHERE id=$id"
                                                [ "$id", box (string source.Id) ]

                                            BundleRows.touch connection null bundle))))
                    ))

            return
                match outcome with
                | Ok value -> value
                | Error error -> Error(AccessFailed error)
        }

    member this.Materialize
        (workspace, bundle, sourceId, inspection: Inspection, token: CancellationToken)
        =
        task {
            let current =
                db (fun () ->
                    BundleRows.source connection null bundle sourceId
                    |> Result.bind (fun source ->
                        BundleRows.work connection null workspace bundle
                        |> Result.map (fun work -> source, work)))

            match current with
            | Error error -> return Error error
            | Ok(source, work) ->
                match source.Digest, source.Identity with
                | Some digest, _ ->
                    return
                        Ok
                            { BundleId = bundle
                              SourceId = sourceId
                              Sha256 = digest }
                | None, Some _ ->
                    return Error "Delete the incomplete archive copy before trying again."
                | None, None ->
                    let! parent =
                        match source.Parent with
                        | None -> Task.FromResult(Ok None)
                        | Some parent ->
                            task {
                                let! input =
                                    this.Materialize(workspace, bundle, parent, inspection, token)

                                return input |> Result.map Some
                            }

                    match parent with
                    | Error error -> return Error error
                    | Ok parent ->
                        let! outcome =
                            operations.Run(fun () ->
                                Ok(
                                    claim workspace bundle refusal (fun () ->
                                        operations.Read(workspace, work.ArtifactId)
                                        |> result
                                        |> Result.bind (fun stored ->
                                            let artifact = stored.Artifact

                                            if
                                                parent.IsNone
                                                && artifact.Sha256 <> Some work.Digest
                                            then
                                                Error
                                                    "The bundle archive changed. Close this checklist and review the fresh archive."
                                            else
                                                let reference: ArtifactRef =
                                                    { WorkspaceId = workspace
                                                      Id = artifact.Id
                                                      Revision = artifact.Revision }

                                                operations.Library workspace
                                                |> result
                                                |> Result.bind (fun directory ->
                                                    use directory = directory

                                                    let recordProblem message =
                                                        db (fun () ->
                                                            Sqlite.execute
                                                                connection
                                                                null
                                                                "UPDATE bundle_sources SET problem=$problem WHERE id=$id"
                                                                [ "$id", box (string source.Id)
                                                                  "$problem", box message ]

                                                            BundleRows.touch
                                                                connection
                                                                null
                                                                bundle)

                                                    try
                                                        let readParent consume =
                                                            match parent with
                                                            | None ->
                                                                inspection.WithContents(
                                                                    reference,
                                                                    token,
                                                                    consume
                                                                )
                                                                |> wait
                                                                |> result
                                                                |> Result.bind id
                                                            | Some input ->
                                                                db (fun () ->
                                                                    BundleRows.source
                                                                        connection
                                                                        null
                                                                        bundle
                                                                        input.SourceId)
                                                                |> Result.bind (fun stored ->
                                                                    let file, _ =
                                                                        directory.Read(
                                                                            BundleFiles.name
                                                                                stored.Id,
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
                                                                    ))

                                                        let copied =
                                                            readParent (fun contents ->
                                                                let entry =
                                                                    contents.Manifest.Entries
                                                                    |> List.tryFind (fun e ->
                                                                        e.Index = source.Index
                                                                        && e.Path = source.Path
                                                                        && e.Size = source.ExpectedLength
                                                                        && not e.Directory)

                                                                match entry with
                                                                | None ->
                                                                    Error
                                                                        "The archive in this bundle changed. Review the fresh archive."
                                                                | Some _ ->
                                                                    db (fun () ->
                                                                        BundleRows.sources
                                                                            connection
                                                                            null
                                                                            bundle
                                                                        |> BundleRows.budget)

                                                                    let output, identity =
                                                                        directory.Create(
                                                                            BundleFiles.name
                                                                                source.Id
                                                                        )

                                                                    use output = output

                                                                    db (fun () ->
                                                                        Sqlite.execute
                                                                            connection
                                                                            null
                                                                            "UPDATE bundle_sources SET identity=$identity WHERE id=$id"
                                                                            [ "$id",
                                                                              box (
                                                                                  string
                                                                                      source.Id
                                                                              )
                                                                              "$identity",
                                                                              box (
                                                                                  LibraryEncoding.identity
                                                                                      identity
                                                                              ) ])

                                                                    use hash =
                                                                        IncrementalHash
                                                                            .CreateHash(
                                                                                HashAlgorithmName.SHA256
                                                                            )

                                                                    let buffer =
                                                                        Array.zeroCreate<byte>
                                                                            65536

                                                                    let mutable digest = None

                                                                    try
                                                                        contents.ReadEntry(
                                                                            source.Index,
                                                                            fun input ->
                                                                                let mutable more =
                                                                                    true

                                                                                while more do
                                                                                    token
                                                                                        .ThrowIfCancellationRequested()

                                                                                    let count =
                                                                                        input
                                                                                            .Read(
                                                                                                buffer,
                                                                                                0,
                                                                                                buffer.Length
                                                                                            )

                                                                                    if
                                                                                        count = 0
                                                                                    then
                                                                                        more <-
                                                                                            false
                                                                                    else
                                                                                        output
                                                                                            .Write(
                                                                                                buffer,
                                                                                                0,
                                                                                                count
                                                                                            )

                                                                                        hash
                                                                                            .AppendData(
                                                                                                buffer,
                                                                                                0,
                                                                                                count
                                                                                            )
                                                                        )

                                                                        output.Flush(true)

                                                                        if
                                                                            output.Length
                                                                            <> source.ExpectedLength
                                                                        then
                                                                            raise (
                                                                                InvalidDataException
                                                                                    "Incomplete nested archive"
                                                                            )

                                                                        digest <-
                                                                            Some(
                                                                                hash
                                                                                    .GetHashAndReset()
                                                                                |> Convert.ToHexStringLower
                                                                            )
                                                                    finally
                                                                        db (fun () ->
                                                                            Sqlite.execute
                                                                                connection
                                                                                null
                                                                                "UPDATE bundle_sources SET length=$length,digest=$digest WHERE id=$id"
                                                                                [ "$id",
                                                                                  box (
                                                                                      string
                                                                                          source.Id
                                                                                  )
                                                                                  "$length",
                                                                                  box
                                                                                      output.Length
                                                                                  "$digest",
                                                                                  digest
                                                                                  |> Option.map
                                                                                      box
                                                                                  |> Option
                                                                                      .defaultValue (
                                                                                          box
                                                                                              DBNull.Value
                                                                                      ) ])

                                                                    Ok digest.Value)

                                                        match copied with
                                                        | Error error ->
                                                            recordProblem error
                                                            Error error
                                                        | Ok digest ->
                                                            db (fun () ->
                                                                Sqlite.execute
                                                                    connection
                                                                    null
                                                                    "UPDATE bundle_sources SET problem=NULL WHERE id=$id"
                                                                    [ "$id",
                                                                      box (string source.Id) ]

                                                                BundleRows.touch
                                                                    connection
                                                                    null
                                                                    bundle)

                                                            Ok
                                                                { BundleId = bundle
                                                                  SourceId = sourceId
                                                                  Sha256 = digest }
                                                    with error ->
                                                        let message =
                                                            ArchiveFailure.message error
                                                            |> Option.defaultValue error.Message

                                                        recordProblem message
                                                        reraise ())))
                                ))

                        return result outcome |> Result.bind id
        }

    interface INestedArchiveSource with
        member _.ReadVerified(workspace, input, token, consume) =
            task {
                let! outcome =
                    operations.Run(fun () ->
                        let claimed =
                            claim
                                workspace
                                input.BundleId
                                (function
                                | Missing _ -> ArtifactError.Stale
                                | Busy -> ArtifactError.Busy)
                                (fun () ->
                                    Ok(
                                        db (fun () ->
                                            BundleRows.source
                                                connection
                                                null
                                                input.BundleId
                                                input.SourceId)
                                        |> Result.mapError (fun _ -> ArtifactError.Stale)
                                        |> Result.bind (fun source ->
                                            if source.Digest <> Some input.Sha256 then
                                                Error ArtifactError.Stale
                                            else
                                                operations.Library workspace
                                                |> Result.map (fun directory ->
                                                    use directory = directory

                                                    let file, _ =
                                                        directory.Read(
                                                            BundleFiles.name source.Id,
                                                            source.Identity
                                                        )

                                                    use file = file

                                                    ArtifactFiles.verify
                                                        token
                                                        source.Length
                                                        source.Digest
                                                        file

                                                    file.Position <- 0L

                                                    try
                                                        Choice1Of2(consume (file :> Stream))
                                                    with error ->
                                                        Choice2Of2 error))
                                    ))

                        claimed |> Result.bind id)

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
