namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open System.Text.Json
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Deployment
open ModConductor.Engine
open ModConductor.GameContexts
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module WorkspaceDeletionFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private mkdir path =
        Directory.CreateDirectory(path).FullName

    let private write folder name (value: string) =
        let path = Path.Combine(folder, name)
        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        File.WriteAllText(path, value)
        path

    let private privateData (store: OperationStore) workspace profile =
        let current = store.ProfileGameData.Read(workspace, profile) |> wait |> result

        store.ProfileGameData.Edit(
            { Id = Guid.NewGuid()
              Expected = current.Reference
              Options = { Settings = true; Saves = true }
              InitialSaves = InitialSaves.Empty
              DisabledFiles = DisabledFiles.Keep },
            ignore,
            token
        )
        |> wait
        |> result
        |> _.State

    let private populate (store: OperationStore) workspace profile root outside =
        let source = mkdir (Path.Combine(root, "foreign-source"))
        write source "managed.txt" "installed mod" |> ignore
        let mods = store.ModLibrary :> IModLibrary
        let modId, version = Guid.NewGuid(), Guid.NewGuid()

        let registered =
            mods.Register(
                workspace,
                modId,
                { Name = "Managed"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(ModKind.Regular, DeploymentFixtureData.path "foreign-source")
            )
            |> wait
            |> result

        mods.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
        let selection = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, selection.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let archive = write outside "download.zip" "external download bytes"

        let copies =
            [ ArtifactStorage.Copy; ArtifactStorage.Reference ]
            |> List.map (fun storage ->
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = archive
                      Storage = storage },
                    token
                )
                |> wait
                |> result)

        let copied = copies |> List.find (fun entry -> entry.Storage = ArtifactStorage.Copy)

        store.Artifacts.Link(
            { WorkspaceId = workspace
              Id = copied.Id
              Revision = copied.Revision },
            modId,
            version,
            false
        )
        |> wait
        |> result
        |> ignore

        let scope = store.GeneratedOutputs.Read(workspace, profile, None) |> wait |> result

        let output =
            store.GeneratedOutputs.Add(
                Guid.NewGuid(),
                scope,
                "Tool output",
                OutputPurpose.ToolFolder
            )
            |> wait
            |> result

        write output.PhysicalPath "generated.txt" "generated output" |> ignore
        let image = write outside "thumbnail.png" "owned thumbnail bytes"

        store.ProfileImages.Set(workspace, profile, Some image)
        |> wait
        |> result
        |> ignore

        archive, copied.Path, output.PhysicalPath

    let private retainedRows state workspace =
        use connection =
            new SqliteConnection("Data Source=" + Path.Combine(state, "state.db"))

        connection.Open()
        use query = connection.CreateCommand()

        query.CommandText <-
            "SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%'"

        use reader = query.ExecuteReader()

        let tables =
            [ while reader.Read() do
                  yield reader.GetString 0 ]

        reader.Close()
        let mutable total = 0L

        for table in tables do
            use columns = connection.CreateCommand()

            columns.CommandText <-
                "SELECT name FROM pragma_table_info($table) WHERE name='workspace_id'"

            columns.Parameters.AddWithValue("$table", table) |> ignore

            if not (isNull (columns.ExecuteScalar())) then
                use count = connection.CreateCommand()

                count.CommandText <-
                    "SELECT count(*) FROM " + table + " WHERE workspace_id=$workspace"

                count.Parameters.AddWithValue("$workspace", string workspace) |> ignore
                total <- total + (count.ExecuteScalar() :?> int64)

        use foreign = connection.CreateCommand()
        foreign.CommandText <- "PRAGMA foreign_key_check"
        use violations = foreign.ExecuteReader()
        total = 0L && not (violations.Read())

    let private scenario (writer: Utf8JsonWriter) parent name moveSaves active missingFolder =
        let area = mkdir (Path.Combine(parent, name))
        let statePath = mkdir (Path.Combine(area, "state"))
        let root = mkdir (Path.Combine(area, "workspace"))
        let outside = mkdir (Path.Combine(area, "downloads"))
        let foreign = write root "foreign.txt" "foreign root data"
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        BethesdaSamples.requiredBaseFiles game

        File.WriteAllBytes(
            Path.Combine(game, "Data", "Private.esp"),
            BethesdaSamples.header 0u 1.7f [ "Skyrim.esm" ] false
        )

        let originalGame =
            write (Path.Combine(game, "Data")) "original.txt" "game installation bytes"

        let workspace, first, second = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        use store = new OperationStore(statePath)
        let ws = store.Workspaces :> IWorkspaceState

        let created =
            ws.Create(workspace, "Delete fixture", StorageWorker.select root)
            |> wait
            |> result

        let added =
            ws.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = first; Name = "First" }
            )
            |> wait
            |> result

        ws.Edit(
            workspace,
            added.Workspace.Revision,
            ProfileEdit.Create { Id = second; Name = "Second" }
        )
        |> wait
        |> result
        |> ignore

        for profile in [ first; second ] do
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
            |> ignore

            DeploymentFixtureData.isolateWindowsGameLocations store statePath area workspace profile

        let binding =
            (store.GameContexts :> IGameContexts).Read(workspace, first)
            |> wait
            |> result
            |> _.Binding
            |> Option.get

        let documents =
            match binding.Evidence.Locations.Documents with
            | Location.Located(path, _) -> path
            | Location.Unavailable detail -> invalidOp detail

        let saves =
            match binding.Evidence.Locations.Saves with
            | Location.Located(path, _) -> path
            | Location.Unavailable detail -> invalidOp detail

        let local =
            match binding.Evidence.Locations.LocalAppData with
            | Location.Located(path, _) -> path
            | Location.Unavailable detail -> invalidOp detail

        let pluginList = write local "plugins.txt" "# global plugin order\n"
        let beforePlugins = File.ReadAllText pluginList
        let ini = write documents "Skyrim.ini" "[General]\nsLocalSavePath=Saves\\\n"
        let prefs = write documents "SkyrimPrefs.ini" "[Display]\niSize W=1280\n"

        if not missingFolder then
            write saves "slot.ESS" "global save" |> ignore
            write saves "slot.SKSE" "global companion" |> ignore

        let firstData = privateData store workspace first
        let secondData = privateData store workspace second

        for data, label in [ firstData, "first"; secondData, "second" ] do
            write data.SavesPath "slot.ess" (label + " save") |> ignore
            write data.SavesPath "slot.skse" (label + " companion") |> ignore
            write data.SettingsPath "SkyrimPrefs.ini" "[Display]\niSize W=1920\n" |> ignore

        let archive, copyPath, outputPath = populate store workspace first root outside
        let beforeIni = File.ReadAllText ini
        let beforePrefs = File.ReadAllText prefs

        if active then
            let headers = store.Plugins.Scan(first, token) |> wait |> result
            let order = store.PluginOrders.Read(workspace, first, headers.Id) |> wait |> result

            store.PluginOrders.Change(
                order.Reference,
                headers.Id,
                ModConductor.Bethesda.PluginOrderChange.Enable([ "Private.esp" ], true)
            )
            |> wait
            |> result
            |> ignore

            let backend = store.Deployments
            let read = backend.Read first |> wait |> result

            let prepared =
                backend.Prepare(Guid.NewGuid(), read.Sources, ignore, token) |> wait |> result

            backend.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> wait
            |> result
            |> ignore

            let session = store.ProfileGameData :?> ProfileGameDataSession
            let current = store.ProfileGameData.Read(workspace, first) |> wait |> result

            session.ApplyForLaunch(
                Guid.NewGuid(),
                workspace,
                first,
                current.Revision,
                token,
                (fun _ -> Task.FromResult())
            )
            |> wait
            |> result
            |> ignore

            if
                (store.ProfileGameData.Read(workspace, first) |> wait |> result).InUse
                <> Some first
            then
                invalidOp "Private routing was not applied."

            if File.ReadAllText pluginList = beforePlugins then
                invalidOp "Private plugin order was not applied."

        if missingFolder then
            Directory.Delete saves

        let before = ws.Read(workspace, None) |> wait |> result
        let info = ws.DeletionInfo workspace |> wait |> result
        writer.WriteStartObject name

        writer.WriteBoolean(
            "privateSaveDestination",
            info.HasPrivateSaves && info.SaveDestinations = [ saves ]
        )

        let busySafe =
            use lease =
                (store.Deployments :?> DeploymentBackend).TryAcquireWorkspace workspace
                |> Option.get

            ws.Delete(workspace, before.Workspace.Revision, moveSaves, token) |> wait = Error
                WorkspaceError.Busy
            && File.Exists copyPath
            && File.Exists foreign

        writer.WriteBoolean("busyRefusesWithoutDeletion", busySafe)

        let retryableFailure =
            if name <> "moveKeepBoth" || not (OperatingSystem.IsLinux()) then
                true
            else
                let permissions = File.GetUnixFileMode root

                try
                    File.SetUnixFileMode(root, UnixFileMode.UserRead ||| UnixFileMode.UserExecute)

                    let failed =
                        ws.Delete(workspace, before.Workspace.Revision, moveSaves, token) |> wait

                    Result.isError failed
                    && ((ws.Recent None |> wait).Workspaces
                        |> List.exists (fun item -> item.Id = workspace))
                    && File.ReadAllText foreign = "foreign root data"
                    && File.ReadAllText(Path.Combine(saves, "slot.ESS")) = "global save"
                finally
                    File.SetUnixFileMode(root, permissions)

        writer.WriteBoolean("failedDeletionRetainsRegistration", retryableFailure)

        ws.Delete(workspace, before.Workspace.Revision, moveSaves, token)
        |> wait
        |> result
        |> ignore

        writer.WriteBoolean(
            "ownedRemoved",
            not (File.Exists copyPath)
            && not (Directory.Exists outputPath)
            && not (Directory.Exists firstData.SavesPath)
            && not (Directory.Exists secondData.SavesPath)
            && not (
                Directory.Exists(Path.Combine(statePath, "profile-images", workspace.ToString "N"))
            )
            && not (File.Exists(Path.Combine(root, ".mod-conductor-root")))
            && (Directory.GetDirectories root
                |> Array.forall (fun path -> Path.GetFileName path = "foreign-source"))
        )

        writer.WriteBoolean(
            "registrationRemoved",
            (ws.Recent None |> wait).Workspaces.IsEmpty && retainedRows statePath workspace
        )

        writer.WriteBoolean(
            "foreignPreserved",
            File.ReadAllText foreign = "foreign root data"
            && File.ReadAllText archive = "external download bytes"
            && File.ReadAllText originalGame = "game installation bytes"
            && File.ReadAllText(Path.Combine(root, "foreign-source", "managed.txt")) = "installed mod"
        )

        let entries =
            if Directory.Exists saves then
                Directory.GetFiles saves
            else
                [||]

        let movedPairs =
            if moveSaves then
                entries
                |> Array.filter (fun path ->
                    Path.GetExtension(path).Equals(".ess", StringComparison.OrdinalIgnoreCase))
                |> Array.filter (fun path -> File.ReadAllText path <> "global save")
                |> Array.map (fun path ->
                    File.ReadAllText path, File.ReadAllText(Path.ChangeExtension(path, ".skse")))
                |> Set.ofArray
                |> (=) (
                    Set.ofList
                        [ "first save", "first companion"; "second save", "second companion" ]
                )
            else
                entries.Length = 2

        writer.WriteBoolean("saveDisposition", movedPairs)

        writer.WriteBoolean(
            "globalPreserved",
            missingFolder
            || (File.ReadAllText(Path.Combine(saves, "slot.ESS")) = "global save"
                && File.ReadAllText(Path.Combine(saves, "slot.SKSE")) = "global companion")
        )

        writer.WriteBoolean(
            "routingRestored",
            File.ReadAllText ini = beforeIni
            && File.ReadAllText prefs = beforePrefs
            && File.ReadAllText pluginList = beforePlugins
            && (Directory.GetFileSystemEntries documents
                |> Array.forall (fun path ->
                    not (Path.GetFileName(path).StartsWith(".mod-conductor-saves-"))))
        )

        writer.WriteEndObject()

    let private cancelledSetup (writer: Utf8JsonWriter) parent =
        let area = mkdir (Path.Combine(parent, "cancelled-setup"))
        let state = mkdir (Path.Combine(area, "state"))
        use store = new OperationStore(state)

        let workspace, profile, game, _, context =
            SkyrimFixtureWorkspace.create store state area "Cancelled setup" "workspace" "game" true

        context |> result |> ignore
        let root = Path.Combine(area, "workspace")
        let foreign = write root "foreign.txt" "foreign root data"
        let scope = store.GeneratedOutputs.Read(workspace, profile, None) |> wait |> result

        let output =
            store.GeneratedOutputs.Add(Guid.NewGuid(), scope, "Output", OutputPurpose.ToolFolder)
            |> wait
            |> result

        let owned = write output.PhysicalPath "generated.txt" "generated output"
        let workflow = SkyrimSetupFixtures.WorkflowState()
        workflow.HoldSkse()
        let dependencies = workflow.Dependencies

        let started =
            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

        let tracked =
            { dependencies with
                StartSkse =
                    fun workspace profile ->
                        task {
                            let! value = dependencies.StartSkse workspace profile
                            started.SetResult()
                            return value
                        } }

        use coordinator = new SkyrimSetupCoordinator(store, tracked)

        coordinator.Start(
            workspace,
            profile,
            { SetupSelection.none with
                Skse = SetupAction.Install },
            token
        )
        |> wait
        |> result
        |> ignore

        if not (started.Task.Wait(TimeSpan.FromSeconds 10.)) then
            invalidOp "The setup did not reach the active child operation."

        let ws = store.Workspaces :> IWorkspaceState
        let before = ws.Read(workspace, None) |> wait |> result
        coordinator.Cancel(workspace, profile, token) |> wait |> ignore
        let pending = store.SkyrimSetups.Read(workspace, profile) |> wait |> Option.get

        writer.WriteBoolean(
            "unfinishedCancellationPreservesWorkspace",
            pending.CancelRequested
            && not pending.Cancelled
            && ws.Delete(workspace, before.Workspace.Revision, false, token) |> wait = Error
                WorkspaceError.Busy
            && File.ReadAllText owned = "generated output"
            && File.ReadAllText foreign = "foreign root data"
            && ((ws.Recent None |> wait).Workspaces
                |> List.exists (fun value -> value.Id = workspace))
        )

        workflow.CompleteSkse()
        coordinator.Cancel(workspace, profile, token) |> wait |> ignore
        let terminal = store.SkyrimSetups.Read(workspace, profile) |> wait |> Option.get

        let deleted = ws.Delete(workspace, before.Workspace.Revision, false, token) |> wait

        writer.WriteBoolean(
            "cancelledSetupAllowsDeletion",
            terminal.Cancelled
            && not terminal.Completed
            && not terminal.CancelRequested
            && deleted = Ok()
            && (ws.Recent None |> wait).Workspaces.IsEmpty
            && (store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone
            && not (File.Exists owned)
            && not (File.Exists(Path.Combine(root, ".mod-conductor-root")))
            && File.ReadAllText foreign = "foreign root data"
            && File.Exists(Path.Combine(game, "SkyrimSE.exe"))
        )

    let observe (writer: Utf8JsonWriter) parent =
        writer.WriteStartObject "workspaceDeletion"
        scenario writer parent "discardActive" false true false
        scenario writer parent "moveKeepBoth" true false false
        scenario writer parent "createSaveFolder" true false true
        cancelledSetup writer parent
        let area = mkdir (Path.Combine(parent, "empty"))
        let root = mkdir (Path.Combine(area, "workspace"))
        use store = new OperationStore(Path.Combine(area, "state"))
        let ws = store.Workspaces :> IWorkspaceState
        let id = Guid.NewGuid()
        let created = ws.Create(id, "Empty", StorageWorker.select root) |> wait |> result

        ws.Delete(id, created.Workspace.Revision, false, token)
        |> wait
        |> result
        |> ignore

        writer.WriteBoolean(
            "emptyRootRemoved",
            not (Directory.Exists root) && (ws.Recent None |> wait).Workspaces.IsEmpty
        )

        writer.WriteEndObject()
