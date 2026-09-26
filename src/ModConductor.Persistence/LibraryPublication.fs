namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary

/// Publication receipts share the existing SQLite queue and engine ownership lease.
type internal LibraryPublication(database: StateDatabase, access: LibraryAccess) as this =
    let connection = database.Connection
    let db action = database.EnqueueInternal action

    let checkCancelled version () =
        let cancelled =
            (db (fun () ->
                Sqlite.number
                    connection
                    null
                    "SELECT cancelled FROM mod_versions WHERE id=$id"
                    [ "$id", box (string version) ]))
                .GetAwaiter()
                .GetResult()

        if cancelled <> 0L then
            raise (OperationCanceledException())

    let capture root (library: StoredLibrary) row version afterEffect afterObservation =
        task {
            let! previous =
                db (fun () ->
                    row.Entry.CurrentVersion
                    |> Option.bind (fun id -> LibraryRows.version connection null id 0 100001)
                    |> Option.map _.Entries
                    |> Option.defaultValue [])

            let prior =
                previous |> List.map (fun entry -> entry.Path, entry.Payload) |> Map.ofList

            let! captured =
                Task.Run(fun () ->
                    match
                        LibraryFiles.openSource
                            root
                            row
                            (library.Identity |> Option.toList |> Set.ofList)
                    with
                    | Error error -> Error error
                    | Ok source ->
                        use source = source
                        use destination = LibraryFiles.openLibrary root library
                        let check = checkCancelled version

                        match
                            SourceFiles.scan
                                source
                                (Set.singleton destination.Identity)
                                100000
                                check
                        with
                        | Error error -> Error error.Error
                        | Ok(files, _) ->
                            let captureFile file =
                                check ()

                                let reused =
                                    prior
                                    |> Map.tryFind file.Path
                                    |> Option.filter (fun payload ->
                                        payload.Length = file.Length
                                        && payload.Sha256 = file.Sha256)

                                let payload =
                                    match reused with
                                    | Some payload ->
                                        let stored =
                                            (db (fun () ->
                                                LibraryRows.payload connection null payload.Id
                                                |> Option.get))
                                                .GetAwaiter()
                                                .GetResult()

                                        LibraryFiles.verify destination stored
                                        Ok payload
                                    | None ->
                                        let payload =
                                            { Id = Guid.NewGuid()
                                              Length = file.Length
                                              Sha256 = file.Sha256 }

                                        (db (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "INSERT INTO mod_payloads(id,workspace_id,publication_id) VALUES($id,$workspace,$version)"
                                                [ "$id", box (string payload.Id)
                                                  "$workspace", box (string root.Id)
                                                  "$version", box (string version) ]))
                                            .GetAwaiter()
                                            .GetResult()

                                        let stream, identity =
                                            destination.Create(LibraryFiles.payloadName payload.Id)

                                        use stream = stream

                                        SourceFiles.copy source file stream check
                                        |> Result.map (fun () ->
                                            afterEffect ()

                                            (db (fun () ->
                                                Sqlite.execute
                                                    connection
                                                    null
                                                    "UPDATE mod_payloads SET identity=$identity,length=$length,digest=$digest WHERE id=$id"
                                                    [ "$id", box (string payload.Id)
                                                      "$identity",
                                                      box (LibraryEncoding.identity identity)
                                                      "$length", box payload.Length
                                                      "$digest", box payload.Sha256 ]))
                                                .GetAwaiter()
                                                .GetResult()

                                            payload)

                                payload
                                |> Result.map (fun payload ->
                                    (db (fun () ->
                                        Sqlite.execute
                                            connection
                                            null
                                            "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                                            [ "$version", box (string version)
                                              "$path", box (LibraryEncoding.path file.Path)
                                              "$payload", box (string payload.Id) ]))
                                        .GetAwaiter()
                                        .GetResult())

                            use entries = files.GetEnumerator()
                            let mutable failure = None

                            while failure.IsNone && entries.MoveNext() do
                                match captureFile entries.Current with
                                | Ok() -> ()
                                | Error error -> failure <- Some error

                            match failure with
                            | Some error -> Error error
                            | None ->
                                SourceFiles.scan
                                    source
                                    (Set.singleton destination.Identity)
                                    100000
                                    check
                                |> Result.mapError _.Error
                                |> Result.bind (fun (after, _) ->
                                    if files = after then
                                        Ok()
                                    else
                                        Error LibraryError.SourceChanged))

            match captured with
            | Error error -> return Error error
            | Ok() ->
                do!
                    db (fun () ->
                        Sqlite.execute
                            connection
                            null
                            "UPDATE mod_versions SET phase=2 WHERE id=$id AND owner=$owner AND phase=1"
                            [ "$id", box (string version); "$owner", box database.OwnerId ])

                afterObservation ()
                return Ok()
        }

    let clearCapture root library version =
        task {
            let! payloads =
                db (fun () ->
                    use statement =
                        Sqlite.command
                            connection
                            null
                            "SELECT id FROM mod_payloads WHERE publication_id=$version"
                            [ "$version", box (string version) ]

                    use reader = statement.ExecuteReader()

                    [ while reader.Read() do
                          yield Guid.Parse(reader.GetString 0) ])

            do!
                Task.Run(fun () ->
                    use destination = LibraryFiles.openLibrary root library

                    for payload in payloads do
                        let name = LibraryFiles.payloadName payload

                        match destination.InspectEntry name with
                        | None -> ()
                        | Some entry when entry.Kind = EntryKind.RegularFile ->
                            destination.RemoveFile(name, entry.Identity)
                        | Some _ -> raise (IOException("The incomplete library file changed.")))

            do!
                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "DELETE FROM mod_manifest WHERE version_id=$version; DELETE FROM mod_payloads WHERE publication_id=$version"
                        [ "$version", box (string version) ])
        }

    let cleanupIncomplete version =
        task {
            let! cleanup =
                db (fun () ->
                    match PublicationRows.find connection null version with
                    | None -> Ok None
                    | Some receipt when receipt.Phase = PublicationPhase.Complete ->
                        Error LibraryError.UnsupportedAction
                    | Some receipt ->
                        match LibraryRows.find connection null receipt.ModId with
                        | None -> Error LibraryError.NotFound
                        | Some row ->
                            use statement =
                                Sqlite.command
                                    connection
                                    null
                                    "SELECT id FROM mod_payloads WHERE publication_id=$version"
                                    [ "$version", box (string version) ]

                            use reader = statement.ExecuteReader()

                            let payloads =
                                [ while reader.Read() do
                                      yield Guid.Parse(reader.GetString 0) ]

                            Ok(Some(row.Entry.WorkspaceId, payloads)))

            match cleanup with
            | Error error -> return Error error
            | Ok None -> return Ok version
            | Ok(Some(workspace, payloads)) ->
                let! filesRemoved =
                    task {
                        if payloads.IsEmpty then
                            return Ok()
                        else
                            let! rootResult = access.Root workspace

                            match rootResult with
                            | Error error -> return Error error
                            | Ok root ->
                                let! library =
                                    db (fun () -> LibraryRows.library connection null workspace)

                                match library with
                                | None -> return Error LibraryError.FileUnavailable
                                | Some library ->
                                    do!
                                        Task.Run(fun () ->
                                            use destination = LibraryFiles.openLibrary root library

                                            for payload in payloads do
                                                let name = LibraryFiles.payloadName payload

                                                match destination.InspectEntry name with
                                                | None -> ()
                                                | Some entry when
                                                    entry.Kind = EntryKind.RegularFile
                                                    ->
                                                    destination.RemoveFile(name, entry.Identity)
                                                | Some _ ->
                                                    raise (
                                                        IOException(
                                                            "The incomplete library file changed."
                                                        )
                                                    ))

                                    return Ok()
                    }

                match filesRemoved with
                | Error error -> return Error error
                | Ok() -> return! db (fun () -> PublicationRows.removeIncomplete connection version)
        }

    let verify root library version =
        task {
            let! payloads =
                db (fun () ->
                    use statement =
                        Sqlite.command
                            connection
                            null
                            "SELECT DISTINCT payload_id FROM mod_manifest WHERE version_id=$id"
                            [ "$id", box (string version) ]

                    use reader = statement.ExecuteReader()

                    let ids =
                        [ while reader.Read() do
                              yield Guid.Parse(reader.GetString 0) ]

                    reader.Close()

                    ids
                    |> List.map (fun id -> LibraryRows.payload connection null id |> Option.get))

            do!
                Task.Run(fun () ->
                    use directory = LibraryFiles.openLibrary root library

                    for payload in payloads do
                        checkCancelled version ()
                        LibraryFiles.verify directory payload)
        }

    member private _.Run
        (
            modId,
            expected,
            version,
            composition,
            cancellation: System.Threading.CancellationToken,
            afterEffect,
            afterObservation,
            beforeInlineEffect,
            finalize
        ) =
        task {
            if version = Guid.Empty then
                return Error LibraryError.IdentityConflict
            else
                let! prepared =
                    database.Enqueue(fun () ->
                        PublicationRows.prepare
                            connection
                            database.OwnerId
                            modId
                            expected
                            version
                            composition)

                match prepared with
                | Error error -> return Error error
                | Ok(row, Replay) -> return Ok row.Entry
                | Ok(row, work) ->
                    let mutable successful = false
                    let mutable cancelled = false

                    try
                        try
                            let! rootResult = access.Root row.Entry.WorkspaceId

                            match rootResult with
                            | Error error -> return Error error
                            | Ok root ->
                                let! libraryResult = access.PrepareLibrary(root, ignore)

                                match libraryResult with
                                | Error error -> return Error error
                                | Ok library ->
                                    let! captured =
                                        task {
                                            match work with
                                            | Capture
                                            | RestartCapture ->
                                                if work = RestartCapture then
                                                    do! clearCapture root library version

                                                match composition with
                                                | None ->
                                                    return!
                                                        capture
                                                            root
                                                            library
                                                            row
                                                            version
                                                            afterEffect
                                                            afterObservation
                                                | Some input ->
                                                    return!
                                                        LibraryComposition.capture
                                                            database
                                                            root
                                                            library
                                                            version
                                                            input
                                                            (fun () ->
                                                                cancellation
                                                                    .ThrowIfCancellationRequested()

                                                                checkCancelled version ())
                                                            afterEffect
                                                            afterObservation
                                                            beforeInlineEffect
                                            | CommitObserved -> return Ok()
                                            | Replay ->
                                                return
                                                    invalidOp
                                                        "A completed publication has no file work."
                                        }

                                    match captured with
                                    | Error error -> return Error error
                                    | Ok() -> do! verify root library version

                                    let! completed =
                                        db (fun () ->
                                            match finalize with
                                            | None ->
                                                PublicationRows.complete
                                                    connection
                                                    database.OwnerId
                                                    version
                                            | Some finish ->
                                                use transaction =
                                                    connection.BeginTransaction(deferred = false)

                                                let completed =
                                                    PublicationRows.completeIn
                                                        connection
                                                        transaction
                                                        database.OwnerId
                                                        version

                                                let result =
                                                    completed
                                                    |> Result.bind (fun entry ->
                                                        finish connection transaction entry
                                                        |> Result.map (fun () -> entry))

                                                if Result.isOk result then
                                                    transaction.Commit()

                                                result)

                                    match completed with
                                    | Ok _ -> successful <- true
                                    | Error LibraryError.Cancelled -> cancelled <- true
                                    | Error _ -> ()

                                    return completed
                        with
                        | :? OperationCanceledException ->
                            cancelled <- true
                            return Error LibraryError.Cancelled
                        | :? IOException
                        | :? UnauthorizedAccessException ->
                            return Error LibraryError.FileUnavailable
                    finally
                        if not successful then
                            // Accepted jobs use the internal queue even when external readers saturate it.
                            try
                                (db (fun () ->
                                    PublicationRows.fail
                                        connection
                                        database.OwnerId
                                        version
                                        cancelled))
                                    .GetAwaiter()
                                    .GetResult()

                                if cancelled || Option.isSome finalize then
                                    match (cleanupIncomplete version).GetAwaiter().GetResult() with
                                    | Ok _ -> ()
                                    | Error _ ->
                                        raise (
                                            IOException(
                                                "The incomplete publication could not be removed."
                                            )
                                        )
                            with _ ->
                                access.Fail()
                                reraise ()
        }

    member _.Publish(modId, expected, version, afterEffect, afterObservation) =
        this.Run(
            modId,
            expected,
            version,
            None,
            System.Threading.CancellationToken.None,
            afterEffect,
            afterObservation,
            ignore,
            None
        )

    member _.Compose
        (
            modId,
            expected,
            version,
            input,
            cancellation,
            afterEffect,
            afterObservation,
            beforeInlineEffect
        ) =
        this.Run(
            modId,
            expected,
            version,
            Some input,
            cancellation,
            afterEffect,
            afterObservation,
            beforeInlineEffect,
            None
        )

    member _.ComposeFinalized(modId, expected, version, input, cancellation, finalize) =
        this.Run(
            modId,
            expected,
            version,
            Some input,
            cancellation,
            ignore,
            ignore,
            ignore,
            Some finalize
        )

    member _.Abandon(action) =
        task {
            let! claimed =
                db (fun () -> PublicationRows.claimAbandon connection database.OwnerId action)

            match claimed with
            | Error error -> return Error error
            | Ok version ->
                try
                    let! removed = cleanupIncomplete version

                    match removed with
                    | Ok _ -> return Ok version
                    | Error error ->
                        do!
                            db (fun () ->
                                PublicationRows.releaseAbandon connection database.OwnerId version)

                        return Error error
                with error ->
                    do!
                        db (fun () ->
                            PublicationRows.releaseAbandon connection database.OwnerId version)

                    return raise error
        }
