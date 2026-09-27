namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.GeneratedOutputs
open ModConductor.Deployment

module internal OutputLocationCommands =
    let root (access: LibraryAccess) workspace =
        task {
            let! value = access.Root workspace

            return
                value
                |> Result.mapError (fun _ ->
                    OutputError.Unavailable "The workspace folder is not available.")
        }

    let checkContext (database: StateDatabase) (scope: OutputScope) =
        task {
            let! selected =
                database.Enqueue(fun () ->
                    OutputRows.boundContext
                        database.Connection
                        null
                        database.OwnerId
                        scope.WorkspaceId
                        scope.ProfileId
                    |> Result.bind (fun (state, context) ->
                        if context = scope.ContextId then
                            Ok state
                        else
                            Error OutputError.Stale))

            match selected with
            | Error error -> return Error error
            | Ok state ->
                let! evidence = Task.Run(fun () -> GameProcesses.validateContext state)
                return Ok evidence
        }

    let private purposeValid =
        function
        | OutputPurpose.ToolFolder -> Ok()
        | OutputPurpose.WritableFile path ->
            OutputPolicy.path ModConductor.GameContexts.Skyrim.definition.TargetPolicy path
            |> Result.map ignore

    let private physicalPath (root: WorkspaceRoot) rootName evidence =
        let physical =
            HostPath.create (Path.Combine(HostPath.value root.Path, rootName))
            |> Result.defaultWith invalidOp

        let data = HostPath.create evidence.DataPath.Value |> Result.defaultWith invalidOp

        if SourceFiles.relative data physical |> Result.isOk then
            Error(OutputError.Invalid "Output storage must be outside the game Data folder.")
        else
            Ok physical

    let private addedBytes name physical purpose =
        512
        + System.Text.Encoding.UTF8.GetByteCount name
        + System.Text.Encoding.UTF8.GetByteCount(HostPath.value physical)
        + (match purpose with
           | OutputPurpose.ToolFolder -> 0
           | OutputPurpose.WritableFile path ->
               System.Text.Encoding.UTF8.GetByteCount(LibraryEncoding.path path) * 2)

    let private checkWritable rows purpose =
        match purpose with
        | OutputPurpose.ToolFolder -> Ok()
        | OutputPurpose.WritableFile path ->
            let policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy

            let conflict row =
                match row.View.Purpose with
                | OutputPurpose.WritableFile previous when row.Enabled ->
                    (TargetPolicy.comparer policy)
                        .Equals(TargetPolicy.key policy previous, TargetPolicy.key policy path)
                | _ -> false

            if List.exists conflict rows then
                Error(OutputError.Invalid "This game file is already writable.")
            else
                Ok()

    let private insert
        (database: StateDatabase)
        transaction
        (root: WorkspaceRoot)
        expected
        name
        purpose
        id
        rootName
        evidence
        =
        Sqlite.execute
            database.Connection
            transaction
            "INSERT INTO output_contexts(workspace_id,id,game_path,revision) VALUES($workspace,$context,$game,0) ON CONFLICT(workspace_id,id) DO NOTHING"
            [ "$workspace", box (string root.Id)
              "$context", box (string expected.ContextId)
              "$game", box evidence.RootPath ]

        let kind, path =
            match purpose with
            | OutputPurpose.ToolFolder -> 0, box DBNull.Value
            | OutputPurpose.WritableFile path -> 1, box (LibraryEncoding.path path)

        Sqlite.execute
            database.Connection
            transaction
            "INSERT INTO output_locations(id,workspace_id,context_id,name,purpose,target,revision,enabled,initialized,root_name) VALUES($id,$workspace,$context,$name,$purpose,$target,0,1,0,$root)"
            [ "$id", box (string id)
              "$workspace", box (string root.Id)
              "$context", box (string expected.ContextId)
              "$name", box name
              "$purpose", box kind
              "$target", path
              "$root", box rootName ]

        Sqlite.execute
            database.Connection
            transaction
            "UPDATE output_contexts SET revision=revision+1 WHERE workspace_id=$workspace AND id=$context"
            [ "$workspace", box (string root.Id)
              "$context", box (string expected.ContextId) ]

        OutputRows.find database.Connection transaction root id |> Option.get, true

    let private create
        (database: StateDatabase)
        transaction
        (root: WorkspaceRoot)
        expected
        name
        purpose
        id
        rootName
        evidence
        physical
        rows
        =
        if rows.Length >= OutputLimits.locations then
            Error OutputError.LimitExceeded
        else
            OutputRows.scope
                database.Connection
                transaction
                database.OwnerId
                root
                expected.ProfileId
                (Some expected.ContextId)
            |> Result.bind (fun (scope, _) ->
                if
                    OutputPolicy.scopeBytes scope + addedBytes name physical purpose > OutputLimits.pageBytes
                then
                    Error OutputError.LimitExceeded
                else
                    checkWritable rows purpose)
            |> Result.map (fun () ->
                insert database transaction root expected name purpose id rootName evidence)

    let private addInTransaction
        (database: StateDatabase)
        (root: WorkspaceRoot)
        expected
        name
        purpose
        id
        rootName
        evidence
        physical
        =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let choose () =
            let rows =
                OutputRows.locations database.Connection transaction root expected.ContextId

            match OutputRows.find database.Connection transaction root id with
            | Some row when
                row.View.ContextId = expected.ContextId
                && row.View.Name = name
                && row.View.Purpose = purpose
                && row.RootIdentity.IsSome
                ->
                Ok(row, false)
            | Some _ ->
                Error(
                    OutputError.Unavailable
                        "This output folder creation did not complete or belongs to another request."
                )
            | None ->
                create
                    database
                    transaction
                    root
                    expected
                    name
                    purpose
                    id
                    rootName
                    evidence
                    physical
                    rows

        let result =
            if not (OutputRows.current database.Connection transaction expected) then
                Error OutputError.Stale
            else
                OutputRows.idle database.Connection transaction expected.WorkspaceId
                |> Result.bind (fun () ->
                    OutputRows.boundContext
                        database.Connection
                        transaction
                        database.OwnerId
                        expected.WorkspaceId
                        expected.ProfileId
                    |> Result.bind (fun (_, context) ->
                        if context = expected.ContextId then
                            choose ()
                        else
                            Error OutputError.Stale))

        if Result.isOk result then
            transaction.Commit()

        result

    let private confirm (database: StateDatabase) (root: WorkspaceRoot) id purpose rootName =
        task {
            let! identity =
                Task.Run(fun () ->
                    use parent = HeldDirectory.Open(root.Path, root.Identity)
                    use folder = parent.CreateDirectory rootName
                    folder.Identity)

            return!
                database.EnqueueInternal(fun () ->
                    Sqlite.execute
                        database.Connection
                        null
                        "UPDATE output_locations SET root_identity=$identity,initialized=$initialized WHERE id=$id AND root_identity IS NULL"
                        [ "$identity", box (LibraryEncoding.identity identity)
                          "$initialized", box (purpose = OutputPurpose.ToolFolder)
                          "$id", box (string id) ]

                    (OutputRows.find database.Connection null root id |> Option.get).View)
        }

    let add
        (database: StateDatabase)
        (access: LibraryAccess)
        id
        (expected: OutputScope)
        name
        purpose
        =
        task {
            if id = Guid.Empty then
                return Error(OutputError.Invalid "Use a new output location identity.")
            else
                let! selected = checkContext database expected

                match selected with
                | Error error -> return Error error
                | Ok evidence ->
                    let! workspace = root access expected.WorkspaceId

                    match workspace with
                    | Error error -> return Error error
                    | Ok root ->
                        match purposeValid purpose with
                        | Error error -> return Error error
                        | Ok() ->
                            let rootName = ".mod-conductor-output-" + id.ToString("N")

                            match physicalPath root rootName evidence with
                            | Error error -> return Error error
                            | Ok physical ->
                                let! stored =
                                    database.Enqueue(fun () ->
                                        addInTransaction
                                            database
                                            root
                                            expected
                                            name
                                            purpose
                                            id
                                            rootName
                                            evidence
                                            physical)

                                match stored with
                                | Error error -> return Error error
                                | Ok(row, false) -> return Ok row.View
                                | Ok(_, true) ->
                                    let! created = confirm database root id purpose rootName
                                    return Ok created
        }

    let private workspace (database: StateDatabase) id =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT workspace_id FROM output_locations WHERE id=$id"
                    [ "$id", box (string id) ]

            match query.ExecuteScalar() with
            | :? string as workspace -> Ok(Guid.Parse workspace)
            | _ -> Error OutputError.NotFound)

    let private stopInTransaction (database: StateDatabase) (root: WorkspaceRoot) id revision =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let stopRow row =
            if row.View.Revision <> revision then
                Error OutputError.Stale
            elif row.RootIdentity.IsNone then
                Error OutputError.Busy
            else
                match row.View.Purpose with
                | OutputPurpose.ToolFolder ->
                    Error(OutputError.Invalid "This location is a tool output folder.")
                | OutputPurpose.WritableFile _ ->
                    if row.Enabled then
                        Sqlite.execute
                            database.Connection
                            transaction
                            "UPDATE output_locations SET enabled=0,revision=revision+1 WHERE id=$id"
                            [ "$id", box (string id) ]

                        Sqlite.execute
                            database.Connection
                            transaction
                            "UPDATE output_contexts SET revision=revision+1 WHERE workspace_id=$workspace AND id=$context"
                            [ "$workspace", box (string root.Id)
                              "$context", box (string row.View.ContextId) ]

                    Ok((OutputRows.find database.Connection transaction root id |> Option.get).View)

        let result =
            OutputRows.idle database.Connection transaction root.Id
            |> Result.bind (fun () ->
                OutputRows.find database.Connection transaction root id
                |> Option.map stopRow
                |> Option.defaultValue (Error OutputError.NotFound))

        if Result.isOk result then
            transaction.Commit()

        result

    let stop (database: StateDatabase) (access: LibraryAccess) id revision =
        task {
            let! found = workspace database id

            match found with
            | Error error -> return Error error
            | Ok workspace ->
                let! selected = root access workspace

                match selected with
                | Error error -> return Error error
                | Ok root ->
                    return! database.Enqueue(fun () -> stopInTransaction database root id revision)
        }
