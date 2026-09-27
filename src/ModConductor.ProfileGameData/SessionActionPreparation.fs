namespace ModConductor.ProfileGameData

open System.Threading.Tasks
open ModConductor.GameContexts

module internal ProfileDataActionPreparation =
    let prepareIncoming
        (repository: IProfileDataRepository)
        (scope: ProfileDataScope)
        (context: ProfileDataContext)
        (action: ProfileDataActionRecord)
        token
        progress
        =
        ProfileDataResultTask.resultTask {
            match action.Kind with
            | ProfileDataActionKind.Edit(options, saves, _) ->
                let! privateDataResult =
                    DataInitialization.profile repository context action.ProfileId

                let! privateData = privateDataResult

                let! initializationResult =
                    DataInitialization.seed
                        repository
                        context
                        privateData
                        options
                        saves
                        scope.Game
                        token
                        progress

                let! initialized = initializationResult

                let changed =
                    { initialized with
                        Options = options
                        Revision = initialized.Revision + 1L }

                let incoming =
                    match context.Applied with
                    | Some active when active.ProfileId = action.ProfileId ->
                        Some
                            { initialized with
                                Options =
                                    { Settings = active.Options.Settings && options.Settings
                                      Saves = active.Options.Saves && options.Saves } }
                    | _ -> None

                return incoming, Some changed
            | ProfileDataActionKind.Apply
            | ProfileDataActionKind.ApplyArchives _
            | ProfileDataActionKind.RestoreArchives
            | ProfileDataActionKind.SaveFiles _ ->
                let! privateDataResult =
                    DataInitialization.profile repository context action.ProfileId

                let! privateData = privateDataResult

                return Some privateData, None
            | ProfileDataActionKind.Restore -> return None, None
            | ProfileDataActionKind.EditConfiguration _ ->
                match scope.Profile with
                | Some privateData -> return Some privateData, None
                | None -> return! Error ProfileDataError.NotFound
            | ProfileDataActionKind.Clone _
            | ProfileDataActionKind.Delete _ -> return invalidOp "Use the profile mutation owner."
        }

    let affectsGame (context: ProfileDataContext) (action: ProfileDataActionRecord) =
        match action.Kind with
        | ProfileDataActionKind.Edit(options, _, _) ->
            context.Applied
            |> Option.exists (fun active ->
                active.ProfileId = action.ProfileId
                && ((active.Options.Settings && not options.Settings)
                    || (active.Options.Saves && not options.Saves)))
        | ProfileDataActionKind.EditConfiguration _ -> false
        | _ -> true

    let prepareEffects
        (repository: IProfileDataRepository)
        (archives: ModConductor.Bethesda.ArchivePolicySession)
        desiredPlugins
        (scope: ProfileDataScope)
        (context: ProfileDataContext)
        (action: ProfileDataActionRecord)
        (incoming: PrivateProfileData option)
        token
        progress
        =
        match action.Kind with
        | ProfileDataActionKind.ApplyArchives _
        | ProfileDataActionKind.RestoreArchives ->
            ArchivePreparation.prepare repository archives context action incoming.Value token
        | ProfileDataActionKind.SaveFiles _ ->
            SavePreparation.prepare repository scope context action incoming.Value token progress
        | ProfileDataActionKind.EditConfiguration receipt ->
            task {
                let! prepared =
                    ConfigurationPreparation.prepare
                        repository
                        context
                        action
                        incoming.Value
                        receipt
                        token

                return prepared |> Result.map (fun action -> context, action)
            }
        | _ -> DataActionPreparation.prepare repository context action incoming desiredPlugins token

    let finishDeletion
        (repository: IProfileDataRepository)
        (action: ProfileDataActionRecord)
        changed
        token
        progress
        =
        ProfileDataResultTask.resultTask {
            match action.Kind, changed with
            | ProfileDataActionKind.Edit(options, _, DisabledFiles.Delete), Some profile ->
                let mutable action = action

                if action.Deletion.IsNone then
                    let roots =
                        [ if not options.Settings then
                              yield profile.Settings.Value
                          if not options.Saves then
                              yield profile.Saves.Value ]

                    let! trees =
                        roots
                        |> ProfileDataResultFlow.traverse (fun root ->
                            SaveTrees.observe root token progress)

                    action <-
                        { action with
                            Deletion = Some(ProfileDeletion.prepare trees []) }

                    let! saved = repository.SaveAction action
                    do! saved

                let! deletedResult = ProfileDeletion.run action repository.SaveAction token progress
                let! deleted = deletedResult

                let profile =
                    { profile with
                        SettingsInitialized = options.Settings && profile.SettingsInitialized
                        SavesInitialized = options.Saves && profile.SavesInitialized
                        ArchiveList = if options.Settings then profile.ArchiveList else None }

                return deleted, Some profile
            | ProfileDataActionKind.SaveFiles receipt, Some _ when
                receipt.Action = ProfileSaveAction.DeleteFromProfile
                ->
                let! deletedResult = ProfileDeletion.run action repository.SaveAction token progress
                let! deleted = deletedResult
                return deleted, changed
            | _ -> return action, changed
        }
