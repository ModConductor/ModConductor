namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open Microsoft.Data.Sqlite
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Operations

module StorageFixtures =
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

    let observe (writer: Utf8JsonWriter) primary =
        let directory = Directory.CreateDirectory(Path.Combine(primary, "storage")).FullName

        let area name =
            let parent = Directory.CreateDirectory(Path.Combine(directory, name)).FullName
            let state = Directory.CreateDirectory(Path.Combine(parent, "state")).FullName
            let root = Directory.CreateDirectory(Path.Combine(parent, "root")).FullName
            state, root, Guid.NewGuid()

        let worker mode state root (id: Guid) =
            new NativeChild(
                Environment.ProcessPath,
                [ "--storage-worker"; mode; state; root; id.ToString() ]
            )

        writer.WriteStartObject("storage")
        writer.WriteStartObject("schema")
        let state, _, _ = area "schema"

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

        let interrupted, _, _ = area "schema-interrupted"
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

        let unsupported, _, _ = area "schema-unsupported"

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

        let mutable resetInstruction = false

        try
            use _ = new OperationStore(unsupported)
            ()
        with :? InvalidOperationException as error ->
            resetInstruction <- error.Message.Contains("Delete the Mod Conductor state directory")

        writer.WriteBoolean(
            "unsupportedRefused",
            resetInstruction
            && number unsupported "PRAGMA user_version" = 1L
            && number unsupported "SELECT value FROM development_state" = 42L
            && number unsupported "SELECT count(*) FROM sqlite_master WHERE name='operation_state'" = 0L
        )

        do
            use _ = new OperationStore(state)
            writer.WriteBoolean("restartCurrent", true)

        writer.WriteEndObject()
        PersistenceEncodingFixtures.observe writer

        writer.WriteStartObject("lifecycle")
        let state, root, id = area "lifecycle"
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

        for scenario in [ "intent"; "effect"; "observed"; "changed"; "replaced" ] do
            let state, root, id = area scenario

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

        for scenario in [ "live"; "slow" ] do
            let state, root, id = area scenario
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

        let state, root, id = area "foreign"
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

        let state, root, id = area "moved-root"

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
