namespace ModConductor.GameContexts

open System
open System.Threading.Tasks
open ModConductor.Platform

[<RequireQualifiedAccess>]
type ContextPlatform =
    | Windows
    | Proton

[<Struct; RequireQualifiedAccess>]
type GameId =
    | SkyrimSpecialEditionSteam

module GameId =
    let value =
        function
        | GameId.SkyrimSpecialEditionSteam -> "skyrim-se-steam"

    let tryParse =
        function
        | "skyrim-se-steam" -> Some GameId.SkyrimSpecialEditionSteam
        | _ -> None

type GameDefinition =
    { Id: GameId
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
      IniFiles: string list
      TargetPolicy: TargetPolicy }

module Skyrim =
    let definition =
        { Id = GameId.SkyrimSpecialEditionSteam
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
          IniFiles = [ "Skyrim.ini"; "SkyrimPrefs.ini"; "SkyrimCustom.ini" ]
          TargetPolicy = TargetPolicy.windows }

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

[<RequireQualifiedAccess>]
type ProtonAssociation =
    | Manual
    | Steam of steamRoot: string * library: string

type ProtonSelection =
    { AppId: uint32
      Association: ProtonAssociation
      CompatData: string
      RuntimeDirectory: string
      ToolId: string }

type ContextSelection =
    { GameId: GameId
      Path: string
      Proton: ProtonSelection option }

type ContextFileEvidence =
    { Path: string
      Identity: FileIdentity
      Sha256: string }

type ProtonPath =
    { Name: string
      WindowsPath: string option
      HostLocation: Location }

type ProtonLaunch =
    { Executable: string
      Arguments: string list
      SteamRoot: string
      Libraries: string list }

type ProtonEvidence =
    { Selection: ProtonSelection
      PrefixPath: string
      PrefixIdentity: FileIdentity
      CompatDataIdentity: FileIdentity
      RuntimeIdentity: FileIdentity
      RuntimeName: string
      RuntimeVersion: string
      PrefixVersion: string option
      Launcher: ContextFileEvidence
      Launch: Result<ProtonLaunch, string>
      Metadata: ContextFileEvidence list
      PerGameTool: string option
      GlobalTool: string option
      MappingProblem: string option
      Paths: ProtonPath list }

type InstallationEvidence =
    { DefinitionId: GameId
      DefinitionRevision: int
      Platform: ContextPlatform
      RootPath: string
      RootIdentity: FileIdentity option
      DataPath: string option
      DataIdentity: FileIdentity option
      Executable: ExecutableEvidence option
      LauncherPath: string option
      Locations: UserLocations
      Proton: ProtonEvidence option
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
      GameId: GameId
      Path: string
      Proton: ProtonSelection option
      Evidence: InstallationEvidence
      NeedsCheck: bool
      Failure: string option }

type GameContextState =
    { WorkspaceId: Guid
      ProfileId: Guid
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
    abstract Read: workspace: Guid * profile: Guid -> Task<Result<GameContextState, ContextError>>

    abstract Save:
        workspace: Guid * profile: Guid * expected: int64 * selection: ContextSelection ->
            Task<Result<GameContextState, ContextError>>

    abstract Refresh:
        workspace: Guid * profile: Guid * expected: int64 ->
            Task<Result<GameContextState, ContextError>>
