namespace ModConductor.GameContexts

module internal ClassicRules =
    let fallout3 =
        { TitleRules.newVegas with
            Primary = [ "Fallout3.esm" ]
            Official =
                [ "Fallout3.esm"
                  "ThePitt.esm"
                  "Anchorage.esm"
                  "BrokenSteel.esm"
                  "PointLookout.esm"
                  "Zeta.esm" ]
            CompanionExtension = None
            ExtenderName = Some "FOSE"
            ExtenderLoader = Some "fose_loader.exe"
            ExtenderUrl = Some "https://fose.silverlock.org/"
            Invalidation = Some("Fallout - Invalidation.bsa", 104u)
            NexusGame = "fallout3"
            LootGame = "Fallout 3" }

    let ttw =
        let required =
            TitleRules.newVegas.Official
            @ fallout3.Official
            @ [ "TaleOfTwoWastelands.esm"; "YUPTTW.esm" ]
            |> List.distinctBy _.ToUpperInvariant()

        { TitleRules.newVegas with
            Primary = required
            Official = required
            NexusGame = "" }

    let oblivion =
        { TitleRules.newVegas with
            Primary = [ "Oblivion.esm" ]
            Official =
                [ "Oblivion.esm"
                  "Update.esm"
                  "DLCBattlehornCastle.esp"
                  "DLCShiveringIsles.esp"
                  "Knights.esp"
                  "DLCFrostcrag.esp"
                  "DLCSpellTomes.esp"
                  "DLCMehrunesRazor.esp"
                  "DLCOrrery.esp"
                  "DLCThievesDen.esp"
                  "DLCVileLair.esp"
                  "DLCHorseArmor.esp" ]
            Ini = "Oblivion.ini"
            HeaderBytes = 20
            ArchiveFormats = [ "BSA v103" ]
            Invalidation = Some("Oblivion - Invalidation.bsa", 103u)
            SaveExtension = Some ".ess"
            CompanionExtension = Some ".obse"
            ExtenderName = Some "OBSE"
            ExtenderLoader = Some "obse_loader.exe"
            ExtenderUrl = Some "https://github.com/llde/xOBSE/releases"
            NexusGame = "oblivion"
            LootGame = "Oblivion" }

    let nehrim =
        { oblivion with
            Primary = [ "Nehrim.esm"; "Translation.esp" ]
            Official = [ "Nehrim.esm"; "Translation.esp" ]
            NexusGame = "nehrim" }

    let morrowind =
        { oblivion with
            Activation = PluginActivation.MorrowindIni
            Primary = [ "Morrowind.esm" ]
            Official = [ "Morrowind.esm"; "Tribunal.esm"; "Bloodmoon.esm" ]
            Ini = "Morrowind.ini"
            HeaderBytes = 16
            ArchiveKeys = []
            ArchiveFormats = [ "BSA v256" ]
            Invalidation = None
            CompanionExtension = Some ".mwse"
            ExtenderName = Some "MWSE"
            ExtenderLoader = None
            ExtenderUrl = Some "https://mwse.github.io/MWSE/"
            NexusGame = "morrowind"
            LootGame = "Morrowind"
            GameSettings = Some ""
            GamePlugins = Some ""
            GameSaves = Some "Saves" }

    let skyrim =
        { TitleRules.skyrim with
            Activation = PluginActivation.Plain
            CreationFile = None
            Implicit = []
            Official =
                TitleRules.skyrim.Official
                @ [ "HighResTexturePack01.esp"
                    "HighResTexturePack02.esp"
                    "HighResTexturePack03.esp" ]
            ArchiveFormats = [ "BSA v104" ]
            SupportsLight = false
            ExtenderName = Some "SKSE"
            ExtenderLoader = Some "skse_loader.exe"
            NexusGame = "skyrim"
            LootGame = "Skyrim" }

    let enderal =
        let required = [ "Skyrim.esm"; "Enderal - Forgotten Stories.esm"; "Update.esm" ]

        { skyrim with
            Primary = required
            Official = required
            Ini = "Enderal.ini"
            NexusGame = "enderal"
            LootGame = "Enderal" }
