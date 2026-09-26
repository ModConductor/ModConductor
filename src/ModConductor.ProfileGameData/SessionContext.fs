namespace ModConductor.ProfileGameData

open System
open ModConductor.Bethesda
open ModConductor.GameContexts

type internal ProfileDataSessionContext =
    { Repository: IProfileDataRepository
      Plugins: PluginSession
      Archives: ArchivePolicySession
      Stopped: GameContextState -> unit
      ConfigurationCheckpoint: string -> unit
      Previews: ProfileDataPreviewCache }

module internal ProfileDataSessionContext =
    let requireIds ids =
        if ids |> List.contains Guid.Empty then
            Error(ProfileDataError.Invalid "The request contains an empty identifier.")
        else
            Ok()

    let read context =
        ProfileDataProjection.read context.Repository

    let execute context arguments =
        ProfileDataActions.execute
            { Repository = context.Repository
              Archives = context.Archives
              Stopped = context.Stopped
              Read = read context }
            arguments

    let replay context =
        ProfileDataActions.replay context.Repository (read context)
