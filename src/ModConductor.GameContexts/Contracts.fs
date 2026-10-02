namespace ModConductor.GameContexts

open System
open System.Threading.Tasks
open ModConductor.Platform

[<RequireQualifiedAccess>]
type ContextPlatform =
    | Windows
    | Proton
    | Wine
    | NativeLinux

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

type WineSelection = { Executable: string; Prefix: string }

type ContextSelection =
    { GameId: GameId
      Path: string
      Proton: ProtonSelection option
      Wine: WineSelection option }

type ContextFileEvidence =
    { Path: string
      Identity: FileIdentity
      Sha256: string }

type ContextPath =
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
      Paths: ContextPath list }

type WineEvidence =
    { Selection: WineSelection
      PrefixIdentity: FileIdentity
      ExecutableIdentity: FileIdentity
      Paths: ContextPath list }

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
      Wine: WineEvidence option
      Problems: ValidationProblem list
      CheckedAt: DateTimeOffset
      Fingerprint: string }

    member this.Valid =
        this.RootIdentity.IsSome
        && this.DataIdentity.IsSome
        && this.Executable.IsSome
        && this.Problems.IsEmpty

module ContextRuntime =
    let ready (evidence: InstallationEvidence) =
        match evidence.Platform with
        | ContextPlatform.Windows
        | ContextPlatform.NativeLinux -> true
        | ContextPlatform.Proton -> evidence.Proton.IsSome
        | ContextPlatform.Wine -> evidence.Wine.IsSome

    let prefix (evidence: InstallationEvidence) =
        match evidence.Platform with
        | ContextPlatform.Windows
        | ContextPlatform.NativeLinux -> None
        | ContextPlatform.Proton -> evidence.Proton |> Option.map _.PrefixPath
        | ContextPlatform.Wine -> evidence.Wine |> Option.map _.Selection.Prefix

    let paths (evidence: InstallationEvidence) =
        let original =
            match evidence.Platform with
            | ContextPlatform.Windows
            | ContextPlatform.NativeLinux -> []
            | ContextPlatform.Proton ->
                evidence.Proton |> Option.map _.Paths |> Option.defaultValue []
            | ContextPlatform.Wine -> evidence.Wine |> Option.map _.Paths |> Option.defaultValue []

        let project (entry: ContextPath) =
            let location =
                match entry.Name with
                | "Documents" -> evidence.Locations.Documents
                | "Local AppData" -> evidence.Locations.LocalAppData
                | "Saves" -> evidence.Locations.Saves
                | name when name.EndsWith(".ini", StringComparison.OrdinalIgnoreCase) ->
                    match evidence.Locations.Documents with
                    | Location.Located(path, _) ->
                        let file = System.IO.Path.Combine(path, name)
                        Location.Located(file, System.IO.File.Exists file)
                    | Location.Unavailable reason -> Location.Unavailable reason
                | _ -> entry.HostLocation

            if location = entry.HostLocation then
                entry
            else
                { entry with
                    HostLocation = location
                    WindowsPath =
                        match location with
                        | Location.Located(path, _) -> Some("Z:" + path.Replace('/', '\\'))
                        | Location.Unavailable _ -> None }

        original |> List.map project

    let name (evidence: InstallationEvidence) =
        match evidence.Platform with
        | ContextPlatform.Windows -> "Windows"
        | ContextPlatform.NativeLinux -> "Native Linux"
        | ContextPlatform.Proton ->
            evidence.Proton |> Option.map _.RuntimeName |> Option.defaultValue "Proton"
        | ContextPlatform.Wine -> "Wine"

type GameBinding =
    { Id: Guid
      GameId: GameId
      Path: string
      Proton: ProtonSelection option
      Wine: WineSelection option
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
