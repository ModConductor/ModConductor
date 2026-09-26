namespace ModConductor.Persistence

open ModConductor.ModLibrary

module internal InventoryEditing =
    let private update connection transaction id metadata beforeCommit =
        CategoryRows.saveReferences connection transaction id metadata.Categories

        Sqlite.execute
            connection
            transaction
            "UPDATE mods SET name=$name,notes=$notes,comment=$comment,version_text=$version,source_text=$source,revision=revision+1 WHERE id=$id"
            (LibraryRows.metadataParameters metadata @ [ "$id", box (string id) ])

        beforeCommit ()
        Ok((LibraryRows.find connection transaction id |> Option.get).Entry)

    let private decide
        connection
        transaction
        id
        expected
        metadata
        beforeCommit
        (current: StoredMod)
        =
        if current.Entry.Revision <> expected then
            Error LibraryError.StaleRevision
        elif not (List.contains ModAction.EditMetadata current.Entry.Actions) then
            Error LibraryError.UnsupportedAction
        elif
            current.Entry.Status = InventoryStatus.Publishing
            || MaintenanceClaims.busy connection transaction id
        then
            Error LibraryError.Busy
        else
            CategoryRows.canonicalMetadata
                connection
                transaction
                current.Entry.WorkspaceId
                id
                metadata
            |> Result.bind (fun canonical ->
                update connection transaction id canonical beforeCommit)

    let private editRow (database: StateDatabase) id expected (metadata: ModMetadata) beforeCommit =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            let connection = database.Connection
            let current = LibraryRows.find connection transaction id |> Option.get
            let result = decide connection transaction id expected metadata beforeCommit current
            transaction.Commit()
            result)

    let private editExisting
        (database: StateDatabase)
        (access: LibraryAccess)
        id
        expected
        metadata
        beforeCommit
        (row: StoredMod)
        =
        task {
            let! root = access.Root row.Entry.WorkspaceId

            match root with
            | Error error -> return Error error
            | Ok _ -> return! editRow database id expected metadata beforeCommit
        }

    let edit (database: StateDatabase) (access: LibraryAccess) id expected metadata beforeCommit =
        task {
            match InventoryPolicy.metadata metadata with
            | Error error -> return Error error
            | Ok metadata ->
                let! found =
                    database.Enqueue(fun () -> LibraryRows.find database.Connection null id)

                match found with
                | None -> return Error LibraryError.NotFound
                | Some row ->
                    return! editExisting database access id expected metadata beforeCommit row
        }
