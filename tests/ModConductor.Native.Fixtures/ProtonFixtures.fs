namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.GameContexts
open ModConductor.ProtonContexts
open ModConductor.Persistence
open ModConductor.Workspaces

module ProtonFixtures =
    let private write path (text: string) =
        Directory.CreateDirectory(Path.GetDirectoryName(path: string)) |> ignore
        File.WriteAllText(path, text)

    let create primary =
        let steam, library, game = SteamDiscoveryFixtures.create primary
        let data = Path.Combine(library, "steamapps", "compatdata", "489830")
        let prefix = Path.Combine(data, "pfx")
        let runtime = Path.Combine(steam, "compatibilitytools.d", "Custom Ω Proton")

        write
            (Path.Combine(runtime, "proton"))
            "#!/usr/bin/python3\n# owned inert fixture; never execute\n"

        write (Path.Combine(runtime, "version")) "1784681611 fixture-proton-11.0\n"
        write (Path.Combine(runtime, "files", "bin", "wine")) "owned inert fixture"

        write
            (Path.Combine(runtime, "compatibilitytool.vdf"))
            "compatibilitytools { compat_tools { fixture_tool { install_path . display_name \"Fixture Proton Ω\" from_oslist windows to_oslist linux } } }"

        write
            (Path.Combine(steam, "config", "config.vdf"))
            "InstallConfigStore { Software { Valve { Steam { CompatToolMapping { 0 { name fixture_tool priority 75 } } } } } }"

        write (Path.Combine(data, "version")) "Different-prefix-version-10.0\n"

        write
            (Path.Combine(prefix, "user.reg"))
            """WINE REGISTRY Version 2

[Volatile Environment]
"USERPROFILE"="C:\\users\\steamuser"
"HOMEDRIVE"="C:"
"HOMEPATH"="\\users\\steamuser"

[Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders]
"Personal"=str(2):"%USERPROFILE%\\Documents"
"Local AppData"=str(2):"%USERPROFILE%\\AppData\\Local"
"AppData"=str(2):"%USERPROFILE%\\AppData\\Roaming"
"""

        Directory.CreateDirectory(
            Path.Combine(
                prefix,
                "drive_c",
                "users",
                "steamuser",
                "Documents",
                "My Games",
                "Skyrim Special Edition",
                "Saves"
            )
        )
        |> ignore

        if OperatingSystem.IsLinux() then
            Directory.CreateDirectory(Path.Combine(prefix, "dosdevices")) |> ignore

            Directory.CreateSymbolicLink(Path.Combine(prefix, "dosdevices", "c:"), "../drive_c")
            |> ignore

            Directory.CreateSymbolicLink(Path.Combine(prefix, "dosdevices", "z:"), "/")
            |> ignore

        game,
        { AppId = 489830u
          Association = ProtonAssociation.Steam(steam, library)
          CompatData = data
          RuntimeDirectory = runtime
          ToolId = "fixture_tool" }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Path.Combine(primary, "proton")
        let game, selected = create area
        let installation = InstallationValidation.inspect Skyrim.definition game
        let checkedContext = Validation.inspect installation selected
        writer.WriteStartObject("proton")

        if not (OperatingSystem.IsLinux()) then
            writer.WriteBoolean(
                "nativeWindowsPreserved",
                installation.Valid && installation.Platform = ContextPlatform.Windows
            )

            writer.WriteBoolean(
                "protonUnsupported",
                not checkedContext.Valid && checkedContext.Proton.IsNone
            )
        else
            if not checkedContext.Valid then
                invalidOp (checkedContext.Problems |> List.map _.Detail |> String.concat " ")

            let observed = checkedContext.Proton.Value

            let bytes path =
                File.ReadAllBytes path |> SHA256.HashData |> Convert.ToHexStringLower

            let registry = Path.Combine(observed.PrefixPath, "user.reg")
            let original = File.ReadAllText registry
            let initialHash = bytes registry

            let roots: ModConductor.SteamDiscovery.SearchRoot list =
                match selected.Association with
                | ProtonAssociation.Steam(root, _) -> [ { Path = root; Origin = "Fixture" } ]
                | ProtonAssociation.Manual -> []

            let search = Search.discover game roots CancellationToken.None

            writer.WriteBoolean(
                "defaultPrefixAndToolFound",
                search.Prefixes.Length = 1 && search.Tools.Length = 1
            )

            writer.WriteBoolean(
                "globalOnlyNotActive",
                observed.PerGameTool.IsNone
                && observed.GlobalTool = Some "fixture_tool"
                && observed.MappingProblem.IsNone
            )

            writer.WriteBoolean(
                "runtimeAndPrefixVersionsDistinct",
                observed.RuntimeVersion = "1784681611 fixture-proton-11.0"
                && observed.PrefixVersion = Some "Different-prefix-version-10.0"
            )

            writer.WriteBoolean(
                "prefixUserPathsLocated",
                match checkedContext.Locations.Saves with
                | Location.Located(path, true) ->
                    path.StartsWith(observed.PrefixPath, StringComparison.Ordinal)
                    && observed.Paths.Head.WindowsPath.Value.StartsWith(
                        "C:\\users\\steamuser",
                        StringComparison.Ordinal
                    )
                | _ -> false
            )

            writer.WriteBoolean(
                "absentLeavesNotCreated",
                match checkedContext.Locations.LocalAppData with
                | Location.Located(path, false) -> not (Directory.Exists path)
                | _ -> false
            )

            writer.WriteBoolean("readOnlyRegistry", bytes registry = initialHash)

            let documents =
                Path.Combine(observed.PrefixPath, "drive_c", "users", "steamuser", "Documents")

            let originalDocuments = documents + ".original"
            Directory.Move(documents, originalDocuments)
            Directory.CreateSymbolicLink(documents, "Documents.original") |> ignore
            let linked = Validation.inspect installation selected

            writer.WriteBoolean(
                "internalRedirectLocated",
                match linked.Locations.Saves with
                | Location.Located(path, true) ->
                    path.Contains("Documents.original", StringComparison.Ordinal)
                | _ -> false
            )

            Directory.Delete documents
            let external = Path.Combine(area, "External documents")
            Directory.CreateDirectory(external) |> ignore
            Directory.CreateSymbolicLink(documents, external) |> ignore
            let outside = Validation.inspect installation selected

            writer.WriteBoolean(
                "externalRedirectUnavailable",
                match outside.Locations.Saves with
                | Location.Unavailable _ -> Directory.GetFileSystemEntries(external).Length = 0
                | _ -> false
            )

            Directory.Delete documents
            Directory.Move(originalDocuments, documents)

            Directory.CreateDirectory(
                Path.Combine(observed.PrefixPath, "drive_c", "users", "steamuser", "documents")
            )
            |> ignore

            let ambiguous = Validation.inspect installation selected

            writer.WriteBoolean(
                "caseAmbiguityUnavailable",
                match ambiguous.Locations.Documents with
                | Location.Unavailable _ -> true
                | _ -> false
            )

            Directory.Delete(
                Path.Combine(observed.PrefixPath, "drive_c", "users", "steamuser", "documents")
            )

            File.WriteAllText(registry, original.Replace("%USERPROFILE%", "%UNKNOWN%"))
            let unknown = Validation.inspect installation selected

            writer.WriteBoolean(
                "unknownVariableNoHostFallback",
                match unknown.Locations.Documents with
                | Location.Unavailable _ -> true
                | _ -> false
            )

            File.WriteAllText(registry, original)
            let foreign = Validation.inspect installation { selected with AppId = 1u }
            writer.WriteBoolean("foreignAppRefused", not foreign.Valid)

            let foreignData =
                Path.Combine(Directory.GetParent(selected.CompatData).FullName, "123")

            Directory.CreateDirectory(Path.Combine(foreignData, "pfx")) |> ignore

            let foreignLibrary =
                Directory.GetParent(Directory.GetParent(foreignData).FullName).Parent.FullName

            write
                (Path.Combine(foreignLibrary, "steamapps", "appmanifest_123.acf"))
                "AppState { appid 123 installdir OtherGame }"

            let foreignAlias = Path.Combine(area, "Manual alias")
            Directory.CreateSymbolicLink(foreignAlias, foreignData) |> ignore

            let conflicting =
                Validation.inspect
                    installation
                    { selected with
                        Association = ProtonAssociation.Manual
                        CompatData = foreignAlias }

            writer.WriteBoolean("manualAliasCannotHideForeignApp", not conflicting.Valid)

            let manual =
                Validation.inspect
                    installation
                    { selected with
                        Association = ProtonAssociation.Manual }

            writer.WriteBoolean(
                "manualAssociationExplicit",
                manual.Valid
                && manual.Proton.Value.MappingProblem.IsSome
                && manual.Proton.Value.GlobalTool.IsNone
            )

            let nestedRuntime = Path.Combine(area, "Nested tool")
            let nestedFiles = Path.Combine(nestedRuntime, "installation")
            Directory.CreateDirectory(nestedFiles) |> ignore

            for name in [ "proton"; "version" ] do
                File.Copy(
                    Path.Combine(selected.RuntimeDirectory, name),
                    Path.Combine(nestedFiles, name)
                )

            write (Path.Combine(nestedFiles, "files", "bin", "wine")) "owned inert fixture"

            let toolManifest =
                File.ReadAllText(Path.Combine(selected.RuntimeDirectory, "compatibilitytool.vdf"))

            write
                (Path.Combine(nestedRuntime, "compatibilitytool.vdf"))
                (toolManifest.Replace("install_path .", "install_path installation"))

            let nested =
                Validation.inspect
                    installation
                    { selected with
                        RuntimeDirectory = nestedRuntime }

            writer.WriteBoolean(
                "declaredRuntimeSubdirectory",
                nested.Valid
                && nested.Proton.Value.Launcher.Path = Path.Combine(nestedFiles, "proton")
                && nested.Proton.Value.Selection.RuntimeDirectory = nestedRuntime
            )

            let statePath = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
            let workspace = Guid.NewGuid()
            let profile = Guid.NewGuid()
            let wait = StorageWorker.wait
            let result = StorageWorker.result
            let mutable saved = Unchecked.defaultof<GameContextState>

            do
                use store = new OperationStore(statePath)
                let contexts = store.GameContexts :> IGameContexts
                let workspaces = store.Workspaces :> IWorkspaceState

                let workspaceRoot =
                    Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

                let created =
                    workspaces.Create(workspace, "Proton", StorageWorker.select workspaceRoot)
                    |> wait
                    |> result

                workspaces.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "Proton" }
                )
                |> wait
                |> result
                |> ignore

                saved <-
                    contexts.Save(
                        workspace,
                        profile,
                        0L,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Proton = Some { selected with ToolId = "" } }
                    )
                    |> wait
                    |> result

                writer.WriteBoolean(
                    "observedToolIdentityPersisted",
                    saved.Binding.Value.Proton.Value.ToolId = selected.ToolId
                )

                let stale = contexts.Save(workspace, profile, 0L, { GameId = GameId.SkyrimSpecialEditionSteam
                                                                    Path = game; Proton = None }) |> wait

                writer.WriteBoolean(
                    "staleDoesNotDropSelection",
                    stale = Error ContextError.StaleRevision
                    && (contexts.Read(workspace, profile) |> wait |> result) = saved
                )

                let invalid =
                    contexts.Save(
                        workspace,
                        profile,
                        saved.Revision,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Proton =
                            Some
                                { selected with
                                    RuntimeDirectory = Path.Combine(area, "absent") } }
                    )
                    |> wait

                writer.WriteBoolean(
                    "invalidReplacementAtomic",
                    Result.isError invalid && (contexts.Read(workspace, profile) |> wait |> result) = saved
                )

                File.Move(
                    Path.Combine(selected.RuntimeDirectory, "proton"),
                    Path.Combine(selected.RuntimeDirectory, "proton.hidden")
                )

                let failed = contexts.Refresh(workspace, profile, saved.Revision) |> wait |> result

                writer.WriteBoolean(
                    "failedRefreshRetainsPins",
                    failed.Binding.Value.NeedsCheck
                    && failed.Binding.Value.Evidence = saved.Binding.Value.Evidence
                    && failed.Binding.Value.Proton = saved.Binding.Value.Proton
                )

                File.Move(
                    Path.Combine(selected.RuntimeDirectory, "proton.hidden"),
                    Path.Combine(selected.RuntimeDirectory, "proton")
                )

                saved <- contexts.Refresh(workspace, profile, failed.Revision) |> wait |> result

            do
                use store = new OperationStore(statePath)

                let reopened =
                    (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

                writer.WriteBoolean(
                    "restartRetainsSelectionAndRequiresCheck",
                    reopened.Binding.Value.NeedsCheck
                    && reopened.Binding.Value.Proton = saved.Binding.Value.Proton
                    && reopened.Binding.Value.Evidence = saved.Binding.Value.Evidence
                )

        writer.WriteEndObject()
