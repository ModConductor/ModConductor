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
      Package: VersionReference option
      Mod: Guid option
      Enabled: bool
      SettingsAvailable: bool
      LogAvailable: bool }

type ILoaderSelection =
    abstract Read: workspace: Guid * profile: Guid -> Task<Result<LoaderState, string>>

module LoaderPackage =
    let reference (client: UnityLoader) : VersionReference option =
        client.Package
        |> Option.map (fun loader ->
            { Package =
                { Community = loader.Community
                  Namespace = loader.Namespace
                  Name = loader.Name }
              Version = loader.Version })

    let role (client: UnityLoader) source (paths: seq<ModConductor.Platform.LogicalPath>) =
        let declared =
            match VersionReference.tryDecode source, reference client with
            | Some selected, Some expected when selected.Package = expected.Package ->
                client.Package |> Option.map _.ArchiveRoot
            | _ -> None

        let core =
            match client.Backend with
            | UnityBackend.Mono -> "BepInEx.Preloader.dll"
            | UnityBackend.Il2Cpp -> "BepInEx.Unity.IL2CPP.dll"

        match declared with
        | Some prefix -> PackageRole.Loader prefix
        | None ->
            paths
            |> Seq.tryPick (fun path ->
                let same a b =
                    String.Equals(a, b, StringComparison.OrdinalIgnoreCase)

                match ModConductor.Platform.LogicalPath.components path with
                | [ bep; directory; file ] when
                    same bep "BepInEx" && same directory "core" && same file core
                    ->
                    Some ""
                | [ prefix; bep; directory; file ] when
                    same bep "BepInEx" && same directory "core" && same file core
                    ->
                    Some prefix
                | _ -> None)
            |> Option.map PackageRole.Loader
            |> Option.defaultValue PackageRole.Plugin
