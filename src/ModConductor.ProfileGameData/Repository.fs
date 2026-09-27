namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks
open ModConductor.GameContexts

type internal ProfileDataScope =
    { WorkspaceId: Guid
      ProfileId: Guid
      Workspace: DataRoot
      Game: GameContextState
      Availability: string option
      Context: ProfileDataContext option
      Profile: PrivateProfileData option }

type internal IProfileDataRepository =
    abstract Read:
        workspace: Guid * profile: Guid -> Task<Result<ProfileDataScope, ProfileDataError>>

    abstract HasData: workspace: Guid -> Task<bool>
    abstract CreateContext: ProfileDataContext -> Task<Result<ProfileDataContext, ProfileDataError>>
    abstract SaveContext: ProfileDataContext -> Task<Result<unit, ProfileDataError>>
    abstract SaveProfile: context: Guid * PrivateProfileData -> Task<Result<unit, ProfileDataError>>

    abstract SaveOrder:
        ProfileDataContext * PrivateProfileData * ModConductor.FilePlanning.SourceStamp ->
            Task<Result<unit, ProfileDataError>>

    abstract Profile: context: Guid * profile: Guid -> Task<PrivateProfileData option>

    abstract Claim:
        ProfileDataContext * ProfileDataActionRecord ->
            Task<Result<ProfileDataActionRecord, ProfileDataError>>

    abstract Action:
        workspace: Guid * id: Guid -> Task<Result<ProfileDataActionRecord option, ProfileDataError>>

    abstract Context: id: Guid -> Task<Result<ProfileDataContext, ProfileDataError>>
    abstract SaveAction: ProfileDataActionRecord -> Task<Result<unit, ProfileDataError>>
    abstract Discard: ProfileDataActionRecord -> Task<Result<unit, ProfileDataError>>

    abstract Complete:
        ProfileDataContext * PrivateProfileData option * ProfileDataActionRecord ->
            Task<Result<unit, ProfileDataError>>

    abstract Release: id: Guid -> Task<unit>
