namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

/// Opt-in qualification only. The default fixture runner never acquires or launches games.
module UnrealRuntimeFixtures =
    let private get = UnityMonoEnvironment.get
    let private path area name = Path.Combine(area, name)
    let private text (value: JsonElement) (name: string) = value.GetProperty(name).GetString()

    let private package (store: OperationStore) workspace declaration (value: JsonElement) token =
        let name, version = text value "name", text value "version"

        let started =
            store.Downloads.Start
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Name = name + ".zip"
                  Sources = [ DownloadSource.Url(text value "url") ]
                  ExpectedLength = None
                  ExpectedSha256 = None }
            |> get

        let archive =
            UnrealArchiveInstallation.waitDownload
                store.Downloads
                store.Artifacts
                (fun _ -> Task.CompletedTask)
                token
                started
            |> get

        let status =
            UnrealArchiveInstallation.start
                store.Installations
                { declaration with
                    Name = name
                    Version = version }
                archive
                token
            |> get

        UnrealArchiveInstallation.waitInstall
            store.Installations
            (fun _ -> Task.CompletedTask)
            token
            status
        |> get

    let prepare (writer: Utf8JsonWriter) area manifest =
        use data = JsonDocument.Parse(File.ReadAllBytes manifest)
        let source = data.RootElement
        let gameId = GameId.tryParse (text source "gameId") |> Option.get
        let definition = GameCatalog.forGame gameId
        let declared = GameClient.unreal definition |> Option.get
        use store = new OperationStore(path area "state")
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(path area "workspace").FullName
        let workspaces = store.Workspaces :> IWorkspaceState

        let initial =
            workspaces.Create(workspace, definition.Name, StorageWorker.select root) |> get

        workspaces.Edit(
            workspace,
            initial.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Qualification" }
        )
        |> get
        |> ignore

        let selected =
            { AppId = definition.SteamAppId
              Association = ProtonAssociation.Manual
              CompatData = text source "compatdata"
              RuntimeDirectory = text source "runtime"
              ToolId = "" }

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                0L,
                { GameId = gameId
                  Path = text source "game"
                  Proton = Some selected
                  Wine = None }
            )
        |> get
        |> ignore

        let loader = store.Unreal.Read(workspace, profile) |> get
        use deadline = new CancellationTokenSource(TimeSpan.FromMinutes 5.)

        let loaded =
            store.UnrealAcquisition.Acquire(
                workspace,
                profile,
                loader.ContextRevision,
                text source "archive",
                (fun _ -> Task.CompletedTask),
                deadline.Token
            )
            |> get

        let mods =
            source.GetProperty("packages").EnumerateArray()
            |> Seq.map (fun item -> package store workspace declared.Loader item deadline.Token)
            |> Seq.toList

        let chosen = store.Unreal.Read(workspace, profile) |> get

        if not mods.IsEmpty then
            (store.ModSelection :> IModSelection)
                .Change(profile, chosen.SelectionRevision, mods, SelectionEdit.Enable true)
            |> get
            |> ignore

        let runnable = UnityMonoEnvironment.deploy store profile
        use saved = File.Create(path area "fixture.json")
        use record = new Utf8JsonWriter(saved)
        record.WriteStartObject()
        record.WriteString("workspace", workspace.ToString("N"))
        record.WriteString("profile", profile.ToString("N"))
        record.WriteStartArray("mods")

        for id in mods do
            record.WriteStringValue(id.ToString("N"))

        record.WriteEndArray()
        record.WriteEndObject()
        writer.WriteStartObject("unrealPreparation")
        writer.WriteString("root", runnable)
        writer.WriteString("workspace", workspace.ToString("N"))
        writer.WriteString("profile", profile.ToString("N"))
        writer.WriteString("loader", loaded.Mod.Value.ToString("N"))
        writer.WriteNumber("mods", mods.Length)
        writer.WriteEndObject()

    let private ids area =
        use saved = JsonDocument.Parse(File.ReadAllBytes(path area "fixture.json"))
        let source = saved.RootElement

        Guid.Parse(text source "workspace"),
        Guid.Parse(text source "profile"),
        (source.GetProperty("mods").EnumerateArray()
         |> Seq.map (fun item -> Guid.Parse(item.GetString()))
         |> Seq.toList)

    let register (writer: Utf8JsonWriter) area folder =
        let workspace, _, mods = ids area
        use store = new OperationStore(path area "state")
        let library = store.ModLibrary :> IModLibrary

        let entry =
            library.Register(
                workspace,
                Guid.NewGuid(),
                { Name = "MC menu probe"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ folder ] |> StorageWorker.result
                )
            )
            |> get

        library.Publish(entry.Id, entry.Revision, Guid.NewGuid()) |> get |> ignore
        use saved = JsonDocument.Parse(File.ReadAllBytes(path area "fixture.json"))
        let profile = Guid.Parse(text saved.RootElement "profile")

        use output = File.Create(path area "fixture.json")
        use record = new Utf8JsonWriter(output)
        record.WriteStartObject()
        record.WriteString("workspace", workspace.ToString("N"))
        record.WriteString("profile", profile.ToString("N"))
        record.WriteStartArray("mods")

        for id in mods @ [ entry.Id ] do
            record.WriteStringValue(id.ToString("N"))

        record.WriteEndArray()
        record.WriteEndObject()

        writer.WriteString("marker", entry.Id.ToString("N"))

    let descriptor area enabled =
        let workspace, profile, mods = ids area
        use store = new OperationStore(path area "state")
        let contexts = store.GameContexts :> IGameContexts
        let previous = contexts.Read(workspace, profile) |> get
        let context = contexts.Refresh(workspace, profile, previous.Revision) |> get

        ModConductor.Deployment.GameProcesses.validate context
        |> StorageWorker.result
        |> ignore

        let loader = store.Unreal.Read(workspace, profile) |> get

        let changed =
            store.Unreal.Change(
                workspace,
                profile,
                loader.ContextRevision,
                loader.SelectionRevision,
                enabled
            )
            |> get

        if not mods.IsEmpty then
            (store.ModSelection :> IModSelection)
                .Change(profile, changed.SelectionRevision, mods, SelectionEdit.Enable enabled)
            |> get
            |> ignore

        let root = UnityMonoEnvironment.deploy store profile

        let configuration =
            Some
                { LoaderEnabled = enabled
                  GenerationId = Guid.Empty
                  GameSha256 = loader.GameSha256
                  Environment = [] }

        let _, _, launch =
            Descriptor.createWith context root None configuration |> StorageWorker.result

        { launch with
            Arguments = launch.Arguments @ [ "-windowed"; "-ResX=1280"; "-ResY=720"; "-NoSplash" ] },
        root

    let private saveLaunch area (launch: NativeLaunch) =
        use output = File.Create(path area "launch.json")
        use record = new Utf8JsonWriter(output)
        record.WriteStartObject()
        record.WriteString("Executable", launch.Executable)
        record.WriteString("WorkingDirectory", launch.WorkingDirectory)
        record.WriteStartArray("Arguments")

        for arg in launch.Arguments do
            record.WriteStringValue arg

        record.WriteEndArray()
        record.WriteStartObject("Environment")

        for name, value in launch.Environment do
            match value with
            | Some value -> record.WriteString(name, value)
            | None -> record.WriteNull(name)

        record.WriteEndObject()
        record.WriteEndObject()

    let plan (writer: Utf8JsonWriter) area enabled =
        let launch, root = descriptor area enabled
        saveLaunch area launch
        writer.WriteString("root", root)
        writer.WriteString("command", launch.Executable)
        writer.WriteStartArray("arguments")

        for arg in launch.Arguments do
            writer.WriteStringValue arg

        writer.WriteEndArray()

    let run (writer: Utf8JsonWriter) area enabled seconds =
        let launch, root = descriptor area enabled
        saveLaunch area launch
        use child = NativeProcessLaunch.start launch
        File.WriteAllText(path area "pid", string child.ProcessId)
        let deadline = DateTime.UtcNow.AddSeconds(float seconds)

        while not child.RootExit.IsCompleted && DateTime.UtcNow < deadline do
            Thread.Sleep 250

        if not child.RootExit.IsCompleted then
            child.TerminateScope()

        let code = child.RootExit.GetAwaiter().GetResult()
        writer.WriteStartObject("unrealRuntime")
        writer.WriteString("root", root)
        writer.WriteNumber("exitCode", code)
        writer.WriteBoolean("loaderEnabled", enabled)
        writer.WriteEndObject()
