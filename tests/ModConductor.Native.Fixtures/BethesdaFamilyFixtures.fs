namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module BethesdaFamilyFixtures =
    let private get value =
        StorageWorker.wait value
        |> Result.defaultWith (fun error ->
            let detail =
                match box error with
                | :? DeploymentError as error ->
                    match error with
                    | DeploymentError.Blocked detail
                    | DeploymentError.Unavailable detail -> detail
                    | other -> other.ToString()
                | :? ProfileDataError as error ->
                    match error with
                    | ProfileDataError.Invalid detail
                    | ProfileDataError.Conflict detail
                    | ProfileDataError.Unavailable detail -> detail
                    | other -> other.ToString()
                | _ -> error.ToString()

            invalidOp ("Bethesda family request failed: " + detail))

    let private getData operation value =
        StorageWorker.wait value
        |> Result.defaultWith (fun error ->
            let detail =
                match error with
                | ProfileDataError.Invalid message
                | ProfileDataError.Unavailable message
                | ProfileDataError.Conflict message -> message
                | other -> other.ToString()

            invalidOp (operation + ": " + detail))

    let private token = CancellationToken.None

    let private located =
        function
        | Location.Located(path, _) -> path
        | Location.Unavailable reason -> invalidOp reason

    let private observeTitle (definition: GameDefinition) area =
        let game, proton, data, docs, originalIni =
            BethesdaFamilyEnvironment.initialize definition area

        let rules = GameCatalog.rules definition.Id
        let sourceIni = Path.Combine(docs, rules.Ini)

        use store = new OperationStore(Path.Combine(area, "state"))

        let ws, workspace, profile, modId, library, plugin, sourceStable =
            BethesdaFamilyEnvironment.create store area definition game proton

        let selection = store.ModSelection :> IModSelection

        let enable value =
            let current = InventoryObservations.read store profile

            selection.Change(
                profile,
                current.SelectionRevision,
                [ modId ],
                SelectionEdit.Enable value
            )
            |> get
            |> ignore

        let deploy () =
            let current = store.ProfileGameData.Read(workspace, profile) |> get

            store.ApplyProfileDataAtCheckpoint(
                Guid.NewGuid(),
                workspace,
                profile,
                current.Revision,
                token,
                ignore
            )
            |> getData "apply profile data"
            |> ignore

            let state = store.Deployments.Read profile |> get

            let prepared =
                store.Deployments.Prepare(Guid.NewGuid(), state.Sources, ignore, token) |> get

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> get
            |> ignore

            state.RunnableRoot

        enable true

        let scan () =
            store.Plugins.Scan(profile, token) |> get

        let mutable extensionGate = true

        if not rules.LightExtensions.IsEmpty then
            let extended = scan ()

            extensionGate <-
                extended.Entries
                |> List.find (fun row -> row.Name = "Small.esl")
                |> fun row ->
                    row.Header |> Result.exists (fun header -> header.Kind = PluginKind.LightMaster)

            let extension = Path.Combine(data, rules.LightExtensions.Head)
            File.Delete extension
            let vanilla = scan ()

            extensionGate <-
                extensionGate
                && ((vanilla.Entries |> List.find (fun row -> row.Name = "Small.esl")).Header
                    |> Result.isError)

            File.WriteAllText(extension, "fixture extension")

        let header = scan ()
        let entry = header.Entries |> List.find (fun row -> row.Name = "Example.esp")
        let read = store.PluginOrders.Read(workspace, profile, header.Id) |> get

        let activated =
            store.PluginOrders.Change(
                read.Reference,
                header.Id,
                PluginOrderChange.Enable([ "Example.esp" ], true)
            )
            |> get

        let root = deploy ()

        let selectedContext =
            (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        let _, _, launch =
            ModConductor.GameLaunching.Descriptor.createWithHost
                false
                true
                selectedContext
                root
                None
                None
            |> StorageWorker.result

        let tool =
            ModConductor.GameLaunching.Descriptor.createToolWithHost
                false
                true
                selectedContext
                root
                None
                None
                Guid.Empty
                (Path.Combine(game, definition.Executable))
                [ "--fixture" ]
            |> StorageWorker.result

        let launchRoute =
            tool.ToolExecutable = Path.Combine(root, definition.Executable)
            && tool.Launch.WorkingDirectory = root
            && tool.Launch.Arguments |> List.contains "--fixture"
            && launch.WorkingDirectory = root
            && launch.Arguments
               |> List.contains (Path.Combine(root, GameCatalog.launchExecutable definition.Id))


        let output =
            if definition.Id = GameId.StarfieldSteam then
                Path.Combine(docs, "Data")
            else
                Path.Combine(root, definition.Data)

        let hybrid =
            if definition.Id <> GameId.OblivionRemasteredSteam then
                true
            else
                [ "OblivionRemastered/Content/Paks/Example.pak"
                  "OblivionRemastered/Binaries/Win64/OBSE/Plugins/Example.dll"
                  "OblivionRemastered/Binaries/Win64/ue4ss/Mods/Example/main.lua"
                  "OblivionRemastered/Content/Movies/Example.bk2" ]
                |> List.forall (fun relative ->
                    File.ReadAllText(Path.Combine(root, relative)) = "mod content")

        let installed = File.ReadAllBytes(Path.Combine(output, "Example.esp")) = plugin

        let primaryWon =
            definition.Id <> GameId.StarfieldSteam
            || (File.ReadAllText(Path.Combine(output, "asset.txt")) = "user asset"
                && File.ReadAllText(Path.Combine(output, "User.txt")) = "mod replacement")

        let activation =
            if rules.Activation = PluginActivation.MorrowindIni then
                File.ReadAllText(Path.Combine(root, rules.Ini)).Contains "GameFile1=Example.esp"
            else
                let local =
                    if rules.GamePlugins.IsSome then
                        Path.Combine(root, rules.GamePlugins.Value)
                    else
                        located
                            ((store.GameContexts :> IGameContexts).Read(workspace, profile) |> get)
                                .Binding.Value.Evidence.Locations.LocalAppData

                File.ReadAllText(Path.Combine(local, "plugins.txt")).Contains "Example.esp"

        let saves =
            BethesdaRuntimeSwitchFixtures.saves store workspace profile game root rules deploy

        let sharedRestore =
            BethesdaRuntimeSwitchFixtures.starfield
                store
                ws
                workspace
                profile
                game
                proton
                output
                deploy
                definition

        let retainedComponents =
            BethesdaRuntimeSwitchFixtures.remastered
                store
                workspace
                profile
                modId
                root
                deploy
                definition

        enable false
        deploy () |> ignore
        let disabled = not (File.Exists(Path.Combine(output, "Example.esp")))

        let ownSettings =
            rules.GameSettings
            |> Option.forall (fun relative ->
                let file = Path.Combine(root, relative, rules.Ini)

                File.Exists file
                && isNull (File.ResolveLinkTarget(file, false))
                && file <> sourceIni)

        let currentMod =
            (library.Scan(workspace, 100) |> get).Entries
            |> List.find (fun entry -> entry.Id = modId)

        store.Deletions.Delete(workspace, modId, currentMod.Revision) |> get |> ignore

        let removed =
            (library.Scan(workspace, 100) |> get).Entries
            |> List.exists (fun entry -> entry.Id = modId)
            |> not

        installed
        && retainedComponents
        && sourceStable ()
        && hybrid
        && extensionGate
        && launchRoute
        && disabled
        && removed
        && primaryWon
        && sharedRestore
        && activation
        && saves
        && Result.isOk entry.Header
        && activated.View.Issues.IsEmpty
        && ownSettings
        && File.ReadAllText(sourceIni) = originalIni
        && not (File.Exists(Path.Combine(data, "Example.esp")))
        && File.ReadAllText(Path.Combine(data, "asset.txt")) = "original asset"

    let observeSelected (writer: Utf8JsonWriter) primary game =
        writer.WriteStartObject "bethesdaFamilies"

        for definition in
            GameCatalog.definitions
            |> List.distinctBy _.Name
            |> List.filter (fun definition -> game |> Option.forall ((=) definition.Id)) do
            let area =
                Directory
                    .CreateDirectory(Path.Combine(primary, GameId.value definition.Id))
                    .FullName

            let passed = observeTitle definition area
            writer.WriteBoolean(definition.Name, passed)
            writer.Flush()

            if not passed then
                invalidOp ("Bethesda family fixture failed: " + definition.Name)

        writer.WriteEndObject()

    let observe writer primary = observeSelected writer primary None
