namespace ModConductor.Persistence

open System

type internal StoredSkyrimSetupIntent =
    { WorkspaceId: Guid
      ProfileId: Guid
      IncludeFnis: bool
      PlanToken: string
      RequestedAt: DateTimeOffset }

type internal SkyrimSetupStore(database: StateDatabase) =
    member _.Read(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT workspace_id,include_fnis,plan_token,requested_at FROM skyrim_setup_intents WHERE profile_id=$profile"
                    [ "$profile", box (string profile) ]

            use reader = command.ExecuteReader()

            if reader.Read() && Guid.Parse(reader.GetString 0) = workspace then
                Some
                    { WorkspaceId = workspace
                      ProfileId = profile
                      IncludeFnis = reader.GetInt64 1 = 1L
                      PlanToken = reader.GetString 2
                      RequestedAt = DateTimeOffset.Parse(reader.GetString 3) }
            else
                None)

    member _.Save(value: StoredSkyrimSetupIntent) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skyrim_setup_intents(profile_id,workspace_id,include_fnis,plan_token,requested_at) VALUES($profile,$workspace,$fnis,$token,$requested) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,include_fnis=excluded.include_fnis,plan_token=excluded.plan_token,requested_at=excluded.requested_at"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$fnis", box (if value.IncludeFnis then 1 else 0)
                  "$token", box value.PlanToken
                  "$requested", box (value.RequestedAt.ToString("O")) ])

    member _.Remove(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM skyrim_setup_intents WHERE profile_id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ])
