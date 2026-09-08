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

type DeploymentStatus =
    { WorkspaceId: Guid
      Revision: int64
      ActiveGeneration: Guid option
      PendingReceipt: Guid option
      Sources: SourceStamp }

type PreparedDeployment =
    { Id: Guid
      WorkspaceId: Guid
      Fingerprint: string
      Sources: SourceStamp
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

type IDeploymentBackend =
    abstract Read: profile: Guid -> Task<Result<DeploymentStatus, DeploymentError>>

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

type internal PreparedState =
    { View: PreparedDeployment
      Context: GameContextState
      Switch: SwitchRequest }

type internal IDeploymentRepository =
    abstract Read: Guid -> Task<PlanSources * Context option>

    abstract Prepare:
        Guid * PlanSources * Context option * (DeploymentProgress -> unit) * CancellationToken ->
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
    abstract Context: Guid -> Task<GameContextState>
    abstract Start: SwitchRequest * CancellationToken -> Task<Result<Receipt, RecoveryError>>

    abstract Run:
        Guid * int64 * bool * CancellationToken * (string -> int -> unit) ->
            Task<Result<Receipt, RecoveryError>>

    abstract Receipt: Guid -> Task<Receipt option>
