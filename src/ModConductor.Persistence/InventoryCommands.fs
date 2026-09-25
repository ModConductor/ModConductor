namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.Platform

module internal InventoryCommands =
    let register
        (database: StateDatabase)
        (access: LibraryAccess)
        workspace
        id
        metadata
        registration
        =
        task {
            match InventoryPolicy.metadata metadata with
            | Error error -> return Error error
            | Ok _ when id = Guid.Empty -> return Error LibraryError.IdentityConflict
            | Ok metadata ->
                let! rootResult = access.Root workspace

                match rootResult with
                | Error error -> return Error error
                | Ok root ->
                    let! libraryResult = access.PrepareLibrary(root, ignore)

                    match libraryResult with
                    | Error error -> return Error error
                    | Ok library ->
                        let! input =
                            Task.Run(fun () ->
                                let normalized =
                                    match registration with
                                    | Registration.NativeDirectory(kind, candidate) ->
                                        SourceFiles.relative root.Path candidate
                                        |> Result.map (fun path ->
                                            Registration.Directory(kind, path))
                                    | value -> Ok value

                                match normalized with
                                | Error error -> Error error
                                | Ok(Registration.Directory(kind, path)) when
                                    kind = ModKind.Regular
                                    || kind = ModKind.Unmanaged
                                    || kind = ModKind.GeneratedOutput
                                    ->
                                    use directory = HeldDirectory.Open(root.Path, root.Identity)

                                    use source =
                                        SourceFiles.child
                                            directory
                                            path
                                            None
                                            (library.Identity |> Option.toList |> Set.ofList)

                                    Ok(kind, Some path, Some source.Identity, None)
                                | Ok(Registration.Directory _)
                                | Ok(Registration.NativeDirectory _) ->
                                    Error LibraryError.UnsupportedAction
                                | Ok Registration.Separator ->
                                    Ok(ModKind.Separator, None, None, None)
                                | Ok(Registration.Backup version) ->
                                    Ok(ModKind.Backup, None, None, Some version))

                        match input with
                        | Error error -> return Error error
                        | Ok(kind, path, identity, version) ->
                            return!
                                database.Enqueue(fun () ->
                                    use transaction =
                                        database.Connection.BeginTransaction(deferred = false)

                                    let versionValid =
                                        version
                                        |> Option.forall (fun version ->
                                            LibraryRows.version
                                                database.Connection
                                                transaction
                                                version
                                                0
                                                1
                                            |> Option.bind (fun value ->
                                                LibraryRows.find
                                                    database.Connection
                                                    transaction
                                                    value.ModId)
                                            |> Option.exists (fun value ->
                                                value.Entry.WorkspaceId = workspace))

                                    let canonical =
                                        CategoryRows.canonicalMetadata
                                            database.Connection
                                            transaction
                                            workspace
                                            id
                                            metadata

                                    let result =
                                        match
                                            canonical,
                                            LibraryRows.find database.Connection transaction id
                                        with
                                        | Error error, _ -> Error error
                                        | Ok metadata, Some row when
                                            row.Entry.WorkspaceId = workspace
                                            && row.Entry.Kind = kind
                                            && row.Entry.Metadata = metadata
                                            && row.Entry.SourcePath = path
                                            && row.SourceIdentity = identity
                                            && row.Entry.CurrentVersion = version
                                            ->
                                            Ok row.Entry
                                        | Ok _, Some _ -> Error LibraryError.IdentityConflict
                                        | Ok _, None when not versionValid ->
                                            Error LibraryError.NotFound
                                        | Ok metadata, None ->
                                            Sqlite.execute
                                                database.Connection
                                                transaction
                                                "INSERT INTO mods VALUES($id,$workspace,$kind,$name,$notes,$comment,$version,$source,0,$path,$identity,$current,1)"
                                                (LibraryRows.metadataParameters metadata
                                                 @ [ "$id", box (string id)
                                                     "$workspace", box (string workspace)
                                                     "$kind", box (LibraryEncoding.kind kind)
                                                     "$path",
                                                     (path
                                                      |> Option.map (LibraryEncoding.path >> box)
                                                      |> Option.defaultValue (box DBNull.Value))
                                                     "$identity",
                                                     (identity
                                                      |> Option.map (
                                                          LibraryEncoding.identity >> box
                                                      )
                                                      |> Option.defaultValue (box DBNull.Value))
                                                     "$current",
                                                     (version
                                                      |> Option.map (string >> box)
                                                      |> Option.defaultValue (box DBNull.Value)) ])

                                            CategoryRows.saveReferences
                                                database.Connection
                                                transaction
                                                id
                                                metadata.Categories

                                            SelectionRows.registered
                                                database.Connection
                                                transaction
                                                workspace
                                                id
                                                kind

                                            Ok
                                                (LibraryRows.find
                                                    database.Connection
                                                    transaction
                                                    id
                                                 |> Option.get)
                                                    .Entry

                                    transaction.Commit()
                                    result)
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
                    let! root = access.Root row.Entry.WorkspaceId

                    match root with
                    | Error error -> return Error error
                    | Ok _ ->
                        return!
                            database.Enqueue(fun () ->
                                use transaction =
                                    database.Connection.BeginTransaction(deferred = false)

                                let current =
                                    LibraryRows.find database.Connection transaction id
                                    |> Option.get

                                let result =
                                    if current.Entry.Revision <> expected then
                                        Error LibraryError.StaleRevision
                                    elif
                                        not (
                                            List.contains
                                                ModAction.EditMetadata
                                                current.Entry.Actions
                                        )
                                    then
                                        Error LibraryError.UnsupportedAction
                                    elif
                                        current.Entry.Status = InventoryStatus.Publishing
                                        || MaintenanceClaims.busy
                                            database.Connection
                                            transaction
                                            id
                                    then
                                        Error LibraryError.Busy
                                    else
                                        match
                                            CategoryRows.canonicalMetadata
                                                database.Connection
                                                transaction
                                                current.Entry.WorkspaceId
                                                id
                                                metadata
                                        with
                                        | Error error -> Error error
                                        | Ok metadata ->
                                            CategoryRows.saveReferences
                                                database.Connection
                                                transaction
                                                id
                                                metadata.Categories

                                            Sqlite.execute
                                                database.Connection
                                                transaction
                                                "UPDATE mods SET name=$name,notes=$notes,comment=$comment,version_text=$version,source_text=$source,revision=revision+1 WHERE id=$id"
                                                (LibraryRows.metadataParameters metadata
                                                 @ [ "$id", box (string id) ])

                                            beforeCommit ()

                                            Ok
                                                (LibraryRows.find
                                                    database.Connection
                                                    transaction
                                                    id
                                                 |> Option.get)
                                                    .Entry

                                transaction.Commit()
                                result)
        }

    let private createOutput connection transaction workspace id kind metadata =
        if id = Guid.Empty then
            raise (InvalidDataException "The mod identity is empty.")

        let metadata =
            InventoryPolicy.metadata metadata
            |> Result.defaultWith (fun _ ->
                raise (InvalidDataException "The mod metadata is invalid."))

        if LibraryRows.find connection transaction id |> Option.isSome then
            raise (InvalidDataException "The mod identity is already in use.")

        Sqlite.execute
            connection
            transaction
            "INSERT INTO mods VALUES($id,$workspace,$kind,$name,$notes,$comment,$version,$source,0,NULL,NULL,NULL,1)"
            (LibraryRows.metadataParameters metadata
             @ [ "$id", box (string id)
                 "$workspace", box (string workspace)
                 "$kind", box (LibraryEncoding.kind kind) ])

        if kind = ModKind.Regular then
            SelectionRows.registered connection transaction workspace id kind

        (LibraryRows.find connection transaction id |> Option.get).Entry

    let createFromOutputs connection transaction workspace id metadata =
        createOutput connection transaction workspace id ModKind.Regular metadata

    let createFnisOutput connection transaction workspace id metadata =
        createOutput connection transaction workspace id ModKind.GeneratedOutput metadata
