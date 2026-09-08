namespace ModConductor.GeneratedOutputs

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

[<RequireQualifiedAccess>]
type OutputPurpose =
    | ToolFolder
    | WritableFile of LogicalPath

[<RequireQualifiedAccess>]
type OutputError =
    | NotFound
    | Busy
    | Stale
    | Cancelled
    | Invalid of string
    | Unavailable of string
    | LimitExceeded

[<RequireQualifiedAccess>]
type OutputLocationState =
    | Uninitialized
    | Ready
    | Stopped

type OutputLocation =
    { Id: Guid
      WorkspaceId: Guid
      ContextId: Guid
      Name: string
      Purpose: OutputPurpose
      Revision: int64
      State: OutputLocationState
      PhysicalPath: string }

type OutputContext =
    { Id: Guid
      Installation: string
      Current: bool }

type OutputScope =
    { WorkspaceId: Guid
      ContextId: Guid
      Revision: int64
      ContextRevision: int64
      Installation: string
      Locations: OutputLocation list
      Contexts: OutputContext list
      PendingActions: Guid list }

type OutputProgress = { Files: int; Bytes: int64 }

[<RequireQualifiedAccess>]
type OutputFileState =
    | New
    | Changed
    | Kept
    | Absent

type OutputFile =
    { LocationId: Guid
      Path: LogicalPath
      State: OutputFileState
      Length: int64
      Sha256: string
      Identity: FileIdentity option
      ObservedAt: DateTimeOffset
      DeploymentId: Guid option }

type OutputSnapshot =
    { Id: Guid
      Scope: OutputScope
      ObservedAt: DateTimeOffset
      Files: int
      Entries: int
      Unreviewed: int }

[<RequireQualifiedAccess>]
type OutputView =
    | ToolOutputs
    | WritableFiles

type OutputPage =
    { Snapshot: OutputSnapshot
      Entries: OutputFile list
      MatchedEntries: int
      Files: int
      Unreviewed: int
      NextCursor: string option }

type OutputSelection = { LocationId: Guid; Path: LogicalPath }

[<RequireQualifiedAccess>]
type OutputDestination =
    | ExistingMod of id: Guid * revision: int64 * versionLabel: string
    | NewMod of id: Guid * name: string * versionLabel: string

[<RequireQualifiedAccess>]
type OutputAction =
    | Keep
    | Discard
    | MoveToMod of OutputDestination
    | SaveCopyToMod of OutputDestination

[<RequireQualifiedAccess>]
type OutputDisposition =
    | Kept
    | Discarded
    | Moved
    | Copied
    | Changed
    | Pending

type OutputActionEntry =
    { File: OutputSelection
      Disposition: OutputDisposition }

type OutputActionResult =
    { Published: bool
      Id: Guid
      VersionId: Guid option
      Entries: OutputActionEntry list
      Complete: bool }

type OutputPromotionPreview =
    { Selected: int
      Replaced: ModConductor.Platform.LogicalPath list
      PreviousVersion: Guid option
      RegisteredSource: bool }

type IGeneratedOutputs =
    abstract Read: workspace: Guid * context: Guid option -> Task<Result<OutputScope, OutputError>>

    abstract Add:
        id: Guid * expected: OutputScope * name: string * purpose: OutputPurpose ->
            Task<Result<OutputLocation, OutputError>>

    abstract StopUsing:
        location: Guid * revision: int64 -> Task<Result<OutputLocation, OutputError>>

    abstract Observe:
        scope: OutputScope * progress: (OutputProgress -> unit) * cancellation: CancellationToken ->
            Task<Result<OutputSnapshot, OutputError>>

    abstract Page:
        snapshot: Guid * view: OutputView * cursor: string option * filter: string ->
            Task<Result<OutputPage, OutputError>>

    abstract Preview:
        snapshot: Guid * files: OutputSelection list * action: OutputAction ->
            Task<Result<OutputPromotionPreview, OutputError>>

    abstract Apply:
        id: Guid *
        snapshot: Guid *
        files: OutputSelection list *
        action: OutputAction *
        cancellation: CancellationToken ->
            Task<Result<OutputActionResult, OutputError>>

    abstract Action: Guid -> Task<Result<OutputActionResult, OutputError>>

    abstract Resume: Guid * CancellationToken -> Task<Result<OutputActionResult, OutputError>>
