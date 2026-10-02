namespace ModConductor.GameContexts

type CookedPluginLayout =
    { Mods: string
      GameFeatures: string
      Configs: string
      GameFeatureField: string }

[<RequireQualifiedAccess>]
type LoaderWorkingPath =
    | File of string
    | Directory of string

type LuaLoaderLayout =
    { Proxy: string
      Core: string
      Mods: string
      SettingsFile: string
      Log: string
      Cache: LoaderWorkingPath list }

[<RequireQualifiedAccess>]
type UnrealModMechanism =
    | CookedPlugins of CookedPluginLayout
    | UE4SS of LuaLoaderLayout

type UnrealLoaderDeclaration =
    { Id: string
      Name: string
      Subtitle: string option
      Version: string
      VersionLabel: string
      Source: string
      License: string
      UpstreamCommit: string option
      Page: string
      Download: string option
      Icon: string
      IconHeaders: (string * string) list
      Mechanism: UnrealModMechanism }

type UnrealClient =
    { Loader: UnrealLoaderDeclaration
      Arguments: string list
      Excluded: string list
      LogDirectory: string }
