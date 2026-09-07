namespace ModConductor.ModLibrary

open System
open System.Threading.Tasks
open ModConductor.Platform

[<RequireQualifiedAccess>]
type ModKind =
    | Regular
    | Separator
    | Backup
    | Unmanaged
    | GeneratedOutput

type ModMetadata =
    { Name: string
      Notes: string
      Comment: string
      Version: string
      Source: string
      Category: string }

[<RequireQualifiedAccess>]
type InventoryStatus =
    | Ready
    | Detached
    | Changed
    | Unproved
    | Publishing

[<RequireQualifiedAccess>]
type ModAction =
    | EditMetadata
    | Publish
    | ReadVersion

type ModEntry =
    { Id: Guid
      WorkspaceId: Guid
      Kind: ModKind
      Metadata: ModMetadata
      Revision: int64
      SourcePath: LogicalPath option
      CurrentVersion: Guid option
      Status: InventoryStatus
      Actions: ModAction list }

type Payload =
    { Id: Guid
      Length: int64
      Sha256: string }

type ManifestEntry = { Path: LogicalPath; Payload: Payload }

type ModVersion =
    { Id: Guid
      ModId: Guid
      Entries: ManifestEntry list
      NextOffset: int option }

type InventoryPage =
    { Entries: ModEntry list
      NextMod: Guid option }

type UnmanagedEntry = { Path: LogicalPath; Kind: EntryKind }

type InventoryScan =
    { Entries: ModEntry list
      Unmanaged: UnmanagedEntry list
      Limited: bool }

[<RequireQualifiedAccess>]
type LibraryError =
    | NotFound
    | StaleRevision
    | IdentityConflict
    | InvalidMetadata
    | InvalidSource
    | UnprovedOwnership
    | SourceChanged
    | UnsupportedAction
    | Busy
    | LimitExceeded
    | FileUnavailable
    | Cancelled

[<RequireQualifiedAccess>]
type Registration =
    | Directory of ModKind * LogicalPath
    | NativeDirectory of ModKind * HostPath
    | Separator
    | Backup of Guid

[<RequireQualifiedAccess>]
type PublicationPhase =
    | Intent
    | Observed
    | Complete
    | Interrupted
    | Cancelled

type PublicationReceipt =
    { VersionId: Guid
      ModId: Guid
      ExpectedRevision: int64
      Phase: PublicationPhase }

type IModLibrary =
    abstract Register:
        Guid * Guid * ModMetadata * Registration -> Task<Result<ModEntry, LibraryError>>

    abstract Edit: Guid * int64 * ModMetadata -> Task<Result<ModEntry, LibraryError>>
    abstract Inventory: Guid * Guid option -> Task<Result<InventoryPage, LibraryError>>
    abstract Scan: Guid * int -> Task<Result<InventoryScan, LibraryError>>
    abstract Publish: Guid * int64 * Guid -> Task<Result<ModEntry, LibraryError>>
    abstract Publication: Guid -> Task<Result<PublicationReceipt, LibraryError>>
    abstract CancelPublication: Guid -> Task<Result<PublicationReceipt, LibraryError>>
    abstract Version: Guid * int -> Task<Result<ModVersion, LibraryError>>
    abstract ReadPayload: Guid * Guid * int64 * int -> Task<Result<byte array, LibraryError>>
