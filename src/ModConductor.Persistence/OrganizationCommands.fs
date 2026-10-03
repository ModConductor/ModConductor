namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary
open ModConductor.ModOrganization

module internal OrganizationCommands =
    let change connection transaction profile expected ids edit =
        match SelectionRows.profile connection transaction profile with
        | None -> Error LibraryError.NotFound
        | Some(_, revision) when revision <> expected -> Error LibraryError.StaleRevision
        | Some(_, revision) ->
            use command =
                Sqlite.command
                    connection
                    transaction
                    "SELECT p.mod_id,p.organization_position,p.group_id,m.kind FROM profile_mods p JOIN mods m ON m.id=p.mod_id WHERE p.profile_id=$profile ORDER BY p.organization_position"
                    [ "$profile", box (string profile) ]

            use reader = command.ExecuteReader()

            let current =
                [ while reader.Read() do
                      yield
                          { Id = Guid.Parse(reader.GetString 0)
                            Position = reader.GetInt32 1
                            GroupId =
                              if reader.IsDBNull 2 then
                                  None
                              else
                                  Some(Guid.Parse(reader.GetString 2))
                            IsSeparator = reader.GetInt32 3 = 2 } ]

            reader.Close()

            match GroupPolicy.change ids edit current with
            | Error error -> Error error
            | Ok changed ->
                for row in changed do
                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE profile_mods SET organization_position=$position,group_id=$group WHERE profile_id=$profile AND mod_id=$mod"
                        [ "$profile", box (string profile)
                          "$mod", box (string row.Id)
                          "$position", box row.Position
                          "$group",
                          row.GroupId
                          |> Option.map (string >> box)
                          |> Option.defaultValue (box DBNull.Value) ]

                Sqlite.execute
                    connection
                    transaction
                    "UPDATE profiles SET selection_revision=selection_revision+1 WHERE id=$profile"
                    [ "$profile", box (string profile) ]

                Ok(revision + 1L)
