namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.DeploymentRecovery
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces
open ModConductor.ProfileGameData

module WorkspaceReopenFixtures =
    let private wait = StorageWorker.wait

    let private result value =
        value
        |> Result.defaultWith (fun error ->
            match box error with
            | :? ProfileDataError as error -> invalidOp (DataErrors.problemMessage error)
            | _ -> invalidOp (error.ToString()))

    let private token = CancellationToken.None

    let private deployment value =
        value
        |> Result.defaultWith (function
            | ModConductor.Deployment.DeploymentError.Unavailable text
            | ModConductor.Deployment.DeploymentError.Blocked text -> invalidOp text
            | error -> invalidOp (error.ToString()))

    let private path = DeploymentFixtureData.path

    let private previous identity =
        { identity with
            Device =
                match identity.Device with
                | LinuxDevice(major, minor) -> LinuxDevice(major, minor + 37u)
                | WindowsVolume serial -> WindowsVolume(serial + 37UL) }

    let private editDatabase state action =
        let databasePath = Path.Combine(state, "state.db")

        use connection =
            new SqliteConnection("Data Source=" + databasePath + ";Pooling=False")

        connection.Open()
        action connection

    let private oldIdentities state =
        editDatabase state (fun connection ->
            for table, column in
                [ "mod_libraries", "identity"
                  "mods", "source_identity"
                  "mod_payloads", "identity"
                  "artifacts", "source_identity"
                  "artifacts", "stored_identity"
                  "output_locations", "root_identity" ] do
                use query = connection.CreateCommand()

                query.CommandText <-
                    "SELECT rowid,"
                    + column
                    + " FROM "
                    + table
                    + " WHERE "
                    + column
                    + " IS NOT NULL"

                use reader = query.ExecuteReader()

                let rows =
                    [ while reader.Read() do
                          yield reader.GetInt64 0, reader.GetString 1 ]

                reader.Close()

                for id, identity in rows do
                    Sqlite.execute
                        connection
                        null
                        ("UPDATE " + table + " SET " + column + "=$identity WHERE rowid=$id")
                        [ "$id", box id
                          "$identity",
                          box (
                              LibraryEncoding.readIdentity identity
                              |> previous
                              |> LibraryEncoding.identity
                          ) ]

            Sqlite.execute
                connection
                null
                "UPDATE workspace_roots SET device=CASE device_kind WHEN 1 THEN substr(device,1,instr(device,':')) || (CAST(substr(device,instr(device,':')+1) AS INTEGER)+37) ELSE CAST(device AS INTEGER)+37 END"
                []

            Sqlite.execute
                connection
                null
                "UPDATE root_creation_receipts SET marker_device=CASE marker_device_kind WHEN 1 THEN substr(marker_device,1,instr(marker_device,':')) || (CAST(substr(marker_device,instr(marker_device,':')+1) AS INTEGER)+37) ELSE CAST(marker_device AS INTEGER)+37 END"
                [])

    let private documents (store: OperationStore) workspace profile =
        let game =
            (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        match game.Binding.Value.Evidence.Locations.Documents with
        | ModConductor.GameContexts.Location.Located(path, _) -> path
        | ModConductor.GameContexts.Location.Unavailable text -> invalidOp text

    let private oldProfileData state =
        let root (value: DataRoot) =
            { value with
                Identity = previous value.Identity }

        let stored (value: StoredDataFile) =
            { value with
                Root = root value.Root
                File =
                    { value.File with
                        Identity = previous value.File.Identity } }

        editDatabase state (fun connection ->
            for table in [ "profile_data_contexts"; "profile_data_profiles" ] do
                use query = connection.CreateCommand()
                query.CommandText <- "SELECT rowid,body FROM " + table
                use reader = query.ExecuteReader()

                let rows =
                    [ while reader.Read() do
                          yield reader.GetInt64 0, reader.GetFieldValue<byte array> 1 ]

                reader.Close()

                for id, bytes in rows do
                    let changed =
                        if table = "profile_data_contexts" then
                            let value = ProfileDataEncoding.readContext bytes

                            { value with
                                Workspace = root value.Workspace
                                Documents = root value.Documents
                                Storage = value.Storage |> Option.map root
                                OriginalsRoot = value.OriginalsRoot |> Option.map root
                                PluginRoot = value.PluginRoot |> Option.map root
                                PluginOriginals = value.PluginOriginals |> Option.map root
                                PluginObserved =
                                    value.PluginObserved |> Option.map (Option.map stored)
                                Applied =
                                    value.Applied
                                    |> Option.map (fun applied ->
                                        { applied with
                                            Originals =
                                                applied.Originals
                                                |> List.map (fun original ->
                                                    { original with
                                                        Original =
                                                            original.Original
                                                            |> Option.map stored })
                                            Plugins =
                                                applied.Plugins
                                                |> Option.map (fun plugins ->
                                                    { plugins with
                                                        Original =
                                                            plugins.Original |> Option.map stored })
                                            SaveLink = applied.SaveLink |> Option.map previous }) }
                            |> ProfileDataEncoding.context
                        else
                            let value = ProfileDataEncoding.readProfile bytes

                            { value with
                                Root = value.Root |> Option.map root
                                Settings = value.Settings |> Option.map root
                                Saves = value.Saves |> Option.map root }
                            |> ProfileDataEncoding.profile

                    Sqlite.execute
                        connection
                        null
                        ("UPDATE " + table + " SET body=$body WHERE rowid=$id")
                        [ "$body", box changed; "$id", box id ])

    let private oldDeployments state =
        let location (value: Location) =
            { value with
                Identity = previous value.Identity }

        let entry (value: HeldEntry) =
            { value with
                Identity = previous value.Identity }

        editDatabase state (fun connection ->
            for table in [ "deployment_contexts"; "deployment_generations" ] do
                use query = connection.CreateCommand()
                query.CommandText <- "SELECT rowid,body FROM " + table
                use reader = query.ExecuteReader()

                let rows =
                    [ while reader.Read() do
                          yield reader.GetInt64 0, reader.GetFieldValue<byte array> 1 ]

                reader.Close()

                for id, bytes in rows do
                    let changed =
                        if table = "deployment_contexts" then
                            let value = DeploymentEncoding.contextFrom bytes

                            { value with
                                Roots =
                                    value.Roots
                                    |> List.map (fun root ->
                                        { root with
                                            Directory = location root.Directory
                                            Originals = location root.Originals })
                                Links =
                                    value.Links
                                    |> List.map (fun link ->
                                        { link with Entry = entry link.Entry })
                                Originals =
                                    value.Originals
                                    |> List.map (fun original ->
                                        { original with
                                            Entry = entry original.Entry })
                                Directories =
                                    value.Directories
                                    |> List.map (fun directory ->
                                        { directory with
                                            Identity = previous directory.Identity }) }
                            |> DeploymentEncoding.contextBytes
                        else
                            let value = DeploymentEncoding.generationFrom bytes

                            { value with
                                Directory = location value.Directory
                                Files =
                                    value.Files
                                    |> List.map (fun file ->
                                        { file with
                                            Identity = previous file.Identity
                                            Backing =
                                                file.Backing
                                                |> Option.map (fun backing ->
                                                    { backing with
                                                        Directory = location backing.Directory
                                                        Identity = previous backing.Identity }) })
                                Observed =
                                    value.Observed
                                    |> List.map (fun file ->
                                        { file with
                                            Identity = previous file.Identity })
                                Working =
                                    value.Working
                                    |> List.map (fun working ->
                                        { working with
                                            Root = location working.Root
                                            Identity = working.Identity |> Option.map previous }) }
                            |> DeploymentEncoding.generationBytes

                    Sqlite.execute
                        connection
                        null
                        ("UPDATE " + table + " SET body=$body,digest=$digest WHERE rowid=$id")
                        [ "$id", box id
                          "$body", box changed
                          "$digest", box (DeploymentEncoding.hash changed) ])

    let private legacyTupleReuse area =
        let state = Path.Combine(area, "tuple-reuse-state")

        let first =
            Directory.CreateDirectory(Path.Combine(area, "tuple-reuse-first")).FullName

        let second =
            Directory.CreateDirectory(Path.Combine(area, "tuple-reuse-second")).FullName

        let firstId = Guid.NewGuid()

        do
            use store = new OperationStore(state)

            (store.Workspaces :> IWorkspaceState)
                .Create(firstId, "First", StorageWorker.select first)
            |> wait
            |> result
            |> ignore

        let selected = StorageWorker.select second

        let identity =
            match (RootSelection.facts selected).File with
            | Known value -> value
            | Unknown text -> invalidOp text

        let kind, device =
            match identity.Device with
            | LinuxDevice(major, minor) -> 1, string major + ":" + string minor
            | WindowsVolume serial -> 2, string serial

        editDatabase state (fun connection ->
            Sqlite.execute
                connection
                null
                "CREATE UNIQUE INDEX IF NOT EXISTS workspace_root_identity ON workspace_roots(device_kind,device,file_low,file_high)"
                []

            Sqlite.execute
                connection
                null
                "UPDATE workspace_roots SET device_kind=$kind,device=$device,file_low=$low,file_high=$high WHERE id=$id"
                [ "$kind", box kind
                  "$device", box device
                  "$low", box (string identity.Low)
                  "$high", box (string identity.High)
                  "$id", box (string firstId) ])

        use reopened = new OperationStore(state)
        let api = reopened.Workspaces :> IWorkspaceState
        let created = api.Create(Guid.NewGuid(), "Second", selected) |> wait |> result
        let original = api.Open(StorageWorker.select first) |> wait |> result
        created.Workspace.Id <> original.Workspace.Id && original.Workspace.Id = firstId

    let worker area =
        let ids = File.ReadAllLines(Path.Combine(area, "ids"))
        let id n = Guid.Parse ids[n]

        let workspace, profile, modId, version, copied, referenced, output =
            id 0, id 1, id 2, id 3, id 4, id 5, id 6

        let statePath, root = Path.Combine(area, "state"), Path.Combine(area, "root")
        use bytes = new MemoryStream()
        use writer = new Utf8JsonWriter(bytes)

        let check (name: string) condition =
            if not condition then
                failwith ("Workspace reopen fixture failed: " + name)

            writer.WriteBoolean(name, condition)

        writer.WriteStartObject()

        do
            use store = new OperationStore(statePath)
            let state = store.Workspaces :> IWorkspaceState
            let reopened = state.Open(StorageWorker.select root) |> wait |> result

            check
                "logicalSelectionRetained"
                (reopened.Workspace.Id = workspace
                 && reopened.Workspace.SelectedProfile.Value.Id = profile)

            let library = store.ModLibrary :> IModLibrary
            let manifest = library.Version(version, 0) |> wait |> result

            check
                "modAndPayloadRetained"
                (manifest.ModId = modId
                 && (library.ReadPayload(version, manifest.Entries.Head.Payload.Id, 0L, 1024)
                     |> wait
                     |> result
                     |> Text.Encoding.UTF8.GetString) = "saved mod")

            let contexts = store.GameContexts :> IGameContexts
            let before = contexts.Read(workspace, profile) |> wait |> result

            check
                "legacyKeysDerived"
                (before.Binding.Value.DeploymentKey = ids[7]
                 && before.Binding.Value.ComponentRoot = id 8)

            let refreshed =
                contexts.Refresh(workspace, profile, before.Revision) |> wait |> result

            check
                "refreshRetainsAssociation"
                (refreshed.Binding.Value.Id = before.Binding.Value.Id
                 && refreshed.Binding.Value.DeploymentKey = ids[7]
                 && refreshed.Binding.Value.ComponentRoot = id 8)

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace profile

            let artifacts = store.Artifacts

            for artifact in [ copied; referenced ] do
                let saved = artifacts.Read(workspace, artifact) |> wait |> result

                let content =
                    store.ArtifactSource.ReadVerified(
                        { WorkspaceId = workspace
                          Id = artifact
                          Revision = saved.Revision },
                        token,
                        fun (_, stream) ->
                            use reader = new StreamReader(stream, leaveOpen = true)
                            reader.ReadToEnd()
                    )
                    |> wait
                    |> result

                check
                    (if artifact = copied then
                         "copiedArchiveReadable"
                     else
                         "referencedArchiveReadable")
                    (content = "saved archive")

            let pendingCopy = artifacts.Read(workspace, id 10) |> wait |> result

            let pendingDelete =
                artifacts.DeleteCopy(
                    { WorkspaceId = workspace
                      Id = pendingCopy.Id
                      Revision = pendingCopy.Revision }
                )
                |> wait

            check
                "pendingArchiveDeletionRetainsRecordedExpectation"
                (Result.isError pendingDelete
                 && File.ReadAllText pendingCopy.Path = "saved archive")

            let savedCopy = artifacts.Read(workspace, copied) |> wait |> result

            let deleted =
                artifacts.DeleteCopy(
                    { WorkspaceId = workspace
                      Id = copied
                      Revision = savedCopy.Revision }
                )
                |> wait
                |> result

            check
                "newArchiveDeletionUsesContentProof"
                (deleted.State = ArtifactState.Detached
                 && not (File.Exists savedCopy.Path)
                 && File.ReadAllText(Path.Combine(area, "archive.zip")) = "saved archive")

            let outputs = store.GeneratedOutputs

            let scope () =
                outputs.Read(workspace, profile, None) |> wait |> result

            check
                "outputAssociationRetained"
                ((scope ()).Locations |> List.exists (fun location -> location.Id = output))

            let selected =
                [ { LocationId = output
                    Path = path "generated.txt" } ]

            let first = outputs.Observe(scope (), ignore, token) |> wait |> result

            let physical =
                (scope ()).Locations
                |> List.find (fun location -> location.Id = output)
                |> _.PhysicalPath

            File.WriteAllText(Path.Combine(physical, "generated.txt"), "changed after preview")

            let stale =
                outputs.Apply(Guid.NewGuid(), first.Id, selected, OutputAction.Discard, token)
                |> wait

            check
                "staleDiscardPreservesFile"
                (Result.isError stale
                 && File.ReadAllText(Path.Combine(physical, "generated.txt")) = "changed after preview")

            let snapshot = outputs.Observe(scope (), ignore, token) |> wait |> result

            outputs.Apply(Guid.NewGuid(), snapshot.Id, selected, OutputAction.Discard, token)
            |> wait
            |> result
            |> ignore

            check
                "freshOutputDiscardWorks"
                (not (File.Exists(Path.Combine(physical, "generated.txt"))))

            let read = store.Deployments.Read profile |> wait |> deployment
            check "completedDeploymentReadable" read.Active.IsSome

            let prepared =
                store.Deployments.Prepare(Guid.NewGuid(), read.Sources, ignore, token)
                |> wait
                |> deployment

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> wait
            |> deployment
            |> ignore

            check
                "newDeploymentUsesCurrentFiles"
                (File.ReadAllText(
                    Path.Combine(
                        GameViews.rootPath (StorageWorker.select root |> RootSelection.path) profile,
                        "Data",
                        "input.txt"
                    )
                ) = "saved mod")

            let active = store.Deployments.Read profile |> wait |> deployment

            let deactivation =
                store.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    active.Sources,
                    None,
                    ignore,
                    token
                )
                |> wait
                |> deployment

            store.Deployments.Activate(deactivation.Id, deactivation.Sources, ignore, token)
            |> wait
            |> result
            |> ignore

            check
                "legacyOriginalRestored"
                (File.ReadAllText(
                    Path.Combine(
                        GameViews.rootPath (StorageWorker.select root |> RootSelection.path) profile,
                        "Data",
                        "input.txt"
                    )
                ) = "original input")

            let restored = store.Deployments.Read profile |> wait |> deployment

            let reapplied =
                store.Deployments.Prepare(Guid.NewGuid(), restored.Sources, ignore, token)
                |> wait
                |> deployment

            store.Deployments.Activate(reapplied.Id, reapplied.Sources, ignore, token)
            |> wait
            |> deployment
            |> ignore

            check
                "restoredOriginalSupportsNextDeployment"
                (File.ReadAllText(
                    Path.Combine(
                        GameViews.rootPath (StorageWorker.select root |> RootSelection.path) profile,
                        "Data",
                        "input.txt"
                    )
                ) = "saved mod")

            let activeAgain = store.Deployments.Read profile |> wait |> deployment

            let clearedAgain =
                store.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    activeAgain.Sources,
                    None,
                    ignore,
                    token
                )
                |> wait
                |> deployment

            store.Deployments.Activate(clearedAgain.Id, clearedAgain.Sources, ignore, token)
            |> wait
            |> deployment
            |> ignore

            let privateApi = store.ProfileGameData
            let settings = privateApi.Read(workspace, profile) |> wait |> result

            check
                "privateSettingsRetained"
                (settings.Options.Settings && settings.Options.Saves && settings.InUse.IsSome)

            privateApi.Restore(Guid.NewGuid(), settings.Reference, token)
            |> wait
            |> result
            |> ignore

            check
                "privateOriginalRestored"
                (File.ReadAllText(
                    Path.Combine(documents store workspace profile, "SkyrimPrefs.ini")
                ) = "[Display]\r\niSize W=1280\r\n")

            let currentMod =
                (library.Scan(workspace, 100) |> wait |> result).Entries
                |> List.find (fun entry -> entry.Id = modId)

            store.Deletions.Delete(workspace, modId, currentMod.Revision)
            |> wait
            |> result
            |> ignore

            check
                "freshModDeletionWorks"
                ((library.Scan(workspace, 100) |> wait |> result).Entries
                 |> List.forall (fun entry -> entry.Id <> modId))

            check
                "restoredOriginalRetainedAfterModDeletion"
                (File.ReadAllText(
                    Path.Combine(
                        GameViews.rootPath (StorageWorker.select root |> RootSelection.path) profile,
                        "Data",
                        "input.txt"
                    )
                ) = "original input")

            check
                "modSourcePreserved"
                (File.ReadAllText(Path.Combine(root, "source", "input.txt")) = "saved mod")

            check
                "foreignRootFilePreserved"
                (File.ReadAllText(Path.Combine(root, "foreign.txt")) = "keep")

        do
            use store = new OperationStore(statePath)

            let bound =
                (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

            check
                "associationSurvivesAnotherReopen"
                (bound.Binding.Value.DeploymentKey = ids[7]
                 && bound.Binding.Value.ComponentRoot = id 8)

            let otherGame, otherProton =
                ProtonFixtures.create (Path.Combine(area, "another-installation"))

            let changed =
                (store.GameContexts :> IGameContexts)
                    .Save(
                        workspace,
                        profile,
                        bound.Revision,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = otherGame
                          Wine = None
                          Proton = if OperatingSystem.IsLinux() then Some otherProton else None }
                    )
                |> wait
                |> result

            check
                "differentInstallationHasSeparateAssociation"
                (changed.Binding.Value.Id <> bound.Binding.Value.Id
                 && changed.Binding.Value.DeploymentKey <> ids[7]
                 && changed.Binding.Value.ComponentRoot <> id 8)

            DeploymentFixtureData.isolateWindowsGameLocations
                store
                statePath
                (Path.Combine(area, "another-installation"))
                workspace
                profile

            let separate =
                store.GeneratedOutputs.Read(workspace, profile, None) |> wait |> result

            check
                "differentInstallationDoesNotAdoptOutput"
                (separate.Locations |> List.forall (fun location -> location.Id <> output))

        check "legacyTupleReuseDoesNotBlockNewWorkspace" (legacyTupleReuse area)

        writer.WriteEndObject()
        writer.Flush()
        Console.WriteLine(Text.Encoding.UTF8.GetString(bytes.ToArray()))

    let observe (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "renumbered-workspace")).FullName

        let statePath = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "root")).FullName
        let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
        File.WriteAllText(Path.Combine(source, "input.txt"), "saved mod")
        File.WriteAllText(Path.Combine(root, "foreign.txt"), "keep")
        let archive = Path.Combine(area, "archive.zip")
        File.WriteAllText(archive, "saved archive")

        let workspace, profile, modId, version, copied, referenced, output =
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid(),
            Guid.NewGuid()

        let pendingCopy = Guid.NewGuid()
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        BethesdaSamples.requiredBaseFiles game
        let mutable deploymentKey = ""
        let mutable componentRoot = Guid.Empty
        let mutable legacyEvidence = ""
        let mutable legacyDataContext = Guid.Empty

        do
            use store = new OperationStore(statePath)
            let state = store.Workspaces :> IWorkspaceState

            state.Create(workspace, "Saved workspace", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

            state.Edit(workspace, 0L, ProfileEdit.Create { Id = profile; Name = "Saved profile" })
            |> wait
            |> result
            |> ignore

            let library = store.ModLibrary :> IModLibrary

            library.Register(
                workspace,
                modId,
                { Name = "Saved mod"
                  Notes = ""
                  Comment = ""
                  Version = "1"
                  Source = ""
                  Categories = [] },
                Registration.Directory(ModKind.Regular, path "source")
            )
            |> wait
            |> result
            |> ignore

            library.Publish(modId, 0L, version) |> wait |> result |> ignore
            let inventory = InventoryObservations.read store profile

            (store.ModSelection :> IModSelection)
                .Change(profile, inventory.SelectionRevision, [ modId ], SelectionEdit.Enable true)
            |> wait
            |> result
            |> ignore

            let context =
                (store.GameContexts :> IGameContexts)
                    .Save(
                        workspace,
                        profile,
                        0L,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Wine = None
                          Proton = if OperatingSystem.IsLinux() then Some proton else None }
                    )
                |> wait
                |> result

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace profile

            let context =
                (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

            let old =
                { context.Binding.Value.Evidence with
                    DefinitionRevision = context.Binding.Value.Evidence.DefinitionRevision - 1
                    RootIdentity =
                        context.Binding.Value.Evidence.RootIdentity |> Option.map previous
                    DataIdentity =
                        context.Binding.Value.Evidence.DataIdentity |> Option.map previous }

            legacyEvidence <- GameContextEncoding.encode old
            deploymentKey <- ModConductor.Deployment.DeploymentContextId.physicalFingerprint old
            componentRoot <-
                ComponentRoots.legacyRootId workspace old
                |> Option.defaultWith (fun () -> invalidOp "The saved game root is unavailable.")

            editDatabase statePath (fun connection ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE game_contexts SET evidence=$evidence WHERE profile_id=$profile"
                    [ "$evidence", box (GameContextEncoding.encode old)
                      "$profile", box (string profile) ])

            (store.GameContexts :> IGameContexts).Refresh(workspace, profile, context.Revision)
            |> wait
            |> result
            |> ignore

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace profile

            for artifact, storage in
                [ copied, ArtifactStorage.Copy
                  referenced, ArtifactStorage.Reference
                  pendingCopy, ArtifactStorage.Copy ] do
                store.Artifacts.Add(
                    { Id = artifact
                      WorkspaceId = workspace
                      Path = archive
                      Storage = storage },
                    token
                )
                |> wait
                |> result
                |> ignore

            let outputs = store.GeneratedOutputs
            let scope = outputs.Read(workspace, profile, None) |> wait |> result

            let location =
                outputs.Add(output, scope, "Saved output", OutputPurpose.ToolFolder)
                |> wait
                |> result

            File.WriteAllText(Path.Combine(location.PhysicalPath, "generated.txt"), "generated")

            let privateApi = store.ProfileGameData
            let settings = privateApi.Read(workspace, profile) |> wait |> result

            File.WriteAllText(
                Path.Combine(documents store workspace profile, "SkyrimPrefs.ini"),
                "[Display]\r\niSize W=1280\r\n"
            )

            let configured =
                privateApi.Edit(
                    { Id = Guid.NewGuid()
                      Expected = settings.Reference
                      Options = { Settings = true; Saves = true }
                      InitialSaves = InitialSaves.Empty
                      DisabledFiles = DisabledFiles.Keep },
                    ignore,
                    token
                )
                |> wait
                |> result

            store.ApplyProfileDataAtCheckpoint(
                Guid.NewGuid(),
                workspace,
                profile,
                configured.State.Reference.Revision,
                token,
                ignore
            )
            |> wait
            |> result
            |> ignore

            let gameView =
                GameViews.rootPath (StorageWorker.select root |> RootSelection.path) profile

            Directory.CreateDirectory(Path.Combine(gameView, "Data")) |> ignore
            File.WriteAllText(Path.Combine(gameView, "Data", "input.txt"), "original input")
            let read = store.Deployments.Read profile |> wait |> deployment

            let prepared =
                store.Deployments.Prepare(Guid.NewGuid(), read.Sources, ignore, token)
                |> wait
                |> deployment

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> wait
            |> deployment
            |> ignore

        editDatabase statePath (fun connection ->
            Sqlite.execute
                connection
                null
                "UPDATE game_contexts SET evidence=$evidence WHERE profile_id=$profile"
                [ "$evidence", box legacyEvidence; "$profile", box (string profile) ])

        editDatabase statePath (fun connection ->
            Sqlite.execute
                connection
                null
                "UPDATE artifacts SET phase=4 WHERE id=$id"
                [ "$id", box (string pendingCopy) ])

        oldIdentities statePath
        oldDeployments statePath
        oldProfileData statePath

        File.WriteAllLines(
            Path.Combine(area, "ids"),
            [ string workspace
              string profile
              string modId
              string version
              string copied
              string referenced
              string output
              deploymentKey
              string componentRoot
              string legacyDataContext
              string pendingCopy ]
        )

        use child =
            new NativeChild(Environment.ProcessPath, [ "--workspace-reopen-worker"; area ])

        use report = JsonDocument.Parse(child.Line())
        child.Finish()
        writer.WritePropertyName("workspaceReopen")
        report.RootElement.WriteTo writer
