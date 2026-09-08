namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.ModLibrary

type internal PublicationWork =
    | Replay
    | Capture
    | CommitObserved

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
            | Some receipt, Some row when
                receipt.ModId = modId && receipt.ExpectedRevision = expected
                ->
                let matchingOrigin =
                    match LibraryRows.origin connection transaction version, composition with
                    | VersionOrigin.RegisteredSource, None -> true
                    | VersionOrigin.Outputs action, Some input -> action = input.ActionId
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
                          "$label", box input.VersionLabel ])

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

    let complete (connection: Microsoft.Data.Sqlite.SqliteConnection) owner version =
        use transaction = connection.BeginTransaction(deferred = false)
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

                Ok (LibraryRows.find connection transaction receipt.ModId |> Option.get).Entry

        transaction.Commit()
        result
