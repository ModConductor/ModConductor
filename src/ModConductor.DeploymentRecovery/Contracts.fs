namespace ModConductor.DeploymentRecovery

open System
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.DeploymentPlanning

type internal Location =
    { Path: HostPath
      Identity: FileIdentity }

type internal PreparedOriginalStorage =
    { Parent: Location
      Directory: Location }

type internal RootBinding =
    { Root: TargetRoot
      Directory: Location
      Originals: Location }

type internal FileBacking =
    { Directory: Location
      Path: LogicalPath
      Identity: FileIdentity
      OwnerGeneration: Guid option }

type internal ObservedFile =
    { Target: TargetFile
      Identity: FileIdentity
      Length: int64
      Sha256: string }

type internal WorkingBinding =
    { Target: TargetFile
      Directory: bool
      Root: Location
      Path: LogicalPath
      Identity: FileIdentity option }

type internal GenerationFile =
    { Target: TargetFile
      Path: LogicalPath
      Identity: FileIdentity
      Length: int64
      Sha256: string
      Backing: FileBacking option }

type internal SavedMod =
    { ModId: Guid
      VersionId: Guid option
      Priority: int
      Enabled: bool }

type internal SavedProfile =
    { Id: Guid
      Name: string
      Revision: int64
      Mods: SavedMod list
      Hidden: Set<ModFile> }

type internal GenerationProvenance =
    { PreparedAt: DateTimeOffset
      Profile: SavedProfile option }

type internal Generation =
    { Id: Guid
      PlanFingerprint: string
      Directory: Location
      Files: GenerationFile list
      References: SourcePin list
      Writable: WritableTarget list
      Roots: TargetRoot list
      Observed: ObservedFile list
      Working: WorkingBinding list
      NativeTargets: Map<TargetFile, LogicalPath>
      Provenance: GenerationProvenance option }

type internal LinkSpec =
    { Generation: Guid
      Target: string
      Directory: bool }

type internal ActiveLink =
    { Target: TargetFile
      Spec: LinkSpec
      Entry: HeldEntry }

type internal Original =
    { Target: TargetFile
      Entry: HeldEntry
      Sha256: string option
      Backup: string }

type internal OwnedDirectory =
    { Target: TargetFile
      Identity: FileIdentity }

type internal Context =
    { Id: Guid
      Fingerprint: string
      Roots: RootBinding list
      Revision: int64
      Active: Guid option
      Links: ActiveLink list
      Directories: OwnedDirectory list
      Originals: Original list
      Pending: Guid option }

[<RequireQualifiedAccess>]
type internal EntryState =
    | Missing
    | Link of LinkSpec * HeldEntry option
    | Original of Original

[<RequireQualifiedAccess>]
type internal EntryPhase =
    | Pending
    | RemoveIntent
    | Cleared
    | InstallIntent
    | Installed
    | RestoreIntent
    | Restored

type internal ParentChange =
    { Target: TargetFile
      Before: FileIdentity option
      Desired: bool
      Observed: FileIdentity option
      Restored: FileIdentity option
      Phase: EntryPhase }

[<RequireQualifiedAccess>]
type internal ReceiptPhase =
    | Applying
    | Restoring
    | Complete
    | Restored
    | Blocked

type internal EntryChange =
    { Target: TargetFile
      Before: EntryState
      After: EntryState
      Phase: EntryPhase
      Observed: HeldEntry option
      RestoredEntry: HeldEntry option }

[<RequireQualifiedAccess>]
type internal DeploymentModel = SymbolicLinkGeneration

type internal Receipt =
    { Id: Guid
      Model: DeploymentModel
      Context: Context
      Proposed: Guid
      Previous: Guid option
      PlanFingerprint: string
      Revision: int64
      Phase: ReceiptPhase
      Changes: EntryChange list
      Parents: ParentChange list
      Originals: Original list
      Detail: string }

type internal SwitchRequest =
    { Id: Guid
      ContextId: Guid
      ContextFingerprint: string
      ExpectedRevision: int64
      Roots: RootBinding list
      Generation: Generation
      DirectoryBoundaries: TargetFile list
      PreserveOriginals: TargetFile list
      ExpectedSources: ModConductor.FilePlanning.SourceStamp option }

[<RequireQualifiedAccess>]
type internal RecoveryError =
    | NotFound
    | Busy
    | Stale
    | InvalidPlan
    | Limit
    | Mismatch of string
    | Unavailable of string
    | Corrupt of string

exception internal RecoveryException of RecoveryError

type internal IRecoveryRepository =
    abstract Context: Guid -> Task<Context option>
    abstract Generation: Guid * Guid -> Task<Generation option>
    abstract Read: Guid -> Task<Receipt option>

    abstract Begin:
        Context option * Receipt * Generation * ModConductor.FilePlanning.SourceStamp option ->
            Task<Receipt>

    abstract Claim: Guid * int64 -> Task<Receipt>
    abstract Save: Receipt -> Task<Receipt>
    abstract Finish: Receipt * Context -> Task<Receipt>
    abstract Release: Guid -> Task<unit>
    abstract Pending: int64 -> Task<(int64 * Receipt) list>
