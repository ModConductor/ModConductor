namespace ModConductor.BepInEx

open System
open System.Threading.Tasks
open ModConductor.Thunderstore
open ModConductor.GameContexts

[<RequireQualifiedAccess>]
type PackageRole =
    | Loader of archiveRoot: string
    | Plugin

type LoaderState =
    { Workspace: Guid
      Profile: Guid
      SelectionRevision: int64
      ContextRevision: int64
      GameSha256: string
      Package: VersionReference
      Mod: Guid option
      Enabled: bool
      SettingsAvailable: bool
      LogAvailable: bool }

type ILoaderSelection =
    abstract Read: workspace: Guid * profile: Guid -> Task<Result<LoaderState, string>>

module LoaderPackage =
    let reference (client: UnityMonoClient) : VersionReference =
        let loader = client.Loader

        { Package =
            { Community = loader.Community
              Namespace = loader.Namespace
              Name = loader.Name }
          Version = loader.Version }

    let role client source =
        match VersionReference.tryDecode source with
        | Some selected when selected.Package = (reference client).Package ->
            PackageRole.Loader client.Loader.ArchiveRoot
        | _ -> PackageRole.Plugin
