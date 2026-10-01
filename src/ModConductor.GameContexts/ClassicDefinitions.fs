namespace ModConductor.GameContexts

module internal ClassicDefinitions =
    let fallout3 =
        { NewVegas.definition with
            Id = GameId.Fallout3Steam
            Name = "Fallout 3"
            SteamAppId = 22300u
            SteamAppIds = [ 22300u; 22370u ]
            Executable = "Fallout3.exe"
            Launcher = "Fallout3Launcher.exe"
            Documents = [ "My Games"; "Fallout3" ]
            Saves = [ "My Games"; "Fallout3"; "Saves" ]
            LocalAppData = [ "Fallout3" ] }

    let ttw =
        { NewVegas.definition with
            Id = GameId.TaleOfTwoWastelandsSteam
            Name = "Tale of Two Wastelands" }

    let oblivion =
        { Skyrim.definition with
            Id = GameId.OblivionSteam
            Name = "Oblivion"
            SteamAppId = 22330u
            SteamAppIds = [ 22330u ]
            Executable = "Oblivion.exe"
            Launcher = "OblivionLauncher.exe"
            Documents = [ "My Games"; "Oblivion" ]
            Saves = [ "My Games"; "Oblivion"; "Saves" ]
            LocalAppData = [ "Oblivion" ]
            IniFiles = [ "Oblivion.ini"; "OblivionPrefs.ini" ] }

    let nehrim =
        { oblivion with
            Id = GameId.NehrimSteam
            Name = "Nehrim"
            Executable = "NehrimLauncher.exe" }

    let morrowind =
        { oblivion with
            Id = GameId.MorrowindSteam
            Name = "Morrowind"
            SteamAppId = 22320u
            SteamAppIds = [ 22320u ]
            Executable = "Morrowind.exe"
            Launcher = "Morrowind Launcher.exe"
            Data = "Data Files"
            Documents = []
            Saves = []
            LocalAppData = []
            IniFiles = [ "Morrowind.ini" ] }

    let skyrim =
        { Skyrim.definition with
            Id = GameId.SkyrimSteam
            Name = "Skyrim"
            SteamAppId = 72850u
            SteamAppIds = [ 72850u ]
            Executable = "TESV.exe"
            Launcher = "SkyrimLauncher.exe"
            Documents = [ "My Games"; "Skyrim" ]
            Saves = [ "My Games"; "Skyrim"; "Saves" ]
            LocalAppData = [ "Skyrim" ]
            IniFiles = [ "Skyrim.ini"; "SkyrimPrefs.ini" ] }

    let enderal =
        { skyrim with
            Id = GameId.EnderalSteam
            Name = "Enderal"
            SteamAppId = 933480u
            SteamAppIds = [ 933480u ]
            Executable = "skse_loader.exe"
            Launcher = "Enderal Launcher.exe"
            Documents = [ "My Games"; "Enderal" ]
            Saves = [ "My Games"; "Enderal"; "Saves" ]
            LocalAppData = [ "Enderal" ]
            IniFiles = [ "Enderal.ini"; "EnderalPrefs.ini" ] }
