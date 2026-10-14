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
open ModConductor.ModMaintenance
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module InstallationFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (a: Artifact) : ArtifactRef =
        { WorkspaceId = a.WorkspaceId
          Id = a.Id
          Revision = a.Revision }

    let private untilStopped (store: OperationStore) workspace id =
        let deadline = DateTime.UtcNow.AddSeconds 15
        let mutable status = store.Installations.Read(workspace, id) |> wait |> result

        while status.State = InstallationState.Running && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            status <- store.Installations.Read(workspace, id) |> wait |> result

        if status.State = InstallationState.Running then
            failwith "The installation did not stop."

        status

    let private zipEntries path (entries: (string * string) list) =
        use file = File.Create path
        use archive = new ZipArchive(file, ZipArchiveMode.Create)

        for path, text in entries do
            use output = archive.CreateEntry(path).Open()
            output.Write(Encoding.UTF8.GetBytes text)

    let private zip path =
        zipEntries
            path
            [ "Rivière/Data/textures/water.dds", "water"
              "Rivière/Data/textures/landscape/river.dds", "river"
              "Rivière/Readme.txt", "not installed" ]

    let create area =
        Directory.CreateDirectory area |> ignore
        zip (Path.Combine(area, "Rivière textures.zip"))

        zipEntries
            (Path.Combine(area, "Nested data.zip"))
            [ "Wrapper/Data/Meshes/actors/character/behaviors/0_master.hkx", "behavior"
              "Wrapper/Data/source/scripts/FNIS_example.psc", "source"
              "Wrapper/Data/FNIS.esp", "plugin"
              "Wrapper/FNIS_Readme.txt", "not installed" ]

        zipEntries
            (Path.Combine(area, "Two data roots.zip"))
            [ "First/Data/Meshes/a.nif", "first"; "Second/Data/Meshes/b.nif", "second" ]

        ArchiveInspectionFixtures.create area
        let malformed = Path.Combine(area, "corrupt-payload.zip")
        zipEntries malformed [ "textures/broken.dds", "ordinary compressed payload" ]
        let bytes = File.ReadAllBytes malformed

        let payloadOffset =
            30
            + int (BitConverter.ToUInt16(bytes, 26))
            + int (BitConverter.ToUInt16(bytes, 28))

        bytes[payloadOffset] <- 7uy
        File.WriteAllBytes(malformed, bytes)

    let worker state (workspace: string) (artifact: string) (id: string) checkpoint =
        use store = new OperationStore(state)

        let workspace, artifact, id =
            Guid.Parse workspace, Guid.Parse artifact, Guid.Parse id

        let archive = store.Artifacts.Read(workspace, artifact) |> wait |> result
        let draft = store.Installations.Prepare(reference archive, token) |> wait |> result

        store.Installations.StartAtCheckpoint(
            workspace,
            draft.Id,
            draft.Revision,
            id,
            fun name ->
                if name = checkpoint then
                    StorageWorker.pause ()
        )
        |> result
        |> ignore

        untilStopped store workspace id |> ignore
        store.Installations.Stop() |> wait

    let observe (writer: Utf8JsonWriter) area =
        create area
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let mutable originalVersion = Guid.Empty
        let mutable originalPayload = Guid.Empty
        let mutable archiveId = Guid.Empty

        let check (name: string) condition =
            writer.WriteBoolean(name, condition)

            if not condition then
                failwith ("Installation fixture failed: " + name)

        writer.WriteStartObject("archiveInstallation")

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Installation fixture", StorageWorker.select root)
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

            let missing = Guid.NewGuid()
            let unavailable = Error "This installation is no longer available."

            check
                "MissingInstallationReadRefused"
                (store.Installations.Read(workspace, missing) |> wait = unavailable)

            check
                "MissingInstallationCancelRefused"
                (store.Installations.Cancel(workspace, missing) |> wait = unavailable)

            check
                "MissingInstallationDiscardRefused"
                (store.Installations.Discard(workspace, missing) |> wait = unavailable)

            let source = Directory.CreateDirectory(Path.Combine(root, "existing")).FullName
            File.WriteAllText(Path.Combine(source, "existing.txt"), "existing mod")
            let library = store.ModLibrary :> IModLibrary

            let registered =
                library.Register(
                    workspace,
                    Guid.NewGuid(),
                    { Name = "Existing"
                      Version = "1"
                      Notes = ""
                      Comment = ""
                      Source = ""
                      Categories = [] },
                    Registration.Directory(
                        ModKind.Regular,
                        LogicalPath.create [ "existing" ] |> result
                    )
                )
                |> wait
                |> result

            originalVersion <- Guid.NewGuid()

            library.Publish(registered.Id, registered.Revision, originalVersion)
            |> wait
            |> result
            |> ignore

            originalPayload <-
                (library.Version(originalVersion, 0) |> wait |> result).Entries.Head.Payload.Id

            let adopt path =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Reference },
                    token
                )
                |> wait
                |> result

            let mergedPath = Path.Combine(area, "merged-tree.zip")

            zipEntries
                mergedPath
                [ "Wrapper/Data/meshes/actors/a.nif", "first"
                  "Wrapper/data/Meshes/ACTORS/b.nif", "second"
                  "Wrapper/Data/MESHES/actors/A.nif", "replacement"
                  "Wrapper/Data/textures/old", "stale file"
                  "Wrapper/Data/Textures/old/new.dds", "folder replaces file"
                  "Wrapper/Data/sound/old.wav/nested.txt", "stale folder"
                  "Wrapper/Data/Sound/old.wav", "file replaces folder"
                  "Wrapper/Data/empty.txt", "" ]

            let originalMerged = File.ReadAllBytes mergedPath
            let merged = adopt mergedPath

            let mergedDraft =
                store.Installations.Prepare(reference merged, token) |> wait |> result

            check
                "SharedSourceFoldersAndReplacementProduceOneTree"
                (mergedDraft.Files.Length = 5 && mergedDraft.Plan.IsSome)

            let mergedId = Guid.NewGuid()

            store.Installations.Start(workspace, mergedDraft.Id, mergedDraft.Revision, mergedId)
            |> result
            |> ignore

            let mergedJob = untilStopped store workspace mergedId

            if mergedJob.State <> InstallationState.Complete then
                failwith (defaultArg mergedJob.Problem "Merged installation incomplete")

            let mergedVersion = library.Version(mergedJob.VersionId.Value, 0) |> wait |> result

            let bytes =
                mergedVersion.Entries
                |> List.map (fun entry ->
                    Destinations.key entry.Path,
                    library.ReadPayload(mergedVersion.Id, entry.Payload.Id, 0L, 65536)
                    |> wait
                    |> result
                    |> Encoding.UTF8.GetString)
                |> Map.ofList

            check
                "MergedTreePublishesWinningAndEmptyBytes"
                (bytes = Map.ofList
                    [ "MESHES/ACTORS/B.NIF", "second"
                      "MESHES/ACTORS/A.NIF", "replacement"
                      "TEXTURES/OLD/NEW.DDS", "folder replaces file"
                      "SOUND/OLD.WAV", "file replaces folder"
                      "EMPTY.TXT", "" ])

            let prefixes =
                mergedVersion.Entries
                |> List.collect (fun entry ->
                    let parts = LogicalPath.components entry.Path

                    [ for count in 1 .. parts.Length - 1 ->
                          LogicalPath.create (List.take count parts) |> result ])
                |> List.groupBy Destinations.key

            check
                "PublishedDirectoriesHaveOneSpellingAndArchiveStaysUnchanged"
                (prefixes |> List.forall (fun (_, paths) -> (paths |> List.distinct).Length = 1)
                 && File.ReadAllBytes mergedPath = originalMerged)

            let updatePath = Path.Combine(area, "merged-update.zip")
            zipEntries updatePath [ "Data/mEsHeS/AcToRs/c.nif", "added" ]
            let updateArchive = adopt updatePath

            let updateDraft =
                store.Installations.Prepare(reference updateArchive, token) |> wait |> result

            let currentMerged =
                (library.Scan(workspace, 100) |> wait |> result).Entries
                |> List.find (fun entry -> entry.Id = mergedJob.ModId.Value)

            let update =
                store.Installations.PrepareUpdate(
                    workspace,
                    updateDraft.Id,
                    updateDraft.Revision,
                    currentMerged.Id,
                    currentMerged.Revision,
                    UpdateMode.Merge,
                    Set.empty,
                    "2"
                )
                |> wait
                |> result

            let updateJob =
                store.Installations.StartUpdate(workspace, update.Id, Guid.NewGuid()) |> result

            let updated = untilStopped store workspace updateJob.Id

            if updated.State <> InstallationState.Complete then
                failwith (defaultArg updated.Problem "Merged update incomplete")

            let updatedVersion = library.Version(updated.VersionId.Value, 0) |> wait |> result

            let added =
                updatedVersion.Entries
                |> List.find (fun entry -> Destinations.key entry.Path = "MESHES/ACTORS/C.NIF")

            let previous =
                mergedVersion.Entries
                |> List.find (fun entry -> Destinations.key entry.Path = "MESHES/ACTORS/B.NIF")

            check
                "MergeUpdateRetainsPayloadsAndExistingDirectorySpelling"
                (updatedVersion.Entries.Length = 6
                 && mergedVersion.Entries
                    |> List.forall (fun entry -> List.contains entry updatedVersion.Entries)
                 && (LogicalPath.components added.Path |> List.take 2) = (LogicalPath.components
                                                                              previous.Path
                                                                          |> List.take 2)
                 && (library.ReadPayload(updatedVersion.Id, added.Payload.Id, 0L, 65536)
                     |> wait
                     |> result
                     |> Encoding.UTF8.GetString) = "added")

            let nested = adopt (Path.Combine(area, "Nested data.zip"))

            let nestedDraft =
                store.Installations.Prepare(reference nested, token) |> wait |> result

            check
                "NestedMarkersUseExplicitDataRoot"
                (nestedDraft.Root = [ "Wrapper"; "Data" ]
                 && (nestedDraft.Files
                     |> List.map (fun file -> LogicalPath.display file.Destination)
                     |> Set.ofList) = set
                     [ "Meshes/actors/character/behaviors/0_master.hkx"
                       "source/scripts/FNIS_example.psc"
                       "FNIS.esp" ])

            let ambiguous = adopt (Path.Combine(area, "Two data roots.zip"))

            let ambiguousDraft =
                store.Installations.Prepare(reference ambiguous, token) |> wait |> result

            check
                "IndependentDataRootsStillNeedSelection"
                (ambiguousDraft.Root.IsEmpty && ambiguousDraft.Files.IsEmpty)

            let originalArchive = File.ReadAllBytes(Path.Combine(area, "Rivière textures.zip"))
            let archive = adopt (Path.Combine(area, "Rivière textures.zip"))
            archiveId <- archive.Id

            let prepared =
                store.Installations.Prepare(reference archive, token) |> wait |> result

            check
                "QuickWrapperDataRoot"
                (prepared.Root = [ "Rivière"; "Data" ] && prepared.Files.Length = 2)

            let changed =
                store.Installations.Change(
                    workspace,
                    prepared.Id,
                    prepared.Revision,
                    LayoutChange.Destination(
                        [ "Rivière"; "Data"; "textures"; "water.dds" ],
                        [ "textures"; "renamed.dds" ]
                    )
                )
                |> result

            let replaced =
                store.Installations.Change(
                    workspace,
                    changed.Id,
                    changed.Revision,
                    LayoutChange.Destination(
                        [ "Rivière"; "Data"; "textures"; "landscape"; "river.dds" ],
                        [ "textures"; "renamed.dds" ]
                    )
                )
                |> result

            check
                "ConflictingRemapUsesLastSelectedFile"
                (replaced.Files.Length = 1
                 && replaced.Files.Head.Index = changed.Files[1].Index
                 && replaced.Plan.Value.Files = replaced.Files)

            let fresh = store.Installations.Prepare(reference archive, token) |> wait |> result

            let changed =
                store.Installations.Change(
                    workspace,
                    fresh.Id,
                    fresh.Revision,
                    LayoutChange.Destination(
                        [ "Rivière"; "Data"; "textures"; "water.dds" ],
                        [ "textures"; "renamed.dds" ]
                    )
                )
                |> result

            let plan = changed.Plan.Value
            let job = Guid.NewGuid()

            store.Installations.Start(workspace, changed.Id, changed.Revision, job)
            |> result
            |> ignore

            let installed = untilStopped store workspace job

            if installed.State <> InstallationState.Complete then
                failwith (defaultArg installed.Problem "Installation incomplete")

            check
                "OriginalArchiveUnchanged"
                (File.ReadAllBytes(Path.Combine(area, "Rivière textures.zip")) = originalArchive)

            let version = library.Version(installed.VersionId.Value, 0) |> wait |> result

            check
                "ConfirmedDestinationsPublishedOnce"
                (version.Entries |> List.map (fun e -> LogicalPath.display e.Path) |> Set.ofList = (plan.Files
                                                                                                    |> List.map
                                                                                                        (fun
                                                                                                            f ->
                                                                                                            LogicalPath.display
                                                                                                                f.Destination)
                                                                                                    |> Set.ofList))

            let renamed =
                version.Entries
                |> List.find (fun e -> LogicalPath.display e.Path = "textures/renamed.dds")

            check
                "PublishedBytesMatchSelection"
                (Encoding.UTF8.GetString(
                    library.ReadPayload(version.Id, renamed.Payload.Id, 0L, 65536) |> wait |> result
                ) = "water")

            let repeated =
                store.Installations.Start(workspace, changed.Id, changed.Revision, job)
                |> result

            check "RepeatStartHasSameMod" (repeated.ModId = installed.ModId)

            check "TypedArchiveOrigin" (version.Origin = VersionOrigin.Archive archive.Id)
            let inventory = InventoryObservations.read store profile

            let imported =
                inventory.Entries
                |> List.find (fun e -> e.Entry.Mod.Id = installed.ModId.Value)
                |> _.Entry

            check
                "NoMutableSourceAndDisabledProfileReference"
                (imported.Mod.SourcePath.IsNone
                 && not (List.contains ModAction.Publish imported.Mod.Actions)
                 && (match imported.Selection with
                     | SelectionState.Managed(_, false) -> true
                     | _ -> false))

            let linked = store.Artifacts.Read(workspace, archive.Id) |> wait |> result

            check
                "AutomaticExactProvenance"
                (linked.State = ArtifactState.Installed
                 && linked.Links
                    |> List.exists (fun l ->
                        l.ModId = installed.ModId.Value && l.VersionId = version.Id && l.Installed))

            for filename in
                [ Path.Combine(area, "textures.7z")
                  Path.Combine(
                      AppContext.BaseDirectory,
                      "fixtures/archives/test_read_format_rar5_multiple_files_solid.rar"
                  ) ] do
                let artifact = adopt filename
                let draft = store.Installations.Prepare(reference artifact, token) |> wait |> result

                let draft =
                    if draft.Plan.IsNone then
                        store.Installations.Change(
                            workspace,
                            draft.Id,
                            draft.Revision,
                            LayoutChange.Root []
                        )
                        |> result
                    else
                        draft

                let draft =
                    if draft.Files.Length > 2 then
                        let first =
                            draft.Manifest.Entries
                            |> List.find (fun e -> e.Index = draft.Files.Head.Index)

                        store.Installations.Change(
                            workspace,
                            draft.Id,
                            draft.Revision,
                            LayoutChange.Include(LogicalPath.components first.Path, false)
                        )
                        |> result
                    else
                        draft

                let id = Guid.NewGuid()

                store.Installations.Start(workspace, draft.Id, draft.Revision, id)
                |> result
                |> ignore

                let outcome = untilStopped store workspace id

                if outcome.State <> InstallationState.Complete then
                    failwith (defaultArg outcome.Problem "Format installation failed")

                let published = library.Version(outcome.VersionId.Value, 0) |> wait |> result

                check
                    ("Installed_" + draft.Manifest.Format)
                    (published.Entries.Length = draft.Files.Length
                     && (published.Entries |> List.sumBy _.Payload.Length) = draft.Plan.Value.Bytes)

            let cancellationArchive =
                store.Artifacts.Read(workspace, archiveId) |> wait |> result

            let draft =
                store.Installations.Prepare(reference cancellationArchive, token)
                |> wait
                |> result

            use arrived = new ManualResetEventSlim(false)
            use release = new ManualResetEventSlim(false)
            let cancelId = Guid.NewGuid()

            store.Installations.StartAtCheckpoint(
                workspace,
                draft.Id,
                draft.Revision,
                cancelId,
                fun name ->
                    if name = "file-observed" then
                        arrived.Set()
                        release.Wait()
            )
            |> result
            |> ignore

            if not (arrived.Wait 10000) then
                failwith "Installation observation checkpoint was not reached."

            let held = store.Installations.Read(workspace, cancelId) |> wait |> result

            check
                "RunningInstallationDiscardRefused"
                (store.Installations.Discard(workspace, cancelId) |> wait = Error
                    "Wait for the installation to stop before deleting temporary files.")

            check
                "RunningInstallationStillPresent"
                ((store.Installations.Read(workspace, cancelId) |> wait |> result).State = InstallationState.Running)

            use changedTimeout = new CancellationTokenSource(TimeSpan.FromSeconds 5.)

            let changed =
                store.Installations.WaitForChange(workspace, cancelId, held, changedTimeout.Token)

            Thread.Sleep 150
            check "IdleInstallationWatchWaitsForChange" (not changed.IsCompleted)

            store.Installations.Cancel(workspace, cancelId) |> wait |> result |> ignore
            release.Set()

            changed.GetAwaiter().GetResult()
            check "CancelledInstallationWakesWatch" changed.IsCompletedSuccessfully

            check
                "CancelledBeforePublication"
                ((untilStopped store workspace cancelId).State = InstallationState.Stopped)

            store.Installations.Discard(workspace, cancelId) |> wait |> result |> ignore
            let corrupt = adopt (Path.Combine(area, "corrupt-payload.zip"))
            let draft = store.Installations.Prepare(reference corrupt, token) |> wait |> result
            let corruptId = Guid.NewGuid()

            store.Installations.Start(workspace, draft.Id, draft.Revision, corruptId)
            |> result
            |> ignore

            let failed = untilStopped store workspace corruptId

            check
                "CorruptPayloadHasNoPublishedMod"
                (failed.State = InstallationState.Stopped && failed.ModId.IsNone)

            writer.WriteString("CorruptError", failed.Problem.Value)

            let unfinishedArchive =
                store.Artifacts.Read(workspace, corrupt.Id) |> wait |> result

            check "UnfinishedFilesKeepArchiveEntry" (not unfinishedArchive.CanRemove)
            store.Installations.Discard(workspace, corruptId) |> wait |> result |> ignore
            let removable = store.Artifacts.Read(workspace, corrupt.Id) |> wait |> result
            check "TemporaryCleanupReleasesArchiveEntry" removable.CanRemove
            store.Artifacts.Remove(reference removable) |> wait |> result

            check
                "ExistingPayloadPreservedAfterFailureAndCleanup"
                (Encoding.UTF8.GetString(
                    library.ReadPayload(originalVersion, originalPayload, 0L, 65536)
                    |> wait
                    |> result
                ) = "existing mod")

            store.Installations.Stop() |> wait

        for checkpoint in [ "before-publication"; "after-publication" ] do
            let id = Guid.NewGuid()

            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--installation-worker"
                      state
                      string workspace
                      string archiveId
                      string id
                      checkpoint ]
                )

            child.Line() |> ignore
            child.Terminate()
            use restarted = new OperationStore(state)
            let saved = restarted.Installations.Read(workspace, id) |> wait |> result
            let complete = checkpoint = "after-publication"

            check
                ("Restart_" + checkpoint)
                (saved.State = if complete then
                                   InstallationState.Complete
                               else
                                   InstallationState.Stopped)

            if complete then
                let linked = restarted.Artifacts.Read(workspace, archiveId) |> wait |> result
                let inventory = InventoryObservations.read restarted profile

                check
                    "RestartKeepsModProfileAndArtifactTogether"
                    (linked.Links
                     |> List.exists (fun l ->
                         Some l.ModId = saved.ModId
                         && Some l.VersionId = saved.VersionId
                         && l.Installed)
                     && inventory.Entries
                        |> List.exists (fun e -> Some e.Entry.Mod.Id = saved.ModId))
            else
                restarted.Installations.Discard(workspace, id) |> wait |> result |> ignore

            let library = restarted.ModLibrary :> IModLibrary

            check
                ("ExistingPayloadAfter_" + checkpoint)
                (Encoding.UTF8.GetString(
                    library.ReadPayload(originalVersion, originalPayload, 0L, 65536)
                    |> wait
                    |> result
                ) = "existing mod")

        writer.WriteEndObject()
