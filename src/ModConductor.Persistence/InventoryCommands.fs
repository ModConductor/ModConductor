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
                                match registration with
                                | Registration.Directory(kind, path) when
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
                                | Registration.Directory _ -> Error LibraryError.UnsupportedAction
                                | Registration.Separator -> Ok(ModKind.Separator, None, None, None)
                                | Registration.Backup version ->
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

                                    let result =
                                        match
                                            LibraryRows.find database.Connection transaction id
                                        with
                                        | Some row when
                                            row.Entry.WorkspaceId = workspace
                                            && row.Entry.Kind = kind
                                            && row.Entry.Metadata = metadata
                                            && row.Entry.SourcePath = path
                                            && row.SourceIdentity = identity
                                            && row.Entry.CurrentVersion = version
                                            ->
                                            Ok row.Entry
                                        | Some _ -> Error LibraryError.IdentityConflict
                                        | None when not versionValid -> Error LibraryError.NotFound
                                        | None ->
                                            Sqlite.execute
                                                database.Connection
                                                transaction
                                                "INSERT INTO mods VALUES($id,$workspace,$kind,$name,$notes,$comment,$version,$source,$category,0,$path,$identity,$current,1)"
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
                                    elif current.Entry.Status = InventoryStatus.Publishing then
                                        Error LibraryError.Busy
                                    else
                                        Sqlite.execute
                                            database.Connection
                                            transaction
                                            "UPDATE mods SET name=$name,notes=$notes,comment=$comment,version_text=$version,source_text=$source,category=$category,revision=revision+1 WHERE id=$id"
                                            (LibraryRows.metadataParameters metadata
                                             @ [ "$id", box (string id) ])

                                        beforeCommit ()

                                        Ok
                                            (LibraryRows.find database.Connection transaction id
                                             |> Option.get)
                                                .Entry

                                transaction.Commit()
                                result)
        }

    let inventory (database: StateDatabase) (access: LibraryAccess) profile after =
        task {
            let! workspace =
                database.Enqueue(fun () ->
                    LibraryRows.profileWorkspace database.Connection null profile)

            match workspace with
            | None -> return Error LibraryError.NotFound
            | Some workspace ->
                let! root = access.Root workspace

                match root with
                | Error error -> return Error error
                | Ok _ ->
                    return!
                        database.Enqueue(fun () ->
                            use transaction = database.Connection.BeginTransaction(deferred = true)
                            // Recheck the actual profile reference in the same read snapshot.
                            let result =
                                if
                                    LibraryRows.profileWorkspace
                                        database.Connection
                                        transaction
                                        profile
                                    <> Some workspace
                                then
                                    Error LibraryError.NotFound
                                else
                                    let ids =
                                        LibraryRows.ids
                                            database.Connection
                                            transaction
                                            workspace
                                            (after |> Option.map string |> Option.defaultValue "")
                                            33

                                    let entries =
                                        ids
                                        |> List.choose (fun id ->
                                            LibraryRows.find database.Connection transaction id
                                            |> Option.map _.Entry)
                                        |> InventoryPolicy.inventoryWindow

                                    Ok
                                        { Entries = entries
                                          NextMod =
                                            if ids.Length > entries.Length then
                                                entries |> List.tryLast |> Option.map _.Id
                                            else
                                                None }


                            transaction.Commit()
                            result)
        }
