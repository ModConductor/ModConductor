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
            let! root = access.Root workspace

            return
                root
                |> Result.defaultWith (fun _ ->
                    OutputRows.fail (
                        OutputError.Unavailable "The workspace folder is not available."
                    ))
        }

    let checkContext (database: StateDatabase) (scope: OutputScope) =
        task {
            let! state =
                database.Enqueue(fun () ->
                    let state =
                        OutputRows.game database.Connection null database.OwnerId scope.WorkspaceId

                    if OutputRows.contextId scope.WorkspaceId state <> scope.ContextId then
                        OutputRows.fail OutputError.Stale

                    state)

            let! evidence = Task.Run(fun () -> GameProcesses.validateContext state)
            return evidence
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
                OutputRows.fail (OutputError.Invalid "Use a new output location identity.")

            let! evidence = checkContext database expected
            let! root = root access expected.WorkspaceId

            match purpose with
            | OutputPurpose.WritableFile path ->
                OutputPolicy.path ModConductor.GameContexts.Skyrim.definition.TargetPolicy path
                |> Result.defaultWith OutputRows.fail
                |> ignore
            | OutputPurpose.ToolFolder -> ()

            let rootName = ".mod-conductor-output-" + id.ToString("N")

            let physical =
                HostPath.create (Path.Combine(HostPath.value root.Path, rootName))
                |> Result.defaultWith invalidOp

            let data = HostPath.create evidence.DataPath.Value |> Result.defaultWith invalidOp

            if SourceFiles.relative data physical |> Result.isOk then
                OutputRows.fail (
                    OutputError.Invalid "Output storage must be outside the game Data folder."
                )

            let! stored, fresh =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)

                    if not (OutputRows.current database.Connection transaction expected) then
                        OutputRows.fail OutputError.Stale

                    OutputRows.idle database.Connection transaction expected.WorkspaceId

                    let state =
                        OutputRows.game
                            database.Connection
                            transaction
                            database.OwnerId
                            expected.WorkspaceId

                    if OutputRows.contextId expected.WorkspaceId state <> expected.ContextId then
                        OutputRows.fail OutputError.Stale

                    let rows =
                        OutputRows.locations
                            database.Connection
                            transaction
                            root
                            expected.ContextId

                    let result =
                        match OutputRows.find database.Connection transaction root id with
                        | Some row when
                            row.View.ContextId = expected.ContextId
                            && row.View.Name = name
                            && row.View.Purpose = purpose
                            && row.RootIdentity.IsSome
                            ->
                            row, false
                        | Some _ ->
                            OutputRows.fail (
                                OutputError.Unavailable
                                    "This output folder creation did not complete or belongs to another request."
                            )
                        | None ->
                            if rows.Length >= OutputLimits.locations then
                                OutputRows.fail OutputError.LimitExceeded

                            let scope, _ =
                                OutputRows.scope
                                    database.Connection
                                    transaction
                                    database.OwnerId
                                    root
                                    (Some expected.ContextId)

                            let addedBytes =
                                512
                                + System.Text.Encoding.UTF8.GetByteCount name
                                + System.Text.Encoding.UTF8.GetByteCount(HostPath.value physical)
                                + (match purpose with
                                   | OutputPurpose.ToolFolder -> 0
                                   | OutputPurpose.WritableFile path ->
                                       System.Text.Encoding.UTF8.GetByteCount(
                                           LibraryEncoding.path path
                                       )
                                       * 2)

                            if
                                OutputPolicy.scopeBytes scope + addedBytes > OutputLimits.pageBytes
                            then
                                OutputRows.fail OutputError.LimitExceeded

                            match purpose with
                            | OutputPurpose.WritableFile path ->
                                let policy =
                                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy

                                for row in rows do
                                    match row.View.Purpose with
                                    | OutputPurpose.WritableFile previous when
                                        row.Enabled
                                        && (TargetPolicy.comparer policy)
                                            .Equals(
                                                TargetPolicy.key policy previous,
                                                TargetPolicy.key policy path
                                            )
                                        ->
                                        OutputRows.fail (
                                            OutputError.Invalid
                                                "This game file is already writable."
                                        )
                                    | _ -> ()
                            | OutputPurpose.ToolFolder -> ()

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
                                | OutputPurpose.WritableFile path ->
                                    1, box (LibraryEncoding.path path)

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

                            OutputRows.find database.Connection transaction root id |> Option.get,
                            true

                    transaction.Commit()
                    result)

            if not fresh then
                return stored.View
            else
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

    let stop (database: StateDatabase) (access: LibraryAccess) id revision =
        task {
            let! workspace =
                database.Enqueue(fun () ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT workspace_id FROM output_locations WHERE id=$id"
                            [ "$id", box (string id) ]

                    match query.ExecuteScalar() with
                    | :? string as workspace -> Guid.Parse workspace
                    | _ -> OutputRows.fail OutputError.NotFound)

            let! root = root access workspace

            return!
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)
                    OutputRows.idle database.Connection transaction workspace

                    let row =
                        OutputRows.find database.Connection transaction root id
                        |> Option.defaultWith (fun () -> OutputRows.fail OutputError.NotFound)

                    if row.View.Revision <> revision then
                        OutputRows.fail OutputError.Stale

                    if row.RootIdentity.IsNone then
                        OutputRows.fail OutputError.Busy

                    match row.View.Purpose with
                    | OutputPurpose.ToolFolder ->
                        OutputRows.fail (
                            OutputError.Invalid "This location is a tool output folder."
                        )
                    | OutputPurpose.WritableFile _ -> ()

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
                            [ "$workspace", box (string workspace)
                              "$context", box (string row.View.ContextId) ]

                    let result =
                        OutputRows.find database.Connection transaction root id |> Option.get

                    transaction.Commit()
                    result.View)
        }
