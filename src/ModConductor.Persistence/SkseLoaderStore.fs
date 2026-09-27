namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Deployment
open ModConductor.GameLaunching
open ModConductor.Nexus
open ModConductor.Skse

type internal StoredSkseSelection =
    { ArtifactId: Guid option
      WorkspaceId: Guid
      ProfileId: Guid option
      AccountId: string
      GameVersion: string
      GameSha256: string
      Selection: SkseSelection
      CheckedAt: DateTimeOffset }

type internal StoredSkseStatus =
    { WorkspaceId: Guid
      ProfileId: Guid
      Phase: string
      GameVersion: string
      ComponentVersion: string
      Status: string
      Detail: string
      NexusFileId: int64 option
      CheckedAt: DateTimeOffset }

type internal StoredSkseLoader =
    { Loader: ComponentLoader
      ModId: Guid
      VersionId: Guid
      ArchiveSha256: string
      NexusModId: int64
      NexusFileId: int64
      SourceCheckedAt: DateTimeOffset }

module internal SkseRows =
    let private acquisition =
        function
        | 0L -> SkseAcquisition.Direct
        | 1L -> SkseAcquisition.NexusPage
        | _ -> invalidOp "The saved SKSE acquisition route is invalid."

    let private acquisitionValue =
        function
        | SkseAcquisition.Direct -> 0
        | SkseAcquisition.NexusPage -> 1

    let private optionalInt64 (reader: SqliteDataReader) index =
        if reader.IsDBNull index then
            None
        else
            Some(reader.GetInt64 index)

    let readSelection (reader: SqliteDataReader) artifact profile =
        let file =
            { Id = reader.GetInt64 5
              Name = reader.GetString 6
              Version = reader.GetString 7
              Category = reader.GetString 8
              Description = reader.GetString 9
              Bytes = optionalInt64 reader 10 }

        { ArtifactId = artifact
          WorkspaceId = Guid.Parse(reader.GetString 0)
          ProfileId = profile
          AccountId = reader.GetString 1
          GameVersion = reader.GetString 2
          GameSha256 = reader.GetString 3
          Selection =
            { Release =
                { ModId = reader.GetInt64 4
                  File = file
                  ComponentVersion = Version.Parse(reader.GetString 11)
                  RuntimeVersion = Version.Parse(reader.GetString 12) }
              Acquisition = acquisition (reader.GetInt64 13) }
          CheckedAt =
            DateTimeOffset.Parse(reader.GetString 14, Globalization.CultureInfo.InvariantCulture) }

    let selectionParameters (value: StoredSkseSelection) =
        let release = value.Selection.Release

        [ "$workspace", box (string value.WorkspaceId)
          "$account", box value.AccountId
          "$gameVersion", box value.GameVersion
          "$gameHash", box value.GameSha256
          "$nexusMod", box release.ModId
          "$nexusFile", box release.File.Id
          "$name", box release.File.Name
          "$fileVersion", box release.File.Version
          "$category", box release.File.Category
          "$description", box release.File.Description
          "$bytes", release.File.Bytes |> Option.map box |> Option.defaultValue (box DBNull.Value)
          "$component", box (string release.ComponentVersion)
          "$runtime", box (string release.RuntimeVersion)
          "$acquisition", box (acquisitionValue value.Selection.Acquisition)
          "$checked", box (value.CheckedAt.ToString("O")) ]

    let readStatus connection transaction workspace profile =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT phase,game_version,component_version,status,detail,nexus_file,checked_at FROM skse_profile_status WHERE profile_id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            Some
                { WorkspaceId = workspace
                  ProfileId = profile
                  Phase = reader.GetString 0
                  GameVersion = reader.GetString 1
                  ComponentVersion = reader.GetString 2
                  Status = reader.GetString 3
                  Detail = reader.GetString 4
                  NexusFileId = if reader.IsDBNull 5 then None else Some(reader.GetInt64 5)
                  CheckedAt = DateTimeOffset.Parse(reader.GetString 6) }
        else None

    let writeStatus connection transaction (value: StoredSkseStatus) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO skse_profile_status(profile_id,workspace_id,phase,game_version,component_version,status,detail,nexus_file,checked_at) SELECT $profile,$workspace,$phase,$game,$component,$status,$detail,$file,$checked WHERE EXISTS(SELECT 1 FROM profiles WHERE id=$profile AND workspace_id=$workspace) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,phase=excluded.phase,game_version=excluded.game_version,component_version=excluded.component_version,status=excluded.status,detail=excluded.detail,nexus_file=excluded.nexus_file,checked_at=excluded.checked_at"
            [ "$profile", box (string value.ProfileId)
              "$workspace", box (string value.WorkspaceId)
              "$phase", box value.Phase
              "$game", box value.GameVersion
              "$component", box value.ComponentVersion
              "$status", box value.Status
              "$detail", box value.Detail
              "$file", value.NexusFileId |> Option.map box |> Option.defaultValue (box DBNull.Value)
              "$checked", box (value.CheckedAt.ToString("O")) ]

    let activeGeneration connection transaction owner workspace profile =
        GameContextRows.read connection transaction owner workspace profile
        |> Result.toOption
        |> Option.bind _.Binding
        |> Option.bind (fun binding ->
            let id =
                DeploymentContextId.create
                    workspace
                    profile
                    (DeploymentContextId.fingerprint binding.Evidence)

            DeploymentRows.context connection transaction id |> Option.bind _.Active)

    let completeReplacement connection transaction receiptId publish =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,profile_id,expected_selection_revision,previous_mod_id,mod_id,version_id,generation_id,executable,component_version,runtime_version,game_sha256,archive_sha256,nexus_mod,nexus_file,source_checked_at FROM skse_replacement_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]

        use reader = query.ExecuteReader()

        if reader.Read() && publish then
            let workspace = Guid.Parse(reader.GetString 0)
            let profile = Guid.Parse(reader.GetString 1)
            let expected = reader.GetInt64 2

            let previous =
                if reader.IsDBNull 3 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 3))

            let modId = Guid.Parse(reader.GetString 4)
            let versionId = Guid.Parse(reader.GetString 5)
            let generation = Guid.Parse(reader.GetString 6)
            let executable = reader.GetString 7
            let componentVersion = reader.GetString 8
            let runtime = reader.GetString 9
            let game = reader.GetString 10
            let archive = reader.GetString 11
            let nexusMod = reader.GetInt64 12
            let nexusFile = reader.GetInt64 13
            let checkedAt = reader.GetString 14
            reader.Close()

            match SelectionRows.profile connection transaction profile with
            | Some(owner, revision) when owner = workspace && revision = expected -> ()
            | _ ->
                raise (
                    ModConductor.DeploymentRecovery.RecoveryException
                        ModConductor.DeploymentRecovery.RecoveryError.Stale
                )

            let current = SelectionRows.all connection transaction profile

            if current |> List.exists (fun row -> row.Id = modId) |> not then
                raise (
                    ModConductor.DeploymentRecovery.RecoveryException
                        ModConductor.DeploymentRecovery.RecoveryError.Stale
                )

            let changed =
                current
                |> List.map (fun row ->
                    if row.Id = modId then
                        { row with Enabled = Some true }
                    elif previous = Some row.Id then
                        { row with Enabled = Some false }
                    else
                        row)

            SelectionRows.apply connection transaction profile changed

            Sqlite.execute
                connection
                transaction
                "INSERT OR IGNORE INTO skse_loader_selections VALUES($profile,$workspace,$mod,$version,$generation,$executable,$component,$runtime,$game,$archive,$nexusMod,$nexusFile,$checked)"
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$mod", box (string modId)
                  "$version", box (string versionId)
                  "$generation", box (string generation)
                  "$executable", box executable
                  "$component", box componentVersion
                  "$runtime", box runtime
                  "$game", box game
                  "$archive", box archive
                  "$nexusMod", box nexusMod
                  "$nexusFile", box nexusFile
                  "$checked", box checkedAt ]

            Sqlite.execute
                connection
                transaction
                "DELETE FROM skse_replacement_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]
        elif reader.HasRows then
            reader.Close()

            Sqlite.execute
                connection
                transaction
                "DELETE FROM skse_replacement_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]

