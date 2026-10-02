namespace ModConductor.Engine

open ModConductor.GameCatalogue.Serialization
open ModConductor.Protocol.V1

module internal GameRegistrationWire =
    let draft (d: GameDocument) =
        let result =
            CustomGameDraft(
                Id = d.Id,
                Revision = d.Revision,
                Name = d.Name,
                SteamAppId = d.SteamAppId,
                Mechanism = d.Mechanism,
                Executable = d.Executable,
                LinuxExecutable = d.LinuxExecutable,
                Content = d.Content,
                WindowsRuntime = d.WindowsRuntime,
                LinuxRuntime = d.LinuxRuntime,
                Metadata = d.Metadata,
                UnityMetadata = d.UnityMetadata,
                LinuxWrapper = d.LinuxWrapper,
                Community = d.Community,
                LoaderNamespace = d.LoaderNamespace,
                LoaderPackage = d.LoaderPackage,
                LoaderVersion = d.LoaderVersion,
                ArchiveRoot = d.ArchiveRoot,
                LoaderPage = d.LoaderPage,
                LoaderDownload = d.LoaderDownload,
                LoaderLicense = d.LoaderLicense,
                Proxy = d.Proxy,
                Core = d.Core,
                Mods = d.Mods,
                SettingsFile = d.SettingsFile,
                Log = d.Log,
                GameFeatures = d.GameFeatures,
                Configs = d.Configs,
                GameFeatureField = d.GameFeatureField
            )

        result.Arguments.AddRange d.Arguments
        result.Excluded.AddRange d.Excluded
        result

    let document (d: CustomGameDraft) =
        GameDocument(
            Id = d.Id,
            Revision = d.Revision,
            Name = d.Name,
            SteamAppId = d.SteamAppId,
            Mechanism = d.Mechanism,
            Executable = d.Executable,
            LinuxExecutable = d.LinuxExecutable,
            Content = d.Content,
            WindowsRuntime = d.WindowsRuntime,
            LinuxRuntime = d.LinuxRuntime,
            Metadata = d.Metadata,
            UnityMetadata = d.UnityMetadata,
            LinuxWrapper = d.LinuxWrapper,
            Community = d.Community,
            LoaderNamespace = d.LoaderNamespace,
            LoaderPackage = d.LoaderPackage,
            LoaderVersion = d.LoaderVersion,
            ArchiveRoot = d.ArchiveRoot,
            LoaderPage = d.LoaderPage,
            LoaderDownload = d.LoaderDownload,
            LoaderLicense = d.LoaderLicense,
            Proxy = d.Proxy,
            Core = d.Core,
            Mods = d.Mods,
            SettingsFile = d.SettingsFile,
            Log = d.Log,
            GameFeatures = d.GameFeatures,
            Configs = d.Configs,
            GameFeatureField = d.GameFeatureField,
            Arguments = Array.ofSeq d.Arguments,
            Excluded = Array.ofSeq d.Excluded
        )
