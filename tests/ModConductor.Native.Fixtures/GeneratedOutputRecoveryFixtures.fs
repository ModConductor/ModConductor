namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Workspaces

module GeneratedOutputRecoveryFixtures =
    let private wait = StorageWorker.wait

    let private result =
        function
        | Ok value -> value
        | Error error -> invalidOp ("Output recovery request failed: " + string error)

    let private token = CancellationToken.None
    let private path = DeploymentFixtureData.path

    type private Checkpoint =
        | BeforeEffect
        | BeforeResult

    type private Owner(directory) =
        let database = new StateDatabase(directory)
        let roots = OwnedWorkspaceRootStore(database)
        let library = ModLibraryStore(database, roots)
        let contexts = GameContextStore(database, roots)

        let repository =
            OutputRepository(database, library.Access, library.PublicationOwner)

        member _.Repository = repository :> IOutputRepository
        member _.Library = library :> IModLibrary
        member _.Contexts = contexts :> IGameContexts

        member _.VersionCount modId =
            database.Enqueue(fun () ->
                Sqlite.number
                    database.Connection
                    null
                    "SELECT count(*) FROM mod_versions WHERE mod_id=$mod"
                    [ "$mod", box (string modId) ])
            |> wait

        interface IDisposable with
            member _.Dispose() =
                if not (contexts.TryClose() && library.TryClose(roots.TryClose)) then
                    invalidOp "The output recovery fixture still owns an operation."

                (database :> IDisposable).Dispose()

    let private interrupt (inner: IOutputRepository) checkpoint =
        { new IOutputRepository with
            member _.Read(workspace, context) = inner.Read(workspace, context)
            member _.Add(id, scope, name, purpose) = inner.Add(id, scope, name, purpose)
            member _.Workspace id = inner.Workspace id
            member _.StopUsing(id, revision) = inner.StopUsing(id, revision)
            member _.Current scope = inner.Current scope
            member _.Previous scope = inner.Previous scope
            member _.Observed(scope, files) = inner.Observed(scope, files)
            member _.ActiveDeployment scope = inner.ActiveDeployment scope

            member _.CheckAction record =
                task {
                    do! inner.CheckAction record
                    let! recorded = inner.FindAction record.Id

                    if checkpoint = BeforeEffect && recorded.IsSome then
                        raise (IOException "Owned fixture stopped before the file effect.")
                }

            member _.Preview record = inner.Preview record
            member _.Claim record = inner.Claim record
            member _.FindAction id = inner.FindAction id
            member _.Resume id = inner.Resume id
            member _.Publish(record, cancelled) = inner.Publish(record, cancelled)

            member _.SaveEntry(id, file, disposition) =
                if checkpoint = BeforeResult then
                    raise (IOException "Owned fixture stopped before the file result was saved.")

                inner.SaveEntry(id, file, disposition)

            member _.Release id = inner.Release id }

    let observe (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "output-recovery")).FullName

        let directory = Path.Combine(area, "state")

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()

        let check (name: string) passed =
            writer.WriteBoolean(name, passed)

            if not passed then
                invalidOp ("Output recovery fixture failed: " + name)

        let slot, tool =
            use store = new OperationStore(directory)
            let ws = store.Workspaces :> IWorkspaceState

            let created =
                ws.Create(workspace, "Recovery", StorageWorker.select workspacePath)
                |> wait
                |> result

            ws.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Everyday" }
            )
            |> wait
            |> result
            |> ignore

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    0L,
                    { Path = game
                      Proton = if OperatingSystem.IsLinux() then Some proton else None }
                )
            |> wait
            |> result
            |> ignore

            let outputs = store.GeneratedOutputs

            let scope () =
                outputs.Read(workspace, None) |> wait |> result

            let slot =
                outputs.Add(
                    Guid.NewGuid(),
                    scope (),
                    "Working settings",
                    OutputPurpose.WritableFile(path "settings.txt")
                )
                |> wait
                |> result

            let tool =
                outputs.Add(Guid.NewGuid(), scope (), "Tool files", OutputPurpose.ToolFolder)
                |> wait
                |> result

            slot, tool

        let initialize (owner: Owner) =
            let state = owner.Contexts.Read workspace |> wait |> result
            owner.Contexts.Refresh(workspace, state.Revision) |> wait |> result |> ignore

        let session (owner: Owner) checkpoint =
            let repository =
                match checkpoint with
                | Some value -> interrupt owner.Repository value
                | None -> owner.Repository

            GeneratedOutputSession(repository)

        let applyInterrupted owner checkpoint location name action =
            let session = session owner (Some checkpoint)

            try
                let outputs = session :> IGeneratedOutputs
                let scope = outputs.Read(workspace, None) |> wait |> result
                let observed = outputs.Observe(scope, ignore, token) |> wait |> result
                let id = Guid.NewGuid()

                let outcome =
                    outputs.Apply(
                        id,
                        observed.Id,
                        [ { LocationId = location
                            Path = path name } ],
                        action,
                        token
                    )
                    |> wait

                match outcome with
                | Error(OutputError.Unavailable _) -> ()
                | _ -> invalidOp "The selected output checkpoint did not interrupt."

                let pending = outputs.Action id |> wait |> result

                if pending.Complete then
                    invalidOp "The output checkpoint persisted a final result."

                pending
            finally
                if not (session.TryClose(fun () -> true)) then
                    invalidOp "The fixture session is busy."

        let resume owner id =
            let session = session owner None

            try
                (session :> IGeneratedOutputs).Resume(id, token) |> wait
            finally
                if not (session.TryClose(fun () -> true)) then
                    invalidOp "The resumed session is busy."

        File.WriteAllText(slot.PhysicalPath, "Keep these working settings")

        let stoppedAction =
            use owner = new Owner(directory)
            initialize owner
            applyInterrupted owner BeforeEffect slot.Id "settings.txt" OutputAction.Discard

        do
            use owner = new Owner(directory)
            initialize owner
            owner.Repository.StopUsing(slot.Id, slot.Revision) |> wait |> ignore

            check
                "stoppedOutputRefusesOldDiscardAfterRestart"
                (resume owner stoppedAction.Id = Error OutputError.Stale
                 && File.ReadAllText(slot.PhysicalPath) = "Keep these working settings")

        let movedPath = Path.Combine(tool.PhysicalPath, "moved.txt")
        File.WriteAllText(movedPath, "One immutable result")
        let modId = Guid.NewGuid()

        let move =
            use owner = new Owner(directory)
            initialize owner

            let action =
                applyInterrupted
                    owner
                    BeforeResult
                    tool.Id
                    "moved.txt"
                    (OutputAction.MoveToMod(OutputDestination.NewMod(modId, "Result", "1")))

            check
                "removedOutputRetainsPendingPublicationBeforeResultSave"
                (not (File.Exists movedPath) && action.Published && action.VersionId.IsSome)

            action

        do
            use owner = new Owner(directory)
            initialize owner
            let completed = resume owner move.Id |> result
            let saved = owner.Library.Version(move.VersionId.Value, 0) |> wait |> result

            check
                "restartCompletesAbsentMoveWithoutAnotherPublication"
                (completed.Complete
                 && completed.Published
                 && completed.VersionId = move.VersionId
                 && completed.Entries.Head.Disposition = OutputDisposition.Moved
                 && not (File.Exists movedPath)
                 && owner.VersionCount modId = 1L
                 && saved.Origin = VersionOrigin.Outputs move.Id)

            let current, _ = owner.Repository.Read(workspace, None) |> wait

            owner.Repository.Add(Guid.NewGuid(), current, "Another tool", OutputPurpose.ToolFolder)
            |> wait
            |> ignore

            check
                "completedOutputReplayRemainsHistoricalAfterConfigurationChange"
                (resume owner move.Id = Ok completed)

        let discardedPath = Path.Combine(tool.PhysicalPath, "discarded.txt")
        File.WriteAllText(discardedPath, "Discard these bytes")

        let discarded =
            use owner = new Owner(directory)
            initialize owner
            applyInterrupted owner BeforeResult tool.Id "discarded.txt" OutputAction.Discard

        do
            use owner = new Owner(directory)
            initialize owner
            let completed = resume owner discarded.Id |> result

            check
                "restartCompletesAbsentDiscardTruthfully"
                (completed.Complete
                 && completed.Entries.Head.Disposition = OutputDisposition.Discarded
                 && not (File.Exists discardedPath))

        let replacedPath = Path.Combine(tool.PhysicalPath, "replaced.txt")
        File.WriteAllText(replacedPath, "Original reviewed output")

        let replaced =
            use owner = new Owner(directory)
            initialize owner
            applyInterrupted owner BeforeResult tool.Id "replaced.txt" OutputAction.Discard

        File.WriteAllText(replacedPath, "New output after the interrupted removal")

        do
            use owner = new Owner(directory)
            initialize owner
            let completed = resume owner replaced.Id |> result

            check
                "restartLeavesPresentReplacementUntouched"
                (completed.Complete
                 && completed.Entries.Head.Disposition = OutputDisposition.Changed
                 && File.ReadAllText(replacedPath) = "New output after the interrupted removal")

        GenerationCleanup.normalize area
