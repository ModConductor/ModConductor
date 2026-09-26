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
        task {
            match action.Kind with
            | ProfileDataActionKind.Edit(options, saves, _) ->
                let! privateData = DataInitialization.profile repository context action.ProfileId

                let! initialized =
                    DataInitialization.seed
                        repository
                        context
                        privateData
                        options
                        saves
                        scope.Game
                        token
                        progress

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
                let! privateData = DataInitialization.profile repository context action.ProfileId

                return Some privateData, None
            | ProfileDataActionKind.Restore -> return None, None
            | ProfileDataActionKind.EditConfiguration _ ->
                let privateData =
                    scope.Profile
                    |> Option.defaultWith (fun () ->
                        raise (ProfileDataException ProfileDataError.NotFound))

                return Some privateData, None
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

                return context, prepared
            }
        | _ -> DataActionPreparation.prepare repository context action incoming desiredPlugins token

    let finishDeletion
        (repository: IProfileDataRepository)
        (action: ProfileDataActionRecord)
        changed
        token
        progress
        =
        task {
            match action.Kind, changed with
            | ProfileDataActionKind.Edit(options, _, DisabledFiles.Delete), Some profile ->
                let mutable action = action

                if action.Deletion.IsNone then
                    let trees =
                        [ if not options.Settings then
                              yield SaveTrees.observe profile.Settings.Value token progress
                          if not options.Saves then
                              yield SaveTrees.observe profile.Saves.Value token progress ]

                    action <-
                        { action with
                            Deletion = Some(ProfileDeletion.prepare trees []) }

                    do! repository.SaveAction action

                let! deleted = ProfileDeletion.run action repository.SaveAction token progress

                let profile =
                    { profile with
                        SettingsInitialized = options.Settings && profile.SettingsInitialized
                        SavesInitialized = options.Saves && profile.SavesInitialized
                        ArchiveList = if options.Settings then profile.ArchiveList else None }

                return deleted, Some profile
            | ProfileDataActionKind.SaveFiles receipt, Some _ when
                receipt.Action = ProfileSaveAction.DeleteFromProfile
                ->
                let! deleted = ProfileDeletion.run action repository.SaveAction token progress
                return deleted, changed
            | _ -> return action, changed
        }
