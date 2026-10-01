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

module BethesdaFamilyEnvironment =
    let located =
        function
        | Location.Located(path, _) -> path
        | Location.Unavailable reason -> invalidOp reason

    let initialize (definition: GameDefinition) area =
        let rules = GameCatalog.rules definition.Id

        let x86 =
            rules.HeaderBytes = 16
            || rules.HeaderBytes = 20
            || rules.Ordering = PluginOrdering.FileTime
            || definition.Id = GameId.SkyrimSteam
            || definition.Id = GameId.EnderalSteam

        let game, proton =
            ProtonFixtures.createFor definition x86 (Path.Combine(area, "installation"))

        let evidence =
            ModConductor.ProtonContexts.Validation.inspect
                (InstallationValidation.inspect definition game)
                proton

        if definition.Id = GameId.OblivionRemasteredSteam then
            let shipping = Path.Combine(game, GameCatalog.launchExecutable definition.Id)
            Directory.CreateDirectory(Path.GetDirectoryName shipping) |> ignore
            File.Copy(Path.Combine(game, definition.Executable), shipping)

        let data = evidence.DataPath.Value

        for name in rules.Primary do
            File.WriteAllBytes(Path.Combine(data, name), BethesdaFamilySamples.header rules true)

        let docs = located evidence.Locations.Documents
        Directory.CreateDirectory docs |> ignore
        let local = located evidence.Locations.LocalAppData
        Directory.CreateDirectory local |> ignore

        let ini =
            if rules.Activation = PluginActivation.MorrowindIni then
                "[General]\r\nSkipIntro=1\r\n[Game Files]\r\nGameFile0=Morrowind.esm\r\n"
            else
                "[General]\r\nFixture=preserved\r\n"

        File.WriteAllText(Path.Combine(docs, rules.Ini), ini)

        if rules.Activation <> PluginActivation.MorrowindIni then
            File.WriteAllText(Path.Combine(local, "plugins.txt"), "")

        for relative in rules.LightExtensions |> List.truncate 1 do
            let file = Path.Combine(data, relative)
            Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
            File.WriteAllText(file, "fixture extension")

        File.WriteAllText(Path.Combine(data, "asset.txt"), "original asset")

        if definition.Id = GameId.StarfieldSteam then
            let primary = Directory.CreateDirectory(Path.Combine(docs, "Data")).FullName
            File.WriteAllText(Path.Combine(primary, "asset.txt"), "user asset")
            File.WriteAllText(Path.Combine(primary, "User.txt"), "preserved user file")
            Directory.CreateDirectory(Path.Combine(primary, "meshes")) |> ignore
            File.WriteAllText(Path.Combine(primary, "meshes", "keep.txt"), "user nested file")

        game, proton, data, docs, ini

    let private get task =
        task |> StorageWorker.wait |> StorageWorker.result

    let private path name =
        LogicalPath.create [ name ] |> StorageWorker.result

    let create (store: OperationStore) area (definition: GameDefinition) game proton =
        let rules = GameCatalog.rules definition.Id

        let workspace, profile, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let ws = store.Workspaces :> IWorkspaceState

        let created =
            ws.Create(
                workspace,
                definition.Name,
                StorageWorker.select (
                    Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
                )
            )
            |> get

        ws.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Test" }
        )
        |> get
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                0L,
                { GameId = definition.Id
                  Path = game
                  Proton = Some proton
                  Wine = None }
            )
        |> get
        |> ignore

        let modPath =
            Directory
                .CreateDirectory(Path.Combine(HostPath.value created.Workspace.Path, "mod"))
                .FullName

        let plugin = BethesdaFamilySamples.header rules false
        File.WriteAllBytes(Path.Combine(modPath, "Example.esp"), plugin)

        if definition.Id = GameId.StarfieldSteam then
            File.WriteAllText(Path.Combine(modPath, "User.txt"), "mod replacement")
            Directory.CreateDirectory(Path.Combine(modPath, "meshes")) |> ignore
            File.WriteAllText(Path.Combine(modPath, "meshes", "keep.txt"), "mod nested replacement")

        if definition.Id = GameId.OblivionRemasteredSteam then
            for relative in
                [ "Paks/Example.pak"
                  "OBSE/Plugins/Example.dll"
                  "UE4SS/Example/main.lua"
                  "Movies/Example.bk2" ] do
                let file = Path.Combine(modPath, relative)
                Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
                File.WriteAllText(file, "mod content")

        if not rules.LightExtensions.IsEmpty then
            File.WriteAllBytes(
                Path.Combine(modPath, "Small.esl"),
                BethesdaSamples.header 0x201u 1.7f [] false
            )

        let metadata =
            { Name = "Example"
              Version = "1"
              Notes = ""
              Comment = ""
              Source = ""
              Categories = [] }

        let library = store.ModLibrary :> IModLibrary

        let registered =
            library.Register(
                workspace,
                modId,
                metadata,
                Registration.Directory(ModKind.Regular, path "mod")
            )
            |> get

        library.Publish(modId, registered.Revision, version) |> get |> ignore
        let root = store.ModLibrary.Access.Root workspace |> get
        let container = store.ModLibrary.Access.PrepareLibrary(root, ignore) |> get
        let payloads = (library.Version(version, 100) |> get).Entries

        let originals =
            payloads
            |> List.map (fun entry ->
                let file =
                    Path.Combine(
                        HostPath.value root.Path,
                        container.Name,
                        LibraryFiles.payloadName entry.Payload.Id
                    )

                file, File.ReadAllBytes file, File.GetLastWriteTimeUtc file)

        let sourceStable () =
            originals
            |> List.forall (fun (file, bytes, modified) ->
                File.ReadAllBytes file = bytes && File.GetLastWriteTimeUtc file = modified)

        ws, workspace, profile, modId, library, plugin, sourceStable