type internal SkseLoaderStore(database: StateDatabase) =
    let selectionColumns =
        "workspace_id,account_id,game_version,game_sha256,nexus_mod,nexus_file,file_name,file_version,file_category,file_description,file_bytes,component_version,runtime_version,acquisition,checked_at"

    member _.ReusableVersion
        (workspace: Guid, profile: Guid, archiveSha256: string, release: SkseRelease)
        =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    """SELECT s.mod_id,s.version_id
                       FROM skse_loader_selections s
                       JOIN mods m ON m.id=s.mod_id AND m.workspace_id=$workspace AND m.current_version=s.version_id
                       JOIN mod_versions v ON v.id=s.version_id AND v.mod_id=m.id AND v.phase=3 AND v.busy=0
                       WHERE s.workspace_id=$workspace AND s.archive_sha256=$archive
                         AND s.component_version=$component AND s.runtime_version=$runtime
                         AND s.nexus_mod=$nexusMod AND s.nexus_file=$nexusFile
                       ORDER BY CASE WHEN s.profile_id=$profile THEN 0 ELSE 1 END,s.rowid DESC
                       LIMIT 1"""
                    [ "$workspace", box (string workspace)
                      "$profile", box (string profile)
                      "$archive", box archiveSha256
                      "$component", box (string release.ComponentVersion)
                      "$runtime", box (string release.RuntimeVersion)
                      "$nexusMod", box release.ModId
                      "$nexusFile", box release.File.Id ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some(Guid.Parse(reader.GetString 0), Guid.Parse(reader.GetString 1))
            else
                None)

    member _.ReadStored(workspace: Guid, profile: Guid, activeGeneration: Guid option) =
        database.Enqueue(fun () ->
            match activeGeneration with
            | None -> None
            | Some generation ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT executable,component_version,runtime_version,game_sha256,mod_id,version_id,archive_sha256,nexus_mod,nexus_file,source_checked_at FROM skse_loader_selections WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                use reader = query.ExecuteReader()

                if reader.Read() then
                    Some
                        { Loader =
                            { GenerationId = generation
                              Executable = reader.GetString 0
                              ComponentVersion = reader.GetString 1
                              RuntimeVersion = reader.GetString 2
                              GameSha256 = reader.GetString 3 }
                          ModId = Guid.Parse(reader.GetString 4)
                          VersionId = Guid.Parse(reader.GetString 5)
                          ArchiveSha256 = reader.GetString 6
                          NexusModId = reader.GetInt64 7
                          NexusFileId = reader.GetInt64 8
                          SourceCheckedAt = DateTimeOffset.Parse(reader.GetString 9) }
                else
                    None)

    interface IComponentLoaderSelection with
        member this.Read(workspace, profile, activeGeneration) =
            task {
                let! stored = this.ReadStored(workspace, profile, activeGeneration)
                return stored |> Option.map _.Loader
            }

    member _.SaveArtifactSelection(artifact: Artifact, value: StoredSkseSelection) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                ("INSERT INTO skse_artifact_selections(artifact_id,"
                 + selectionColumns
                 + ") VALUES($artifact,$workspace,$account,$gameVersion,$gameHash,$nexusMod,$nexusFile,$name,$fileVersion,$category,$description,$bytes,$component,$runtime,$acquisition,$checked) ON CONFLICT(artifact_id) DO UPDATE SET workspace_id=excluded.workspace_id,account_id=excluded.account_id,game_version=excluded.game_version,game_sha256=excluded.game_sha256,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file,file_name=excluded.file_name,file_version=excluded.file_version,file_category=excluded.file_category,file_description=excluded.file_description,file_bytes=excluded.file_bytes,component_version=excluded.component_version,runtime_version=excluded.runtime_version,acquisition=excluded.acquisition,checked_at=excluded.checked_at")
                (("$artifact", box (string artifact.Id)) :: SkseRows.selectionParameters value))

    member _.Cached(workspace: Guid, account: string, gameSha256: string) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    ("SELECT s."
                     + selectionColumns.Replace(",", ",s.")
                     + ",s.artifact_id FROM skse_artifact_selections s JOIN artifacts a ON a.id=s.artifact_id WHERE s.workspace_id=$workspace AND s.account_id=$account AND s.game_sha256=$game AND a.phase=2 ORDER BY s.checked_at DESC LIMIT 1")
                    [ "$workspace", box (string workspace)
                      "$account", box account
                      "$game", box gameSha256 ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some(SkseRows.readSelection reader (Some(Guid.Parse(reader.GetString 15))) None)
            else
                None)

    member _.SaveStatus(value: StoredSkseStatus) =
        database.EnqueueInternal(fun () ->
            SkseRows.writeStatus database.Connection null value)

    member _.ReadStatus(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            SkseRows.readStatus database.Connection null workspace profile)

    member _.SaveCheckedUpdateStatus
        (generation: Guid, version: Guid, observed: StoredSkseStatus option, value: StoredSkseStatus)
        =
        database.EnqueueInternal(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)
            let workspace, profile = value.WorkspaceId, value.ProfileId

            let active =
                SkseRows.activeGeneration
                    database.Connection
                    transaction
                    database.OwnerId
                    workspace
                    profile

            let installed =
                Sqlite.number
                    database.Connection
                    transaction
                    "SELECT count(*) FROM skse_loader_selections WHERE workspace_id=$workspace AND profile_id=$profile AND generation_id=$generation AND version_id=$version"
                    [ "$workspace", box (string workspace)
                      "$profile", box (string profile)
                      "$generation", box (string generation)
                      "$version", box (string version) ] = 1L

            let unchanged =
                SkseRows.readStatus database.Connection transaction workspace profile = observed

            let publish = active = Some generation && installed && unchanged

            if publish then
                SkseRows.writeStatus database.Connection transaction value

            transaction.Commit()
            publish)

    member _.SavePending(value: StoredSkseSelection) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                ("INSERT INTO skse_pending_handoffs(profile_id,"
                 + selectionColumns
                 + ") VALUES($profile,$workspace,$account,$gameVersion,$gameHash,$nexusMod,$nexusFile,$name,$fileVersion,$category,$description,$bytes,$component,$runtime,$acquisition,$checked) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,account_id=excluded.account_id,game_version=excluded.game_version,game_sha256=excluded.game_sha256,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file,file_name=excluded.file_name,file_version=excluded.file_version,file_category=excluded.file_category,file_description=excluded.file_description,file_bytes=excluded.file_bytes,component_version=excluded.component_version,runtime_version=excluded.runtime_version,acquisition=excluded.acquisition,checked_at=excluded.checked_at")
                (("$profile", box (string value.ProfileId.Value))
                 :: SkseRows.selectionParameters value))

    member _.Pending() =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    ("SELECT "
                     + selectionColumns
                     + ",profile_id FROM skse_pending_handoffs ORDER BY checked_at")
                    []

            use reader = query.ExecuteReader()

            [ while reader.Read() do
                  yield SkseRows.readSelection reader None (Some(Guid.Parse(reader.GetString 15))) ])

    member _.RemovePending(profile: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM skse_pending_handoffs WHERE profile_id=$profile"
                [ "$profile", box (string profile) ])

    member _.StageReplacement
        (
            receipt: Guid,
            expectedRevision: int64,
            previousMod: Guid option,
            value: StoredSkseLoader,
            workspace: Guid,
            profile: Guid
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skse_replacement_intents VALUES($receipt,$workspace,$profile,$revision,$previous,$mod,$version,$generation,$executable,$component,$runtime,$game,$archive,$nexusMod,$nexusFile,$checked)"
                [ "$receipt", box (string receipt)
                  "$workspace", box (string workspace)
                  "$profile", box (string profile)
                  "$revision", box expectedRevision
                  "$previous",
                  previousMod
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$mod", box (string value.ModId)
                  "$version", box (string value.VersionId)
                  "$generation", box (string value.Loader.GenerationId)
                  "$executable", box value.Loader.Executable
                  "$component", box value.Loader.ComponentVersion
                  "$runtime", box value.Loader.RuntimeVersion
                  "$game", box value.Loader.GameSha256
                  "$archive", box value.ArchiveSha256
                  "$nexusMod", box value.NexusModId
                  "$nexusFile", box value.NexusFileId
                  "$checked", box (value.SourceCheckedAt.ToString("O")) ])

    member _.RemoveReplacement(receipt: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM skse_replacement_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receipt) ])

    member _.Save
        (
            workspace,
            profile,
            modId,
            versionId,
            generation,
            executable,
            componentVersion,
            runtimeVersion,
            gameSha256,
            archiveSha256,
            nexusMod,
            nexusFile
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skse_loader_selections VALUES($profile,$workspace,$mod,$version,$generation,$executable,$component,$runtime,$game,$archive,$nexusMod,$nexusFile,$checked)"
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$mod", box (string modId)
                  "$version", box (string versionId)
                  "$generation", box (string generation)
                  "$executable", box executable
                  "$component", box componentVersion
                  "$runtime", box runtimeVersion
                  "$game", box gameSha256
                  "$archive", box archiveSha256
                  "$nexusMod", box nexusMod
                  "$nexusFile", box nexusFile
                  "$checked", box (DateTimeOffset.UtcNow.ToString("O")) ])
