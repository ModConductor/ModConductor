namespace ModConductor.Persistence

open System
open ModConductor.Nexus

// SQL work is brief; provider requests run outside this owner.
type internal NexusMetadataStore(database: StateDatabase) =
    let connection = database.Connection

    let read tx workspace modId =
        NexusMetadataRows.read connection tx database.OwnerId workspace modId

    let transact (expected: ModNexusDetails) check action =
        database.EnqueueInternal(fun () ->
            use tx = connection.BeginTransaction(deferred = false)

            let result =
                read tx expected.Workspace expected.Mod
                |> Result.bind (fun current ->
                    if
                        current.LinkRevision <> expected.LinkRevision
                        || current.Identity <> expected.Identity
                        || current.Version <> expected.Version
                        || not (check current)
                    then
                        Error NexusProblem.ModChanged
                    else
                        action tx current
                        |> Result.bind (fun () -> read tx expected.Workspace expected.Mod))

            tx.Commit()
            result)

    let ensure tx (value: ModNexusDetails) =
        Sqlite.execute
            connection
            tx
            "INSERT OR IGNORE INTO mod_nexus_links(mod_id,game,nexus_mod) VALUES($id,$game,$mod)"
            [ "$id", box (string value.Mod)
              "$game", NexusMetadataRows.nullable (value.Identity |> Option.map _.Game)
              "$mod", NexusMetadataRows.nullable (value.Identity |> Option.map _.Mod) ]

    interface INexusMetadataStore with
        member _.Read(workspace, modId) =
            database.EnqueueInternal(fun () -> read null workspace modId)

        member _.Save(expected, result) =
            transact expected (fun _ -> true) (fun tx current ->
                match result with
                | Ok value when Some value.Identity <> current.Identity ->
                    Error NexusProblem.ModChanged
                | _ when current.Identity.IsNone -> Error NexusProblem.ModChanged
                | _ ->
                    ensure tx current

                    match result with
                    | Ok value ->
                        NexusMetadataRows.save connection tx database.OwnerId current.Mod value
                    | Error error ->
                        Sqlite.execute
                            connection
                            tx
                            "UPDATE mod_nexus_links SET problem=$problem WHERE mod_id=$id"
                            [ "$id", box (string current.Mod)
                              "$problem", box (NexusProblem.message error) ]

                    Ok())

        member _.Link(expected, metadata, file) =
            transact
                expected
                (fun current -> current.ModRevision = expected.ModRevision)
                (fun tx current ->
                    if
                        file.IsSome
                        && (current.Version.IsNone
                            || metadata.IsNone
                            || not (
                                metadata.Value.Files
                                |> List.exists (fun candidate -> candidate.File = file.Value)
                            ))
                    then
                        Error NexusProblem.ModChanged
                    else
                        ensure tx current

                        Sqlite.execute
                            connection
                            tx
                            "UPDATE mod_nexus_links SET revision=revision+1,game=$game,nexus_mod=$mod,name=NULL,summary=NULL,version=NULL,author=NULL,uploader=NULL,category_id=NULL,category_label=NULL,modified=NULL,available=NULL,allows_rating=NULL,checked=NULL,checked_owner=NULL,problem=NULL,mapped_provider=NULL,mapped_category=NULL WHERE mod_id=$id; DELETE FROM mod_nexus_files WHERE mod_id=$id; DELETE FROM mod_nexus_updates WHERE mod_id=$id"
                            [ "$id", box (string current.Mod)
                              "$game",
                              NexusMetadataRows.nullable (metadata |> Option.map _.Identity.Game)
                              "$mod",
                              NexusMetadataRows.nullable (metadata |> Option.map _.Identity.Mod) ]

                        metadata
                        |> Option.iter (
                            NexusMetadataRows.save connection tx database.OwnerId current.Mod
                        )

                        match metadata, file, current.Version with
                        | Some value, Some file, Some version ->
                            NexusOriginRows.save
                                connection
                                tx
                                version
                                value.Identity
                                { Id = file.Id
                                  Version = file.Version
                                  Manual = true }
                        | _ -> ()

                        Ok())

        member _.MapCategory(expected, categoryId) =
            transact
                expected
                (fun current ->
                    (current.Snapshot |> Option.bind _.Category) = (expected.Snapshot
                                                                    |> Option.bind _.Category))
                (fun tx current ->
                    match
                        current.Snapshot |> Option.bind _.Category,
                        CategoryRows.find connection tx categoryId
                    with
                    | Some(provider, _), Some category when
                        not category.Missing && category.WorkspaceId = current.Workspace
                        ->
                        ensure tx current

                        Sqlite.execute
                            connection
                            tx
                            "UPDATE mod_nexus_links SET mapped_provider=$provider,mapped_category=$category WHERE mod_id=$id; INSERT OR IGNORE INTO mod_categories(mod_id,category_id,label) VALUES($id,$category,$label); UPDATE mods SET revision=revision+1 WHERE id=$id"
                            [ "$id", box (string current.Mod)
                              "$provider", box provider
                              "$category", box (string categoryId)
                              "$label", box category.Label ]

                        CategoryRows.advance connection tx current.Workspace
                        Ok()
                    | _ -> Error NexusProblem.CategoryUnavailable)
