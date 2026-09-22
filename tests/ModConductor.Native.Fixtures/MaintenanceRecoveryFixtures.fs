namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.ModMaintenance
open ModConductor.Persistence
open ModConductor.Workspaces

module MaintenanceRecoveryFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (value: Artifact) : ArtifactRef =
        { Id = value.Id
          WorkspaceId = value.WorkspaceId
          Revision = value.Revision }

    let worker
        state
        (workspace: string)
        (modId: string)
        (artifact: string)
        (id: string)
        kind
        checkpoint
        =
        use store = new OperationStore(state)

        let workspace, modId, artifact, id =
            Guid.Parse workspace, Guid.Parse modId, Guid.Parse artifact, Guid.Parse id

        let current =
            ((store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun row -> row.Id = modId)

        let hook name =
            if name = checkpoint then
                StorageWorker.pause ()

        if kind = "update" then
            let archive = store.Artifacts.Read(workspace, artifact) |> wait |> result
            let draft = store.Installations.Prepare(reference archive, token) |> wait

            let preview =
                store.Installations.PrepareUpdate(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    modId,
                    current.Revision,
                    UpdateMode.Replace,
                    Set.empty,
                    "2"
                )
                |> wait

            store.Installations.StartUpdateAtCheckpoint(workspace, preview.Id, id, hook)
            |> ignore
        else
            let preview = store.Deletions.Prepare(workspace, modId, current.Revision) |> wait
            store.Deletions.StartAtCheckpoint(workspace, preview.Id, id, hook) |> ignore

        Thread.Sleep Timeout.Infinite

    let observe (writer: Utf8JsonWriter) area =
        Directory.CreateDirectory area |> ignore
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let mutable modId, firstVersion, archiveId = Guid.Empty, Guid.Empty, Guid.Empty

        let check (name: string) condition =
            writer.WriteBoolean(name, condition)

            if not condition then
                failwith ("Maintenance restart fixture failed: " + name)

        writer.WriteStartObject("maintenanceRestart")

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Restart fixture", StorageWorker.select root)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Everyday" }
            )
            |> wait
            |> result
            |> ignore

            MaintenanceFixtures.zip
                (Path.Combine(area, "Rivière textures.zip"))
                [ "Data/a.txt", "old"; "Data/keep.txt", "same" ]

            MaintenanceFixtures.zip
                (Path.Combine(area, "textures.zip"))
                [ "Data/a.txt", "new"; "Data/keep.txt", "same" ]

            let adopt file =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = Path.Combine(area, file)
                      Storage = ArtifactStorage.Copy },
                    token
                )
                |> wait
                |> result

            let first = adopt "Rivière textures.zip"
            let draft = store.Installations.Prepare(reference first, token) |> wait

            let started =
                store.Installations.Start(workspace, draft.Id, draft.Revision, Guid.NewGuid())

            let deadline = DateTime.UtcNow.AddSeconds 20
            let mutable current = store.Installations.Read(workspace, started.Id) |> wait

            while current.State = InstallationState.Running && DateTime.UtcNow < deadline do
                Thread.Sleep 10
                current <- store.Installations.Read(workspace, started.Id) |> wait

            if current.State <> InstallationState.Complete then
                failwith (string current.Problem)

            modId <- current.ModId.Value
            firstVersion <- current.VersionId.Value
            archiveId <- (adopt "textures.zip").Id
            store.Installations.Stop() |> wait

        let runChild target kind id checkpoint =
            new NativeChild(
                Environment.ProcessPath,
                [ "--maintenance-worker"
                  state
                  string workspace
                  string target
                  string archiveId
                  string id
                  kind
                  checkpoint ]
            )

        let published = Guid.NewGuid()
        let mutable admissionMod = Guid.Empty

        do
            use child = runChild modId "update" published "after-publication"

            if child.Line() <> "ready" then
                failwith "The publication checkpoint was not reached."

            child.Terminate()

        do
            use store = new OperationStore(state)
            let current = store.Installations.Read(workspace, published) |> wait
            let cancelled = store.Installations.Cancel(workspace, published) |> wait
            use connection = MaintenanceDeployments.database state
            let row = LibraryRows.find connection null modId |> Option.get
            let archive = store.Artifacts.Read(workspace, archiveId) |> wait |> result

            check
                "CommittedUpdateSurvivesProcessLossAndLateCancellation"
                (current.State = InstallationState.Complete
                 && cancelled.State = InstallationState.Complete
                 && row.Entry.CurrentVersion = current.VersionId
                 && row.Entry.CurrentVersion <> Some firstVersion
                 && archive.Links
                    |> List.exists (fun link ->
                        link.ModId = modId
                        && Some link.VersionId = current.VersionId
                        && link.Installed)
                 && (LibraryRows.version connection null firstVersion 0 100).IsSome)

            firstVersion <- current.VersionId.Value

        do
            use store = new OperationStore(state)
            let next = Path.Combine(area, "next-update.zip")
            MaintenanceFixtures.zip next [ "Data/a.txt", "later update"; "Data/keep.txt", "same" ]

            archiveId <-
                (store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = next
                      Storage = ArtifactStorage.Copy },
                    token
                 )
                 |> wait
                 |> result)
                    .Id

        let update = Guid.NewGuid()

        do
            use child = runChild modId "update" update "file-observed"

            if child.Line() <> "ready" then
                failwith "The update effect checkpoint was not reached."

            child.Terminate()

        do
            use store = new OperationStore(state)
            let current = store.Installations.Read(workspace, update) |> wait
            use connection = MaintenanceDeployments.database state
            let modRow = LibraryRows.find connection null modId |> Option.get

            check
                "UpdateProcessLossRetainsOldVersionAndObservedTemporaryFiles"
                (current.State = InstallationState.Stopped
                 && current.Files > 0
                 && modRow.Entry.CurrentVersion = Some firstVersion)

            let archive = store.Artifacts.Read(workspace, archiveId) |> wait |> result
            check "UnpublishedUpdateDoesNotClaimInstalledProvenance" (archive.Links.IsEmpty)

        let deletion = Guid.NewGuid()

        do
            use child = runChild modId "delete" deletion "after-deletion-effect"

            if child.Line() <> "ready" then
                failwith "The deletion effect checkpoint was not reached."

            child.Terminate()

        do
            use store = new OperationStore(state)
            let pending = store.Deletions.Recent workspace |> wait |> List.exactlyOne

            check
                "DeletionReturnsIncompleteWithoutAutomaticEffects"
                (pending.Id = deletion && pending.Phase = DeletionPhase.Incomplete)

            store.Deletions.Continue(workspace, deletion) |> ignore
            let deadline = DateTime.UtcNow.AddSeconds 20
            let mutable current = store.Deletions.Read(workspace, deletion) |> wait

            while current.Phase = DeletionPhase.Running && DateTime.UtcNow < deadline do
                Thread.Sleep 10
                current <- store.Deletions.Read(workspace, deletion) |> wait

            check
                "ContinueFinishesUnacknowledgedEffectAndRemovesReceipt"
                (current.Phase = DeletionPhase.Complete
                 && (store.Deletions.Recent workspace |> wait).IsEmpty)

            use connection = MaintenanceDeployments.database state

            check
                "DeletionIncludesInterruptedUpdateTemporaryData"
                (Sqlite.number
                    connection
                    null
                    "SELECT count(*) FROM archive_installations WHERE mod_id=$mod"
                    [ "$mod", box (string modId) ] = 0L
                 && Directory.GetFiles(root, "*", SearchOption.AllDirectories)
                    |> Array.forall (fun file ->
                        not (
                            file.EndsWith(".payload")
                            || file.EndsWith(".archive")
                            || file.EndsWith(".partial")
                        )))

            let source = Directory.CreateDirectory(Path.Combine(root, "registered-source"))
            File.WriteAllText(Path.Combine(source.FullName, "file.txt"), "registered")
            admissionMod <- Guid.NewGuid()

            let registered =
                (store.ModLibrary :> IModLibrary)
                    .Register(
                        workspace,
                        admissionMod,
                        { Name = "Admission fixture"
                          Notes = ""
                          Comment = ""
                          Version = ""
                          Source = ""
                          Categories = [] },
                        Registration.Directory(
                            ModKind.Regular,
                            ModConductor.Platform.LogicalPath.create [ source.Name ] |> result
                        )
                    )
                |> wait
                |> result

            (store.ModLibrary :> IModLibrary)
                .Publish(registered.Id, registered.Revision, Guid.NewGuid())
            |> wait
            |> result
            |> ignore

            store.Deletions.Stop() |> wait

        let admissionDeletion = Guid.NewGuid()

        do
            use child =
                runChild admissionMod "delete" admissionDeletion "before-deletion-effect"

            if child.Line() <> "ready" then
                failwith "The admission deletion checkpoint was not reached."

            child.Terminate()

        do
            use store = new OperationStore(state)
            let library = store.ModLibrary :> IModLibrary

            let expected =
                (library.Scan(workspace, 100) |> wait |> result).Entries
                |> List.find (fun entry -> entry.Id = admissionMod)
                |> _.Revision

            let pending = store.Deletions.Recent workspace |> wait |> List.exactlyOne

            let metadata =
                library.Edit(
                    admissionMod,
                    expected,
                    { Name = "Admission fixture"
                      Notes = "not applied"
                      Comment = ""
                      Version = ""
                      Source = ""
                      Categories = [] }
                )
                |> wait

            check
                "RecoveredDeletionMetadataEditUsesOperationSpecificResult"
                (metadata = Error LibraryError.UnsupportedAction)

            let publication =
                library.Publish(admissionMod, expected, Guid.NewGuid()) |> wait

            check "RecoveredDeletionAdmitsPublication" (Result.isOk publication)

            let stillPending = store.Deletions.Recent workspace |> wait |> List.exactlyOne

            check
                "RecoveredDeletionRemainsAvailableAfterPublication"
                (pending.Id = admissionDeletion
                 && pending.Phase = DeletionPhase.Incomplete
                 && stillPending.Id = admissionDeletion
                 && stillPending.Phase = DeletionPhase.Incomplete)

            store.Deletions.Continue(workspace, admissionDeletion) |> ignore
            let deadline = DateTime.UtcNow.AddSeconds 20
            let mutable current = store.Deletions.Read(workspace, admissionDeletion) |> wait

            while current.Phase = DeletionPhase.Running && DateTime.UtcNow < deadline do
                Thread.Sleep 10
                current <- store.Deletions.Read(workspace, admissionDeletion) |> wait

            check
                "RecoveredDeletionContinuesAfterPublication"
                (current.Phase = DeletionPhase.Complete
                 && (store.Deletions.Recent workspace |> wait).IsEmpty)

            store.Deletions.Stop() |> wait

        writer.WriteEndObject()
