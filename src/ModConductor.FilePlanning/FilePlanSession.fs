namespace ModConductor.FilePlanning

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

/// Owns the bounded background work and disposable snapshots used by the real file view.
type FilePlanSession(repository: IFilePlanRepository) =
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

    let keep fresh snapshot =
        cache.Put(snapshot, fresh)
        describe false snapshot

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
                                          Target = copy.Path
                                          Next = None
                                          FocusedCopy = None
                                          Copies =
                                            [ { Copy = Some copy
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
