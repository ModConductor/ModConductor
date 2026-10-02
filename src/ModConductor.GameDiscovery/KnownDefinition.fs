namespace ModConductor.GameDiscovery

open ModConductor.GameContexts
open ModConductor.GameCatalogue.Serialization

module KnownDefinition =
    let private loader (d: GameDocument) (value: UnityLoaderPackage) =
        d.Community <- value.Community
        d.LoaderNamespace <- value.Namespace
        d.LoaderPackage <- value.Name
        d.LoaderVersion <- value.Version
        d.ArchiveRoot <- value.ArchiveRoot

    let draft (definition: GameDefinition) =
        let d =
            GameDocument(
                Name = definition.Name,
                SteamAppId = definition.SteamAppId,
                Executable = definition.Executable,
                Content = definition.Data
            )

        match definition.Client with
        | GameClient.Bethesda -> ()
        | GameClient.UnityMono c ->
            d.Mechanism <- "unity-mono"
            d.LinuxExecutable <- c.LinuxExecutable
            d.WindowsRuntime <- c.WindowsRuntime
            d.LinuxRuntime <- c.LinuxRuntime
            d.Metadata <- c.ManagedAssembly
            d.UnityMetadata <- c.UnityMetadata
            d.LinuxWrapper <- c.LinuxWrapper
            loader d c.Loader
        | GameClient.UnityIl2Cpp c ->
            d.Mechanism <- "unity-il2cpp"
            d.LinuxExecutable <- defaultArg c.LinuxExecutable ""
            d.WindowsRuntime <- c.WindowsRuntime
            d.LinuxRuntime <- c.LinuxRuntime
            d.Metadata <- c.Metadata
            d.UnityMetadata <- c.UnityMetadata
            d.LinuxWrapper <- c.LinuxWrapper
            c.Loader |> Option.iter (loader d)
        | GameClient.Unreal c ->
            d.Arguments <- List.toArray c.Arguments
            d.Excluded <- List.toArray c.Excluded
            d.LoaderVersion <- c.Loader.Version
            d.LoaderPage <- c.Loader.Page
            d.LoaderDownload <- defaultArg c.Loader.Download ""
            d.LoaderLicense <- c.Loader.License

            match c.Loader.Mechanism with
            | UnrealModMechanism.UE4SS paths ->
                d.Mechanism <- "ue4ss"
                d.Proxy <- paths.Proxy
                d.Core <- paths.Core
                d.Mods <- paths.Mods
                d.SettingsFile <- paths.SettingsFile
                d.Log <- paths.Log
            | UnrealModMechanism.CookedPlugins paths ->
                d.Mechanism <- "cooked-plugins"
                d.Mods <- paths.Mods
                d.GameFeatures <- paths.GameFeatures
                d.Configs <- paths.Configs
                d.GameFeatureField <- paths.GameFeatureField

        d
