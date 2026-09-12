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
        let mutable status = store.Installations.Read(workspace, id) |> wait

        while status.State = InstallationState.Running && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            status <- store.Installations.Read(workspace, id) |> wait

        if status.State = InstallationState.Running then
            failwith "The installation did not stop."

        status

    let private zip path =
        use file = File.Create path
        use archive = new ZipArchive(file, ZipArchiveMode.Create)

        for path, text in
            [ "Rivière/Data/textures/water.dds", "water"
              "Rivière/Data/textures/landscape/river.dds", "river"
              "Rivière/Readme.txt", "not installed" ] do
            use output = archive.CreateEntry(path).Open()
            output.Write(Encoding.UTF8.GetBytes text)

    let create area =
        Directory.CreateDirectory area |> ignore
        zip (Path.Combine(area, "Rivière textures.zip"))
        ArchiveInspectionFixtures.create area
        let malformed = Path.Combine(area, "wrong-size.zip")
        File.Copy(Path.Combine(area, "textures.zip"), malformed)
        let bytes = File.ReadAllBytes malformed

        for i in 0 .. bytes.Length - 4 do
            let signature = BitConverter.ToUInt32(bytes, i)

            let offset =
                if signature = 0x04034B50u then Some(i + 22)
                elif signature = 0x02014B50u then Some(i + 24)
                else None

            offset
            |> Option.iter (fun start -> BitConverter.GetBytes(1u).CopyTo(bytes, start))

        File.WriteAllBytes(malformed, bytes)

    let worker state (workspace: string) (artifact: string) (id: string) checkpoint =
        use store = new OperationStore(state)

        let workspace, artifact, id =
            Guid.Parse workspace, Guid.Parse artifact, Guid.Parse id

        let archive = store.Artifacts.Read(workspace, artifact) |> wait |> result
        let draft = store.Installations.Prepare(reference archive, token) |> wait

        store.Installations.StartAtCheckpoint(
            workspace,
            draft.Id,
            draft.Revision,
            id,
            fun name ->
                if name = checkpoint then
                    StorageWorker.pause ()
        )
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

            let originalArchive = File.ReadAllBytes(Path.Combine(area, "Rivière textures.zip"))
            let archive = adopt (Path.Combine(area, "Rivière textures.zip"))
            archiveId <- archive.Id
            let prepared = store.Installations.Prepare(reference archive, token) |> wait

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

            let rejected =
                try
                    store.Installations.Change(
                        workspace,
                        changed.Id,
                        changed.Revision,
                        LayoutChange.Destination(
                            [ "Rivière"; "Data"; "textures"; "landscape"; "river.dds" ],
                            [ "textures"; "renamed.dds" ]
                        )
                    )
                    |> ignore

                    false
                with :? InstallationException ->
                    true

            check "ConflictingRemapLeavesConfirmedDraftUnchanged" rejected
            let plan = changed.Plan.Value
            let job = Guid.NewGuid()

            store.Installations.Start(workspace, changed.Id, changed.Revision, job)
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

            check
                "RepeatStartHasSameMod"
                ((store.Installations.Start(workspace, changed.Id, changed.Revision, job)).ModId = installed.ModId)

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
                let draft = store.Installations.Prepare(reference artifact, token) |> wait

                let draft =
                    if draft.Plan.IsNone then
                        store.Installations.Change(
                            workspace,
                            draft.Id,
                            draft.Revision,
                            LayoutChange.Root []
                        )
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
                    else
                        draft

                let id = Guid.NewGuid()
                store.Installations.Start(workspace, draft.Id, draft.Revision, id) |> ignore
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
                store.Installations.Prepare(reference cancellationArchive, token) |> wait

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
            |> ignore

            if not (arrived.Wait 10000) then
                failwith "Installation observation checkpoint was not reached."

            store.Installations.Cancel(workspace, cancelId) |> wait |> ignore
            release.Set()

            check
                "CancelledBeforePublication"
                ((untilStopped store workspace cancelId).State = InstallationState.Stopped)

            store.Installations.Discard(workspace, cancelId) |> wait |> ignore
            let corrupt = adopt (Path.Combine(area, "wrong-size.zip"))
            let draft = store.Installations.Prepare(reference corrupt, token) |> wait
            let corruptId = Guid.NewGuid()

            store.Installations.Start(workspace, draft.Id, draft.Revision, corruptId)
            |> ignore

            let failed = untilStopped store workspace corruptId

            check
                "CorruptPayloadHasNoPublishedMod"
                (failed.State = InstallationState.Stopped && failed.ModId.IsNone)

            writer.WriteString("CorruptError", failed.Problem.Value)

            let unfinishedArchive =
                store.Artifacts.Read(workspace, corrupt.Id) |> wait |> result

            check "UnfinishedFilesKeepArchiveEntry" (not unfinishedArchive.CanRemove)
            store.Installations.Discard(workspace, corruptId) |> wait |> ignore
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
            let saved = restarted.Installations.Read(workspace, id) |> wait
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
                restarted.Installations.Discard(workspace, id) |> wait |> ignore

            let library = restarted.ModLibrary :> IModLibrary

            check
                ("ExistingPayloadAfter_" + checkpoint)
                (Encoding.UTF8.GetString(
                    library.ReadPayload(originalVersion, originalPayload, 0L, 65536)
                    |> wait
                    |> result
                ) = "existing mod")

        writer.WriteEndObject()
