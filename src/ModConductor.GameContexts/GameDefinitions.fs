namespace ModConductor.GameContexts

open System
open ModConductor.Platform

type UnityLoaderPackage =
    { Community: string
      Namespace: string
      Name: string
      Version: string
      ArchiveRoot: string }

type UnityMonoClient =
    { IndependentExecutable: bool
      LinuxExecutable: string
      WindowsRuntime: string
      LinuxRuntime: string
      LinuxWrapper: string
      ManagedAssembly: string
      UnityMetadata: string
      Loader: UnityLoaderPackage }

[<RequireQualifiedAccess>]
type UnityBackend =
    | Mono
    | Il2Cpp

type UnityIl2CppClient =
    { IndependentExecutable: bool
      LinuxExecutable: string option
      WindowsRuntime: string
      LinuxRuntime: string
      Metadata: string
      UnityMetadata: string
      Loader: UnityLoaderPackage option
      NativeLinuxLoader: UnityLoaderPackage option
      LinuxWrapper: string }

type UnityLoader =
    { Backend: UnityBackend
      Package: UnityLoaderPackage option
      LinuxWrapper: string }

[<RequireQualifiedAccess>]
type GameClient =
    | Bethesda
    | UnityMono of UnityMonoClient
    | UnityIl2Cpp of UnityIl2CppClient
    | Unreal of UnrealClient

type GameDefinition =
    { Id: GameId
      Revision: int
      Name: string
      Storefront: string
      SteamAppId: uint32
      SteamAppIds: uint32 list
      Client: GameClient
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
          Client = GameClient.Bethesda
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

module Valheim =
    let definition =
        { Id = GameId.ValheimSteam
          Revision = 1
          Name = "Valheim"
          Storefront = "Steam"
          SteamAppId = 892970u
          SteamAppIds = [ 892970u ]
          Client =
            GameClient.UnityMono
                { IndependentExecutable = true
                  LinuxExecutable = "valheim.x86_64"
                  WindowsRuntime = "MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll"
                  LinuxRuntime = "MonoBleedingEdge/x86_64/libmonobdwgc-2.0.so"
                  LinuxWrapper = "start_game_bepinex.sh"
                  ManagedAssembly = "Managed/Assembly-CSharp.dll"
                  UnityMetadata = "globalgamemanagers"
                  Loader =
                    { Community = "valheim"
                      Namespace = "denikson"
                      Name = "BepInExPack_Valheim"
                      Version = "5.4.2333"
                      ArchiveRoot = "BepInExPack_Valheim" } }
          Executable = "valheim.exe"
          Launcher = ""
          Data = "valheim_Data"
          Documents = []
          Saves = []
          LocalAppData = []
          IniFiles = []
          TargetPolicy = TargetPolicy.windows }

module GameClient =
    let mono (definition: GameDefinition) =
        match definition.Client with
        | GameClient.UnityMono client -> Some client
        | GameClient.Bethesda
        | GameClient.UnityIl2Cpp _
        | GameClient.Unreal _ -> None

    let unreal (definition: GameDefinition) =
        match definition.Client with
        | GameClient.Unreal client -> Some client
        | GameClient.Bethesda
        | GameClient.UnityMono _
        | GameClient.UnityIl2Cpp _ -> None

    let il2cpp (definition: GameDefinition) =
        match definition.Client with
        | GameClient.UnityIl2Cpp client -> Some client
        | GameClient.Bethesda
        | GameClient.UnityMono _
        | GameClient.Unreal _ -> None

    let nativeLinux (definition: GameDefinition) =
        match definition.Client with
        | GameClient.UnityMono _ -> true
        | GameClient.UnityIl2Cpp client -> client.LinuxExecutable.IsSome
        | GameClient.Bethesda
        | GameClient.Unreal _ -> false

    let unity nativeLinux (definition: GameDefinition) =
        match definition.Client with
        | GameClient.UnityMono client ->
            Some
                { Backend = UnityBackend.Mono
                  Package = Some client.Loader
                  LinuxWrapper = client.LinuxWrapper }
        | GameClient.UnityIl2Cpp client ->
            Some
                { Backend = UnityBackend.Il2Cpp
                  Package =
                    if nativeLinux then
                        client.NativeLinuxLoader
                    else
                        client.Loader
                  LinuxWrapper = client.LinuxWrapper }
        | GameClient.Bethesda
        | GameClient.Unreal _ -> None

    let executable linux (definition: GameDefinition) =
        match definition.Client with
        | GameClient.UnityMono client when linux -> client.LinuxExecutable
        | GameClient.UnityIl2Cpp client when linux ->
            defaultArg client.LinuxExecutable definition.Executable
        | _ -> definition.Executable

    let independentExecutable definition =
        match definition.Client with
        | GameClient.UnityMono client -> client.IndependentExecutable
        | GameClient.UnityIl2Cpp client -> client.IndependentExecutable
        | GameClient.Bethesda
        | GameClient.Unreal _ -> false
