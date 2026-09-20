namespace ModConductor.Persistence

open System

type internal StoredSkyrimSetupIntent =
    { WorkspaceId: Guid
      ProfileId: Guid
      IncludeFnis: bool
      PlanToken: string
      Cancelled: bool
      Completed: bool
      Stage: string
      ContextRevision: int64
      ActionId: Guid option
      ArchivePath: string option
      CancelRequested: bool
      CancelDetail: string
      RequestedAt: DateTimeOffset }

type internal SkyrimSetupStore(database: StateDatabase) =
    member _.Read(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT workspace_id,include_fnis,plan_token,requested_at,cancelled,completed,stage,context_revision,action_id,archive_path,cancel_requested,cancel_detail FROM skyrim_setup_intents WHERE profile_id=$profile"
                    [ "$profile", box (string profile) ]

            use reader = command.ExecuteReader()

            if reader.Read() && Guid.Parse(reader.GetString 0) = workspace then
                Some
                    { WorkspaceId = workspace
                      ProfileId = profile
                      IncludeFnis = reader.GetInt64 1 = 1L
                      PlanToken = reader.GetString 2
                      Cancelled = reader.GetInt64 4 = 1L
                      Completed = reader.GetInt64 5 = 1L
                      Stage = reader.GetString 6
                      ContextRevision = reader.GetInt64 7
                      ActionId =
                        if reader.IsDBNull 8 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 8))
                      ArchivePath = if reader.IsDBNull 9 then None else Some(reader.GetString 9)
                      CancelRequested = reader.GetInt64 10 = 1L
                      CancelDetail = reader.GetString 11
                      RequestedAt = DateTimeOffset.Parse(reader.GetString 3) }
            else
                None)

    member _.Save(value: StoredSkyrimSetupIntent) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skyrim_setup_intents(profile_id,workspace_id,include_fnis,plan_token,requested_at,cancelled,completed,stage,context_revision,action_id,archive_path,cancel_requested,cancel_detail) VALUES($profile,$workspace,$fnis,$token,$requested,$cancelled,$completed,$stage,$context,$action,$archive,$cancelRequested,$cancelDetail) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,include_fnis=excluded.include_fnis,plan_token=excluded.plan_token,requested_at=excluded.requested_at,cancelled=excluded.cancelled,completed=excluded.completed,stage=excluded.stage,context_revision=excluded.context_revision,action_id=excluded.action_id,archive_path=excluded.archive_path,cancel_requested=excluded.cancel_requested,cancel_detail=excluded.cancel_detail"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$fnis", box (if value.IncludeFnis then 1 else 0)
                  "$token", box value.PlanToken
                  "$requested", box (value.RequestedAt.ToString("O"))
                  "$cancelled", box (if value.Cancelled then 1 else 0)
                  "$completed", box (if value.Completed then 1 else 0)
                  "$stage", box value.Stage
                  "$context", box value.ContextRevision
                  "$action",
                  value.ActionId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$archive",
                  value.ArchivePath |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$cancelRequested", box (if value.CancelRequested then 1 else 0)
                  "$cancelDetail", box value.CancelDetail ])

    member _.Remove(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM skyrim_setup_intents WHERE profile_id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ])
