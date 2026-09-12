namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ModLibrary
open ModConductor.ModSelection

module internal SelectionRows =
    let read (reader: SqliteDataReader) =
        { Id = Guid.Parse(reader.GetString 0)
          Priority = reader.GetInt32 1
          Enabled =
            if reader.IsDBNull 2 then
                None
            else
                Some(reader.GetInt64 2 <> 0L) }

    let find connection transaction profile modId =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,priority,enabled FROM profile_mods WHERE profile_id=$profile AND mod_id=$mod"
                [ "$profile", box (string profile); "$mod", box (string modId) ]

        use reader = statement.ExecuteReader()
        if reader.Read() then Some(read reader) else None

    let all connection transaction profile =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id,priority,enabled FROM profile_mods WHERE profile_id=$profile ORDER BY priority"
                [ "$profile", box (string profile) ]

        use reader = statement.ExecuteReader()

        [ while reader.Read() do
              yield read reader ]

    let profile connection transaction id =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,selection_revision FROM profiles WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = statement.ExecuteReader()

        if reader.Read() then
            Some(Guid.Parse(reader.GetString 0), reader.GetInt64 1)
        else
            None

    let enabledCount connection transaction profile =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM profile_mods WHERE profile_id=$profile AND enabled=1"
            [ "$profile", box (string profile) ]
        |> int

    let initialize connection transaction workspace profile source =
        match source with
        | Some source ->
            Sqlite.execute
                connection
                transaction
                "INSERT INTO profile_mods SELECT $profile,mod_id,priority,enabled FROM profile_mods WHERE profile_id=$source"
                [ "$profile", box (string profile); "$source", box (string source) ]
        | None ->
            Sqlite.execute
                connection
                transaction
                "INSERT INTO profile_mods SELECT $profile,id,ROW_NUMBER() OVER(ORDER BY id)-1,CASE WHEN kind=1 THEN 0 ELSE NULL END FROM mods WHERE workspace_id=$workspace AND kind IN (1,2) AND NOT EXISTS(SELECT 1 FROM mod_deletion_targets d WHERE d.mod_id=mods.id)"
                [ "$profile", box (string profile); "$workspace", box (string workspace) ]

    let registered connection transaction workspace modId kind =
        if SelectionPolicy.ordered kind then
            Sqlite.execute
                connection
                transaction
                "INSERT INTO profile_mods SELECT p.id,$mod,(SELECT count(*) FROM profile_mods s WHERE s.profile_id=p.id),$enabled FROM profiles p WHERE p.workspace_id=$workspace"
                [ "$mod", box (string modId)
                  "$workspace", box (string workspace)
                  "$enabled", if kind = ModKind.Regular then box 0 else box DBNull.Value ]
        // Every new inventory ID invalidates a previously joined page, including locked entries.
        Sqlite.execute
            connection
            transaction
            "UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace"
            [ "$workspace", box (string workspace) ]

    let apply connection transaction profile (changed: OrderedMod list) =
        // Negative positions free unique slots only inside this transaction; readers see the final order.
        for row in changed do
            Sqlite.execute
                connection
                transaction
                "UPDATE profile_mods SET priority=-priority-1 WHERE profile_id=$profile AND mod_id=$mod"
                [ "$profile", box (string profile); "$mod", box (string row.Id) ]

        for row in changed do
            Sqlite.execute
                connection
                transaction
                "UPDATE profile_mods SET priority=$priority,enabled=$enabled WHERE profile_id=$profile AND mod_id=$mod"
                [ "$profile", box (string profile)
                  "$mod", box (string row.Id)
                  "$priority", box row.Priority
                  "$enabled",
                  row.Enabled
                  |> Option.map (fun enabled -> box (if enabled then 1 else 0))
                  |> Option.defaultValue (box DBNull.Value) ]

        Sqlite.execute
            connection
            transaction
            "UPDATE profiles SET selection_revision=selection_revision+1 WHERE id=$profile"
            [ "$profile", box (string profile) ]
