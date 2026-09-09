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
    abstract Read: workspace: Guid * profile: Guid -> Task<ProfileDataScope>
    abstract HasData: workspace: Guid -> Task<bool>
    abstract CreateContext: ProfileDataContext -> Task<ProfileDataContext>
    abstract SaveContext: ProfileDataContext -> Task<unit>
    abstract SaveProfile: context: Guid * PrivateProfileData -> Task<unit>
    abstract Profile: context: Guid * profile: Guid -> Task<PrivateProfileData option>
    abstract Claim: ProfileDataContext * ProfileDataActionRecord -> Task<ProfileDataActionRecord>
    abstract Action: workspace: Guid * id: Guid -> Task<ProfileDataActionRecord option>
    abstract SaveAction: ProfileDataActionRecord -> Task<unit>

    abstract Complete:
        ProfileDataContext * PrivateProfileData option * ProfileDataActionRecord -> Task<unit>

    abstract Release: id: Guid -> Task<unit>
