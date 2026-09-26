namespace ModConductor.Loot

open System
open ModConductor.ProfileGameData

[<RequireQualifiedAccess>]
type LootError =
    | Busy
    | Stale
    | Cancelled
    | Unsupported of string
    | MetadataUnavailable of string
    | HelperUnavailable of string
    | InvalidResponse of string

type LootMessage =
    { Plugin: string option
      Level: string
      Text: string }

type LootMove =
    { Plugin: string
      Current: int
      Proposed: int
      Reason: string }

type LootMetadata =
    { Revision: string
      MasterlistCommit: string
      PreludeCommit: string
      MasterlistSha256: string
      PreludeSha256: string
      MasterlistPath: string
      PreludePath: string
      FetchedAt: DateTimeOffset }

type LootProposal =
    { Id: Guid
      Expected: ProfileDataRef
      HeadersId: Guid
      SourceFingerprint: string
      CreatedAt: DateTimeOffset
      Current: string list
      Sorted: string list
      Moves: LootMove list
      Messages: LootMessage list
      Metadata: LootMetadata
      HelperVersion: string
      LiblootVersion: string
      LiblootRevision: string }

type LootState =
    { CapabilityId: string
      Available: bool
      Reason: string option
      Metadata: LootMetadata option
      Proposal: LootProposal option }

type ILootSorting =
    abstract Read: unit -> LootState
    abstract HelperDiagnostic: unit -> string option

    abstract Preview:
        ProfilePluginOrder * Threading.CancellationToken -> Async<Result<LootProposal, LootError>>

    abstract ValidateApply: Guid * ProfileDataRef * Guid -> Result<string list, LootError>

    abstract Applied: Guid -> unit
    abstract Dismiss: Guid -> unit
    abstract RefreshMetadata: Threading.CancellationToken -> Async<Result<LootMetadata, LootError>>
