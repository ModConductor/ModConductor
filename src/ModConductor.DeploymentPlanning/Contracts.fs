namespace ModConductor.DeploymentPlanning

open System
open ModConductor.Platform
open ModConductor.ModLibrary

[<RequireQualifiedAccess>]
type PlanPath =
    | Root
    | At of LogicalPath

type TargetRoot = { Id: Guid; Policy: TargetPolicy }

type RootMapping =
    { SourcePrefix: PlanPath
      TargetRoot: Guid
      TargetPrefix: PlanPath }

type ArchiveAnnotation =
    { Container: LogicalPath
      CapabilityId: string
      CapabilityRevision: string }

type SelectedMod =
    { ModId: Guid
      Priority: int
      Enabled: bool
      Version: ModVersion option
      Mappings: RootMapping list
      Archives: ArchiveAnnotation list }

type ProfileSnapshot =
    { ProfileId: Guid
      Revision: int64
      Complete: bool
      Mods: SelectedMod list }

[<RequireQualifiedAccess>]
type ReadOnlyLayerKind =
    | Base
    | Secondary

type BaseFileMetadata =
    { Identity: FileIdentity
      Length: int64
      Modified: DateTime }

[<RequireQualifiedAccess>]
type SnapshotFileIdentity =
    | Metadata of BaseFileMetadata
    | Content of length: int64 * sha256: string

type SnapshotFile =
    { Path: LogicalPath
      Identity: SnapshotFileIdentity }

module SnapshotFile =
    let length file =
        match file.Identity with
        | SnapshotFileIdentity.Metadata metadata -> metadata.Length
        | SnapshotFileIdentity.Content(length, _) -> length

    let sha256 file =
        match file.Identity with
        | SnapshotFileIdentity.Metadata _ -> None
        | SnapshotFileIdentity.Content(_, sha256) -> Some sha256

    let metadata file =
        match file.Identity with
        | SnapshotFileIdentity.Metadata metadata -> Some metadata
        | SnapshotFileIdentity.Content _ -> None

type ReadOnlySnapshot =
    { Id: Guid
      Generation: string
      Kind: ReadOnlyLayerKind
      Priority: int
      Complete: bool
      Files: SnapshotFile list
      Mappings: RootMapping list
      Archives: ArchiveAnnotation list }

[<RequireQualifiedAccess>]
type WritableTarget =
    | File of root: Guid * path: LogicalPath
    | Subtree of root: Guid * path: PlanPath

type WritableDeclaration = { Id: Guid; Target: WritableTarget }

type PlanningInput =
    { Profile: ProfileSnapshot
      Roots: TargetRoot list
      ReadOnly: ReadOnlySnapshot list
      Writable: WritableDeclaration list }

type TargetFile = { Root: Guid; Path: LogicalPath }

[<RequireQualifiedAccess>]
type SourcePin =
    | Mod of modId: Guid * versionId: Guid * entry: ManifestEntry
    | Snapshot of snapshotId: Guid * generation: string * file: SnapshotFile

[<RequireQualifiedAccess>]
type LayerTier =
    | Base
    | Secondary
    | Mod

type Precedence = { Tier: LayerTier; Priority: int }

type FileContribution<'Source> =
    { LayerId: Guid
      Precedence: Precedence
      Source: 'Source
      MappedTarget: TargetFile
      Archives: ArchiveAnnotation list }

type Contribution = FileContribution<SourcePin>

[<RequireQualifiedAccess>]
type WinnerReason =
    | OnlyContribution
    | HigherLayerTier
    | HigherPriority

type ResolvedTarget<'Source> =
    { Target: TargetFile
      Winner: FileContribution<'Source>
      Alternatives: FileContribution<'Source> list
      Reason: WinnerReason }

type ResolvedFile = ResolvedTarget<SourcePin>

[<RequireQualifiedAccess>]
type WritableProjection =
    | File of id: Guid * target: TargetFile * initialSeed: ResolvedFile option
    | Subtree of id: Guid * root: Guid * path: PlanPath * initialFiles: ResolvedFile list

[<RequireQualifiedAccess>]
type PlanningIssue =
    | IncompleteSelection
    | DuplicateRoot of Guid
    | DuplicateLayer of Guid
    | MissingVersion of Guid
    | WrongModVersion of Guid * Guid
    | IncompleteManifest of Guid
    | IncompleteSnapshot of Guid
    | InvalidContent of layer: Guid * path: LogicalPath
    | InconsistentPayload of Guid
    | MissingTargetRoot of Guid
    | UnmappedFile of layer: Guid * path: LogicalPath
    | AmbiguousMapping of layer: Guid * path: LogicalPath
    | FileMappedToRoot of layer: Guid * path: LogicalPath
    | InvalidTargetName of TargetFile * NameProblem list
    | InvalidArchiveAnnotation of layer: Guid * path: LogicalPath
    | TargetAlias of target: TargetFile * contributions: Contribution list
    | PrecedenceTie of target: TargetFile * contributions: Contribution list
    | DirectorySpellingTie of target: TargetFile * contributions: Contribution list
    | FileDirectoryConflict of TargetFile
    | WritableDirectorySpellingTie of target: TargetFile * declarations: (Guid * LogicalPath) list
    | DuplicateWritableId of Guid
    | OverlappingWritableTargets of Guid * Guid
    | WritableStructureConflict of Guid * TargetFile

type PlanView =
    { Fingerprint: string
      ReadOnlyFiles: ResolvedFile list
      Directories: TargetFile list
      Writable: WritableProjection list }

type DeploymentPlan = internal DeploymentPlan of PlanView

type BlockedPlan =
    { Draft: PlanView
      Issues: PlanningIssue list }

[<RequireQualifiedAccess>]
type PlanningResult =
    | Ready of DeploymentPlan
    | Blocked of BlockedPlan

[<RequireQualifiedAccess>]
type CurrentInputProblem =
    | ChangedInputs
    | UnresolvedInputs of PlanningIssue list
