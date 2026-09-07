namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary
open ModConductor.ModSelection

type ModSelectionStore internal (database: StateDatabase, access: LibraryAccess) =
    let run profile write action =
        access.Run(fun () ->
            task {
                let! original =
                    database.Enqueue(fun () ->
                        SelectionRows.profile database.Connection null profile)

                match original with
                | None -> return Error LibraryError.NotFound
                | Some(workspace, _) ->
                    let! root = access.Root workspace

                    match root with
                    | Error error -> return Error error
                    | Ok _ ->
                        return!
                            database.Enqueue(fun () ->
                                use transaction =
                                    database.Connection.BeginTransaction(deferred = not write)

                                let result =
                                    match
                                        SelectionRows.profile
                                            database.Connection
                                            transaction
                                            profile
                                    with
                                    | Some(currentWorkspace, revision) when
                                        currentWorkspace = workspace
                                        ->
                                        action database.Connection transaction workspace revision
                                    | Some _
                                    | None -> Error LibraryError.NotFound

                                transaction.Commit()
                                result)
            })

    let change profile expected (ids: Guid list) edit beforeCommit =
        run profile true (fun connection transaction workspace revision ->
            if ids.IsEmpty || ids.Length > 512 then
                Error LibraryError.LimitExceeded
            elif revision <> expected then
                Error LibraryError.StaleRevision
            elif
                ids
                |> List.exists (fun id ->
                    LibraryRows.find connection transaction id
                    |> Option.forall (fun row -> row.Entry.WorkspaceId <> workspace))
            then
                Error LibraryError.NotFound
            else
                let current = SelectionRows.all connection transaction profile

                match SelectionPolicy.change ids edit current with
                | Error error -> Error error
                | Ok changed ->
                    SelectionRows.apply connection transaction profile changed
                    beforeCommit ()

                    Ok
                        { Revision = revision + 1L
                          Changed = changed
                          EnabledCount = SelectionRows.enabledCount connection transaction profile })

    member internal _.ChangeAtCheckpoint(profile, expected, ids, edit, beforeCommit) =
        change profile expected ids edit beforeCommit

    interface IModSelection with
        member _.Change(profile, expected, ids, edit) = change profile expected ids edit ignore
