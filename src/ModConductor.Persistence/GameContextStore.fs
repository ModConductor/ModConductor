namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.GameContexts

module internal GameContextRows =
    let read connection transaction owner workspace =
        if
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM workspaces WHERE id=$id"
                [ "$id", box (string workspace) ] = 0L
        then
            Error ContextError.NotFound
        else
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT id,path,revision,evidence,checked_owner,failure,proton_selection FROM game_contexts WHERE workspace_id=$id"
                    [ "$id", box (string workspace) ]

            use row = query.ExecuteReader()

            if row.Read() then
                Ok
                    { WorkspaceId = workspace
                      Revision = row.GetInt64 2
                      Binding =
                        Some
                            { Id = Guid.Parse(row.GetString 0)
                              Path = row.GetString 1
                              Proton =
                                if row.IsDBNull 6 then
                                    None
                                else
                                    Some(ProtonEncoding.decodeSelection (row.GetString 6))
                              Evidence = GameContextEncoding.decode (row.GetString 3)
                              NeedsCheck = row.GetString 4 <> owner || not (row.IsDBNull 5)
                              Failure = if row.IsDBNull 5 then None else Some(row.GetString 5) } }
            else
                Ok
                    { WorkspaceId = workspace
                      Revision = 0L
                      Binding = None }

    let save connection transaction owner workspace revision (binding: GameBinding) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO game_contexts(workspace_id,id,path,revision,evidence,checked_owner,failure,proton_selection) VALUES($workspace,$id,$path,$revision,$evidence,$owner,$failure,$proton) ON CONFLICT(workspace_id) DO UPDATE SET path=excluded.path,revision=excluded.revision,evidence=excluded.evidence,checked_owner=excluded.checked_owner,failure=excluded.failure,proton_selection=excluded.proton_selection"
            [ "$workspace", box (string workspace)
              "$id", box (string binding.Id)
              "$path", box binding.Path
              "$revision", box revision
              "$evidence", box (GameContextEncoding.encode binding.Evidence)
              "$owner", box owner
              "$proton",
              binding.Proton
              |> Option.map (ProtonEncoding.encodeSelection >> box)
              |> Option.defaultValue (box DBNull.Value)
              "$failure",
              binding.Failure |> Option.map box |> Option.defaultValue (box DBNull.Value) ]

type GameContextStore internal (database: StateDatabase, roots: OwnedWorkspaceRootStore) =
    let gate = obj ()
    let mutable active = 0
    let mutable closed = false

    let run action =
        task {
            let admitted =
                lock gate (fun () ->
                    if closed || active >= 2 then
                        false
                    else
                        active <- active + 1
                        true)

            if not admitted then
                return Error ContextError.Busy
            else
                try
                    try
                        return! action ()
                    with :? ModConductor.Operations.CapacityException ->
                        return Error ContextError.Busy
                finally
                    lock gate (fun () -> active <- active - 1)
        }

    let read workspace =
        database.Enqueue(fun () ->
            GameContextRows.read database.Connection null database.OwnerId workspace)

    let change workspace expected (candidate: ContextSelection option) =
        run (fun () ->
            task {
                let! before = read workspace

                match before with
                | Error error -> return Error error
                | Ok before when before.Revision <> expected ->
                    return Error ContextError.StaleRevision
                | Ok before ->
                    let selection =
                        candidate
                        |> Option.orElseWith (fun () ->
                            before.Binding
                            |> Option.map (fun b -> { Path = b.Path; Proton = b.Proton }))

                    match selection with
                    | None -> return Error ContextError.NotFound
                    | Some selection ->
                        let path = selection.Path
                        let! owned = roots.Validate workspace

                        match owned with
                        | Ok receipt when receipt.Phase = RootCreationPhase.Complete ->
                            let! evidence =
                                Task.Run(fun () ->
                                    let installation = InstallationValidation.inspect path

                                    match selection.Proton with
                                    | Some proton when installation.Valid ->
                                        ModConductor.ProtonContexts.Validation.inspect
                                            installation
                                            proton
                                    | _ -> installation)

                            if candidate.IsSome && not evidence.Valid then
                                return Error(ContextError.Invalid evidence)
                            else
                                return!
                                    database.Enqueue(fun () ->
                                        use transaction =
                                            database.Connection.BeginTransaction(deferred = false)

                                        let result =
                                            match
                                                GameContextRows.read
                                                    database.Connection
                                                    transaction
                                                    database.OwnerId
                                                    workspace
                                            with
                                            | Error error -> Error error
                                            | Ok current when current.Revision <> expected ->
                                                Error ContextError.StaleRevision
                                            | Ok current ->
                                                let binding =
                                                    if evidence.Valid then
                                                        { Id =
                                                            current.Binding
                                                            |> Option.map _.Id
                                                            |> Option.defaultWith Guid.NewGuid
                                                          Path = path
                                                          Proton =
                                                            evidence.Proton
                                                            |> Option.map _.Selection
                                                          Evidence = evidence
                                                          NeedsCheck = false
                                                          Failure = None }
                                                    else
                                                        { current.Binding.Value with
                                                            NeedsCheck = true
                                                            Failure =
                                                                Some(
                                                                    evidence.Problems
                                                                    |> List.map _.Detail
                                                                    |> String.concat " "
                                                                ) }

                                                GameContextRows.save
                                                    database.Connection
                                                    transaction
                                                    database.OwnerId
                                                    workspace
                                                    (expected + 1L)
                                                    binding

                                                Ok
                                                    { WorkspaceId = workspace
                                                      Revision = expected + 1L
                                                      Binding = Some binding }

                                        transaction.Commit()
                                        result)
                        | Ok _
                        | Error _ -> return Error ContextError.WorkspaceUnavailable
            })

    member internal _.TryClose() =
        lock gate (fun () ->
            if active <> 0 then
                false
            else
                closed <- true
                true)

    interface IGameContexts with
        member _.Read workspace = run (fun () -> read workspace)

        member _.Save(workspace, expected, selection) =
            change workspace expected (Some selection)

        member _.Refresh(workspace, expected) = change workspace expected None
