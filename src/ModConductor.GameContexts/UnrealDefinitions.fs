namespace ModConductor.GameContexts

open ModConductor.Platform

module UnrealDefinitions =
    let satisfactory =
        { Id = GameId.SatisfactorySteam
          Revision = 1
          Name = "Satisfactory"
          Storefront = "Steam"
          SteamAppId = 526870u
          SteamAppIds = [ 526870u ]
          Executable = "Engine/Binaries/Win64/FactoryGameSteam-Win64-Shipping.exe"
          Launcher = "FactoryGameSteam.exe"
          Data = "FactoryGame/Content"
          Documents = []
          Saves = []
          LocalAppData = []
          IniFiles = []
          TargetPolicy = TargetPolicy.windows
          Client =
            GameClient.Unreal
                { Loader =
                    { Id = "sml"
                      Name = "SML"
                      Subtitle = None
                      Version = "3.12.0"
                      VersionLabel = "Declared version"
                      Source = "GitHub · SatisfactoryModLoader"
                      License = "GPL-3.0"
                      UpstreamCommit = None
                      Page =
                        "https://github.com/satisfactorymodding/SatisfactoryModLoader/releases/tag/v3.12.0"
                      Download =
                        Some
                            "https://github.com/satisfactorymodding/SatisfactoryModLoader/releases/download/v3.12.0/SML-Windows.zip"
                      Icon =
                        "https://storage.ficsit.app/file/smr-prod-s3/images/mods/rpLvf1Q5igJXc6/logo.webp"
                      IconHeaders = [ "Referer", "https://ficsit.app/" ]
                      Mechanism =
                        UnrealModMechanism.CookedPlugins
                            { Mods = "FactoryGame/Mods"
                              GameFeatures = "FactoryGame/Mods/GameFeatures"
                              Configs = "FactoryGame/Configs"
                              GameFeatureField = "GameFeature" } }
                  Arguments = [ "FactoryGame" ]
                  Excluded = [ "FactoryGame/Saved" ]
                  LogDirectory = ".mc-unreal-logs" } }

    let subnautica2 =
        { satisfactory with
            Id = GameId.Subnautica2Steam
            Name = "Subnautica 2"
            SteamAppId = 1962700u
            SteamAppIds = [ 1962700u ]
            Executable = "Subnautica2/Binaries/Win64/Subnautica2-Win64-Shipping.exe"
            Launcher = "Subnautica2.exe"
            Data = "Subnautica2/Content"
            Client =
                GameClient.Unreal
                    { Loader =
                        { Id = "ue4ss"
                          Name = "UE4SS"
                          Subtitle = Some "Lua mods"
                          Version = "2026-08-19"
                          VersionLabel = "Declared package date"
                          Source = "Nexus Mods · mod 36 · file 1130"
                          License = "MIT"
                          UpstreamCommit = Some "d7e7826d415b0332b43439a64e6c87f64019be03"
                          Page = "https://www.nexusmods.com/subnautica2/mods/36?tab=files"
                          Download = None
                          Icon =
                            "https://staticdelivery.nexusmods.com/mods/9198/images/headers/36_1778749182.jpg"
                          IconHeaders = []
                          Mechanism =
                            UnrealModMechanism.UE4SS
                                { Proxy = "dwmapi.dll"
                                  Core = "ue4ss"
                                  Mods = "ue4ss/Mods"
                                  SettingsFile = "ue4ss/UE4SS-settings.ini"
                                  Log = "ue4ss/UE4SS.log"
                                  Cache =
                                    [ LoaderWorkingPath.File "ue4ss/UE4SS.cache"
                                      LoaderWorkingPath.Directory "ue4ss/cache"
                                      LoaderWorkingPath.Directory "ue4ss/Output" ] } }
                      Arguments = []
                      Excluded = [ "Subnautica2/Saved"; "Subnautica2/Binaries/Win64/cache" ]
                      LogDirectory = ".mc-unreal-logs" } }
