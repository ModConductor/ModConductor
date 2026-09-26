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

    let state = FilePlanSessionState(repository, cache)
    let queries = FilePlanQueryHandler(state)
    let visibility = FilePlanVisibilityHandler(state)
    let preview = FilePlanPreviewHandler(state)
    let text = FilePlanTextHandler(state)

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

        member _.AcquireFnisCandidate(profile, candidateRun, progress, token) =
            run token (fun token ->
                acquisition.AcquireFnisCandidate(profile, candidateRun, progress, token))

        member _.Read id =
            run CancellationToken.None (fun _ -> queries.Read id)

        member _.Children(id, parent, query, cursor) =
            run CancellationToken.None (fun _ -> queries.Children(id, parent, query, cursor))

        member _.Problems(id, cursor) =
            run CancellationToken.None (fun _ -> queries.Problems(id, cursor))

        member _.DiagnosticProblems id =
            run CancellationToken.None (fun _ -> queries.DiagnosticProblems id)

        member _.Inspect(id, target, cursor) =
            run CancellationToken.None (fun _ -> queries.Inspect(id, target, cursor))

        member _.InspectCopy(id, copy) =
            run CancellationToken.None (fun _ -> queries.InspectCopy(id, copy))

        member _.Change(id, copy, hidden, token) =
            run token (fun token -> visibility.Change(id, copy, hidden, token))

        member _.Preview(id, source, representation, token) =
            run token (fun token -> preview.Preview(id, source, representation, token))

        member _.OpenManagedText(id, source, token) =
            run token (fun token -> text.OpenManagedText(id, source, token))

        member _.SaveManagedText(id, action, source, content, token) =
            run token (fun token -> text.SaveManagedText(id, action, source, content, token))

        member _.AbandonManagedText(action) =
            run CancellationToken.None (fun _ -> text.AbandonManagedText action)

        member _.History(id, copy, after) =
            run CancellationToken.None (fun _ -> queries.History(id, copy, after))
