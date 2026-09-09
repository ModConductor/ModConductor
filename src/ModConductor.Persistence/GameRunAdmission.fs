namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.Executables

module internal GameRunAdmission =
    let beginRun
        (database: StateDatabase)
        (read: SqliteTransaction -> Guid -> Guid -> ExecutableRun option)
        (game: GameRun)
        =
        database.Enqueue(fun () ->
            let connection = database.Connection
            let request = game.Request
            use transaction = connection.BeginTransaction(deferred = false)

            let count sql args =
                Sqlite.number connection transaction sql args

            let result =
                match read transaction request.WorkspaceId request.Id with
                | Some current ->
                    match current.Source with
                    | RunSource.Game previous when previous.Request = request -> Ok(current, false)
                    | _ -> Error ExecutableError.IdentityConflict
                | None when
                    count
                        "SELECT count(*) FROM executable_runs WHERE id=$id"
                        [ "$id", box (string request.Id) ]
                    <> 0L
                    ->
                    Error ExecutableError.IdentityConflict
                | None ->
                    let context =
                        GameContextRows.read
                            connection
                            transaction
                            database.OwnerId
                            request.WorkspaceId

                    let validContext =
                        match context with
                        | Ok state when state.Revision = request.ContextRevision ->
                            state.Binding
                            |> Option.exists (fun binding ->
                                binding.Id = game.ContextId
                                && not binding.NeedsCheck
                                && binding.Evidence.Valid)
                        | _ -> false

                    let profile =
                        use query =
                            Sqlite.command
                                connection
                                transaction
                                "SELECT p.name FROM workspaces w JOIN profiles p ON p.id=w.selected_profile WHERE w.id=$workspace AND w.revision=$revision AND p.id=$profile"
                                [ "$workspace", box (string request.WorkspaceId)
                                  "$revision", box request.WorkspaceRevision
                                  "$profile", box (string request.ProfileId) ]

                        query.ExecuteScalar() |> Option.ofObj |> Option.map string

                    if not validContext || profile.IsNone then
                        Error ExecutableError.StaleRevision
                    elif
                        count
                            "SELECT count(*) FROM executable_runs WHERE owner=$owner AND phase IN (0,1,2)"
                            [ "$owner", box database.OwnerId ]
                        >= 32L
                    then
                        Error ExecutableError.Capacity
                    else
                        let value =
                            { Source = RunSource.Game game
                              Revision = 1L
                              ProfileId = Some request.ProfileId
                              ProfileName = profile
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
                            "INSERT INTO executable_runs(id,workspace_id,preset_id,owner,revision,phase,data) VALUES($id,$workspace,'',$owner,1,0,$data)"
                            [ "$id", box (string request.Id)
                              "$workspace", box (string request.WorkspaceId)
                              "$owner", box database.OwnerId
                              "$data", box (ExecutableEncoding.encodeRun value) ]

                        Ok(value, true)

            transaction.Commit()
            result)
