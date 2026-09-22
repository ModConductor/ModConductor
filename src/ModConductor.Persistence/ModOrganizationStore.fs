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

    interface IModOrganization with
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
