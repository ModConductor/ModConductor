namespace ModConductor.Native.Fixtures

open System
open System.Buffers.Binary
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.BepInEx
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform

module UnityIl2CppFixtures =
    let private get = UnityMonoEnvironment.get

    let private check (writer: Utf8JsonWriter) (name: string) condition =
        writer.WriteBoolean(name, condition)

        if not condition then
            invalidOp ("Unity IL2CPP fixture failed: " + name)

    let private install (store: OperationStore) workspace archive =
        let artifact =
            store.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  Path = archive
                  Storage = ArtifactStorage.Reference },
                CancellationToken.None
            )
            |> get

        let reference: ArtifactRef =
            { WorkspaceId = workspace
              Id = artifact.Id
              Revision = artifact.Revision }

        let draft = store.Installations.Prepare(reference, CancellationToken.None) |> get

        let draft =
            store.Installations.Change(workspace, draft.Id, draft.Revision, LayoutChange.Root [])
            |> StorageWorker.result

        let job = Guid.NewGuid()

        store.Installations.Start(workspace, draft.Id, draft.Revision, job)
        |> StorageWorker.result
        |> ignore

        let deadline = DateTime.UtcNow.AddSeconds 20.
        let mutable state = store.Installations.Read(workspace, job) |> get

        while state.State = InstallationState.Running && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            state <- store.Installations.Read(workspace, job) |> get

        if state.State <> InstallationState.Complete then
            invalidOp (defaultArg state.Problem "Archive installation did not complete.")

        state.ModId.Value

    let private enable (store: OperationStore) workspace profile value =
        let state = store.BepInEx.Read(workspace, profile) |> get

        store.BepInEx.Change(
            workspace,
            profile,
            state.ContextRevision,
            state.SelectionRevision,
            value
        )
        |> get

    let private create area =
        let definition = UnityIl2CppDefinitions.sonsOfTheForest
        let game, proton = ProtonFixtures.createFor definition false area
        let client = GameClient.il2cpp definition |> Option.get

        File.WriteAllBytes(
            Path.Combine(game, client.WindowsRuntime),
            File.ReadAllBytes(Path.Combine(game, definition.Executable))
        )

        let data = Path.Combine(game, definition.Data)

        Directory.CreateDirectory(Path.GetDirectoryName(Path.Combine(data, client.Metadata)))
        |> ignore

        let metadata = Array.zeroCreate<byte> 8
        BinaryPrimitives.WriteUInt32LittleEndian(metadata.AsSpan(0, 4), 0xFAB11BAFu)
        File.WriteAllBytes(Path.Combine(data, client.Metadata), metadata)
        File.WriteAllText(Path.Combine(data, client.UnityMetadata), "\0002022.2.16f1\000fixture")
        game, (if OperatingSystem.IsLinux() then Some proton else None)

    let private nativeRoute check (state: GameContextState) root =
        let original = UnityIl2CppDefinitions.sonsOfTheForest
        let client = GameClient.il2cpp original |> Option.get

        let definition =
            { original with
                Client =
                    GameClient.UnityIl2Cpp
                        { client with
                            LinuxExecutable = Some "NativeClient.x86_64"
                            Loader = None } }

        let binding = state.Binding.Value

        File.WriteAllBytes(
            Path.Combine(binding.Evidence.RootPath, "NativeClient.x86_64"),
            UnityMonoSamples.elf ()
        )

        File.WriteAllBytes(
            Path.Combine(binding.Evidence.RootPath, client.LinuxRuntime),
            UnityMonoSamples.elf ()
        )

        let evidence = InstallationValidation.inspect definition binding.Evidence.RootPath
        check "declared native Linux client and runtime validate as x64 ELF" evidence.Valid

        let context =
            { state with
                Binding = Some { binding with Evidence = evidence } }

        let configuration =
            Some
                { LoaderEnabled = true
                  GenerationId = Guid.Empty
                  GameSha256 = evidence.Executable.Value.Sha256
                  Environment = [] }

        let _, _, launch =
            Descriptor.createDeclaredWithHost false true definition context root None configuration
            |> StorageWorker.result

        check
            "declared native Linux archive uses its wrapper in the runtime child"
            (List.contains (Path.Combine(root, "run_bepinex.sh")) launch.Arguments
             && List.contains (Path.Combine(root, "NativeClient.x86_64")) launch.Arguments
             && not (launch.Environment |> List.exists (fun (name, _) -> name = "LD_PRELOAD")))

    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject "unityIl2Cpp"
        let check = check writer
        let game, proton = create area
        let definition = UnityIl2CppDefinitions.sonsOfTheForest

        let metadata =
            Path.Combine(game, definition.Data, (GameClient.il2cpp definition).Value.Metadata)

        let originalMetadata = File.ReadAllBytes metadata
        File.WriteAllBytes(metadata, Array.zeroCreate<byte> 8)

        check
            "invalid IL2CPP metadata does not produce a valid binding"
            (not (InstallationValidation.inspect definition game).Valid)

        File.WriteAllBytes(metadata, originalMetadata)

        let capability =
            CapabilityPolicy.tryFind definition.Id CapabilityId.UnityIl2Cpp |> Option.get

        check
            "IL2CPP capability declares Windows and Proton without claiming native Linux"
            (CapabilityPolicy.supports definition.Id ContextPlatform.Windows capability
             && CapabilityPolicy.supports definition.Id ContextPlatform.Proton capability
             && not (CapabilityPolicy.supports definition.Id ContextPlatform.NativeLinux capability))

        use store = new OperationStore(Path.Combine(area, "state"))

        let workspace, first, second, _ =
            UnityMonoEnvironment.createFor store area definition game proton

        let archive = Path.Combine(area, "ordinary-loader.zip")

        let bytes =
            UnityMonoSamples.package
                [ "Bundle/BepInEx/core/BepInEx.Unity.IL2CPP.dll", "loader fixture"
                  "Bundle/dotnet/coreclr.dll", "separate game runtime"
                  "Bundle/winhttp.dll", "proxy fixture"
                  "Bundle/doorstop_config.ini", "[General]\nenabled=true\n"
                  "Bundle/BepInEx/config/BepInEx.cfg", "[IL2CPP]\nUpdateInteropAssemblies = true\n" ]

        File.WriteAllBytes(archive, bytes)
        let loader = install store workspace archive
        let initial = store.BepInEx.Read(workspace, first) |> get

        check
            "ordinary archive is recognized without Thunderstore provenance"
            (initial.Mod = Some loader && initial.Package.IsNone && not initial.Enabled)

        let enabled = enable store workspace first true
        let pluginArchive = Path.Combine(area, "plugin.zip")

        File.WriteAllBytes(
            pluginArchive,
            UnityMonoSamples.package [ "plugins/MenuProbe.dll", "compatible plugin fixture" ]
        )

        let plugin = install store workspace pluginArchive
        let selection = store.ModSelection :> IModSelection
        let current = store.BepInEx.Read(workspace, first) |> get

        selection.Change(first, current.SelectionRevision, [ plugin ], SelectionEdit.Enable true)
        |> get
        |> ignore

        let root = UnityMonoEnvironment.deploy store first
        UnityMonoWireFixtures.observe check store workspace first
        UnityMonoWireFixtures.observeLog check store workspace first root

        check
            "archive loader core and game runtime stay out of the plugin destination"
            (File.ReadAllText(Path.Combine(root, "dotnet", "coreclr.dll")) = "separate game runtime"
             && File.Exists(Path.Combine(root, "BepInEx", "plugins", "MenuProbe.dll")))

        let context = (store.GameContexts :> IGameContexts).Read(workspace, first) |> get

        let configuration =
            Some
                { LoaderEnabled = true
                  GenerationId = Guid.Empty
                  GameSha256 = enabled.GameSha256
                  Environment = [] }

        let _, _, launch =
            Descriptor.createWithHost
                (OperatingSystem.IsWindows())
                (OperatingSystem.IsLinux())
                context
                root
                None
                configuration
            |> StorageWorker.result

        if OperatingSystem.IsLinux() then
            check
                "Proton injects only into the game child"
                (List.contains ("WINEDLLOVERRIDES", Some "winhttp=n,b") launch.Environment
                 && List.contains (Path.Combine(root, definition.Executable)) launch.Arguments)

            nativeRoute check context root

        let windows =
            { context with
                Binding =
                    context.Binding
                    |> Option.map (fun b ->
                        { b with
                            Evidence =
                                { b.Evidence with
                                    Platform = ContextPlatform.Windows
                                    Proton = None } }) }

        let _, _, win =
            Descriptor.createWithHost true false windows root None configuration
            |> StorageWorker.result

        check
            "Windows loader uses the private executable without a Wine override"
            (win.Executable = Path.Combine(root, definition.Executable)
             && not (win.Environment |> List.exists (fun (name, _) -> name = "WINEDLLOVERRIDES")))

        check
            "proxy merge preserves unrelated native overrides"
            (WineDllOverrides.withNative "other,winhttp=b;dxgi=n" "winhttp.dll" = "other=b;dxgi=n;winhttp=n,b")

        for directory, file in
            [ "interop", "Game.dll"
              "unity-libs", "2022.2.16.zip"
              "dummy", "Assembly-CSharp.dll"
              "cache", "loader.cache" ] do
            File.WriteAllText(
                Path.Combine(root, "BepInEx", directory, file),
                "first profile output"
            )

        File.WriteAllText(Path.Combine(root, "BepInEx", "LogOutput.log"), "first profile log")
        File.WriteAllText(Path.Combine(root, "BepInEx", "LogOutput.1.log"), "fallback log")
        UnityMonoEnvironment.deploy store first |> ignore
        enable store workspace second true |> ignore
        let other = UnityMonoEnvironment.deploy store second

        check
            "redeployment retains generated output and profile switches isolate it"
            (File.ReadAllText(Path.Combine(root, "BepInEx", "interop", "Game.dll")) = "first profile output"
             && not (File.Exists(Path.Combine(other, "BepInEx", "interop", "Game.dll")))
             && (store.BepInEx.ReadLog(workspace, second) |> get).Length = 0)

        enable store workspace first false |> ignore
        UnityMonoEnvironment.deploy store first |> ignore

        check
            "disabling removes injection without deleting generated working storage"
            (not (File.Exists(Path.Combine(root, "winhttp.dll")))
             && not (Directory.Exists(Path.Combine(root, "dotnet"))))

        enable store workspace first true |> ignore
        UnityMonoEnvironment.deploy store first |> ignore

        check
            "reenabling restores prior interop and backend log output"
            (File.ReadAllText(Path.Combine(root, "BepInEx", "interop", "Game.dll")) = "first profile output"
             && File.ReadAllText(Path.Combine(root, "BepInEx", "LogOutput.1.log")) = "fallback log")

        let library = store.ModLibrary :> IModLibrary

        let version =
            library.Version(
                ((library.Scan(workspace, 32) |> get).Entries
                 |> List.find (fun e -> e.Id = loader))
                    .CurrentVersion.Value,
                0
            )
            |> get

        let config =
            version.Entries
            |> List.find (fun e -> LogicalPath.display e.Path = "Bundle/BepInEx/config/BepInEx.cfg")

        check
            "generated storage never writes through original game or library payloads"
            (not (Directory.Exists(Path.Combine(game, "BepInEx")))
             && File.ReadAllBytes(archive) = bytes
             && Encoding.UTF8
                 .GetString(
                     library.ReadPayload(
                         version.Id,
                         config.Payload.Id,
                         0L,
                         int config.Payload.Length
                     )
                     |> get
                 )
                 .Contains("true"))

        for profile in [ first; second ] do
            enable store workspace profile false |> ignore
            UnityMonoEnvironment.deploy store profile |> ignore

        let entry =
            (library.Scan(workspace, 32) |> get).Entries
            |> List.find (fun e -> e.Id = loader)

        store.Deletions.Delete(workspace, loader, entry.Revision) |> get |> ignore

        check
            "library removal clears loader selection but retains profile output"
            ((store.BepInEx.Read(workspace, first) |> get).Mod.IsNone
             && (store.BepInEx.ReadSettings(workspace, first) |> get).Length > 0)

        writer.WriteEndObject()
