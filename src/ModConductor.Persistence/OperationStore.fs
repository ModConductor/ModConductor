namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Channels
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Operations

type OperationStore(directory: string) =
    let owners = Path.Combine(directory, "owners")
    let ownerId, ownerPath, lease = OwnerLease.reserve owners

    let settings =
        SqliteConnectionStringBuilder(
            DataSource = Path.Combine(directory, "state.db"),
            Pooling = false,
            DefaultTimeout = 1
        )

    let connection = new SqliteConnection(settings.ConnectionString)

    let queue =
        Channel.CreateBounded<Action>(BoundedChannelOptions(64, SingleReader = true))

    let state transaction =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT revision,cursor FROM operation_state WHERE id=1"
                []

        use reader = statement.ExecuteReader()
        reader.Read() |> ignore
        reader.GetInt64 0, reader.GetInt64 1

    let find transaction id =
        OperationRows.list
            connection
            transaction
            ("SELECT " + OperationRows.columns + " FROM operations WHERE id=$id")
            [ "$id", box id ]
        |> List.tryHead

    let save transaction snapshot =
        Sqlite.execute
            connection
            transaction
            "UPDATE operation_state SET cursor=cursor+1 WHERE id=1"
            []

        let _, cursor = state transaction
        let parameters = OperationRows.parameters snapshot

        Sqlite.execute
            connection
            transaction
            "UPDATE operations SET phase=$phase,progress=$progress,architecture=$architecture,native_aot=$native, sqlite_version=$sqlite,result_revision=$resultRevision,last_cursor=$cursor WHERE id=$id"
            (("$cursor", box cursor) :: parameters)

        Sqlite.execute
            connection
            transaction
            "INSERT INTO operation_events(cursor,id,expected_revision,count,phase,progress,architecture,native_aot,sqlite_version,result_revision) VALUES($cursor,$id,$expected,$count,$phase,$progress,$architecture,$native,$sqlite,$resultRevision)"
            (("$cursor", box cursor) :: parameters)

        Sqlite.execute
            connection
            transaction
            "DELETE FROM operation_events WHERE cursor <= $oldest"
            [ "$oldest", box (cursor - 128L) ]

    let interruptOwner owner =
        use transaction = connection.BeginTransaction(deferred = false)

        let pending =
            OperationRows.list
                connection
                transaction
                ("SELECT "
                 + OperationRows.columns
                 + " FROM operations WHERE owner=$owner AND phase=1")
                [ "$owner", box owner ]

        for snapshot in pending do
            save transaction { snapshot with Phase = Interrupted }

        transaction.Commit()

    do
        try
            SQLitePCL.Batteries_V2.Init()
            connection.Open()
            Sqlite.migrate connection
            OwnerLease.recover owners ownerId interruptOwner
        with _ ->
            connection.Dispose()
            File.Delete ownerPath
            lease.Dispose()
            reraise ()

    let worker =
        Task.Run(
            Func<Task>(fun () ->
                task {
                    let mutable reading = true

                    while reading do
                        let! available = queue.Reader.WaitToReadAsync().AsTask()

                        if not available then
                            reading <- false
                        else
                            let mutable command = Unchecked.defaultof<Action>

                            while queue.Reader.TryRead(&command) do
                                command.Invoke()
                }
                :> Task)
        )

    let enqueue (action: unit -> 'T) =
        let completion =
            TaskCompletionSource<'T>(TaskCreationOptions.RunContinuationsAsynchronously)

        if
            not (
                queue.Writer.TryWrite(
                    Action(fun () ->
                        try
                            completion.SetResult(action ())
                        with error ->
                            completion.SetException(error))
                )
            )
        then
            completion.SetException(CapacityException())

        completion.Task

    let enqueueInternal (action: unit -> 'T) =
        task {
            let completion =
                TaskCompletionSource<'T>(TaskCreationOptions.RunContinuationsAsynchronously)

            let command =
                Action(fun () ->
                    try
                        completion.SetResult(action ())
                    with error ->
                        completion.SetException(error))

            do! queue.Writer.WriteAsync(command).AsTask()
            return! completion.Task
        }

    let feed initial requested =
        use transaction = connection.BeginTransaction(deferred = true)
        let revision, cursor = state transaction

        let gap =
            requested
            |> Option.exists (fun after -> after < max 0L (cursor - 128L) || after > cursor)

        let result =
            if initial || gap then
                { Cursor = cursor
                  Revision = revision
                  ResyncRequired = gap
                  Snapshot =
                    Some(
                        OperationRows.list
                            connection
                            transaction
                            ("SELECT "
                             + OperationRows.columns
                             + " FROM operations ORDER BY last_cursor DESC LIMIT 16")
                            []
                    )
                  Changes = [] }
            else
                let after = requested |> Option.defaultValue cursor

                use statement =
                    Sqlite.command
                        connection
                        transaction
                        ("SELECT "
                         + OperationRows.columns
                         + ",cursor FROM operation_events WHERE cursor>$after ORDER BY cursor LIMIT 16")
                        [ "$after", box after ]

                use reader = statement.ExecuteReader()

                let changes =
                    [ while reader.Read() do
                          yield
                              { Cursor = reader.GetInt64 9
                                Operation = OperationRows.read reader } ]

                { Cursor =
                    changes
                    |> List.tryLast
                    |> Option.map (fun change -> change.Cursor)
                    |> Option.defaultValue after
                  Revision = revision
                  ResyncRequired = false
                  Snapshot = None
                  Changes = changes }

        transaction.Commit()
        result

    member _.SqliteVersion = connection.ServerVersion

    interface IOperationStore with
        member _.Begin(request) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction request.Id with
                    | Some snapshot when snapshot.Request = request -> Ok(snapshot, false)
                    | Some _ -> Error IdentityConflict
                    | None ->
                        let revision, _ = state transaction

                        if revision <> request.ExpectedRevision then
                            Error StaleRevision
                        elif
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM operations WHERE phase=1"
                                []
                            >= 16L
                        then
                            Error Capacity
                        else
                            let snapshot =
                                { Request = request
                                  Phase = Running
                                  Progress = 0
                                  Result = None
                                  ResultRevision = 0L }

                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO operations(id,owner,expected_revision,count,phase,progress,result_revision,last_cursor) VALUES($id,$owner,$expected,$count,1,0,0,0)"
                                [ "$id", box request.Id
                                  "$owner", box ownerId
                                  "$expected", box request.ExpectedRevision
                                  "$count", box request.Count ]

                            save transaction snapshot
                            Ok(snapshot, true)

                transaction.Commit()
                result)

        member _.Advance(id, progress, runtime) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = find transaction id |> Option.get

                let snapshot =
                    if current.Phase <> Running then
                        current
                    elif progress = current.Request.Count then
                        let revision, _ = state transaction

                        if revision <> current.Request.ExpectedRevision then
                            { current with
                                Phase = Stale
                                Progress = progress }
                        else
                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE operation_state SET revision=revision+1 WHERE id=1"
                                []

                            { current with
                                Phase = Completed
                                Progress = progress
                                Result = Some runtime
                                ResultRevision = revision + 1L }
                    else
                        { current with Progress = progress }

                if snapshot <> current then
                    save transaction snapshot

                transaction.Commit()
                snapshot)

        member _.Cancel(id) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction id with
                    | None -> Error NotFound
                    | Some snapshot when snapshot.Phase = Running ->
                        let cancelled = { snapshot with Phase = Cancelled }
                        save transaction cancelled
                        Ok cancelled
                    | Some snapshot -> Ok snapshot

                transaction.Commit()
                result)

        member _.Get(id) =
            enqueue (fun () ->
                find null id |> Option.map Ok |> Option.defaultValue (Error NotFound))

        member _.InitialFeed(cursor) = enqueue (fun () -> feed true cursor)

        member _.Changes(cursor) =
            enqueue (fun () -> feed false (Some cursor))

        member _.Interrupt(id) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                match find transaction id with
                | Some snapshot when snapshot.Phase = Running ->
                    save transaction { snapshot with Phase = Interrupted }
                | Some _
                | None -> ()

                transaction.Commit())

    interface IDisposable with
        member _.Dispose() =
            queue.Writer.TryComplete() |> ignore
            worker.GetAwaiter().GetResult()

            try
                interruptOwner ownerId
                File.Delete ownerPath
            finally
                lease.Dispose()
                connection.Dispose()
