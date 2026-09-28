namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Engine
open ModConductor.Protocol.V1
open Microsoft.Data.Sqlite
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Operations

module StorageFixtures =
    type private CountingOperations(inner: IOperationStore) =
        let mutable initial = 0
        let mutable changes = 0
        let mutable waits = 0
        member _.Initial = Volatile.Read(&initial)
        member _.Changes = Volatile.Read(&changes)
        member _.Waits = Volatile.Read(&waits)

        interface IOperationStore with
            member _.Begin value = inner.Begin value
            member _.Advance(id, progress, runtime) = inner.Advance(id, progress, runtime)
            member _.Cancel id = inner.Cancel id
            member _.Get id = inner.Get id

            member _.InitialFeed after =
                Interlocked.Increment(&initial) |> ignore
                inner.InitialFeed after

            member _.Changes cursor =
                Interlocked.Increment(&changes) |> ignore
                inner.Changes cursor

            member _.WaitForChanges(cursor, token) =
                Interlocked.Increment(&waits) |> ignore
                inner.WaitForChanges(cursor, token)

            member _.Interrupt id = inner.Interrupt id

    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private select = StorageWorker.select

    let private phase =
        function
        | RootCreationPhase.Intent -> "intent"
        | RootCreationPhase.Observed -> "observed"
        | RootCreationPhase.Complete -> "complete"
        | RootCreationPhase.Unresolved -> "unresolved"

    let private receipt (writer: Utf8JsonWriter) (value: RootCreationReceipt) =
        writer.WriteString("phase", phase value.Phase)
        writer.WriteNumber("workspaceRevision", value.Workspace.Revision)
        writer.WriteNumber("receiptRevision", value.Revision)
        writer.WriteString("root", HostPath.value value.Workspace.Path)
        writer.WriteString("detail", value.Detail)
        writer.WriteStartObject("rootIdentity")

        Report.identity
            writer
            { File = Known value.Workspace.Identity
              Mount = Unknown "Not stored"
              Kind = EntryKind.Directory }

        writer.WriteEndObject()

        match value.MarkerIdentity with
        | None -> writer.WriteNull "markerIdentity"
        | Some id ->
            writer.WriteStartObject("markerIdentity")

            Report.identity
                writer
                { File = Known id
                  Mount = Unknown "Not stored"
                  Kind = EntryKind.RegularFile }

            writer.WriteEndObject()

    let private number state sql =
        use connection =
            new SqliteConnection(
                "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
            )

        connection.Open()
        Sqlite.number connection null sql []

    let private area directory name =
        let parent = Directory.CreateDirectory(Path.Combine(directory, name)).FullName
        let state = Directory.CreateDirectory(Path.Combine(parent, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(parent, "root")).FullName
        state, root, Guid.NewGuid()

    let private worker mode state root (id: Guid) =
        new NativeChild(
            Environment.ProcessPath,
            [ "--storage-worker"; mode; state; root; id.ToString() ]
        )

    let private observeSchema (writer: Utf8JsonWriter) directory =
        writer.WriteStartObject("schema")
        let state, _, _ = area directory "schema"

        do
            use store = new OperationStore(state)
            StorageWorker.runtime store "11111111-1111-1111-1111-111111111111" 0L |> ignore

        writer.WriteNumber("version", number state "PRAGMA user_version")
        writer.WriteNumber("applicationId", number state "PRAGMA application_id")

        writer.WriteNumber(
            "tables",
            number
                state
                "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )

        writer.WriteNumber(
            "indexes",
            number
                state
                "SELECT count(*) FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'"
        )

        writer.WriteNumber(
            "triggers",
            number
                state
                "SELECT count(*) FROM sqlite_master WHERE type='trigger' AND name NOT LIKE 'sqlite_%'"
        )

        writer.WriteNumber(
            "foreignKeyFailures",
            number state "SELECT count(*) FROM pragma_foreign_key_check"
        )

        let interrupted, _, _ = area directory "schema-interrupted"
        let mutable rolledBack = false

        do
            use connection =
                new SqliteConnection(
                    "Data Source=" + Path.Combine(interrupted, "state.db") + ";Pooling=False"
                )

            connection.Open()

            try
                Sqlite.initializeAtCommit connection (fun () -> invalidOp "Stop before commit.")
            with :? InvalidOperationException ->
                rolledBack <- true

        writer.WriteBoolean(
            "initializationRollback",
            rolledBack
            && number interrupted "PRAGMA user_version" = 0L
            && number
                interrupted
                "SELECT count(*) FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'" = 0L
        )

        let unsupported, _, _ = area directory "schema-unsupported"

        do
            use connection =
                new SqliteConnection(
                    "Data Source=" + Path.Combine(unsupported, "state.db") + ";Pooling=False"
                )

            connection.Open()

            Sqlite.execute
                connection
                null
                "CREATE TABLE development_state(value INTEGER); INSERT INTO development_state VALUES(42); PRAGMA user_version=1;"
                []

        let unsupportedDatabase = Path.Combine(unsupported, "state.db")
        let unchangedTime = DateTime(2020, 1, 2, 3, 4, 5, DateTimeKind.Utc)
        File.SetLastWriteTimeUtc(unsupportedDatabase, unchangedTime)
        let unsupportedBytes = File.ReadAllBytes unsupportedDatabase

        let unsupportedEntries =
            Directory.GetFileSystemEntries unsupported
            |> Array.map Path.GetFileName
            |> Array.sort

        let mutable resetInstruction = false

        try
            use _ = new OperationStore(unsupported)
            ()
        with :? InvalidOperationException as error ->
            resetInstruction <- error.Message.Contains("Delete the Mod Conductor state directory")

        writer.WriteBoolean(
            "unsupportedRefusedWithoutMutation",
            resetInstruction
            && File.ReadAllBytes unsupportedDatabase = unsupportedBytes
            && File.GetLastWriteTimeUtc unsupportedDatabase = unchangedTime
            && (Directory.GetFileSystemEntries unsupported
                |> Array.map Path.GetFileName
                |> Array.sort) = unsupportedEntries
            && not (Directory.Exists(Path.Combine(unsupported, "owners")))
            && not (File.Exists(unsupportedDatabase + "-wal"))
            && not (File.Exists(unsupportedDatabase + "-shm"))
        )

        do
            use _ = new OperationStore(state)
            writer.WriteBoolean("restartCurrent", true)

        writer.WriteEndObject()

    let private observeLifecycle (writer: Utf8JsonWriter) directory =
        writer.WriteStartObject("lifecycle")
        let state, root, id = area directory "lifecycle"
        let mutable completed = Unchecked.defaultof<RootCreationReceipt>

        do
            use store = new OperationStore(state)
            let roots = store.WorkspaceRoots

            writer.WriteBoolean(
                "stalePrepare",
                roots.Prepare(id, 1L, select root) |> wait = Error WorkspaceFailure.StaleRevision
            )

            let prepared = roots.Prepare(id, 0L, select root) |> wait |> result

            writer.WriteBoolean(
                "staleApply",
                roots.Apply(id, prepared.Revision - 1L) |> wait =
                    Error WorkspaceFailure.StaleRevision
            )

            let applied = roots.Apply(id, prepared.Revision) |> wait |> result

            writer.WriteBoolean(
                "staleComplete",
                roots.Complete(id, prepared.Revision) |> wait = Error WorkspaceFailure.StaleRevision
            )

            completed <- roots.Complete(id, applied.Revision) |> wait |> result

            writer.WriteBoolean(
                "replayUnchanged",
                roots.Prepare(id, 0L, select root) |> wait |> result = completed
            )

            receipt writer completed

        do
            use store = new OperationStore(state)

            writer.WriteBoolean(
                "restartUnchanged",
                store.WorkspaceRoots.Get id |> wait = Some completed
            )

        writer.WriteEndObject()

    let private observeRecovery (writer: Utf8JsonWriter) directory =
        for scenario in [ "intent"; "effect"; "observed"; "changed"; "replaced" ] do
            let state, root, id = area directory scenario

            use child =
                worker
                    (if scenario = "changed" || scenario = "replaced" then
                         "observed"
                     else
                         scenario)
                    state
                    root
                    id

            child.Line() |> ignore
            child.Terminate()
            let marker = Path.Combine(root, RootIdentityFile.name)

            let original =
                if File.Exists marker then
                    Some(File.ReadAllBytes marker)
                else
                    None

            if scenario = "changed" then
                File.WriteAllText(marker, "foreign change")
            elif scenario = "replaced" then
                File.Move(marker, marker + "-original")
                File.WriteAllBytes(marker, original.Value)

            use store = new OperationStore(state)
            let roots = store.WorkspaceRoots
            let before = roots.Get id |> wait |> Option.get
            let pending = roots.Recoverable None |> wait
            let reconciled = roots.Reconcile(id, before.Revision) |> wait |> result
            writer.WriteStartObject(scenario)
            receipt writer reconciled
            writer.WriteBoolean("listedForRecovery", List.contains id pending)
            writer.WriteBoolean("fileExists", File.Exists marker)

            writer.WriteBoolean(
                "foreignPreserved",
                if scenario = "changed" then
                    File.ReadAllText marker = "foreign change"
                elif scenario = "replaced" then
                    File.ReadAllBytes marker = original.Value && File.Exists(marker + "-original")
                else
                    true
            )

            writer.WriteEndObject()

    let private observeWatchCounts (writer: Utf8JsonWriter) directory =
        do
            let watchState =
                Directory
                    .CreateDirectory(Path.Combine(directory, "operation-watch-counts"))
                    .FullName

            use store = new OperationStore(watchState)
            let counted = CountingOperations(store :> IOperationStore)
            let operations = counted :> IOperationStore
            let coordinator = Coordinator(operations, fun () -> Unchecked.defaultof<_>)
            let service = OperationService(operations, coordinator)
            use cancellation = new CancellationTokenSource()
            let stream = WatchCountFixtures.CounterStream<OperationBatch>()
            let context = WatchCountFixtures.StreamContext(cancellation.Token)
            let watching = service.WatchOperations(WatchRequest(), stream, context)

            if
                not (
                    SpinWait.SpinUntil(
                        (fun () -> counted.Waits = 1 && stream.Count = 1),
                        TimeSpan.FromSeconds 3.
                    )
                )
            then
                failwith "The operation watch did not publish its initial snapshot."

            let initial = counted.Initial, counted.Changes, counted.Waits
            Thread.Sleep 150
            let idle = counted.Initial, counted.Changes, counted.Waits
            let feed = (store :> IOperationStore).InitialFeed None |> wait

            let begun =
                operations.Begin
                    { Id = Guid.NewGuid().ToString("N")
                      ExpectedRevision = feed.Revision
                      Count = 1 }
                |> wait

            if
                not (
                    SpinWait.SpinUntil(
                        (fun () -> counted.Changes >= 1 && stream.Count >= 2),
                        TimeSpan.FromSeconds 3.
                    )
                )
            then
                failwith "The operation watch did not publish the owner change."

            let changed = counted.Initial, counted.Changes, counted.Waits
            cancellation.Cancel()

            try
                watching.GetAwaiter().GetResult()
            with :? OperationCanceledException ->
                ()

            writer.WriteStartObject("operationWatchCounts")
            let initialFeed, initialChanges, initialWaits = initial
            let idleFeed, idleChanges, idleWaits = idle
            let changedFeed, changedChanges, changedWaits = changed
            writer.WriteNumber("initialFeedReads", initialFeed)
            writer.WriteNumber("initialChangeReads", initialChanges)
            writer.WriteNumber("initialWaitChecks", initialWaits)
            writer.WriteNumber("idleFeedReads", idleFeed)
            writer.WriteNumber("idleChangeReads", idleChanges)
            writer.WriteNumber("idleWaitChecks", idleWaits)
            writer.WriteNumber("afterChangeFeedReads", changedFeed)
            writer.WriteNumber("afterChangeChangeReads", changedChanges)
            writer.WriteNumber("afterChangeWaitChecks", changedWaits)
            writer.WriteBoolean("idleUnchanged", (initial = idle))
            writer.WriteBoolean("oneChangeRead", (changedChanges = initialChanges + 1))
            writer.WriteEndObject()

            if initial <> idle || changedChanges <> initialChanges + 1 then
                failwith "Operation watch repeated a read while idle or missed its change."

    let private observeLiveOwners (writer: Utf8JsonWriter) directory =
        for scenario in [ "live"; "slow" ] do
            let state, root, id = area directory scenario
            use child = worker scenario state root id
            let signal = child.Line()
            use store = new OperationStore(state)
            let roots = store.WorkspaceRoots
            let before = roots.Get id |> wait |> Option.get
            writer.WriteStartObject(scenario)

            writer.WriteBoolean(
                "recoveryRefused",
                roots.Reconcile(id, before.Revision) |> wait = Error WorkspaceFailure.Busy
            )

            writer.WriteBoolean(
                "notAbandoned",
                roots.Recoverable None |> wait |> List.contains id |> not
            )

            if scenario = "slow" then
                let parts = signal.Split(':')
                writer.WriteNumber("progressWhileFileBlocked", Int64.Parse parts[0])
                writer.WriteBoolean("closeRefused", Boolean.Parse parts[1])
                writer.WriteBoolean("sameOwnerListed", Boolean.Parse parts[2])
                writer.WriteBoolean("featureAvailableAfterRefusedClose", Boolean.Parse parts[3])
                let operation = StorageWorker.runtime store (Guid.NewGuid().ToString()) 1L
                writer.WriteNumber("otherOwnerRuntimeRevision", operation.ResultRevision)

            child.Send "complete"
            child.Finish()
            receipt writer (roots.Get id |> wait |> Option.get)
            writer.WriteEndObject()

    let private observeForeignMarker (writer: Utf8JsonWriter) directory =
        let state, root, id = area directory "foreign"
        let marker = Path.Combine(root, RootIdentityFile.name)
        File.WriteAllText(marker, "foreign")

        do
            use store = new OperationStore(state)
            let prepared = store.WorkspaceRoots.Prepare(id, 0L, select root) |> wait |> result
            let applied = store.WorkspaceRoots.Apply(id, prepared.Revision) |> wait |> result
            writer.WriteStartObject("foreign")
            receipt writer applied
            writer.WriteString("contents", File.ReadAllText marker)
            writer.WriteEndObject()

    let private observeMovedRoot (writer: Utf8JsonWriter) directory =
        let state, root, id = area directory "moved-root"

        do
            use store = new OperationStore(state)
            let prepared = store.WorkspaceRoots.Prepare(id, 0L, select root) |> wait |> result
            Directory.Move(root, root + "-original")
            Directory.CreateDirectory root |> ignore
            File.WriteAllText(Path.Combine(root, "foreign"), "keep")
            let applied = store.WorkspaceRoots.Apply(id, prepared.Revision) |> wait |> result
            writer.WriteStartObject("movedRoot")
            receipt writer applied

            writer.WriteBoolean(
                "replacementUntouched",
                File.ReadAllText(Path.Combine(root, "foreign")) = "keep"
                && not (File.Exists(Path.Combine(root, RootIdentityFile.name)))
            )

            writer.WriteBoolean(
                "originalUntouched",
                not (File.Exists(Path.Combine(root + "-original", RootIdentityFile.name)))
            )

            writer.WriteEndObject()

    let private observeOperationEvents (writer: Utf8JsonWriter) directory =
        let state, _, _ = area directory "operation-events"

        do
            use store = new OperationStore(state)
            let operations = store :> IOperationStore
            let initial = operations.InitialFeed None |> wait
            use cancellation = new CancellationTokenSource()
            let pending = operations.WaitForChanges(initial.Cursor, cancellation.Token)
            Thread.Sleep 150
            let idle = not pending.IsCompleted
            let id = Guid.NewGuid().ToString("N")

            let begun =
                operations.Begin
                    { Id = id
                      ExpectedRevision = initial.Revision
                      Count = 1 }
                |> wait

            pending.WaitAsync(TimeSpan.FromSeconds 3.).GetAwaiter().GetResult()
            let feed = operations.Changes initial.Cursor |> wait
            writer.WriteStartObject("operationEvents")
            writer.WriteBoolean("idleWaits", idle)
            writer.WriteBoolean("commitWakes", Result.isOk begun && feed.Changes.Length = 1)
            writer.WriteEndObject()

    let observe (writer: Utf8JsonWriter) primary =
        let directory = Directory.CreateDirectory(Path.Combine(primary, "storage")).FullName
        writer.WriteStartObject("storage")
        observeSchema writer directory
        PersistenceEncodingFixtures.observe writer
        observeLifecycle writer directory
        observeRecovery writer directory
        observeWatchCounts writer directory
        observeLiveOwners writer directory
        observeForeignMarker writer directory
        observeMovedRoot writer directory
        observeOperationEvents writer directory
        writer.WriteEndObject()

    let run primary =
        use output = Console.OpenStandardOutput()
        use writer = new Utf8JsonWriter(output, JsonWriterOptions(Indented = true))
        writer.WriteStartObject()

        writer.WriteBoolean(
            "nativeAot",
            not Runtime.CompilerServices.RuntimeFeature.IsDynamicCodeSupported
        )

        observe writer primary
        writer.WriteEndObject()
        writer.Flush()
