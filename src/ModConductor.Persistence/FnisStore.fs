namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Fnis
open ModConductor.Nexus

type internal StoredFnisSelection =
    { ArtifactId: Guid option
      WorkspaceId: Guid
      ProfileId: Guid option
      AccountId: string
      Selection: FnisSelection
      CheckedAt: DateTimeOffset }

type internal StoredFnisStatus =
    { WorkspaceId: Guid
      ProfileId: Guid
      Phase: string
      ComponentVersion: string
      Status: string
      Detail: string
      NexusFileId: int64 option
      ArtifactId: Guid option
      CheckedAt: DateTimeOffset }

type internal StoredFnisGenerator =
    { GenerationId: Guid
      ModId: Guid
      VersionId: Guid
      ArtifactId: Guid
      FileName: string
      FileVersion: string
      Executable: string
      ComponentVersion: string
      ArchiveSha256: string
      Provider: string
      Source: string
      Terms: string
      NexusModId: int64
      NexusFileId: int64
      AcquiredAt: DateTimeOffset }

module internal FnisRows =
    let private acquisition =
        function
        | 0L -> FnisAcquisition.Direct
        | 1L -> FnisAcquisition.NexusPage
        | _ -> invalidOp "The saved FNIS acquisition route is invalid."

    let private acquisitionValue =
        function
        | FnisAcquisition.Direct -> 0
        | FnisAcquisition.NexusPage -> 1

    let private optionalInt64 (reader: SqliteDataReader) index =
        if reader.IsDBNull index then
            None
        else
            Some(reader.GetInt64 index)

    let readSelection (reader: SqliteDataReader) artifact profile =
        let file =
            { Id = reader.GetInt64 3
              Name = reader.GetString 4
              Version = reader.GetString 5
              Category = reader.GetString 6
              Description = reader.GetString 7
              Bytes = optionalInt64 reader 8 }

        { ArtifactId = artifact
          WorkspaceId = Guid.Parse(reader.GetString 0)
          ProfileId = profile
          AccountId = reader.GetString 1
          Selection =
            { Release =
                { ModId = reader.GetInt64 2
                  File = file
                  ComponentVersion = Version.Parse(reader.GetString 9) }
              Acquisition = acquisition (reader.GetInt64 10) }
          CheckedAt = DateTimeOffset.Parse(reader.GetString 13) }

    let selectionParameters (value: StoredFnisSelection) =
        let release = value.Selection.Release

        [ "$workspace", box (string value.WorkspaceId)
          "$account", box value.AccountId
          "$nexusMod", box release.ModId
          "$nexusFile", box release.File.Id
          "$name", box release.File.Name
          "$fileVersion", box release.File.Version
          "$category", box release.File.Category
          "$description", box release.File.Description
          "$bytes", release.File.Bytes |> Option.map box |> Option.defaultValue (box DBNull.Value)
          "$component", box (string release.ComponentVersion)
          "$acquisition", box (acquisitionValue value.Selection.Acquisition)
          "$source", box FnisCatalogue.Source
          "$terms", box FnisCatalogue.Terms
          "$checked", box (value.CheckedAt.ToString("O")) ]

    let completePublication connection transaction receiptId publish =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,profile_id,kind,expected_selection_revision,previous_mod_id,mod_id,version_id,artifact_id,file_name,file_version,generation_id,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at FROM fnis_publication_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            let workspace = Guid.Parse(reader.GetString 0)
            let profile = Guid.Parse(reader.GetString 1)
            let kind = reader.GetInt64 2
            let expected = reader.GetInt64 3

            let previous =
                if reader.IsDBNull 4 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 4))

            let target =
                if reader.IsDBNull 5 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 5))

            let generator =
                if kind = 0L then
                    Some(
                        Guid.Parse(reader.GetString 6),
                        Guid.Parse(reader.GetString 7),
                        reader.GetString 8,
                        reader.GetString 9,
                        Guid.Parse(reader.GetString 10),
                        reader.GetString 11,
                        reader.GetString 12,
                        reader.GetString 13,
                        reader.GetString 14,
                        reader.GetString 15,
                        reader.GetString 16,
                        reader.GetInt64 17,
                        reader.GetInt64 18,
                        reader.GetString 19
                    )
                else
                    None

            reader.Close()

            if publish then
                match SelectionRows.profile connection transaction profile with
                | Some(owner, revision) when owner = workspace && revision = expected -> ()
                | _ ->
                    raise (
                        ModConductor.DeploymentRecovery.RecoveryException
                            ModConductor.DeploymentRecovery.RecoveryError.Stale
                    )

                let current = SelectionRows.all connection transaction profile

                let changed =
                    current
                    |> List.map (fun row ->
                        if target = Some row.Id then
                            { row with Enabled = Some true }
                        elif previous = Some row.Id then
                            { row with Enabled = Some false }
                        else
                            row)

                if
                    target
                    |> Option.exists (fun id -> current |> List.exists (fun row -> row.Id = id))
                    |> not
                    && target.IsSome
                then
                    raise (
                        ModConductor.DeploymentRecovery.RecoveryException
                            ModConductor.DeploymentRecovery.RecoveryError.Stale
                    )

                SelectionRows.apply connection transaction profile changed

                match target, generator with
                | Some modId,
                  Some(versionId,
                       artifactId,
                       fileName,
                       fileVersion,
                       generation,
                       executable,
                       componentVersion,
                       archive,
                       provider,
                       source,
                       terms,
                       nexusMod,
                       nexusFile,
                       acquiredAt) ->
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT OR IGNORE INTO fnis_generators(profile_id,workspace_id,generation_id,mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at) VALUES($profile,$workspace,$generation,$mod,$version,$artifact,$fileName,$fileVersion,$executable,$component,$archive,$provider,$source,$terms,$nexusMod,$nexusFile,$acquired)"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation)
                          "$mod", box (string modId)
                          "$version", box (string versionId)
                          "$artifact", box (string artifactId)
                          "$fileName", box fileName
                          "$fileVersion", box fileVersion
                          "$executable", box executable
                          "$component", box componentVersion
                          "$archive", box archive
                          "$provider", box provider
                          "$source", box source
                          "$terms", box terms
                          "$nexusMod", box nexusMod
                          "$nexusFile", box nexusFile
                          "$acquired", box acquiredAt ]
                | _ -> ()

            Sqlite.execute
                connection
                transaction
                "DELETE FROM fnis_publication_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]

