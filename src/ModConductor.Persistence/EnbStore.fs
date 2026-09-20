namespace ModConductor.Persistence

open System
open ModConductor.GameLaunching

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
            previousValues
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO enb_launch_plans VALUES($profile,$workspace,$generation,$game,$runtime,$preset,$runtimeHash,$presetHash,$companions,$overrides,$selectedRuntime,$previous)"
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$generation", box (string generation)
                  "$game", box gameSha256
                  "$runtime", box runtime
                  "$preset", box preset
                  "$runtimeHash", box runtimeHash
                  "$presetHash", box presetHash
                  "$companions", box companions
                  "$overrides", box overrides
                  "$selectedRuntime", box selectedRuntime
                  "$previous", box previousValues ])

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
