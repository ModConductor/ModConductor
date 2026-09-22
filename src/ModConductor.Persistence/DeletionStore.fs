namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open System.Collections.Generic
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation

// The receipt exists only while owned deletion effects remain unfinished.
type DeletionStore internal (database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let gate = obj ()
    let completionGate = obj ()
    let previews = Dictionary<Guid, DeletionPlan>()
    let workers = Dictionary<Guid, CancellationTokenSource * Task>()
    let completed = Dictionary<Guid, DeletionStatus>()
    let mutable closing = false
    let wait (value: Task<'a>) = value.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse message = raise (InstallationException message)

    let snapshot transaction workspace id =
        match DeletionRows.find connection transaction workspace id with
        | Some status -> status
        | None ->
            lock completionGate (fun () ->
                match completed.TryGetValue id with
                | true, status when status.WorkspaceId = workspace -> status
                | _ -> refuse "This deletion is no longer pending.")

    let execute workspace id (token: CancellationToken) checkpoint =
        task {
            try
                let effects = db (fun () -> DeletionRows.effects connection null id)

                for effect in effects do
                    token.ThrowIfCancellationRequested()
                    checkpoint "before-deletion-effect"
                    DeletionFiles.remove effect
                    checkpoint "after-deletion-effect"

                    do!
                        database.EnqueueInternal(fun () ->
                            Sqlite.execute
                                connection
                                null
                                "DELETE FROM mod_deletion_effects WHERE deletion_id=$id AND sequence=$sequence"
                                [ "$id", box (string id); "$sequence", box effect.Sequence ])

                token.ThrowIfCancellationRequested()
                checkpoint "before-deletion-completion"

                db (fun () ->
                    let status = DeletionCompletion.finish connection database.OwnerId workspace id

                    lock completionGate (fun () ->
                        if completed.Count >= 16 then
                            completed.Remove(completed.Keys |> Seq.head) |> ignore

                        completed[id] <- status))

                checkpoint "after-deletion-completion"
            with error ->
                let message =
                    match error with
                    | :? OperationCanceledException ->
                        "Deletion stopped. Continue to delete the remaining owned files."
                    | _ -> error.Message

                do!
                    database.EnqueueInternal(fun () ->
                        Sqlite.execute
                            connection
                            null
                            "UPDATE mod_deletions SET busy=0,problem=$problem WHERE id=$id AND owner=$owner"
                            [ "$id", box (string id)
                              "$owner", box database.OwnerId
                              "$problem", box message ])
        }

    let launch workspace id checkpoint =
        let cancellation = new CancellationTokenSource()

        let work =
            Task.Run(fun () -> execute workspace id cancellation.Token checkpoint :> Task)

        workers[id] <- cancellation, work

    let admission id =
        if closing then
            refuse "The app is closing."

        for key in workers.Keys |> Seq.toArray do
            let cancellation, work = workers[key]

            if work.IsCompleted then
                cancellation.Dispose()
                workers.Remove key |> ignore

    member _.Prepare(workspace, modId, revision) =
        task {
            let! result =
                access.Run(fun () ->
                    task {
                        let! plan = DeletionPlanning.read database access workspace modId revision
                        return Ok plan
                    })

            let plan =
                result
                |> Result.defaultWith (fun _ -> refuse "The mod library is busy or unavailable.")

            return
                lock gate (fun () ->
                    if closing then
                        refuse "The app is closing."

                    if previews.Count >= 16 && not (previews.ContainsKey workspace) then
                        refuse "Close a mod deletion preview before opening another."

                    previews[workspace] <- plan
                    plan.View)
        }

    member _.ClosePreview(workspace, id) =
        lock gate (fun () ->
            match previews.TryGetValue workspace with
            | true, plan when plan.View.Id = id -> previews.Remove workspace |> ignore
            | _ -> ())

    member internal _.StartAtCheckpoint(workspace, previewId, id, checkpoint) =
        lock gate (fun () ->
            admission id

            let plan =
                match previews.TryGetValue workspace with
                | true, plan when plan.View.Id = previewId -> plan
                | _ -> refuse "The deletion preview changed. Review it again."

            let status, fresh =
                db (fun () ->
                    let previous =
                        lock completionGate (fun () ->
                            match completed.TryGetValue id with
                            | true, status when
                                status.WorkspaceId = workspace && status.ModId = plan.View.ModId
                                ->
                                Some status
                            | _ -> None)

                    match previous with
                    | Some status -> status, false
                    | None -> DeletionRows.beginDelete connection database.OwnerId id plan)

            if fresh then
                launch workspace id checkpoint

            status)

    member this.Start(workspace, previewId, id) =
        this.StartAtCheckpoint(workspace, previewId, id, ignore)

    member internal _.ContinueAtCheckpoint(workspace, id, checkpoint) =
        lock gate (fun () ->
            admission id

            let status, fresh =
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    let status = snapshot transaction workspace id

                    let fresh = status.Phase = DeletionPhase.Incomplete

                    if fresh then
                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE mod_deletions SET owner=$owner,busy=1,problem=NULL WHERE id=$id"
                            [ "$id", box (string id); "$owner", box database.OwnerId ]

                    transaction.Commit()

                    (if fresh then
                         { status with
                             Phase = DeletionPhase.Running
                             Problem = None }
                     else
                         status),
                    fresh)

            if fresh then
                launch workspace id checkpoint

            status)

    member this.Continue(workspace, id) =
        this.ContinueAtCheckpoint(workspace, id, ignore)

    member _.Read(workspace, id) =
        database.Enqueue(fun () -> snapshot null workspace id)

    member _.Recent workspace =
        database.Enqueue(fun () ->
            DeletionQueries.ids
                connection
                null
                "SELECT id FROM mod_deletions WHERE workspace_id=$workspace ORDER BY rowid DESC LIMIT 16"
                [ "$workspace", box (string workspace) ]
            |> List.map (snapshot null workspace))

    member _.Stop() =
        task {
            let pending =
                lock gate (fun () ->
                    closing <- true
                    previews.Clear()

                    for cancel, _ in workers.Values do
                        cancel.Cancel()

                    workers.Values |> Seq.map snd |> Seq.toArray)

            do! Task.WhenAll pending
        }

    member _.TryClose() =
        lock gate (fun () ->
            if workers.Values |> Seq.exists (snd >> fun work -> not work.IsCompleted) then
                false
            else
                closing <- true

                for cancel, _ in workers.Values do
                    cancel.Dispose()

                workers.Clear()
                previews.Clear()
                lock completionGate completed.Clear
                true)
