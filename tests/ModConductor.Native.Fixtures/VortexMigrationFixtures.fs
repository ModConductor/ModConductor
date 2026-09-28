namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArtifactLibrary
open ModConductor.Migration
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Workspaces

module VortexMigrationFixtures =
    type private Input =
        { Backup: string
          ProfileId: string
          Staging: string
          Downloads: string
          Game: string }

    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private write (path: string) (content: string) =
        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        File.WriteAllText(path, content, UTF8Encoding(false))

    let private bytes (path: string) (content: byte array) =
        Directory.CreateDirectory(Path.GetDirectoryName path) |> ignore
        File.WriteAllBytes(path, content)

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

    let private backupJson
        archiveLength
        archiveMd5
        loadOrder
        downloadState
        includeDownload
        ruleType
        =
        let loadOrderValue =
            if loadOrder then
                "\"loadOrder\":{\"p1\":{\"beta\":{\"pos\":0,\"enabled\":false},\"alpha\":{\"pos\":1,\"enabled\":true}}},"
            else
                ""

        let download =
            if includeDownload then
                "\"archive-alpha\":{\"id\":\"archive-alpha\",\"state\":\""
                + downloadState
                + "\",\"urls\":[\"https://user:secret@example.invalid/blocked\",\"https://example.invalid/alpha.zip?token=do-not-migrate\"],\"localPath\":\"alpha.zip\",\"game\":[\"game\"],\"modInfo\":{\"nexus\":{\"ids\":{\"modId\":42,\"fileId\":7}}},\"fileMD5\":\""
                + archiveMd5
                + "\",\"size\":"
                + string archiveLength
                + ",\"received\":"
                + string archiveLength
                + ",\"verified\":"
                + string archiveLength
                + "}"
            else
                ""

        """{
  "app":{"appVersion":"2.6.3","extensions":{"private-extension":{"path":"do-not-migrate.exe"}}},
  "user":{"multiUser":false},
  "settings":{"tools":{"private-tool":{"path":"do-not-migrate.exe"}}},
  "confidential":{"account":{"apiKey":"do-not-migrate"}},
  "persistent":{
    "profiles":{
      "p1":{"id":"p1","gameId":"game","name":"Selected","modState":{"alpha":{"enabled":true,"enabledTime":1},"beta":{"enabled":false,"enabledTime":1}},"lastActivated":1},
      "p2":{"id":"p2","gameId":"game","name":"Other","modState":{"alpha":{"enabled":false,"enabledTime":1}},"lastActivated":1}
    },
    "mods":{"game":{
      "alpha":{"id":"alpha","state":"installed","type":"","archiveId":"archive-alpha","installationPath":"Alpha","attributes":{"name":"Alpha Mod","version":"1.2","source":"nexus","fileName":"alpha.zip","fileSize":ARCHIVE_LENGTH,"fileMD5":"ARCHIVE_MD5","modId":42,"fileId":7,"category":"1"},"rules":[{"type":"RULE_TYPE","reference":{"id":"beta"}}]},
      "beta":{"id":"beta","state":"installed","type":"","installationPath":"Beta","attributes":{"name":"Beta Mod","version":"2.0","category":1},"rules":[]},
      "gamma":{"id":"gamma","state":"installed","type":"","installationPath":"Gamma","attributes":{"name":"Gamma Mod","version":"3.0"},"rules":[]}
    }},
    LOAD_ORDER
    "categories":{"game":{"1":{"name":"Visuals","parentCategory":"0","order":0}}},
    "downloads":{"files":{DOWNLOAD}}
  }
}
"""
            .Replace("ARCHIVE_LENGTH", string archiveLength, StringComparison.Ordinal)
            .Replace("ARCHIVE_MD5", archiveMd5, StringComparison.Ordinal)
            .Replace("RULE_TYPE", ruleType, StringComparison.Ordinal)
            .Replace("LOAD_ORDER", loadOrderValue, StringComparison.Ordinal)
            .Replace("DOWNLOAD", download, StringComparison.Ordinal)

    let private source parent name loadOrder downloadState includeDownload ruleType =
        let root = Directory.CreateDirectory(Path.Combine(parent, name)).FullName

        let staging =
            Directory.CreateDirectory(Path.Combine(root, "custom-staging")).FullName

        let downloads =
            Directory.CreateDirectory(Path.Combine(root, "custom-downloads")).FullName

        let game = Directory.CreateDirectory(Path.Combine(root, "game")).FullName
        write (Path.Combine(staging, "Alpha", "textures", "alpha.txt")) "alpha payload"
        write (Path.Combine(staging, "Beta", "beta.txt")) "beta payload"
        write (Path.Combine(staging, "Gamma", "gamma.txt")) "gamma payload"
        let archive = [| 80uy; 75uy; 3uy; 4uy; 1uy; 2uy |]
        bytes (Path.Combine(downloads, "alpha.zip")) archive
        write (Path.Combine(game, "game.exe")) "game unchanged"
        let md5 = Convert.ToHexStringLower(MD5.HashData archive)
        let backup = Path.Combine(root, "backup.json")

        write
            backup
            (backupJson archive.Length md5 loadOrder downloadState includeDownload ruleType)

        { Backup = backup
          ProfileId = "p1"
          Staging = staging
          Downloads = downloads
          Game = game }

    let private request workspace input : Vortex.Request =
        { WorkspaceId = workspace
          BackupFile = input.Backup
          ProfileId = input.ProfileId
          StagingRoot = input.Staging
          DownloadRoot = input.Downloads }

    let private migrate store workspace input token progress =
        Vortex.migrate (store: OperationStore).Migrations (request workspace input) progress token
        |> wait

    let worker
        (mode: string)
        (state: string)
        (backup: string)
        (profile: string)
        (staging: string)
        (downloads: string)
        (workspace: string)
        =
        let checkpoint value =
            if value = mode then
                StorageWorker.pause ()

        use store = new OperationStore(state, migrationCheckpoint = checkpoint)

        let value: Vortex.Request =
            { WorkspaceId = Guid.Parse workspace
              BackupFile = backup
              ProfileId = profile
              StagingRoot = staging
              DownloadRoot = downloads }

        store.MigrateVortexAtCheckpoint(value, ignore, CancellationToken.None, checkpoint)
        |> wait
        |> ignore

    let private crashWindow parent mode =
        let area = Directory.CreateDirectory(Path.Combine(parent, mode)).FullName
        let input = source area "source" false "finished" true "before"
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName

        let workspace, root =
            use store = new OperationStore(state)
            createWorkspace store area "workspace"

        let arguments =
            [ "--vortex-migration-worker"
              mode
              state
              input.Backup
              input.ProfileId
              input.Staging
              input.Downloads
              string workspace ]

        let arguments =
            if Path.GetFileNameWithoutExtension(Environment.ProcessPath) = "dotnet" then
                Environment.GetCommandLineArgs()[0] :: arguments
            else
                arguments

        use child = new NativeChild(Environment.ProcessPath, arguments)

        if child.Line() <> "ready" then
            invalidOp "The Vortex migration checkpoint was not reached."

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

    let private rejection parent name configure expected =
        let area = Directory.CreateDirectory(Path.Combine(parent, name)).FullName
        let input = configure area
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName

        let workspace =
            use store = new OperationStore(state)
            createWorkspace store area "workspace" |> fst

        use store = new OperationStore(state)
        let outcome = migrate store workspace input CancellationToken.None ignore
        expected outcome && empty store workspace

    let private changed parent name action =
        let area = Directory.CreateDirectory(Path.Combine(parent, name)).FullName
        let input = source area "source" false "finished" true "before"
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName

        let workspace =
            use store = new OperationStore(state)
            createWorkspace store area "workspace" |> fst

        use store = new OperationStore(state)

        let outcome =
            store.MigrateVortexAtCheckpoint(
                request workspace input,
                ignore,
                CancellationToken.None,
                fun checkpoint ->
                    if checkpoint = "before-source-recheck" then
                        action input
            )
            |> wait

        (match outcome with
         | Error Error.SourceChanged -> true
         | _ -> false)
        && empty store workspace

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("vortexMigration")

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "vortex-migration")).FullName

        let input = source area "source" true "finished" true "before"
        let sourceBefore = hashes (Path.GetDirectoryName input.Backup)
        let gameBefore = hashes input.Game
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName

        let workspace, workspaceRoot =
            use store = new OperationStore(state)
            createWorkspace store area "workspace"

        do
            use store = new OperationStore(state)
            let choices = Vortex.profiles input.Backup |> result

            writer.WriteBoolean(
                "profiles",
                choices.Length = 2
                && choices |> List.exists (fun item -> item.Id = "p1" && item.Name = "Selected")
            )

            let migrated = migrate store workspace input CancellationToken.None ignore |> result

            writer.WriteBoolean(
                "counts",
                migrated.Profiles = 1 && migrated.Mods = 3 && migrated.Artifacts = 1
            )

            let page =
                (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

            writer.WriteBoolean(
                "selectedProfile",
                page.Profiles.Length = 1
                && page.Workspace.SelectedProfile.Value.Name = "Selected"
            )

            let mods = (store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result
            let alpha = mods.Entries |> List.find (fun item -> item.Metadata.Name = "Alpha Mod")

            writer.WriteBoolean(
                "metadata",
                alpha.Metadata.Version = "1.2"
                && alpha.Metadata.Source = "nexus"
                && alpha.Status = InventoryStatus.Ready
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

            writer.WriteBoolean(
                "loadOrder",
                order.Entries.Length = 3
                && order.Entries[0].Entry.Mod.Metadata.Name = "Beta Mod"
                && order.Entries[0].Entry.Selection = SelectionState.Managed(0, false)
                && order.Entries[1].Entry.Selection = SelectionState.Managed(1, true)
            )

            writer.WriteBoolean(
                "missingProfileState",
                order.Entries[2].Entry.Mod.Metadata.Name = "Gamma Mod"
                && order.Entries[2].Entry.Selection = SelectionState.Managed(2, false)
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

            writer.WriteBoolean(
                "artifact",
                artifacts.Entries.Length = 1
                && artifacts.Entries[0].OriginalName = "alpha.zip"
                && artifacts.Entries[0].Path.StartsWith(workspaceRoot, StringComparison.Ordinal)
                && artifacts.Entries[0].State = ArtifactState.Installed
            )

            writer.WriteBoolean(
                "targetGuard",
                match migrate store workspace input CancellationToken.None ignore with
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
            "excluded",
            not (stateText.Contains "do-not-migrate")
            && not (stateText.Contains "private-extension")
            && not (stateText.Contains "private-tool")
            && not (ownedText.Contains "do-not-migrate")
        )

        do
            use restarted = new OperationStore(state)
            writer.WriteBoolean("restart", not (empty restarted workspace))

        writer.WriteBoolean(
            "sourceUnchanged",
            sourceBefore = hashes (Path.GetDirectoryName input.Backup)
            && gameBefore = hashes input.Game
        )

        let rulesArea = Directory.CreateDirectory(Path.Combine(area, "rule-order")).FullName
        let rulesInput = source rulesArea "source" false "finished" true "before"

        let rulesState =
            Directory.CreateDirectory(Path.Combine(rulesArea, "state")).FullName

        let rulesWorkspace =
            use store = new OperationStore(rulesState)
            createWorkspace store rulesArea "workspace" |> fst

        let rulesOk =
            use store = new OperationStore(rulesState)

            match migrate store rulesWorkspace rulesInput CancellationToken.None ignore with
            | Error _ -> false
            | Ok value ->
                let page =
                    (store.Workspaces :> IWorkspaceState).Read(rulesWorkspace, None)
                    |> wait
                    |> result

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

                value.Mods = 3
                && order.Entries.Length = 3
                && order.Entries[0].Entry.Mod.Metadata.Name = "Alpha Mod"
                && order.Entries[1].Entry.Mod.Metadata.Name = "Beta Mod"
                && order.Entries[2].Entry.Mod.Metadata.Name = "Gamma Mod"
                && order.Entries[2].Entry.Selection = SelectionState.Managed(2, false)

        writer.WriteBoolean("rules", rulesOk)

        writer.WriteBoolean(
            "missingDownload",
            rejection
                area
                "missing-download"
                (fun parent -> source parent "source" false "finished" false "before")
                (function
                 | Error(Error.InvalidSource _) -> true
                 | _ -> false)
        )

        writer.WriteBoolean(
            "unfinishedDownload",
            rejection
                area
                "unfinished-download"
                (fun parent -> source parent "source" false "paused" true "before")
                (function
                 | Error(Error.UnsupportedData _) -> true
                 | _ -> false)
        )

        writer.WriteBoolean(
            "unsupportedRule",
            rejection
                area
                "unsupported-rule"
                (fun parent -> source parent "source" false "finished" true "requires")
                (function
                 | Error(Error.UnsupportedData _) -> true
                 | _ -> false)
        )

        let cancelArea = Directory.CreateDirectory(Path.Combine(area, "cancel")).FullName
        let cancelInput = source cancelArea "source" false "finished" true "before"

        let cancelState =
            Directory.CreateDirectory(Path.Combine(cancelArea, "state")).FullName

        let cancelWorkspace =
            use store = new OperationStore(cancelState)
            createWorkspace store cancelArea "workspace" |> fst

        do
            use store = new OperationStore(cancelState)
            use cancellation = new CancellationTokenSource()

            let outcome =
                migrate store cancelWorkspace cancelInput cancellation.Token (fun _ ->
                    cancellation.Cancel())

            writer.WriteBoolean(
                "cancellation",
                (match outcome with
                 | Error Error.Cancelled -> true
                 | _ -> false)
                && empty store cancelWorkspace
            )

        let backupChanged =
            changed area "backup-changed" (fun value ->
                File.AppendAllText(value.Backup, " ", UTF8Encoding(false)))

        let stagingChanged =
            changed area "staging-changed" (fun value ->
                write (Path.Combine(value.Staging, "Alpha", "added.txt")) "changed")

        let downloadsChanged =
            changed area "downloads-changed" (fun value ->
                write (Path.Combine(value.Downloads, "added.zip")) "changed")

        writer.WriteBoolean("sourceChanged", backupChanged && stagingChanged && downloadsChanged)

        if OperatingSystem.IsLinux() then
            writer.WriteBoolean(
                "caseCollision",
                rejection
                    area
                    "case-collision"
                    (fun parent ->
                        let value = source parent "source" false "finished" true "before"
                        Directory.CreateDirectory(Path.Combine(value.Staging, "alpha")) |> ignore
                        value)
                    (function
                     | Error(Error.CaseCollision _) -> true
                     | _ -> false)
            )

            writer.WriteBoolean(
                "unsafeLink",
                rejection
                    area
                    "unsafe-link"
                    (fun parent ->
                        let value = source parent "source" false "finished" true "before"

                        File.CreateSymbolicLink(
                            Path.Combine(value.Staging, "Alpha", "linked.txt"),
                            Path.Combine(value.Staging, "Alpha", "textures", "alpha.txt")
                        )
                        |> ignore

                        value)
                    (function
                     | Error(Error.UnsafeSource _) -> true
                     | _ -> false)
            )
        else
            writer.WriteBoolean("caseCollision", true)
            writer.WriteBoolean("unsafeLink", true)

        writer.WriteBoolean("crashBeforePublication", crashWindow area "before-publication")
        writer.WriteBoolean("crashAfterPublication", crashWindow area "after-publication")
        writer.WriteBoolean("crashBeforeCommit", crashWindow area "before-commit")
        writer.WriteBoolean("crashAfterCommit", crashWindow area "after-commit")
        writer.WriteEndObject()
