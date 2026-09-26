namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.Platform

/// Owns lifecycle admission and the workspace-root/library file boundary.
type internal LibraryAccess(database: StateDatabase, roots: OwnedWorkspaceRootStore) =
    let gate = obj ()

    let failed =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    let mutable active = 0
    let mutable closing = false

    let mutable idle =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do idle.SetResult()

    member _.Run(action: unit -> Task<Result<'T, LibraryError>>) =
        task {
            let accepted =
                lock gate (fun () ->
                    if closing then
                        false
                    else
                        if active = 0 then
                            idle <-
                                TaskCompletionSource<unit>(
                                    TaskCreationOptions.RunContinuationsAsynchronously
                                )

                        active <- active + 1
                        true)

            if not accepted then
                return Error LibraryError.FileUnavailable
            else
                try
                    try
                        return! action ()
                    with
                    | :? ModConductor.Operations.CapacityException ->
                        return Error LibraryError.FileUnavailable
                    | :? IOException
                    | :? UnauthorizedAccessException -> return Error LibraryError.FileUnavailable
                finally
                    lock gate (fun () ->
                        active <- active - 1

                        if active = 0 then
                            idle.SetResult())
        }

    member _.Root id =
        task {
            let! checkedRoot = roots.Validate id

            return
                match checkedRoot with
                | Ok receipt when receipt.Phase = RootCreationPhase.Complete -> Ok receipt.Workspace
                | Ok _ -> Error LibraryError.UnprovedOwnership
                | Error WorkspaceFailure.Busy -> Error LibraryError.UnprovedOwnership
                | Error WorkspaceFailure.NotFound -> Error LibraryError.NotFound
                | Error WorkspaceFailure.StaleRevision
                | Error WorkspaceFailure.IdentityConflict
                | Error WorkspaceFailure.InvalidRoot -> Error LibraryError.UnprovedOwnership
        }

    member _.PrepareLibrary(root: WorkspaceRoot, afterEffect: unit -> unit) =
        task {
            let! prepared =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)
                    let existing = LibraryRows.library database.Connection transaction root.Id

                    let value =
                        match existing with
                        | Some row -> row, false
                        | None ->
                            let row =
                                { Name = ".mod-conductor-library-" + Guid.NewGuid().ToString("N")
                                  Identity = None
                                  Phase = 1
                                  Owner = database.OwnerId }

                            Sqlite.execute
                                database.Connection
                                transaction
                                "INSERT INTO mod_libraries VALUES($workspace,$directory,$owner,1,NULL)"
                                [ "$workspace", box (string root.Id)
                                  "$directory", box row.Name
                                  "$owner", box database.OwnerId ]

                            row, true

                    transaction.Commit()
                    value)

            let row, fresh = prepared

            if row.Phase = 2 then
                return Ok row
            elif not fresh then
                return Error LibraryError.UnprovedOwnership
            else
                let! identity =
                    Task.Run(fun () ->
                        use directory = HeldDirectory.Open(root.Path, root.Identity)
                        use library = directory.CreateDirectory row.Name
                        afterEffect ()
                        library.Identity)

                do!
                    database.EnqueueInternal(fun () ->
                        Sqlite.execute
                            database.Connection
                            null
                            "UPDATE mod_libraries SET identity=$identity,phase=2 WHERE workspace_id=$workspace AND owner=$owner AND phase=1"
                            [ "$identity", box (LibraryEncoding.identity identity)
                              "$workspace", box (string root.Id)
                              "$owner", box database.OwnerId ])

                return
                    Ok
                        { row with
                            Identity = Some identity
                            Phase = 2 }
        }

    member _.Failed = failed.Task

    member _.Fail() =
        lock gate (fun () -> closing <- true)
        failed.TrySetResult() |> ignore

    member _.Drain() =
        lock gate (fun () ->
            closing <- true
            idle.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (next ()) then
                false
            else
                closing <- true
                true)

module internal LibraryFiles =
    let openLibrary (root: WorkspaceRoot) (row: StoredLibrary) =
        match row.Identity with
        | None -> raise (IOException("The library folder has no recorded identity."))
        | Some identity ->
            use directory = HeldDirectory.Open(root.Path, root.Identity)
            directory.Directory(row.Name, Some identity)

    let openSource (root: WorkspaceRoot) (modRow: StoredMod) forbidden =
        match modRow.Entry.SourcePath, modRow.SourceIdentity with
        | Some path, Some identity ->
            use directory = HeldDirectory.Open(root.Path, root.Identity)
            SourceFiles.child directory path (Some identity) forbidden
        | _ -> Error LibraryError.FileUnavailable

    let payloadName (id: Guid) = id.ToString("N") + ".payload"

    let verify (library: HeldDirectory) (payload: StoredPayload) =
        let stream, _ = library.Read(payloadName payload.Payload.Id, Some payload.Identity)
        use stream = stream

        if
            stream.Length <> payload.Payload.Length
            || SourceFiles.digest stream <> payload.Payload.Sha256
        then
            raise (IOException("The published file changed."))
