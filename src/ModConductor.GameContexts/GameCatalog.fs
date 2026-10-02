namespace ModConductor.GameContexts

module GameCatalog =
    let definitions =
        [ NewVegas.definition
          NewVegas.gog
          NewVegas.epic
          NewVegas.direct
          Skyrim.definition
          Skyrim.gog
          Skyrim.direct
          ClassicDefinitions.fallout3
          ClassicDefinitions.ttw
          ClassicDefinitions.oblivion
          ClassicDefinitions.nehrim
          ClassicDefinitions.morrowind
          ClassicDefinitions.skyrim
          ClassicDefinitions.enderal
          CreationDefinitions.enderal
          CreationDefinitions.skyrimVr
          CreationDefinitions.fallout4
          CreationDefinitions.london
          CreationDefinitions.falloutVr
          CreationDefinitions.starfield
          CreationDefinitions.fallout76
          CreationDefinitions.oblivionRemastered
          Valheim.definition
          UnrealDefinitions.satisfactory
          UnrealDefinitions.subnautica2
          UnityIl2CppDefinitions.sonsOfTheForest ]

    let forGame =
        function
        | GameId.SkyrimSpecialEditionSteam -> Skyrim.definition
        | GameId.SkyrimSpecialEditionGog -> Skyrim.gog
        | GameId.SkyrimSpecialEditionDirect -> Skyrim.direct
        | GameId.FalloutNewVegasSteam -> NewVegas.definition
        | GameId.FalloutNewVegasGog -> NewVegas.gog
        | GameId.FalloutNewVegasEpic -> NewVegas.epic
        | GameId.FalloutNewVegasDirect -> NewVegas.direct

        | GameId.Fallout3Steam -> ClassicDefinitions.fallout3
        | GameId.TaleOfTwoWastelandsSteam -> ClassicDefinitions.ttw
        | GameId.OblivionSteam -> ClassicDefinitions.oblivion
        | GameId.NehrimSteam -> ClassicDefinitions.nehrim
        | GameId.MorrowindSteam -> ClassicDefinitions.morrowind
        | GameId.SkyrimSteam -> ClassicDefinitions.skyrim
        | GameId.EnderalSteam -> ClassicDefinitions.enderal
        | GameId.EnderalSpecialEditionSteam -> CreationDefinitions.enderal
        | GameId.SkyrimVrSteam -> CreationDefinitions.skyrimVr
        | GameId.Fallout4Steam -> CreationDefinitions.fallout4
        | GameId.FalloutLondonSteam -> CreationDefinitions.london
        | GameId.Fallout4VrSteam -> CreationDefinitions.falloutVr
        | GameId.StarfieldSteam -> CreationDefinitions.starfield
        | GameId.Fallout76Steam -> CreationDefinitions.fallout76
        | GameId.OblivionRemasteredSteam -> CreationDefinitions.oblivionRemastered
        | GameId.ValheimSteam -> Valheim.definition
        | GameId.SatisfactorySteam -> UnrealDefinitions.satisfactory
        | GameId.Subnautica2Steam -> UnrealDefinitions.subnautica2
        | GameId.SonsOfTheForestSteam -> UnityIl2CppDefinitions.sonsOfTheForest

    let forRuntime game version =
        if game = GameId.SkyrimSpecialEditionDirect && Skyrim.isGogRuntime version then
            { Skyrim.gog with
                Id = game
                Storefront = Skyrim.direct.Storefront }
        else
            forGame game

    let isBethesda game =
        match (forGame game).Client with
        | GameClient.Bethesda -> true
        | GameClient.UnityMono _
        | GameClient.UnityIl2Cpp _
        | GameClient.Unreal _ -> false

    let rules =
        function
        | GameId.SkyrimSpecialEditionSteam
        | GameId.SkyrimSpecialEditionGog
        | GameId.SkyrimSpecialEditionDirect -> TitleRules.skyrim
        | GameId.FalloutNewVegasSteam
        | GameId.FalloutNewVegasGog
        | GameId.FalloutNewVegasDirect -> TitleRules.newVegas
        | GameId.FalloutNewVegasEpic ->
            { TitleRules.newVegas with
                ExtenderName = None
                ExtenderLoader = None }

        | GameId.Fallout3Steam -> ClassicRules.fallout3
        | GameId.TaleOfTwoWastelandsSteam -> ClassicRules.ttw
        | GameId.OblivionSteam -> ClassicRules.oblivion
        | GameId.NehrimSteam -> ClassicRules.nehrim
        | GameId.MorrowindSteam -> ClassicRules.morrowind
        | GameId.SkyrimSteam -> ClassicRules.skyrim
        | GameId.EnderalSteam -> ClassicRules.enderal
        | GameId.EnderalSpecialEditionSteam -> CreationRules.enderal
        | GameId.SkyrimVrSteam -> CreationRules.skyrimVr
        | GameId.Fallout4Steam -> CreationRules.fallout4
        | GameId.FalloutLondonSteam -> CreationRules.london
        | GameId.Fallout4VrSteam -> CreationRules.falloutVr
        | GameId.StarfieldSteam -> CreationRules.starfield
        | GameId.Fallout76Steam -> CreationRules.fallout76
        | GameId.OblivionRemasteredSteam -> CreationRules.oblivionRemastered
        | GameId.ValheimSteam
        | GameId.SatisfactorySteam
        | GameId.Subnautica2Steam
        | GameId.SonsOfTheForestSteam -> invalidOp "This game does not declare Bethesda rules."

    let tryRules game =
        if isBethesda game then Some(rules game) else None

    let steam game = (forGame game).SteamAppId <> 0u

    let steamApp game app =
        List.contains app (forGame game).SteamAppIds

    let isSkyrimSE game =
        tryRules game
        |> Option.exists (fun rules -> rules.NexusGame = "skyrimspecialedition")

    let arguments game =
        if game = GameId.FalloutNewVegasEpic then
            [ "-EpicPortal" ]
        else
            []

    let runtimeRules game (version: string) =
        let selected = rules game

        match game, System.Version.TryParse version with
        | GameId.SkyrimSteam, (true, value) when value < System.Version(1, 4, 26) ->
            { selected with
                Ordering = PluginOrdering.FileTime }
        | _ -> selected

    let launchExecutable game =
        if game = GameId.OblivionRemasteredSteam then
            "OblivionRemastered/Binaries/Win64/OblivionRemastered-Win64-Shipping.exe"
        else
            (forGame game).Executable
