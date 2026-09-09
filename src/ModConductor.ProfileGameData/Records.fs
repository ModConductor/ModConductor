namespace ModConductor.ProfileGameData

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform

type internal PrivateProfileData =
    { ProfileId: Guid
      Revision: int64
      Options: ProfileDataOptions
      Root: DataRoot option
      Settings: DataRoot option
      Saves: DataRoot option
      SettingsInitialized: bool
      SavesInitialized: bool }

type internal GlobalIni =
    { Name: string
      Original: StoredDataFile option }

type internal AppliedProfileData =
    { ProfileId: Guid
      Options: ProfileDataOptions
      Originals: GlobalIni list
      SaveOverride: SavePathOverride option
      SaveLink: FileIdentity option }

type internal ProfileDataContext =
    { Id: Guid
      WorkspaceId: Guid
      Revision: int64
      Workspace: DataRoot
      Documents: DataRoot
      Storage: DataRoot option
      OriginalsRoot: DataRoot option
      Applied: AppliedProfileData option
      Pending: Guid option }

type internal ProfileDataFilesEffect =
    { Target: DataRoot
      Backups: DataRoot
      Change: PreparedFileChange }

[<RequireQualifiedAccess>]
type internal SaveLinkEffect =
    | Unchanged
    | Remove of FileIdentity
    | Create of target: DataRoot
    | Replace of previous: FileIdentity * target: DataRoot

[<RequireQualifiedAccess>]
type internal ProfileDataActionKind =
    | Edit of ProfileDataOptions * InitialSaves * DisabledFiles
    | Apply
    | Restore
    | Clone of target: Guid * name: string * workspaceRevision: int64
    | Delete of workspaceRevision: int64

type internal ProfileDataDirectoryRemoval =
    { Parent: DataRoot
      Name: string
      Identity: FileIdentity }

type internal ProfileDataDeletion =
    { Files: StoredDataFile list
      Directories: ProfileDataDirectoryRemoval list
      CompletedFiles: int
      CompletedDirectories: int }

type internal ProfileDataActionRecord =
    { Id: Guid
      ContextId: Guid
      ProfileId: Guid
      ExpectedRevision: int64
      Kind: ProfileDataActionKind
      Deletion: ProfileDataDeletion option
      CloneTarget: PrivateProfileData option
      Prepared: bool
      WorkspaceStage: DataRoot option
      DocumentsStage: DataRoot option
      Files: ProfileDataFilesEffect list
      CompletedFiles: int
      Link: SaveLinkEffect
      LinkRemoved: bool
      LinkCreated: FileIdentity option
      Proposed: AppliedProfileData option
      Complete: bool
      Problem: string option }
