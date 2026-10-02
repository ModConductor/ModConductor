namespace ModConductor.Unreal

open System
open System.Threading.Tasks
open ModConductor.GameContexts

type LoaderState =
    { Workspace: Guid
      Profile: Guid
      ContextRevision: int64
      SelectionRevision: int64
      GameSha256: string
      Declaration: UnrealLoaderDeclaration
      Mod: Guid option
      Version: string
      Enabled: bool
      SettingsAvailable: bool
      LogAvailable: bool }

type ILoaderSelection =
    abstract Read: workspace: Guid * profile: Guid -> Task<Result<LoaderState, string>>

module LoaderSource =
    let encode (loader: UnrealLoaderDeclaration) = "unreal-loader:/" + loader.Id
    let matches loader source = source = encode loader
