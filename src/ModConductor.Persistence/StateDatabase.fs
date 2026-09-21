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
        let abandonedFnisRuns =
            use command =
                Sqlite.command
                    connection
                    null
                    "SELECT id FROM fnis_runs WHERE owner=$owner AND busy=1"
                    [ "$owner", box owner ]

            use reader = command.ExecuteReader()

            [ while reader.Read() do
                  yield reader.GetString 0 ]

        OperationJournal.interruptOwner connection owner

        Sqlite.execute
            connection
            null
            "UPDATE bundle_work SET busy=0,problem='Bundle preparation stopped when the app closed. Review the next mod to continue.' WHERE owner=$owner AND busy<>0"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE archive_installations SET state=CASE WHEN state=0 THEN 1 ELSE state END,busy=0,problem=CASE WHEN state=0 AND target_revision IS NOT NULL THEN 'The app closed before the update finished. The previous version stays active.' WHEN state=0 THEN 'The app closed before installation finished. No mod was added.' ELSE problem END WHERE owner=$owner"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE mod_deletions SET busy=0,problem='Deletion stopped when the app closed. Continue deletion to finish.' WHERE owner=$owner AND busy=1"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE artifact_downloads SET state=3 WHERE state IN (0,1,2) AND artifact_id IN (SELECT id FROM artifacts WHERE owner=$owner)"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE artifacts SET busy=0 WHERE owner=$owner"
            [ "$owner", box owner ]

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
            "UPDATE mods SET status=4 WHERE id IN (SELECT mod_id FROM mod_versions WHERE owner=$owner AND phase IN (1,2)) AND NOT EXISTS(SELECT 1 FROM mod_deletion_targets t WHERE t.mod_id=mods.id); UPDATE mod_versions SET phase=CASE WHEN phase=1 THEN 4 ELSE phase END,busy=0 WHERE owner=$owner AND phase IN (1,2)"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE output_actions SET busy=0 WHERE owner=$owner"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE executable_runs SET phase=6,revision=revision+1 WHERE owner=$owner AND phase IN (0,1,2)"
            [ "$owner", box owner ]

        Sqlite.execute
            connection
            null
            "UPDATE fnis_runs SET phase=7,busy=0,problem='FNIS stopped when the app closed. The previous generated output remains active.',completed_at=$completed WHERE owner=$owner AND busy=1"
            [ "$owner", box owner; "$completed", box (DateTimeOffset.UtcNow.ToString("O")) ]

        for run in abandonedFnisRuns do
            let path = Path.Combine(directory, "fnis-runs", Guid.Parse(run).ToString("N"))

            try
                if Directory.Exists path then
                    Directory.Delete(path, true)
            with
            | :? IOException
            | :? UnauthorizedAccessException -> ()

        Sqlite.execute
            connection
            null
            "UPDATE profile_data_actions SET busy=0 WHERE owner=$owner"
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

            Sqlite.initialize connection
            OwnerLease.recover owners ownerId abandonOwner

            Sqlite.execute
                connection
                null
                "DELETE FROM skse_replacement_intents WHERE NOT EXISTS(SELECT 1 FROM deployment_receipts WHERE id=receipt_id)"
                []

            Sqlite.execute
                connection
                null
                "DELETE FROM fnis_publication_intents WHERE NOT EXISTS(SELECT 1 FROM deployment_receipts WHERE id=receipt_id)"
                []
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
