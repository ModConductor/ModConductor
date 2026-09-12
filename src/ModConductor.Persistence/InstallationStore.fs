namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open System.Collections.Generic
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.ModMaintenance

type InstallationStore
    internal
    (
        database: StateDatabase,
        access: LibraryAccess,
        artifacts: IArtifactLibrary,
        inspection: Inspection
    ) =
    let connection = database.Connection
    let gate = obj ()
    let drafts = Dictionary<Guid, InstallationDraft>()
    let preparing = HashSet<Guid>()
    let updates = Dictionary<Guid, UpdatePreview>()
    let workers = Dictionary<Guid, CancellationTokenSource * Task>()
    let mutable closing = false
    let wait (value: Task<'a>) = value.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse message = raise (InstallationException message)

    let draftReference (workspace, id, revision) =
        if closing then
            refuse "The app is closing."

        match drafts.TryGetValue workspace with
        | true, draft when draft.Id = id && draft.Revision = revision -> draft
        | _ -> refuse "The installation preview changed. Open it again."

    let choices =
        FomodDrafts(
            database,
            inspection,
            gate,
            draftReference,
            fun draft ->
                drafts[draft.Artifact.WorkspaceId] <- draft
                updates.Remove draft.Artifact.WorkspaceId |> ignore
        )

    let snapshot workspace id =
        InstallationRows.find connection null workspace id
        |> Option.defaultWith (fun () -> refuse "This installation is no longer available.")

    let artifactResult value =
        value
        |> Result.defaultWith (fun error ->
            match error with
            | ArtifactError.Cancelled -> raise (OperationCanceledException())
            | ArtifactError.Busy ->
                refuse "The archive is busy. Try again when its current operation stops."
            | ArtifactError.Stale -> refuse "The archive changed. Read its contents again."
            | ArtifactError.NotFound
            | ArtifactError.Conflict
            | ArtifactError.InvalidLink
            | ArtifactError.Linked
            | ArtifactError.Unavailable ->
                refuse
                    "The archive is unavailable. Check its location and read its contents again.")

    let payloads = InstallationPayloads(database, access)

    let extract id (plan: InstallationPlan) token checkpoint =
        inspection.WithContents(
            plan.Artifact,
            token,
            fun contents ->
                Layout.confirm plan contents.Manifest
                payloads.Write(id, plan, contents, token, checkpoint)
                token.ThrowIfCancellationRequested()
                checkpoint "before-publication"
                db (fun () -> InstallationRows.publish connection database.OwnerId id plan)
                checkpoint "after-publication"
        )

    let execute id plan token checkpoint =
        task {
            try
                let! result = extract id plan token checkpoint
                artifactResult result
            with error ->
                let message =
                    match error with
                    | :? OperationCanceledException ->
                        if plan.Target.IsSome then
                            "Update cancelled. The previous version stays active."
                        else
                            "Installation cancelled. No mod was added."
                    | :? InstallationException -> error.Message
                    | _ ->
                        ArchiveFailure.message error
                        |> Option.defaultValue (
                            if plan.Target.IsSome then
                                "Update failed. The previous version stays active."
                            else
                                "Installation failed. No mod was added."
                        )

                do!
                    database.EnqueueInternal(fun () ->
                        InstallationRows.stopped connection database.OwnerId id message)
        }

    member _.Prepare(reference: ArtifactRef, token) =
        task {
            lock gate (fun () ->
                if closing || preparing.Contains reference.WorkspaceId || preparing.Count >= 2 then
                    refuse "Archive preparation is busy. Try again shortly."

                if drafts.Count >= 16 && not (drafts.ContainsKey reference.WorkspaceId) then
                    refuse "Close an archive installation preview before opening another."

                preparing.Add reference.WorkspaceId |> ignore)

            try
                let! artifact = artifacts.Read(reference.WorkspaceId, reference.Id)
                let artifact = artifactResult artifact

                let! prepared =
                    inspection.WithContents(
                        reference,
                        token,
                        fun contents ->
                            Layout.prepare reference artifact.OriginalName contents.Manifest,
                            ModConductor.Fomod.ArchiveInput.read contents
                    )

                let draft, input = artifactResult prepared

                let available =
                    match input with
                    | ModConductor.Fomod.InstallerInput.Absent -> false
                    | _ -> true

                let draft =
                    { draft with
                        ChoiceInstaller = available
                        Plan = if available then None else draft.Plan }

                return
                    lock gate (fun () ->
                        if closing then
                            raise (OperationCanceledException())

                        drafts[reference.WorkspaceId] <- draft
                        choices.Prepared(draft, input)
                        draft)
            finally
                lock gate (fun () -> preparing.Remove reference.WorkspaceId |> ignore)
        }

    member _.Fomod = choices

    member _.Change(workspace, id, revision, change) =
        lock gate (fun () ->
            if choices.Active workspace then
                refuse "Return to the manual layout before changing these files."

            match drafts.TryGetValue workspace with
            | true, draft when draft.Id = id && draft.Revision = revision ->
                let next = Layout.change draft change
                updates.Remove workspace |> ignore
                drafts[workspace] <- next
                next
            | _ -> refuse "The installation preview changed. Open it again.")

    member _.CloseDraft(workspace, id) =
        lock gate (fun () ->
            match drafts.TryGetValue workspace with
            | true, draft when draft.Id = id ->
                drafts.Remove workspace |> ignore
                updates.Remove workspace |> ignore
                choices.Close workspace
            | _ -> ())

    member private _.StartPlan(id, plan, checkpoint) =
        lock gate (fun () ->
            if closing then
                refuse "The app is closing."

            for key in workers.Keys |> Seq.toArray do
                let cancellation, work = workers[key]

                if work.IsCompleted then
                    cancellation.Dispose()
                    workers.Remove key |> ignore

            if workers.Count >= 2 && not (workers.ContainsKey id) then
                refuse "Two installations are already active. Wait for one to finish."

            let snapshot, fresh =
                db (fun () ->
                    InstallationRows.reserve
                        connection
                        database.OwnerId
                        id
                        plan
                        (fun transaction ->
                            choices.Check connection transaction plan.Artifact.WorkspaceId))

            if fresh then
                let cancellation = new CancellationTokenSource()

                let work =
                    Task.Run(fun () -> execute id plan cancellation.Token checkpoint :> Task)

                workers[id] <- cancellation, work

            snapshot)

    member internal this.StartAtCheckpoint(workspace, draftId, revision, id, checkpoint) =
        lock gate (fun () ->
            let draft =
                match drafts.TryGetValue workspace with
                | true, draft when draft.Id = draftId && draft.Revision = revision -> draft
                | _ -> refuse "The installation preview changed. Open it again."

            let plan =
                draft.Plan
                |> Option.defaultWith (fun () ->
                    refuse "Choose files and review their destinations before installation.")

            this.StartPlan(id, plan, checkpoint))

    member _.PrepareUpdate(workspace, draftId, revision, modId, expected, mode, keep, version) =
        task {
            let draft =
                lock gate (fun () ->
                    match drafts.TryGetValue workspace with
                    | true, draft when draft.Id = draftId && draft.Revision = revision -> draft
                    | _ -> refuse "The archive layout changed. Review it again.")

            let cached =
                lock gate (fun () ->
                    match updates.TryGetValue workspace with
                    | true, preview when
                        preview.DraftId = draft.Id
                        && preview.DraftRevision = draft.Revision
                        && preview.Target.Id = modId
                        && preview.Target.Revision = expected
                        ->
                        Some preview
                    | _ -> None)

            let! result =
                match cached with
                | Some previous ->
                    Task.FromResult(
                        Ok(
                            Updates.prepare
                                draft
                                previous.Target
                                previous.Previous
                                mode
                                keep
                                version
                                previous.SourceNotices
                        )
                    )
                | None ->
                    access.Run(fun () ->
                        task {
                            let! target, saved, notices =
                                UpdateInspection.read database access modId expected

                            return Ok(Updates.prepare draft target saved mode keep version notices)
                        })

            let preview =
                result
                |> Result.defaultWith (fun _ -> refuse "The mod library is busy or unavailable.")

            return
                lock gate (fun () ->
                    match drafts.TryGetValue workspace with
                    | true, current when current.Id = draft.Id && current.Revision = draft.Revision ->
                        updates[workspace] <- preview
                        preview
                    | _ -> refuse "The archive layout changed. Review it again.")
        }

    member internal this.StartUpdateAtCheckpoint(workspace, previewId, id, checkpoint) =
        lock gate (fun () ->
            match updates.TryGetValue workspace with
            | true, preview when preview.Id = previewId ->
                this.StartPlan(id, preview.Plan, checkpoint)
            | _ -> refuse "The update preview changed. Review it again.")

    member this.StartUpdate(workspace, previewId, id) =
        this.StartUpdateAtCheckpoint(workspace, previewId, id, ignore)

    member this.Start(workspace, draftId, revision, id) =
        this.StartAtCheckpoint(workspace, draftId, revision, id, ignore)

    member _.Read(workspace, id) =
        database.Enqueue(fun () -> snapshot workspace id)

    member _.Recent(workspace) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    connection
                    null
                    "SELECT id FROM archive_installations WHERE workspace_id=$workspace AND state<>3 ORDER BY rowid DESC LIMIT 16"
                    [ "$workspace", box (string workspace) ]

            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()
            ids |> List.map (snapshot workspace))

    member _.Cancel(workspace, id) =
        task {
            do!
                database.Enqueue(fun () ->
                    snapshot workspace id |> ignore

                    Sqlite.execute
                        connection
                        null
                        "UPDATE archive_installations SET cancelled=1 WHERE workspace_id=$workspace AND id=$id AND state=0"
                        [ "$workspace", box (string workspace); "$id", box (string id) ])

            lock gate (fun () ->
                match workers.TryGetValue id with
                | true, (cancel, _) -> cancel.Cancel()
                | _ -> ())

            return! database.Enqueue(fun () -> snapshot workspace id)
        }

    member _.Discard(workspace, id) =
        task {
            let! result =
                access.Run(fun () ->
                    task {
                        do!
                            database.Enqueue(fun () ->
                                let current = snapshot workspace id

                                if current.State <> InstallationState.Stopped then
                                    refuse
                                        "Wait for the installation to stop before deleting temporary files."

                                Sqlite.execute
                                    connection
                                    null
                                    "UPDATE archive_installations SET busy=1,owner=$owner WHERE id=$id AND busy=0"
                                    [ "$id", box (string id); "$owner", box database.OwnerId ]

                                if Sqlite.number connection null "SELECT changes()" [] <> 1L then
                                    refuse "The temporary files are busy.")

                        try
                            do! Task.Run(fun () -> payloads.Delete(workspace, id))

                            do!
                                database.EnqueueInternal(fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "UPDATE archive_installations SET state=3,busy=0 WHERE id=$id; DELETE FROM installation_reuse WHERE installation_id=$id"
                                        [ "$id", box (string id) ])

                            return Ok()
                        finally
                            db (fun () ->
                                Sqlite.execute
                                    connection
                                    null
                                    "UPDATE archive_installations SET busy=0 WHERE id=$id AND owner=$owner"
                                    [ "$id", box (string id); "$owner", box database.OwnerId ])
                    })

            match result with
            | Ok() -> return! database.Enqueue(fun () -> snapshot workspace id)
            | Error _ ->
                return
                    refuse
                        "The temporary files cannot be deleted. Check the workspace folder and try again."
        }

    member _.Stop() =
        task {
            let pending =
                lock gate (fun () ->
                    closing <- true
                    drafts.Clear()
                    updates.Clear()

                    for cancel, _ in workers.Values do
                        cancel.Cancel()

                    workers.Values |> Seq.map snd |> Seq.toArray)

            do! Task.WhenAll pending
        }

    member _.TryClose() =
        lock gate (fun () ->
            if
                preparing.Count <> 0
                || workers.Values |> Seq.exists (snd >> fun work -> not work.IsCompleted)
            then
                false
            else
                closing <- true

                for cancel, _ in workers.Values do
                    cancel.Dispose()

                workers.Clear()
                drafts.Clear()
                updates.Clear()
                true)
