namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform
open ModConductor.ModMaintenance
open ModConductor.Persistence
open ModConductor.Workspaces

module MaintenanceFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (value: Artifact) : ArtifactRef =
        { WorkspaceId = value.WorkspaceId
          Id = value.Id
          Revision = value.Revision }

    let private stopped (store: OperationStore) workspace id =
        let deadline = DateTime.UtcNow.AddSeconds 20
        let mutable status = store.Installations.Read(workspace, id) |> wait |> result

        while status.State = InstallationState.Running && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            status <- store.Installations.Read(workspace, id) |> wait |> result

        if status.State <> InstallationState.Complete then
            failwith (string status.Problem)

        status

    let zip path entries =
        use file = File.Create path
        use archive = new ZipArchive(file, ZipArchiveMode.Create)

        for name, text in entries do
            use output = archive.CreateEntry(name).Open()
            output.Write(Encoding.UTF8.GetBytes(text: string))

    let observe (writer: Utf8JsonWriter) area =
        Directory.CreateDirectory area |> ignore

        let check name condition =
            writer.WriteBoolean((name: string), condition)

            if not condition then
                failwith ("Maintenance fixture failed: " + name)

        writer.WriteStartObject("modMaintenance")
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Maintenance fixture", StorageWorker.select root)
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

        let library = store.ModLibrary :> IModLibrary

        let adopt name entries =
            let path = Path.Combine(area, name)
            zip path entries

            store.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Path = path
                  Storage = ArtifactStorage.Copy },
                token
            )
            |> wait
            |> result

        let original =
            adopt
                "original.zip"
                [ "Data/a.txt", "old"; "Data/keep.txt", "same"; "Data/remove.txt", "old-only" ]

        let source = Directory.CreateDirectory(Path.Combine(root, "Source mod")).FullName

        for name, content in [ "a.txt", "old"; "keep.txt", "same"; "remove.txt", "old-only" ] do
            File.WriteAllText(Path.Combine(source, name), content)

        let initialMetadata =
            { Name = "Original mod"
              Version = "1"
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }

        let registered =
            library.Register(
                workspace,
                Guid.NewGuid(),
                initialMetadata,
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ "Source mod" ] |> result
                )
            )
            |> wait
            |> result

        let installed =
            library.Publish(registered.Id, registered.Revision, Guid.NewGuid())
            |> wait
            |> result

        let modId = installed.Id
        let first = library.Version(installed.CurrentVersion.Value, 0) |> wait |> result

        store.Artifacts.Link(reference original, modId, first.Id, false)
        |> wait
        |> result
        |> ignore

        let context, generation =
            MaintenanceDeployments.save state root workspace profile first area

        let otherArchive = adopt "other.zip" [ "Data/keep.txt", "same" ]

        let otherDraft =
            store.Installations.Prepare(reference otherArchive, token) |> wait |> result

        let otherStarted =
            store.Installations.Start(workspace, otherDraft.Id, otherDraft.Revision, Guid.NewGuid())
            |> result

        let other = stopped store workspace otherStarted.Id
        let otherVersion = library.Version(other.VersionId.Value, 0) |> wait |> result

        let shared =
            first.Entries
            |> List.find (fun entry -> LogicalPath.display entry.Path = "keep.txt")

        MaintenanceDeployments.sharePayload state otherVersion shared
        let otherVersion = library.Version(otherVersion.Id, 0) |> wait |> result

        let otherContext, otherGeneration =
            MaintenanceDeployments.save state root workspace profile otherVersion area

        let originalNow = store.Artifacts.Read(workspace, original.Id) |> wait |> result

        store.Artifacts.Link(reference originalNow, other.ModId.Value, otherVersion.Id, false)
        |> wait
        |> result
        |> ignore

        let metadata =
            { Name = "Before update"
              Version = "1"
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }

        let backup =
            library.Register(workspace, Guid.NewGuid(), metadata, Registration.Backup first.Id)
            |> wait
            |> result

        let revision, _ = MaintenanceDeployments.selection state profile

        (store.ModSelection :> IModSelection)
            .Change(profile, revision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let _, selected = MaintenanceDeployments.selection state profile

        let newer =
            adopt
                "newer.zip"
                [ "Data/a.txt", "new"; "Data/keep.txt", "same"; "Data/added.txt", "added" ]

        let draft = store.Installations.Prepare(reference newer, token) |> wait |> result

        let current =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = modId)

        let missingTarget =
            store.Installations.PrepareUpdate(
                workspace,
                draft.Id,
                draft.Revision,
                Guid.NewGuid(),
                0L,
                UpdateMode.Merge,
                Set.empty,
                "2"
            )
            |> wait

        check "MissingUpdateTargetIsRefused" (Result.isError missingTarget)

        let preview =
            store.Installations.PrepareUpdate(
                workspace,
                draft.Id,
                draft.Revision,
                modId,
                current.Revision,
                UpdateMode.Merge,
                Set.empty,
                "2"
            )
            |> wait
            |> result

        let started =
            store.Installations.StartUpdate(workspace, preview.Id, Guid.NewGuid()) |> result

        let updated = stopped store workspace started.Id
        let second = library.Version(updated.VersionId.Value, 0) |> wait |> result

        check
            "MergeKeepsStableModAndSharesUnchangedPayload"
            (updated.ModId = Some modId
             && second.Entries.Length = 4
             && first.Entries
                |> List.filter (fun entry ->
                    entry.Path <> (ModConductor.Platform.LogicalPath.create [ "a.txt" ] |> result))
                |> List.forall (fun entry -> second.Entries |> List.contains entry))

        check
            "OldVersionRetainedOnUpdate"
            ((library.Version(first.Id, 0) |> wait |> result).Entries = first.Entries)

        let current =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = modId)

        let replacementArchive =
            adopt
                "replacement.zip"
                [ "Data/a.txt", "not selected"
                  "Data/keep.txt", "same"
                  "Data/added.txt", "added" ]

        let draft =
            store.Installations.Prepare(reference replacementArchive, token)
            |> wait
            |> result

        let replacement =
            store.Installations.PrepareUpdate(
                workspace,
                draft.Id,
                draft.Revision,
                modId,
                current.Revision,
                UpdateMode.Replace,
                Set.singleton (LogicalPath.create [ "a.txt" ] |> result),
                "3"
            )
            |> wait
            |> result

        let replacementStarted =
            store.Installations.StartUpdate(workspace, replacement.Id, Guid.NewGuid())
            |> result

        let replacementInstalled = stopped store workspace replacementStarted.Id

        let third =
            library.Version(replacementInstalled.VersionId.Value, 0) |> wait |> result

        check
            "ReplaceHonoursKeepChoiceAndRetainsPreviousVersion"
            (third.Entries.Length = 3
             && third.Entries
                |> List.forall (fun entry -> second.Entries |> List.contains entry)
             && (library.Version(second.Id, 0) |> wait |> result).Entries = second.Entries)

        let _, afterSelection = MaintenanceDeployments.selection state profile
        check "UpdatePreservesProfileOrderAndEnabledState" (selected = afterSelection)

        let current =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = modId)

        MaintenanceDeployments.active state context (Some generation.Id)

        let activeRefused =
            store.Deletions.Delete(workspace, modId, current.Revision)
            |> wait
            |> Result.isError

        check
            "ActiveDeploymentPreventsDeletion"
            (activeRefused
             && (library.Scan(workspace, 100) |> wait |> result).Entries
                |> List.exists (fun entry -> entry.Id = modId))

        MaintenanceDeployments.active state context None

        let retainedBytes =
            File.ReadAllText(
                Path.Combine(
                    ModConductor.Platform.HostPath.value generation.Directory.Path,
                    ModConductor.Platform.LogicalPath.display generation.Files.Head.Path
                )
            )

        check "RetainedGenerationKeepsExactOldBytesAfterUpdate" (retainedBytes = "old")

        let ownedPath =
            use connection = MaintenanceDeployments.database state
            Path.Combine(root, (LibraryRows.library connection null workspace |> Option.get).Name)

        let changedPayload =
            third.Entries
            |> List.find (fun entry -> LogicalPath.display entry.Path = "a.txt")

        let changedPath =
            Path.Combine(ownedPath, LibraryFiles.payloadName changedPayload.Payload.Id)

        File.SetAttributes(changedPath, FileAttributes.Normal)
        File.WriteAllText(changedPath, "changed bytes still owned")

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(changedPath, UnixFileMode.UserWrite)

            store.Deletions.Delete(workspace, modId, current.Revision)
            |> wait
            |> result
            |> ignore
        else
            use noReadAccess =
                new FileStream(changedPath, FileMode.Open, FileAccess.Write, FileShare.Delete)

            store.Deletions.Delete(workspace, modId, current.Revision)
            |> wait
            |> result
            |> ignore

        check "DirectDeletionDoesNotOpenOwnedFileContents" (not (File.Exists changedPath))

        check
            "SuccessfulDeletionRemovesInventory"
            (((library.Scan(workspace, 100) |> wait |> result).Entries
              |> List.forall (fun entry -> entry.Id <> modId)))

        check
            "DeletedGenerationCannotRestoreAndHasNoPrivateReferences"
            (MaintenanceDeployments.unavailable state context.Id generation.Id [ shared.Payload.Id ])

        check
            "RegisteredHumanSourceFolderStaysUnchanged"
            (File.ReadAllText(Path.Combine(source, "a.txt")) = "old"
             && File.ReadAllText(Path.Combine(source, "keep.txt")) = "same"
             && File.ReadAllText(Path.Combine(source, "remove.txt")) = "old-only")

        check
            "OriginalArchivesRemain"
            (File.Exists(Path.Combine(area, "original.zip"))
             && File.Exists(Path.Combine(area, "newer.zip")))

        use connection = MaintenanceDeployments.database state
        let owned = LibraryRows.library connection null workspace |> Option.get
        let libraryPath = Path.Combine(root, owned.Name)

        let targetPayloads =
            first.Entries @ second.Entries @ third.Entries
            |> List.map _.Payload.Id
            |> List.distinct
            |> List.filter ((<>) shared.Payload.Id)

        check
            "ExclusiveOwnedFilesGoneAndSharedPayloadReanchored"
            (targetPayloads
             |> List.forall (fun id ->
                 not (File.Exists(Path.Combine(libraryPath, LibraryFiles.payloadName id))))
             && (LibraryRows.payload connection null shared.Payload.Id).IsSome
             && File.ReadAllText(
                 Path.Combine(libraryPath, LibraryFiles.payloadName shared.Payload.Id)
             ) = "same"
             && Sqlite.number
                 connection
                 null
                 "SELECT count(*) FROM mod_payloads WHERE id=$payload AND publication_id=$version"
                 [ "$payload", box (string shared.Payload.Id)
                   "$version", box (string otherVersion.Id) ] = 1L)

        check
            "UnrelatedModAndDeploymentRemainUsable"
            ((library.Version(otherVersion.Id, 0) |> wait |> result).Entries = otherVersion.Entries
             && MaintenanceClaims.unavailable connection null otherContext.Id otherGeneration.Id = None
             && File.ReadAllText(
                 Path.Combine(
                     HostPath.value otherGeneration.Directory.Path,
                     LogicalPath.display otherGeneration.Files.Head.Path
                 )
             ) = "same")

        check
            "SharedArchiveKeepsOnlySurvivingModLinks"
            ((store.Artifacts.Read(workspace, original.Id) |> wait |> result).Links
             |> List.forall (fun link -> link.ModId = other.ModId.Value))

        check
            "DeletedRowsHaveNoHiddenVersionsOrBackup"
            (Sqlite.number
                connection
                null
                "SELECT count(*) FROM mod_versions WHERE mod_id=$mod"
                [ "$mod", box (string modId) ] = 0L
             && LibraryRows.find connection null backup.Id = None)

        store.Installations.Stop() |> wait
        writer.WriteEndObject()
