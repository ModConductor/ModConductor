namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.DeploymentPlanning
open ModConductor.Fnis
open ModConductor.ModLibrary

type internal FnisExecutionLifecycle(database: StateDatabase, access: LibraryAccess) =
    let candidate connection transaction runId =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,profile_id,output_mod_id,output_version_id,input_fingerprint FROM fnis_runs WHERE id=$id AND phase IN(0,7)"
                [ "$id", box (string runId) ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            raise (InvalidDataException "The FNIS candidate is unavailable.")

        let value =
            Guid.Parse(reader.GetString 0),
            Guid.Parse(reader.GetString 1),
            Guid.Parse(reader.GetString 2),
            Guid.Parse(reader.GetString 3),
            reader.GetString 4

        reader.Close()
        value

    let activated (connection, transaction, runId, modId, version) =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT context_id,proposed_id FROM deployment_receipts WHERE id=$id AND phase=2"
                [ "$id", box (string runId) ]

        use row = query.ExecuteReader()

        if not (row.Read()) then
            false
        else
            let context = Guid.Parse(row.GetString 0)
            let proposed = Guid.Parse(row.GetString 1)
            row.Close()

            (DeploymentRows.context connection transaction context
             |> Option.exists (fun value -> value.Active = Some proposed))
            && (DeploymentRows.generation connection transaction context proposed
                |> Option.exists (fun generation ->
                    generation.References
                    |> List.exists (function
                        | SourcePin.Mod(id, selected, _) -> id = modId && selected = version
                        | _ -> false)))

    let selectOutput
        (connection, transaction, runId, workspace, profile, modId, version, fingerprint)
        =
        Sqlite.execute
            connection
            transaction
            "UPDATE mods SET current_version=$version,revision=revision+1,version_text=COALESCE((SELECT version_label FROM mod_version_origins WHERE version_id=$version),version_text) WHERE id=$mod AND workspace_id=$workspace"
            [ "$version", box (string version)
              "$mod", box (string modId)
              "$workspace", box (string workspace) ]

        Sqlite.execute
            connection
            transaction
            "INSERT INTO fnis_outputs(profile_id,workspace_id,mod_id,version_id,run_id,input_fingerprint,updated_at) VALUES($profile,$workspace,$mod,$version,$run,$fingerprint,$updated) ON CONFLICT(profile_id) DO UPDATE SET version_id=excluded.version_id,run_id=excluded.run_id,input_fingerprint=excluded.input_fingerprint,updated_at=excluded.updated_at"
            [ "$profile", box (string profile)
              "$workspace", box (string workspace)
              "$mod", box (string modId)
              "$version", box (string version)
              "$run", box (string runId)
              "$fingerprint", box fingerprint
              "$updated", box (DateTimeOffset.UtcNow.ToString("O")) ]

        Sqlite.execute
            connection
            transaction
            "UPDATE profiles SET selection_revision=selection_revision+1 WHERE id=$profile"
            [ "$profile", box (string profile) ]

    member _.Interrupted(profile: Guid) =
        database.Enqueue(fun () ->
            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT id FROM fnis_runs WHERE profile_id=$profile AND phase=7 AND EXISTS(SELECT 1 FROM mod_versions WHERE id=output_version_id AND phase=3) ORDER BY requested_at DESC LIMIT 1"
                    [ "$profile", box (string profile) ]

            match command.ExecuteScalar() with
            | :? string as id -> Some(Guid.Parse id)
            | _ -> None)

    member _.Defer(runId: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "UPDATE fnis_runs SET phase=7,busy=0,problem='FNIS output activation needs recovery.',completed_at=$completed WHERE id=$id AND phase=0"
                [ "$id", box (string runId)
                  "$completed", box (DateTimeOffset.UtcNow.ToString("O")) ])

    member _.Complete(runId: Guid) =
        database.EnqueueInternal(fun () ->
            let connection = database.Connection
            use transaction = connection.BeginTransaction(deferred = false)

            let workspace, profile, modId, version, fingerprint =
                candidate connection transaction runId

            if not (activated (connection, transaction, runId, modId, version)) then
                raise (InvalidDataException "The FNIS output is not active in the game view.")

            let selected =
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM fnis_outputs WHERE profile_id=$profile AND run_id=$run"
                    [ "$profile", box (string profile); "$run", box (string runId) ] = 1L

            if not selected then
                selectOutput (
                    connection,
                    transaction,
                    runId,
                    workspace,
                    profile,
                    modId,
                    version,
                    fingerprint
                )

            transaction.Commit())

    member _.MarkCurrent(runId: Guid) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "UPDATE fnis_runs SET phase=3,busy=0,problem=NULL,completed_at=$completed WHERE id=$run AND phase IN(0,7)"
                [ "$run", box (string runId)
                  "$completed", box (DateTimeOffset.UtcNow.ToString("O")) ])

    member _.PruneCandidate(runId: Guid) =
        task {
            let! candidate =
                database.Enqueue(fun () ->
                    use command =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT workspace_id,output_mod_id,output_version_id FROM fnis_runs WHERE id=$id"
                            [ "$id", box (string runId) ]

                    use reader = command.ExecuteReader()

                    if reader.Read() then
                        Some(
                            Guid.Parse(reader.GetString 0),
                            Guid.Parse(reader.GetString 1),
                            Guid.Parse(reader.GetString 2)
                        )
                    else
                        None)

            match candidate with
            | None -> return false
            | Some(workspace, modId, version) ->
                return! FnisOutputCleanup.pruneVersion database access workspace modId version
        }

    member _.PrunePrevious(runId: Guid) =
        task {
            let! previous =
                database.Enqueue(fun () ->
                    use command =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT r.workspace_id,r.output_mod_id,o.source_version FROM fnis_runs r JOIN mod_version_origins o ON o.version_id=r.output_version_id WHERE r.id=$id"
                            [ "$id", box (string runId) ]

                    use reader = command.ExecuteReader()

                    if reader.Read() && not (reader.IsDBNull 2) then
                        Some(
                            Guid.Parse(reader.GetString 0),
                            Guid.Parse(reader.GetString 1),
                            Guid.Parse(reader.GetString 2)
                        )
                    else
                        None)

            match previous with
            | None -> return false
            | Some(workspace, modId, version) ->
                return! FnisOutputCleanup.pruneVersion database access workspace modId version
        }
