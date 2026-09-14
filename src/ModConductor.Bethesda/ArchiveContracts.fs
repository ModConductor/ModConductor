namespace ModConductor.Bethesda

open System
open ModConductor.FilePlanning
open ModConductor.Platform

type ExplicitArchive =
    { Name: string
      Key: string
      Position: int }

[<RequireQualifiedAccess>]
type ArchivePolicyState =
    | Active
    | Inactive
    | Unavailable
    | Unsupported

type ArchivePolicyEntry =
    { Name: string
      Position: int option
      State: ArchivePolicyState
      Required: bool
      Explicit: ExplicitArchive option
      AssociatedPlugin: string option
      Reasons: string list
      Source: PluginSource option
      Format: string option
      Problem: string option }

type ArchivePolicyIniStamp =
    { Identity: FileIdentity option
      Length: int64
      Sha256: string }

type ArchivePolicyInput =
    { Headers: PluginSnapshot
      Order: PluginOrderView
      Explicit: ExplicitArchive list
      Ini: ArchivePolicyIniStamp }

type ArchivePolicySnapshot =
    { Id: Guid
      Stamp: SourceStamp
      ObservedAt: DateTimeOffset
      Stale: bool
      Ini: ArchivePolicyIniStamp
      Entries: ArchivePolicyEntry list
      ExplicitNames: string list
      Problems: string list
      BlockingProblems: string list }

module SkyrimArchives =
    let required =
        [ "Skyrim - Textures0.bsa"
          "Skyrim - Textures1.bsa"
          "Skyrim - Textures2.bsa"
          "Skyrim - Textures3.bsa"
          "Skyrim - Textures4.bsa"
          "Skyrim - Textures5.bsa"
          "Skyrim - Textures6.bsa"
          "Skyrim - Textures7.bsa"
          "Skyrim - Textures8.bsa"
          "Skyrim - Meshes0.bsa"
          "Skyrim - Meshes1.bsa"
          "Skyrim - Voices_en0.bsa"
          "Skyrim - Sounds.bsa"
          "Skyrim - Interface.bsa"
          "Skyrim - Animations.bsa"
          "Skyrim - Shaders.bsa"
          "Skyrim - Misc.bsa" ]

    let isCandidate path =
        match ModConductor.Platform.LogicalPath.components path with
        | [ name ] ->
            name.EndsWith(".bsa", StringComparison.OrdinalIgnoreCase)
            || name.EndsWith(".ba2", StringComparison.OrdinalIgnoreCase)
        | _ -> false
