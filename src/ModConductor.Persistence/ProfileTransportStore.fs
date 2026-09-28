namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces

type ProfileSourceRequirement =
    { ModIndex: int
      ModName: string
      ArchiveName: string
      Sha256: string
      Length: int64
      ProviderGame: string option
      ProviderMod: int64 option
      ProviderFile: int64 option
      ProviderVersion: string option }

type ProfileTransportPreview =
    { Name: string
      Game: string
      Mods: int
      ModFiles: int
      SaveFiles: int
      SaveBytes: int64
      Sources: ProfileSourceRequirement list }

type ProfileTransportStore
    internal
    (
        database: StateDatabase,
        access: LibraryAccess,
        library: ModLibraryStore,
        installations: InstallationStore,
        artifacts: IArtifactLibrary,
        inspection: ModConductor.ArchiveInspection.Inspection,
        images: IProfileImages,
        profileData: IProfileGameData,
        directory: string
    ) =
    let writer = ProfileTransportWriter(database, access, artifacts, inspection, images, directory)
    let importMod = ProfileTransportImportMod(database, access, library, installations, artifacts, directory)

    let payloadLength (file: PortableFile) =
        match file.Content with
        | PortableContent.Payload(_, _, length)
        | PortableContent.Patch(_, _, _, length) -> length

    let modFiles (value: PortableMod) =
        let original =
            value.Base
            |> Option.map (fun source -> source.Selected |> List.map _.Destination |> Set.ofList)
            |> Option.defaultValue Set.empty
        let deleted = value.Deleted |> Set.ofList
        let changed = value.Files |> List.map _.Path |> Set.ofList
        let hidden = value.Hidden |> Set.ofList
        Set.difference (Set.union (Set.difference original deleted) changed) hidden
        |> Set.count

    let privateUsage (root: DataRoot option) (token: CancellationToken) =
        let rec count (folder: HeldDirectory) depth =
            if depth > 128 then
                raise (InvalidDataException "The private profile folder exceeds the depth limit.")
            folder.Names
            |> Seq.fold (fun (files, bytes) name ->
                token.ThrowIfCancellationRequested()
                match folder.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    use child = folder.Directory(name, Some entry.Identity)
                    let nestedFiles, nestedBytes = count child (depth + 1)
                    files + nestedFiles, bytes + nestedBytes
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    let stream, _ = folder.Read(name, Some entry.Identity)
                    use stream = stream
                    files + 1, bytes + stream.Length
                | _ -> raise (InvalidDataException "The private profile folder contains an unsupported entry.")) (0, 0L)
        match root with
        | Some root ->
            use folder = HeldDirectory.Open(root.Path, root.Identity)
            count folder 0
        | None -> 0, 0L

    let preview (profile: PortableProfile) =
        { Name = profile.Name
          Game = profile.Game
          Mods = profile.Mods |> List.filter (fun value -> value.Kind = "regular") |> List.length
          ModFiles =
            profile.Mods
            |> List.filter (fun value -> value.Kind = "regular")
            |> List.sumBy modFiles
          SaveFiles = profile.Saves.Length
          SaveBytes = profile.Saves |> List.sumBy payloadLength
          Sources =
            profile.Mods
            |> List.mapi (fun index value ->
                value.Base
                |> Option.map (fun baseSource ->
                    { ModIndex = index
                      ModName = value.Name
                      ArchiveName = baseSource.ArchiveName
                      Sha256 = baseSource.ArchiveSha256
                      Length = baseSource.ArchiveLength
                      ProviderGame = value.Source |> Option.map _.Game
                      ProviderMod = value.Source |> Option.map _.ModId
                      ProviderFile = value.Source |> Option.map _.FileId
                      ProviderVersion = value.Source |> Option.map _.FileVersion }))
            |> List.choose id }

    let validate (profile: PortableProfile) =
        let uniquePaths paths =
            let seen = Collections.Generic.HashSet<string>(
                TargetPolicy.comparer ModConductor.GameContexts.Skyrim.definition.TargetPolicy
            )
            let keys =
                paths
                |> List.map (fun parts ->
                    let path = LogicalPath.create parts
                               |> Result.defaultWith (fun _ -> raise (InvalidDataException "The profile has an invalid file path."))
                    if not (TargetPolicy.problems ModConductor.GameContexts.Skyrim.definition.TargetPolicy path).IsEmpty then
                        raise (InvalidDataException "The profile has a file path that the game cannot use.")
                    TargetPolicy.key ModConductor.GameContexts.Skyrim.definition.TargetPolicy path)
            keys |> List.forall seen.Add

        let validMod (value: PortableMod) =
            let current = value.Files |> List.map _.Path
            let selected = value.Base |> Option.map (fun item -> item.Selected |> List.map _.Destination) |> Option.defaultValue []
            uniquePaths current
            && uniquePaths value.Deleted
            && uniquePaths value.Hidden
            && (value.Base.IsSome || value.Deleted.IsEmpty)
            && (value.Deleted |> List.forall (fun path -> List.contains path selected))
            && (value.Base |> Option.forall (fun baseValue ->
                baseValue.ArchiveLength >= 0L
                && baseValue.ArchiveSha256.Length = 64
                && not baseValue.Selected.IsEmpty
                && uniquePaths selected
                && (baseValue.Selected |> List.forall (fun file -> file.ArchiveIndex >= 0))))

        if
            profile.Game <> GameId.value GameId.SkyrimSpecialEditionSteam
            || profile.Mods.Length > 100000
            || profile.Mods |> List.mapi (fun index modItem -> index = modItem.Priority) |> List.exists not
            || profile.Mods |> List.exists (validMod >> not)
            || not (uniquePaths (profile.Settings |> List.map _.Path))
            || not (uniquePaths (profile.Saves |> List.map _.Path))
            || profile.Mods |> List.exists (fun modItem -> modItem.Base.IsNone && (modItem.Files |> List.exists (fun file -> match file.Content with | PortableContent.Patch _ -> true | _ -> false)))
        then
            raise (InvalidDataException "The profile metadata is not supported.")

    let createProfile workspace target name game =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            let connection = database.Connection
            let existing =
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM profiles WHERE workspace_id=$workspace AND name=$name COLLATE MC_NAME"
                    [ "$workspace", box (string workspace); "$name", box name ]

            let source =
                match target with
                | Some target ->
                    use query =
                        Sqlite.command
                            connection
                            transaction
                            "SELECT game_id FROM game_contexts WHERE workspace_id=$workspace AND profile_id=$profile AND failure IS NULL"
                            [ "$workspace", box (string workspace); "$profile", box (string target) ]

                    match query.ExecuteScalar() with
                    | :? string as selected when selected = game -> Some target
                    | _ -> None
                | None -> None

            if existing <> 0L then
                Error "Use a new profile name in this workspace."
            elif source.IsNone then
                Error "Select a profile with the same local game installation in the target workspace."
            else
                let id = Guid.NewGuid()
                let current =
                    WorkspaceRows.find connection transaction workspace
                    |> Option.bind (fun row -> WorkspaceProfiles.summary connection transaction row.Receipt)

                match current with
                | None -> Error "The target workspace is unavailable."
                | Some current ->
                    match WorkspaceProfiles.editIn connection transaction workspace current.Revision (ProfileEdit.Create { Id = id; Name = name }) with
                    | Error _ -> Error "The target workspace changed. Try again."
                    | Ok _ ->
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO game_contexts(profile_id,workspace_id,game_id,id,path,revision,evidence,checked_owner,failure,proton_selection) SELECT $new,workspace_id,game_id,$binding,path,revision,evidence,checked_owner,failure,proton_selection FROM game_contexts WHERE profile_id=$source AND workspace_id=$workspace"
                            [ "$new", box (string id)
                              "$binding", box (string (Guid.NewGuid()))
                              "$source", box (string source.Value)
                              "$workspace", box (string workspace) ]

                        transaction.Commit()
                        Ok id)

    let selectMods workspace profile (mods: (PortableMod * Guid) list) =
        database.Enqueue(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            let existing = SelectionRows.all database.Connection transaction profile
            let imported =
                mods
                |> List.filter (fun (value, _) -> value.Kind <> "fnis-output")
            let importedIds = imported |> List.map snd |> Set.ofList
            let unrelated = existing |> List.filter (fun row -> not (Set.contains row.Id importedIds))

            Sqlite.execute
                database.Connection
                transaction
                "UPDATE profile_mods SET priority=-priority-1 WHERE profile_id=$profile"
                [ "$profile", box (string profile) ]

            for priority, (value, id) in imported |> List.indexed do
                match existing |> List.tryFind (fun row -> row.Id = id) with
                | Some _ ->
                    Sqlite.execute
                        database.Connection
                        transaction
                        "UPDATE profile_mods SET priority=$priority,enabled=$enabled WHERE profile_id=$profile AND mod_id=$mod"
                        [ "$profile", box (string profile)
                          "$mod", box (string id)
                          "$priority", box priority
                          "$enabled",
                          value.Enabled
                          |> Option.map (fun enabled -> box (if enabled then 1 else 0))
                          |> Option.defaultValue (box DBNull.Value) ]
                | None ->
                    Sqlite.execute
                        database.Connection
                        transaction
                        "INSERT INTO profile_mods(profile_id,mod_id,priority,enabled) VALUES($profile,$mod,$priority,$enabled)"
                        [ "$profile", box (string profile)
                          "$mod", box (string id)
                          "$priority", box priority
                          "$enabled",
                          value.Enabled
                          |> Option.map (fun enabled -> box (if enabled then 1 else 0))
                          |> Option.defaultValue (box DBNull.Value) ]

            for offset, row in unrelated |> List.indexed do
                Sqlite.execute
                    database.Connection
                    transaction
                    "UPDATE profile_mods SET priority=$priority,enabled=$enabled WHERE profile_id=$profile AND mod_id=$mod"
                    [ "$profile", box (string profile)
                      "$mod", box (string row.Id)
                      "$priority", box (imported.Length + offset)
                      "$enabled", row.Enabled |> Option.map (fun _ -> box 0) |> Option.defaultValue (box DBNull.Value) ]

            Sqlite.execute
                database.Connection
                transaction
                "UPDATE profiles SET selection_revision=selection_revision+1 WHERE id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ]

            transaction.Commit())

    let copyPrivate (bundle: ProfileTransportZip.Bundle) path (files: PortableFile list) =
        if files.Length > 0 && String.IsNullOrEmpty path then
            raise (InvalidDataException "The imported private folder is unavailable.")

        if not (String.IsNullOrEmpty path) then
            let selected =
                HostPath.create path
                |> Result.defaultWith (fun _ -> invalidOp "The private profile path is invalid.")
                |> RootSelection.select
                |> Result.defaultWith (fun _ -> invalidOp "The private profile path is unavailable.")
            let identity =
                match (RootSelection.facts selected).File with
                | Known value -> value
                | Unknown _ -> raise (InvalidDataException "The target private folder is unavailable.")

            use root = HeldDirectory.Open(RootSelection.path selected, identity)

            let rec clear (folder: HeldDirectory) depth =
                if depth > 128 then raise (InvalidDataException "The private folder exceeds the depth limit.")

                for name in folder.Names |> Seq.toList do
                    match folder.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.RegularFile -> folder.RemoveFile(name, entry.Identity)
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        do
                            use child = folder.Directory(name, Some entry.Identity)
                            clear child (depth + 1)

                        folder.RemoveDirectory(name, entry.Identity)
                    | _ -> raise (InvalidDataException "The private folder contains an unsupported entry.")

            let rec copy (folder: HeldDirectory) (path: string list) (staged: string) =
                match path with
                | [] -> raise (InvalidDataException "The private file path is empty.")
                | [ name ] ->
                    use source = File.OpenRead staged
                    let target, _ = folder.Create name
                    use target = target
                    source.CopyTo target
                    target.Flush(true)
                | name :: remaining ->
                    use child =
                        match folder.InspectEntry name with
                        | None -> folder.CreateDirectory name
                        | Some entry when entry.Kind = EntryKind.Directory -> folder.Directory(name, Some entry.Identity)
                        | _ -> raise (InvalidDataException "The private file path conflicts with a file.")

                    copy child remaining staged

            clear root 0

            for file in files do
                match file.Content with
                | PortableContent.Payload(memberName, sha, _) ->
                    let stage = Path.Combine(directory, "profile-transport", Guid.NewGuid().ToString("N") + ".private")
                    Directory.CreateDirectory(Path.GetDirectoryName stage) |> ignore

                    try
                        bundle.Copy(memberName, stage, Some sha)
                        copy root file.Path stage
                    finally
                        if File.Exists stage then File.Delete stage
                | PortableContent.Patch _ ->
                    raise (InvalidDataException "Private profile files must be complete payloads.")

    let restorePrivate workspace profile (value: PortableProfile) bundle token =
        task {
            let! state = profileData.Read(workspace, profile)
            let state =
                match state with
                | Ok value -> value
                | Error _ -> raise (InvalidDataException "The target game settings are unavailable.")

            let options =
                { Settings = value.SettingsEnabled || not value.Settings.IsEmpty
                  Saves = value.SavesEnabled || not value.Saves.IsEmpty }

            if options.Settings || options.Saves then
                let! edited =
                    profileData.Edit(
                        { Id = Guid.NewGuid()
                          Expected = state.Reference
                          Options = options
                          InitialSaves = InitialSaves.Empty
                          DisabledFiles = DisabledFiles.Keep },
                        ignore,
                        token
                    )

                match edited with
                | Ok result when result.Complete -> ()
                | _ -> raise (InvalidDataException "The target private settings could not be created.")

                let! current = profileData.Read(workspace, profile)
                let current =
                    match current with
                    | Ok current -> current
                    | _ -> raise (InvalidDataException "The target private settings are unavailable.")

                copyPrivate bundle current.SettingsPath value.Settings
                copyPrivate bundle current.SavesPath value.Saves

                if options <> { Settings = value.SettingsEnabled; Saves = value.SavesEnabled } then
                    let! changed =
                        profileData.Edit(
                            { Id = Guid.NewGuid()
                              Expected = current.Reference
                              Options = { Settings = value.SettingsEnabled; Saves = value.SavesEnabled }
                              InitialSaves = InitialSaves.Empty
                              DisabledFiles = DisabledFiles.Keep },
                            ignore,
                            token
                        )

                    match changed with
                    | Ok result when result.Complete -> ()
                    | _ -> raise (InvalidDataException "The imported settings state could not be restored.")

            if not value.PluginOrder.IsEmpty then
                do!
                    database.Enqueue(fun () ->
                        use transaction = database.Connection.BeginTransaction(deferred = false)
                        use query =
                            Sqlite.command
                                database.Connection
                                transaction
                                "SELECT p.context_id FROM profile_data_profiles p JOIN profile_data_contexts c ON c.id=p.context_id WHERE c.workspace_id=$workspace AND p.profile_id=$profile"
                                [ "$workspace", box (string workspace); "$profile", box (string profile) ]

                        let context = query.ExecuteScalar()

                        match context with
                        | :? string as id ->
                            let contextId = Guid.Parse id
                            let privateData = ProfileDataRows.profile database.Connection transaction contextId profile
                            let privateData = privateData.Value
                            let order: ModConductor.Bethesda.PluginOrder =
                                { ModConductor.Bethesda.PluginOrder.Document = Array.empty
                                  Entries =
                                    value.PluginOrder
                                    |> List.map (fun entry ->
                                        { ModConductor.Bethesda.PluginSetting.Name = entry.Name
                                          Enabled = entry.Enabled
                                          LockedIndex = entry.LockedIndex }) }

                            ProfileDataRows.saveProfile
                                database.Connection
                                transaction
                                contextId
                                { privateData with Revision = privateData.Revision + 1L; PluginOrder = Some order }
                        | _ -> raise (InvalidDataException "The imported plugin order has no private storage.")

                        transaction.Commit())
        }

    member _.Inspect(path: string) =
        use bundle = new ProfileTransportZip.Bundle(path)
        let profile = bundle.Profile
        validate profile
        preview profile

    member _.PreviewExport(workspace, profile, token: CancellationToken) =
        task {
            let! observed =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = true)
                    let result = ProfileTransportSnapshot.read database.Connection transaction workspace profile
                    transaction.Commit()
                    result)
            match observed with
            | Error problem -> return Error problem
            | Ok observed ->
                let mods =
                    observed.Mods
                    |> List.filter (fun value ->
                        value.Entry.Kind = ModKind.Regular
                        && value.Selection.Enabled = Some true)
                let saveFiles, saveBytes = privateUsage observed.Saves token
                return
                    Ok
                        { Name = observed.Name
                          Game = observed.Game
                          Mods = mods.Length
                          ModFiles =
                            mods
                            |> List.sumBy (fun value ->
                                value.Version
                                |> Option.map (fun version ->
                                    version.Entries
                                    |> List.filter (fun entry ->
                                        let path = LogicalPath.components entry.Path
                                        not (List.contains path value.Hidden))
                                    |> List.length)
                                |> Option.defaultValue 0)
                          SaveFiles = saveFiles
                          SaveBytes = saveBytes
                          Sources = [] }
        }

    member _.Export(workspace, profile, destination, includeSaves, token) =
        writer.Write(workspace, profile, destination, includeSaves, token)

    member _.Import(path, workspace, targetProfile: Guid option, name, artifactsByMod: Map<int, Guid>, token: CancellationToken) =
        task {
            try
                use bundle = new ProfileTransportZip.Bundle(path)
                let value = bundle.Profile
                validate value

                let! root = access.Root workspace
                if Result.isError root then
                    raise (InvalidDataException "The target workspace is unavailable.")

                for requirement in (preview value).Sources do
                    match artifactsByMod |> Map.tryFind requirement.ModIndex with
                    | None ->
                        raise (InvalidDataException("The exact archive for " + requirement.ModName + " is required."))
                    | Some artifact ->
                        let! found = artifacts.Read(workspace, artifact)

                        match found with
                        | Ok source when source.Sha256 = Some requirement.Sha256 && source.Length = Some requirement.Length -> ()
                        | _ ->
                            raise (InvalidDataException("The exact archive for " + requirement.ModName + " is unavailable."))

                let! created = createProfile workspace targetProfile name value.Game
                let profile =
                    match created with
                    | Ok profile -> profile
                    | Error problem -> raise (InvalidDataException problem)

                let imported = ResizeArray<PortableMod * Guid>()

                for index, modItem in value.Mods |> List.indexed do
                    token.ThrowIfCancellationRequested()
                    let artifact = artifactsByMod |> Map.tryFind index
                    let! modId, _ = importMod.Import(workspace, profile, modItem, artifact, bundle, token)
                    imported.Add(modItem, modId)

                do! selectMods workspace profile (imported |> Seq.toList)
                do! restorePrivate workspace profile value bundle token

                match value.Artwork with
                | Some file ->
                    let stage = Path.Combine(directory, "profile-transport", Guid.NewGuid().ToString("N") + ".image")
                    Directory.CreateDirectory(Path.GetDirectoryName stage) |> ignore

                    try
                        match file.Content with
                        | PortableContent.Payload(memberName, sha, _) -> bundle.Copy(memberName, stage, Some sha)
                        | _ -> raise (InvalidDataException "The custom image is invalid.")

                        let! saved = images.Set(workspace, profile, Some stage)
                        if Result.isError saved then raise (InvalidDataException "The custom image could not be saved.")
                    finally
                        if File.Exists stage then File.Delete stage
                | None -> ()

                return Ok profile
            with
            | :? InvalidDataException as error -> return Error error.Message
            | :? OperationCanceledException -> return Error "Profile import was cancelled. The new profile may be incomplete."
        }
