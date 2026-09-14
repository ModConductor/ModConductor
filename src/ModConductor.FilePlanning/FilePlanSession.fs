namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

/// Owns the bounded background work and disposable snapshots used by the real file view.
type FilePlanSession(repository: IFileCandidateRepository) =
    let cache = SnapshotCache()
    let acquisition = SnapshotAcquisition(repository, cache)
    let gate = obj ()
    let stop = new CancellationTokenSource()
    let mutable closing = false
    let mutable active = 0

    let mutable idle =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    do idle.SetResult()

    let run token action =
        task {
            let entered =
                lock gate (fun () ->
                    if closing || active >= 2 then
                        false
                    else
                        if active = 0 then
                            idle <-
                                TaskCompletionSource(
                                    TaskCreationOptions.RunContinuationsAsynchronously
                                )

                        active <- active + 1
                        true)

            if not entered then
                return Error FilePlanError.Busy
            else
                use linked = CancellationTokenSource.CreateLinkedTokenSource(token, stop.Token)

                try
                    try
                        return! action linked.Token
                    with
                    | :? OperationCanceledException -> return Error FilePlanError.Cancelled
                    | :? IOException as e -> return Error(FilePlanError.FileUnavailable e.Message)
                    | :? UnauthorizedAccessException ->
                        return
                            Error(
                                FilePlanError.FileUnavailable
                                    "The file view cannot read its inputs."
                            )
                finally
                    lock gate (fun () ->
                        active <- active - 1

                        if active = 0 then
                            idle.TrySetResult() |> ignore)
        }

    let checkedSnapshot id =
        task {
            match cache.Find id with
            | None -> return Error FilePlanError.Expired
            | Some snapshot ->
                let! current = repository.Current snapshot.Sources.Stamp
                return current |> Result.map (fun current -> snapshot, not current)
        }

    let describe stale snapshot =
        PlanSnapshot.summary (stale || cache.Stale snapshot) snapshot

    let openManagedText (snapshot: PlanSnapshot) (managed: ManagedPreviewSource) token =
        task {
            if managed.Length < 0L || managed.Length > int64 TextDocuments.bytesLimit then
                return Error(FilePlanError.LimitExceeded "This text file is too large to edit.")
            else
                let target = managed.Target

                match InspectionProjection.inspect target None snapshot with
                | Error error -> return Error error
                | Ok(copies, _) ->
                    match
                        copies
                        |> List.tryFind (fun row ->
                            row.Source = FilePreviewSource.ManagedCopy managed)
                    with
                    | None -> return Error FilePlanError.Stale
                    | Some _ ->
                        let! saved =
                            repository.Copy(snapshot.Sources.Stamp.WorkspaceId, managed.Copy)

                        match saved with
                        | Error error -> return Error error
                        | Ok saved when
                            not saved.Current
                            || saved.Entry.Path <> managed.SourcePath
                            || saved.Entry.Payload.Id <> managed.PayloadId
                            || saved.Entry.Payload.Length <> managed.Length
                            || saved.Entry.Payload.Sha256 <> managed.Sha256
                            ->
                            return Error FilePlanError.Stale
                        | Ok saved ->
                            let pin =
                                SourcePin.Mod(
                                    managed.Copy.ModId,
                                    managed.Copy.VersionId,
                                    saved.Entry
                                )

                            let! opened =
                                repository.OpenManaged(
                                    snapshot.Sources.Stamp.WorkspaceId,
                                    pin,
                                    token
                                )

                            match opened with
                            | Error error -> return Error error
                            | Ok stream ->
                                use stream = stream
                                let bytes = Array.zeroCreate<byte> (int managed.Length)
                                stream.ReadExactly bytes
                                token.ThrowIfCancellationRequested()
                                let digest = Convert.ToHexStringLower(SHA256.HashData bytes)

                                if stream.Length <> managed.Length || digest <> managed.Sha256 then
                                    return Error FilePlanError.Stale
                                else
                                    return
                                        TextDocuments.editable bytes
                                        |> Result.mapError FilePlanError.Unsupported
        }

    let keep fresh snapshot =
        cache.Put(snapshot, fresh)
        describe false snapshot

    member internal _.Observation id = cache.Find id |> Option.bind _.Game

    member _.Drain() =
        lock gate (fun () ->
            closing <- true
            stop.Cancel()
            idle.Task)

    member _.TryClose() =
        lock gate (fun () ->
            if active <> 0 then
                false
            else
                closing <- true
                true)

    interface IFilePlans with
        member _.Open(profile, token) =
            run token (fun token -> acquisition.Open(profile, token))

        member _.Acquire(profile, refresh, progress, token) =
            run token (fun token -> acquisition.Acquire(profile, refresh, progress, token))

        member _.Read id =
            run CancellationToken.None (fun _ ->
                task {
                    let! found = checkedSnapshot id
                    return found |> Result.map (fun (snapshot, stale) -> describe stale snapshot)
                })

        member _.Children(id, parent, query, cursor) =
            run CancellationToken.None (fun _ ->
                task {
                    let! found = checkedSnapshot id

                    return
                        found
                        |> Result.bind (fun (snapshot, stale) ->
                            if stale then
                                Error FilePlanError.Stale
                            else
                                PlanSnapshot.children parent query cursor snapshot
                                |> Result.map (fun (nodes, next) ->
                                    { Snapshot = describe false snapshot
                                      Nodes = nodes
                                      Next = next }))
                })

        member _.Problems(id, cursor) =
            run CancellationToken.None (fun _ ->
                task {
                    match cache.Find id with
                    | None -> return Error FilePlanError.Expired
                    | Some snapshot -> return PlanSnapshot.problems cursor snapshot
                })

        member _.Inspect(id, target, cursor) =
            run CancellationToken.None (fun _ ->
                task {
                    let! found = checkedSnapshot id

                    return
                        found
                        |> Result.bind (fun (snapshot, stale) ->
                            InspectionProjection.inspect target cursor snapshot
                            |> Result.map (fun (copies, next) ->
                                { Snapshot = describe stale snapshot
                                  Writable = snapshot.Index.Writable.Contains target
                                  Target = target
                                  Next = next
                                  FocusedCopy = None
                                  Copies =
                                    copies
                                    |> List.map (fun copy ->
                                        { copy with
                                            CanHide =
                                                copy.CanHide
                                                && not stale
                                                && not (cache.Stale snapshot)
                                            CanUnhide = copy.CanUnhide && not stale }) }))
                })

        member _.InspectCopy(id, copy) =
            run CancellationToken.None (fun _ ->
                task {
                    let! found = checkedSnapshot id

                    match found with
                    | Error error -> return Error error
                    | Ok(snapshot, stale) ->
                        let! saved = repository.Copy(snapshot.Sources.Stamp.WorkspaceId, copy)

                        return
                            saved
                            |> Result.bind (fun saved ->
                                match saved.Current, snapshot.Index.CopyTargets.TryFind copy with
                                | true, Some target ->
                                    InspectionProjection.inspect target None snapshot
                                    |> Result.map (fun (copies, next) ->
                                        { Snapshot = describe stale snapshot
                                          Writable = snapshot.Index.Writable.Contains target
                                          Target = target
                                          Next = next
                                          FocusedCopy =
                                            let row =
                                                InspectionProjection.inspectCopy
                                                    target
                                                    copy
                                                    snapshot

                                            Some
                                                { row with
                                                    CanHide =
                                                        row.CanHide
                                                        && not stale
                                                        && not (cache.Stale snapshot)
                                                    CanUnhide = row.CanUnhide && not stale }
                                          Copies =
                                            copies
                                            |> List.map (fun row ->
                                                { row with
                                                    CanHide =
                                                        row.CanHide
                                                        && not stale
                                                        && not (cache.Stale snapshot)
                                                    CanUnhide = row.CanUnhide && not stale }) })
                                | _ ->
                                    Ok
                                        { Snapshot = describe stale snapshot
                                          Writable = false
                                          Target = copy.Path
                                          Next = None
                                          FocusedCopy = None
                                          Copies =
                                            [ { Source =
                                                  FilePreviewSource.ManagedCopy
                                                      { Copy = copy
                                                        SourcePath = copy.Path
                                                        Target = copy.Path
                                                        PayloadId = saved.Entry.Payload.Id
                                                        Length = saved.Entry.Payload.Length
                                                        Sha256 = saved.Entry.Payload.Sha256
                                                        ModRevision =
                                                          snapshot.Index.Labels
                                                          |> Map.tryFind copy.ModId
                                                          |> Option.map _.Revision
                                                          |> Option.defaultValue 0L }
                                                Standing =
                                                  if saved.Current then
                                                      FileSourceStanding.Unavailable
                                                  else
                                                      FileSourceStanding.Previous
                                                Copy = Some copy
                                                SourcePath = copy.Path
                                                Name = saved.Name
                                                VersionLabel = saved.VersionLabel
                                                Priority = None
                                                Enabled = false
                                                Hidden = saved.Hidden
                                                Winner = false
                                                Historical = not saved.Current
                                                Length = saved.Entry.Payload.Length
                                                Sha256 = saved.Entry.Payload.Sha256
                                                CanHide = false
                                                CanUnhide = false } ] })
                            |> Result.bind InspectionProjection.bounded
                })

        member _.Change(id, copy, hidden, token) =
            run token (fun token ->
                task {
                    let! found = checkedSnapshot id

                    match found with
                    | Error error -> return Error error
                    | Ok(_, true) -> return Error FilePlanError.Stale
                    | Ok(snapshot, false) ->
                        match snapshot.Index.CopyTargets.TryFind copy with
                        | None -> return Error FilePlanError.InvalidCopy
                        | Some target ->
                            let nameProblems =
                                TargetPolicy.problems
                                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                    copy.Path

                            let denied =
                                hidden
                                && (cache.Stale snapshot
                                    || snapshot.Problems.Length <> 0
                                    || not nameProblems.IsEmpty)

                            if denied then
                                return Error FilePlanError.Blocked
                            else
                                let! gameCurrent =
                                    if not hidden then
                                        Task.FromResult(Ok true)
                                    else
                                        match snapshot.Game with
                                        | None -> Task.FromResult(Error FilePlanError.Blocked)
                                        | Some game ->
                                            Task.Run(
                                                (fun () -> GameFiles.current game token),
                                                token
                                            )

                                match gameCurrent with
                                | Error FilePlanError.Cancelled ->
                                    return Error FilePlanError.Cancelled
                                | Error error ->
                                    cache.MarkStale snapshot
                                    return Error error
                                | Ok false ->
                                    cache.MarkStale snapshot
                                    return Error FilePlanError.Stale
                                | Ok true ->
                                    match Visibility.setHidden copy hidden snapshot.Visibility with
                                    | Error _ -> return Error FilePlanError.InvalidCopy
                                    | Ok visibility ->
                                        token.ThrowIfCancellationRequested()

                                        let! changed =
                                            repository.SetHidden(
                                                snapshot.Sources.Stamp,
                                                copy,
                                                hidden,
                                                Visibility.fingerprint snapshot.Visibility,
                                                Visibility.fingerprint visibility
                                            )

                                        return
                                            changed
                                            |> Result.map (fun stamp ->
                                                let address =
                                                    { Root = stamp.WorkspaceId
                                                      Path = target }

                                                let present state =
                                                    Visibility.files state
                                                    |> Map.tryFind address
                                                    |> Option.flatten
                                                    |> Option.isSome

                                                let delta =
                                                    (if present visibility then 1 else 0)
                                                    - (if present snapshot.Visibility then
                                                           1
                                                       else
                                                           0)

                                                let updated =
                                                    { snapshot with
                                                        Id = Guid.NewGuid()
                                                        Sources =
                                                            { snapshot.Sources with
                                                                Stamp = stamp
                                                                Hidden =
                                                                    Visibility.hidden visibility }
                                                        Visibility = visibility
                                                        Planned = snapshot.Planned + delta }

                                                let summary = keep false updated

                                                { Snapshot = summary
                                                  Changed =
                                                    if snapshot.Index.Targets.Contains target then
                                                        Some(
                                                            FileIndex.node
                                                                updated.Sources
                                                                visibility
                                                                updated.Index
                                                                target
                                                        )
                                                    else
                                                        None })
                })

        member _.Preview(id, source, representation, token) =
            run token (fun token ->
                task {
                    let! found = checkedSnapshot id

                    match found with
                    | Error error -> return Error error
                    | Ok(_, true) -> return Error FilePlanError.Stale
                    | Ok(snapshot, false) ->
                        let target = FilePreviewRendering.target source

                        let rows =
                            match InspectionProjection.inspect target None snapshot with
                            | Error error -> Error error
                            | Ok(copies, _) -> Ok copies

                        match rows with
                        | Error error -> return Error error
                        | Ok copies ->
                            match copies |> List.tryFind (fun row -> row.Source = source) with
                            | None -> return Error FilePlanError.Stale
                            | Some row ->
                                match source with
                                | FilePreviewSource.ManagedCopy managed ->
                                    let! saved =
                                        repository.Copy(
                                            snapshot.Sources.Stamp.WorkspaceId,
                                            managed.Copy
                                        )

                                    match saved with
                                    | Error error -> return Error error
                                    | Ok saved when
                                        not saved.Current
                                        || saved.Entry.Path <> managed.SourcePath
                                        || saved.Entry.Payload.Id <> managed.PayloadId
                                        || saved.Entry.Payload.Length <> managed.Length
                                        || saved.Entry.Payload.Sha256 <> managed.Sha256
                                        ->
                                        return Error FilePlanError.Stale
                                    | Ok saved ->
                                        let pin =
                                            SourcePin.Mod(
                                                managed.Copy.ModId,
                                                managed.Copy.VersionId,
                                                saved.Entry
                                            )

                                        let! opened =
                                            repository.OpenManaged(
                                                snapshot.Sources.Stamp.WorkspaceId,
                                                pin,
                                                token
                                            )

                                        match opened with
                                        | Error error -> return Error error
                                        | Ok stream ->
                                            use stream = stream

                                            return
                                                Ok(
                                                    FilePreviewRendering.render
                                                        source
                                                        row.Standing
                                                        representation
                                                        stream
                                                        token
                                                )
                                | FilePreviewSource.CheckedGameFile game ->
                                    match snapshot.Game with
                                    | None -> return Error FilePlanError.Stale
                                    | Some observation ->
                                        return
                                            GameFiles.readChecked
                                                observation
                                                game
                                                token
                                                (fun stream ->
                                                    FilePreviewRendering.render
                                                        source
                                                        row.Standing
                                                        representation
                                                        stream
                                                        token)
                                | FilePreviewSource.QualifiedArchiveEntry _ ->
                                    return Error FilePlanError.InvalidCopy
                })

        member _.OpenManagedText(id, source, token) =
            run token (fun token ->
                task {
                    let! found = checkedSnapshot id

                    match found with
                    | Error error -> return Error error
                    | Ok(_, true) -> return Error FilePlanError.Stale
                    | Ok(snapshot, false) ->
                        let! document = openManagedText snapshot source token

                        return
                            document
                            |> Result.map (fun value -> { Source = source; Document = value })
                })

        member _.SaveManagedText(id, action, source, content, token) =
            run token (fun token ->
                task {
                    if action = Guid.Empty then
                        return Error FilePlanError.InvalidCopy
                    else
                        let! found = checkedSnapshot id

                        match found with
                        | Error error -> return Error error
                        | Ok(_, true) -> return Error FilePlanError.Stale
                        | Ok(snapshot, false) ->
                            let! original = openManagedText snapshot source token

                            match original with
                            | Error error -> return Error error
                            | Ok original ->
                                match TextDocuments.encode original content with
                                | Error detail -> return Error(FilePlanError.InvalidEdit detail)
                                | Ok bytes ->
                                    let digest = Convert.ToHexStringLower(SHA256.HashData bytes)

                                    if
                                        int64 bytes.Length = source.Length
                                        && digest = source.Sha256
                                    then
                                        return
                                            Error(
                                                FilePlanError.InvalidEdit
                                                    "The draft has no changes to save."
                                            )
                                    else
                                        let! published =
                                            repository.PublishText(
                                                snapshot.Sources.Stamp,
                                                action,
                                                source,
                                                bytes,
                                                token
                                            )

                                        return
                                            published
                                            |> Result.map (fun version ->
                                                cache.MarkStale snapshot

                                                { Id = action
                                                  VersionId = version
                                                  Source = source })
                })

        member _.History(id, copy, after) =
            run CancellationToken.None (fun _ ->
                task {
                    match cache.Find id with
                    | None -> return Error FilePlanError.Expired
                    | Some snapshot ->
                        let! changes =
                            repository.History(snapshot.Sources.Stamp.WorkspaceId, copy, after)

                        return changes |> Result.bind PlanSnapshot.historyPage
                })
