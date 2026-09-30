namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.Bethesda
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.Loot
open ModConductor.Persistence
open ModConductor.ProfileGameData

module LootProjectionFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private path =
        function
        | Location.Located(path, _) -> path
        | Location.Unavailable reason -> invalidOp reason

    let private project (store: OperationStore) workspace profile game (context: GameContextState) =
        let local = path context.Binding.Value.Evidence.Locations.LocalAppData
        Directory.CreateDirectory local |> ignore

        Directory.CreateDirectory(path context.Binding.Value.Evidence.Locations.Documents)
        |> ignore

        let original = Encoding.UTF8.GetBytes "*Enabled.esp\r\nDisabled.esp\r\n"
        let pluginFile = Path.Combine(local, "Plugins.txt")
        File.WriteAllBytes(pluginFile, original)
        let headers = store.Plugins.Scan(profile, token) |> wait |> result

        let order =
            store.PluginOrders.Read(workspace, profile, headers.Id) |> wait |> result

        let root, projectedGame, projectedLocal =
            store.LootProjectionForFixture(order, token)
            |> Async.StartAsTask
            |> wait
            |> result

        try
            let enabled = Path.Combine(projectedGame, "Data", "Enabled.esp")

            let projected =
                File.ReadAllBytes(enabled) = File.ReadAllBytes(
                    Path.Combine(game, "Data", "Enabled.esp")
                )
                && not (File.Exists(Path.Combine(projectedGame, "Data", "Disabled.esp")))
                && File.ReadAllBytes(Path.Combine(projectedGame, "SkyrimSE.exe")) = File
                    .ReadAllBytes(Path.Combine(game, "SkyrimSE.exe"))
                && File
                    .ReadAllText(Path.Combine(projectedLocal, "Plugins.txt"))
                    .Contains("*Enabled.esp")
                && File.ReadAllBytes(pluginFile) = original

            projected, order
        finally
            Directory.Delete(root, true)

    let observe (writer: Utf8JsonWriter) area =
        if not (OperatingSystem.IsLinux()) then
            invalidOp "This projection fixture uses owned Linux Proton and Wine contexts."

        let state = Path.Combine(area, "state")
        use store = new OperationStore(state)

        let workspace, profile, game, proton, created =
            SkyrimFixtureWorkspace.create
                store
                state
                area
                "LOOT projection"
                "workspace"
                "installation"
                true

        let steam = result created
        BethesdaSamples.requiredBaseFiles game

        File.WriteAllBytes(
            Path.Combine(game, "Data", "Enabled.esp"),
            BethesdaSamples.header 0u 1.7f [ "Skyrim.esm" ] false
        )

        File.WriteAllBytes(
            Path.Combine(game, "Data", "Disabled.esp"),
            BethesdaSamples.header 0u 1.7f [ "Skyrim.esm" ] false
        )

        let wine = Path.Combine(area, "wine-fixture")
        File.WriteAllText(wine, "#!/bin/sh\nexit 0\n")

        File.SetUnixFileMode(
            wine,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        let selection =
            { Executable = wine
              Prefix = Path.Combine(proton.CompatData, "pfx") }

        writer.WriteStartObject "lootProjectionContexts"

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                invalidOp ("LOOT projection fixture failed: " + name)

        let steamProjected, _ = project store workspace profile game steam
        check "steamCheckedOrderProjectsEnabledSources" steamProjected
        let contexts = store.GameContexts :> IGameContexts

        let gog =
            contexts.Save(
                workspace,
                profile,
                steam.Revision,
                { GameId = GameId.SkyrimSpecialEditionGog
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait
            |> result

        let gogProjected, _ = project store workspace profile game gog
        check "gogCheckedOrderProjectsEnabledSources" gogProjected

        let direct =
            contexts.Save(
                workspace,
                profile,
                gog.Revision,
                { GameId = GameId.SkyrimSpecialEditionDirect
                  Path = game
                  Proton = None
                  Wine = Some selection }
            )
            |> wait
            |> result

        let directProjected, order = project store workspace profile game direct
        check "directCheckedOrderProjectsEnabledSources" directProjected

        let uncheckedContext =
            { direct with
                Binding =
                    Some
                        { direct.Binding.Value with
                            NeedsCheck = true } }

        let sources =
            { Stamp = order.Headers.Stamp
              Context = uncheckedContext
              Profile = Unchecked.defaultof<_>
              Mods = []
              Hidden = Set.empty
              Writable = [] }

        let refused =
            Projection.build
                Unchecked.defaultof<_>
                state
                (GameProcesses.validate >> Result.mapError LootError.Unsupported)
                order
                sources
                token
            |> Async.StartAsTask
            |> wait

        let staging = Path.Combine(state, "loot-staging")

        let rejectedByValidator =
            match refused, GameProcesses.validate uncheckedContext with
            | Error(LootError.Unsupported actual), Error expected -> actual = expected
            | _ -> false

        check
            "uncheckedContextIsRejectedBeforeStaging"
            (rejectedByValidator
             && (Directory.EnumerateFileSystemEntries staging |> Seq.isEmpty))

        writer.WriteEndObject()
