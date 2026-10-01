namespace ModConductor.GameContexts

module internal CreationRules =
    let enderal =
        let required =
            TitleRules.skyrim.Official
            @ [ "Enderal - Forgotten Stories.esm"; "SkyUI_SE.esp" ]

        { TitleRules.skyrim with
            Primary = required
            Official = required
            Implicit = TitleRules.skyrim.Official
            CreationFile = None
            Ini = "Enderal.ini"
            NexusGame = "enderalspecialedition"
            LootGame = "Enderal Special Edition" }

    let skyrimVr =
        { TitleRules.skyrim with
            Primary = TitleRules.skyrim.Official @ [ "SkyrimVR.esm" ]
            Official = TitleRules.skyrim.Official @ [ "SkyrimVR.esm" ]
            Implicit = TitleRules.skyrim.Official @ [ "SkyrimVR.esm" ]
            Ini = "SkyrimVR.ini"
            CreationFile = None
            SupportsLight = false
            LightExtensions = [ "skse/plugins/skyrimvresl.dll" ]
            ExtenderName = Some "SKSEVR"
            ExtenderLoader = Some "sksevr_loader.exe"
            NexusGame = ""
            LootGame = "Skyrim VR" }

    let fallout4 =
        let official =
            [ "Fallout4.esm"
              "DLCRobot.esm"
              "DLCWorkshop01.esm"
              "DLCCoast.esm"
              "DLCWorkshop02.esm"
              "DLCWorkshop03.esm"
              "DLCNukaWorld.esm"
              "DLCUltraHighResolution.esm" ]

        { TitleRules.skyrim with
            Primary = [ "Fallout4.esm" ]
            Official = official
            Implicit = official
            Ini = "Fallout4.ini"
            SaveOverrideIni = Some "Fallout4Custom.ini"
            CreationFile = Some "Fallout4.ccc"
            ArchiveKeys = [ "SResourceStartUpArchiveList"; "SResourceIndexFileList" ]
            ArchiveFormats = [ "BA2 v1"; "BA2 v7"; "BA2 v8" ]
            TestFilesOverride = true
            LooseFilesInvalidation = true
            SaveExtension = Some ".fos"
            CompanionExtension = Some ".f4se"
            ExtenderName = Some "F4SE"
            ExtenderLoader = Some "f4se_loader.exe"
            ExtenderUrl = Some "https://f4se.silverlock.org/"
            NexusGame = "fallout4"
            LootGame = "Fallout 4" }

    let london =
        { fallout4 with
            NexusGame = "fallout4london" }

    let falloutVr =
        { fallout4 with
            Primary = [ "Fallout4.esm"; "Fallout4_VR.esm" ]
            Official = fallout4.Official @ [ "Fallout4_VR.esm" ]
            Implicit = [ "Fallout4.esm"; "Fallout4_VR.esm" ]
            TestFilesOverride = false
            CreationFile = None
            SupportsLight = false
            LightExtensions = [ "f4se/plugins/falloutvresl.dll"; "f4se/plugins/Daytripper4.dll" ]
            ExtenderLoader = Some "f4sevr_loader.exe"
            NexusGame = ""
            LootGame = "Fallout 4 VR" }

    let starfield =
        let official =
            [ "Starfield.esm"
              "Constellation.esm"
              "OldMars.esm"
              "ShatteredSpace.esm"
              "SFBGS00D.esm"
              "SFBGS050.esm"
              "SFBGS003.esm"
              "SFBGS004.esm"
              "SFBGS006.esm"
              "SFBGS007.esm"
              "SFBGS008.esm"
              "SFBGS047.esm" ]

        { fallout4 with
            Primary = [ "Starfield.esm" ]
            Official = official
            Implicit = official
            Ini = "StarfieldCustom.ini"
            SaveOverrideIni = None
            CreationFile = Some "Starfield.ccc"
            ArchiveFormats = [ "BA2 v1"; "BA2 v2"; "BA2 v3" ]
            SaveExtension = Some ".sfs"
            CompanionExtension = Some ".sfse"
            ExtenderName = Some "SFSE"
            ExtenderLoader = Some "sfse_loader.exe"
            ExtenderUrl = Some "https://sfse.silverlock.org/"
            NexusGame = "starfield"
            LootGame = "Starfield"
            SupportsMedium = true
            SupportsBlueprint = true }

    let fallout76 =
        { fallout4 with
            Primary = [ "SeventySix.esm" ]
            Official = [ "SeventySix.esm" ]
            Implicit = [ "SeventySix.esm" ]
            Ini = "Fallout76Custom.ini"
            SaveOverrideIni = None
            CreationFile = Some "Fallout76.ccc"
            TestFilesOverride = false
            SaveExtension = None
            CompanionExtension = None
            ExtenderName = None
            ExtenderLoader = None
            ExtenderUrl = None
            NexusGame = "fallout76"
            LootGame = "" }

    let oblivionRemastered =
        { ClassicRules.oblivion with
            Official =
                (ClassicRules.oblivion.Official |> List.filter ((<>) "Update.esm"))
                @ [ "AltarESPMain.esp"; "AltarDeluxe.esp" ]
            Ordering = PluginOrdering.PluginsTxt
            GameSettings = Some "OblivionRemastered/Content/Dev/ObvData"
            GamePlugins = Some "OblivionRemastered/Content/Dev/ObvData/Data"
            Invalidation = None
            SaveExtension = Some ".sav"
            CompanionExtension = None
            ExtenderName = Some "OBSE64"
            ExtenderLoader = Some "OblivionRemastered/Binaries/Win64/obse64_loader.exe"
            ExtenderUrl = Some "https://www.nexusmods.com/oblivionremastered/mods/82"
            NexusGame = "oblivionremastered"
            LootGame = "Oblivion Remastered" }
