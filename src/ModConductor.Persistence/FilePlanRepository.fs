namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.FilePlanning
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

/// This adapter does not scan game folders or select winning sources.
type FilePlanRepository internal (database: StateDatabase, access: LibraryAccess) =
    let protect action =
        task {
            try
                return! action ()
            with
            | :? ModConductor.Operations.CapacityException -> return Error FilePlanError.Busy
            | :? OperationCanceledException -> return Error FilePlanError.Cancelled
            | :? IOException as e -> return Error(FilePlanError.FileUnavailable e.Message)
            | :? UnauthorizedAccessException ->
                return Error(FilePlanError.FileUnavailable "The stored files cannot be read.")
        }

    let transact write action =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = not write)
            let result = action database.Connection transaction
            transaction.Commit()
            result)

    let rootError =
        function
        | LibraryError.NotFound -> FilePlanError.NotFound
        | LibraryError.Busy -> FilePlanError.Busy
        | LibraryError.StaleRevision -> FilePlanError.Stale
        | LibraryError.IdentityConflict
        | LibraryError.InvalidMetadata
        | LibraryError.InvalidSource
        | LibraryError.UnprovedOwnership
        | LibraryError.SourceChanged
        | LibraryError.UnsupportedAction
        | LibraryError.LimitExceeded
        | LibraryError.FileUnavailable
        | LibraryError.Cancelled ->
            FilePlanError.FileUnavailable "The workspace root cannot be checked."

    interface IFilePlanRepository with
        member _.Read profile =
            protect (fun () ->
                task {
                    let! result =
                        transact false (fun c t -> FilePlanRows.read c t database.OwnerId profile)

                    match result with
                    | Error error -> return Error error
                    | Ok sources ->
                        let! root = access.Root sources.Stamp.WorkspaceId
                        return root |> Result.mapError rootError |> Result.map (fun _ -> sources)
                })

        member _.Copy(workspace, copy) =
            protect (fun () ->
                task {
                    let! root = access.Root workspace

                    match root with
                    | Error error -> return Error(rootError error)
                    | Ok _ ->
                        return!
                            transact false (fun c t -> FilePlanRows.savedCopy c t workspace copy)
                })

        member _.Current expected =
            protect (fun () ->
                task {
                    let! root = access.Root expected.WorkspaceId

                    match root with
                    | Error error -> return Error(rootError error)
                    | Ok _ ->
                        return!
                            transact false (fun c t ->
                                Ok(FilePlanRows.stamp c t expected.ProfileId = Some expected))
                })

        member _.VerifyPayloads(sources, remainingBytes, token) =
            protect (fun () ->
                task {
                    let payloads =
                        sources.Profile.Mods
                        |> List.filter _.Enabled
                        |> List.collect (fun row ->
                            row.Version |> Option.map _.Entries |> Option.defaultValue [])
                        |> List.map _.Payload
                        |> List.distinctBy _.Id

                    if payloads |> List.sumBy _.Length > remainingBytes then
                        return
                            Error(
                                FilePlanError.LimitExceeded
                                    "The published files exceed the 64 GiB content limit."
                            )
                    elif payloads.IsEmpty then
                        return Ok()
                    else
                        let! root = access.Root sources.Stamp.WorkspaceId

                        match root with
                        | Error error -> return Error(rootError error)
                        | Ok root ->
                            let! stored =
                                transact false (fun c t ->
                                    match LibraryRows.library c t sources.Stamp.WorkspaceId with
                                    | None ->
                                        Error(
                                            FilePlanError.FileUnavailable
                                                "The published library is unavailable."
                                        )
                                    | Some library ->
                                        let found =
                                            payloads
                                            |> List.map (fun payload ->
                                                LibraryRows.payload c t payload.Id)

                                        if found |> List.exists Option.isNone then
                                            Error(
                                                FilePlanError.FileUnavailable
                                                    "A published payload is unavailable."
                                            )
                                        else
                                            Ok(library, found |> List.choose id))

                            match stored with
                            | Error error -> return Error error
                            | Ok(library, stored) ->
                                return!
                                    Task.Run(
                                        (fun () ->
                                            use folder = LibraryFiles.openLibrary root library

                                            for payload in stored do
                                                token.ThrowIfCancellationRequested()

                                                let stream, _ =
                                                    folder.Read(
                                                        LibraryFiles.payloadName
                                                            payload.Payload.Id,
                                                        Some payload.Identity
                                                    )

                                                use stream = stream

                                                if
                                                    stream.Length <> payload.Payload.Length
                                                    || SourceFiles.digestChecked
                                                        token.ThrowIfCancellationRequested
                                                        stream
                                                       <> payload.Payload.Sha256
                                                then
                                                    raise (
                                                        IOException(
                                                            "A published payload changed."
                                                        )
                                                    )

                                            Ok()),
                                        token
                                    )
                })

        member _.SetHidden(expected, copy, isHidden, beforeFingerprint, afterFingerprint) =
            protect (fun () ->
                task {
                    let! root = access.Root expected.WorkspaceId

                    match root with
                    | Error error -> return Error(rootError error)
                    | Ok _ ->
                        return!
                            transact true (fun c t ->
                                FilePlanRows.setHidden
                                    c
                                    t
                                    expected
                                    copy
                                    isHidden
                                    beforeFingerprint
                                    afterFingerprint)
                })

        member _.History(workspace, copy, after) =
            protect (fun () ->
                task {
                    let! root = access.Root workspace

                    match root with
                    | Error error -> return Error(rootError error)
                    | Ok _ ->
                        return!
                            transact false (fun c t ->
                                Ok(FilePlanRows.history c t workspace copy after))
                })
