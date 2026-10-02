namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text.Json
open System.Threading
open ModConductor.GameCatalogue
open ModConductor.GameCatalogue.Serialization
open ModConductor.GameContexts
open ModConductor.GameDiscovery
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.ModSelection
open ModConductor.SteamDiscovery
open ModConductor.Thunderstore

module GameRegistrationFixtures =
    let private get = UnityMonoEnvironment.get
    let private token = CancellationToken.None

    let private check (writer: Utf8JsonWriter) (name: string) passed =
        writer.WriteBoolean(name, passed)

        if not passed then
            invalidOp ("Game registration fixture failed: " + name)

    let private save (store: OperationStore) d =
        store.GameCatalogue.Save d |> StorageWorker.result

    let private binding writer (store: OperationStore) area definition game proton =
        let workspace, profile, _, _ =
            UnityMonoEnvironment.createFor store area definition game proton

        let state = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        check
            writer
            "customProfileUsesStableIdentity"
            (state.Binding.Value.GameId = definition.Id
             && state.Binding.Value.Path = game
             && state.Binding.Value.Evidence.Valid
             && not state.Binding.Value.NeedsCheck)

        workspace, profile

    let private portable
        (writer: Utf8JsonWriter)
        (store: OperationStore)
        area
        workspace
        profile
        (d: GameDocument)
        =
        writer.WriteStartObject "portable"
        let bundle = Path.Combine(area, "portable.mcprof")

        store.ProfileTransport.Export(workspace, profile, bundle, false, token)
        |> get
        |> ignore

        use zip = ZipFile.OpenRead bundle

        let metadata =
            zip.Entries
            |> Seq.find (fun entry -> entry.FullName.EndsWith(".json", StringComparison.Ordinal))

        use source = new StreamReader(metadata.Open())
        let text = source.ReadToEnd()

        check
            writer
            "portableCarriesDefinitionWithoutLocalPath"
            (text.Contains("gameDefinition")
             && text.Contains(d.Id)
             && not (text.Contains(area)))

        use imported = new OperationStore(Path.Combine(area, "import-state"))

        let observed = imported.ProfileTransport.Inspect bundle
        check writer "portableInspectionDoesNotRegister" ((imported.GameCatalogue.Read d.Id).IsNone)
        let embedded = observed.GameDefinition |> Option.get
        let definition = save imported embedded

        let game, proton =
            if (GameClient.mono definition).IsSome then
                UnityMonoSamples.create definition (Path.Combine(area, "import-installation")), None
            else
                let game, proton =
                    ProtonFixtures.createFor
                        definition
                        false
                        (Path.Combine(area, "import-installation"))

                game, (if OperatingSystem.IsLinux() then Some proton else None)

        let workspace, target =
            binding writer imported (Path.Combine(area, "import")) definition game proton

        let profile =
            imported.ProfileTransport.Import(
                bundle,
                workspace,
                Some target,
                "Imported",
                Map.empty,
                token
            )
            |> get

        let context =
            (imported.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        check writer "portableImportUsesDestinationInstallation" (context.Binding.Value.Path = game)

        let before = imported.GameCatalogue.Read d.Id |> Option.get

        imported.ProfileTransport.Import(
            bundle,
            workspace,
            Some target,
            "Imported again",
            Map.empty,
            token
        )
        |> get
        |> ignore

        check
            writer
            "portableReusesRegisteredIdentity"
            ((imported.GameCatalogue.Read d.Id).Value.Revision = before.Revision)

        check
            writer
            "portableImportRegistersCustomDefinition"
            (imported.GameCatalogue.Read(d.Id).IsSome && profile <> Guid.Empty)

        writer.WriteEndObject()

    let private mono writer area =
        let stateDirectory = Path.Combine(area, "mono-state")
        use store = new OperationStore(stateDirectory)
        let d = KnownDefinition.draft Valheim.definition
        d.Name <- "Same name"
        d.SteamAppId <- 990001u
        d.Executable <- "Fixture.exe"
        d.LinuxExecutable <- "Fixture.x86_64"
        d.Content <- "Fixture_Data"
        let definition = save store d
        let duplicate = KnownDefinition.draft Valheim.definition
        duplicate.Name <- d.Name
        let other = save store duplicate

        check
            writer
            "duplicateNamesRetainDistinctIdentities"
            (other.Id <> definition.Id
             && (GameCatalog.forGame definition.Id).Name = (GameCatalog.forGame other.Id).Name)

        let original = File.ReadAllText(Path.Combine(stateDirectory, "games.toml"))
        let invalid = KnownDefinition.draft Valheim.definition
        invalid.Executable <- "../outside.exe"

        check
            writer
            "invalidSavePreservesCatalogue"
            (store.GameCatalogue.Save invalid |> Result.isError
             && original = File.ReadAllText(Path.Combine(stateDirectory, "games.toml")))

        let game =
            UnityMonoSamples.create definition (Path.Combine(area, "mono-installation"))

        GameDiscoveryFixtures.observe writer game
        let workspace, profile = binding writer store area definition game None
        let root = UnityMonoEnvironment.deploy store profile
        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        let descriptor = Descriptor.createWith context root None None

        let expected =
            Path.Combine(root, GameClient.executable (OperatingSystem.IsLinux()) definition)

        check
            writer
            "customMonoReachesDeploymentAndLaunchBoundary"
            (Directory.Exists root
             && descriptor
                |> Result.toOption
                |> Option.exists (fun (_, _, launch) ->
                    launch.Executable = expected || List.contains expected launch.Arguments))

        portable writer store area workspace profile d
        let reloaded = Catalogue(stateDirectory)

        check
            writer
            "restartPreservesIdsAndDuplicates"
            ((reloaded.Read d.Id).IsSome
             && (GameCatalog.forGame definition.Id).Name = d.Name
             && GameCatalog.customDefinitions().Length = 2)

        let edit = reloaded.Read d.Id |> Option.get
        let stale = reloaded.Read d.Id |> Option.get
        edit.Name <- "Renamed"
        reloaded.Save edit |> StorageWorker.result |> ignore

        check
            writer
            "staleDefinitionEditPreservesNewerSave"
            (reloaded.Save stale |> Result.isError
             && (reloaded.Read d.Id).Value.Name = "Renamed")

        let current = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        check
            writer
            "definitionEditRetainsLocalPathAndRequiresCheck"
            (current.Binding.Value.Path = game
             && current.Binding.Value.GameId = definition.Id
             && current.Binding.Value.NeedsCheck)

    let private unreal writer area =
        use store = new OperationStore(Path.Combine(area, "unreal-state"))
        let d = KnownDefinition.draft UnrealDefinitions.subnautica2
        d.Name <- "Same name"
        d.SteamAppId <- 990002u
        let definition = save store d

        let game, proton =
            ProtonFixtures.createFor definition false (Path.Combine(area, "unreal-installation"))

        let workspace, profile =
            binding
                writer
                store
                (Path.Combine(area, "unreal"))
                definition
                game
                (if OperatingSystem.IsLinux() then Some proton else None)

        let root = UnityMonoEnvironment.deploy store profile
        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        let descriptor = Descriptor.createWith context root None None

        check
            writer
            "customUnrealReachesDeploymentAndLaunchBoundary"
            (Directory.Exists root
             && descriptor
                |> Result.toOption
                |> Option.exists (fun (_, _, launch) ->
                    launch.Executable.EndsWith(definition.Executable, StringComparison.Ordinal)
                    || launch.Arguments
                       |> List.contains (Path.Combine(root, definition.Executable))))

        portable writer store (Path.Combine(area, "unreal")) workspace profile d

    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject "gameRegistration"
        writer.WriteStartObject "mono"
        mono writer area
        writer.WriteEndObject()
        writer.WriteStartObject "unreal"
        unreal writer area
        writer.WriteEndObject()
        writer.WriteEndObject()
