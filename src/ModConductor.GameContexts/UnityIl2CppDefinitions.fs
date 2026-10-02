namespace ModConductor.GameContexts

open ModConductor.Platform

module UnityIl2CppDefinitions =
    let sonsOfTheForest =
        { Id = GameId.SonsOfTheForestSteam
          Revision = 1
          Name = "Sons of the Forest"
          Storefront = "Steam"
          SteamAppId = 1326470u
          SteamAppIds = [ 1326470u ]
          Client =
            GameClient.UnityIl2Cpp
                { IndependentExecutable = true
                  LinuxExecutable = None
                  WindowsRuntime = "GameAssembly.dll"
                  LinuxRuntime = "GameAssembly.so"
                  Metadata = "il2cpp_data/Metadata/global-metadata.dat"
                  UnityMetadata = "globalgamemanagers"
                  Loader =
                    Some
                        { Community = "sons-of-the-forest"
                          Namespace = "BepInEx"
                          Name = "BepInExPack_IL2CPP"
                          Version = "6.0.755"
                          ArchiveRoot = "BepInExPack" }
                  NativeLinuxLoader = None
                  LinuxWrapper = "run_bepinex.sh" }
          Executable = "SonsOfTheForest.exe"
          Launcher = ""
          Data = "SonsOfTheForest_Data"
          Documents = []
          Saves = []
          LocalAppData = []
          IniFiles = []
          TargetPolicy = TargetPolicy.windows }
