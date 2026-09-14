namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.FilePlanning

type internal ConfigurationPreview =
    { Public: ProfileConfigurationDocument
      Root: DataRoot
      Before: DataFile option
      Bytes: byte array }

module internal ConfigurationFiles =
    let private declared name =
        Skyrim.definition.IniFiles
        |> List.tryFind (fun value -> value.Equals(name, StringComparison.OrdinalIgnoreCase))
        |> Option.defaultWith (fun () ->
            raise (
                ProfileDataException(
                    ProfileDataError.Invalid "Choose a supported profile settings file."
                )
            ))

    let private settings (scope: ProfileDataScope) =
        match scope.Profile with
        | Some profile when profile.SettingsInitialized && profile.Settings.IsSome ->
            profile, profile.Settings.Value
        | _ ->
            raise (
                ProfileDataException(
                    ProfileDataError.Unavailable
                        "Turn on local game settings before editing profile files."
                )
            )

    let private actualName (held: HeldDirectory) name =
        let declared = declared name

        let matches =
            held.Names
            |> Seq.filter (fun actual ->
                actual.Equals(declared, StringComparison.OrdinalIgnoreCase))
            |> Seq.toList

        match matches with
        | [] -> declared
        | [ actual ] -> actual
        | _ -> DataFiles.fail (declared + " has more than one matching filename.")

    let list (scope: ProfileDataScope) (token: CancellationToken) =
        let _, root = settings scope
        use held = HeldDirectory.Open(root.Path, root.Identity)

        [ for name in Skyrim.definition.IniFiles do
              token.ThrowIfCancellationRequested()
              let actual = actualName held name
              let file = DataFiles.observe held actual token

              yield
                  { Name = name
                    Exists = file.IsSome
                    Bytes = file |> Option.map _.Length |> Option.defaultValue 0L } ]

    let read (scope: ProfileDataScope) expected name token =
        let _, root = settings scope
        use held = HeldDirectory.Open(root.Path, root.Identity)
        let actual = actualName held name
        let before = DataFiles.observe held actual token
        let bytes = DataFiles.readIni held actual before token |> Option.defaultValue [||]

        let document =
            TextDocuments.editable bytes
            |> Result.defaultWith (fun detail ->
                raise (ProfileDataException(ProfileDataError.Unavailable detail)))

        let publicValue =
            { PreviewId = Guid.NewGuid()
              Expected = expected
              Name = declared name
              Exists = before.IsSome
              Length = before |> Option.map _.Length |> Option.defaultValue 0L
              Sha256 = before |> Option.map _.Sha256
              Document = document }

        { Public = publicValue
          Root = root
          Before = before
          Bytes = bytes }

    let check (scope: ProfileDataScope) (preview: ConfigurationPreview) token =
        let _, root = settings scope

        if root <> preview.Root then
            raise (ProfileDataException ProfileDataError.Stale)

        use held = HeldDirectory.Open(root.Path, root.Identity)
        let actual = actualName held preview.Public.Name

        if actual <> preview.Public.Name && preview.Before.IsNone then
            DataFiles.fail (preview.Public.Name + " changed.")

        DataFiles.check held actual preview.Before token

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

    let restoreOriginal (action: ProfileDataActionRecord) (token: CancellationToken) =
        match action.Kind with
        | ProfileDataActionKind.EditConfiguration _ when not action.Prepared -> ()
        | ProfileDataActionKind.EditConfiguration _ ->
            match action.Files with
            | [ effect ] ->
                use target = HeldDirectory.Open(effect.Target.Path, effect.Target.Identity)
                use backups = HeldDirectory.Open(effect.Backups.Path, effect.Backups.Identity)
                let change = effect.Change
                let current = DataFiles.observe target change.Name token
                let backup = DataFiles.observe backups change.BackupName token

                let replacement =
                    change.Replacement
                    |> Option.defaultWith (fun () ->
                        raise (
                            ProfileDataException(
                                ProfileDataError.Conflict
                                    "The prepared profile file is unavailable."
                            )
                        ))

                let staged = DataFiles.observe backups replacement.Name token
                let replacementWasInstalled = action.CompletedFiles > 0 || staged.IsNone

                match current, change.Before, replacementWasInstalled with
                | Some file, _, _ when file = replacement.File -> ()
                | None, Some _, true ->
                    DataFiles.fail (change.Name + " changed. It was left untouched.")
                | None, _, _ -> ()
                | Some _, _, _ -> DataFiles.fail (change.Name + " changed. It was left untouched.")

                match change.Before, backup with
                | Some original, Some preserved when original = preserved -> ()
                | None, None -> ()
                | _ ->
                    DataFiles.fail (
                        change.Name + " has a different preserved original. It was left untouched."
                    )

                match staged with
                | Some file when file = replacement.File -> ()
                | None -> ()
                | Some _ -> DataFiles.fail (change.Name + " has a different prepared copy.")

                current
                |> Option.iter (fun file -> target.RemoveFile(change.Name, file.Identity))

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

                match staged with
                | Some file -> backups.RemoveFile(replacement.Name, file.Identity)
                | None -> ()
            | _ ->
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
