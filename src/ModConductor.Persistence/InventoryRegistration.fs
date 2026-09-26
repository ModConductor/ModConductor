namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.Platform

module internal InventoryRegistration =
    let private normalize (root: WorkspaceRoot) registration =
        match registration with
        | Registration.NativeDirectory(kind, candidate) ->
            SourceFiles.relative root.Path candidate
            |> Result.map (fun path -> Registration.Directory(kind, path))
        | value -> Ok value

    let private admitSource (root: WorkspaceRoot) libraryIdentity registration =
        Task.Run(fun () ->
            match normalize root registration with
            | Error error -> Error error
            | Ok(Registration.Directory(kind, path)) when
                kind = ModKind.Regular
                || kind = ModKind.Unmanaged
                || kind = ModKind.GeneratedOutput
                ->
                use directory = HeldDirectory.Open(root.Path, root.Identity)

                match
                    SourceFiles.child
                        directory
                        path
                        None
                        (libraryIdentity |> Option.toList |> Set.ofList)
                with
                | Error error -> Error error
                | Ok source ->
                    use source = source
                    Ok(kind, Some path, Some source.Identity, None)
            | Ok(Registration.Directory _)
            | Ok(Registration.NativeDirectory _) -> Error LibraryError.UnsupportedAction
            | Ok Registration.Separator -> Ok(ModKind.Separator, None, None, None)
            | Ok(Registration.Backup version) -> Ok(ModKind.Backup, None, None, Some version))

    let private versionExists connection transaction workspace version =
        version
        |> Option.forall (fun version ->
            LibraryRows.version connection transaction version 0 1
            |> Option.bind (fun value -> LibraryRows.find connection transaction value.ModId)
            |> Option.exists (fun value -> value.Entry.WorkspaceId = workspace))

    let private insert connection transaction workspace id metadata kind path identity version =
        Sqlite.execute
            connection
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
                  |> Option.map (LibraryEncoding.identity >> box)
                  |> Option.defaultValue (box DBNull.Value))
                 "$current",
                 (version |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)) ])

        CategoryRows.saveReferences connection transaction id metadata.Categories
        SelectionRows.registered connection transaction workspace id kind
        Ok((LibraryRows.find connection transaction id |> Option.get).Entry)

    let private matches workspace kind metadata path identity version (row: StoredMod) =
        row.Entry.WorkspaceId = workspace
        && row.Entry.Kind = kind
        && row.Entry.Metadata = metadata
        && row.Entry.SourcePath = path
        && row.SourceIdentity = identity
        && row.Entry.CurrentVersion = version

    let private decide
        connection
        transaction
        workspace
        id
        metadata
        kind
        path
        identity
        version
        valid
        =
        let canonical =
            CategoryRows.canonicalMetadata connection transaction workspace id metadata

        let existing = LibraryRows.find connection transaction id

        match canonical, existing with
        | Error error, _ -> Error error
        | Ok metadata, Some row when matches workspace kind metadata path identity version row ->
            Ok row.Entry
        | Ok _, Some _ -> Error LibraryError.IdentityConflict
        | Ok _, None when not valid -> Error LibraryError.NotFound
        | Ok metadata, None ->
            insert connection transaction workspace id metadata kind path identity version

    let private registerRow
        (database: StateDatabase)
        workspace
        id
        metadata
        kind
        path
        identity
        version
        =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            let connection = database.Connection
            let valid = versionExists connection transaction workspace version

            let result =
                decide
                    connection
                    transaction
                    workspace
                    id
                    metadata
                    kind
                    path
                    identity
                    version
                    valid

            transaction.Commit()
            result)

    let private prepareRegistration (access: LibraryAccess) workspace registration =
        task {
            let! rootResult = access.Root workspace

            match rootResult with
            | Error error -> return Error error
            | Ok root ->
                let! libraryResult = access.PrepareLibrary(root, ignore)

                match libraryResult with
                | Error error -> return Error error
                | Ok library -> return! admitSource root library.Identity registration
        }

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
                let! input = prepareRegistration access workspace registration

                match input with
                | Error error -> return Error error
                | Ok(kind, path, identity, version) ->
                    return! registerRow database workspace id metadata kind path identity version
        }
