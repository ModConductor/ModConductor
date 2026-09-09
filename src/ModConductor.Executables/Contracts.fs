namespace ModConductor.Executables

open System
open System.Threading.Tasks
open ModConductor.Platform

type ExecutablePreset =
    { Id: Guid
      WorkspaceId: Guid
      Revision: int64
      Name: string
      Launch: NativeLaunch }

[<RequireQualifiedAccess>]
type RunPhase =
    | Starting
    | Running
    | WaitingForChildren
    | Finished
    | Failed
    | Detached
    | TrackingUnavailable

type RunRequest =
    { Id: Guid
      WorkspaceId: Guid
      WorkspaceRevision: int64
      PresetId: Guid
      PresetRevision: int64 }

type ExecutableRun =
    { Request: RunRequest
      Revision: int64
      Preset: ExecutablePreset
      ProfileId: Guid option
      ProfileName: string option
      RequestedAt: DateTimeOffset
      Phase: RunPhase
      ProcessId: int option
      Scope: string option
      RootExitCode: int option
      ActiveProcesses: int option
      Problem: string option }

type PresetPage =
    { Presets: ExecutablePreset list
      LatestRuns: ExecutableRun list
      Next: Guid option }

[<RequireQualifiedAccess>]
type ExecutableError =
    | NotFound
    | StaleRevision
    | IdentityConflict
    | Capacity
    | Invalid of string
    | Unavailable of string

type IExecutableRepository =
    abstract List: Guid * Guid option -> Task<Result<PresetPage, ExecutableError>>
    abstract ReadPreset: Guid * Guid -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Save: ExecutablePreset -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Delete: Guid * Guid * int64 -> Task<Result<unit, ExecutableError>>
    abstract Begin: RunRequest -> Task<Result<ExecutableRun * bool, ExecutableError>>
    abstract Read: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>

    abstract Recent:
        Guid * Guid option -> Task<Result<ExecutableRun list * Guid option, ExecutableError>>

    abstract Update: ExecutableRun -> Task<ExecutableRun>

type IExecutables =
    abstract List: Guid * Guid option -> Task<Result<PresetPage, ExecutableError>>
    abstract ReadPreset: Guid * Guid -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Save: ExecutablePreset -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Delete: Guid * Guid * int64 -> Task<Result<unit, ExecutableError>>
    abstract Begin: RunRequest -> Task<Result<ExecutableRun, ExecutableError>>
    abstract Read: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>

    abstract Recent:
        Guid * Guid option -> Task<Result<ExecutableRun list * Guid option, ExecutableError>>

    abstract StopWaiting: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>
