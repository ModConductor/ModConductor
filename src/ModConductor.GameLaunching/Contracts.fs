namespace ModConductor.GameLaunching

open System
open System.Threading.Tasks
open ModConductor.Executables

type GameLaunchState =
    { WorkspaceId: Guid
      ProfileId: Guid
      ContextRevision: int64
      SourceToken: string
      Name: string
      Runtime: string
      Problem: string option
      Latest: ExecutableRun option }

type IGameLaunching =
    abstract Read: workspace: Guid * profile: Guid -> Task<Result<GameLaunchState, ExecutableError>>
    abstract Begin: GameRunRequest -> Task<Result<ExecutableRun, ExecutableError>>
    abstract Cancel: workspace: Guid * run: Guid -> Task<Result<ExecutableRun, ExecutableError>>
