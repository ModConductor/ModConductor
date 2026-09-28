namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.GameContexts

module internal GameContextRows =
    let read connection transaction owner workspace profile =
        if
            Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM profiles WHERE workspace_id=$workspace AND id=$profile"
                [ "$workspace", box (string workspace); "$profile", box (string profile) ] = 0L
        then
            Error ContextError.NotFound
        else
            use query =
                Sqlite.command
                    connection
                    transaction
                    "SELECT game_id,id,path,revision,evidence,checked_owner,failure,proton_selection FROM game_contexts WHERE workspace_id=$workspace AND profile_id=$profile"
                    [ "$workspace", box (string workspace); "$profile", box (string profile) ]

            use row = query.ExecuteReader()

            if row.Read() then
                Ok
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Revision = row.GetInt64 3
                      Binding =
                        Some
                            { Id = Guid.Parse(row.GetString 1)
                              GameId =
                                GameId.tryParse (row.GetString 0)
                                |> Option.defaultWith (fun () -> invalidOp "Invalid stored game ID.")
                              Path = row.GetString 2
                              Proton =
                                if row.IsDBNull 7 then
                                    None
                                else
                                    Some(ProtonEncoding.decodeSelection (row.GetString 7))
                              Evidence = GameContextEncoding.decode (row.GetString 4)
                              NeedsCheck = row.GetString 5 <> owner || not (row.IsDBNull 6)
                              Failure = if row.IsDBNull 6 then None else Some(row.GetString 6) } }
            else
                Ok
                    { WorkspaceId = workspace
                      ProfileId = profile
                      Revision = 0L
                      Binding = None }

    let save connection transaction owner workspace profile revision (binding: GameBinding) =
        Sqlite.execute
            connection
            transaction
            "INSERT INTO game_contexts(profile_id,workspace_id,game_id,id,path,revision,evidence,checked_owner,failure,proton_selection) VALUES($profile,$workspace,$game,$id,$path,$revision,$evidence,$owner,$failure,$proton) ON CONFLICT(profile_id) DO UPDATE SET game_id=excluded.game_id,path=excluded.path,revision=excluded.revision,evidence=excluded.evidence,checked_owner=excluded.checked_owner,failure=excluded.failure,proton_selection=excluded.proton_selection"
            [ "$workspace", box (string workspace)
              "$profile", box (string profile)
              "$game", box (GameId.value binding.GameId)
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
    let mutable activeChanges = 0
    let mutable closed = false

    let run change action =
        task {
            let admitted =
                lock gate (fun () ->
                    if closed || (change && activeChanges >= 2) then
                        false
                    else
                        active <- active + 1
                        if change then activeChanges <- activeChanges + 1
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
                    lock gate (fun () ->
                        active <- active - 1
                        if change then activeChanges <- activeChanges - 1)
        }

    let read workspace profile =
        database.Enqueue(fun () ->
            GameContextRows.read database.Connection null database.OwnerId workspace profile)

    let change workspace profile expected (candidate: ContextSelection option) =
        run true (fun () ->
            task {
                let! before = read workspace profile

                match before with
                | Error error -> return Error error
                | Ok before when before.Revision <> expected ->
                    return Error ContextError.StaleRevision
                | Ok before ->
                    let selection =
                        candidate
                        |> Option.orElseWith (fun () ->
                            before.Binding
                            |> Option.map (fun b ->
                                { GameId = b.GameId
                                  Path = b.Path
                                  Proton = b.Proton }))

                    match selection with
                    | None -> return Error ContextError.NotFound
                    | Some selection ->
                        let path = selection.Path
                        let! owned = roots.Validate workspace

                        match owned with
                        | Ok receipt when receipt.Phase = RootCreationPhase.Complete ->
                            let definition =
                                match selection.GameId with
                                | GameId.SkyrimSpecialEditionSteam -> Skyrim.definition

                            let! installation, evidence =
                                Task.Run(fun () ->
                                    let installation = InstallationValidation.inspect definition path

                                    let evidence =
                                        match selection.Proton with
                                        | Some proton when installation.Valid ->
                                            ModConductor.ProtonContexts.Validation.inspect
                                                installation
                                                proton
                                        | _ -> installation

                                    installation, evidence)

                            let pendingFirstRun =
                                match candidate, selection.Proton with
                                | Some _, Some proton when
                                    installation.Valid
                                    && proton.AppId = Skyrim.definition.SteamAppId
                                    ->
                                    evidence.Problems
                                    |> List.exists (fun problem ->
                                        problem.Path.StartsWith(
                                            proton.CompatData,
                                            StringComparison.Ordinal
                                        )
                                        && (problem.Detail.StartsWith(
                                                "The Proton data folder could not be checked.",
                                                StringComparison.Ordinal
                                            )
                                            || problem.Detail.StartsWith(
                                                "The Proton user folders could not be checked.",
                                                StringComparison.Ordinal
                                            )
                                            || problem.Detail.StartsWith(
                                                "The Proton prefix metadata could not be checked.",
                                                StringComparison.Ordinal
                                            )))
                                | _ -> false

                            if candidate.IsSome && not evidence.Valid && not pendingFirstRun then
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
                                                    profile
                                            with
                                            | Error error -> Error error
                                            | Ok current when current.Revision <> expected ->
                                                Error ContextError.StaleRevision
                                            | Ok current ->
                                                let binding =
                                                    { Id =
                                                        current.Binding
                                                        |> Option.filter (fun binding ->
                                                            binding.GameId = selection.GameId)
                                                        |> Option.map _.Id
                                                        |> Option.defaultWith Guid.NewGuid
                                                      GameId = selection.GameId
                                                      Path = path
                                                      Proton =
                                                        if evidence.Valid then
                                                            evidence.Proton
                                                            |> Option.map _.Selection
                                                        else
                                                            selection.Proton
                                                      Evidence =
                                                        if evidence.Valid then
                                                            evidence
                                                        else
                                                            current.Binding
                                                            |> Option.map _.Evidence
                                                            |> Option.defaultValue evidence
                                                      NeedsCheck = not evidence.Valid
                                                      Failure =
                                                        if evidence.Valid then
                                                            None
                                                        else
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
                                                    profile
                                                    (expected + 1L)
                                                    binding

                                                Ok
                                                    { WorkspaceId = workspace
                                                      ProfileId = profile
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
        member _.Read(workspace, profile) =
            // A transient Busy snapshot would leave a setup watch waiting for an unrelated change.
            run false (fun () ->
                database.EnqueueInternal(fun () ->
                    GameContextRows.read database.Connection null database.OwnerId workspace profile))

        member _.Save(workspace, profile, expected, selection) =
            change workspace profile expected (Some selection)

        member _.Refresh(workspace, profile, expected) = change workspace profile expected None
