namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary

type ModLibraryStore internal (database: StateDatabase, roots: OwnedWorkspaceRootStore) =
    let access = LibraryAccess(database, roots)
    let publication = LibraryPublication(database, access)

    // Receipt queries and cancellation remain available while both file-job slots are occupied.
    let receipt action =
        task {
            try
                return! database.Enqueue action
            with :? ModConductor.Operations.CapacityException ->
                return Error LibraryError.Busy
        }

    member internal _.PublicationOwner = publication
    member internal _.Access = access
    member _.Failed = access.Failed
    member _.Drain() = access.Drain()
    member internal _.TryClose(next) = access.TryClose next

    member internal _.PublishAtCheckpoint(id, expected, version, afterEffect, afterObservation) =
        access.Run(fun () ->
            publication.Publish(id, expected, version, afterEffect, afterObservation))

    member internal _.EditAtCheckpoint(id, expected, metadata, beforeCommit) =
        access.Run(fun () ->
            InventoryCommands.edit database access id expected metadata beforeCommit)

    interface IModLibrary with
        member _.Register(workspace, id, metadata, registration) =
            access.Run(fun () ->
                InventoryCommands.register database access workspace id metadata registration)

        member _.Edit(id, expected, metadata) =
            access.Run(fun () -> InventoryCommands.edit database access id expected metadata ignore)

        member _.Scan(workspace, limit) =
            access.Run(fun () -> InventoryScan.run database access workspace limit)

        member _.Publish(id, expected, version) =
            access.Run(fun () -> publication.Publish(id, expected, version, ignore, ignore))

        member _.Publication(version) =
            receipt (fun () ->
                PublicationRows.find database.Connection null version
                |> Option.map Ok
                |> Option.defaultValue (Error LibraryError.NotFound))

        member _.CancelPublication(version) =
            receipt (fun () -> PublicationRows.cancel database.Connection version)

        member _.Version(id, offset) =
            access.Run(fun () ->
                task {
                    if offset < 0 then
                        return Error LibraryError.LimitExceeded
                    else
                        return!
                            database.Enqueue(fun () ->
                                LibraryRows.version database.Connection null id offset 65
                                |> Option.map (fun version ->
                                    let entries = InventoryPolicy.manifestWindow version.Entries

                                    Ok
                                        { version with
                                            Entries = entries
                                            NextOffset =
                                                if version.Entries.Length > entries.Length then
                                                    Some(offset + entries.Length)
                                                else
                                                    None })
                                |> Option.defaultValue (Error LibraryError.NotFound))
                })

        member _.ReadPayload(version, payloadId, offset, count) =
            access.Run(fun () ->
                task {
                    if offset < 0L || count < 1 || count > 65536 then
                        return Error LibraryError.LimitExceeded
                    else
                        let! found =
                            database.Enqueue(fun () ->
                                use transaction =
                                    database.Connection.BeginTransaction(deferred = true)

                                let result =
                                    match
                                        PublicationRows.find
                                            database.Connection
                                            transaction
                                            version
                                    with
                                    | Some receipt when
                                        receipt.Phase = PublicationPhase.Complete
                                        && Sqlite.number
                                            database.Connection
                                            transaction
                                            "SELECT count(*) FROM mod_manifest WHERE version_id=$version AND payload_id=$payload"
                                            [ "$version", box (string version)
                                              "$payload", box (string payloadId) ]
                                           <> 0L
                                        ->
                                        LibraryRows.find
                                            database.Connection
                                            transaction
                                            receipt.ModId
                                        |> Option.bind (fun row ->
                                            match
                                                LibraryRows.library
                                                    database.Connection
                                                    transaction
                                                    row.Entry.WorkspaceId,
                                                LibraryRows.payload
                                                    database.Connection
                                                    transaction
                                                    payloadId
                                            with
                                            | Some library, Some payload ->
                                                Some(row.Entry.WorkspaceId, library, payload)
                                            | _ -> None)
                                    | Some _
                                    | None -> None

                                transaction.Commit()
                                result)

                        match found with
                        | None -> return Error LibraryError.NotFound
                        | Some(workspace, library, payload) ->
                            let! rootResult = access.Root workspace

                            match rootResult with
                            | Error error -> return Error error
                            | Ok root ->
                                return!
                                    Task.Run(fun () ->
                                        use directory = LibraryFiles.openLibrary root library
                                        LibraryFiles.verify directory payload

                                        let stream, _ =
                                            directory.Read(
                                                LibraryFiles.payloadName payloadId,
                                                Some payload.Identity
                                            )

                                        use stream = stream

                                        if offset > payload.Payload.Length then
                                            Error LibraryError.LimitExceeded
                                        else
                                            stream.Position <- offset

                                            let bytes =
                                                Array.zeroCreate<byte> (
                                                    int (
                                                        min
                                                            (int64 count)
                                                            (payload.Payload.Length - offset)
                                                    )
                                                )

                                            stream.ReadExactly bytes
                                            Ok bytes)
                })
