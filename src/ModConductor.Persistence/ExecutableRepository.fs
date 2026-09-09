namespace ModConductor.Persistence

open System
open System.Text
open ModConductor.Executables

[<Sealed>]
type internal ExecutableRepository(database: StateDatabase) =
    let connection = database.Connection
    let id (v: Guid) = v.ToString()

    let scalar transaction sql args =
        use command = Sqlite.command connection transaction sql args
        let value = command.ExecuteScalar()

        if isNull value || Convert.IsDBNull value then
            None
        else
            Some(string value)

    let preset transaction key =
        scalar
            transaction
            "SELECT data FROM executable_presets WHERE id=$id"
            [ "$id", box (id key) ]
        |> Option.map ExecutableEncoding.decodePreset

    let readRun transaction workspace key =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT data,revision,phase,owner FROM executable_runs WHERE workspace_id=$workspace AND id=$id"
                [ "$workspace", box (id workspace); "$id", box (id key) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let stored = ExecutableEncoding.decodeRun (reader.GetString 0)
            let phase = ExecutableEncoding.readPhase (reader.GetInt32 2)

            let ownerChanged =
                reader.GetString(3) <> database.OwnerId && not (ExecutablePolicy.terminal phase)

            Some
                { stored with
                    Revision = reader.GetInt64 1
                    Phase = (if ownerChanged then RunPhase.TrackingUnavailable else phase)
                    Problem =
                        (if ownerChanged then
                             Some "Another app session tracks this run."
                         elif
                             phase = RunPhase.TrackingUnavailable
                             && not (ExecutablePolicy.terminal stored.Phase)
                         then
                             Some "The app restarted. The tool can still be active."
                         else
                             stored.Problem) }

    let exists transaction workspace =
        scalar transaction "SELECT id FROM workspaces WHERE id=$id" [ "$id", box (id workspace) ]
        |> Option.isSome

    let bound cost (values: 'a list) =
        let mutable used = 0
        let mutable more = false
        let result = ResizeArray<'a>()

        for value in values do
            let size = cost value

            if more || result.Count >= 32 || (result.Count > 0 && used + size > 1024 * 1024) then
                more <- true
            else
                used <- used + size
                result.Add value

        List.ofSeq result, more

    let presetSize (value: ExecutablePreset) =
        1024 + Encoding.UTF8.GetByteCount(ExecutableEncoding.encodePreset value)

    let runSize (value: ExecutableRun) =
        1024 + Encoding.UTF8.GetByteCount(ExecutableEncoding.encodeRun value)

    interface IExecutableRepository with
        member _.List(workspace, after) =
            database.Enqueue(fun () ->
                if not (exists null workspace) then
                    Error ExecutableError.NotFound
                else
                    let rows =
                        use command =
                            Sqlite.command
                                connection
                                null
                                "SELECT data FROM executable_presets WHERE workspace_id=$workspace AND id>$after ORDER BY id LIMIT 33"
                                [ "$workspace", box (id workspace)
                                  "$after", box (after |> Option.map id |> Option.defaultValue "") ]

                        use reader = command.ExecuteReader()

                        [ while reader.Read() do
                              yield ExecutableEncoding.decodePreset (reader.GetString 0) ]

                    let withRuns =
                        rows
                        |> List.map (fun tool ->
                            let latest =
                                scalar
                                    null
                                    "SELECT id FROM executable_runs WHERE workspace_id=$workspace AND preset_id=$preset ORDER BY sequence DESC LIMIT 1"
                                    [ "$workspace", box (id workspace)
                                      "$preset", box (id tool.Id) ]
                                |> Option.map Guid.Parse
                                |> Option.bind (readRun null workspace)

                            tool, latest)

                    let values, more =
                        bound
                            (fun (tool, latest) ->
                                presetSize tool
                                + (latest |> Option.map runSize |> Option.defaultValue 0))
                            withRuns

                    Ok
                        { Presets = values |> List.map fst
                          LatestRuns = values |> List.choose snd
                          Next =
                            if more then
                                values |> List.tryLast |> Option.map (fun (tool, _) -> tool.Id)
                            else
                                None })

        member _.ReadPreset(workspace, key) =
            database.Enqueue(fun () ->
                match preset null key with
                | Some value when value.WorkspaceId = workspace -> Ok value
                | _ -> Error ExecutableError.NotFound)

        member _.Save value =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    if not (exists transaction value.WorkspaceId) then
                        Error ExecutableError.NotFound
                    else
                        match preset transaction value.Id with
                        | Some current when current.WorkspaceId <> value.WorkspaceId ->
                            Error ExecutableError.IdentityConflict
                        | Some current when current.Revision <> value.Revision ->
                            Error ExecutableError.StaleRevision
                        | None when value.Revision <> 0L -> Error ExecutableError.StaleRevision
                        | _ ->
                            let saved =
                                { value with
                                    Revision = value.Revision + 1L }

                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO executable_presets(id,workspace_id,revision,data) VALUES($id,$workspace,$revision,$data) ON CONFLICT(id) DO UPDATE SET revision=$revision,data=$data"
                                [ "$id", box (id value.Id)
                                  "$workspace", box (id value.WorkspaceId)
                                  "$revision", box saved.Revision
                                  "$data", box (ExecutableEncoding.encodePreset saved) ]

                            Ok saved

                transaction.Commit()
                result)

        member _.Delete(workspace, key, revision) =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match preset transaction key with
                    | None -> Error ExecutableError.NotFound
                    | Some value when value.WorkspaceId <> workspace ->
                        Error ExecutableError.NotFound
                    | Some value when value.Revision <> revision ->
                        Error ExecutableError.StaleRevision
                    | Some _ ->
                        Sqlite.execute
                            connection
                            transaction
                            "DELETE FROM executable_presets WHERE id=$id"
                            [ "$id", box (id key) ]

                        Ok()

                transaction.Commit()
                result)

        member _.Begin request =
            database.Enqueue(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match readRun transaction request.WorkspaceId request.Id with
                    | Some current when current.Request = request -> Ok(current, false)
                    | Some _ -> Error ExecutableError.IdentityConflict
                    | None when
                        scalar
                            transaction
                            "SELECT id FROM executable_runs WHERE id=$id"
                            [ "$id", box (id request.Id) ]
                        |> Option.isSome
                        ->
                        Error ExecutableError.IdentityConflict
                    | None ->
                        use command =
                            Sqlite.command
                                connection
                                transaction
                                "SELECT w.revision,w.selected_profile,p.name FROM workspaces w LEFT JOIN profiles p ON p.id=w.selected_profile WHERE w.id=$workspace"
                                [ "$workspace", box (id request.WorkspaceId) ]

                        let workspace =
                            use reader = command.ExecuteReader()

                            if reader.Read() then
                                Some(
                                    reader.GetInt64 0,
                                    (if reader.IsDBNull 1 then
                                         None
                                     else
                                         Some(Guid.Parse(reader.GetString 1))),
                                    (if reader.IsDBNull 2 then None else Some(reader.GetString 2))
                                )
                            else
                                None

                        match workspace, preset transaction request.PresetId with
                        | None, _
                        | _, None -> Error ExecutableError.NotFound
                        | Some(revision, _, _), Some tool when
                            revision <> request.WorkspaceRevision
                            || tool.Revision <> request.PresetRevision
                            ->
                            Error ExecutableError.StaleRevision
                        | _, Some tool when tool.WorkspaceId <> request.WorkspaceId ->
                            Error ExecutableError.NotFound
                        | Some(_, profile, name), Some tool ->
                            if
                                Sqlite.number
                                    connection
                                    transaction
                                    "SELECT count(*) FROM executable_runs WHERE owner=$owner AND phase IN (0,1,2)"
                                    [ "$owner", box database.OwnerId ]
                                >= 32L
                            then
                                Error ExecutableError.Capacity
                            else
                                let value =
                                    { Request = request
                                      Revision = 1L
                                      Preset = tool
                                      ProfileId = profile
                                      ProfileName = name
                                      RequestedAt = DateTimeOffset.UtcNow
                                      Phase = RunPhase.Starting
                                      ProcessId = None
                                      Scope = None
                                      RootExitCode = None
                                      ActiveProcesses = None
                                      Problem = None }

                                Sqlite.execute
                                    connection
                                    transaction
                                    "INSERT INTO executable_runs(id,workspace_id,preset_id,owner,revision,phase,data) VALUES($id,$workspace,$preset,$owner,1,0,$data)"
                                    [ "$id", box (id request.Id)
                                      "$workspace", box (id request.WorkspaceId)
                                      "$preset", box (id request.PresetId)
                                      "$owner", box database.OwnerId
                                      "$data", box (ExecutableEncoding.encodeRun value) ]

                                Ok(value, true)

                transaction.Commit()
                result)

        member _.Read(workspace, key) =
            database.Enqueue(fun () ->
                readRun null workspace key
                |> Option.map Ok
                |> Option.defaultValue (Error ExecutableError.NotFound))

        member _.Recent(workspace, after) =
            database.Enqueue(fun () ->
                if not (exists null workspace) then
                    Error ExecutableError.NotFound
                else
                    let cursor =
                        after
                        |> Option.bind (fun key ->
                            scalar
                                null
                                "SELECT sequence FROM executable_runs WHERE workspace_id=$workspace AND id=$id"
                                [ "$workspace", box (id workspace); "$id", box (id key) ]
                            |> Option.map Int64.Parse)

                    if Option.isSome after && Option.isNone cursor then
                        Error ExecutableError.NotFound
                    else
                        let keys =
                            use command =
                                Sqlite.command
                                    connection
                                    null
                                    "SELECT id FROM executable_runs WHERE workspace_id=$workspace AND sequence<$after ORDER BY sequence DESC LIMIT 33"
                                    [ "$workspace", box (id workspace)
                                      "$after", box (Option.defaultValue Int64.MaxValue cursor) ]

                            use reader = command.ExecuteReader()

                            [ while reader.Read() do
                                  yield Guid.Parse(reader.GetString 0) ]

                        let values, more =
                            keys |> List.choose (readRun null workspace) |> bound runSize

                        Ok(
                            values,
                            if more then
                                values |> List.tryLast |> Option.map _.Request.Id
                            else
                                None
                        ))

        member _.Update value =
            database.EnqueueInternal(fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let current =
                    readRun transaction value.Request.WorkspaceId value.Request.Id
                    |> Option.defaultWith (fun () ->
                        invalidOp "The executable run no longer exists.")

                let result =
                    if
                        current.Revision <> value.Revision
                        || ExecutablePolicy.terminal current.Phase
                    then
                        current
                    else
                        let saved =
                            { value with
                                Revision = value.Revision + 1L }

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE executable_runs SET revision=$revision,phase=$phase,data=$data WHERE id=$id AND owner=$owner"
                            [ "$id", box (id value.Request.Id)
                              "$owner", box database.OwnerId
                              "$revision", box saved.Revision
                              "$phase", box (ExecutableEncoding.phase saved.Phase)
                              "$data", box (ExecutableEncoding.encodeRun saved) ]

                        saved

                transaction.Commit()
                result)
