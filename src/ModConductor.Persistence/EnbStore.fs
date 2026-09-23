namespace ModConductor.Persistence

open System
open ModConductor.GameLaunching
open ModConductor.Nexus

type internal StoredEnbComponent =
    { Kind: string
      ModId: Guid
      VersionId: Guid
      Version: string
      Sha256: string
      NexusModId: int64 option
      NexusFileId: int64 option
      Source: string
      Terms: string
      CheckedAt: DateTimeOffset }

type internal StoredEnbPendingSource =
    { WorkspaceId: Guid
      ProfileId: Guid
      RuntimeArtifactId: Guid
      RuntimeSha256: string
      Kind: string
      NexusModId: int64
      File: NexusFile
      AccountId: string
      CheckedAt: DateTimeOffset }

type internal StoredEnbStatus =
    { WorkspaceId: Guid
      ProfileId: Guid
      Phase: string
      Status: string
      Detail: string
      RuntimeVersion: string
      PresetVersion: string
      ArtifactId: Guid option
      ArchiveSha256: string option
      CheckedAt: DateTimeOffset }

type internal StoredEnbConfigurationOperation =
    { ReceiptId: Guid
      WorkspaceId: Guid
      ProfileId: Guid
      GenerationId: Guid option
      Kind: string
      Phase: string
      Values: string
      ActionId: Guid option
      Detail: string }

