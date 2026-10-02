namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.DeploymentPlanning
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Unreal
open ModConductor.Workspaces

module UnrealFixtures =
    let private get = UnityMonoEnvironment.get

    let create (writer: Utf8JsonWriter) root =
        let game, selected =
            ProtonFixtures.createFor UnrealDefinitions.subnautica2 false root

        let archive = Path.Combine(root, "loader.zip")

        File.WriteAllBytes(
            archive,
            UnityMonoSamples.package
                [ "dwmapi.dll", "fixture proxy"
                  "ue4ss/UE4SS.dll", "fixture core"
                  "ue4ss/UE4SS-settings.ini", "Enabled = true\r\n"
                  "ue4ss/Mods/Marker/scripts/main.lua", "fixture script" ]
        )

        writer.WriteString("game", game)
        writer.WriteString("archive", archive)
        writer.WriteString("compatdata", selected.CompatData)
        writer.WriteString("runtime", selected.RuntimeDirectory)

        match selected.Association with
        | ProtonAssociation.Steam(steam, library) ->
            writer.WriteString("steam", steam)
            writer.WriteString("library", library)
        | ProtonAssociation.Manual -> ()

    let private check (writer: Utf8JsonWriter) (name: string) condition =
        writer.WriteBoolean(name, condition)
        writer.Flush()

        if not condition then
            invalidOp ("Unreal fixture failed: " + name)

    let private selected files =
        let id = Guid.NewGuid()

        { ModId = id
          Priority = 3
          Enabled = true
          Mappings = []
          Archives = []
          Version =
            Some
                { Id = Guid.NewGuid()
                  ModId = id
                  Origin = VersionOrigin.RegisteredSource
                  NextOffset = None
                  Entries =
                    files
                    |> List.map (fun path ->
                        { Path = WorkingPaths.logical (WorkingPaths.parts path)
                          Payload =
                            { Id = Guid.NewGuid()
                              Length = 1L
                              Sha256 = String.replicate 64 "a" } }) } }

    let private destinations (reviewed: ReviewedComponent) =
        reviewed.Mod.Mappings
        |> List.map (fun route ->
            match route.TargetPrefix with
            | PlanPath.At path -> LogicalPath.display path
            | PlanPath.Root -> "")

    let private declarations writer area =
        let original = UnrealDefinitions.subnautica2
        let client = GameClient.unreal original |> Option.get

        let layout =
            match client.Loader.Mechanism with
            | UnrealModMechanism.UE4SS layout -> layout
            | _ -> failwith "fixture"

        let changed =
            { original with
                Name = "Another Unreal Client"
                SteamAppId = 4112233u
                SteamAppIds = [ 4112233u ]
                Executable = "Runtime/Client/Bin/Alternate.exe"
                Data = "Different/Assets" }

        let client =
            { client with
                Loader =
                    { client.Loader with
                        Id = "another-lua-loader"
                        Name = "Alternate loader"
                        Mechanism =
                            UnrealModMechanism.UE4SS
                                { layout with
                                    Core = "loader-core"
                                    Mods = "LuaPackages"
                                    SettingsFile = "configuration/user.ini"
                                    Log = "logs/output.log"
                                    Cache =
                                        [ LoaderWorkingPath.File "cache-state"
                                          LoaderWorkingPath.Directory "cache.data" ] } }
                Arguments = [ "DifferentProject" ]
                Excluded = [ "Different/UserSaves" ] }

        let changed =
            { changed with
                Client = GameClient.Unreal client }

        let game = Path.Combine(area, "declared-game")
        GameContextFixtures.createFor changed false game
        let evidence = InstallationValidation.inspect changed game

        check
            writer
            "changed declaration validates nested executable and content without title layout"
            (evidence.Valid
             && evidence.Executable.Value.Path = Path.Combine(game, changed.Executable)
             && evidence.DataPath = Some(Path.Combine(game, changed.Data)))

        let package =
            selected
                [ "ue4ss/UE4SS.dll"
                  "dwmapi.dll"
                  "ue4ss/UE4SS-settings.ini"
                  "ue4ss/Mods/Bundled/scripts/main.lua" ]

        let routed =
            PackageRoutes.review changed client (Guid.NewGuid()) (Guid.NewGuid()) true [] package
            |> Result.defaultWith invalidOp

        check
            writer
            "changed loader core and working paths follow the declaration"
            (destinations routed |> List.contains "Runtime/Client/Bin/loader-core/UE4SS.dll"
             && destinations routed
                |> List.contains "Runtime/Client/Bin/LuaPackages/Bundled/scripts/main.lua"
             && WorkingPaths.settings changed client = ("Runtime/Client/Bin/configuration/user.ini",
                                                        false))

        let exclusions = WorkingPaths.exclusions changed client
        let working = WorkingPaths.declarations changed client (Guid.NewGuid())

        check
            writer
            "declared independent writable locations retain explicit file and directory shape"
            ([ "LuaPackages"
               "configuration/user.ini"
               "logs/output.log"
               "cache-state"
               "cache.data" ]
             |> List.forall (fun relative ->
                 List.contains ("Runtime/Client/Bin/" + relative) exclusions)
             && working
                |> List.exists (fun item ->
                    match item.Target with
                    | WritableTarget.File(_, path) ->
                        LogicalPath.display path = "Runtime/Client/Bin/cache-state"
                    | _ -> false)
             && working
                |> List.exists (fun item ->
                    match item.Target with
                    | WritableTarget.Subtree(_, PlanPath.At path) ->
                        LogicalPath.display path = "Runtime/Client/Bin/cache.data"
                    | _ -> false))

        let lua = selected [ "Marker/scripts/main.lua"; "Marker/readme.txt" ]

        let routed =
            PackageRoutes.review changed client (Guid.NewGuid()) (Guid.NewGuid()) false [] lua
            |> Result.defaultWith invalidOp

        check
            writer
            "changed Lua destination preserves companions and ordered mod identity"
            (destinations routed
             |> List.contains "Runtime/Client/Bin/LuaPackages/Marker/readme.txt"
             && PackageRoutes.luaNames
                 changed
                 (match client.Loader.Mechanism with
                  | UnrealModMechanism.UE4SS layout -> layout
                  | _ -> failwith "fixture")
                 [ routed ] = [ "Marker" ])

        let state =
            { WorkspaceId = Guid.NewGuid()
              ProfileId = Guid.NewGuid()
              Revision = 1L
              Binding =
                Some
                    { Id = Guid.NewGuid()
                      GameId = changed.Id
                      Path = game
                      Proton = None
                      Wine = None
                      NeedsCheck = false
                      Failure = None
                      Evidence =
                        { evidence with
                            Platform = ContextPlatform.Windows } } }

        let launch =
            Descriptor.createDeclaredWithHost
                true
                false
                changed
                state
                (Path.Combine(area, "private-game"))
                None
                (Some
                    { LoaderEnabled = true
                      GenerationId = Guid.NewGuid()
                      GameSha256 = evidence.Executable.Value.Sha256
                      Environment = [] })
            |> Result.defaultWith invalidOp
            |> fun (_, _, launch) -> launch

        check
            writer
            "Windows projection uses changed executable and Steam identity without Wine overrides"
            (launch.Executable.EndsWith(
                changed.Executable.Replace('/', Path.DirectorySeparatorChar)
             )
             && launch.Environment |> List.contains ("SteamAppId", Some "4112233")
             && launch.Arguments.Head = "DifferentProject"
             && not (launch.Environment |> List.exists (fun (name, _) -> name = "WINEDLLOVERRIDES")))

        check
            writer
            "Proton override merge preserves unrelated names and replaces only the selected proxy"
            (Launch.wineOverrides "other,dwmapi=b;dxgi=n" "dwmapi.dll" = "other=b;dxgi=n;dwmapi=n,b")

        let cooked = UnrealDefinitions.satisfactory

        check
            writer
            "invalid plugin metadata returns a normal routing error"
            ([ "[]"; "{" ]
             |> List.forall (fun value ->
                 PluginDescriptor.gameFeature "Feature" (Encoding.UTF8.GetBytes value)
                 |> Result.isError))

        let cookedClient = GameClient.unreal cooked |> Option.get

        let cookedLayout =
            { Mods = "Custom/Plugins"
              GameFeatures = "Custom/Features"
              Configs = "Custom/UserConfig"
              GameFeatureField = "AnotherFeatureFlag" }

        let cookedClient =
            { cookedClient with
                Loader =
                    { cookedClient.Loader with
                        Mechanism = UnrealModMechanism.CookedPlugins cookedLayout } }

        let plugin =
            selected [ "Wrapped/Visual/Visual.uplugin"; "Wrapped/Visual/Content/Visual.pak" ]

        let routed =
            PackageRoutes.review
                cooked
                cookedClient
                (Guid.NewGuid())
                (Guid.NewGuid())
                false
                [ ([ "Wrapped"; "Visual" ],
                   "Visual",
                   PluginDescriptor.gameFeature
                       "AnotherFeatureFlag"
                       (Encoding.UTF8.GetBytes("{\"AnotherFeatureFlag\":true}"))
                   |> Result.defaultWith invalidOp) ]
                plugin
            |> Result.defaultWith invalidOp

        check
            writer
            "GameFeature metadata routes every companion to the declared plugin destination"
            (destinations routed = [ "Custom/Features/Visual/Visual.uplugin"
                                     "Custom/Features/Visual/Content/Visual.pak" ])

    let private environment (store: OperationStore) area definition =
        let game, proton =
            ProtonFixtures.createFor definition false (Path.Combine(area, "installation"))

        let workspace = Guid.NewGuid()
        let first, second = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let ws = store.Workspaces :> IWorkspaceState

        let initial = ws.Create(workspace, "Unreal", StorageWorker.select root) |> get
        let mutable revision = initial.Workspace.Revision

        for profile in [ first; second ] do
            let current =
                ws.Edit(
                    workspace,
                    revision,
                    ProfileEdit.Create { Id = profile; Name = string profile }
                )
                |> get

            revision <- current.Workspace.Revision

            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = definition.Id
                      Path = game
                      Proton = if OperatingSystem.IsLinux() then Some proton else None
                      Wine = None }
                )
            |> get
            |> ignore

        game, workspace, first, second, root

    let private nexus writer =
        use server = new NexusServer()
        server.Premium <- false
        server.Mode <- "nxm"
        use credentials = new ModConductor.Credentials.CredentialSession(NexusMemoryStore())

        use session =
            new ModConductor.Nexus.NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> System.Threading.Tasks.Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        session.SignIn() |> StorageWorker.wait |> ignore
        let deadline = DateTime.UtcNow.AddSeconds 10.

        while session.Status.Waiting && DateTime.UtcNow < deadline do
            Thread.Sleep 10

        let expires = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()

        let grantId = Guid.NewGuid()

        let accepted =
            session.AcceptNxm(
                grantId,
                "nxm://another-game/mods/36/files/1130?key=synthetic-nxm-private-grant&expires="
                + string expires
                + "&user_id=42"
            )

        use admission =
            session.AdmitNxm(grantId, "42")
            |> Result.defaultWith (fun _ -> invalidOp "The fixture grant could not be admitted.")

        admission.Complete()

        let resolve game file subject =
            session.Resolve(game, 36L, file, subject, requiresLink = true)
            |> StorageWorker.wait

        check
            writer
            "generic Nexus grants remain bound to the exact game, file and account"
            (accepted
             && resolve "another-game" 1130L "42" |> Result.isOk
             && resolve "different-game" 1130L "42" = Error
                 ModConductor.Nexus.NexusProblem.DownloadLinkNeeded
             && resolve "another-game" 1131L "42" = Error
                 ModConductor.Nexus.NexusProblem.DownloadLinkNeeded
             && resolve "another-game" 1130L "another-account" = Error
                 ModConductor.Nexus.NexusProblem.DownloadAccount)

    let observe (writer: Utf8JsonWriter) root =
        let area = Directory.CreateDirectory(Path.Combine(root, "unreal")).FullName
        writer.WriteStartObject("unreal")
        declarations writer area
        use store = new OperationStore(Path.Combine(area, "state"))
        let definition = UnrealDefinitions.subnautica2

        let game, workspace, first, second, workspaceRoot =
            environment store area definition

        let binary = Path.GetDirectoryName(Path.Combine(game, definition.Executable))
        File.WriteAllText(Path.Combine(binary, "dwmapi.dll"), "user proxy")

        Directory.CreateDirectory(Path.Combine(binary, "ue4ss", "Mods", "UserMod", "scripts"))
        |> ignore

        File.WriteAllText(
            Path.Combine(binary, "ue4ss", "Mods", "UserMod", "scripts", "main.lua"),
            "user mod"
        )

        let archive = Path.Combine(area, "loader.zip")

        File.WriteAllBytes(
            archive,
            UnityMonoSamples.package
                [ "dwmapi.dll", "owned proxy"
                  "ue4ss/UE4SS.dll", "owned core"
                  "ue4ss/UE4SS-settings.ini", "Enabled = true\r\n"
                  "ue4ss/Mods/Base/scripts/main.lua", "base"
                  "ue4ss/Mods/Disabled/scripts/main.lua", "disabled"
                  "ue4ss/Mods/Keybinds/scripts/main.lua", "keybinds"
                  "ue4ss/Mods/mods.txt", "Disabled : 0\nBase : 1\nKeybinds : 1\n" ]
        )

        let before = store.Unreal.Read(workspace, first) |> get

        let acquired =
            store.UnrealAcquisition.Acquire(
                workspace,
                first,
                before.ContextRevision,
                archive,
                (fun _ -> System.Threading.Tasks.Task.CompletedTask),
                CancellationToken.None
            )
            |> get

        let firstRoot = UnityMonoEnvironment.deploy store first

        if OperatingSystem.IsLinux() then
            let context = (store.GameContexts :> IGameContexts).Read(workspace, first) |> get

            let _, _, launch =
                Descriptor.createWith context firstRoot None None |> StorageWorker.result

            let roots =
                launch.Environment
                |> List.pick (fun (name, value) ->
                    if name = "STEAM_COMPAT_LIBRARY_PATHS" then value else None)

            check
                writer
                "Proton can reach checked source companions behind private-view links"
                (roots.Split(Path.PathSeparator) |> Array.contains game)

        let privateBinary =
            Path.GetDirectoryName(Path.Combine(firstRoot, definition.Executable))

        check
            writer
            "existing user loader and Lua mods never enter the private profile view"
            (File.ReadAllText(Path.Combine(binary, "dwmapi.dll")) = "user proxy"
             && File.ReadAllText(Path.Combine(privateBinary, "dwmapi.dll")) = "owned proxy"
             && not (Directory.Exists(Path.Combine(privateBinary, "ue4ss", "Mods", "UserMod"))))

        let settings =
            store.Unreal.Text(workspace, first, "UE4SS-settings.ini", None, false) |> get

        store.Unreal.Text(
            workspace,
            first,
            "UE4SS-settings.ini",
            Some(settings, "Enabled = false\n"),
            false
        )
        |> get
        |> ignore

        check
            writer
            "stale editable loader defaults never overwrite profile settings"
            (store.Unreal.Text(
                workspace,
                first,
                "UE4SS-settings.ini",
                Some(settings, "stale"),
                false
             )
             |> StorageWorker.wait
             |> Result.isError)

        UnityMonoEnvironment.deploy store first |> ignore
        let other = store.Unreal.Read(workspace, second) |> get

        store.Unreal.Change(workspace, second, other.ContextRevision, other.SelectionRevision, true)
        |> get
        |> ignore

        let otherRoot = UnityMonoEnvironment.deploy store second

        let otherBinary =
            Path.GetDirectoryName(Path.Combine(otherRoot, definition.Executable))

        check
            writer
            "redeployment retains settings while sibling profiles seed independent defaults"
            (File.ReadAllText(Path.Combine(privateBinary, "ue4ss", "UE4SS-settings.ini")) = "Enabled = false\r\n"
             && File.ReadAllText(Path.Combine(otherBinary, "ue4ss", "UE4SS-settings.ini")) = "Enabled = true\r\n")

        UnrealOrderFixtures.observe
            (check writer)
            store
            workspace
            first
            second
            workspaceRoot
            privateBinary
            otherBinary

        let current = store.Unreal.Read(workspace, first) |> get

        store.Unreal.Change(
            workspace,
            first,
            current.ContextRevision,
            current.SelectionRevision,
            false
        )
        |> get
        |> ignore

        UnityMonoEnvironment.deploy store first |> ignore

        check
            writer
            "loader disablement removes owned proxy without changing original or sibling loader"
            (not (File.Exists(Path.Combine(privateBinary, "dwmapi.dll")))
             && File.ReadAllText(Path.Combine(binary, "dwmapi.dll")) = "user proxy"
             && File.Exists(Path.Combine(otherBinary, "dwmapi.dll")))

        check
            writer
            "Nexus references accept declared game slugs without title allowlisting"
            (ModConductor.HttpDownloads.DownloadSource.valid (
                ModConductor.HttpDownloads.DownloadSource.Nexus
                    { Account = "fixture"
                      Game = "another-game"
                      ModId = 36L
                      FileId = 1130L
                      Keyed = true
                      Version = None }
            ))

        nexus writer

        writer.WriteEndObject()
