namespace ModConductor.GameContexts

open System
open System.Threading.Tasks
open ModConductor.Platform

[<RequireQualifiedAccess>]
type ContextPlatform =
    | Windows
    | Proton

type UnavailableCapability = { Name: string; Reason: string }

type GameDefinition =
    { Id: string
      Revision: int
      Name: string
      Storefront: string
      SteamAppId: uint32
      Executable: string
      Launcher: string
      Data: string
      Documents: string list
      Saves: string list
      LocalAppData: string list
      TargetPolicy: TargetPolicy
      UnavailableCapabilities: UnavailableCapability list }

module Skyrim =
    let definition =
        { Id = "skyrim-se-steam"
          Revision = 1
          Name = "Skyrim Special Edition"
          Storefront = "Steam"
          SteamAppId = 489830u
          Executable = "SkyrimSE.exe"
          Launcher = "SkyrimSELauncher.exe"
          Data = "Data"
          Documents = [ "My Games"; "Skyrim Special Edition" ]
          Saves = [ "My Games"; "Skyrim Special Edition"; "Saves" ]
          LocalAppData = [ "Skyrim Special Edition" ]
          TargetPolicy = TargetPolicy.windows
          UnavailableCapabilities =
            [ { Name = "Launch"
                Reason = "Game launch is not implemented." }
              { Name = "Deployment"
                Reason = "Deployment is not implemented." }
              { Name = "Plugin editing"
                Reason = "Plugin editing is not implemented." }
              { Name = "Archive inspection"
                Reason = "Archive inspection is not implemented." }
              { Name = "Save management"
                Reason = "Save management is not implemented." } ] }

[<RequireQualifiedAccess>]
type Location =
    | Located of path: string * exists: bool
    | Unavailable of reason: string

type UserLocations =
    { Documents: Location
      Saves: Location
      LocalAppData: Location }

type ExecutableEvidence =
    { Path: string
      Identity: FileIdentity
      Length: int64
      Sha256: string
      FileVersion: string
      ProductVersion: string }

type ValidationProblem = { Path: string; Detail: string }

type InstallationEvidence =
    { DefinitionId: string
      DefinitionRevision: int
      Platform: ContextPlatform
      RootPath: string
      RootIdentity: FileIdentity option
      DataPath: string option
      DataIdentity: FileIdentity option
      Executable: ExecutableEvidence option
      LauncherPath: string option
      Locations: UserLocations
      Problems: ValidationProblem list
      CheckedAt: DateTimeOffset
      Fingerprint: string }

    member this.Valid =
        this.RootIdentity.IsSome
        && this.DataIdentity.IsSome
        && this.Executable.IsSome
        && this.Problems.IsEmpty

type GameBinding =
    { Id: Guid
      Path: string
      Evidence: InstallationEvidence
      NeedsCheck: bool
      Failure: string option }

type GameContextState =
    { WorkspaceId: Guid
      Revision: int64
      Binding: GameBinding option }

[<RequireQualifiedAccess>]
type ContextError =
    | NotFound
    | StaleRevision
    | WorkspaceUnavailable
    | Busy
    | Invalid of InstallationEvidence

type IGameContexts =
    abstract Read: workspace: Guid -> Task<Result<GameContextState, ContextError>>

    abstract Save:
        workspace: Guid * expected: int64 * path: string ->
            Task<Result<GameContextState, ContextError>>

    abstract Refresh:
        workspace: Guid * expected: int64 -> Task<Result<GameContextState, ContextError>>
