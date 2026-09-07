namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.Workspaces

module internal WorkspaceProfiles =
    let profile connection transaction workspace id =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT id,name FROM profiles WHERE workspace_id=$workspace AND id=$id"
                [ "$workspace", box (string workspace); "$id", box (string id) ]

        use reader = statement.ExecuteReader()

        if reader.Read() then
            Some
                { Profile.Id = Guid.Parse(reader.GetString 0)
                  Name = reader.GetString 1 }
        else
            None

    let summary connection transaction (root: RootCreationReceipt) =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT name,revision,selected_profile FROM workspaces WHERE id=$id"
                [ "$id", box (string root.Workspace.Id) ]

        use reader = statement.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let name = reader.GetString 0
            let revision = reader.GetInt64 1

            let selected =
                if reader.IsDBNull 2 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 2))

            reader.Close()

            Some
                { Id = root.Workspace.Id
                  Name = name
                  Path = root.Workspace.Path
                  Revision = revision
                  SelectedProfile =
                    selected |> Option.bind (profile connection transaction root.Workspace.Id)
                  PendingRoot =
                    if root.Phase = RootCreationPhase.Complete then
                        None
                    else
                        Some
                            { ReceiptRevision = root.Revision
                              Reason =
                                match root.Phase, root.MarkerIdentity with
                                | RootCreationPhase.Unresolved, None ->
                                    RootIssueReason.OwnershipUnproved
                                | RootCreationPhase.Unresolved, Some _ ->
                                    RootIssueReason.IdentityUnverified
                                | _ -> RootIssueReason.IncompleteCreation } }

    let page connection transaction root after =
        summary connection transaction root
        |> Option.map (fun workspace ->
            use statement =
                Sqlite.command
                    connection
                    transaction
                    "SELECT id,name FROM profiles WHERE workspace_id=$workspace AND id>$after ORDER BY id LIMIT 33"
                    [ "$workspace", box (string workspace.Id)
                      "$after", box (after |> Option.map string |> Option.defaultValue "") ]

            use reader = statement.ExecuteReader()

            let rows =
                [ while reader.Read() do
                      yield
                          { Profile.Id = Guid.Parse(reader.GetString 0)
                            Name = reader.GetString 1 } ]

            let profiles = rows |> List.truncate 32

            { Workspace = workspace
              Profiles = profiles
              NextProfile =
                if rows.Length > 32 then
                    Some((List.last profiles).Id)
                else
                    None })

    let private read connection transaction id =
        WorkspaceRows.find connection transaction id
        |> Option.bind (fun row -> summary connection transaction row.Receipt)

    let edit (connection: SqliteConnection) id expected command beforeCommit =
        use transaction = connection.BeginTransaction(deferred = false)

        let result =
            match read connection transaction id with
            | None -> Error WorkspaceError.NotFound
            | Some current when current.PendingRoot.IsSome -> Error WorkspaceError.RootUnresolved
            | Some current when current.Revision <> expected -> Error WorkspaceError.StaleRevision
            | Some current ->
                let selected = current.SelectedProfile |> Option.map (fun profile -> profile.Id)
                let target = profile connection transaction id (ProfilePolicy.target command)

                match ProfilePolicy.validate selected target command with
                | Error error -> Error error
                | Ok edit ->
                    let newProfile =
                        match edit with
                        | ProfileEdit.Create value
                        | ProfileEdit.Clone(_, value) -> Some value
                        | ProfileEdit.Rename _
                        | ProfileEdit.Select _
                        | ProfileEdit.Delete _ -> None

                    let duplicate =
                        newProfile
                        |> Option.exists (fun value ->
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM profiles WHERE id=$id"
                                [ "$id", box (string value.Id) ]
                            <> 0L)

                    if duplicate then
                        Error WorkspaceError.IdentityConflict
                    else
                        let changed, deleted, selection =
                            match edit with
                            | ProfileEdit.Create value
                            | ProfileEdit.Clone(_, value) ->
                                Sqlite.execute
                                    connection
                                    transaction
                                    "INSERT INTO profiles(id,workspace_id,name) VALUES($id,$workspace,$name)"
                                    [ "$id", box (string value.Id)
                                      "$workspace", box (string id)
                                      "$name", box value.Name ]

                                let source =
                                    match edit with
                                    | ProfileEdit.Clone(source, _) -> Some source
                                    | ProfileEdit.Create _ -> None
                                    | ProfileEdit.Rename _
                                    | ProfileEdit.Select _
                                    | ProfileEdit.Delete _ -> invalidOp "Expected a new profile."

                                SelectionRows.initialize connection transaction id value.Id source
                                Some value, None, selected |> Option.orElse (Some value.Id)
                            | ProfileEdit.Rename(target, name) ->
                                Sqlite.execute
                                    connection
                                    transaction
                                    "UPDATE profiles SET name=$name WHERE workspace_id=$workspace AND id=$id"
                                    [ "$id", box (string target)
                                      "$workspace", box (string id)
                                      "$name", box name ]

                                Some { Profile.Id = target; Name = name }, None, selected
                            | ProfileEdit.Select target -> None, None, Some target
                            | ProfileEdit.Delete target ->
                                Sqlite.execute
                                    connection
                                    transaction
                                    "DELETE FROM profiles WHERE workspace_id=$workspace AND id=$id"
                                    [ "$id", box (string target); "$workspace", box (string id) ]

                                None, Some target, selected

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE workspaces SET revision=revision+1,selected_profile=$selected WHERE id=$id"
                            [ "$id", box (string id)
                              "$selected",
                              selection
                              |> Option.map (string >> box)
                              |> Option.defaultValue (box DBNull.Value) ]

                        let workspace = read connection transaction id |> Option.get

                        Ok
                            { Workspace = workspace
                              Changed = changed
                              Deleted = deleted }

        beforeCommit ()
        transaction.Commit()
        result
