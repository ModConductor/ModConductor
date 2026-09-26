namespace ModConductor.ProfileGameData

open System
open ModConductor.Platform

module internal ConfigurationPreparation =
    let private actualName held name =
        ConfigurationFiles.actualName held name
        |> Result.defaultWith (fun error -> raise (ProfileDataException error))

    let prepare
        (repository: IProfileDataRepository)
        (context: ProfileDataContext)
        (action: ProfileDataActionRecord)
        (profile: PrivateProfileData)
        (receipt: ConfigurationEditReceipt)
        token
        =
        task {
            if action.Prepared then
                return action
            else
                let! staged =
                    task {
                        match action.WorkspaceStage with
                        | Some root ->
                            DataLocations.existing context.Storage.Value root |> ignore
                            return action
                        | None ->
                            let staged =
                                { action with
                                    WorkspaceStage =
                                        Some(
                                            DataLocations.child
                                                context.Storage.Value
                                                ("action-" + action.Id.ToString("N"))
                                        ) }

                            do! repository.SaveAction staged
                            return staged
                    }

                let settings = profile.Settings.Value
                use target = HeldDirectory.Open(settings.Path, settings.Identity)
                let actual = actualName target receipt.Name

                if actual <> receipt.Name && receipt.Before.IsNone then
                    DataFiles.fail (receipt.Name + " changed.")

                DataFiles.check target actual receipt.Before token

                use staging =
                    HeldDirectory.Open(
                        staged.WorkspaceStage.Value.Path,
                        staged.WorkspaceStage.Value.Identity
                    )

                let replacementName = "edit-" + receipt.Name

                match DataFiles.observe staging replacementName token with
                | Some previous -> staging.RemoveFile(replacementName, previous.Identity)
                | None -> ()

                let replacement =
                    { Root = staged.WorkspaceStage.Value
                      Name = replacementName
                      File = DataFiles.stage staging replacementName receipt.Bytes token }

                let prepared =
                    { staged with
                        Prepared = true
                        ChangedProfile =
                            Some
                                { profile with
                                    Revision = profile.Revision + 1L }
                        Files =
                            [ { Target = settings
                                Backups = staged.WorkspaceStage.Value
                                Change =
                                  { Name = actual
                                    Before = receipt.Before
                                    Replacement = Some replacement
                                    BackupName = "previous-" + receipt.Name } } ] }

                do! repository.SaveAction prepared
                return prepared
        }
