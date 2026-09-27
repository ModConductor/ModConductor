namespace ModConductor.ProfileGameData

open System
open System.Threading
open ModConductor.Bethesda
open ModConductor.Platform

module internal ArchivePreparation =
    let private clean (root: DataRoot) token =
        use staging = HeldDirectory.Open(root.Path, root.Identity)

        for name in staging.Names |> Seq.toList do
            match DataFiles.observe staging name token with
            | Some file -> staging.RemoveFile(name, file.Identity)
            | None -> ()

    let private profileSettings (profile: PrivateProfileData) =
        match profile.Settings with
        | Some root -> Ok root
        | None ->
            Error(ProfileDataError.Unavailable "The profile settings folder is not initialized.")

    let private read (root: DataRoot) declared token =
        use held = HeldDirectory.Open(root.Path, root.Identity)

        let actual =
            DataLocations.iniNames held
            |> List.find (fun (name, _) -> name = declared)
            |> snd

        let file = DataFiles.observe held actual token
        actual, file, DataFiles.readIni held actual file token

    let private rewrite kind patch bytes =
        match kind with
        | ProfileDataActionKind.ApplyArchives request ->
            let canonical =
                match patch, bytes with
                | Some patch, Some bytes -> Ini.removeArchives patch bytes
                | Some _, None ->
                    Error(
                        ProfileDataError.Unavailable
                            "The active Skyrim archive list changed. Read it again before applying."
                    )
                | None, bytes -> Ok bytes

            canonical
            |> Result.bind (Ini.applyArchives request.Names)
            |> Result.map (fun (desired, next) -> Some desired, Some next)
        | ProfileDataActionKind.RestoreArchives ->
            match patch, bytes with
            | Some patch, Some bytes ->
                Ini.removeArchives patch bytes |> Result.map (fun restored -> restored, None)
            | Some _, None ->
                Error(
                    ProfileDataError.Unavailable
                        "The active Skyrim archive list changed. Read it again before restoration."
                )
            | None, bytes -> Ok(bytes, None)
        | _ -> invalidOp "Use the archive action owner."

    let prepare
        (repository: IProfileDataRepository)
        (archives: ArchivePolicySession)
        (initialContext: ProfileDataContext)
        (initialAction: ProfileDataActionRecord)
        (incoming: PrivateProfileData)
        (token: CancellationToken)
        =
        ProfileDataResultTask.resultTask {
            if initialAction.Prepared then
                return initialContext, initialAction
            else
                match initialAction.Kind with
                | ProfileDataActionKind.ApplyArchives request ->
                    let! retained = archives.Read request.SnapshotId

                    let! current =
                        match retained with
                        | Ok snapshot -> archives.Verify(snapshot, token)
                        | Error error -> System.Threading.Tasks.Task.FromResult(Error error)

                    do!
                        match current with
                        | Ok() -> Ok()
                        | _ -> Error ProfileDataError.Stale

                    if not incoming.Options.Settings || not incoming.SettingsInitialized then
                        return!
                            Error(
                                ProfileDataError.Unavailable
                                    "Enable and initialize profile settings before changing Skyrim archives."
                            )
                | ProfileDataActionKind.RestoreArchives -> ()
                | _ -> invalidOp "Use the archive action owner."

                let! stagesResult =
                    DataActionPreparation.stages repository initialContext initialAction

                let! context, action = stagesResult

                clean action.WorkspaceStage.Value token
                clean action.DocumentsStage.Value token

                let! profileRoot = profileSettings incoming
                let profileName, profileBefore, profileBytes = read profileRoot "Skyrim.ini" token

                match action.Kind with
                | ProfileDataActionKind.ApplyArchives request when
                    profileName <> request.IniName || profileBefore <> request.Ini
                    ->
                    return! Error ProfileDataError.Stale
                | _ -> ()

                let previousProfile = incoming.ArchiveList |> Option.map _.Profile

                let! desiredProfile, nextProfile = rewrite action.Kind previousProfile profileBytes

                use workspace =
                    HeldDirectory.Open(
                        action.WorkspaceStage.Value.Path,
                        action.WorkspaceStage.Value.Identity
                    )

                use documents =
                    HeldDirectory.Open(
                        action.DocumentsStage.Value.Path,
                        action.DocumentsStage.Value.Identity
                    )

                let stage (root: DataRoot) (held: HeldDirectory) name bytes =
                    bytes
                    |> Option.map (fun bytes ->
                        { Root = root
                          Name = name
                          File = DataFiles.stage held name bytes token })

                let effects = ResizeArray<ProfileDataFilesEffect>()

                if desiredProfile <> profileBytes then
                    effects.Add
                        { Target = profileRoot
                          Backups = action.WorkspaceStage.Value
                          Change =
                            { Name = profileName
                              Before = profileBefore
                              Replacement =
                                stage
                                    action.WorkspaceStage.Value
                                    workspace
                                    "apply-archive-profile.ini"
                                    desiredProfile
                              BackupName = "before-archive-profile.ini" } }

                let active =
                    context.Applied
                    |> Option.exists (fun value ->
                        value.ProfileId = incoming.ProfileId && value.Options.Settings)

                let mutable nextDocuments = None

                if active then
                    let globalName, globalBefore, globalBytes =
                        read context.Documents "Skyrim.ini" token

                    let previousDocuments =
                        incoming.ArchiveList
                        |> Option.bind (fun receipt ->
                            receipt.Documents |> Option.orElse (Some receipt.Profile))

                    let! desiredGlobal, patch = rewrite action.Kind previousDocuments globalBytes

                    nextDocuments <- patch

                    if desiredGlobal <> globalBytes then
                        effects.Add
                            { Target = context.Documents
                              Backups = action.DocumentsStage.Value
                              Change =
                                { Name = globalName
                                  Before = globalBefore
                                  Replacement =
                                    stage
                                        action.DocumentsStage.Value
                                        documents
                                        "apply-archive-global.ini"
                                        desiredGlobal
                                  BackupName = "before-archive-global.ini" } }

                let changed =
                    { incoming with
                        Revision = incoming.Revision + 1L
                        ArchiveList =
                            nextProfile
                            |> Option.map (fun profile ->
                                { Profile = profile
                                  Documents = nextDocuments }) }

                let prepared =
                    { action with
                        Prepared = true
                        ChangedProfile = Some changed
                        Files = List.ofSeq effects }

                let! saved = repository.SaveAction prepared
                do! saved
                return context, prepared
        }
