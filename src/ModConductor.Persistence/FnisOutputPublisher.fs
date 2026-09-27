namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.Platform

type internal FnisOutputPublisher
    (database: StateDatabase, access: LibraryAccess, publication: LibraryPublication) =
    let input = FnisInputInspection.read database
    let outputId = FnisRunRows.outputId

    let mapLibrary =
        function
        | LibraryError.Busy -> FnisExecutionError.Busy
        | LibraryError.Cancelled -> FnisExecutionError.Cancelled
        | LibraryError.StaleRevision
        | LibraryError.SourceChanged -> FnisExecutionError.Stale
        | LibraryError.IdentityConflict -> FnisExecutionError.IdentityConflict
        | LibraryError.NotFound -> FnisExecutionError.NotFound
        | LibraryError.LimitExceeded ->
            FnisExecutionError.Invalid "The generated FNIS output exceeds its file limit."
        | LibraryError.InvalidMetadata
        | LibraryError.InvalidSource
        | LibraryError.UnsupportedAction ->
            FnisExecutionError.Invalid "The generated FNIS output is invalid."
        | LibraryError.UnprovedOwnership
        | LibraryError.FileUnavailable ->
            FnisExecutionError.Unavailable "The generated FNIS output could not be saved."



    member _.Publish
        (
            run: FnisRunStage,
            exitCode,
            stdout: byte array,
            stderr: byte array,
            runLog: byte array,
            token: CancellationToken
        ) =
        task {
            let root =
                match HostPath.create run.Directory with
                | Error _ -> raise (IOException "The FNIS output stage is unavailable.")
                | Ok path ->
                    RootSelection.select path
                    |> Result.defaultWith (fun _ ->
                        raise (IOException "The FNIS output stage is unavailable."))

            let identity =
                match RootSelection.facts root with
                | { File = Observation.Known value } -> value
                | _ -> raise (IOException "The FNIS output stage identity is unavailable.")

            let rootPath = RootSelection.path root
            use held = HeldDirectory.Open(rootPath, identity)

            let scanned =
                SourceFiles.scan held Set.empty 100000 (fun () ->
                    token.ThrowIfCancellationRequested())

            match scanned with
            | Error error -> return Error(FnisExecutionError.SourceInspectionFailed error.Message)
            | Ok(files, _) when files.IsEmpty ->
                return Error(FnisExecutionError.Invalid "FNIS produced no generated files.")
            | Ok(files, _) when files |> List.sumBy _.Length > 2L * 1024L * 1024L * 1024L ->
                return Error(FnisExecutionError.Invalid "The generated FNIS output exceeds 2 GiB.")
            | Ok(files, _) ->
                let! prepared =
                    database.Enqueue(fun () ->
                        use transaction = database.Connection.BeginTransaction(deferred = false)

                        input
                            database.Connection
                            transaction
                            run.Request.WorkspaceId
                            run.Request.ProfileId
                        |> Result.mapError FnisExecutionError.SourceInspectionFailed
                        |> Result.map (fun (_, _, selectionRevision) ->
                            let output = outputId run.Request.ProfileId
                            let row = LibraryRows.find database.Connection transaction output

                            let entry, created =
                                match row with
                                | Some row when row.Entry.WorkspaceId = run.Request.WorkspaceId ->
                                    row.Entry, false
                                | Some _ ->
                                    raise (
                                        InvalidDataException
                                            "The FNIS output identity is already in use."
                                    )
                                | None ->
                                    (InventoryOutput.createFnisOutput
                                        database.Connection
                                        transaction
                                        run.Request.WorkspaceId
                                        output
                                        { Name = "FNIS generated output"
                                          Notes = "Managed by Run FNIS."
                                          Comment = ""
                                          Version =
                                            DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss")
                                          Source = ""
                                          Categories = [] }),
                                    true

                            Sqlite.execute
                                database.Connection
                                transaction
                                "UPDATE fnis_runs SET expected_selection_revision=$revision WHERE id=$id AND owner=$owner AND busy=1"
                                [ "$revision", box selectionRevision
                                  "$id", box (string run.Request.Id)
                                  "$owner", box database.OwnerId ]

                            transaction.Commit()

                            entry.Revision,
                            selectionRevision,
                            entry.CurrentVersion,
                            entry.Metadata.Version,
                            created))

                match prepared with
                | Error error -> return Error error
                | Ok(expectedRevision, expectedSelection, sourceVersion, sourceLabel, createdOutput) ->

                    let inputFiles: CompositionFile list =
                        files
                        |> List.map (fun file ->
                            { Target = file.Path
                              Root = rootPath
                              RootIdentity = identity
                              File = file })

                    let composition: LibraryCompositionInput =
                        { ActionId = run.Request.Id
                          SourceVersion = sourceVersion
                          VersionLabel = DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss")
                          Policy = Skyrim.definition.TargetPolicy
                          Files = inputFiles
                          Bytes = [] }

                    let! version =
                        database.Enqueue(fun () ->
                            use command =
                                Sqlite.command
                                    database.Connection
                                    null
                                    "SELECT output_version_id FROM fnis_runs WHERE id=$id"
                                    [ "$id", box (string run.Request.Id) ]

                            Guid.Parse(command.ExecuteScalar() :?> string))

                    let mutable inputError = None

                    let! published =
                        access.Run(fun () ->
                            publication.ComposeFinalized(
                                outputId run.Request.ProfileId,
                                expectedRevision,
                                version,
                                composition,
                                token,
                                (fun connection transaction entry ->
                                    match
                                        input
                                            connection
                                            transaction
                                            run.Request.WorkspaceId
                                            run.Request.ProfileId
                                    with
                                    | Error detail ->
                                        inputError <- Some detail
                                        Error LibraryError.StaleRevision
                                    | Ok(current, _, selectionRevision) when
                                        selectionRevision <> expectedSelection
                                        || current <> run.Fingerprint
                                        ->
                                        Error LibraryError.StaleRevision
                                    | Ok _ ->
                                        Sqlite.execute
                                            connection
                                            transaction
                                            "UPDATE mods SET current_version=$previous,revision=$revision,version_text=$label WHERE id=$mod AND current_version=$candidate"
                                            [ "$previous",
                                              sourceVersion
                                              |> Option.map (string >> box)
                                              |> Option.defaultValue (box DBNull.Value)
                                              "$revision", box expectedRevision
                                              "$label", box sourceLabel
                                              "$mod",
                                              box (string (outputId run.Request.ProfileId))
                                              "$candidate",
                                              box (string entry.CurrentVersion.Value) ]

                                        Sqlite.execute
                                            connection
                                            transaction
                                            "UPDATE fnis_runs SET exit_code=$exit,stdout=$stdout,stderr=$stderr,run_log=$log WHERE id=$id AND owner=$owner AND busy=1"
                                            [ "$exit", box exitCode
                                              "$stdout", box stdout
                                              "$stderr", box stderr
                                              "$log", box runLog
                                              "$id", box (string run.Request.Id)
                                              "$owner", box database.OwnerId ]

                                        Ok())
                            ))

                    match published with
                    | Error error ->
                        if createdOutput then
                            do!
                                database.EnqueueInternal(fun () ->
                                    use transaction =
                                        database.Connection.BeginTransaction(deferred = false)

                                    let output = outputId run.Request.ProfileId

                                    let removable =
                                        Sqlite.number
                                            database.Connection
                                            transaction
                                            "SELECT count(*) FROM mods WHERE id=$mod AND current_version IS NULL AND NOT EXISTS(SELECT 1 FROM mod_versions WHERE mod_id=$mod) AND NOT EXISTS(SELECT 1 FROM fnis_outputs WHERE mod_id=$mod)"
                                            [ "$mod", box (string output) ] = 1L

                                    if removable then
                                        Sqlite.execute
                                            database.Connection
                                            transaction
                                            "DELETE FROM profile_mods WHERE mod_id=$mod; DELETE FROM mods WHERE id=$mod; UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace"
                                            [ "$mod", box (string output)
                                              "$workspace", box (string run.Request.WorkspaceId) ]

                                    transaction.Commit())

                        return
                            Error(
                                match inputError with
                                | Some detail -> FnisExecutionError.SourceInspectionFailed detail
                                | None -> mapLibrary error
                            )
                    | Ok _ -> return Ok()
        }
