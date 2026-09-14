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
      SettingsInitialized: bool
      SavesInitialized: bool
      Pending: Guid option
      PendingProfileChange: bool
      PendingConfiguration: string option
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

type ProfileConfigurationFile =
    { Name: string
      Exists: bool
      Bytes: int64 }

type ProfileConfigurationDocument =
    { PreviewId: Guid
      Expected: ProfileDataRef
      Name: string
      Exists: bool
      Length: int64
      Sha256: string option
      Document: ModConductor.FilePlanning.TextDocument }

type ProfileConfigurationEdit =
    { Id: Guid
      PreviewId: Guid
      Expected: ProfileDataRef
      Name: string
      Content: string }

type ProfileSaveEntry =
    { Name: string
      Directory: bool
      Bytes: int64 }

type ProfileSavePage =
    { Entries: ProfileSaveEntry list
      Next: string option }

[<RequireQualifiedAccess>]
type ProfileSaveSource =
    | Global
    | Profile

[<RequireQualifiedAccess>]
type ProfileSaveEntryKind =
    | Save
    | Directory
    | Other

type ProfileSaveGroupEntry =
    { Id: string
      Name: string
      Kind: ProfileSaveEntryKind
      Bytes: int64
      Companion: string option
      CompanionBytes: int64
      Actionable: bool
      Problem: string option }

type ProfileSavePath =
    { HostPath: string
      WindowsPath: string option }

type ProfileSaveGroupPage =
    { Source: ProfileSaveSource
      Path: ProfileSavePath
      Entries: ProfileSaveGroupEntry list
      Next: string option }

[<RequireQualifiedAccess>]
type SavePluginState =
    | Missing
    | Inactive

type SavePluginIssue =
    { Name: string
      State: SavePluginState
      Source: string option }

type ProfileSaveInspection =
    { Source: ProfileSaveSource
      Path: ProfileSavePath
      Entry: ProfileSaveGroupEntry
      Metadata: ModConductor.Bethesda.SkyrimSaveMetadata option
      MetadataProblem: string option
      PluginIssues: SavePluginIssue list
      PluginCheckProblem: string option }

[<RequireQualifiedAccess>]
type ProfileSaveAction =
    | CopyToProfile
    | DeleteFromProfile

type ProfileSaveActionFile = { Name: string; Bytes: int64 }

type ProfileSaveActionPreview =
    { Id: Guid
      Expected: ProfileDataRef
      Action: ProfileSaveAction
      Source: ProfileSavePath
      Destination: ProfileSavePath option
      Files: ProfileSaveActionFile list
      Bytes: int64 }

type ProfilePluginOrder =
    { Reference: ProfileDataRef
      Headers: ModConductor.Bethesda.PluginSnapshot
      Facts: ModConductor.Bethesda.PluginOrderFacts
      View: ModConductor.Bethesda.PluginOrderView
      Saved: bool
      Applied: bool
      ExternalChanged: bool
      Pending: bool
      Problem: string option }

type ProfileArchivePolicy =
    { Reference: ProfileDataRef
      Snapshot: ModConductor.Bethesda.ArchivePolicySnapshot
      IniName: string
      Saved: bool
      Applied: bool
      Pending: bool
      Problem: string option }

type IProfilePluginOrders =
    abstract Read:
        workspace: Guid * profile: Guid * headers: Guid ->
            Task<Result<ProfilePluginOrder, ProfileDataError>>

    abstract Change:
        expected: ProfileDataRef * headers: Guid * ModConductor.Bethesda.PluginOrderChange ->
            Task<Result<ProfilePluginOrder, ProfileDataError>>

    abstract UseGameOrder:
        expected: ProfileDataRef * headers: Guid ->
            Task<Result<ProfilePluginOrder, ProfileDataError>>

    abstract ApplyExactOrder:
        expected: ProfileDataRef * headers: Guid * names: string list ->
            Task<Result<ProfilePluginOrder, ProfileDataError>>

type IProfileArchivePolicies =
    abstract Scan:
        workspace: Guid * profile: Guid * headers: Guid * CancellationToken ->
            Task<Result<ProfileArchivePolicy, ProfileDataError>>

    abstract Read:
        workspace: Guid * profile: Guid * snapshot: Guid * CancellationToken ->
            Task<Result<ProfileArchivePolicy, ProfileDataError>>

    abstract Apply:
        id: Guid *
        expected: ProfileDataRef *
        snapshot: Guid *
        (ProfileDataProgress -> unit) *
        CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Restore:
        id: Guid * expected: ProfileDataRef * (ProfileDataProgress -> unit) * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

type IProfileGameData =
    abstract SaveFiles:
        workspace: Guid * profile: Guid * path: string list * after: string option ->
            Task<Result<ProfileSavePage, ProfileDataError>>

    abstract Read:
        workspace: Guid * profile: Guid -> Task<Result<ProfileDataState, ProfileDataError>>

    abstract ConfigurationFiles:
        expected: ProfileDataRef * CancellationToken ->
            Task<Result<ProfileConfigurationFile list, ProfileDataError>>

    abstract ReadConfiguration:
        expected: ProfileDataRef * name: string * CancellationToken ->
            Task<Result<ProfileConfigurationDocument, ProfileDataError>>

    abstract SaveConfiguration:
        ProfileConfigurationEdit * (ProfileDataProgress -> unit) * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract RestoreConfiguration:
        workspace: Guid * action: Guid * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract SaveGroups:
        workspace: Guid * profile: Guid * source: ProfileSaveSource * after: string option ->
            Task<Result<ProfileSaveGroupPage, ProfileDataError>>

    abstract InspectSave:
        workspace: Guid *
        profile: Guid *
        source: ProfileSaveSource *
        name: string *
        headers: Guid option *
        CancellationToken ->
            Task<Result<ProfileSaveInspection, ProfileDataError>>

    abstract PreviewSaveAction:
        expected: ProfileDataRef *
        action: ProfileSaveAction *
        names: string list *
        CancellationToken ->
            Task<Result<ProfileSaveActionPreview, ProfileDataError>>

    abstract ApplySaveAction:
        id: Guid *
        preview: Guid *
        expected: ProfileDataRef *
        (ProfileDataProgress -> unit) *
        CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Edit:
        ProfileDataEdit * (ProfileDataProgress -> unit) * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Restore:
        id: Guid * expected: ProfileDataRef * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>

    abstract Resume:
        workspace: Guid * id: Guid * CancellationToken ->
            Task<Result<ProfileDataResult, ProfileDataError>>
