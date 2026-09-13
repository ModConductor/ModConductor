namespace ModConductor.FilePlanning

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

module Limits =
    let entries = 1000000
    let depth = 128
    let contentBytes = 64L * 1024L * 1024L * 1024L
    let snapshotBytes = 128L * 1024L * 1024L
    let cacheBytes = 256L * 1024L * 1024L
    let pageRows = 32
    let pageBytes = 240 * 1024

type AcquisitionProgress =
    { Files: int
      TotalFiles: int
      Bytes: int64
      TotalBytes: int64 }

type ObservedEntry =
    { Path: LogicalPath
      Identity: FileIdentity
      Directory: bool
      Length: int64
      Modified: DateTime }

type GameFileSource = ObservedFileSource

type GameOwnedLink = { Path: LogicalPath; Entry: HeldEntry }

type GameProjection =
    { Stamp: string option
      Links: GameOwnedLink list
      Directories: Map<LogicalPath, FileIdentity>
      Originals: Map<LogicalPath, GameFileSource> }

module GameProjection =
    let empty =
        { Stamp = None
          Links = []
          Directories = Map.empty
          Originals = Map.empty }

type GameObservation =
    { ContextFingerprint: string
      Root: HostPath
      Identity: FileIdentity
      Entries: ObservedEntry list
      Projection: GameProjection
      Snapshot: ReadOnlySnapshot
      ObservedAt: DateTimeOffset
      EncodedBytes: int64 }

[<RequireQualifiedAccess>]
type FilePlanError =
    | NotFound
    | Busy
    | Expired
    | Stale
    | ContextUnavailable of string
    | FileUnavailable of string
    | LimitExceeded of string
    | Cancelled
    | InvalidCopy
    | Blocked

type SourceStamp =
    { WorkspaceId: Guid
      ProfileId: Guid
      SelectionRevision: int64
      ContextRevision: int64
      ExclusionRevision: int64
      OutputRevision: int64
      Versions: (Guid * Guid option) list
      Deployment: string option }

type ModLabel =
    { Id: Guid
      Name: string
      Version: string }

type PlanSources =
    { Stamp: SourceStamp
      Context: GameContextState
      Profile: ProfileSnapshot
      Mods: ModLabel list
      Hidden: Set<ModFile>
      Writable: WritableDeclaration list }

type FileChange =
    { Id: int64
      Copy: ModFile
      Hidden: bool
      BeforeHidden: bool
      ProfileId: Guid
      BeforeFingerprint: string
      AfterFingerprint: string
      RecordedAt: DateTimeOffset }

type FileHistoryPage =
    { Changes: FileChange list
      NextBeforeId: int64 option }

type SavedCopy =
    { Copy: ModFile
      Name: string
      VersionLabel: string
      Current: bool
      Hidden: bool
      Entry: ManifestEntry }

/// Persistence owns these reads and the single transaction that checks and records a change.
type IFilePlanRepository =
    abstract Read: Guid -> Task<Result<PlanSources, FilePlanError>>
    abstract Copy: Guid * ModFile -> Task<Result<SavedCopy, FilePlanError>>
    abstract Current: SourceStamp -> Task<Result<bool, FilePlanError>>

    abstract GameProjection:
        SourceStamp * CancellationToken -> Task<Result<GameProjection, FilePlanError>>

    abstract VerifyPayloads:
        PlanSources * int64 * CancellationToken -> Task<Result<unit, FilePlanError>>

    abstract SetHidden:
        SourceStamp * ModFile * bool * string * string -> Task<Result<SourceStamp, FilePlanError>>

    abstract History: Guid * ModFile * int64 option -> Task<Result<FileChange list, FilePlanError>>

[<RequireQualifiedAccess>]
type FileDisposition =
    | Writable
    | Planned
    | Absent
    | Unresolved

type FileNode =
    { Path: LogicalPath
      Directory: bool
      Disposition: FileDisposition
      SourceName: string
      Copies: int }

type FilePlanSummary =
    { Id: Guid
      WorkspaceId: Guid
      ProfileId: Guid
      Fingerprint: string
      Loaded: bool
      Stale: bool
      PlannedFiles: int
      AbsentTargets: int
      InspectedFiles: int
      Problems: string list
      ProblemCount: int
      ObservedAt: DateTimeOffset option }

type FileCursor = { Identity: string; Offset: int }

type FilePage =
    { Snapshot: FilePlanSummary
      Nodes: FileNode list
      Next: FileCursor option }

type InspectedCopy =
    { Copy: ModFile option
      SourcePath: LogicalPath
      Name: string
      VersionLabel: string
      Priority: int option
      Enabled: bool
      Hidden: bool
      Winner: bool
      Historical: bool
      Length: int64
      Sha256: string
      CanHide: bool
      CanUnhide: bool }

type FileInspection =
    { Writable: bool
      Snapshot: FilePlanSummary
      Target: LogicalPath
      Copies: InspectedCopy list
      FocusedCopy: InspectedCopy option
      Next: FileCursor option }

type VisibilityChange =
    { Snapshot: FilePlanSummary
      Changed: FileNode option }

type IFilePlans =
    abstract Open: Guid * CancellationToken -> Task<Result<FilePlanSummary, FilePlanError>>

    abstract Acquire:
        Guid * bool * (AcquisitionProgress -> unit) * CancellationToken ->
            Task<Result<FilePlanSummary, FilePlanError>>

    abstract Read: Guid -> Task<Result<FilePlanSummary, FilePlanError>>

    abstract Children:
        Guid * LogicalPath option * string * FileCursor option ->
            Task<Result<FilePage, FilePlanError>>

    abstract Problems:
        Guid * FileCursor option -> Task<Result<string list * FileCursor option, FilePlanError>>

    abstract Inspect:
        Guid * LogicalPath * FileCursor option -> Task<Result<FileInspection, FilePlanError>>

    abstract InspectCopy: Guid * ModFile -> Task<Result<FileInspection, FilePlanError>>

    abstract Change:
        Guid * ModFile * bool * CancellationToken -> Task<Result<VisibilityChange, FilePlanError>>

    abstract History: Guid * ModFile * int64 option -> Task<Result<FileHistoryPage, FilePlanError>>

/// Candidate reads keep header inspection separate from full deployment acquisition.
type IFileCandidateRepository =
    inherit IFilePlanRepository

    abstract CandidateProjection:
        SourceStamp * (LogicalPath -> bool) * CancellationToken ->
            Task<Result<GameProjection, FilePlanError>>

    abstract OpenManaged:
        Guid * SourcePin * CancellationToken -> Task<Result<System.IO.FileStream, FilePlanError>>

type CandidateObservation =
    { Sources: PlanSources
      Plan: CandidatePlan }