type internal EnbStore(database: StateDatabase) =
    let optional (reader: Microsoft.Data.Sqlite.SqliteDataReader) index =
        if reader.IsDBNull index then
            None
        else
            Some(reader.GetString index)

    member _.SaveStatus(value: StoredEnbStatus) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO enb_profile_status VALUES($profile,$workspace,$phase,$status,$detail,$runtime,$preset,$artifact,$hash,$checked) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,phase=excluded.phase,status=excluded.status,detail=excluded.detail,runtime_version=excluded.runtime_version,preset_version=excluded.preset_version,artifact_id=excluded.artifact_id,archive_sha256=excluded.archive_sha256,checked_at=excluded.checked_at"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$phase", box value.Phase
                  "$status", box value.Status
                  "$detail", box value.Detail
                  "$runtime", box value.RuntimeVersion
                  "$preset", box value.PresetVersion
                  "$artifact",
                  value.ArtifactId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$hash",
                  value.ArchiveSha256 |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$checked", box (value.CheckedAt.ToString("O")) ])

    member _.ReadStatus(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT phase,status,detail,runtime_version,preset_version,artifact_id,archive_sha256,checked_at FROM enb_profile_status WHERE profile_id=$profile AND workspace_id=$workspace"
                    [ "$profile", box (string profile); "$workspace", box (string workspace) ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Phase = reader.GetString 0
                      Status = reader.GetString 1
                      Detail = reader.GetString 2
                      RuntimeVersion = reader.GetString 3
                      PresetVersion = reader.GetString 4
                      ArtifactId = optional reader 5 |> Option.map Guid.Parse
                      ArchiveSha256 = optional reader 6
                      CheckedAt = DateTimeOffset.Parse(reader.GetString 7) }
            else
                None)

    member _.SaveLaunchPlan
        (
            workspace,
            profile,
            generation,
            gameSha256,
            runtime,
            preset,
            runtimeHash,
            presetHash,
            companions,
            overrides,
            selectedRuntime,
            previousValues,
            configurationAction: Guid option
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT OR REPLACE INTO enb_launch_plans VALUES($profile,$workspace,$generation,$game,$runtime,$preset,$runtimeHash,$presetHash,$companions,$overrides,$selectedRuntime,$previous,$configuration)"
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$generation", box (string generation)
                  "$game", box gameSha256
                  "$runtime", box runtime
                  "$preset", preset |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$runtimeHash", box runtimeHash
                  "$presetHash", presetHash |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$companions", box companions
                  "$overrides", box overrides
                  "$selectedRuntime", box selectedRuntime
                  "$previous", box previousValues
                  "$configuration",
                  configurationAction
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value) ])

    member _.SaveGeneration(workspace, profile, generation, components: StoredEnbComponent list) =
        database.EnqueueInternal(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)

            for value in components do
                Sqlite.execute
                    database.Connection
                    transaction
                    "INSERT OR REPLACE INTO enb_generation_components VALUES($profile,$workspace,$generation,$kind,$mod,$versionId,$version,$hash,$nexusMod,$nexusFile,$source,$terms,$checked)"
                    [ "$profile", box (string profile)
                      "$workspace", box (string workspace)
                      "$generation", box (string generation)
                      "$kind", box value.Kind
                      "$mod", box (string value.ModId)
                      "$versionId", box (string value.VersionId)
                      "$version", box value.Version
                      "$hash", box value.Sha256
                      "$nexusMod",
                      value.NexusModId |> Option.map box |> Option.defaultValue (box DBNull.Value)
                      "$nexusFile",
                      value.NexusFileId |> Option.map box |> Option.defaultValue (box DBNull.Value)
                      "$source", box value.Source
                      "$terms", box value.Terms
                      "$checked", box (value.CheckedAt.ToString("O")) ]

            transaction.Commit())

    member _.StageSelection
        (receipt, workspace, profile, expectedRevision, values: (Guid * bool) list)
        =
        database.EnqueueInternal(fun () ->
            use transaction = database.Connection.BeginTransaction(deferred = false)

            for modId, enabled in values do
                Sqlite.execute
                    database.Connection
                    transaction
                    "INSERT INTO enb_selection_intents VALUES($receipt,$profile,$workspace,$revision,$mod,$enabled)"
                    [ "$receipt", box (string receipt)
                      "$profile", box (string profile)
                      "$workspace", box (string workspace)
                      "$revision", box expectedRevision
                      "$mod", box (string modId)
                      "$enabled", box enabled ]

            transaction.Commit())

    member _.RemoveSelection(receipt: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM enb_selection_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receipt) ])

    member _.Components(workspace: Guid, profile: Guid, generation: Guid option) =
        database.Enqueue(fun () ->
            match generation with
            | None -> []
            | Some generation ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT kind,mod_id,version_id,component_version,archive_sha256,nexus_mod,nexus_file,source_url,terms_url,checked_at FROM enb_generation_components WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation ORDER BY kind"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                use reader = query.ExecuteReader()

                [ while reader.Read() do
                      yield
                          { Kind = reader.GetString 0
                            ModId = Guid.Parse(reader.GetString 1)
                            VersionId = Guid.Parse(reader.GetString 2)
                            Version = reader.GetString 3
                            Sha256 = reader.GetString 4
                            NexusModId =
                              if reader.IsDBNull 5 then None else Some(reader.GetInt64 5)
                            NexusFileId =
                              if reader.IsDBNull 6 then None else Some(reader.GetInt64 6)
                            Source = reader.GetString 7
                            Terms = reader.GetString 8
                            CheckedAt = DateTimeOffset.Parse(reader.GetString 9) } ])

    member _.SavePending(value: StoredEnbPendingSource) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO enb_pending_sources VALUES($profile,$workspace,$runtime,$runtimeHash,$kind,$nexusMod,$nexusFile,$name,$version,$bytes,$account,$checked) ON CONFLICT(profile_id,kind) DO UPDATE SET runtime_artifact_id=excluded.runtime_artifact_id,runtime_sha256=excluded.runtime_sha256,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file,file_name=excluded.file_name,file_version=excluded.file_version,file_bytes=excluded.file_bytes,account_id=excluded.account_id,checked_at=excluded.checked_at"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$runtime", box (string value.RuntimeArtifactId)
                  "$runtimeHash", box value.RuntimeSha256
                  "$kind", box value.Kind
                  "$nexusMod", box value.NexusModId
                  "$nexusFile", box value.File.Id
                  "$name", box value.File.Name
                  "$version", box value.File.Version
                  "$bytes",
                  value.File.Bytes |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$account", box value.AccountId
                  "$checked", box (value.CheckedAt.ToString("O")) ])

    member _.Pending() =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT workspace_id,profile_id,runtime_artifact_id,runtime_sha256,kind,nexus_mod,nexus_file,file_name,file_version,file_bytes,account_id,checked_at FROM enb_pending_sources ORDER BY checked_at"
                    []

            use reader = query.ExecuteReader()

            [ while reader.Read() do
                  yield
                      { WorkspaceId = Guid.Parse(reader.GetString 0)
                        ProfileId = Guid.Parse(reader.GetString 1)
                        RuntimeArtifactId = Guid.Parse(reader.GetString 2)
                        RuntimeSha256 = reader.GetString 3
                        Kind = reader.GetString 4
                        NexusModId = reader.GetInt64 5
                        File =
                          { Id = reader.GetInt64 6
                            Name = reader.GetString 7
                            Version = reader.GetString 8
                            Category = "MAIN"
                            Description = ""
                            Bytes = if reader.IsDBNull 9 then None else Some(reader.GetInt64 9) }
                        AccountId = reader.GetString 10
                        CheckedAt = DateTimeOffset.Parse(reader.GetString 11) } ])

    member _.RemovePending(profile: Guid, kind: string option) =
        database.EnqueueInternal(fun () ->
            match kind with
            | Some kind ->
                Sqlite.execute
                    database.Connection
                    null
                    "DELETE FROM enb_pending_sources WHERE profile_id=$profile AND kind=$kind"
                    [ "$profile", box (string profile); "$kind", box kind ]
            | None ->
                Sqlite.execute
                    database.Connection
                    null
                    "DELETE FROM enb_pending_sources WHERE profile_id=$profile"
                    [ "$profile", box (string profile) ])

    member _.ConfigurationPlan(workspace: Guid, profile: Guid, generation: Guid option) =
        database.Enqueue(fun () ->
            match generation with
            | None -> None
            | Some generation ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT previous_values,configuration_action FROM enb_launch_plans WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                use reader = query.ExecuteReader()

                if reader.Read() then
                    Some(
                        reader.GetString 0,
                        if reader.IsDBNull 1 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 1))
                    )
                else
                    None)

    member _.StageConfiguration(value: StoredEnbConfigurationOperation) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO enb_configuration_operations VALUES($receipt,$workspace,$profile,$generation,$kind,$phase,$values,$action,$detail)"
                [ "$receipt", box (string value.ReceiptId)
                  "$workspace", box (string value.WorkspaceId)
                  "$profile", box (string value.ProfileId)
                  "$generation",
                  value.GenerationId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$kind", box value.Kind
                  "$phase", box value.Phase
                  "$values", box value.Values
                  "$action",
                  value.ActionId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$detail", box value.Detail ])

    member _.UpdateConfiguration(receipt: Guid, phase, action: Guid option, detail) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "UPDATE enb_configuration_operations SET phase=$phase,action_id=COALESCE($action,action_id),detail=$detail WHERE receipt_id=$receipt"
                [ "$receipt", box (string receipt)
                  "$phase", box phase
                  "$action",
                  action |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)
                  "$detail", box detail ])

    member _.ConfigurationOperation(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT receipt_id,generation_id,kind,phase,values_text,action_id,detail FROM enb_configuration_operations WHERE workspace_id=$workspace AND profile_id=$profile ORDER BY rowid DESC LIMIT 1"
                    [ "$workspace", box (string workspace); "$profile", box (string profile) ]

            use reader = query.ExecuteReader()

            if reader.Read() then
                Some
                    { ReceiptId = Guid.Parse(reader.GetString 0)
                      WorkspaceId = workspace
                      ProfileId = profile
                      GenerationId =
                        if reader.IsDBNull 1 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 1))
                      Kind = reader.GetString 2
                      Phase = reader.GetString 3
                      Values = reader.GetString 4
                      ActionId =
                        if reader.IsDBNull 5 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 5))
                      Detail = reader.GetString 6 }
            else
                None)

    member _.RemoveConfiguration(receipt: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM enb_configuration_operations WHERE receipt_id=$receipt"
                [ "$receipt", box (string receipt) ])

    member _.Owner(workspace: Guid, generation: Guid option) =
        database.Enqueue(fun () ->
            match generation with
            | None -> None
            | Some generation ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT profile_id FROM enb_launch_plans WHERE workspace_id=$workspace AND generation_id=$generation"
                        [ "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                match query.ExecuteScalar() with
                | :? string as value -> Some(Guid.Parse value)
                | _ -> None)

    interface IComponentLaunchConfigurationSelection with
        member _.Read(workspace, profile, activeGeneration) =
            database.Enqueue(fun () ->
                match activeGeneration with
                | None -> None
                | Some generation ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT game_sha256,dll_overrides FROM enb_launch_plans WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                            [ "$profile", box (string profile)
                              "$workspace", box (string workspace)
                              "$generation", box (string generation) ]

                    use reader = query.ExecuteReader()

                    if reader.Read() then
                        Some
                            { GenerationId = generation
                              GameSha256 = reader.GetString 0
                              Environment = [ "WINEDLLOVERRIDES", Some(reader.GetString 1) ] }
                    else
                        None)

module internal EnbRows =
    let completeReplacement connection transaction receiptId publish =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT profile_id,workspace_id,expected_revision,mod_id,enabled FROM enb_selection_intents WHERE receipt_id=$receipt ORDER BY mod_id"
                [ "$receipt", box (string receiptId) ]

        use reader = query.ExecuteReader()

        let rows =
            [ while reader.Read() do
                  yield
                      Guid.Parse(reader.GetString 0),
                      Guid.Parse(reader.GetString 1),
                      reader.GetInt64 2,
                      Guid.Parse(reader.GetString 3),
                      reader.GetBoolean 4 ]

        reader.Close()

        match rows with
        | [] -> ()
        | (profile, workspace, expected, _, _) :: _ when publish ->
            match SelectionRows.profile connection transaction profile with
            | Some(owner, revision) when owner = workspace && revision = expected -> ()
            | _ ->
                raise (
                    ModConductor.DeploymentRecovery.RecoveryException
                        ModConductor.DeploymentRecovery.RecoveryError.Stale
                )

            let desired =
                rows |> List.map (fun (_, _, _, id, enabled) -> id, enabled) |> Map.ofList

            let current = SelectionRows.all connection transaction profile

            let changed =
                current
                |> List.map (fun row ->
                    desired.TryFind row.Id
                    |> Option.map (fun enabled -> { row with Enabled = Some enabled })
                    |> Option.defaultValue row)

            if
                desired
                |> Map.forall (fun id _ -> current |> List.exists (fun row -> row.Id = id))
                |> not
            then
                raise (
                    ModConductor.DeploymentRecovery.RecoveryException
                        ModConductor.DeploymentRecovery.RecoveryError.Stale
                )

            SelectionRows.apply connection transaction profile changed
        | _ -> ()

        Sqlite.execute
            connection
            transaction
            "DELETE FROM enb_selection_intents WHERE receipt_id=$receipt"
            [ "$receipt", box (string receiptId) ]
