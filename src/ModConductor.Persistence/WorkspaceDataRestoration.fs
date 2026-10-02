namespace ModConductor.Persistence

open System
open ModConductor.Deployment
open ModConductor.GameContexts
open ModConductor.ProfileGameData

module internal WorkspaceDataRestoration =
    let private stopped (context: ProfileDataContext) (game: GameContextState) =
        match game.Binding with
        | None ->
            Error(ProfileDataError.Unavailable "The applied game's installation is unavailable.")
        | Some binding ->
            GameProcesses.checkWithRoot
                binding.Evidence
                (Some(GameViews.rootPath context.Workspace.Path context.Applied.Value.ProfileId))
            |> Result.mapError ProfileDataError.Unavailable

    let restore database access enter plugins archives (context: ProfileDataContext) token =
        task {
            let session =
                ProfileGameDataSession(
                    ProfileDataRepository(database, access, restoring = context),
                    enter,
                    stopped context,
                    plugins,
                    archives
                )
                :> IProfileGameData

            let! current = session.Read(context.WorkspaceId, context.Applied.Value.ProfileId)

            match current with
            | Error error -> return Error error
            | Ok current -> return! session.Restore(Guid.NewGuid(), current.Reference, token)
        }
