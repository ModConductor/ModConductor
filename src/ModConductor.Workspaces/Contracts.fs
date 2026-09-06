namespace ModConductor.Workspaces

open System
open System.Threading.Tasks
open ModConductor.Platform

type Profile = { Id: Guid; Name: string }

[<RequireQualifiedAccess>]
type RootIssueReason =
    | IncompleteCreation
    | OwnershipUnproved
    | IdentityUnverified

type RootIssue =
    { ReceiptRevision: int64
      Reason: RootIssueReason }

type Workspace =
    { Id: Guid
      Name: string
      Path: HostPath
      Revision: int64
      SelectedProfile: Profile option
      PendingRoot: RootIssue option }

type WorkspacePage =
    { Workspace: Workspace
      Profiles: Profile list
      NextProfile: Guid option }

type WorkspaceList =
    { Workspaces: Workspace list
      NextWorkspace: Guid option }

[<RequireQualifiedAccess>]
type WorkspaceError =
    | NotFound
    | StaleRevision
    | IdentityConflict
    | SelectedProfile
    | InvalidName
    | InvalidRoot of string
    | RootUnresolved
    | Busy

[<RequireQualifiedAccess>]
type ProfileEdit =
    | Create of Profile
    | Clone of source: Guid * copy: Profile
    | Rename of Guid * string
    | Select of Guid
    | Delete of Guid

type ProfileChange =
    { Workspace: Workspace
      Changed: Profile option
      Deleted: Guid option }

type IWorkspaceState =
    abstract Create: Guid * string * SelectedRoot -> Task<Result<WorkspacePage, WorkspaceError>>
    abstract Open: SelectedRoot -> Task<Result<WorkspacePage, WorkspaceError>>
    abstract Read: Guid * Guid option -> Task<Result<WorkspacePage, WorkspaceError>>
    abstract Edit: Guid * int64 * ProfileEdit -> Task<Result<ProfileChange, WorkspaceError>>
    abstract Check: Guid * int64 -> Task<Result<WorkspacePage, WorkspaceError>>
    abstract Recent: Guid option -> Task<WorkspaceList>
