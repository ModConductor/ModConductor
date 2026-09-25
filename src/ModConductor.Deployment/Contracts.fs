namespace ModConductor.Deployment

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

[<RequireQualifiedAccess>]
type DeploymentError =
    | NotFound
    | Busy
    | Stale
    | Cancelled
    | Blocked of string
    | Unavailable of string

[<RequireQualifiedAccess>]
type DeploymentPhase =
    | Preparing
    | Applying
    | Restoring
    | Complete
    | Restored
    | Blocked

type DeploymentProgress =
    { Phase: DeploymentPhase
      Completed: int
      Total: int
      Bytes: int64 }

type DeploymentProfile =
    { Id: Guid
      Name: string
      Revision: int64
      EnabledMods: int }

type SavedDeployment =
    { Id: Guid
      PreparedAt: DateTimeOffset option
      Profile: DeploymentProfile option
      Known: bool
      Active: bool
      Fingerprint: string
      CanRestore: bool
      Unavailable: string option }

type SavedDeploymentPage =
    { Entries: SavedDeployment list
      NextBefore: int64 option }

type DeploymentStatus =
    { WorkspaceId: Guid
      RunnableRoot: string
      Revision: int64
      ActiveGeneration: Guid option
      Active: SavedDeployment option
      PendingReceipt: Guid option
      Sources: SourceStamp }

type PreparedDeployment =
    { Id: Guid
      WorkspaceId: Guid
      Fingerprint: string
      Sources: SourceStamp
      Profile: DeploymentProfile option
      WritableFiles: int
      ChangedPaths: int
      PreservedOriginals: int
      ManagedLinks: int
      CopiedBytes: int64
      RequiredBytes: int64 }

type DeploymentReceipt =
    { Id: Guid
      WorkspaceId: Guid
      Revision: int64
      Phase: DeploymentPhase
      Previous: Guid option
      Proposed: Guid
      Completed: int
      Total: int
      Detail: string }

type DeploymentRecoveryPreview =
    { ReceiptId: Guid
      WorkspaceId: Guid
      Revision: int64
      Paths: string list }

type IDeploymentBackend =
    abstract Read: profile: Guid -> Task<Result<DeploymentStatus, DeploymentError>>

    abstract Saved:
        profile: Guid * before: int64 option -> Task<Result<SavedDeploymentPage, DeploymentError>>

    abstract Prepare:
        id: Guid *
        expected: SourceStamp *
        progress: (DeploymentProgress -> unit) *
        cancellation: CancellationToken ->
            Task<Result<PreparedDeployment, DeploymentError>>

    abstract PrepareRetained:
        id: Guid *
        expected: SourceStamp *
        generation: Guid option *
        progress: (DeploymentProgress -> unit) *
        cancellation: CancellationToken ->
            Task<Result<PreparedDeployment, DeploymentError>>

    abstract RefreshFnis:
        id: Guid *
        expected: SourceStamp *
        candidateRun: Guid *
        progress: (DeploymentProgress -> unit) *
        cancellation: CancellationToken ->
            Task<Result<DeploymentReceipt, DeploymentError>>

    abstract Activate:
        prepared: Guid *
        expected: SourceStamp *
        progress: (DeploymentProgress -> unit) *
        cancellation: CancellationToken ->
            Task<Result<DeploymentReceipt, DeploymentError>>

    abstract Recover:
        receipt: Guid *
        revision: int64 *
        restore: bool *
        progress: (DeploymentProgress -> unit) *
        cancellation: CancellationToken ->
            Task<Result<DeploymentReceipt, DeploymentError>>

    abstract Receipt: Guid -> Task<Result<DeploymentReceipt, DeploymentError>>

    abstract PreviewRecovery:
        receipt: Guid * revision: int64 -> Task<Result<DeploymentRecoveryPreview, DeploymentError>>

type internal PreparedState =
    { View: PreparedDeployment
      Context: GameContextState
      PluginSelectionRevision: int64
      Switch: SwitchRequest
      OriginalStorage: PreparedOriginalStorage option }

module internal PreparedState =
    let abandon value =
        if
            value.Switch.Roots.Length = 2
            && value.Switch.Roots
               |> List.exists (fun root ->
                   (ModConductor.Platform.HostPath.value root.Directory.Path).Contains(
                       ".mc-game-views",
                       StringComparison.Ordinal
                   ))
        then
            ModConductor.DeploymentGenerations.GenerationFiles.removeOwned value.Switch.Generation

        value.OriginalStorage |> Option.iter Preparation.abandonOriginalStorage

type internal IDeploymentRepository =
    abstract Read: Guid -> Task<PlanSources * Context option>
    abstract RunnableRoot: Guid * Guid -> Task<string>
    abstract Saved: Guid * Guid option * int64 option -> Task<SavedDeploymentPage>
    abstract SavedOne: Guid * Guid -> Task<SavedDeployment option>

    abstract Prepare:
        Guid * PlanSources * Context option * (DeploymentProgress -> unit) * CancellationToken ->
            Task<PreparedState>

    abstract PrepareTransient:
        Guid * PlanSources * Context option * Guid * (DeploymentProgress -> unit) * CancellationToken ->
            Task<PreparedState>

    abstract Retained:
        Guid *
        PlanSources *
        Context *
        Guid option *
        (DeploymentProgress -> unit) *
        CancellationToken ->
            Task<PreparedState>

    abstract Current: SourceStamp -> Task<bool>
    abstract Context: workspace: Guid * profile: Guid -> Task<GameContextState>
    abstract ContextForDeployment: workspace: Guid * context: Guid -> Task<GameContextState>
    abstract Start: PreparedState * CancellationToken -> Task<Result<Receipt, RecoveryError>>

    abstract Run:
        Guid * int64 * bool * CancellationToken * (string -> int -> unit) ->
            Task<Result<Receipt, RecoveryError>>

    abstract Receipt: Guid -> Task<Receipt option>
