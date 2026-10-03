namespace ModConductor.Persistence

open ModConductor.ModLibrary
open ModConductor.ModOrganization

type ModOrganizationStore internal (database: StateDatabase, access: LibraryAccess) =
    let run workspace write action =
        access.Run(fun () ->
            task {
                let! root = access.Root workspace

                match root with
                | Error error -> return Error error
                | Ok _ ->
                    return!
                        database.Enqueue(fun () ->
                            use transaction =
                                database.Connection.BeginTransaction(deferred = not write)

                            let result = action database.Connection transaction
                            transaction.Commit()
                            result)
            })

    let layout profile write action =
        task {
            let! found =
                database.Enqueue(fun () -> SelectionRows.profile database.Connection null profile)

            match found with
            | None -> return Error LibraryError.NotFound
            | Some(workspace, _) -> return! run workspace write action
        }

    interface IModOrganization with
        member _.LoadOrderLayout profile =
            layout profile false (fun connection transaction ->
                use command =
                    Sqlite.command
                        connection
                        transaction
                        "SELECT entry_id FROM profile_load_layout WHERE profile_id=$profile ORDER BY position"
                        [ "$profile", box (string profile) ]

                use reader = command.ExecuteReader()

                Ok
                    [ while reader.Read() do
                          yield reader.GetString 0 ])

        member _.SaveLoadOrderLayout(profile, entries) =
            layout profile true (fun connection transaction ->
                if
                    entries.Length > 32768
                    || entries
                       |> List.exists (fun value ->
                           System.String.IsNullOrWhiteSpace value || value.Length > 512)
                    || (Set.ofList entries).Count <> entries.Length
                then
                    Error LibraryError.InvalidMetadata
                else
                    Sqlite.execute
                        connection
                        transaction
                        "DELETE FROM profile_load_layout WHERE profile_id=$profile"
                        [ "$profile", box (string profile) ]

                    for position, entry in entries |> List.indexed do
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO profile_load_layout(profile_id,position,entry_id) VALUES($profile,$position,$entry)"
                            [ "$profile", box (string profile)
                              "$position", box position
                              "$entry", box entry ]

                    Ok())

        member _.Change(profile, expected, ids, edit) =
            task {
                let! found =
                    database.Enqueue(fun () ->
                        SelectionRows.profile database.Connection null profile)

                match found with
                | None -> return Error LibraryError.NotFound
                | Some(workspace, _) ->
                    return!
                        run workspace true (fun connection transaction ->
                            OrganizationCommands.change
                                connection
                                transaction
                                profile
                                expected
                                ids
                                edit)
            }

        member _.Categories(workspace, parent, after, expected) =
            run workspace false (fun connection transaction ->
                CategoryRows.page connection transaction workspace parent after expected)

        member _.EditCategory(workspace, expected, edit) =
            run workspace true (fun connection transaction ->
                CategoryCommands.edit connection transaction workspace expected edit)

        member _.Query(profile, query, cursor, inspected) =
            task {
                try
                    match OrganizationPolicy.normalize query with
                    | Error error -> return Error error
                    | Ok query ->
                        let! found =
                            database.Enqueue(fun () ->
                                SelectionRows.profile database.Connection null profile)

                        match found with
                        | None -> return Error LibraryError.NotFound
                        | Some(workspace, _) ->
                            return!
                                run workspace false (fun connection transaction ->
                                    match SelectionRows.profile connection transaction profile with
                                    | Some(current, revision) when current = workspace ->
                                        OrganizationQuery.read
                                            connection
                                            transaction
                                            workspace
                                            profile
                                            revision
                                            query
                                            cursor
                                            inspected
                                    | Some _
                                    | None -> Error LibraryError.NotFound)
                with :? ModConductor.Operations.CapacityException ->
                    return Error LibraryError.FileUnavailable
            }
