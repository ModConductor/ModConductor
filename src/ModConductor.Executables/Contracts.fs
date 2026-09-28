namespace ModConductor.Executables

open System
open System.Threading
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
    | Cancelled
    | Detached
    | TrackingUnavailable

type RunRequest =
    { Id: Guid
      WorkspaceId: Guid
      WorkspaceRevision: int64
      PresetId: Guid
      PresetRevision: int64 }

type GameRunRequest =
    { Id: Guid
      WorkspaceId: Guid
      WorkspaceRevision: int64
      ProfileId: Guid
      ContextRevision: int64
      SourceToken: string }

type AppliedGameFiles =
    { ReceiptId: Guid
      GenerationId: Guid
      Fingerprint: string }

[<RequireQualifiedAccess>]
type GamePreparationPhase =
    | Preparing
    | Applying
    | Ready
    | ProfileData

type GamePreparation =
    { Phase: GamePreparationPhase
      Completed: int
      Total: int }

type AppliedProfileData =
    { ReceiptId: Guid
      Revision: int64
      CompletedFiles: int
      Complete: bool }

type GameRun =
    { Request: GameRunRequest
      ContextId: Guid
      Name: string
      GameDirectory: string
      Runtime: string
      Launch: NativeLaunch
      Preparation: GamePreparation
      Files: AppliedGameFiles option
      ProfileDataRevision: int64
      ProfileData: AppliedProfileData option }

[<RequireQualifiedAccess>]
type RunSource =
    | Preset of RunRequest * ExecutablePreset
    | Game of GameRun

    member this.Id =
        match this with
        | Preset(request, _) -> request.Id
        | Game game -> game.Request.Id

    member this.WorkspaceId =
        match this with
        | Preset(request, _) -> request.WorkspaceId
        | Game game -> game.Request.WorkspaceId

    member this.Name =
        match this with
        | Preset(_, preset) -> preset.Name
        | Game game -> game.Name

    member this.Launch =
        match this with
        | Preset(_, preset) -> preset.Launch
        | Game game -> game.Launch

type ExecutableRun =
    { Source: RunSource
      Revision: int64
      ProfileId: Guid option
      ProfileName: string option
      RequestedAt: DateTimeOffset
      Phase: RunPhase
      ProcessId: int option
      Scope: string option
      RootExitCode: int option
      ActiveProcesses: int option
      Problem: string option }

    member this.Id = this.Source.Id
    member this.WorkspaceId = this.Source.WorkspaceId
    member this.Name = this.Source.Name
    member this.Launch = this.Source.Launch

type PrepareGameRun =
    GameRun -> CancellationToken -> (GameRun -> Task<unit>) -> Task<GameRun * IDisposable>

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
    abstract BeginGame: GameRun -> Task<Result<ExecutableRun * bool, ExecutableError>>
    abstract LatestGame: Guid -> Task<ExecutableRun option>
    abstract Read: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>

    abstract Recent:
        Guid * Guid option -> Task<Result<ExecutableRun list * Guid option, ExecutableError>>

    abstract Update: ExecutableRun -> Task<ExecutableRun>

type IExecutables =
    abstract HasActive: unit -> bool
    abstract List: Guid * Guid option -> Task<Result<PresetPage, ExecutableError>>
    abstract ReadPreset: Guid * Guid -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Save: ExecutablePreset -> Task<Result<ExecutablePreset, ExecutableError>>
    abstract Delete: Guid * Guid * int64 -> Task<Result<unit, ExecutableError>>
    abstract Begin: RunRequest -> Task<Result<ExecutableRun, ExecutableError>>
    abstract Read: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>
    abstract WaitForChange: Guid * Guid * int64 * CancellationToken -> Task

    abstract Recent:
        Guid * Guid option -> Task<Result<ExecutableRun list * Guid option, ExecutableError>>

    abstract StopWaiting: Guid * Guid -> Task<Result<ExecutableRun, ExecutableError>>