type internal FnisStore(database: StateDatabase) =
    let selectionColumns =
        "workspace_id,account_id,nexus_mod,nexus_file,file_name,file_version,file_category,file_description,file_bytes,component_version,acquisition,source,terms,checked_at"

    member _.ReadStored(workspace: Guid, profile: Guid, activeGeneration: Guid option) =
        database.Enqueue(fun () ->
            match activeGeneration with
            | None -> None
            | Some generation ->
                let readStored (query: Microsoft.Data.Sqlite.SqliteCommand) =
                    use reader = query.ExecuteReader()

                    if reader.Read() then
                        Some
                            { GenerationId = generation
                              ModId = Guid.Parse(reader.GetString 0)
                              VersionId = Guid.Parse(reader.GetString 1)
                              ArtifactId = Guid.Parse(reader.GetString 2)
                              FileName = reader.GetString 3
                              FileVersion = reader.GetString 4
                              Executable = reader.GetString 5
                              ComponentVersion = reader.GetString 6
                              ArchiveSha256 = reader.GetString 7
                              Provider = reader.GetString 8
                              Source = reader.GetString 9
                              Terms = reader.GetString 10
                              NexusModId = reader.GetInt64 11
                              NexusFileId = reader.GetInt64 12
                              AcquiredAt = DateTimeOffset.Parse(reader.GetString 13) }
                    else
                        None

                use exact =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at FROM fnis_generators WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                match readStored exact with
                | Some stored -> Some stored
                | None ->
                    use selected =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT g.mod_id,g.version_id,g.artifact_id,g.file_name,g.file_version,g.executable,g.component_version,g.archive_sha256,g.provider,g.source,g.terms,g.nexus_mod,g.nexus_file,g.acquired_at FROM fnis_generators g JOIN profile_mods p ON p.profile_id=g.profile_id AND p.mod_id=g.mod_id AND p.enabled=1 JOIN mods m ON m.id=g.mod_id AND m.current_version=g.version_id WHERE g.profile_id=$profile AND g.workspace_id=$workspace ORDER BY g.acquired_at DESC LIMIT 1"
                            [ "$profile", box (string profile)
                              "$workspace", box (string workspace) ]

                    readStored selected)

    member _.SaveArtifactSelection(artifact: Artifact, value: StoredFnisSelection) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                ("INSERT INTO fnis_artifact_selections(artifact_id,"
                 + selectionColumns
                 + ") VALUES($artifact,$workspace,$account,$nexusMod,$nexusFile,$name,$fileVersion,$category,$description,$bytes,$component,$acquisition,$source,$terms,$checked) ON CONFLICT(artifact_id) DO UPDATE SET workspace_id=excluded.workspace_id,account_id=excluded.account_id,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file,file_name=excluded.file_name,file_version=excluded.file_version,file_category=excluded.file_category,file_description=excluded.file_description,file_bytes=excluded.file_bytes,component_version=excluded.component_version,acquisition=excluded.acquisition,source=excluded.source,terms=excluded.terms,checked_at=excluded.checked_at")
                (("$artifact", box (string artifact.Id)) :: FnisRows.selectionParameters value))

    member _.Cached(workspace: Guid, account: string) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    ("SELECT s."
                     + selectionColumns.Replace(",", ",s.")
                     + ",s.artifact_id FROM fnis_artifact_selections s JOIN artifacts a ON a.id=s.artifact_id WHERE s.workspace_id=$workspace AND s.account_id=$account AND a.phase IN (2,3) ORDER BY s.checked_at DESC LIMIT 1")
                    [ "$workspace", box (string workspace); "$account", box account ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some(FnisRows.readSelection reader (Some(Guid.Parse(reader.GetString 14))) None)
            else
                None)

    member _.SelectionForArtifact(workspace: Guid, artifact: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    ("SELECT "
                     + selectionColumns
                     + " FROM fnis_artifact_selections WHERE workspace_id=$workspace AND artifact_id=$artifact")
                    [ "$workspace", box (string workspace); "$artifact", box (string artifact) ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some(FnisRows.readSelection reader (Some artifact) (Some profile))
            else
                None)

    member _.SaveStatus(value: StoredFnisStatus) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO fnis_profile_status(profile_id,workspace_id,phase,component_version,status,detail,nexus_file,artifact_id,checked_at) SELECT $profile,$workspace,$phase,$component,$status,$detail,$file,$artifact,$checked WHERE EXISTS(SELECT 1 FROM profiles WHERE id=$profile AND workspace_id=$workspace) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,phase=excluded.phase,component_version=excluded.component_version,status=excluded.status,detail=excluded.detail,nexus_file=excluded.nexus_file,artifact_id=excluded.artifact_id,checked_at=excluded.checked_at"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$phase", box value.Phase
                  "$component", box value.ComponentVersion
                  "$status", box value.Status
                  "$detail", box value.Detail
                  "$file",
                  value.NexusFileId |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$artifact",
                  value.ArtifactId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$checked", box (value.CheckedAt.ToString("O")) ])

    member _.ReadStatus(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT phase,component_version,status,detail,nexus_file,artifact_id,checked_at FROM fnis_profile_status WHERE profile_id=$profile AND workspace_id=$workspace"
                    [ "$profile", box (string profile); "$workspace", box (string workspace) ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = reader.GetString 0
                      ComponentVersion = reader.GetString 1
                      Status = reader.GetString 2
                      Detail = reader.GetString 3
                      NexusFileId = if reader.IsDBNull 4 then None else Some(reader.GetInt64 4)
                      ArtifactId =
                        if reader.IsDBNull 5 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 5))
                      CheckedAt = DateTimeOffset.Parse(reader.GetString 6) }
            else
                None)

    member _.SavePending(value: StoredFnisSelection) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                ("INSERT INTO fnis_pending_handoffs(profile_id,"
                 + selectionColumns
                 + ") VALUES($profile,$workspace,$account,$nexusMod,$nexusFile,$name,$fileVersion,$category,$description,$bytes,$component,$acquisition,$source,$terms,$checked) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,account_id=excluded.account_id,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file,file_name=excluded.file_name,file_version=excluded.file_version,file_category=excluded.file_category,file_description=excluded.file_description,file_bytes=excluded.file_bytes,component_version=excluded.component_version,acquisition=excluded.acquisition,source=excluded.source,terms=excluded.terms,checked_at=excluded.checked_at")
                (("$profile", box (string value.ProfileId.Value))
                 :: FnisRows.selectionParameters value))

    member _.Pending() =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    ("SELECT "
                     + selectionColumns
                     + ",profile_id FROM fnis_pending_handoffs ORDER BY checked_at")
                    []

            use reader = query.ExecuteReader()

            [ while reader.Read() do
                  yield FnisRows.readSelection reader None (Some(Guid.Parse(reader.GetString 14))) ])

    member _.RemovePending(profile: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM fnis_pending_handoffs WHERE profile_id=$profile"
                [ "$profile", box (string profile) ])

    member _.StageInstall
        (
            receipt: Guid,
            expectedRevision: int64,
            previousMod: Guid option,
            value: StoredFnisGenerator,
            workspace: Guid,
            profile: Guid
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO fnis_publication_intents(receipt_id,workspace_id,profile_id,kind,expected_selection_revision,previous_mod_id,mod_id,version_id,artifact_id,file_name,file_version,generation_id,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at) VALUES($receipt,$workspace,$profile,0,$revision,$previous,$mod,$version,$artifact,$fileName,$fileVersion,$generation,$executable,$component,$archive,$provider,$source,$terms,$nexusMod,$nexusFile,$acquired)"
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
                  "$artifact", box (string value.ArtifactId)
                  "$fileName", box value.FileName
                  "$fileVersion", box value.FileVersion
                  "$generation", box (string value.GenerationId)
                  "$executable", box value.Executable
                  "$component", box value.ComponentVersion
                  "$archive", box value.ArchiveSha256
                  "$provider", box value.Provider
                  "$source", box value.Source
                  "$terms", box value.Terms
                  "$nexusMod", box value.NexusModId
                  "$nexusFile", box value.NexusFileId
                  "$acquired", box (value.AcquiredAt.ToString("O")) ])

    member _.StageRemoval
        (
            receipt: Guid,
            expectedRevision: int64,
            previousMod: Guid,
            generation: Guid,
            workspace: Guid,
            profile: Guid
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO fnis_publication_intents(receipt_id,workspace_id,profile_id,kind,expected_selection_revision,previous_mod_id,generation_id) VALUES($receipt,$workspace,$profile,1,$revision,$previous,$generation)"
                [ "$receipt", box (string receipt)
                  "$workspace", box (string workspace)
                  "$profile", box (string profile)
                  "$revision", box expectedRevision
                  "$previous", box (string previousMod)
                  "$generation", box (string generation) ])

    member _.RemoveIntent(receipt: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM fnis_publication_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receipt) ])
