namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Channels
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Operations

type internal StateDatabase(directory: string) =
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

    let abandonOwner owner =
        OperationJournal.interruptOwner connection owner

        Sqlite.execute
            connection
            null
            "UPDATE deployment_receipts SET abandoned=1,busy=0 WHERE owner=$owner AND phase NOT IN (2,3)"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE root_creation_receipts SET abandoned=1,busy=0 WHERE owner=$owner AND phase<>3"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE mods SET status=4 WHERE id IN (SELECT mod_id FROM mod_versions WHERE owner=$owner AND phase IN (1,2)); UPDATE mod_versions SET phase=CASE WHEN phase=1 THEN 4 ELSE phase END,busy=0 WHERE owner=$owner AND phase IN (1,2)"
            [ "$owner", box owner ]

    do
        try
            SQLitePCL.Batteries_V2.Init()
            connection.Open()

            connection.CreateCollation(
                "MC_NAME",
                (fun left right ->
                    ModConductor.ModOrganization.OrganizationPolicy.compareNames left right)
            )

            connection.CreateFunction<string, string, bool>(
                "mc_contains",
                fun value query ->
                    ModConductor.ModOrganization.OrganizationPolicy.contains value query
            )

            Sqlite.migrate connection
            OwnerLease.recover owners ownerId abandonOwner
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

    member _.OwnerId = ownerId
    member _.Connection = connection
    member _.Enqueue action = enqueue action
    member _.EnqueueInternal action = enqueueInternal action

    interface IDisposable with
        member _.Dispose() =
            queue.Writer.TryComplete() |> ignore
            worker.GetAwaiter().GetResult()

            try
                abandonOwner ownerId
                File.Delete ownerPath
            finally
                lease.Dispose()
                connection.Dispose()
