namespace ModConductor.Migration

open System
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

[<RequireQualifiedAccess>]
type Error =
    | InvalidSource of string
    | TargetNotEmpty
    | UnsafeSource of string
    | CaseCollision of string
    | UnsupportedData of string
    | SourceChanged
    | Cancelled
    | Busy
    | Unavailable of string

type Request =
    { WorkspaceId: Guid
      SourceFolder: string }

type Progress =
    { Completed: int
      Total: int
      Message: string }

type Result =
    { WorkspaceId: Guid
      Profiles: int
      Mods: int
      Artifacts: int }

type Category =
    { SourceId: int
      Label: string
      ParentSourceId: int option }

type File =
    { Id: Guid
      Path: LogicalPath
      Length: int64
      Sha256: string
      Identity: FileIdentity }

type Mod =
    { Id: Guid
      VersionId: Guid
      Kind: ModKind
      Metadata: ModMetadata
      CategorySourceIds: int list
      Files: File list }

type Profile =
    { Id: Guid
      Name: string
      Mods: OrderedMod list }

type Artifact =
    { Id: Guid
      OriginalName: string
      OriginalPath: string
      FileName: string
      File: File
      Partial: bool
      Sources: string list
      InstalledMod: Guid option }

type Target =
    { ActionId: Guid
      WorkspaceId: Guid
      WorkspacePath: HostPath
      WorkspaceIdentity: FileIdentity
      ExpectedRevision: int64
      StagedName: string
      FinalName: string }

type Commit =
    { Target: Target
      LibraryIdentity: FileIdentity
      Categories: Category list
      Mods: Mod list
      Profiles: Profile list
      SelectedProfile: Guid
      Artifacts: Artifact list }

type IStore =
    abstract Begin:
        Guid * Guid * string * string -> Task<Microsoft.FSharp.Core.Result<Target, Error>>

    abstract Ready: Target -> Task<Microsoft.FSharp.Core.Result<unit, Error>>

    abstract Complete: Commit -> Task<Microsoft.FSharp.Core.Result<Result, Error>>

    abstract Abandon: Target -> Task<unit>
