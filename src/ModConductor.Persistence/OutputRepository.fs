namespace ModConductor.Persistence

open System
open System.Threading.Tasks
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary

type internal OutputRepository
    (database: StateDatabase, access: LibraryAccess, publication: LibraryPublication) =
    let db action =
        task {
            try
                return! database.Enqueue action
            with
            | :? ModConductor.Operations.CapacityException ->
                return OutputRows.fail OutputError.Busy
            | :? SourceOverlapException ->
                return
                    OutputRows.fail (
                        OutputError.Invalid
                            "The selected output paths conflict under the game filename rules."
                    )
        }

    interface IOutputRepository with
        member _.Read(workspace, context) =
            task {
                let! root = OutputLocationCommands.root access workspace

                return!
                    db (fun () ->
                        use transaction = database.Connection.BeginTransaction(deferred = true)

                        let result =
                            OutputRows.scope
                                database.Connection
                                transaction
                                database.OwnerId
                                root
                                context

                        transaction.Commit()
                        result)
            }

        member _.Add(id, scope, name, purpose) =
            OutputLocationCommands.add database access id scope name purpose

        member _.Workspace id =
            db (fun () ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT workspace_id FROM output_locations WHERE id=$id"
                        [ "$id", box (string id) ]

                match query.ExecuteScalar() with
                | :? string as value -> Guid.Parse value
                | _ -> OutputRows.fail OutputError.NotFound)

        member _.StopUsing(id, revision) =
            OutputLocationCommands.stop database access id revision

        member _.Current scope =
            db (fun () -> OutputRows.current database.Connection null scope)

        member _.Previous scope =
            db (fun () ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT o.location_id,o.path,o.sha256,o.kept FROM output_observations o JOIN output_locations l ON o.location_id=l.id WHERE l.workspace_id=$workspace AND l.context_id=$context LIMIT 1000001"
                        [ "$workspace", box (string scope.WorkspaceId)
                          "$context", box (string scope.ContextId) ]

                use reader = query.ExecuteReader()

                let rows =
                    [ while reader.Read() do
                          yield
                              (Guid.Parse(reader.GetString 0),
                               LibraryEncoding.readPath (reader.GetString 1)),
                              (reader.GetString 2, reader.GetBoolean 3) ]

                if rows.Length > OutputLimits.entries then
                    OutputRows.fail OutputError.LimitExceeded

                Map.ofList rows)

        member _.Observed(scope, files) =
            database.EnqueueInternal(fun () ->
                use transaction = database.Connection.BeginTransaction(deferred = false)
                let current = OutputRows.current database.Connection transaction scope

                if current then
                    for value in files do
                        if value.File.Identity.IsSome then
                            Sqlite.execute
                                database.Connection
                                transaction
                                "INSERT INTO output_observations(location_id,path,sha256,kept) VALUES($location,$path,$hash,0) ON CONFLICT(location_id,path) DO UPDATE SET kept=CASE WHEN sha256=$hash THEN kept ELSE 0 END,sha256=$hash"
                                [ "$location", box (string value.File.LocationId)
                                  "$path", box (LibraryEncoding.path value.File.Path)
                                  "$hash", box value.File.Sha256 ]

                transaction.Commit()
                current)

        member _.ActiveDeployment scope =
            db (fun () ->
                DeploymentRows.context database.Connection null scope.ContextId
                |> Option.bind _.Active
                |> Option.filter (fun id ->
                    DeploymentRows.generation database.Connection null scope.ContextId id
                    |> Option.exists (fun generation ->
                        match generation.Provenance with
                        | Some provenance -> provenance.Profile.IsSome
                        | None -> true)))

        member _.CheckAction record =
            task {
                let! evidence = OutputLocationCommands.checkContext database record.Scope

                if
                    record.Action = OutputAction.Discard
                    && (record.Files
                        |> List.exists (fun file ->
                            match file.Backing.Location.Purpose with
                            | OutputPurpose.WritableFile _ -> true
                            | OutputPurpose.ToolFolder -> false))
                then
                    ModConductor.Deployment.GameProcesses.check evidence
            }

        member _.Preview record =
            db (fun () ->
                use transaction = database.Connection.BeginTransaction(deferred = true)

                if not (OutputRows.current database.Connection transaction record.Scope) then
                    OutputRows.fail OutputError.Stale

                let value = OutputActionRows.preview database.Connection transaction record
                transaction.Commit()
                value)

        member _.Claim record =
            db (fun () -> OutputActionRows.claim database record)

        member _.FindAction id =
            db (fun () -> OutputActionRows.find database.Connection null id)

        member _.Resume id =
            db (fun () -> OutputActionRows.resume database id)

        member _.Publish(record, token) =
            task {
                let version =
                    record.Result.VersionId
                    |> Option.defaultWith (fun () ->
                        OutputRows.fail (OutputError.Invalid "This action has no publication."))

                let! input =
                    db (fun () ->
                        match PublicationRows.find database.Connection null version with
                        | Some receipt when receipt.Phase = PublicationPhase.Complete ->
                            if
                                LibraryRows.origin database.Connection null version
                                <> VersionOrigin.Outputs record.Id
                            then
                                OutputRows.fail (
                                    OutputError.Invalid
                                        "The saved version belongs to another action."
                                )

                            None
                        | _ -> OutputActionRows.composition database.Connection null record)

                match input with
                | None -> return version
                | Some(modId, expected, input) ->
                    use cancelled =
                        token.Register(fun () ->
                            database
                                .EnqueueInternal(fun () ->
                                    PublicationRows.cancel database.Connection version |> ignore)
                                .GetAwaiter()
                                .GetResult())

                    token.ThrowIfCancellationRequested()

                    let! result =
                        access.Run(fun () ->
                            publication.Compose(
                                modId,
                                expected,
                                version,
                                input,
                                token,
                                ignore,
                                ignore
                            ))

                    match result with
                    | Ok _ -> return version
                    | Error LibraryError.StaleRevision
                    | Error LibraryError.SourceChanged -> return OutputRows.fail OutputError.Stale
                    | Error LibraryError.Busy -> return OutputRows.fail OutputError.Busy
                    | Error LibraryError.Cancelled -> return raise (OperationCanceledException())
                    | Error LibraryError.NotFound -> return OutputRows.fail OutputError.NotFound
                    | Error LibraryError.LimitExceeded ->
                        return OutputRows.fail OutputError.LimitExceeded
                    | Error LibraryError.InvalidMetadata
                    | Error LibraryError.InvalidSource
                    | Error LibraryError.IdentityConflict
                    | Error LibraryError.UnsupportedAction ->
                        return
                            OutputRows.fail (
                                OutputError.Invalid
                                    "The output publication is not valid for this mod."
                            )
                    | Error LibraryError.UnprovedOwnership
                    | Error LibraryError.FileUnavailable ->
                        return
                            OutputRows.fail (
                                OutputError.Unavailable
                                    "The output version could not be saved. Its files remain available for review."
                            )
            }

        member _.SaveEntry(id, file, disposition) =
            database.EnqueueInternal(fun () ->
                OutputActionRows.saveEntry database id file disposition)

        member _.Release id =
            database.EnqueueInternal(fun () ->
                Sqlite.execute
                    database.Connection
                    null
                    "UPDATE output_actions SET busy=0 WHERE id=$id AND owner=$owner"
                    [ "$id", box (string id); "$owner", box database.OwnerId ])
