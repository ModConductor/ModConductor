namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Migration
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Workspaces

module MigrationFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private write (path: string) (content: string) =
        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        File.WriteAllText(path, content, UTF8Encoding(false))

    let private bytes (path: string) (content: byte array) =
        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        File.WriteAllBytes(path, content)

    let private source (parent: string) (name: string) =
        let root = Directory.CreateDirectory(Path.Combine(parent, name)).FullName
        let mods = Directory.CreateDirectory(Path.Combine(root, "mods")).FullName
        let profiles = Directory.CreateDirectory(Path.Combine(root, "profiles")).FullName
        let downloads = Directory.CreateDirectory(Path.Combine(root, "downloads")).FullName

        write
            (Path.Combine(root, "ModOrganizer.ini"))
            "[General]\ngameName=Example\ngamePath=@ByteArray(C:\\\\Games\\\\Example)\nselected_profile=@ByteArray(Default)\napi_token=do-not-migrate\n[Settings]\nbase_directory=%BASE_DIR%\nmod_directory=%BASE_DIR%/mods\nprofiles_directory=%BASE_DIR%/profiles\ndownload_directory=%BASE_DIR%/downloads\n"

        write (Path.Combine(root, "categories.dat")) "1|Visuals|0\n2|Textures|1\n"
        write (Path.Combine(root, "nexuscatmap.dat")) "2|Textures|5\n"
        let alpha = Directory.CreateDirectory(Path.Combine(mods, "Alpha")).FullName

        write
            (Path.Combine(alpha, "meta.ini"))
            "[General]\nversion=1.2\nnotes=Useful notes\ncomments=Migration comment\ncategory=2\ninstallationFile=legacy.zip\nnexus_api_key=do-not-migrate\n[installedFiles]\n1\\modid=42\n1\\fileid=7\nsize=1\n"

        write (Path.Combine(alpha, "textures", "alpha.txt")) "alpha payload"
        Directory.CreateDirectory(Path.Combine(mods, "Divider_separator")) |> ignore
        let backup = Directory.CreateDirectory(Path.Combine(mods, "Alpha backup1")).FullName
        write (Path.Combine(backup, "old.txt")) "backup payload"

        for profile, list in
            [ "Default", "+Alpha\n-Divider_separator\n"
              "Testing", "Alpha\n+Divider_separator\n" ] do
            let directory = Directory.CreateDirectory(Path.Combine(profiles, profile)).FullName
            write (Path.Combine(directory, "modlist.txt")) list

            write
                (Path.Combine(directory, "settings.ini"))
                "[General]\nLocalSaves=false\nLocalSettings=false\n"

        bytes (Path.Combine(downloads, "alpha.zip")) [| 80uy; 75uy; 3uy; 4uy; 1uy; 2uy |]

        write
            (Path.Combine(downloads, "alpha.zip.meta"))
            "[General]\ninstalled=false\nmodID=42\nfileID=7\nurl=https://example.invalid/alpha.zip?token=do-not-migrate\nauthor=Example\napiKey=do-not-migrate\n"

        bytes (Path.Combine(downloads, "partial.zip.unfinished")) [| 1uy; 2uy; 3uy |]

        write
            (Path.Combine(downloads, "partial.zip.unfinished.meta"))
            "[General]\npaused=true\nurl=https://example.invalid/partial.zip?key=do-not-migrate\n"

        root

    let private hashes root =
        Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories)
        |> Seq.map (fun path ->
            Path.GetRelativePath(root, path),
            Convert.ToHexStringLower(SHA256.HashData(File.ReadAllBytes path)))
        |> Map.ofSeq

    let private createWorkspace (store: OperationStore) parent name =
        let root = Directory.CreateDirectory(Path.Combine(parent, name)).FullName
        let id = Guid.NewGuid()

        (store.Workspaces :> IWorkspaceState).Create(id, name, StorageWorker.select root)
        |> wait
        |> result
        |> ignore

        id, root

    let private empty (store: OperationStore) workspace =
        let page =
            (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

        let mods = (store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result

        let artifacts =
            store.Artifacts.List(workspace, None, false, CancellationToken.None)
            |> wait
            |> result

        page.Profiles.IsEmpty && mods.Entries.IsEmpty && artifacts.Entries.IsEmpty

    let worker (mode: string) (state: string) (source: string) (workspace: string) =
        let checkpoint value =
            if value = mode then
                StorageWorker.pause ()

        use store = new OperationStore(state, migrationCheckpoint = checkpoint)

        store.MigrateAtCheckpoint(
            { WorkspaceId = Guid.Parse workspace
              SourceFolder = source },
            ignore,
            CancellationToken.None,
            checkpoint
        )
        |> wait
        |> ignore

    let private crashWindow parent mode =
        let area = Directory.CreateDirectory(Path.Combine(parent, mode)).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let sourceRoot = source area "source"

        let workspace, root =
            use store = new OperationStore(state)
            createWorkspace store area "workspace"

        let workerArguments =
            [ "--migration-worker"; mode; state; sourceRoot; string workspace ]

        let workerArguments =
            if Path.GetFileNameWithoutExtension(Environment.ProcessPath) = "dotnet" then
                Environment.GetCommandLineArgs()[0] :: workerArguments
            else
                workerArguments

        use child = new NativeChild(Environment.ProcessPath, workerArguments)

        if child.Line() <> "ready" then
            invalidOp "The migration checkpoint was not reached."

        child.Terminate()

        use recovered = new OperationStore(state)

        let owned =
            Directory.EnumerateFileSystemEntries root
            |> Seq.map Path.GetFileName
            |> Seq.filter (fun name -> name <> ".mod-conductor-root")
            |> Seq.toList

        if mode = "after-commit" then
            not (empty recovered workspace)
            && owned.Length = 1
            && owned[0].StartsWith(".mod-conductor-library-", StringComparison.Ordinal)
        else
            empty recovered workspace && owned.IsEmpty

    let private existingLibrary state workspace =
        use connection =
            new SqliteConnection("Data Source=" + Path.Combine(state, "state.db"))

        connection.Open()
        use command = connection.CreateCommand()

        command.CommandText <-
            "INSERT INTO mod_libraries(workspace_id,directory,owner,phase,identity) VALUES($workspace,'existing-library','fixture',2,NULL)"

        command.Parameters.AddWithValue("$workspace", string workspace) |> ignore
        command.ExecuteNonQuery() |> ignore

    let private emptyCounts state workspace =
        use connection =
            new SqliteConnection("Data Source=" + Path.Combine(state, "state.db"))

        connection.Open()
        use command = connection.CreateCommand()

        command.CommandText <-
            "SELECT (SELECT count(*) FROM profiles WHERE workspace_id=$workspace) + (SELECT count(*) FROM mods WHERE workspace_id=$workspace) + (SELECT count(*) FROM artifacts WHERE workspace_id=$workspace), (SELECT count(*) FROM mod_libraries WHERE workspace_id=$workspace)"

        command.Parameters.AddWithValue("$workspace", string workspace) |> ignore
        use reader = command.ExecuteReader()
        reader.Read() |> ignore
        reader.GetInt64(0), reader.GetInt64(1)

    let private migrate
        (store: OperationStore)
        (workspace: Guid)
        (sourceRoot: string)
        (token: CancellationToken)
        (progress: Progress -> unit)
        =
        ModOrganizer.migrate
            (store.Migrations)
            { WorkspaceId = workspace
              SourceFolder = sourceRoot }
            progress
            token
        |> wait

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("migration")
        let area = Directory.CreateDirectory(Path.Combine(primary, "migration")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let sourceRoot = source area "source"
        let before = hashes sourceRoot

        let workspace, workspaceRoot =
            use store = new OperationStore(state)
            createWorkspace store area "workspace"

        do
            use store = new OperationStore(state)

            let migrated =
                migrate store workspace sourceRoot CancellationToken.None ignore |> result

            writer.WriteBoolean(
                "counts",
                migrated.Profiles = 2 && migrated.Mods = 3 && migrated.Artifacts = 2
            )

            writer.WriteBoolean("sourceUnchanged", (before = hashes sourceRoot))

            let page =
                (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

            writer.WriteBoolean(
                "selectedProfile",
                page.Workspace.SelectedProfile.Value.Name = "Default"
            )

            let mods = (store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result

            writer.WriteBoolean(
                "modKinds",
                mods.Entries |> List.map _.Kind |> Set.ofList =
                    set [ ModKind.Regular; ModKind.Separator; ModKind.Backup ]
            )

            writer.WriteBoolean(
                "modsReady",
                mods.Entries |> List.forall (fun item -> item.Status = InventoryStatus.Ready)
            )

            let query =
                { Text = ""
                  Mode = FilterMode.All
                  Filters = []
                  View = OrganizationView.Flat
                  Sort = OrganizationSort.Priority }

            let order =
                (store.ModOrganization :> IModOrganization)
                    .Query(page.Workspace.SelectedProfile.Value.Id, query, None, None)
                |> wait
                |> result

            let ordered =
                order.Entries |> List.filter (fun item -> item.Entry.Mod.Kind <> ModKind.Backup)

            writer.WriteBoolean(
                "reversePriority",
                ordered.Length = 2
                && ordered[0].Entry.Mod.Kind = ModKind.Separator
                && match ordered[1].Entry.Selection with
                   | SelectionState.Managed(1, true) -> true
                   | _ -> false
            )

            let categories =
                (store.ModOrganization :> IModOrganization).Categories(workspace, None, None, None)
                |> wait
                |> result

            writer.WriteBoolean(
                "categories",
                categories.Entries.Length = 1 && categories.Entries[0].Label = "Visuals"
            )

            let artifacts =
                store.Artifacts.List(workspace, None, false, CancellationToken.None)
                |> wait
                |> result

            let artifact =
                artifacts.Entries |> List.find (fun item -> item.OriginalName = "alpha.zip")

            let partial =
                artifacts.Entries |> List.find (fun item -> item.OriginalName = "partial.zip")

            writer.WriteBoolean(
                "artifactOwned",
                artifact.Storage = ArtifactStorage.Copy
                && artifact.State = ArtifactState.Installed
                && artifact.Path.StartsWith(workspaceRoot, StringComparison.Ordinal)
                && not (artifact.Path.StartsWith(sourceRoot, StringComparison.Ordinal))
                && partial.State = ArtifactState.Incomplete
                && partial.Download.Value.State = DownloadState.Paused
                && partial.Path.StartsWith(workspaceRoot, StringComparison.Ordinal)
            )

            writer.WriteBoolean(
                "emptyTargetGuard",
                match migrate store workspace sourceRoot CancellationToken.None ignore with
                | Error Error.TargetNotEmpty -> true
                | _ -> false
            )

        let stateText =
            File.ReadAllBytes(Path.Combine(state, "state.db")) |> Encoding.Latin1.GetString

        let ownedText =
            Directory.EnumerateFiles(workspaceRoot, "*", SearchOption.AllDirectories)
            |> Seq.map (File.ReadAllBytes >> Encoding.Latin1.GetString)
            |> String.concat ""

        writer.WriteBoolean(
            "credentialsExcluded",
            not (stateText.Contains "do-not-migrate")
            && not (ownedText.Contains "do-not-migrate")
        )

        do
            use restarted = new OperationStore(state)
            writer.WriteBoolean("restartComplete", not (empty restarted workspace))

        let cancelArea = Directory.CreateDirectory(Path.Combine(area, "cancel")).FullName

        let cancelState =
            Directory.CreateDirectory(Path.Combine(cancelArea, "state")).FullName

        let cancelWorkspace =
            use store = new OperationStore(cancelState)
            createWorkspace store cancelArea "workspace" |> fst

        do
            use store = new OperationStore(cancelState)
            use cancellation = new CancellationTokenSource()

            let outcome =
                migrate store cancelWorkspace sourceRoot cancellation.Token (fun _ ->
                    cancellation.Cancel())

            writer.WriteBoolean(
                "cancellation",
                (match outcome with
                 | Error Error.Cancelled -> true
                 | _ -> false)
                && empty store cancelWorkspace
            )

        let changedSource action name =
            let changedArea = Directory.CreateDirectory(Path.Combine(area, name)).FullName
            let changedRoot = source changedArea "source"

            let changedState =
                Directory.CreateDirectory(Path.Combine(changedArea, "state")).FullName

            let changedWorkspace =
                use store = new OperationStore(changedState)
                createWorkspace store changedArea "workspace" |> fst

            use store = new OperationStore(changedState)

            let outcome =
                store.MigrateAtCheckpoint(
                    { WorkspaceId = changedWorkspace
                      SourceFolder = changedRoot },
                    ignore,
                    CancellationToken.None,
                    fun checkpoint ->
                        if checkpoint = "before-source-recheck" then
                            action changedRoot
                )
                |> wait

            (match outcome with
             | Error Error.SourceChanged -> true
             | _ -> false)
            && empty store changedWorkspace

        let addedSource =
            changedSource
                (fun root -> write (Path.Combine(root, "mods", "Alpha", "added.txt")) "added")
                "source-added"

        let removedSource =
            changedSource
                (fun root -> File.Delete(Path.Combine(root, "downloads", "alpha.zip")))
                "source-removed"

        writer.WriteBoolean("sourceManifestChanged", addedSource && removedSource)

        let foreignArea =
            Directory.CreateDirectory(Path.Combine(area, "foreign-root")).FullName

        let foreignState =
            Directory.CreateDirectory(Path.Combine(foreignArea, "state")).FullName

        let foreignWorkspace, foreignRoot =
            use store = new OperationStore(foreignState)
            createWorkspace store foreignArea "workspace"

        write (Path.Combine(foreignRoot, "foreign.txt")) "not managed"

        do
            use store = new OperationStore(foreignState)

            writer.WriteBoolean(
                "foreignRootGuard",
                (match migrate store foreignWorkspace sourceRoot CancellationToken.None ignore with
                 | Error Error.TargetNotEmpty -> true
                 | _ -> false)
                && empty store foreignWorkspace
            )

        let changedTargetArea =
            Directory.CreateDirectory(Path.Combine(area, "changed-target")).FullName

        let changedTargetState =
            Directory.CreateDirectory(Path.Combine(changedTargetArea, "state")).FullName

        let changedTargetWorkspace, changedTargetRoot =
            use store = new OperationStore(changedTargetState)
            createWorkspace store changedTargetArea "workspace"

        do
            use store = new OperationStore(changedTargetState)

            let outcome =
                store.MigrateAtCheckpoint(
                    { WorkspaceId = changedTargetWorkspace
                      SourceFolder = sourceRoot },
                    ignore,
                    CancellationToken.None,
                    fun checkpoint ->
                        if checkpoint = "before-publication" then
                            write (Path.Combine(changedTargetRoot, "foreign.txt")) "not managed"
                )
                |> wait

            let published =
                Directory.EnumerateFileSystemEntries changedTargetRoot
                |> Seq.map Path.GetFileName
                |> Seq.exists (fun name ->
                    name.StartsWith(".mod-conductor-library-", StringComparison.Ordinal))

            writer.WriteBoolean(
                "targetRecheck",
                (match outcome with
                 | Error Error.TargetNotEmpty -> true
                 | _ -> false)
                && not published
                && empty store changedTargetWorkspace
            )

        let libraryArea =
            Directory.CreateDirectory(Path.Combine(area, "empty-library")).FullName

        let libraryState =
            Directory.CreateDirectory(Path.Combine(libraryArea, "state")).FullName

        let libraryWorkspace =
            use store = new OperationStore(libraryState)
            createWorkspace store libraryArea "workspace" |> fst

        existingLibrary libraryState libraryWorkspace

        do
            use store = new OperationStore(libraryState)

            let outcome =
                migrate store libraryWorkspace sourceRoot CancellationToken.None ignore

            let data, libraries = emptyCounts libraryState libraryWorkspace

            writer.WriteBoolean(
                "emptyLibraryGuard",
                (match outcome with
                 | Error Error.TargetNotEmpty -> true
                 | _ -> false)
                && data = 0L
                && libraries = 1L
            )

        let unsupportedArea =
            Directory.CreateDirectory(Path.Combine(area, "unsupported")).FullName

        let unsupportedSource = source unsupportedArea "source"
        write (Path.Combine(unsupportedSource, "profiles", "Default", "plugins.txt")) "Alpha.esp\n"

        let unsupportedState =
            Directory.CreateDirectory(Path.Combine(unsupportedArea, "state")).FullName

        let unsupportedWorkspace =
            use store = new OperationStore(unsupportedState)
            createWorkspace store unsupportedArea "workspace" |> fst

        do
            use store = new OperationStore(unsupportedState)

            let outcome =
                migrate store unsupportedWorkspace unsupportedSource CancellationToken.None ignore

            writer.WriteBoolean(
                "unsupportedBeforeMutation",
                (match outcome with
                 | Error(Error.UnsupportedData _) -> true
                 | _ -> false)
                && empty store unsupportedWorkspace
            )

        let missingArea = Directory.CreateDirectory(Path.Combine(area, "missing")).FullName
        let missingSource = source missingArea "source"
        File.Delete(Path.Combine(missingSource, "profiles", "Default", "modlist.txt"))

        let missingState =
            Directory.CreateDirectory(Path.Combine(missingArea, "state")).FullName

        let missingWorkspace =
            use store = new OperationStore(missingState)
            createWorkspace store missingArea "workspace" |> fst

        do
            use store = new OperationStore(missingState)

            writer.WriteBoolean(
                "missingFile",
                (match
                    migrate store missingWorkspace missingSource CancellationToken.None ignore
                 with
                 | Error(Error.InvalidSource _) -> true
                 | _ -> false)
                && empty store missingWorkspace
            )

        if OperatingSystem.IsLinux() then
            let collisionArea =
                Directory.CreateDirectory(Path.Combine(area, "collision")).FullName

            let collisionSource = source collisionArea "source"

            Directory.CreateDirectory(Path.Combine(collisionSource, "mods", "alpha"))
            |> ignore

            let collisionState =
                Directory.CreateDirectory(Path.Combine(collisionArea, "state")).FullName

            let collisionWorkspace =
                use store = new OperationStore(collisionState)
                createWorkspace store collisionArea "workspace" |> fst

            use store = new OperationStore(collisionState)

            writer.WriteBoolean(
                "caseCollision",
                match
                    migrate store collisionWorkspace collisionSource CancellationToken.None ignore
                with
                | Error(Error.CaseCollision _) -> true
                | _ -> false
            )
        else
            writer.WriteBoolean("caseCollision", true)

        let linkArea = Directory.CreateDirectory(Path.Combine(area, "link")).FullName
        let linkSource = source linkArea "source"

        File.CreateSymbolicLink(
            Path.Combine(linkSource, "mods", "Alpha", "linked.txt"),
            Path.Combine(linkSource, "mods", "Alpha", "textures", "alpha.txt")
        )
        |> ignore

        let linkState = Directory.CreateDirectory(Path.Combine(linkArea, "state")).FullName

        let linkWorkspace =
            use store = new OperationStore(linkState)
            createWorkspace store linkArea "workspace" |> fst

        do
            use store = new OperationStore(linkState)

            writer.WriteBoolean(
                "unsafeLink",
                match migrate store linkWorkspace linkSource CancellationToken.None ignore with
                | Error(Error.UnsafeSource _) -> true
                | _ -> false
            )

        writer.WriteBoolean("crashBeforePublication", crashWindow area "before-publication")
        writer.WriteBoolean("crashAfterPublication", crashWindow area "after-publication")
        writer.WriteBoolean("crashBeforeCommit", crashWindow area "before-commit")
        writer.WriteBoolean("crashAfterCommit", crashWindow area "after-commit")
        writer.WriteEndObject()
