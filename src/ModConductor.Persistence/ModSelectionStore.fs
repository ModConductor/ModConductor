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

        member _.Find(profile, modId, expected) =
            run profile false (fun connection transaction workspace revision ->
                if expected |> Option.exists ((<>) revision) then
                    Error LibraryError.StaleRevision
                else
                    match LibraryRows.find connection transaction modId with
                    | Some row when row.Entry.WorkspaceId = workspace ->
                        Ok
                            { Revision = revision
                              Entry =
                                { Mod = row.Entry
                                  Selection =
                                    SelectionRows.find connection transaction profile modId
                                    |> SelectionPolicy.state row.Entry.Kind } }
                    | Some _
                    | None -> Error LibraryError.NotFound)

        member _.Read(profile, after, expected) =
            run profile false (fun connection transaction workspace revision ->
                if expected |> Option.exists ((<>) revision) then
                    Error LibraryError.StaleRevision
                elif after.IsSome && expected.IsNone then
                    Error LibraryError.StaleRevision
                else
                    let ids =
                        LibraryRows.ids
                            connection
                            transaction
                            workspace
                            (after |> Option.map string |> Option.defaultValue "")
                            33

                    let entries =
                        ids
                        |> List.choose (fun id ->
                            LibraryRows.find connection transaction id |> Option.map _.Entry)
                        |> InventoryPolicy.inventoryWindow

                    let values =
                        entries
                        |> List.map (fun entry ->
                            { Mod = entry
                              Selection =
                                SelectionRows.find connection transaction profile entry.Id
                                |> SelectionPolicy.state entry.Kind })

                    Ok
                        { Revision = revision
                          Entries = values
                          NextMod =
                            if ids.Length > entries.Length then
                                entries |> List.tryLast |> Option.map _.Id
                            else
                                None
                          Total =
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM mods WHERE workspace_id=$workspace"
                                [ "$workspace", box (string workspace) ]
                            |> int
                          EnabledCount = SelectionRows.enabledCount connection transaction profile })
