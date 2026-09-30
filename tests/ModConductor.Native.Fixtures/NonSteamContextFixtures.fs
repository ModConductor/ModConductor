namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Buffers.Binary
open System.Text.Json
open Microsoft.Data.Sqlite
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Skse
open ModConductor.Nexus
open ModConductor.Workspaces
open ModConductor.ProfileGameData
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Executables
open System.Threading

module NonSteamContextFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private gogGame path =
        GameContextFixtures.create path 1179

        for name in [ "SkyrimSE.exe"; "SkyrimSELauncher.exe" ] do
            let file = Path.Combine(path, name)
            let bytes = File.ReadAllBytes file

            for offset in [ 816; 824 ] do
                BinaryPrimitives.WriteUInt32LittleEndian(bytes.AsSpan(offset, 4), 0x10006u)

            File.WriteAllBytes(file, bytes)

    let private file id gog runtime =
        { Id = id
          Name = if gog then "SKSE GOG" else "SKSE Steam"
          Version = "2.2.6"
          Category = "MAIN"
          Description =
            "Compatible with Skyrim Special Edition "
            + runtime
            + (if gog then " from GOG" else " from Steam")
          Bytes = None }
        : NexusFile

    let private prefix root =
        let path = Path.Combine(root, "wine-prefix")
        let user = Path.Combine(path, "drive_c", "users", "player")

        let documents =
            Path.Combine(user, "Documents", "My Games", "Skyrim Special Edition GOG")

        Directory.CreateDirectory(Path.Combine(documents, "Saves")) |> ignore

        Directory.CreateDirectory(
            Path.Combine(user, "AppData", "Local", "Skyrim Special Edition GOG")
        )
        |> ignore

        Directory.CreateDirectory(Path.Combine(path, "dosdevices")) |> ignore

        Directory.CreateSymbolicLink(Path.Combine(path, "dosdevices", "c:"), "../drive_c")
        |> ignore

        File.WriteAllText(
            Path.Combine(path, "user.reg"),
            """WINE REGISTRY Version 2

[Volatile Environment]
"USERPROFILE"="C:\\users\\player"

[Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders]
"Personal"=str(2):"%USERPROFILE%\\Documents"
"Local AppData"=str(2):"%USERPROFILE%\\AppData\\Local"
            """
        )

        path, documents

    let private createWorkspace (store: OperationStore) area workspace profile =
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Contexts", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "GOG" }
        )
        |> wait
        |> result
        |> ignore

    let private windows (state: GameContextState) =
        let binding = state.Binding.Value

        { state with
            Binding =
                Some
                    { binding with
                        Wine = None
                        Evidence =
                            { binding.Evidence with
                                Platform = ContextPlatform.Windows
                                Wine = None } } }

    let private profileProjection
        (writer: Utf8JsonWriter)
        (store: OperationStore)
        area
        workspace
        profile
        game
        documents
        wineExecutable
        =
        BethesdaSamples.requiredBaseFiles game
        File.WriteAllText(Path.Combine(game, "Data", "Marker.txt"), "base")
        File.WriteAllText(Path.Combine(documents, "Skyrim.ini"), "[General]\nsTest=global\n")

        let managed =
            Directory.CreateDirectory(Path.Combine(area, "workspace", "Managed")).FullName

        File.WriteAllText(Path.Combine(managed, "Marker.txt"), "profile")
        let library = store.ModLibrary :> IModLibrary
        let modId, version = Guid.NewGuid(), Guid.NewGuid()

        let registered =
            library.Register(
                workspace,
                modId,
                { Name = "Managed"
                  Version = "1"
                  Notes = ""
                  Comment = ""
                  Source = ""
                  Categories = [] },
                Registration.Directory(
                    ModKind.Regular,
                    LogicalPath.create [ "Managed" ]
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid fixture path.")
                )
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
        let selected = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, selected.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let data = store.ProfileGameData
        let before = data.Read(workspace, profile) |> wait |> result

        let enabled =
            data.Edit(
                { Id = Guid.NewGuid()
                  Expected = before.Reference
                  Options = { Settings = true; Saves = true }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        File.WriteAllText(
            Path.Combine(enabled.State.SettingsPath, "Skyrim.ini"),
            "[General]\nsTest=profile\n"
        )

        File.WriteAllText(Path.Combine(enabled.State.SavesPath, "owned.ess"), "profile save")
        let capture = Path.Combine(area, "profile-read.txt")

        let script =
            "#!/bin/sh\nset -e\ncat Data/Marker.txt > '"
            + capture
            + "'\ncat '"
            + Path.Combine(documents, "Skyrim.ini")
            + "' >> '"
            + capture
            + "'\ntest -f '"
            + Path.Combine(
                documents,
                ".mod-conductor-saves-" + enabled.State.Reference.ContextId.ToString("N"),
                "owned.ess"
            )
            + "'\ntest -z \"${SteamAppId+x}\"\ntest -z \"${STEAM_COMPAT_DATA_PATH+x}\"\n"

        File.WriteAllText(wineExecutable, script)

        File.SetUnixFileMode(
            wineExecutable,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        let contexts = store.GameContexts :> IGameContexts
        let prior = contexts.Read(workspace, profile) |> wait |> result
        contexts.Refresh(workspace, profile, prior.Revision) |> wait |> result |> ignore

        let current =
            (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

        let launch = store.GameLaunching.Read(workspace, profile) |> wait |> result

        let started =
            store.GameLaunching.Begin
                { Id = Guid.NewGuid()
                  WorkspaceId = workspace
                  ProfileId = profile
                  WorkspaceRevision = current.Workspace.Revision
                  ContextRevision = launch.ContextRevision
                  SourceToken = launch.SourceToken }
            |> wait
            |> result

        let deadline = DateTime.UtcNow.AddSeconds 15.
        let mutable run = started

        while run.Phase <> RunPhase.Finished
              && run.Phase <> RunPhase.Failed
              && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            run <- store.Executables.Read(workspace, started.Id) |> wait |> result

        let deployed = store.Deployments.Read profile |> wait |> result

        writer.WriteBoolean(
            "nonSteamLaunchAppliesManagedFilesSettingsAndSaves",
            run.Phase = RunPhase.Finished
            && run.RootExitCode = Some 0
            && File.ReadAllText(capture).Contains("profile")
            && File.ReadAllText(capture).Contains("sTest=profile")
            && File.ReadAllText(Path.Combine(game, "Data", "Marker.txt")) = "base"
            && deployed.RunnableRoot.Contains(".mc-game-views")
        )

    let private wineContexts
        (writer: Utf8JsonWriter)
        (store: OperationStore)
        area
        workspace
        profile
        game
        runRoot
        (incomplete: GameContextState)
        =
        let contexts = store.GameContexts :> IGameContexts
        let mutable current = incomplete
        let winePrefix, documents = prefix area
        let wineExecutable = Path.Combine(area, "wine-fixture")
        File.WriteAllText(wineExecutable, "#!/bin/sh\nexit 0\n")

        File.SetUnixFileMode(
            wineExecutable,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        let selection =
            { Executable = wineExecutable
              Prefix = winePrefix }

        let saved =
            contexts.Save(
                workspace,
                profile,
                incomplete.Revision,
                { GameId = GameId.SkyrimSpecialEditionGog
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait
            |> result

        current <- saved
        let evidence = saved.Binding.Value.Evidence

        let path value =
            match value with
            | Location.Located(path, _) -> path
            | Location.Unavailable reason -> failwith reason

        writer.WriteBoolean(
            "wineGogPathsAndSelectionRoundTrip",
            evidence.Wine.Value.Selection = selection
            && evidence.Proton.IsNone
            && path evidence.Locations.Documents = documents
            && path evidence.Locations.Saves = Path.Combine(documents, "Saves")
            && (contexts.Read(workspace, profile) |> wait |> result) = current
        )

        let projected =
            Descriptor.createToolWithHost
                false
                true
                saved
                runRoot
                None
                None
                (Guid.NewGuid())
                "Data/tool.exe"
                [ "--profile" ]
            |> result

        writer.WriteBoolean(
            "wineToolKeepsSelectedPrefixAndProfileRoot",
            projected.Launch.Executable = wineExecutable
            && projected.Launch.Arguments = [ Path.Combine(runRoot, "Data", "tool.exe")
                                              "--profile" ]
            && projected.Launch.WorkingDirectory = runRoot
            && (projected.Launch.Environment |> Map.ofList)["WINEPREFIX"] = Some winePrefix
        )

        profileProjection writer store area workspace profile game documents wineExecutable
        current <- contexts.Read(workspace, profile) |> wait |> result

        let stale =
            contexts.Save(
                workspace,
                profile,
                incomplete.Revision,
                { GameId = GameId.SkyrimSpecialEditionDirect
                  Path = game
                  Proton = None
                  Wine = None }
            )
            |> wait

        writer.WriteBoolean(
            "staleContextSwitchPreservesWine",
            stale = Error ContextError.StaleRevision
            && (contexts.Read(workspace, profile) |> wait |> result) = current
        )

        let wrongRuntime =
            contexts.Save(
                workspace,
                profile,
                saved.Revision,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait

        writer.WriteBoolean(
            "steamCannotAcquireStandaloneWine",
            Result.isError wrongRuntime
            && (contexts.Read(workspace, profile) |> wait |> result) = current
        )

        let documentsParent =
            Path.Combine(winePrefix, "drive_c", "users", "player", "Documents")

        Directory.Move(documentsParent, Path.Combine(area, "external-documents"))

        Directory.CreateSymbolicLink(documentsParent, Path.Combine(area, "external-documents"))
        |> ignore

        let refreshed =
            contexts.Refresh(workspace, profile, current.Revision) |> wait |> result

        current <- refreshed

        writer.WriteBoolean(
            "wineUsesExplicitExistingDocumentsRedirect",
            path refreshed.Binding.Value.Evidence.Locations.Documents =
                Path.Combine(area, "external-documents", "My Games", "Skyrim Special Edition GOG")
        )

        let manual =
            contexts.Save(
                workspace,
                profile,
                refreshed.Revision,
                { GameId = GameId.SkyrimSpecialEditionDirect
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait
            |> result

        current <- manual

        writer.WriteBoolean(
            "manualGogRuntimeUsesGogPathsWithoutSteamProvenance",
            manual.Binding.Value.GameId = GameId.SkyrimSpecialEditionDirect
            && manual.Binding.Value.Evidence.Proton.IsNone
            && path manual.Binding.Value.Evidence.Locations.Documents = path
                refreshed.Binding.Value.Evidence.Locations.Documents
        )

        let pending =
            contexts.Save(
                workspace,
                profile,
                manual.Revision,
                { GameId = GameId.SkyrimSpecialEditionGog
                  Path = game
                  Proton = None
                  Wine =
                    Some
                        { Executable = wineExecutable
                          Prefix = "" } }
            )
            |> wait
            |> result

        writer.WriteBoolean(
            "partialRuntimeRetainedWithoutOldCheckedRuntime",
            pending.Binding.Value.Wine.Value.Executable = wineExecutable
            && pending.Binding.Value.Evidence.Wine.IsNone
            && pending.Binding.Value.Evidence.Valid
            && pending.Binding.Value.Failure.IsNone
        )

        current <-
            contexts.Save(
                workspace,
                profile,
                pending.Revision,
                { GameId = GameId.SkyrimSpecialEditionGog
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait
            |> result

        current

    let observe (writer: Utf8JsonWriter) area =
        Directory.CreateDirectory area |> ignore
        let game = Path.Combine(area, "game")
        gogGame game
        let stateDirectory = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let workspace, profile, clone = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        writer.WriteStartObject("nonSteam")
        let mutable released = Unchecked.defaultof<GameContextState>
        let mutable selectedProfile = None

        do
            use store = new OperationStore(stateDirectory)
            createWorkspace store area workspace profile
            let contexts = store.GameContexts :> IGameContexts

            let incomplete =
                contexts.Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionGog
                      Path = game
                      Proton = None
                      Wine = None }
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "incompleteRuntimeRetainsInstallation",
                incomplete.Binding.Value.Evidence.Valid
                && not incomplete.Binding.Value.NeedsCheck
                && incomplete.Binding.Value.Failure.IsNone
                && not (ContextRuntime.ready incomplete.Binding.Value.Evidence)
            )

            let runRoot = Directory.CreateDirectory(Path.Combine(area, "runnable")).FullName

            writer.WriteBoolean(
                "incompleteRuntimeCannotPlay",
                Descriptor.createWith incomplete runRoot None None |> Result.isError
            )

            let direct = windows incomplete

            let launch =
                Descriptor.createToolWithHost
                    true
                    false
                    direct
                    runRoot
                    None
                    None
                    (Guid.NewGuid())
                    "Data/tool.exe"
                    [ "--profile" ]
                |> result

            let environment = launch.Launch.Environment |> Map.ofList

            writer.WriteBoolean(
                "windowsDirectAndToolsUseProfileRootWithoutSteam",
                launch.Launch.Executable = Path.Combine(runRoot, "Data", "tool.exe")
                && launch.Launch.WorkingDirectory = runRoot
                && environment["SteamAppId"].IsNone
                && environment["SteamGameId"].IsNone
            )

            let releases =
                SkseResolver.releases
                    { Game = "skyrimspecialedition"
                      Id = SkseResolver.NexusModId
                      Name = "SKSE"
                      Summary = ""
                      Author = ""
                      Category = ""
                      Picture = None
                      Files = [ file 1L false "1.6.1179"; file 2L true "1.6.1179" ] }

            writer.WriteBoolean(
                "gogSkseCannotSelectSameVersionSteamBuild",
                (SkseResolver.resolve incomplete releases |> result).File.Id = 2L
            )

            let unknown =
                { incomplete with
                    Binding =
                        Some
                            { incomplete.Binding.Value with
                                GameId = GameId.SkyrimSpecialEditionDirect
                                Evidence =
                                    { incomplete.Binding.Value.Evidence with
                                        DefinitionId = GameId.SkyrimSpecialEditionDirect
                                        Executable =
                                            Some
                                                { incomplete.Binding.Value.Evidence.Executable.Value with
                                                    FileVersion = "9.0.0.0" } } } }

            writer.WriteBoolean(
                "unknownManualEditionLimitsSkseNotBaseLaunch",
                (SkseResolver.resolve unknown releases |> Result.isError)
                && (Descriptor.createToolWithHost
                        true
                        false
                        (windows unknown)
                        runRoot
                        None
                        None
                        (Guid.NewGuid())
                        "Data/tool.exe"
                        []
                    |> Result.isOk)
            )

            let mutable current = incomplete

            if OperatingSystem.IsLinux() then
                current <- wineContexts writer store area workspace profile game runRoot incomplete

            let workspaces = store.Workspaces :> IWorkspaceState
            let page = workspaces.Read(workspace, None) |> wait |> result

            workspaces.Edit(
                workspace,
                page.Workspace.Revision,
                ProfileEdit.Clone(profile, { Id = clone; Name = "Clone" })
            )
            |> wait
            |> result
            |> ignore

            let cloned = contexts.Read(workspace, clone) |> wait |> result

            writer.WriteBoolean(
                "clonePreservesWineWithoutSharingBinding",
                cloned.Binding.Value.Wine = current.Binding.Value.Wine
                && cloned.Binding.Value.Id <> current.Binding.Value.Id
            )

            let steam =
                contexts.Save(
                    workspace,
                    profile,
                    current.Revision,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton = None
                      Wine = None }
                )
                |> wait
                |> result

            released <- steam

            selectedProfile <-
                (workspaces.Read(workspace, None) |> wait |> result).Workspace.SelectedProfile

        do
            use connection =
                new SqliteConnection(
                    "Data Source=" + Path.Combine(stateDirectory, "state.db") + ";Pooling=False"
                )

            connection.Open()

            Sqlite.execute
                connection
                null
                "ALTER TABLE game_contexts DROP COLUMN wine_selection; PRAGMA user_version=1;"
                []

            let mutable rolledBack = false

            try
                Sqlite.initializeAtCommit connection (fun () -> invalidOp "fixture interruption")
            with :? InvalidOperationException ->
                rolledBack <- true

            writer.WriteBoolean(
                "releasedUpgradeRollsBackBeforeCommit",
                rolledBack
                && Sqlite.number connection null "PRAGMA user_version" [] = 1L
                && Sqlite.number
                    connection
                    null
                    "SELECT count(*) FROM pragma_table_info('game_contexts') WHERE name='wine_selection'"
                    [] = 0L
            )

        do
            use restarted = new OperationStore(stateDirectory)

            let preserved =
                (restarted.GameContexts :> IGameContexts).Read(workspace, profile)
                |> wait
                |> result

            let cloned =
                (restarted.GameContexts :> IGameContexts).Read(workspace, clone)
                |> wait
                |> result

            writer.WriteBoolean(
                "releasedSteamStateAndProfileSelectionSurviveUpgrade",
                preserved.Binding.Value.Id = released.Binding.Value.Id
                && preserved.Revision = released.Revision
                && preserved.Binding.Value.GameId = released.Binding.Value.GameId
                && GameContextEncoding.encode preserved.Binding.Value.Evidence = GameContextEncoding.encode
                    released.Binding.Value.Evidence
                && preserved.Binding.Value.Proton = released.Binding.Value.Proton
                && preserved.Binding.Value.Wine.IsNone
                && preserved.Binding.Value.NeedsCheck
                && cloned.Binding.IsSome
                && ((restarted.Workspaces :> IWorkspaceState).Read(workspace, None)
                    |> wait
                    |> result)
                    .Workspace.SelectedProfile = selectedProfile
            )

        writer.WriteEndObject()
