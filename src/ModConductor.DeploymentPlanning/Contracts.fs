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

type SnapshotFile =
    { Path: LogicalPath
      Length: int64
      Sha256: string }

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

type Contribution =
    { LayerId: Guid
      Precedence: Precedence
      Source: SourcePin
      MappedTarget: TargetFile
      Archives: ArchiveAnnotation list }

[<RequireQualifiedAccess>]
type WinnerReason =
    | OnlyContribution
    | HigherLayerTier
    | HigherPriority

type ResolvedFile =
    { Target: TargetFile
      Winner: Contribution
      Alternatives: Contribution list
      Reason: WinnerReason }

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
