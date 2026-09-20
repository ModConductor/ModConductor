namespace ModConductor.GameLaunching

open System
open System.Threading.Tasks
open ModConductor.Executables

type ComponentLoader =
    { GenerationId: Guid
      Executable: string
      ComponentVersion: string
      RuntimeVersion: string
      GameSha256: string }

type IComponentLoaderSelection =
    abstract Read:
        workspace: Guid * profile: Guid * activeGeneration: Guid option ->
            Task<ComponentLoader option>

type ComponentLaunchConfiguration =
    { GenerationId: Guid
      GameSha256: string
      Environment: (string * string option) list }

type IComponentLaunchConfigurationSelection =
    abstract Read:
        workspace: Guid * profile: Guid * activeGeneration: Guid option ->
            Task<ComponentLaunchConfiguration option>

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

type ToolLaunchDescriptor =
    { ContextId: Guid
      Runtime: string
      GenerationId: Guid
      Launch: ModConductor.Platform.NativeLaunch }

type IToolLaunchProjection =
    abstract Project:
        workspace: Guid *
        profile: Guid *
        generation: Guid *
        executable: string *
        arguments: string list ->
            Task<Result<ToolLaunchDescriptor, ExecutableError>>
