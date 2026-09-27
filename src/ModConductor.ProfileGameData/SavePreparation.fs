namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform

module internal SavePreparation =
    let private clear (root: DataRoot) =
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        for name in directory.Names |> Seq.toList do
            match directory.InspectEntry name with
            | Some entry when entry.Kind = EntryKind.RegularFile ->
                directory.RemoveFile(name, entry.Identity)
            | Some _ -> DataFiles.fail "The prepared save action contains an unsupported entry."
            | None -> ()

    let prepare
        (repository: IProfileDataRepository)
        (scope: ProfileDataScope)
        (context: ProfileDataContext)
        (action: ProfileDataActionRecord)
        (profile: PrivateProfileData)
        (token: CancellationToken)
        progress
        =
        ProfileDataResultTask.resultTask {
            if action.Prepared then
                return context, action
            else
                let receipt =
                    match action.Kind with
                    | ProfileDataActionKind.SaveFiles value -> value
                    | _ -> invalidOp "Use save preparation only for save actions."

                do! SaveGroups.checkReceipt scope receipt token

                let changed =
                    { profile with
                        Revision = profile.Revision + 1L }

                match receipt.Action with
                | ProfileSaveAction.CopyToProfile ->
                    let! stagesResult = DataActionPreparation.stages repository context action
                    let! context, staged = stagesResult
                    clear staged.WorkspaceStage.Value
                    let mutable copied = 0L
                    let effects = ResizeArray<ProfileDataFilesEffect>()

                    receipt.Files
                    |> List.iteri (fun index file ->
                        token.ThrowIfCancellationRequested()
                        let source = file.Source.Value
                        use sourceRoot = HeldDirectory.Open(source.Root.Path, source.Root.Identity)

                        use target =
                            HeldDirectory.Open(
                                staged.WorkspaceStage.Value.Path,
                                staged.WorkspaceStage.Value.Identity
                            )

                        let stagedName = "save-" + string index

                        let replacement =
                            DataFiles.copy
                                sourceRoot
                                source.Name
                                source.File
                                target
                                stagedName
                                token
                                (fun bytes ->
                                    progress
                                        { Files = effects.Count
                                          Bytes = copied + bytes })

                        copied <- copied + replacement.Length

                        effects.Add
                            { Target = file.Target
                              Backups = staged.DocumentsStage.Value
                              Change =
                                { Name = file.Name
                                  Before = file.Before
                                  Replacement =
                                    Some
                                        { Root = staged.WorkspaceStage.Value
                                          Name = stagedName
                                          File = replacement }
                                  BackupName = "save-original-" + string index } })

                    do! SaveGroups.checkReceipt scope receipt token

                    let prepared =
                        { staged with
                            Prepared = true
                            ChangedProfile = Some changed
                            Files = List.ofSeq effects }

                    let! saved = repository.SaveAction prepared
                    do! saved
                    return context, prepared
                | ProfileSaveAction.DeleteFromProfile ->
                    let deletion =
                        { Files =
                            receipt.Files
                            |> List.map (fun file ->
                                { Root = file.Target
                                  Name = file.Name
                                  File = file.Before.Value })
                          Directories = []
                          CompletedFiles = 0
                          CompletedDirectories = 0 }

                    let prepared =
                        { action with
                            Prepared = true
                            ChangedProfile = Some changed
                            Deletion = Some deletion }

                    let! saved = repository.SaveAction prepared
                    do! saved
                    return context, prepared
        }
