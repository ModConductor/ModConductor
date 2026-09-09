namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts

module internal DataInitialization =
    let context (repository: IProfileDataRepository) (scope: ProfileDataScope) =
        task {
            let! initial =
                task {
                    match scope.Context with
                    | Some value -> return value
                    | None ->
                        let documents = DataLocations.documents scope.Game

                        return!
                            repository.CreateContext
                                { Id = DataLocations.id scope.WorkspaceId documents
                                  WorkspaceId = scope.WorkspaceId
                                  Revision = 0L
                                  Workspace = scope.Workspace
                                  Documents = documents
                                  Storage = None
                                  OriginalsRoot = None
                                  Applied = None
                                  Pending = None }
                }

            match initial.Storage with
            | Some storage ->
                DataLocations.existing initial.Workspace storage |> ignore
                return initial
            | None ->
                let created =
                    DataLocations.child
                        initial.Workspace
                        (".mod-conductor-profile-data-" + initial.Id.ToString("N"))

                let updated = { initial with Storage = Some created }
                do! repository.SaveContext updated
                return updated
        }

    let profile (repository: IProfileDataRepository) (context: ProfileDataContext) id =
        task {
            let! previous = repository.Profile(context.Id, id)

            let mutable value =
                previous
                |> Option.defaultValue
                    { ProfileId = id
                      Revision = 0L
                      Options = { Settings = false; Saves = false }
                      Root = None
                      Settings = None
                      Saves = None
                      SettingsInitialized = false
                      SavesInitialized = false }

            if previous.IsNone then
                do! repository.SaveProfile(context.Id, value)

            match value.Root with
            | Some root -> DataLocations.existing context.Storage.Value root |> ignore
            | None ->
                value <-
                    { value with
                        Root = Some(DataLocations.child context.Storage.Value (id.ToString("N"))) }

                do! repository.SaveProfile(context.Id, value)

            match value.Settings with
            | Some root -> DataLocations.existing value.Root.Value root |> ignore
            | None ->
                value <-
                    { value with
                        Settings = Some(DataLocations.child value.Root.Value "settings") }

                do! repository.SaveProfile(context.Id, value)

            match value.Saves with
            | Some root -> DataLocations.existing value.Root.Value root |> ignore
            | None ->
                value <-
                    { value with
                        Saves = Some(DataLocations.child value.Root.Value "saves") }

                do! repository.SaveProfile(context.Id, value)

            return value
        }

    let seed
        (repository: IProfileDataRepository)
        (context: ProfileDataContext)
        (profile: PrivateProfileData)
        (options: ProfileDataOptions)
        initialSaves
        (game: GameContextState)
        (token: CancellationToken)
        progress
        =
        task {
            let mutable value = profile

            if options.Settings && not value.SettingsInitialized then
                let globals = SettingsPreparation.globalSettings context token

                use settings =
                    HeldDirectory.Open(value.Settings.Value.Path, value.Settings.Value.Identity)

                for name, bytes in globals do
                    token.ThrowIfCancellationRequested()

                    match DataFiles.observe settings name token with
                    | Some prior -> settings.RemoveFile(name, prior.Identity)
                    | None -> ()

                    bytes
                    |> Option.iter (fun bytes ->
                        DataFiles.stage settings name bytes token |> ignore)

                value <-
                    { value with
                        SettingsInitialized = true }

                do! repository.SaveProfile(context.Id, value)

            if options.Saves && not value.SavesInitialized then
                let destination = value.Saves.Value
                let existing = SaveTrees.observe destination token ignore
                SaveTrees.remove existing token ignore

                match initialSaves with
                | InitialSaves.Empty -> ()
                | InitialSaves.CopyGlobal ->
                    match game.Binding.Value.Evidence.Locations.Saves with
                    | Location.Located(path, true) ->
                        let source = DataLocations.root path

                        if source.Identity = destination.Identity then
                            raise (
                                ProfileDataException(
                                    ProfileDataError.Invalid
                                        "The global and private save folders are the same."
                                )
                            )

                        let observed = SaveTrees.observe source token progress
                        SaveTrees.copy observed destination token progress
                    | Location.Located(_, false) -> ()
                    | Location.Unavailable reason ->
                        raise (ProfileDataException(ProfileDataError.Unavailable reason))

                value <- { value with SavesInitialized = true }
                do! repository.SaveProfile(context.Id, value)

            return value
        }
