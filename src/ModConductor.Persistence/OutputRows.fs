namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.GeneratedOutputs
open ModConductor.Platform
open ModConductor.Deployment

type internal StoredOutputLocation =
    { View: OutputLocation
      RootName: string
      RootIdentity: FileIdentity option
      Initialized: bool
      Enabled: bool }

module internal OutputRows =
    let contextId workspace profile (state: ModConductor.GameContexts.GameContextState) =
        state.Binding
        |> Option.map (fun binding ->
            DeploymentContextId.create
                workspace
                profile
                (DeploymentContextId.fingerprint binding.Evidence))
        |> Option.defaultWith (fun () ->
            raise (InvalidDataException "The game context has no bound installation."))

    let boundContext connection transaction owner workspace profile =
        match GameContextRows.read connection transaction owner workspace profile with
        | Error _ -> Error OutputError.NotFound
        | Ok state when state.Binding.IsNone ->
            Error(OutputError.Unavailable "Select a game installation first.")
        | Ok state -> Ok(state, contextId workspace profile state)

    let revision connection transaction workspace context =
        Sqlite.number
            connection
            transaction
            "SELECT COALESCE((SELECT revision FROM output_contexts WHERE workspace_id=$workspace AND id=$context),0)"
            [ "$workspace", box (string workspace); "$context", box (string context) ]

    let current connection transaction (scope: OutputScope) =
        revision connection transaction scope.WorkspaceId scope.ContextId = scope.Revision
        && Sqlite.number
            connection
            transaction
            "SELECT COALESCE((SELECT revision FROM game_contexts WHERE workspace_id=$workspace AND profile_id=$profile),0)"
            [ "$workspace", box (string scope.WorkspaceId)
              "$profile", box (string scope.ProfileId) ] = scope.ContextRevision

    let pending connection transaction workspace context =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT id FROM output_actions WHERE workspace_id=$workspace AND context_id=$context AND complete=0 ORDER BY id LIMIT 17"
                [ "$workspace", box (string workspace); "$context", box (string context) ]

        use reader = query.ExecuteReader()

        let result =
            [ while reader.Read() do
                  yield Guid.Parse(reader.GetString 0) ]

        if result.Length > 16 then
            raise (InvalidDataException "The saved output action count exceeds its limit.")

        result

    let active connection transaction workspace =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM output_actions WHERE workspace_id=$workspace AND busy=1"
            [ "$workspace", box (string workspace) ]
        <> 0L

    let idle connection transaction workspace =
        if active connection transaction workspace then
            Error OutputError.Busy
        else
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT id FROM deployment_contexts WHERE pending IS NOT NULL"
                    []

            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            if
                ids
                |> List.exists (fun id ->
                    DeploymentRows.context connection transaction id
                    |> Option.exists (fun context ->
                        context.Roots |> List.exists (fun root -> root.Root.Id = workspace)))
            then
                Error OutputError.Busy
            else
                Ok()

    let columns =
        "id,workspace_id,context_id,name,purpose,target,revision,enabled,initialized,root_name,root_identity"

    let private read (root: WorkspaceRoot) (row: Microsoft.Data.Sqlite.SqliteDataReader) =
        let purpose =
            match row.GetInt32 4 with
            | 0 -> OutputPurpose.ToolFolder
            | 1 -> OutputPurpose.WritableFile(LibraryEncoding.readPath (row.GetString 5))
            | _ -> raise (InvalidDataException "The output purpose is invalid.")

        let name = row.GetString 9
        let rootPath = Path.Combine(HostPath.value root.Path, name)

        let physical =
            match purpose with
            | OutputPurpose.ToolFolder -> rootPath
            | OutputPurpose.WritableFile path ->
                Path.Combine(rootPath, List.last (LogicalPath.components path))

        let enabled = row.GetBoolean 7
        let initialized = row.GetBoolean 8

        { View =
            { Id = Guid.Parse(row.GetString 0)
              WorkspaceId = Guid.Parse(row.GetString 1)
              ContextId = Guid.Parse(row.GetString 2)
              Name = row.GetString 3
              Purpose = purpose
              Revision = row.GetInt64 6
              State =
                if not enabled then OutputLocationState.Stopped
                elif initialized then OutputLocationState.Ready
                else OutputLocationState.Uninitialized
              PhysicalPath = physical }
          RootName = name
          RootIdentity =
            if row.IsDBNull 10 then
                None
            else
                Some(LibraryEncoding.readIdentity (row.GetString 10))
          Initialized = initialized
          Enabled = enabled }

    let locations connection transaction (root: WorkspaceRoot) context =
        use query =
            Sqlite.command
                connection
                transaction
                ("SELECT "
                 + columns
                 + " FROM output_locations WHERE workspace_id=$workspace AND context_id=$context ORDER BY id LIMIT 65")
                [ "$workspace", box (string root.Id); "$context", box (string context) ]

        use reader = query.ExecuteReader()

        let result =
            [ while reader.Read() do
                  yield read root reader ]

        if result.Length > OutputLimits.locations then
            raise (InvalidDataException "The saved output location count exceeds its limit.")

        result

    let find connection transaction (root: WorkspaceRoot) id =
        use query =
            Sqlite.command
                connection
                transaction
                ("SELECT "
                 + columns
                 + " FROM output_locations WHERE workspace_id=$workspace AND id=$id")
                [ "$workspace", box (string root.Id); "$id", box (string id) ]

        use reader = query.ExecuteReader()
        if reader.Read() then Some(read root reader) else None

    let backing (root: WorkspaceRoot) (location: StoredOutputLocation) =
        location.RootIdentity
        |> Option.map (fun identity ->
            { Location = location.View
              Root =
                HostPath.create (Path.Combine(HostPath.value root.Path, location.RootName))
                |> Result.defaultWith invalidOp
              RootIdentity = identity
              Path =
                match location.View.Purpose with
                | OutputPurpose.ToolFolder -> None
                | OutputPurpose.WritableFile path ->
                    Some(
                        LogicalPath.create [ List.last (LogicalPath.components path) ]
                        |> Result.defaultWith (fun _ -> invalidOp "Invalid stored output path.")
                    ) })

    let private scopeForContext
        connection
        transaction
        (root: WorkspaceRoot)
        profile
        requested
        state
        currentId
        =
        let selected = requested |> Option.defaultValue currentId

        use query =
            Sqlite.command
                connection
                transaction
                "SELECT id,game_path FROM output_contexts WHERE workspace_id=$workspace ORDER BY id LIMIT 65"
                [ "$workspace", box (string root.Id) ]

        use reader = query.ExecuteReader()

        let stored =
            [ while reader.Read() do
                  let id = Guid.Parse(reader.GetString 0) in

                  yield
                      { Id = id
                        Installation = reader.GetString 1
                        Current = id = currentId } ]

        reader.Close()

        if stored.Length > 64 then
            Error OutputError.LimitExceeded
        else
            let contexts =
                if stored |> List.exists (fun value -> value.Id = currentId) then
                    stored
                else
                    { Id = currentId
                      Installation = state.Binding.Value.Path
                      Current = true }
                    :: stored

            match contexts |> List.tryFind (fun value -> value.Id = selected) with
            | None -> Error OutputError.NotFound
            | Some selectedContext ->
                let locations = locations connection transaction root selected

                let result: OutputScope =
                    { WorkspaceId = root.Id
                      ProfileId = profile
                      ContextId = selected
                      Revision = revision connection transaction root.Id selected
                      ContextRevision = state.Revision
                      Installation = selectedContext.Installation
                      Locations = locations |> List.map _.View
                      Contexts = contexts
                      PendingActions = pending connection transaction root.Id selected }

                if OutputPolicy.scopeBytes result > OutputLimits.pageBytes then
                    Error OutputError.LimitExceeded
                else
                    Ok(result, locations |> List.choose (backing root))

    let scope connection transaction owner (root: WorkspaceRoot) profile requested =
        boundContext connection transaction owner root.Id profile
        |> Result.bind (fun (state, currentId) ->
            scopeForContext connection transaction root profile requested state currentId)
