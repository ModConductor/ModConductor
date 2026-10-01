namespace ModConductor.GameContexts

open System
open ModConductor.Platform

type GameDefinition =
    { Id: GameId
      Revision: int
      Name: string
      Storefront: string
      SteamAppId: uint32
      SteamAppIds: uint32 list
      Executable: string
      Launcher: string
      Data: string
      Documents: string list
      Saves: string list
      LocalAppData: string list
      IniFiles: string list
      TargetPolicy: TargetPolicy }

module Skyrim =
    let definition =
        { Id = GameId.SkyrimSpecialEditionSteam
          Revision = 1
          Name = "Skyrim Special Edition"
          Storefront = "Steam"
          SteamAppId = 489830u
          SteamAppIds = [ 489830u ]
          Executable = "SkyrimSE.exe"
          Launcher = "SkyrimSELauncher.exe"
          Data = "Data"
          Documents = [ "My Games"; "Skyrim Special Edition" ]
          Saves = [ "My Games"; "Skyrim Special Edition"; "Saves" ]
          LocalAppData = [ "Skyrim Special Edition" ]
          IniFiles = [ "Skyrim.ini"; "SkyrimPrefs.ini"; "SkyrimCustom.ini" ]
          TargetPolicy = TargetPolicy.windows }

    let gog =
        { definition with
            Id = GameId.SkyrimSpecialEditionGog
            Storefront = "GOG Windows"
            SteamAppId = 0u
            SteamAppIds = []
            Documents = [ "My Games"; "Skyrim Special Edition GOG" ]
            Saves = [ "My Games"; "Skyrim Special Edition GOG"; "Saves" ]
            LocalAppData = [ "Skyrim Special Edition GOG" ] }

    let direct =
        { definition with
            Id = GameId.SkyrimSpecialEditionDirect
            Storefront = "DRM-free Windows"
            SteamAppId = 0u
            SteamAppIds = [] }

    let isGogRuntime (version: string) =
        match Version.TryParse version with
        | true, value ->
            value.Major = 1 && value.Minor = 6 && (value.Build = 659 || value.Build = 1179)
        | _ -> false
