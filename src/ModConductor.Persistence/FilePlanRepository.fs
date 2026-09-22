namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.FilePlanning
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

/// This adapter does not scan game folders or select winning sources.
type FilePlanRepository
    internal
    (
        database: StateDatabase,
        access: LibraryAccess,
        ?publication: LibraryPublication,
        ?beforeTextEffect: unit -> unit,
        ?afterTextEffect: unit -> unit,
        ?afterTextObservation: unit -> unit
    ) =
    let beforeTextEffect = defaultArg beforeTextEffect ignore
    let afterTextEffect = defaultArg afterTextEffect ignore
    let afterTextObservation = defaultArg afterTextObservation ignore

    let protect action =
        task {
            try
                return! action ()
            with
            | ModConductor.DeploymentRecovery.RecoveryException _ ->
                return Error FilePlanError.Blocked
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

        member _.GameProjection(expected, token) =
            protect (fun () ->
                transact false (fun c t ->
                    DeploymentProjection.read c t database.OwnerId expected token))

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

    interface IFileCandidateRepository with
        member _.CandidateProjection(expected, predicate, token) =
            protect (fun () ->
                transact false (fun c t ->
                    DeploymentProjection.candidates predicate c t database.OwnerId expected token))

        member _.OpenManaged(workspace, pin, token) =
            protect (fun () ->
                task {
                    token.ThrowIfCancellationRequested()
                    let! root = access.Root workspace

                    match root with
                    | Error error -> return Error(rootError error)
                    | Ok root ->
                        let! stored =
                            transact false (fun c t ->
                                match pin with
                                | SourcePin.Snapshot _ -> Error FilePlanError.InvalidCopy
                                | SourcePin.Mod(modId, versionId, entry) ->
                                    match
                                        FilePlanRows.savedCopy
                                            c
                                            t
                                            workspace
                                            { ModId = modId
                                              VersionId = versionId
                                              Path = entry.Path }
                                    with
                                    | Ok copy when copy.Entry = entry ->
                                        match
                                            LibraryRows.library c t workspace,
                                            LibraryRows.payload c t entry.Payload.Id
                                        with
                                        | Some library, Some payload when
                                            payload.Payload = entry.Payload
                                            ->
                                            Ok(library, payload)
                                        | _ ->
                                            Error(
                                                FilePlanError.FileUnavailable
                                                    "The published plugin payload is unavailable."
                                            )
                                    | _ -> Error FilePlanError.Stale)

                        match stored with
                        | Error error -> return Error error
                        | Ok(library, payload) ->
                            use folder = LibraryFiles.openLibrary root library

                            let stream, _ =
                                folder.Read(
                                    LibraryFiles.payloadName payload.Payload.Id,
                                    Some payload.Identity
                                )

                            if stream.Length <> payload.Payload.Length then
                                stream.Dispose()

                                return
                                    Error(
                                        FilePlanError.FileUnavailable
                                            "The published plugin file changed."
                                    )
                            else
                                return Ok stream
                })

        member _.PublishText(expected, action, source, bytes, token) =
            protect (fun () ->
                task {
                    token.ThrowIfCancellationRequested()

                    let owner =
                        publication
                        |> Option.defaultWith (fun () ->
                            raise (InvalidOperationException "Text publication is unavailable."))

                    let! prepared =
                        transact false (fun c t ->
                            if FilePlanRows.stamp c t expected.ProfileId <> Some expected then
                                Error FilePlanError.Stale
                            else
                                match
                                    LibraryRows.find c t source.Copy.ModId,
                                    PublicationRows.edit c t action TextDocuments.bytesLimit
                                with
                                | _, Error LibraryError.LimitExceeded ->
                                    Error(
                                        FilePlanError.LimitExceeded
                                            "The persisted edit is too large to continue."
                                    )
                                | _, Error _ -> Error FilePlanError.Stale
                                | Some row, Ok(Some persisted) when
                                    persisted.ModId = source.Copy.ModId
                                    && persisted.SourceVersion = source.Copy.VersionId
                                    && persisted.Path = source.SourcePath
                                    && persisted.PreviousPayload = source.PayloadId
                                    && persisted.ExpectedRevision = source.ModRevision
                                    && persisted.VersionId = action
                                    && persisted.Phase = PublicationPhase.Complete
                                    ->
                                    Ok(source.ModRevision, None)
                                | Some row, Ok(Some persisted) when
                                    persisted.ModId = source.Copy.ModId
                                    && persisted.SourceVersion = source.Copy.VersionId
                                    && persisted.Path = source.SourcePath
                                    && persisted.PreviousPayload = source.PayloadId
                                    && persisted.ExpectedRevision = source.ModRevision
                                    && persisted.VersionId = action
                                    && (persisted.Phase = PublicationPhase.Interrupted
                                        || persisted.Phase = PublicationPhase.Observed)
                                    && row.Entry.WorkspaceId = expected.WorkspaceId
                                    && row.Entry.Kind = ModKind.Regular
                                    && row.Entry.Revision = persisted.ExpectedRevision
                                    && row.Entry.CurrentVersion = Some persisted.SourceVersion
                                    ->
                                    Ok(
                                        persisted.ExpectedRevision,
                                        Some
                                            { ActionId = action
                                              SourceVersion = Some persisted.SourceVersion
                                              VersionLabel = row.Entry.Metadata.Version
                                              Policy =
                                                ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                              Files = []
                                              Bytes =
                                                [ { Target = persisted.Path
                                                    Content = Array.copy persisted.Content
                                                    Sha256 = persisted.Digest } ] }
                                    )
                                | Some _, Ok(Some _) -> Error FilePlanError.Stale
                                | Some row, Ok None when
                                    row.Entry.WorkspaceId = expected.WorkspaceId
                                    && row.Entry.Kind = ModKind.Regular
                                    && row.Entry.Revision = source.ModRevision
                                    && row.Entry.CurrentVersion = Some source.Copy.VersionId
                                    ->
                                    match
                                        FilePlanRows.savedCopy
                                            c
                                            t
                                            expected.WorkspaceId
                                            source.Copy
                                    with
                                    | Ok saved when
                                        saved.Current
                                        && saved.Entry.Path = source.SourcePath
                                        && saved.Entry.Payload.Id = source.PayloadId
                                        && saved.Entry.Payload.Length = source.Length
                                        && saved.Entry.Payload.Sha256 = source.Sha256
                                        ->
                                        Ok(
                                            source.ModRevision,
                                            Some
                                                { ActionId = action
                                                  SourceVersion = Some source.Copy.VersionId
                                                  VersionLabel = row.Entry.Metadata.Version
                                                  Policy =
                                                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                                  Files = []
                                                  Bytes =
                                                    [ { Target = source.SourcePath
                                                        Content = Array.copy bytes
                                                        Sha256 =
                                                          Convert.ToHexStringLower(
                                                              System.Security.Cryptography.SHA256.HashData
                                                                  bytes
                                                          ) } ] }
                                        )
                                    | _ -> Error FilePlanError.Stale
                                | _ -> Error FilePlanError.Stale)

                    match prepared with
                    | Error error -> return Error error
                    | Ok(_, None) -> return Ok action
                    | Ok(revision, Some input) ->
                        use cancellation =
                            token.Register(fun () ->
                                database
                                    .EnqueueInternal(fun () ->
                                        PublicationRows.cancel database.Connection action
                                        |> ignore)
                                    .GetAwaiter()
                                    .GetResult())

                        let! result =
                            access.Run(fun () ->
                                owner.Compose(
                                    source.Copy.ModId,
                                    revision,
                                    action,
                                    input,
                                    token,
                                    afterTextEffect,
                                    afterTextObservation,
                                    beforeTextEffect
                                ))

                        return
                            match result with
                            | Ok _ -> Ok action
                            | Error LibraryError.NotFound -> Error FilePlanError.NotFound
                            | Error LibraryError.Busy -> Error FilePlanError.Busy
                            | Error LibraryError.StaleRevision
                            | Error LibraryError.SourceChanged -> Error FilePlanError.Stale
                            | Error LibraryError.Cancelled -> Error FilePlanError.Cancelled
                            | Error LibraryError.LimitExceeded ->
                                Error(
                                    FilePlanError.LimitExceeded
                                        "The edited mod exceeds the publication limits."
                                )
                            | Error LibraryError.InvalidMetadata
                            | Error LibraryError.InvalidSource
                            | Error LibraryError.IdentityConflict
                            | Error LibraryError.UnsupportedAction ->
                                Error(FilePlanError.InvalidEdit "This mod file cannot be edited.")
                            | Error LibraryError.UnprovedOwnership
                            | Error LibraryError.FileUnavailable ->
                                Error(
                                    FilePlanError.FileUnavailable
                                        "The edited mod version could not be saved."
                                )
                })

        member _.AbandonText(action) =
            protect (fun () ->
                task {
                    let! result =
                        match publication with
                        | Some owner -> access.Run(fun () -> owner.Abandon(action))
                        | None -> Task.FromResult(Error LibraryError.UnsupportedAction)

                    return
                        match result with
                        | Ok id -> Ok id
                        | Error LibraryError.NotFound -> Error FilePlanError.NotFound
                        | Error LibraryError.Busy -> Error FilePlanError.Busy
                        | Error _ ->
                            Error(
                                FilePlanError.InvalidEdit
                                    "This interrupted edit cannot be abandoned."
                            )
                })
