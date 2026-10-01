namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module BethesdaContextCorrectionFixtures =
    let private token = CancellationToken.None

    let private get value =
        value
        |> StorageWorker.wait
        |> Result.defaultWith (fun error ->
            let detail =
                match box error with
                | :? ProfileDataError as error ->
                    match error with
                    | ProfileDataError.Invalid detail
                    | ProfileDataError.Conflict detail
                    | ProfileDataError.Unavailable detail -> detail
                    | other -> string other
                | other -> string other

            invalidOp detail)

    let private check (writer: Utf8JsonWriter) (name: string) passed =
        writer.WriteBoolean(name, passed)
        writer.Flush()

        if not passed then
            invalidOp ("Bethesda context correction failed: " + name)

    let private saveRouting (writer: Utf8JsonWriter) area gameId =
        let definition = GameCatalog.forGame gameId

        let game, proton, _, docs, originalBase =
            BethesdaFamilyEnvironment.initialize definition area

        let custom = Path.Combine(docs, "Fallout4Custom.ini")
        let original = "[General]\r\nSLocalSavePath=OtherSaves\\\r\nFixture=preserved\r\n"
        File.WriteAllText(custom, original)
        use store = new OperationStore(Path.Combine(area, "state"))

        let ws, workspace, profile, _, _, _, _ =
            BethesdaFamilyEnvironment.create store area definition game proton

        let read profile =
            store.ProfileGameData.Read(workspace, profile) |> get

        let apply profile =
            let current = read profile

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

        let edit settings saves =
            let current = read profile

            store.ProfileGameData.Edit(
                { Id = Guid.NewGuid()
                  Expected = current.Reference
                  Options = { Settings = settings; Saves = saves }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            )
            |> get
            |> ignore

            apply profile

        let privateLink () =
            let current = read profile
            Path.Combine(docs, ".mod-conductor-saves-" + current.ContextId.ToString("N"))

        let routed () =
            let current = read profile

            File.ReadAllText(custom).Contains(Path.GetFileName(privateLink ()) + "\\")
            && Directory.ResolveLinkTarget(privateLink (), true).FullName = current.SavesPath
            && File.ReadAllText(Path.Combine(docs, "Fallout4.ini")) = originalBase

        let restored () =
            File.ReadAllText(custom) = original
            && not (Directory.Exists(privateLink ()))
            && File.ReadAllText(Path.Combine(docs, "Fallout4.ini")) = originalBase

        edit false true
        check writer "sharedSettingsPrivateOnUsesCustomIni" (routed ())
        File.WriteAllText(Path.Combine(privateLink (), "Private.fos"), "private save")
        edit false false
        check writer "privateOffRestoresExistingCustomOverride" (restored ())
        edit false true

        let other = Guid.NewGuid()
        let latest = ws.Read(workspace, None) |> get

        ws.Edit(
            workspace,
            latest.Workspace.Revision,
            ProfileEdit.Create { Id = other; Name = "Other" }
        )
        |> get
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                other,
                0L,
                { GameId = gameId
                  Path = game
                  Proton = Some proton
                  Wine = None }
            )
        |> get
        |> ignore

        apply other
        check writer "otherProfileRestoresSharedSaveOverride" (restored ())
        apply profile

        check
            writer
            "returnToProfileRetainsPrivateSave"
            (routed ()
             && File.ReadAllText(Path.Combine(privateLink (), "Private.fos")) = "private save")

        store.ProfileGameData.Restore(Guid.NewGuid(), (read profile).Reference, token)
        |> get
        |> ignore

        check writer "restoreRemovesSavePatchAndLink" (restored ())

        edit true true
        check writer "privateSettingsPrivateOnUsesCustomIni" (routed ())
        File.AppendAllText(custom, "Changed=retained\r\n")
        edit true false

        let captured =
            File.ReadAllText(Path.Combine((read profile).SettingsPath, "Fallout4Custom.ini"))

        check
            writer
            "privateOffCapturesSettingsWithoutSavePatch"
            (captured.Contains "SLocalSavePath=OtherSaves\\"
             && captured.Contains "Changed=retained"
             && not (captured.Contains ".mod-conductor-saves-"))

        store.ProfileGameData.Restore(Guid.NewGuid(), (read profile).Reference, token)
        |> get
        |> ignore

        check writer "privateSettingsRestorePreservesGlobalCustomIni" (restored ())

    let private launchCasing (writer: Utf8JsonWriter) area gameId =
        let definition = GameCatalog.forGame gameId
        let game, proton, _, _, _ = BethesdaFamilyEnvironment.initialize definition area
        let lower = definition.Executable.ToLowerInvariant()
        File.Move(Path.Combine(game, definition.Executable), Path.Combine(game, lower))
        let remastered = gameId = GameId.OblivionRemasteredSteam

        if remastered then
            let shipping = Path.Combine(game, GameCatalog.launchExecutable gameId)

            File.Move(
                shipping,
                Path.Combine(
                    Path.GetDirectoryName shipping,
                    Path.GetFileName(shipping).ToLowerInvariant()
                )
            )

            let win64 = Path.GetDirectoryName shipping
            Directory.Move(win64, Path.Combine(Path.GetDirectoryName win64, "win64"))
            let binaries = Path.GetDirectoryName win64
            Directory.Move(binaries, Path.Combine(Path.GetDirectoryName binaries, "binaries"))

        use store = new OperationStore(Path.Combine(area, "state"))

        let _, workspace, profile, _, _, _, _ =
            BethesdaFamilyEnvironment.create store area definition game proton

        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> get
        let data = store.ProfileGameData.Read(workspace, profile) |> get

        store.ApplyProfileDataAtCheckpoint(
            Guid.NewGuid(),
            workspace,
            profile,
            data.Revision,
            token,
            ignore
        )
        |> get
        |> ignore

        let state = store.Deployments.Read profile |> get

        let prepared =
            store.Deployments.Prepare(Guid.NewGuid(), state.Sources, ignore, token) |> get

        store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
        |> get
        |> ignore

        let descriptor windows =
            ModConductor.GameLaunching.Descriptor.createWithHost
                windows
                (not windows)
                context
                state.RunnableRoot
                None
                None
            |> StorageWorker.result

        let _, _, launch = descriptor false
        let target = launch.Arguments[2]

        let expected =
            if remastered then
                Path.Combine(
                    state.RunnableRoot,
                    "OblivionRemastered/binaries/win64/oblivionremastered-win64-shipping.exe"
                )
            else
                Path.Combine(state.RunnableRoot, lower)

        check
            writer
            "checkedFilenameCaseSurvivesPrivateView"
            (context.Binding.Value.Evidence.Executable.Value.Path = Path.Combine(game, lower)
             && context.Binding.Value.Evidence.Valid
             && File.Exists target
             && target = expected)

        let windowsContext =
            { context with
                Binding =
                    context.Binding
                    |> Option.map (fun binding ->
                        { binding with
                            Evidence =
                                { binding.Evidence with
                                    Platform = ContextPlatform.Windows } }) }

        let _, _, windows =
            ModConductor.GameLaunching.Descriptor.createWithHost
                true
                false
                windowsContext
                state.RunnableRoot
                None
                None
            |> StorageWorker.result

        check writer "windowsDescriptorPreservesSamePrivatePath" (windows.Executable = expected)

    let private regionalProton (writer: Utf8JsonWriter) area =
        let definition = GameCatalog.forGame GameId.FalloutNewVegasSteam
        let regional = { definition with SteamAppId = 22490u }
        let game, selection = ProtonFixtures.createFor regional true area
        let installation = InstallationValidation.inspect definition game

        let roots: ModConductor.SteamDiscovery.SearchRoot list =
            match selection.Association with
            | ProtonAssociation.Steam(root, _) -> [ { Path = root; Origin = "fixture" } ]
            | ProtonAssociation.Manual -> []

        let search = ModConductor.ProtonContexts.Search.discover definition game roots token

        let selected =
            { selection with
                AppId = search.Prefixes.Head.Origins.Head.Manifest.AppId }

        let valid = ModConductor.ProtonContexts.Validation.inspect installation selected

        let primary =
            ModConductor.ProtonContexts.Validation.inspect
                installation
                { selection with
                    AppId = definition.SteamAppId }

        check
            writer
            "discoveredRegionalAppIdUsesValidatedPrefix"
            (selected.AppId = 22490u && valid.Valid && not primary.Valid)

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject "bethesdaContextCorrections"
        regionalProton writer (Path.Combine(primary, "regional-proton"))

        for game in [ GameId.Fallout4Steam; GameId.FalloutLondonSteam; GameId.Fallout4VrSteam ] do
            writer.WriteStartObject(GameId.value game)
            saveRouting writer (Path.Combine(primary, GameId.value game)) game
            writer.WriteEndObject()

        for game in [ GameId.FalloutNewVegasSteam; GameId.OblivionRemasteredSteam ] do
            writer.WriteStartObject(GameId.value game)
            launchCasing writer (Path.Combine(primary, GameId.value game)) game
            writer.WriteEndObject()

        writer.WriteEndObject()
