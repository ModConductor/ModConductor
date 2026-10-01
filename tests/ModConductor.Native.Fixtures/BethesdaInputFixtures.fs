namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.ProfileGameData

module BethesdaInputFixtures =
    let private get task =
        task |> StorageWorker.wait |> StorageWorker.result

    let private located =
        function
        | Location.Located(path, _) -> path
        | Location.Unavailable reason -> invalidOp reason

    let private observeTitle (definition: GameDefinition) area =
        let token = CancellationToken.None

        let game, proton, data, docs, _ =
            BethesdaFamilyEnvironment.initialize definition area

        let rules = GameCatalog.rules definition.Id
        use store = new OperationStore(Path.Combine(area, "state"))

        let _, workspace, profile, _, _, _, _ =
            BethesdaFamilyEnvironment.create store area definition game proton

        for name in [ "Documents.esm"; "Installation.esm" ] do
            File.WriteAllBytes(Path.Combine(data, name), BethesdaFamilySamples.header rules true)

        if definition.Id = GameId.StarfieldSteam then
            File.WriteAllText(Path.Combine(game, "Starfield.ccc"), "Installation.esm\r\n")

            File.WriteAllText(
                Path.Combine(docs, "Starfield.ccc"),
                "# retained comment\r\nDocuments.esm\r\n"
            )

        let headers = store.Plugins.Scan(profile, token) |> get
        let original = store.PluginOrders.Read(workspace, profile, headers.Id) |> get

        let creation =
            definition.Id <> GameId.StarfieldSteam
            || (List.contains "Documents.esm" original.Facts.Implicit
                && not (List.contains "Installation.esm" original.Facts.Implicit))

        store.PluginOrders.Change(
            original.Reference,
            headers.Id,
            PluginOrderChange.Enable([ "Documents.esm" ], true)
        )
        |> get
        |> ignore

        let custom =
            definition.IniFiles
            |> List.find (fun name ->
                name.EndsWith("Custom.ini", StringComparison.OrdinalIgnoreCase))

        File.WriteAllText(
            Path.Combine(docs, custom),
            "[General]\r\nsTestFile1=Installation.esm\r\n"
        )

        let overridden = store.PluginOrders.Read(workspace, profile, headers.Id) |> get

        let enabled name =
            overridden.View.Order.Entries
            |> List.find (fun row -> row.Name = name)
            |> _.Enabled = Some true

        let refused =
            store.PluginOrders.Change(
                overridden.Reference,
                headers.Id,
                PluginOrderChange.Enable([ "Documents.esm" ], true)
            )
            |> StorageWorker.wait
            |> function
                | Error(ProfileDataError.Unavailable _) -> true
                | _ -> false

        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get

        let plugins =
            Path.Combine(
                located context.Binding.Value.Evidence.Locations.LocalAppData,
                "plugins.txt"
            )

        let before = File.ReadAllBytes plugins
        let current = store.ProfileGameData.Read(workspace, profile) |> get

        store.ApplyProfileDataAtCheckpoint(
            Guid.NewGuid(),
            workspace,
            profile,
            current.Revision,
            token,
            ignore
        )
        |> get
        |> ignore

        creation
        && overridden.Problem.IsSome
        && not overridden.Saved
        && enabled "Installation.esm"
        && not (enabled "Documents.esm")
        && not (List.contains "Documents.esm" overridden.Facts.Implicit)
        && refused
        && File.ReadAllBytes plugins = before
        && File.ReadAllText(Path.Combine(docs, custom)).Contains("sTestFile1=Installation.esm")

    let private absentData area =
        let token = CancellationToken.None
        let definition = GameCatalog.forGame GameId.StarfieldSteam

        let game, proton, data, docs, _ =
            BethesdaFamilyEnvironment.initialize definition area

        let output = Path.Combine(docs, "Data")
        Directory.Delete(output, true)
        use store = new OperationStore(Path.Combine(area, "state"))

        let _, _, profile, _, _, _, _ =
            BethesdaFamilyEnvironment.create store area definition game proton

        let deploy active =
            let current = store.Deployments.Read profile |> get

            let prepared =
                if active then
                    store.Deployments.Prepare(Guid.NewGuid(), current.Sources, ignore, token) |> get
                else
                    store.Deployments.PrepareRetained(
                        Guid.NewGuid(),
                        current.Sources,
                        None,
                        ignore,
                        token
                    )
                    |> get

            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
            |> get
            |> ignore

        deploy true

        let materialized =
            File.ReadAllText(Path.Combine(output, "asset.txt")) = "original asset"

        deploy false

        materialized
        && (not (Directory.Exists output)
            || Directory.EnumerateFileSystemEntries(output) |> Seq.isEmpty)
        && File.ReadAllText(Path.Combine(data, "asset.txt")) = "original asset"

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "bethesdaInputs"

        for definition in
            [ GameCatalog.forGame GameId.Fallout4Steam
              GameCatalog.forGame GameId.StarfieldSteam ] do
            let area =
                Directory
                    .CreateDirectory(Path.Combine(primary, GameId.value definition.Id))
                    .FullName

            let passed = observeTitle definition area
            writer.WriteBoolean(definition.Name, passed)
            writer.Flush()

            if not passed then
                invalidOp ("Bethesda input fixture failed: " + definition.Name)

        let absent =
            absentData (
                Directory.CreateDirectory(Path.Combine(primary, "absent-starfield-data")).FullName
            )

        writer.WriteBoolean("absentStarfieldDataRestored", absent)

        if not absent then
            invalidOp "The absent Starfield Data fixture failed."

        writer.WriteEndObject()
