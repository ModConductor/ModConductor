namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.IO
open System.Threading.Tasks
open ModConductor.Migration
open ModConductor.ModLibrary
open ModConductor.ModOrganization
open ModConductor.Platform
open ModConductor.Workspaces

exception private MigrationTargetChanged

type internal MigrationStore
    (database: StateDatabase, roots: OwnedWorkspaceRootStore, commitCheckpoint: string -> unit) =
    let connection = database.Connection

    let workspacePath (workspace: WorkspaceRoot) name =
        Path.GetFullPath(Path.Combine(HostPath.value workspace.Path, name))

    let targetRoot (target: Target) =
        { WorkspaceRoot.Id = target.WorkspaceId
          Path = target.WorkspacePath
          Identity = target.WorkspaceIdentity
          Revision = 0L }

    let isOwnedPath (workspace: WorkspaceRoot) (prefix: string) (path: string) =
        let name = Path.GetFileName path

        name.StartsWith(prefix, StringComparison.Ordinal)
        && String.Equals(path, workspacePath workspace name, StringComparison.Ordinal)

    let removeDirectory (workspace: WorkspaceRoot) prefix path =
        if not (isOwnedPath workspace prefix path) then
            raise (IOException "The saved migration path is outside its workspace.")

        if Directory.Exists path then
            Directory.Delete(path, true)

    let cleanup workspace staged final =
        removeDirectory workspace ".mod-conductor-migration-" staged
        removeDirectory workspace ".mod-conductor-library-" final

    let recover () =
        let rows =
            database.Enqueue(fun () ->
                use command =
                    Sqlite.command
                        connection
                        null
                        "SELECT id,migration_staged_path,migration_final_path FROM operations WHERE migration_staged_path IS NOT NULL AND phase IN(1,4)"
                        []

                use reader = command.ExecuteReader()

                [ while reader.Read() do
                      yield reader.GetString 0, reader.GetString 1, reader.GetString 2 ])
            |> fun work -> work.GetAwaiter().GetResult()

        for id, staged, final in rows do
            let parent = Path.GetDirectoryName staged

            let workspaceId =
                database.Enqueue(fun () ->
                    use command =
                        Sqlite.command
                            connection
                            null
                            "SELECT id FROM workspace_roots WHERE path=$path"
                            [ "$path", box parent ]

                    match command.ExecuteScalar() with
                    | :? string as value -> Some(Guid.Parse value)
                    | _ -> None)
                |> fun work -> work.GetAwaiter().GetResult()

            let creation =
                match workspaceId with
                | Some workspace -> roots.Get(workspace).GetAwaiter().GetResult()
                | None -> None

            match creation with
            | Some creation when
                String.Equals(parent, Path.GetDirectoryName final, StringComparison.Ordinal)
                ->
                cleanup creation.Workspace staged final

                database.Enqueue(fun () ->
                    Sqlite.execute
                        connection
                        null
                        "DELETE FROM operations WHERE id=$id"
                        [ "$id", box id ])
                |> fun work -> work.GetAwaiter().GetResult()
            | Some _
            | None -> ()

    do recover ()

    let targetNotEmpty transaction workspace =
        Sqlite.number
            connection
            transaction
            """
            SELECT
              (SELECT count(*) FROM profiles WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM mods WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM artifacts WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM mod_libraries WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM categories WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM profile_mods s JOIN profiles p ON p.id=s.profile_id WHERE p.workspace_id=$workspace) +
              (SELECT count(*) FROM mod_categories c JOIN mods m ON m.id=c.mod_id WHERE m.workspace_id=$workspace) +
              (SELECT count(*) FROM hidden_mod_files WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM file_visibility_state WHERE workspace_id=$workspace) +
              (SELECT count(*) FROM workspaces WHERE id=$workspace AND selected_profile IS NOT NULL)
            """
            [ "$workspace", box (string workspace) ]
        <> 0L

    let activeOperation transaction workspace allowed =
        Sqlite.number
            connection
            transaction
            """
            SELECT
              (SELECT count(*) FROM operations WHERE phase=1 AND id<>$allowed) +
              (SELECT count(*) FROM archive_installations WHERE workspace_id=$workspace AND busy<>0) +
              (SELECT count(*) FROM mod_deletions WHERE workspace_id=$workspace AND busy<>0) +
              (SELECT count(*) FROM bundle_work WHERE workspace_id=$workspace AND busy<>0) +
              (SELECT count(*) FROM output_actions WHERE workspace_id=$workspace AND complete=0) +
              (SELECT count(*) FROM profile_data_actions a JOIN profile_data_contexts c ON c.id=a.context_id WHERE c.workspace_id=$workspace AND a.complete=0) +
              (SELECT count(*) FROM executable_runs WHERE workspace_id=$workspace AND phase IN(0,1,2))
            """
            [ "$allowed", box (allowed |> Option.defaultValue "")
              "$workspace", box (string workspace) ]
        <> 0L

    let targetFilesEmpty (workspace: WorkspaceRoot) allowed =
        use root = HeldDirectory.Open(workspace.Path, workspace.Identity)
        let accepted = Set.ofList (RootIdentityFile.name :: allowed)
        root.Names |> Seq.forall accepted.Contains

    let migrationBusy transaction (workspace: WorkspaceRoot) =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT migration_staged_path FROM operations WHERE migration_staged_path IS NOT NULL"
                []

        use reader = command.ExecuteReader()
        let root = HostPath.value workspace.Path
        let mutable busy = false

        while not busy && reader.Read() do
            busy <-
                String.Equals(
                    Path.GetDirectoryName(reader.GetString 0),
                    root,
                    StringComparison.Ordinal
                )

        busy

    let nullable value =
        value |> Option.map box |> Option.defaultValue (box DBNull.Value)

    let categoryId transaction workspace parent label =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT id FROM categories WHERE workspace_id=$workspace AND parent_id IS $parent AND label=$label AND missing=0"
                [ "$workspace", box (string workspace)
                  "$parent",
                  parent |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)
                  "$label", box label ]

        match command.ExecuteScalar() with
        | :? string as value -> Some(Guid.Parse value)
        | _ -> None

    let categories transaction workspace (values: ModConductor.Migration.Category list) =
        let mapped = Dictionary<int, Guid>()
        let mutable remaining = values
        let mutable revision = CategoryRows.revision connection transaction workspace
        let mutable changed = true

        while not remaining.IsEmpty && changed do
            changed <- false

            remaining <-
                remaining
                |> List.choose (fun value ->
                    let parent =
                        match value.ParentSourceId with
                        | None -> Some None
                        | Some source ->
                            match mapped.TryGetValue source with
                            | true, id -> Some(Some id)
                            | _ -> None

                    match parent with
                    | None -> Some value
                    | Some parentId ->
                        let id =
                            categoryId transaction workspace parentId value.Label
                            |> Option.defaultWith (fun () ->
                                let id = Guid.NewGuid()

                                match
                                    CategoryCommands.edit
                                        connection
                                        transaction
                                        workspace
                                        revision
                                        (CategoryEdit.Create(id, parentId, value.Label))
                                with
                                | Ok next ->
                                    revision <- next
                                    id
                                | Error _ ->
                                    raise (
                                        InvalidDataException "The migrated category is invalid."
                                    )

                            )

                        mapped.Add(value.SourceId, id)
                        changed <- true
                        None)

        if not remaining.IsEmpty then
            raise (InvalidDataException "The migrated categories contain a parent cycle.")

        mapped

    let complete (value: Commit) =
        use transaction = connection.BeginTransaction(deferred = false)
        let target = value.Target
        let workspace = target.WorkspaceId
        let targetWorkspace = targetRoot target

        let operation =
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM operations WHERE id=$id AND owner=$owner AND phase=1 AND migration_staged_path=$staged AND migration_final_path=$final"
                [ "$id", box (target.ActionId.ToString("N"))
                  "$owner", box database.OwnerId
                  "$staged", box (workspacePath targetWorkspace target.StagedName)
                  "$final", box (workspacePath targetWorkspace target.FinalName) ]

        let current = WorkspaceRows.find connection transaction workspace

        if operation <> 1L || current.IsNone then
            Error Error.Busy
        elif current.Value.Receipt.Phase <> RootCreationPhase.Complete then
            Error(Error.Unavailable "The workspace folder is not ready.")
        elif activeOperation transaction workspace (Some(target.ActionId.ToString("N"))) then
            Error Error.Busy
        elif targetNotEmpty transaction workspace then
            Error Error.TargetNotEmpty
        elif not (targetFilesEmpty targetWorkspace [ target.FinalName ]) then
            Error Error.TargetNotEmpty
        else
            let summary =
                WorkspaceProfiles.summary connection transaction current.Value.Receipt
                |> Option.defaultWith (fun () ->
                    raise (InvalidDataException "The workspace state is missing."))

            if summary.Revision <> target.ExpectedRevision then
                Error Error.TargetNotEmpty
            else
                let mutable revision = summary.Revision

                for profile in value.Profiles do
                    match
                        WorkspaceProfiles.editIn
                            connection
                            transaction
                            workspace
                            revision
                            (ProfileEdit.Create { Id = profile.Id; Name = profile.Name })
                    with
                    | Ok change -> revision <- change.Workspace.Revision
                    | Error _ -> raise (InvalidDataException "A migrated profile is invalid.")

                let mappedCategories = categories transaction workspace value.Categories

                Sqlite.execute
                    connection
                    transaction
                    "INSERT INTO mod_libraries(workspace_id,directory,owner,phase,identity) VALUES($workspace,$directory,$owner,2,$identity)"
                    [ "$workspace", box (string workspace)
                      "$directory", box target.FinalName
                      "$owner", box database.OwnerId
                      "$identity", box (LibraryEncoding.identity value.LibraryIdentity) ]

                for item in value.Mods do
                    let references =
                        item.CategorySourceIds
                        |> List.map (fun source ->
                            match mappedCategories.TryGetValue source with
                            | true, id ->
                                let category =
                                    CategoryRows.find connection transaction id |> Option.get

                                { CategoryReference.Id = id
                                  Label = category.Label
                                  Missing = false }
                            | _ -> raise (InvalidDataException "A migrated category is missing."))

                    let metadata =
                        { item.Metadata with
                            Categories = references }

                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO mods(id,workspace_id,kind,name,notes,comment,version_text,source_text,revision,source_path,source_identity,current_version,status) VALUES($id,$workspace,$kind,$name,$notes,$comment,$version,$source,0,NULL,NULL,NULL,1)"
                        (LibraryRows.metadataParameters metadata
                         @ [ "$id", box (string item.Id)
                             "$workspace", box (string workspace)
                             "$kind", box (LibraryEncoding.kind item.Kind) ])

                    CategoryRows.saveReferences connection transaction item.Id references

                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO mod_versions(id,mod_id,expected_revision,owner,phase,busy,cancelled) VALUES($version,$mod,0,$owner,3,0,0)"
                        [ "$version", box (string item.VersionId)
                          "$mod", box (string item.Id)
                          "$owner", box database.OwnerId ]

                    for file in item.Files do
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO mod_payloads(id,workspace_id,publication_id,identity,length,digest) VALUES($id,$workspace,$version,$identity,$length,$digest)"
                            [ "$id", box (string file.Id)
                              "$workspace", box (string workspace)
                              "$version", box (string item.VersionId)
                              "$identity", box (LibraryEncoding.identity file.Identity)
                              "$length", box file.Length
                              "$digest", box file.Sha256 ]

                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO mod_manifest(version_id,path,payload_id) VALUES($version,$path,$payload)"
                            [ "$version", box (string item.VersionId)
                              "$path", box (LibraryEncoding.path file.Path)
                              "$payload", box (string file.Id) ]

                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE mods SET current_version=$version WHERE id=$id"
                        [ "$version", box (string item.VersionId); "$id", box (string item.Id) ]

                    SelectionRows.registered connection transaction workspace item.Id item.Kind

                for profile in value.Profiles do
                    SelectionRows.apply connection transaction profile.Id profile.Mods

                let selected =
                    WorkspaceProfiles.summary connection transaction current.Value.Receipt
                    |> Option.bind _.SelectedProfile
                    |> Option.map _.Id

                if selected <> Some value.SelectedProfile then
                    match
                        WorkspaceProfiles.editIn
                            connection
                            transaction
                            workspace
                            revision
                            (ProfileEdit.Select value.SelectedProfile)
                    with
                    | Ok change -> revision <- change.Workspace.Revision
                    | Error _ ->
                        raise (InvalidDataException "The selected migrated profile is invalid.")

                let versionByMod = value.Mods |> Seq.map (fun item -> item.Id, item) |> dict
                let libraryPath = workspacePath targetWorkspace target.FinalName

                for artifact in value.Artifacts do
                    let phase = if artifact.Partial then 0 else 2
                    let path = Path.Combine(libraryPath, artifact.FileName)

                    Sqlite.execute
                        connection
                        transaction
                        "INSERT INTO artifacts(id,workspace_id,revision,original_name,original_path,path,storage,phase,owner,busy,length,sha256,source_identity,stored_identity,problem) VALUES($id,$workspace,0,$name,$original,$path,1,$phase,$owner,0,$length,$sha,NULL,$identity,NULL)"
                        [ "$id", box (string artifact.Id)
                          "$workspace", box (string workspace)
                          "$name", box artifact.OriginalName
                          "$original", box artifact.OriginalPath
                          "$path", box path
                          "$phase", box phase
                          "$owner", box database.OwnerId
                          "$length", box artifact.File.Length
                          "$sha", box artifact.File.Sha256
                          "$identity", box (LibraryEncoding.identity artifact.File.Identity) ]

                    if not artifact.Sources.IsEmpty then
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO artifact_downloads(artifact_id,sources,state,bytes,total,source_index,attempt,restart_required,checksum_matched) VALUES($id,$sources,$state,$bytes,$total,0,0,0,$matched)"
                            [ "$id", box (string artifact.Id)
                              "$sources", box (String.concat "\n" artifact.Sources)
                              "$state", box (if artifact.Partial then 3 else 5)
                              "$bytes", box artifact.File.Length
                              "$total",
                              if artifact.Partial then
                                  box DBNull.Value
                              else
                                  box artifact.File.Length
                              "$matched", box (not artifact.Partial) ]

                    artifact.InstalledMod
                    |> Option.iter (fun modId ->
                        let item = versionByMod[modId]

                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO artifact_links(artifact_id,mod_id,version_id,mod_name,version_label,installed) VALUES($artifact,$mod,$version,$name,$label,1)"
                            [ "$artifact", box (string artifact.Id)
                              "$mod", box (string item.Id)
                              "$version", box (string item.VersionId)
                              "$name", box item.Metadata.Name
                              "$label", box item.Metadata.Version ])

                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM operations WHERE id=$id AND owner=$owner"
                    [ "$id", box (target.ActionId.ToString("N")); "$owner", box database.OwnerId ]

                if not (targetFilesEmpty targetWorkspace [ target.FinalName ]) then
                    raise MigrationTargetChanged

                commitCheckpoint "before-commit"
                transaction.Commit()
                commitCheckpoint "after-commit"

                Ok
                    { WorkspaceId = workspace
                      Profiles = value.Profiles.Length
                      Mods = value.Mods.Length
                      Artifacts = value.Artifacts.Length }

    interface IStore with
        member _.Begin(workspace, action, stagedName, finalName) =
            task {
                let! root = roots.Validate workspace

                match root with
                | Error WorkspaceFailure.Busy -> return Error Error.Busy
                | Error _ -> return Error(Error.Unavailable "The workspace folder is not ready.")
                | Ok creation when creation.Phase <> RootCreationPhase.Complete ->
                    return Error(Error.Unavailable "The workspace folder is not ready.")
                | Ok creation ->
                    return!
                        database.Enqueue(fun () ->
                            use transaction = connection.BeginTransaction(deferred = false)

                            let summary = WorkspaceProfiles.summary connection transaction creation

                            let result =
                                match summary with
                                | None ->
                                    Error(Error.Unavailable "The workspace state is missing.")
                                | Some _ when targetNotEmpty transaction workspace ->
                                    Error Error.TargetNotEmpty
                                | Some _ when not (targetFilesEmpty creation.Workspace []) ->
                                    Error Error.TargetNotEmpty
                                | Some _ when activeOperation transaction workspace None ->
                                    Error Error.Busy
                                | Some current when migrationBusy transaction creation.Workspace ->
                                    Error Error.Busy
                                | Some current ->
                                    let staged = workspacePath creation.Workspace stagedName
                                    let final = workspacePath creation.Workspace finalName

                                    Sqlite.execute
                                        connection
                                        transaction
                                        "INSERT INTO operations(id,owner,expected_revision,count,phase,progress,result_revision,last_cursor,migration_staged_path,migration_final_path) VALUES($id,$owner,$revision,0,1,0,0,0,$staged,$final)"
                                        [ "$id", box (action.ToString("N"))
                                          "$owner", box database.OwnerId
                                          "$revision", box current.Revision
                                          "$staged", box staged
                                          "$final", box final ]

                                    Ok
                                        { ActionId = action
                                          WorkspaceId = workspace
                                          WorkspacePath = creation.Workspace.Path
                                          WorkspaceIdentity = creation.Workspace.Identity
                                          ExpectedRevision = current.Revision
                                          StagedName = stagedName
                                          FinalName = finalName }

                            transaction.Commit()
                            result)
            }

        member _.Ready(value) =
            task {
                try
                    return!
                        database.Enqueue(fun () ->
                            use transaction = connection.BeginTransaction(deferred = false)
                            let workspace = targetRoot value

                            let operation =
                                Sqlite.number
                                    connection
                                    transaction
                                    "SELECT count(*) FROM operations WHERE id=$id AND owner=$owner AND phase=1 AND migration_staged_path=$staged AND migration_final_path=$final"
                                    [ "$id", box (value.ActionId.ToString("N"))
                                      "$owner", box database.OwnerId
                                      "$staged", box (workspacePath workspace value.StagedName)
                                      "$final", box (workspacePath workspace value.FinalName) ]

                            let result =
                                match
                                    WorkspaceRows.find connection transaction value.WorkspaceId
                                with
                                | None ->
                                    Error(Error.Unavailable "The workspace state is missing.")
                                | Some current when
                                    current.Receipt.Phase <> RootCreationPhase.Complete
                                    ->
                                    Error(Error.Unavailable "The workspace folder is not ready.")
                                | Some _ when operation <> 1L -> Error Error.Busy
                                | Some _ when
                                    activeOperation
                                        transaction
                                        value.WorkspaceId
                                        (Some(value.ActionId.ToString("N")))
                                    ->
                                    Error Error.Busy
                                | Some _ when targetNotEmpty transaction value.WorkspaceId ->
                                    Error Error.TargetNotEmpty
                                | Some current when
                                    let summary =
                                        WorkspaceProfiles.summary
                                            connection
                                            transaction
                                            current.Receipt

                                    summary
                                    |> Option.forall (fun state ->
                                        state.Revision <> value.ExpectedRevision)
                                    ->
                                    Error Error.TargetNotEmpty
                                | Some _ when
                                    not (
                                        targetFilesEmpty
                                            workspace
                                            [ value.StagedName; value.FinalName ]
                                    )
                                    ->
                                    Error Error.TargetNotEmpty
                                | Some _ -> Ok()

                            transaction.Commit()
                            result)
                with
                | :? IOException -> return Error(Error.Unavailable "The workspace folder changed.")
                | :? UnauthorizedAccessException ->
                    return Error(Error.Unavailable "The workspace folder is unavailable.")
            }

        member _.Complete(value) =
            task {
                try
                    use root =
                        HeldDirectory.Open(
                            value.Target.WorkspacePath,
                            value.Target.WorkspaceIdentity
                        )

                    use final = root.Directory(value.Target.FinalName, Some value.LibraryIdentity)
                    return! database.Enqueue(fun () -> complete value)
                with
                | :? IOException ->
                    return
                        Error(
                            Error.Unavailable "The copied files changed before migration finished."
                        )
                | :? UnauthorizedAccessException ->
                    return Error(Error.Unavailable "The copied files are unavailable.")
                | :? InvalidDataException as error ->
                    return Error(Error.InvalidSource error.Message)
                | MigrationTargetChanged -> return Error Error.TargetNotEmpty
            }

        member _.Abandon(value) =
            task {
                let workspace = targetRoot value
                let staged = workspacePath workspace value.StagedName
                let final = workspacePath workspace value.FinalName
                cleanup workspace staged final

                do!
                    database.Enqueue(fun () ->
                        Sqlite.execute
                            connection
                            null
                            "DELETE FROM operations WHERE id=$id AND owner=$owner"
                            [ "$id", box (value.ActionId.ToString("N"))
                              "$owner", box database.OwnerId ])
            }
