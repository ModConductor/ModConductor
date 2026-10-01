namespace ModConductor.GameContexts

module internal CreationDefinitions =
    let enderal =
        { Skyrim.definition with
            Id = GameId.EnderalSpecialEditionSteam
            Name = "Enderal Special Edition"
            SteamAppId = 976620u
            SteamAppIds = [ 976620u ]
            Executable = "skse64_loader.exe"
            Launcher = "Enderal Launcher.exe"
            Documents = [ "My Games"; "Enderal Special Edition" ]
            Saves = [ "My Games"; "Enderal Special Edition"; "Saves" ]
            LocalAppData = [ "Enderal Special Edition" ]
            IniFiles = [ "Enderal.ini"; "EnderalPrefs.ini" ] }

    let skyrimVr =
        { Skyrim.definition with
            Id = GameId.SkyrimVrSteam
            Name = "Skyrim VR"
            SteamAppId = 611670u
            SteamAppIds = [ 611670u ]
            Executable = "SkyrimVR.exe"
            Launcher = "SkyrimVR.exe"
            Documents = [ "My Games"; "Skyrim VR" ]
            Saves = [ "My Games"; "Skyrim VR"; "Saves" ]
            LocalAppData = [ "Skyrim VR" ]
            IniFiles = [ "SkyrimVR.ini"; "SkyrimPrefs.ini" ] }

    let fallout4 =
        { Skyrim.definition with
            Id = GameId.Fallout4Steam
            Name = "Fallout 4"
            SteamAppId = 377160u
            SteamAppIds = [ 377160u ]
            Executable = "Fallout4.exe"
            Launcher = "Fallout4Launcher.exe"
            Documents = [ "My Games"; "Fallout4" ]
            Saves = [ "My Games"; "Fallout4"; "Saves" ]
            LocalAppData = [ "Fallout4" ]
            IniFiles = [ "Fallout4.ini"; "Fallout4Prefs.ini"; "Fallout4Custom.ini" ] }

    let london =
        { fallout4 with
            Id = GameId.FalloutLondonSteam
            Name = "Fallout 4 London"
            Documents = [ "My Games"; "Fallout4" ] }

    let falloutVr =
        { fallout4 with
            Id = GameId.Fallout4VrSteam
            Name = "Fallout 4 VR"
            SteamAppId = 611660u
            SteamAppIds = [ 611660u ]
            Executable = "Fallout4VR.exe"
            Launcher = "Fallout4VR.exe"
            Documents = [ "My Games"; "Fallout4VR" ]
            Saves = [ "My Games"; "Fallout4VR"; "Saves" ]
            LocalAppData = [ "Fallout4VR" ] }

    let starfield =
        { fallout4 with
            Id = GameId.StarfieldSteam
            Name = "Starfield"
            SteamAppId = 1716740u
            SteamAppIds = [ 1716740u ]
            Executable = "Starfield.exe"
            Launcher = "Starfield.exe"
            Documents = [ "My Games"; "Starfield" ]
            Saves = [ "My Games"; "Starfield"; "Saves" ]
            LocalAppData = [ "Starfield" ]
            IniFiles = [ "StarfieldPrefs.ini"; "StarfieldCustom.ini" ] }

    let fallout76 =
        { fallout4 with
            Id = GameId.Fallout76Steam
            Name = "Fallout 76"
            SteamAppId = 1151340u
            SteamAppIds = [ 1151340u ]
            Executable = "Fallout76.exe"
            Launcher = "Fallout76.exe"
            Documents = [ "My Games"; "Fallout 76" ]
            Saves = []
            LocalAppData = [ "Fallout76" ]
            IniFiles = [ "Fallout76.ini"; "Fallout76Prefs.ini"; "Fallout76Custom.ini" ] }

    let oblivionRemastered =
        { fallout4 with
            Id = GameId.OblivionRemasteredSteam
            Name = "Oblivion Remastered"
            SteamAppId = 2623190u
            SteamAppIds = [ 2623190u ]
            Executable = "OblivionRemastered.exe"
            Launcher = "OblivionRemastered.exe"
            Data = "OblivionRemastered/Content/Dev/ObvData/Data"
            Documents = [ "My Games"; "Oblivion Remastered" ]
            Saves = [ "My Games"; "Oblivion Remastered"; "Saved"; "SaveGames" ]
            LocalAppData = [ "Oblivion Remastered" ]
            IniFiles = [ "Oblivion.ini" ] }
