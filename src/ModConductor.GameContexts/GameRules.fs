namespace ModConductor.GameContexts

[<RequireQualifiedAccess>]
type PluginActivation =
    | Starred
    | Plain
    | MorrowindIni

[<RequireQualifiedAccess>]
type PluginOrdering =
    | PluginsTxt
    | FileTime
    | None

type GameRules =
    { Activation: PluginActivation
      Ordering: PluginOrdering
      Primary: string list
      Official: string list
      Implicit: string list
      Ini: string
      SaveOverrideIni: string option
      CreationFile: string option
      ArchiveKeys: string list
      ArchiveFormats: string list
      Invalidation: (string * uint32) option
      LooseFilesInvalidation: bool
      SaveExtension: string option
      CompanionExtension: string option
      ExtenderName: string option
      ExtenderLoader: string option
      ExtenderUrl: string option
      NexusGame: string
      LootGame: string
      HeaderBytes: int
      SupportsLight: bool
      SupportsMedium: bool
      SupportsBlueprint: bool
      TestFilesOverride: bool
      GameSettings: string option
      GamePlugins: string option
      GameSaves: string option
      LightExtensions: string list }

module internal TitleRules =
    let skyrim =
        { Activation = PluginActivation.Starred
          Ordering = PluginOrdering.PluginsTxt
          Primary = [ "Skyrim.esm"; "Update.esm" ]
          Official =
            [ "Skyrim.esm"
              "Update.esm"
              "Dawnguard.esm"
              "HearthFires.esm"
              "Dragonborn.esm" ]
          Implicit = [ "Skyrim.esm"; "Update.esm" ]
          Ini = "Skyrim.ini"
          SaveOverrideIni = None
          CreationFile = Some "Skyrim.ccc"
          ArchiveKeys = [ "SResourceArchiveList"; "SResourceArchiveList2" ]
          ArchiveFormats = [ "BSA v105" ]
          Invalidation = None
          LooseFilesInvalidation = false
          SaveExtension = Some ".ess"
          CompanionExtension = Some ".skse"
          ExtenderName = Some "SKSE64"
          ExtenderLoader = Some "skse64_loader.exe"
          ExtenderUrl = Some "https://skse.silverlock.org/"
          NexusGame = "skyrimspecialedition"
          LootGame = "Skyrim Special Edition"
          HeaderBytes = 24
          SupportsLight = true
          SupportsMedium = false
          SupportsBlueprint = false
          TestFilesOverride = false
          GameSettings = None
          GamePlugins = None
          GameSaves = None
          LightExtensions = [] }

    let newVegas =
        { skyrim with
            Activation = PluginActivation.Plain
            Ordering = PluginOrdering.FileTime
            Primary = [ "FalloutNV.esm" ]
            Official =
                [ "FalloutNV.esm"
                  "DeadMoney.esm"
                  "HonestHearts.esm"
                  "OldWorldBlues.esm"
                  "LonesomeRoad.esm"
                  "GunRunnersArsenal.esm"
                  "CaravanPack.esm"
                  "ClassicPack.esm"
                  "MercenaryPack.esm"
                  "TribalPack.esm" ]
            Implicit = []
            Ini = "Fallout.ini"
            CreationFile = None
            ArchiveKeys = [ "SArchiveList" ]
            ArchiveFormats = [ "BSA v104" ]
            Invalidation = Some("Fallout - Invalidation.bsa", 104u)
            SaveExtension = Some ".fos"
            CompanionExtension = Some ".nvse"
            ExtenderName = Some "NVSE"
            ExtenderLoader = Some "nvse_loader.exe"
            ExtenderUrl = Some "https://github.com/xNVSE/NVSE/releases"
            NexusGame = "newvegas"
            LootGame = "Fallout: New Vegas"
            SupportsLight = false }
