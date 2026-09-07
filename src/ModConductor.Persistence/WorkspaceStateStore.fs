namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.Workspaces
open ModConductor.Platform

/// Feature adapter over the existing SQLite queue and owned-root receipts.
type WorkspaceStateStore internal (database: StateDatabase, roots: OwnedWorkspaceRootStore) =
    let gate = obj ()
    let mutable active = 0
    let mutable closing = false

    let mutable idle =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do idle.SetResult()

    let run action =
        let accepted =
            lock gate (fun () ->
                if closing || active >= 2 then
                    false
                else
                    if active = 0 then
                        idle <-
                            TaskCompletionSource<unit>(
                                TaskCreationOptions.RunContinuationsAsynchronously
                            )

                    active <- active + 1
                    true)

        task {
            if not accepted then
                return Error WorkspaceError.Busy
            else
                try
                    return! action ()
                finally
                    lock gate (fun () ->
                        active <- active - 1

                        if active = 0 then
                            idle.SetResult())
        }

    let failure =
        function
        | WorkspaceFailure.NotFound -> WorkspaceError.NotFound
        | WorkspaceFailure.StaleRevision -> WorkspaceError.StaleRevision
        | WorkspaceFailure.IdentityConflict -> WorkspaceError.IdentityConflict
        | WorkspaceFailure.Busy -> WorkspaceError.Busy
        | WorkspaceFailure.InvalidRoot ->
            WorkspaceError.InvalidRoot "The workspace folder or its identity file is unavailable."

    let page id after =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = true)

            let result =
                WorkspaceRows.find database.Connection transaction id
                |> Option.bind (fun row ->
                    WorkspaceProfiles.page database.Connection transaction row.Receipt after)
                |> Option.map Ok
                |> Option.defaultValue (Error WorkspaceError.NotFound)

            transaction.Commit()
            result)

    let read id after =
        task {
            let! valid = roots.Validate id

            match valid with
            | Error error -> return Error(failure error)
            | Ok _ -> return! page id after
        }

    let create id requestedName root beforeEffect afterEffect afterObservation =
        run (fun () ->
            task {
                match ProfilePolicy.name requestedName with
                | Error error -> return Error error
                | Ok name when id = Guid.Empty -> return Error WorkspaceError.IdentityConflict
                | Ok name ->
                    let! prepared =
                        database.Enqueue(fun () ->
                            use transaction =
                                database.Connection.BeginTransaction(deferred = false)

                            let result =
                                match
                                    WorkspaceRows.prepareIn
                                        database.Connection
                                        transaction
                                        database.OwnerId
                                        id
                                        0L
                                        root
                                with
                                | Error error -> Error(failure error)
                                | Ok receipt ->
                                    match
                                        WorkspaceProfiles.summary
                                            database.Connection
                                            transaction
                                            receipt
                                    with
                                    | Some existing when existing.Name <> name ->
                                        Error WorkspaceError.IdentityConflict
                                    | Some _ -> Ok receipt
                                    | None ->
                                        Sqlite.execute
                                            database.Connection
                                            transaction
                                            "INSERT INTO workspaces(id,name,revision,selected_profile) VALUES($id,$name,0,NULL)"
                                            [ "$id", box (string id); "$name", box name ]

                                        Ok receipt

                            match result with
                            | Ok _ -> transaction.Commit()
                            | Error _ -> ()

                            result)

                    match prepared with
                    | Error error -> return Error error
                    | Ok receipt when receipt.Phase = RootCreationPhase.Complete ->
                        return! read id None
                    | Ok receipt when receipt.Phase <> RootCreationPhase.Intent ->
                        return! page id None
                    | Ok receipt ->
                        beforeEffect ()
                        let! applied = roots.ApplyAtCheckpoint(id, receipt.Revision, afterEffect)

                        match applied with
                        | Error error -> return Error(failure error)
                        | Ok observed when observed.Phase = RootCreationPhase.Observed ->
                            afterObservation ()
                            let! completed = roots.Complete(id, observed.Revision)

                            match completed with
                            | Error error -> return Error(failure error)
                            | Ok _ -> return! page id None
                        | Ok _ -> return! page id None
            })

    let edit id expected command beforeCommit =
        run (fun () ->
            task {
                let! valid = roots.Validate id

                match valid with
                | Error error -> return Error(failure error)
                | Ok _ ->
                    return!
                        database.Enqueue(fun () ->
                            WorkspaceProfiles.edit
                                database.Connection
                                id
                                expected
                                command
                                beforeCommit)
            })

    member internal _.CreateAtCheckpoint
        (id, name, root, beforeEffect, afterEffect, afterObservation)
        =
        create id name root beforeEffect afterEffect afterObservation

    member internal _.EditAtCheckpoint(id, expected, command, beforeCommit) =
        edit id expected command beforeCommit

    member _.Drain() =
        lock gate (fun () ->
            closing <- true
            idle.Task)

    member internal _.TryClose(closeRoots: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (closeRoots ()) then
                false
            else
                closing <- true
                true)

    interface IWorkspaceState with
        member _.Create(id, name, root) =
            create id name root ignore ignore ignore

        member _.Open(root) =
            run (fun () ->
                task {
                    let! found =
                        database.Enqueue(fun () ->
                            WorkspaceRows.findSelected database.Connection null root)

                    match found with
                    | None ->
                        return
                            Error(
                                WorkspaceError.InvalidRoot
                                    "This folder is not registered with this installation of Mod Conductor."
                            )
                    | Some row -> return! read row.Receipt.Workspace.Id None
                })

        member _.Read(id, after) = run (fun () -> read id after)
        member _.Edit(id, expected, command) = edit id expected command ignore

        member _.Check(id, expected) =
            run (fun () ->
                task {
                    let! valid = roots.Validate id

                    match valid with
                    | Error error -> return Error(failure error)
                    | Ok receipt when receipt.Phase = RootCreationPhase.Complete ->
                        return! page id None
                    | Ok _ ->
                        let! result = roots.Reconcile(id, expected)

                        match result with
                        | Error error -> return Error(failure error)
                        | Ok _ -> return! page id None
                })

        member _.Recent(after) =
            database.Enqueue(fun () ->
                use transaction = database.Connection.BeginTransaction(deferred = true)

                use statement =
                    Sqlite.command
                        database.Connection
                        transaction
                        "SELECT id FROM workspaces WHERE id>$after ORDER BY id LIMIT 9"
                        [ "$after", box (after |> Option.map string |> Option.defaultValue "") ]

                use reader = statement.ExecuteReader()

                let ids =
                    [ while reader.Read() do
                          yield Guid.Parse(reader.GetString 0) ]

                reader.Close()
                let visible = List.truncate 8 ids

                let workspaces =
                    visible
                    |> List.choose (fun id ->
                        WorkspaceRows.find database.Connection transaction id
                        |> Option.bind (fun row ->
                            WorkspaceProfiles.summary database.Connection transaction row.Receipt))

                transaction.Commit()

                { Workspaces = workspaces
                  NextWorkspace = if ids.Length > 8 then Some(List.last visible) else None })
