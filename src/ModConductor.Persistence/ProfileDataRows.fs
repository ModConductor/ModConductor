namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ProfileGameData

module internal ProfileDataRows =
    let fail error = raise (ProfileDataException error)

    let private bytes (reader: SqliteDataReader) offset =
        if reader.GetInt64(offset + 1) > 16L * 1024L * 1024L then
            ProfileDataValueEncoding.invalid ()

        reader.GetFieldValue<byte array> offset

    let context connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT body,length(body) FROM profile_data_contexts WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            Some(ProfileDataEncoding.readContext (bytes reader 0))
        else
            None

    let saveContext connection transaction (value: ProfileDataContext) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO profile_data_contexts(id,workspace_id,documents_identity,revision,pending,body) VALUES($id,$workspace,$documents,$revision,$pending,$body) ON CONFLICT(id) DO UPDATE SET revision=excluded.revision,pending=excluded.pending,body=excluded.body"
            [ "$id", box (string value.Id)
              "$workspace", box (string value.WorkspaceId)
              "$documents", box (LibraryEncoding.identity value.Documents.Identity)
              "$revision", box value.Revision
              "$pending",
              value.Pending
              |> Option.map (string >> box)
              |> Option.defaultValue (box DBNull.Value)
              "$body", box (ProfileDataEncoding.context value) ]

    let profile connection transaction context profile =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT body,length(body) FROM profile_data_profiles WHERE context_id=$context AND profile_id=$profile"
                [ "$context", box (string context); "$profile", box (string profile) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            Some(ProfileDataEncoding.readProfile (bytes reader 0))
        else
            None

    let saveProfile connection transaction context (value: PrivateProfileData) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO profile_data_profiles(context_id,profile_id,body) VALUES($context,$profile,$body) ON CONFLICT(context_id,profile_id) DO UPDATE SET body=excluded.body"
            [ "$context", box (string context)
              "$profile", box (string value.ProfileId)
              "$body", box (ProfileDataEncoding.profile value) ]

    let action connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT body,length(body) FROM profile_data_actions WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            Some(ProfileDataEncoding.readAction (bytes reader 0))
        else
            None

    let saveAction connection transaction owner busy (value: ProfileDataActionRecord) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO profile_data_actions(id,context_id,owner,busy,complete,body) VALUES($id,$context,$owner,$busy,$complete,$body) ON CONFLICT(id) DO UPDATE SET owner=excluded.owner,busy=excluded.busy,complete=excluded.complete,body=excluded.body"
            [ "$id", box (string value.Id)
              "$context", box (string value.ContextId)
              "$owner", box owner
              "$busy", box busy
              "$complete", box value.Complete
              "$body", box (ProfileDataEncoding.action value) ]

    let checkOwnership connection transaction (expected: ProfileDataContext) =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT body,length(body) FROM profile_data_contexts WHERE documents_identity=$documents AND id<>$id"
                [ "$documents", box (LibraryEncoding.identity expected.Documents.Identity)
                  "$id", box (string expected.Id) ]

        use reader = query.ExecuteReader()

        while reader.Read() do
            let other = ProfileDataEncoding.readContext (bytes reader 0)

            if other.Applied.IsSome || other.Pending.IsSome then
                fail (
                    ProfileDataError.Conflict
                        "Another workspace is using these settings and saves. Restore it first."
                )

    let checkProfile connection transaction workspace profile =
        if
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM profiles WHERE workspace_id=$workspace AND id=$profile"
                [ "$workspace", box (string workspace); "$profile", box (string profile) ]
            <> 1L
        then
            fail ProfileDataError.NotFound

    let profileEditAllowed connection transaction workspace expected command =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT a.body,length(a.body) FROM profile_data_contexts c JOIN profile_data_actions a ON a.id=c.pending WHERE c.workspace_id=$workspace"
                [ "$workspace", box (string workspace) ]

        use reader = query.ExecuteReader()
        let mutable allowed = true

        while reader.Read() do
            let action = ProfileDataEncoding.readAction (bytes reader 0)

            let own =
                match command, action.Kind with
                | ModConductor.Workspaces.ProfileEdit.Clone(source, target),
                  ProfileDataActionKind.Clone(id, name, revision) ->
                    source = action.ProfileId
                    && target.Id = id
                    && target.Name = name
                    && expected = revision
                | ModConductor.Workspaces.ProfileEdit.Delete target,
                  ProfileDataActionKind.Delete revision ->
                    target = action.ProfileId && expected = revision
                | _ -> false

            allowed <- allowed && own

        allowed
