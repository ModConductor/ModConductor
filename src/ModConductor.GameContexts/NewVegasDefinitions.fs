namespace ModConductor.GameContexts

open ModConductor.Platform

module NewVegas =
    let definition =
        { Id = GameId.FalloutNewVegasSteam
          Revision = 1
          Name = "Fallout: New Vegas"
          Storefront = "Steam"
          SteamAppId = 22380u
          SteamAppIds = [ 22380u; 22490u ]
          Client = GameClient.Bethesda
          Executable = "FalloutNV.exe"
          Launcher = "FalloutNVLauncher.exe"
          Data = "Data"
          Documents = [ "My Games"; "FalloutNV" ]
          Saves = [ "My Games"; "FalloutNV"; "Saves" ]
          LocalAppData = [ "FalloutNV" ]
          IniFiles =
            [ "Fallout.ini"
              "FalloutPrefs.ini"
              "FalloutCustom.ini"
              "GECKCustom.ini"
              "GECKPrefs.ini" ]
          Community = ""
          TargetPolicy = TargetPolicy.windows }

    let private standalone id storefront =
        { definition with
            Id = id
            Storefront = storefront
            SteamAppId = 0u
            SteamAppIds = [] }

    let gog = standalone GameId.FalloutNewVegasGog "GOG Windows"
    let direct = standalone GameId.FalloutNewVegasDirect "DRM-free Windows"

    let epic =
        { standalone GameId.FalloutNewVegasEpic "Epic Windows" with
            Documents = [ "My Games"; "FalloutNV_Epic" ]
            Saves = [ "My Games"; "FalloutNV_Epic"; "Saves" ]
            LocalAppData = [ "FalloutNV_Epic" ] }
