namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.BepInEx
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Thunderstore

/// Explicit CLI-only runtime proof. The default fixture runner never launches the installed game.
module UnityMonoRuntimeFixtures =
    let private get = UnityMonoEnvironment.get
    let private path area name = Path.Combine(area, name)

    let private extract (store: OperationStore) workspace references =
        let library = store.ModLibrary :> IModLibrary
        let entries = (library.Scan(workspace, 32) |> get).Entries

        for entry in entries do
            let version = library.Version(entry.CurrentVersion.Value, 0) |> get

            for file in version.Entries do
                let name = LogicalPath.components file.Path |> List.last

                if name = "BepInEx.dll" || name = "Jotunn.dll" then
                    use output = File.Create(path references name)
                    let mutable offset = 0L

                    while offset < file.Payload.Length do
                        let count = int (min 65536L (file.Payload.Length - offset))

                        let bytes =
                            library.ReadPayload(version.Id, file.Payload.Id, offset, count) |> get

                        output.Write bytes
                        offset <- offset + int64 bytes.Length

    let private publicPackages (store: OperationStore) workspace =
        use reader = new PackageReader()
        use deadline = new CancellationTokenSource(TimeSpan.FromMinutes 3.)

        let acquisition =
            ThunderstoreAcquisition(
                reader,
                store.Downloads,
                store.Artifacts,
                store.Installations,
                store.ThunderstoreInventory
            )

        acquisition.Acquire(
            workspace,
            ThunderstoreSamples.jotunn,
            (fun _ -> Task.CompletedTask),
            deadline.Token
        )
        |> StorageWorker.wait
        |> Result.defaultWith (Problem.message >> invalidOp)

    let prepare (writer: Utf8JsonWriter) area game =
        use store = new OperationStore(path area "state")
        let workspace, first, second, root = UnityMonoEnvironment.create store area game
        let packages = publicPackages store workspace
        let refs = Directory.CreateDirectory(path area "references").FullName
        extract store workspace refs
        use data = File.Create(path area "fixture.json")
        use saved = new Utf8JsonWriter(data)
        saved.WriteStartObject()

        for name, value in [ "workspace", workspace; "first", first; "second", second ] do
            saved.WriteString(name, value.ToString("N"))

        saved.WriteEndObject()
        writer.WriteStartObject "nativeClientPreparation"
        writer.WriteString("workspace", root)
        writer.WriteString("references", refs)
        writer.WriteNumber("packages", packages.Length)
        writer.WriteEndObject()

    let private ids area =
        use data = JsonDocument.Parse(File.ReadAllBytes(path area "fixture.json"))

        let read (name: string) =
            data.RootElement.GetProperty(name).GetString() |> Guid.Parse

        read "workspace", read "first", read "second"

    let private marker (store: OperationStore) workspace area =
        let library = store.ModLibrary :> IModLibrary

        let existing =
            (library.Scan(workspace, 32) |> get).Entries
            |> List.tryFind (fun entry -> entry.Metadata.Name = "MC menu probe")

        match existing with
        | Some entry -> entry.Id
        | None ->
            let source = path (path area "workspace") "menu-probe"
            Directory.CreateDirectory(path source "plugins") |> ignore
            File.Copy(path area "MC.MenuProbe.dll", path (path source "plugins") "MC.MenuProbe.dll")

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
                        LogicalPath.create [ "menu-probe" ] |> StorageWorker.result
                    )
                )
                |> get

            library.Publish(entry.Id, entry.Revision, Guid.NewGuid()) |> get |> ignore
            entry.Id

    let private select (store: OperationStore) workspace profile enabled probe =
        let loader = store.BepInEx.Read(workspace, profile) |> get

        let changed =
            store.BepInEx.Change(
                workspace,
                profile,
                loader.ContextRevision,
                loader.SelectionRevision,
                enabled
            )
            |> get

        let revision = changed.SelectionRevision
        let entries = (store.ModLibrary :> IModLibrary).Scan(workspace, 32) |> get

        let jotunn =
            entries.Entries
            |> List.find (fun entry ->
                VersionReference.tryDecode entry.Metadata.Source = Some ThunderstoreSamples.jotunn)

        (store.ModSelection :> IModSelection)
            .Change(profile, revision, [ jotunn.Id; probe ], SelectionEdit.Enable enabled)
        |> get
        |> ignore

    let private descriptor (store: OperationStore) workspace profile root =
        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get
        let loader = store.BepInEx.Read(workspace, profile) |> get

        let config =
            Some
                { LoaderEnabled = loader.Enabled
                  GenerationId = Guid.Empty
                  GameSha256 = loader.GameSha256
                  Environment = [] }

        Descriptor.createWith context root None config
        |> StorageWorker.result
        |> fun (_, _, launch) -> launch

    let run (writer: Utf8JsonWriter) area phase =
        let workspace, first, second = ids area
        use store = new OperationStore(path area "state")
        let profile = if phase = "second" then second else first
        let enabled = phase <> "off"
        let contexts = store.GameContexts :> IGameContexts
        let previous = contexts.Read(workspace, profile) |> get
        let context = contexts.Refresh(workspace, profile, previous.Revision) |> get

        ModConductor.Deployment.GameProcesses.validate context
        |> StorageWorker.result
        |> ignore

        let probe = marker store workspace area
        select store workspace profile enabled probe
        let root = UnityMonoEnvironment.deploy store profile
        let launch = descriptor store workspace profile root
        let output = Directory.CreateDirectory(path area phase).FullName

        let launch =
            { launch with
                Arguments =
                    launch.Arguments
                    @ [ "-savedir"
                        path output "saves"
                        "-screen-fullscreen"
                        "0"
                        "-screen-width"
                        "1280"
                        "-screen-height"
                        "720"
                        "-logFile"
                        path output "player.log" ]
                Environment =
                    launch.Environment @ [ "MC_MENU_PROBE_IMAGE", Some(path output "menu.png") ] }

        use child = NativeProcessLaunch.start launch
        let deadline = DateTime.UtcNow.AddSeconds(if enabled then 120. else 40.)

        while not child.RootExit.IsCompleted && DateTime.UtcNow < deadline do
            Thread.Sleep 250

        if not child.RootExit.IsCompleted then
            child.TerminateScope()

        child.RootExit.GetAwaiter().GetResult() |> ignore
        writer.WriteStartObject "nativeClientRuntime"
        writer.WriteString("phase", phase)
        writer.WriteString("root", root)
        writer.WriteString("command", launch.Executable)
        writer.WriteString("playerLog", path output "player.log")
        writer.WriteBoolean("menuImage", File.Exists(path output "menu.png"))
        writer.WriteBoolean("loaderLog", File.Exists(path root "BepInEx/LogOutput.log"))
        writer.WriteEndObject()
