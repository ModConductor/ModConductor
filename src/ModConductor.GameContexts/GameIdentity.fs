namespace ModConductor.GameContexts

[<Struct; RequireQualifiedAccess>]
type GameId =
    | SkyrimSpecialEditionSteam
    | SkyrimSpecialEditionGog
    | SkyrimSpecialEditionDirect
    | FalloutNewVegasSteam
    | FalloutNewVegasGog
    | FalloutNewVegasEpic
    | FalloutNewVegasDirect

    | Fallout3Steam
    | TaleOfTwoWastelandsSteam
    | OblivionSteam
    | NehrimSteam
    | MorrowindSteam
    | SkyrimSteam
    | EnderalSteam
    | EnderalSpecialEditionSteam
    | SkyrimVrSteam
    | Fallout4Steam
    | FalloutLondonSteam
    | Fallout4VrSteam
    | StarfieldSteam
    | Fallout76Steam
    | OblivionRemasteredSteam
    | ValheimSteam
    | SatisfactorySteam
    | Subnautica2Steam

module GameId =
    let value =
        function
        | GameId.SkyrimSpecialEditionSteam -> "skyrim-se-steam"
        | GameId.SkyrimSpecialEditionGog -> "skyrim-se-gog"
        | GameId.SkyrimSpecialEditionDirect -> "skyrim-se-direct"
        | GameId.FalloutNewVegasSteam -> "new-vegas-steam"
        | GameId.FalloutNewVegasGog -> "new-vegas-gog"
        | GameId.FalloutNewVegasEpic -> "new-vegas-epic"
        | GameId.FalloutNewVegasDirect -> "new-vegas-direct"

        | GameId.Fallout3Steam -> "fallout3-steam"
        | GameId.TaleOfTwoWastelandsSteam -> "ttw-steam"
        | GameId.OblivionSteam -> "oblivion-steam"
        | GameId.NehrimSteam -> "nehrim-steam"
        | GameId.MorrowindSteam -> "morrowind-steam"
        | GameId.SkyrimSteam -> "skyrim-steam"
        | GameId.EnderalSteam -> "enderal-steam"
        | GameId.EnderalSpecialEditionSteam -> "enderal-se-steam"
        | GameId.SkyrimVrSteam -> "skyrim-vr-steam"
        | GameId.Fallout4Steam -> "fallout4-steam"
        | GameId.FalloutLondonSteam -> "fallout-london-steam"
        | GameId.Fallout4VrSteam -> "fallout4-vr-steam"
        | GameId.StarfieldSteam -> "starfield-steam"
        | GameId.Fallout76Steam -> "fallout76-steam"
        | GameId.OblivionRemasteredSteam -> "oblivion-remastered-steam"
        | GameId.ValheimSteam -> "valheim-steam"
        | GameId.SatisfactorySteam -> "satisfactory-steam"
        | GameId.Subnautica2Steam -> "subnautica2-steam"

    let tryParse =
        function
        | "skyrim-se-steam" -> Some GameId.SkyrimSpecialEditionSteam
        | "skyrim-se-gog" -> Some GameId.SkyrimSpecialEditionGog
        | "skyrim-se-direct" -> Some GameId.SkyrimSpecialEditionDirect
        | "new-vegas-steam" -> Some GameId.FalloutNewVegasSteam
        | "new-vegas-gog" -> Some GameId.FalloutNewVegasGog
        | "new-vegas-epic" -> Some GameId.FalloutNewVegasEpic
        | "new-vegas-direct" -> Some GameId.FalloutNewVegasDirect
        | "fallout3-steam" -> Some GameId.Fallout3Steam
        | "ttw-steam" -> Some GameId.TaleOfTwoWastelandsSteam
        | "oblivion-steam" -> Some GameId.OblivionSteam
        | "nehrim-steam" -> Some GameId.NehrimSteam
        | "morrowind-steam" -> Some GameId.MorrowindSteam
        | "skyrim-steam" -> Some GameId.SkyrimSteam
        | "enderal-steam" -> Some GameId.EnderalSteam
        | "enderal-se-steam" -> Some GameId.EnderalSpecialEditionSteam
        | "skyrim-vr-steam" -> Some GameId.SkyrimVrSteam
        | "fallout4-steam" -> Some GameId.Fallout4Steam
        | "fallout-london-steam" -> Some GameId.FalloutLondonSteam
        | "fallout4-vr-steam" -> Some GameId.Fallout4VrSteam
        | "starfield-steam" -> Some GameId.StarfieldSteam
        | "fallout76-steam" -> Some GameId.Fallout76Steam
        | "oblivion-remastered-steam" -> Some GameId.OblivionRemasteredSteam
        | "valheim-steam" -> Some GameId.ValheimSteam
        | "satisfactory-steam" -> Some GameId.SatisfactorySteam
        | "subnautica2-steam" -> Some GameId.Subnautica2Steam
        | _ -> None
