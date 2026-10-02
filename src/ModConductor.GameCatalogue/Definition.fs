namespace ModConductor.GameCatalogue

open System
open ModConductor.GameContexts
open ModConductor.GameCatalogue.Serialization
open ModConductor.Platform

module Definition =
    let private relative required (value: string) =
        if value = "" && not required then
            true
        else
            value.Split([| '/'; '\\' |])
            |> Array.toList
            |> LogicalPath.create
            |> Result.isOk

    let private package (d: GameDocument) =
        if d.LoaderPackage = "" then
            None
        else
            Some
                { Community = d.Community
                  Namespace = d.LoaderNamespace
                  Name = d.LoaderPackage
                  Version = d.LoaderVersion
                  ArchiveRoot = d.ArchiveRoot }

    let private unreal (d: GameDocument) =
        let mechanism =
            if d.Mechanism = "ue4ss" then
                UnrealModMechanism.UE4SS
                    { Proxy = d.Proxy
                      Core = d.Core
                      Mods = d.Mods
                      SettingsFile = d.SettingsFile
                      Log = d.Log
                      Cache = [] }
            else
                UnrealModMechanism.CookedPlugins
                    { Mods = d.Mods
                      GameFeatures = d.GameFeatures
                      Configs = d.Configs
                      GameFeatureField = d.GameFeatureField }

        GameClient.Unreal
            { Loader =
                { Id = d.Mechanism
                  Name = (if d.Mechanism = "ue4ss" then "UE4SS" else "Cooked Plugins")
                  Subtitle = None
                  Version = d.LoaderVersion
                  VersionLabel = "Version"
                  Source = "Custom game"
                  License = d.LoaderLicense
                  UpstreamCommit = None
                  Page = d.LoaderPage
                  Download =
                    (if d.LoaderDownload = "" then
                         None
                     else
                         Some d.LoaderDownload)
                  Icon = ""
                  IconHeaders = []
                  Mechanism = mechanism }
              Arguments = Array.toList d.Arguments
              Excluded = Array.toList d.Excluded
              LogDirectory = ".mc-unreal-logs" }

    let private client (d: GameDocument) =
        match d.Mechanism with
        | "unity-mono" ->
            GameClient.UnityMono
                { IndependentExecutable = true
                  LinuxExecutable = d.LinuxExecutable
                  WindowsRuntime = d.WindowsRuntime
                  LinuxRuntime = d.LinuxRuntime
                  LinuxWrapper = d.LinuxWrapper
                  ManagedAssembly = d.Metadata
                  UnityMetadata = d.UnityMetadata
                  Loader =
                    package d
                    |> Option.defaultValue
                        { Community = ""
                          Namespace = ""
                          Name = ""
                          Version = ""
                          ArchiveRoot = "" } }
        | "unity-il2cpp" ->
            GameClient.UnityIl2Cpp
                { IndependentExecutable = true
                  LinuxExecutable =
                    if d.LinuxExecutable = "" then
                        None
                    else
                        Some d.LinuxExecutable
                  WindowsRuntime = d.WindowsRuntime
                  LinuxRuntime = d.LinuxRuntime
                  Metadata = d.Metadata
                  UnityMetadata = d.UnityMetadata
                  Loader = package d
                  NativeLinuxLoader = None
                  LinuxWrapper = d.LinuxWrapper }
        | "ue4ss"
        | "cooked-plugins" -> unreal d
        | _ -> invalidOp "The validated game mechanism is unavailable."

    let validate (d: GameDocument) =
        let paths =
            [ d.Executable, true
              d.Content, true
              d.LinuxExecutable, false
              d.WindowsRuntime, false
              d.LinuxRuntime, false
              d.Metadata, false
              d.UnityMetadata, false
              d.LinuxWrapper, false
              d.ArchiveRoot, false ]

        let unrealPaths = [ d.Proxy; d.Core; d.Mods; d.SettingsFile; d.Log ]
        let unity = d.Mechanism.StartsWith("unity-", StringComparison.Ordinal)

        if d.Id <> "" && d.Revision < 1 then
            Error "Use a positive game definition revision."
        elif String.IsNullOrWhiteSpace d.Name then
            Error "Enter a game name."
        elif
            not (
                List.contains
                    d.Mechanism
                    [ "unity-mono"; "unity-il2cpp"; "ue4ss"; "cooked-plugins" ]
            )
        then
            Error "Select an implemented mod setup."
        elif paths |> List.exists (fun (path, required) -> not (relative required path)) then
            Error "Use relative paths inside the game folder."
        elif unity && (d.WindowsRuntime = "" || d.Metadata = "") then
            Error "Enter the Unity runtime and metadata paths."
        elif unity && d.UnityMetadata = "" then
            Error "Enter the Unity metadata path."
        elif unity && d.LinuxExecutable <> "" && d.LinuxRuntime = "" then
            Error "Enter the Linux runtime path for the native Linux executable."
        elif d.Mechanism = "ue4ss" && unrealPaths |> List.exists (relative true >> not) then
            Error "Enter relative UE4SS paths."
        elif
            d.Mechanism = "cooked-plugins"
            && [ d.Mods; d.GameFeatures; d.Configs ] |> List.exists (relative true >> not)
        then
            Error "Enter the Cooked Plugins paths."
        elif
            d.LoaderPackage <> ""
            && not (
                ModConductor.Thunderstore.VersionReference.valid
                    { Package =
                        { Community = d.Community
                          Namespace = d.LoaderNamespace
                          Name = d.LoaderPackage }
                      Version = d.LoaderVersion }
            )
        then
            Error "Enter the Thunderstore community, namespace, package, and version."
        elif
            [ d.LoaderPage; d.LoaderDownload ]
            |> List.exists (fun text ->
                text <> ""
                && (match Uri.TryCreate(text, UriKind.Absolute) with
                    | true, url -> url.Scheme <> "https" && url.Scheme <> "http"
                    | _ -> true))
        then
            Error "Enter an HTTP or HTTPS loader address."
        elif d.Excluded |> Array.exists (relative true >> not) then
            Error "Use relative excluded paths."
        else
            Ok d

    let toGame (d: GameDocument) =
        { Id =
            GameId.tryParse d.Id
            |> Option.defaultWith (fun () -> invalidOp "Invalid custom game identity.")
          Revision = d.Revision
          Name = d.Name.Trim()
          Community = d.Community
          Storefront = (if d.SteamAppId = 0u then "Folder" else "Steam")
          SteamAppId = d.SteamAppId
          SteamAppIds = (if d.SteamAppId = 0u then [] else [ d.SteamAppId ])
          Executable = d.Executable
          Launcher = ""
          Data = d.Content
          Client = client d
          Documents = []
          Saves = []
          LocalAppData = []
          IniFiles = []
          TargetPolicy = TargetPolicy.windows }
