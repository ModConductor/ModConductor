namespace ModConductor.Bethesda

open System
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning

[<RequireQualifiedAccess>]
type HeaderError =
    | Malformed of string
    | Unsupported of string
    | Limit of string
    | Unavailable of string

[<RequireQualifiedAccess>]
type PluginKind =
    | Plugin
    | Master
    | LightPlugin
    | LightMaster

type PluginHeader =
    { Extension: string
      Flags: uint32
      FormVersion: uint16
      HeaderVersion: single
      DeclaredRecords: uint32
      Kind: PluginKind
      Localized: bool
      Author: string option
      Description: string option
      Masters: string list }

[<RequireQualifiedAccess>]
type MasterState =
    | Found
    | Missing
    | Ambiguous
    | Unavailable
    | Cyclic

type PluginSource =
    { Source: CandidateSource
      Name: string
      Version: string }

type MasterReference =
    { Name: string
      State: MasterState
      Source: PluginSource option }

type PluginEntry =
    { Name: string
      Path: LogicalPath
      Winner: PluginSource option
      Alternatives: PluginSource list
      Header: Result<PluginHeader, HeaderError>
      Ambiguity: string option
      Masters: MasterReference list }

type PluginSnapshot =
    { Id: Guid
      Stamp: SourceStamp
      ObservedAt: DateTimeOffset
      Stale: bool
      Entries: PluginEntry list
      Problems: string list }

module SkyrimPlugins =
    let isCandidate path =
        match LogicalPath.components path with
        | [ name ] ->
            [ ".esp"; ".esm"; ".esl" ]
            |> List.exists (fun suffix -> name.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
        | _ -> false

    let kind extension flags =
        let master = flags &&& 1u <> 0u || extension = ".esm" || extension = ".esl"
        let light = flags &&& 0x200u <> 0u || extension = ".esl"

        match master, light with
        | false, false -> PluginKind.Plugin
        | true, false -> PluginKind.Master
        | false, true -> PluginKind.LightPlugin
        | true, true -> PluginKind.LightMaster
