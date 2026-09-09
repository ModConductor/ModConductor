namespace ModConductor.ProfileGameData

open System
open System.Threading
open System.Threading.Tasks

[<RequireQualifiedAccess>]
type ProfileDataError =
    | NotFound
    | Busy
    | Stale
    | Cancelled
    | Invalid of string
    | Unavailable of string
    | Conflict of string

type ProfileDataOptions = { Settings: bool; Saves: bool }

[<RequireQualifiedAccess>]
type InitialSaves =
    | Empty
    | CopyGlobal

[<RequireQualifiedAccess>]
type DisabledFiles =
    | Keep
    | Delete

type ProfileDataProgress = { Files: int; Bytes: int64 }

type ProfileDataRef =
    { WorkspaceId: Guid
      ProfileId: Guid
      ContextId: Guid
      Revision: int64 }

type ProfileDataState =
    { WorkspaceId: Guid
      ProfileId: Guid
      ContextId: Guid
      Revision: int64
      Options: ProfileDataOptions
      InUse: Guid option
      SettingsPath: string
      SavesPath: string
      SettingsFiles: int
      SaveFiles: int
      Pending: Guid option
      PendingProfileChange: bool
      Problem: string option }

    member this.Reference =
        { WorkspaceId = this.WorkspaceId
          ProfileId = this.ProfileId
          ContextId = this.ContextId
          Revision = this.Revision }
        : ProfileDataRef

type ProfileDataEdit =
    { Id: Guid
      Expected: ProfileDataRef
      Options: ProfileDataOptions
      InitialSaves: InitialSaves
      DisabledFiles: DisabledFiles }

type ProfileDataResult =
    { Id: Guid
      State: ProfileDataState
      Complete: bool
      CompletedFiles: int
      Problem: string option }

type ProfileDataApplication =
    { ReceiptId: Guid
      Revision: int64
      CompletedFiles: int
      Complete: bool
      Problem: string option }

type IProfileGameData =
    abstract Read:
        workspace: Guid * profile: Guid -> Task<Result<ProfileDataState, ProfileDataError>>

    abstract Edit:
        ProfileDataEdit * (ProfileDataProgress -> unit) * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Restore:
        id: Guid * expected: ProfileDataRef * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Resume:
        workspace: Guid * id: Guid * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>
