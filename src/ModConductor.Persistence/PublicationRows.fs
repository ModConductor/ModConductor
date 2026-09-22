namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open ModConductor.ModLibrary
open ModConductor.Platform

type internal PublicationWork =
    | Replay
    | Capture
    | RestartCapture
    | CommitObserved

type internal PersistedEdit =
    { VersionId: Guid
      ModId: Guid
      ExpectedRevision: int64
      Phase: PublicationPhase
      SourceVersion: Guid
      Path: LogicalPath
      PreviousPayload: Guid
      Content: byte array
      Digest: string }

module internal PublicationRows =
    let readPhase =
        function
        | 1 -> PublicationPhase.Intent
        | 2 -> PublicationPhase.Observed
        | 3 -> PublicationPhase.Complete
        | 4 -> PublicationPhase.Interrupted
        | 5 -> PublicationPhase.Cancelled
        | _ -> raise (InvalidDataException("Unknown publication phase."))

    let find connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,expected_revision,phase FROM mod_versions WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            Some
                { VersionId = id
                  ModId = Guid.Parse(reader.GetString 0)
                  ExpectedRevision = reader.GetInt64 1
                  Phase = readPhase (reader.GetInt32 2) }

    let edit connection transaction action limit =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT e.version_id,v.mod_id,v.expected_revision,v.phase,e.source_version,e.path,e.previous_payload,e.content,e.digest FROM mod_edit_origins e JOIN mod_versions v ON v.id=e.version_id WHERE e.edit_id=$action"
                [ "$action", box (string action) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            Ok None
        else
            let content = reader.GetFieldValue<byte array> 7
            let digest = reader.GetString 8
            let phase = readPhase (reader.GetInt32 3)

            if content.Length > limit then
                Error LibraryError.LimitExceeded
            elif
                phase <> PublicationPhase.Complete
                && phase <> PublicationPhase.Cancelled
                && Convert.ToHexStringLower(SHA256.HashData content) <> digest
            then
                Error LibraryError.SourceChanged
            else
                Ok(
                    Some
                        { VersionId = Guid.Parse(reader.GetString 0)
                          ModId = Guid.Parse(reader.GetString 1)
                          ExpectedRevision = reader.GetInt64 2
                          Phase = phase
                          SourceVersion = Guid.Parse(reader.GetString 4)
                          Path = LibraryEncoding.readPath (reader.GetString 5)
                          PreviousPayload = Guid.Parse(reader.GetString 6)
                          Content = content
                          Digest = digest }
                )

    let prepare
        (connection: Microsoft.Data.Sqlite.SqliteConnection)
        owner
        modId
        expected
        version
        (composition: LibraryCompositionInput option)
        =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match
                find connection transaction version, LibraryRows.find connection transaction modId
            with
            | _, Some _ when MaintenanceClaims.busy connection transaction modId ->
                Error LibraryError.Busy
            | Some receipt, Some row when
                receipt.ModId = modId && receipt.ExpectedRevision = expected
                ->
                let matchingOrigin =
                    match LibraryRows.origin connection transaction version, composition with
                    | VersionOrigin.RegisteredSource, None -> true
                    | VersionOrigin.Outputs action, Some input ->
                        action = input.ActionId && input.Bytes.IsEmpty
                    | VersionOrigin.Edited(action, source, path, digest), Some input ->
                        match input.SourceVersion, input.Files, input.Bytes with
                        | Some expected, [], [ file ] ->
                            action = input.ActionId
                            && source = expected
                            && path = file.Target
                            && digest = file.Sha256
                        | _ -> false
                    | _ -> false

                if not matchingOrigin then
                    Error LibraryError.IdentityConflict
                elif receipt.Phase = PublicationPhase.Complete then
                    Ok(row, Replay)
                elif
                    receipt.Phase = PublicationPhase.Observed
                    && Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                        [ "$mod", box (string modId) ] = 0L
                then
                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE mod_versions SET owner=$owner,busy=1 WHERE id=$id"
                        [ "$owner", box owner; "$id", box (string version) ]

                    Ok(row, CommitObserved)
                elif
                    receipt.Phase = PublicationPhase.Interrupted
                    && Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                        [ "$mod", box (string modId) ] = 0L
                then
                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE mod_versions SET owner=$owner,phase=1,busy=1,cancelled=0 WHERE id=$id"
                        [ "$owner", box owner; "$id", box (string version) ]

                    LibraryRows.setStatus connection transaction modId InventoryStatus.Publishing
                    Ok(row, RestartCapture)
                elif
                    receipt.Phase = PublicationPhase.Intent
                    || receipt.Phase = PublicationPhase.Observed
                then
                    Error LibraryError.Busy
                else
                    Error LibraryError.UnprovedOwnership
            | Some _, _ -> Error LibraryError.IdentityConflict
            | None, None -> Error LibraryError.NotFound
            | None, Some row when row.Entry.Revision <> expected -> Error LibraryError.StaleRevision
            | None, Some row when composition.IsNone && row.Entry.SourcePath.IsNone ->
                Error LibraryError.UnsupportedAction
            | None, Some row when
                composition
                |> Option.exists (fun input -> input.SourceVersion <> row.Entry.CurrentVersion)
                ->
                Error LibraryError.StaleRevision
            | None, Some row when row.Entry.Kind <> ModKind.Regular ->
                Error LibraryError.UnsupportedAction
            | None, Some _ when
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM mod_versions WHERE mod_id=$mod AND busy=1"
                    [ "$mod", box (string modId) ]
                <> 0L
                ->
                Error LibraryError.Busy
            | None, Some row ->
                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_versions(id,mod_id,expected_revision,owner,phase,busy) VALUES($version,$mod,$revision,$owner,1,1)"
                    [ "$version", box (string version)
                      "$mod", box (string modId)
                      "$revision", box expected
                      "$owner", box owner ]

                composition
                |> Option.iter (fun input ->
                    match input.SourceVersion, input.Files, input.Bytes with
                    | Some source, [], [ file ] ->
                        let previous =
                            LibraryRows.version connection transaction source 0 100001
                            |> Option.bind (fun value ->
                                value.Entries
                                |> List.tryFind (fun entry -> entry.Path = file.Target))
                            |> Option.defaultWith (fun () -> raise (SourceChangedException()))

                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO mod_edit_origins VALUES($version,$action,$source,$path,$payload,$content,$digest)"
                            [ "$version", box (string version)
                              "$action", box (string input.ActionId)
                              "$source", box (string source)
                              "$path", box (LibraryEncoding.path file.Target)
                              "$payload", box (string previous.Payload.Id)
                              "$content", box file.Content
                              "$digest", box file.Sha256 ]
                    | _, _, [] ->
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO mod_version_origins VALUES($version,$action,$source,$label)"
                            [ "$version", box (string version)
                              "$action", box (string input.ActionId)
                              "$source",
                              input.SourceVersion
                              |> Option.map (string >> box)
                              |> Option.defaultValue (box DBNull.Value)
                              "$label", box input.VersionLabel ]
                    | _ -> raise (SourceOverlapException()))

                LibraryRows.setStatus connection transaction modId InventoryStatus.Publishing
                Ok(row, Capture)

        transaction.Commit()
        result

    let fail (connection: Microsoft.Data.Sqlite.SqliteConnection) owner version cancelled =
        use transaction = connection.BeginTransaction(deferred = false)

        match find connection transaction version with
        | Some receipt when receipt.Phase <> PublicationPhase.Complete ->
            Sqlite.execute
                connection
                transaction
                "UPDATE mod_versions SET phase=$phase,busy=0 WHERE id=$id AND owner=$owner"
                [ "$id", box (string version)
                  "$owner", box owner
                  "$phase", box (if cancelled then 5 else 4) ]

            LibraryRows.setStatus connection transaction receipt.ModId InventoryStatus.Unproved
        | Some _
        | None -> ()

        transaction.Commit()

    let cancel (connection: Microsoft.Data.Sqlite.SqliteConnection) version =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match find connection transaction version with
            | None -> Error LibraryError.NotFound
            | Some receipt when
                receipt.Phase = PublicationPhase.Complete
                || receipt.Phase = PublicationPhase.Cancelled
                ->
                Ok receipt
            | Some receipt ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_versions SET cancelled=1,phase=5 WHERE id=$id"
                    [ "$id", box (string version) ]
                // Cancellation prevents commit immediately; the bounded worker can still be closing its current file.
                if
                    Sqlite.number
                        connection
                        transaction
                        "SELECT busy FROM mod_versions WHERE id=$id"
                        [ "$id", box (string version) ] = 0L
                then
                    LibraryRows.setStatus
                        connection
                        transaction
                        receipt.ModId
                        InventoryStatus.Unproved

                Ok
                    { receipt with
                        Phase = PublicationPhase.Cancelled }

        transaction.Commit()
        result

    let claimAbandon (connection: Microsoft.Data.Sqlite.SqliteConnection) owner action =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match edit connection transaction action Int32.MaxValue with
            | Error error -> Error error
            | Ok None -> Error LibraryError.NotFound
            | Ok(Some persisted) when persisted.Phase = PublicationPhase.Complete ->
                Error LibraryError.UnsupportedAction
            | Ok(Some persisted) when
                Sqlite.number
                    connection
                    transaction
                    "SELECT busy FROM mod_versions WHERE id=$id"
                    [ "$id", box (string persisted.VersionId) ]
                <> 0L
                ->
                Error LibraryError.Busy
            | Ok(Some persisted) ->
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_versions SET owner=$owner,phase=5,busy=1,cancelled=1 WHERE id=$id"
                    [ "$id", box (string persisted.VersionId); "$owner", box owner ]

                Ok persisted.VersionId

        transaction.Commit()
        result

    let releaseAbandon (connection: Microsoft.Data.Sqlite.SqliteConnection) owner version =
        use transaction = connection.BeginTransaction(deferred = false)

        match find connection transaction version with
        | Some receipt when receipt.Phase <> PublicationPhase.Complete ->
            Sqlite.execute
                connection
                transaction
                "UPDATE mod_versions SET busy=0 WHERE id=$id AND owner=$owner"
                [ "$id", box (string version); "$owner", box owner ]

            LibraryRows.setStatus connection transaction receipt.ModId InventoryStatus.Unproved
        | Some _
        | None -> ()

        transaction.Commit()

    let removeIncomplete (connection: Microsoft.Data.Sqlite.SqliteConnection) version =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match find connection transaction version with
            | None -> Error LibraryError.NotFound
            | Some receipt when receipt.Phase = PublicationPhase.Complete ->
                Error LibraryError.UnsupportedAction
            | Some receipt when
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM mods WHERE current_version=$id"
                    [ "$id", box (string version) ]
                <> 0L
                ->
                Error LibraryError.IdentityConflict
            | Some receipt ->
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM mod_manifest WHERE version_id=$id; DELETE FROM mod_edit_origins WHERE version_id=$id; DELETE FROM mod_version_origins WHERE version_id=$id; DELETE FROM mod_payloads WHERE publication_id=$id; DELETE FROM mod_versions WHERE id=$id"
                    [ "$id", box (string version) ]

                LibraryRows.setStatus connection transaction receipt.ModId InventoryStatus.Ready
                Ok version

        transaction.Commit()
        result

    let completeIn (connection: Microsoft.Data.Sqlite.SqliteConnection) transaction owner version =
        let receipt = find connection transaction version |> Option.get
        let row = LibraryRows.find connection transaction receipt.ModId |> Option.get

        let cancelled =
            Sqlite.number
                connection
                transaction
                "SELECT cancelled FROM mod_versions WHERE id=$id"
                [ "$id", box (string version) ]
            <> 0L

        let result =
            if cancelled then
                Error LibraryError.Cancelled
            elif row.Entry.Revision <> receipt.ExpectedRevision then
                Error LibraryError.StaleRevision
            else
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_versions SET phase=3,busy=0 WHERE id=$id AND owner=$owner AND phase=2"
                    [ "$id", box (string version); "$owner", box owner ]

                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mods SET current_version=$version,revision=revision+1,status=1,version_text=COALESCE((SELECT version_label FROM mod_version_origins WHERE version_id=$version),version_text) WHERE id=$mod"
                    [ "$version", box (string version); "$mod", box (string receipt.ModId) ]

                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_edit_origins SET content=X'' WHERE version_id=$version"
                    [ "$version", box (string version) ]

                Ok (LibraryRows.find connection transaction receipt.ModId |> Option.get).Entry

        result

    let complete (connection: Microsoft.Data.Sqlite.SqliteConnection) owner version =
        use transaction = connection.BeginTransaction(deferred = false)
        let result = completeIn connection transaction owner version
        transaction.Commit()
        result
