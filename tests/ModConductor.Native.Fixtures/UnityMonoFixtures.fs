namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.BepInEx
open ModConductor.Deployment
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform

module UnityMonoFixtures =
    let private get = UnityMonoEnvironment.get

    let private check (writer: Utf8JsonWriter) (name: string) condition =
        writer.WriteBoolean(name, condition)
        writer.Flush()

        if not condition then
            invalidOp ("Unity Mono fixture failed: " + name)

    let private enable (store: OperationStore) workspace profile =
        let state = store.BepInEx.Read(workspace, profile) |> get

        store.BepInEx.Change(
            workspace,
            profile,
            state.ContextRevision,
            state.SelectionRevision,
            true
        )
        |> get

    let private identity (path: string) =
        let selection = StorageWorker.select (Path.GetDirectoryName path)
        let root = RootSelection.facts selection

        use directory =
            HeldDirectory.Open(
                RootSelection.path selection,
                (match root.File with
                 | Known identity -> identity
                 | Unknown _ -> invalidOp "File identity unavailable.")
            )

        directory.InspectEntry(Path.GetFileName path) |> Option.get |> _.Identity

    let private originals (store: OperationStore) workspace =
        let entries = (store.ModLibrary :> IModLibrary).Scan(workspace, 32) |> get

        entries.Entries
        |> List.map (fun entry ->
            let version =
                (store.ModLibrary :> IModLibrary).Version(entry.CurrentVersion.Value, 0) |> get

            entry.Id,
            version.Entries
            |> List.map (fun file ->
                file.Payload,
                (store.ModLibrary :> IModLibrary)
                    .ReadPayload(version.Id, file.Payload.Id, 0L, int file.Payload.Length)
                |> get))

    let private nativeDescriptors (writer: Utf8JsonWriter) context root =
        let binding = context.Binding.Value

        let configuration =
            Some
                { MonoLoader = true
                  GenerationId = Guid.NewGuid()
                  GameSha256 = binding.Evidence.Executable.Value.Sha256
                  Environment = [] }

        let linux = Descriptor.createWithHost false true context root None configuration

        check
            writer
            "native Linux wrapper remains inside runtime child"
            (linux
             |> Result.toOption
             |> Option.exists (fun (_, _, launch) ->
                 let wrapper = Path.Combine(root, "start_game_bepinex.sh")

                 List.contains wrapper launch.Arguments
                 && List.contains (Path.Combine(root, "valheim.x86_64")) launch.Arguments
                 && not (launch.Environment |> List.exists (fun (key, _) -> key = "LD_PRELOAD"))))

        let executable =
            { binding.Evidence.Executable.Value with
                Path = Path.Combine(binding.Evidence.RootPath, "valheim.exe") }

        let evidence =
            { binding.Evidence with
                Platform = ContextPlatform.Windows
                Executable = Some executable }

        let windowsContext =
            { context with
                Binding = Some { binding with Evidence = evidence } }

        let windows =
            Descriptor.createWithHost true false windowsContext root None configuration

        check
            writer
            "native Windows launch uses private client without Wine"
            (windows
             |> Result.toOption
             |> Option.exists (fun (_, runtime, launch) ->
                 runtime = "Windows"
                 && launch.Executable = Path.Combine(root, "valheim.exe")
                 && not (
                     launch.Environment |> List.exists (fun (key, _) -> key = "WINEDLLOVERRIDES")
                 )))

    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject "unityMono"

        let game =
            UnityMonoSamples.create Valheim.definition (Path.Combine(area, "installation"))

        use store = new OperationStore(Path.Combine(area, "state"))
        let workspace, first, second, _ = UnityMonoEnvironment.create store area game
        let acquired = UnityMonoEnvironment.acquire store workspace
        let originalPayloads = originals store workspace
        let initial = store.BepInEx.Read(workspace, first) |> get

        check
            writer
            "acquisition retains disabled profile selection"
            (initial.Mod.IsSome && not initial.Enabled)

        let enabled = enable store workspace first

        let plugin =
            acquired |> List.find (fun row -> row.Reference = ThunderstoreSamples.jotunn)

        (store.ModSelection :> IModSelection)
            .Change(first, enabled.SelectionRevision, [ plugin.ModId ], SelectionEdit.Enable true)
        |> get
        |> ignore

        let firstRoot = UnityMonoEnvironment.deploy store first
        UnityMonoWireFixtures.observe (check writer) store workspace first

        let clientName =
            GameClient.executable (OperatingSystem.IsLinux()) Valheim.definition

        let privateClient = Path.Combine(firstRoot, clientName)
        let originalClient = Path.Combine(game, clientName)
        let originalClientBytes = File.ReadAllBytes originalClient
        let firstIdentity = identity privateClient

        check
            writer
            "private client is independent while game assets stay linked"
            ((FileInfo privateClient).LinkTarget = null
             && firstIdentity <> identity originalClient
             && File.ResolveLinkTarget(Path.Combine(firstRoot, "UnityPlayer.so"), true).FullName = Path
                 .Combine(game, "UnityPlayer.so")
             && File
                 .ResolveLinkTarget(Path.Combine(firstRoot, "valheim_Data", "assets.dat"), true)
                 .FullName = Path.Combine(game, "valheim_Data", "assets.dat"))

        check
            writer
            "loader and plugin use declared game root rather than Unity assets"
            (File.Exists(Path.Combine(firstRoot, "BepInEx", "core", "BepInEx.Preloader.dll"))
             && File.ReadAllText(Path.Combine(firstRoot, "BepInEx", "plugins", "Jotunn.dll")) = "plugin fixture"
             && not (File.Exists(Path.Combine(firstRoot, "valheim_Data", "plugins", "Jotunn.dll"))))

        let config = store.BepInEx.ReadSettings(workspace, first) |> get

        store.BepInEx.SaveSettings(workspace, first, config, "[Logging.Disk]\nEnabled = false\n")
        |> get
        |> ignore

        File.WriteAllText(
            Path.Combine(firstRoot, "BepInEx", "cache", "generated.cache"),
            "private cache"
        )

        File.WriteAllText(
            Path.Combine(firstRoot, "BepInEx", "DumpedAssemblies", "assembly.dll"),
            "private generated assembly"
        )

        File.WriteAllText(Path.Combine(firstRoot, "BepInEx", "LogOutput.log"), "first profile log")

        check
            writer
            "settings preserve encoding and original newline"
            (Encoding.UTF8.GetString(store.BepInEx.ReadSettings(workspace, first) |> get) = "[Logging.Disk]\r\nEnabled = false\r\n")

        check
            writer
            "stale settings draft does not overwrite the owned file"
            (store.BepInEx.SaveSettings(workspace, first, config, "stale\n")
             |> StorageWorker.wait
             |> Result.isError)

        UnityMonoEnvironment.deploy store first |> ignore

        check
            writer
            "unchanged client and writable state survive redeployment"
            (identity privateClient = firstIdentity
             && File.ReadAllText(Path.Combine(firstRoot, "BepInEx", "cache", "generated.cache")) = "private cache")

        enable store workspace second |> ignore
        let secondRoot = UnityMonoEnvironment.deploy store second

        check
            writer
            "profiles keep separate clients and loader settings"
            (identity (Path.Combine(secondRoot, clientName)) <> firstIdentity
             && Encoding.UTF8.GetString(store.BepInEx.ReadSettings(workspace, second) |> get) = "[Logging.Disk]\r\nEnabled = true\r\n"
             && (store.BepInEx.ReadLog(workspace, second) |> get).Length = 0)

        let context = (store.GameContexts :> IGameContexts).Read(workspace, first) |> get

        if OperatingSystem.IsLinux() then
            nativeDescriptors writer context firstRoot

        let state = store.BepInEx.Read(workspace, first) |> get

        store.BepInEx.Change(
            workspace,
            first,
            state.ContextRevision,
            state.SelectionRevision,
            false
        )
        |> get
        |> ignore

        UnityMonoEnvironment.deploy store first |> ignore

        check
            writer
            "disable removes loader injection files but retains settings"
            (not (File.Exists(Path.Combine(firstRoot, "BepInEx", "core", "BepInEx.Preloader.dll")))
             && not (File.Exists(Path.Combine(firstRoot, "winhttp.dll")))
             && Encoding.UTF8
                 .GetString(store.BepInEx.ReadSettings(workspace, first) |> get)
                 .Contains
                 "false")

        enable store workspace first |> ignore
        UnityMonoEnvironment.deploy store first |> ignore

        check
            writer
            "reenable restores loader without resetting writable state"
            (File.ReadAllText(Path.Combine(firstRoot, "BepInEx", "LogOutput.log")) = "first profile log"
             && File.ReadAllText(
                 Path.Combine(firstRoot, "BepInEx", "DumpedAssemblies", "assembly.dll")
             ) = "private generated assembly")

        check
            writer
            "original installation and package payloads remain unchanged"
            (File.ReadAllBytes(originalClient) = originalClientBytes
             && originals store workspace = originalPayloads
             && not (Directory.Exists(Path.Combine(game, "BepInEx"))))

        let launch = store.GameLaunching.Read(workspace, first) |> get
        check writer "native launch needs no Bethesda settings or plugin list" launch.Problem.IsNone

        for profile in [ first; second ] do
            let current = store.BepInEx.Read(workspace, profile) |> get

            store.BepInEx.Change(
                workspace,
                profile,
                current.ContextRevision,
                current.SelectionRevision,
                false
            )
            |> get
            |> ignore

            UnityMonoEnvironment.deploy store profile |> ignore

        let library = (store.ModLibrary :> IModLibrary).Scan(workspace, 32) |> get

        let loader =
            library.Entries |> List.find (fun entry -> entry.Id = enabled.Mod.Value)

        store.Deletions.Delete(workspace, loader.Id, loader.Revision) |> get |> ignore

        check
            writer
            "ordinary library removal clears loader selection without erasing profile settings"
            ((store.BepInEx.Read(workspace, first) |> get).Mod.IsNone
             && (store.BepInEx.ReadSettings(workspace, first) |> get).Length > 0
             && not (Directory.Exists(Path.Combine(game, "BepInEx"))))

        writer.WriteEndObject()
