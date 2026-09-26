namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform

module internal ConfigurationRecovery =
    let private replacement (change: PreparedFileChange) =
        change.Replacement
        |> Option.defaultWith (fun () ->
            raise (
                ProfileDataException(
                    ProfileDataError.Conflict "The prepared profile file is unavailable."
                )
            ))

    let private checkCurrent
        (change: PreparedFileChange)
        (replacement: StoredDataFile)
        completed
        (staged: DataFile option)
        (current: DataFile option)
        =
        let replacementWasInstalled = completed || staged.IsNone

        match current, change.Before, replacementWasInstalled with
        | Some file, _, _ when file = replacement.File -> ()
        | None, Some _, true -> DataFiles.fail (change.Name + " changed. It was left untouched.")
        | None, _, _ -> ()
        | Some _, _, _ -> DataFiles.fail (change.Name + " changed. It was left untouched.")

    let private checkOriginal (change: PreparedFileChange) (backup: DataFile option) =
        match change.Before, backup with
        | Some original, Some preserved when original = preserved -> ()
        | None, None -> ()
        | _ ->
            DataFiles.fail (
                change.Name + " has a different preserved original. It was left untouched."
            )

    let private checkStaged
        (change: PreparedFileChange)
        (replacement: StoredDataFile)
        (staged: DataFile option)
        =
        match staged with
        | Some file when file = replacement.File -> ()
        | None -> ()
        | Some _ -> DataFiles.fail (change.Name + " has a different prepared copy.")

    let private restoreBackup
        (target: HeldDirectory)
        (backups: HeldDirectory)
        (change: PreparedFileChange)
        (backup: DataFile option)
        =
        match change.Before, backup with
        | Some _, Some preserved ->
            backups.MoveOriginal(
                change.BackupName,
                { Identity = preserved.Identity
                  Kind = EntryKind.RegularFile
                  LinkTarget = None
                  DirectoryLink = None },
                target,
                change.Name
            )
        | None, None -> ()
        | _ -> invalidOp "The preserved original was checked above."

    let private restoreEffect
        (action: ProfileDataActionRecord)
        (effect: ProfileDataFilesEffect)
        token
        =
        use target = HeldDirectory.Open(effect.Target.Path, effect.Target.Identity)
        use backups = HeldDirectory.Open(effect.Backups.Path, effect.Backups.Identity)
        let change = effect.Change
        let current = DataFiles.observe target change.Name token
        let backup = DataFiles.observe backups change.BackupName token
        let replacement = replacement change
        let staged = DataFiles.observe backups replacement.Name token

        checkCurrent change replacement (action.CompletedFiles > 0) staged current
        checkOriginal change backup
        checkStaged change replacement staged

        current
        |> Option.iter (fun file -> target.RemoveFile(change.Name, file.Identity))

        restoreBackup target backups change backup

        staged
        |> Option.iter (fun file -> backups.RemoveFile(replacement.Name, file.Identity))

    let restoreOriginal (action: ProfileDataActionRecord) (token: CancellationToken) =
        match action.Kind, action.Prepared, action.Files with
        | ProfileDataActionKind.EditConfiguration _, false, _ -> ()
        | ProfileDataActionKind.EditConfiguration _, true, [ effect ] ->
            restoreEffect action effect token
        | ProfileDataActionKind.EditConfiguration _, true, _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Conflict "The profile file receipt is invalid."
                )
            )
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "This action is not a profile file edit."
                )
            )

    let checkResume (action: ProfileDataActionRecord) (token: CancellationToken) =
        match action.Kind, action.Files with
        | ProfileDataActionKind.EditConfiguration _, [ effect ] when action.CompletedFiles > 0 ->
            use target = HeldDirectory.Open(effect.Target.Path, effect.Target.Identity)

            let replacement =
                effect.Change.Replacement
                |> Option.defaultWith (fun () ->
                    raise (
                        ProfileDataException(
                            ProfileDataError.Conflict "The profile file receipt is invalid."
                        )
                    ))

            match DataFiles.observe target effect.Change.Name token with
            | Some current when current = replacement.File -> ()
            | _ -> DataFiles.fail (effect.Change.Name + " changed. It was left untouched.")
        | ProfileDataActionKind.EditConfiguration _, _ when action.CompletedFiles > 0 ->
            raise (
                ProfileDataException(
                    ProfileDataError.Conflict "The profile file receipt is invalid."
                )
            )
        | _ -> ()
