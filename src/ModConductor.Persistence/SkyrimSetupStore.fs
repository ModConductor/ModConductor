namespace ModConductor.Persistence

open System

[<RequireQualifiedAccess>]
type internal SetupAction =
    | Unchanged = 0
    | Install = 1
    | Remove = 2
    | Update = 3

type internal SetupSelection =
    { Skse: SetupAction
      Enb: SetupAction
      Fnis: SetupAction
      EnbArchive: string option }

module internal SetupSelection =
    let none =
        { Skse = SetupAction.Unchanged
          Enb = SetupAction.Unchanged
          Fnis = SetupAction.Unchanged
          EnbArchive = None }

    let hasChange value =
        value.Skse <> SetupAction.Unchanged
        || value.Enb <> SetupAction.Unchanged
        || value.Fnis <> SetupAction.Unchanged

type internal StoredSkyrimSetupIntent =
    { WorkspaceId: Guid
      ProfileId: Guid
      Selection: SetupSelection
      Cancelled: bool
      Completed: bool
      Stage: string
      ActionId: Guid option
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
                    "SELECT workspace_id,skse_action,enb_action,fnis_action,requested_at,cancelled,completed,stage,action_id,enb_archive_path,cancel_requested,cancel_detail FROM skyrim_setup_intents WHERE profile_id=$profile"
                    [ "$profile", box (string profile) ]

            use reader = command.ExecuteReader()

            if reader.Read() && Guid.Parse(reader.GetString 0) = workspace then
                Some
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Selection =
                        { Skse = enum<SetupAction> (int (reader.GetInt64 1))
                          Enb = enum<SetupAction> (int (reader.GetInt64 2))
                          Fnis = enum<SetupAction> (int (reader.GetInt64 3))
                          EnbArchive = if reader.IsDBNull 9 then None else Some(reader.GetString 9) }
                      Cancelled = reader.GetInt64 5 = 1L
                      Completed = reader.GetInt64 6 = 1L
                      Stage = reader.GetString 7
                      ActionId =
                        if reader.IsDBNull 8 then
                            None
                        else
                            Some(Guid.Parse(reader.GetString 8))
                      CancelRequested = reader.GetInt64 10 = 1L
                      CancelDetail = reader.GetString 11
                      RequestedAt = DateTimeOffset.Parse(reader.GetString 4) }
            else
                None)

    member _.Save(value: StoredSkyrimSetupIntent) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skyrim_setup_intents(profile_id,workspace_id,skse_action,enb_action,fnis_action,requested_at,cancelled,completed,stage,action_id,enb_archive_path,cancel_requested,cancel_detail) VALUES($profile,$workspace,$skse,$enb,$fnis,$requested,$cancelled,$completed,$stage,$action,$archive,$cancelRequested,$cancelDetail) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,skse_action=excluded.skse_action,enb_action=excluded.enb_action,fnis_action=excluded.fnis_action,requested_at=excluded.requested_at,cancelled=excluded.cancelled,completed=excluded.completed,stage=excluded.stage,action_id=excluded.action_id,enb_archive_path=excluded.enb_archive_path,cancel_requested=excluded.cancel_requested,cancel_detail=excluded.cancel_detail"
                [ "$profile", box (string value.ProfileId)
                  "$workspace", box (string value.WorkspaceId)
                  "$skse", box (int value.Selection.Skse)
                  "$enb", box (int value.Selection.Enb)
                  "$fnis", box (int value.Selection.Fnis)
                  "$requested", box (value.RequestedAt.ToString("O"))
                  "$cancelled", box (if value.Cancelled then 1 else 0)
                  "$completed", box (if value.Completed then 1 else 0)
                  "$stage", box value.Stage
                  "$action",
                  value.ActionId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$archive",
                  value.Selection.EnbArchive |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$cancelRequested", box (if value.CancelRequested then 1 else 0)
                  "$cancelDetail", box value.CancelDetail ])

    member _.Remove(workspace: Guid, profile: Guid) =
        database.Enqueue(fun () ->
            Sqlite.execute
                database.Connection
                null
                "DELETE FROM skyrim_setup_intents WHERE profile_id=$profile AND workspace_id=$workspace"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ])
