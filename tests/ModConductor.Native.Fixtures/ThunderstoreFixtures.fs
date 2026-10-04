namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.Persistence
open ModConductor.Thunderstore
open ModConductor.Workspaces

module ThunderstoreFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private create (store: OperationStore) area =
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace = Guid.NewGuid()

        (store.Workspaces :> IWorkspaceState)
            .Create(workspace, "Thunderstore fixture", StorageWorker.select root)
        |> wait
        |> result
        |> ignore

        workspace

    let private inventory (store: OperationStore) workspace =
        ((store.ModLibrary :> IModLibrary).Scan(workspace, 32) |> wait |> result).Entries

    let private scalar state sql =
        use connection =
            new SqliteConnection(
                "Data Source="
                + Path.Combine(state, "state.db")
                + ";Mode=ReadOnly;Pooling=False"
            )

        connection.Open()
        use command = connection.CreateCommand()
        command.CommandText <- sql
        Convert.ToInt32(command.ExecuteScalar())

    let private coordinator (store: OperationStore) reader =
        ThunderstoreAcquisition(
            reader,
            store.Downloads,
            store.Artifacts,
            store.Installations,
            store.ThunderstoreInventory
        )

    let private paths (store: OperationStore) (entry: ModEntry) =
        let library = store.ModLibrary :> IModLibrary
        let mutable next, paths = Some 0, []

        while next.IsSome do
            let page = library.Version(entry.CurrentVersion.Value, next.Value) |> wait |> result

            paths <-
                paths @ (page.Entries |> List.map (fun entry -> LogicalPath.display entry.Path))

            next <- page.NextOffset

        paths

    let private staging (check: string -> bool -> unit) area =
        let state = Path.Combine(area, "state")
        use store = new OperationStore(state)
        let workspace = create store area
        use server = new DownloadServer(ThunderstoreSamples.payload ())

        let package reference dependencies =
            ThunderstoreSamples.package
                reference
                (server.Url + "/good")
                (int64 server.Payload.Length)
                dependencies

        let reader =
            ThunderstoreSamples.reader
                [ package
                      ThunderstoreSamples.jotunn
                      [ ThunderstoreSamples.dependency ThunderstoreSamples.bep ]
                  package ThunderstoreSamples.bep [] ]

        let acquisition = coordinator store reader
        let progress = ResizeArray<ThunderstoreProgress>()

        let emit value =
            progress.Add value
            Task.CompletedTask

        let installed =
            acquisition.Acquire(workspace, ThunderstoreSamples.jotunn, emit, token)
            |> wait
            |> result

        let entries = inventory store workspace

        check
            "RequiredVersionAndRootEnterLibraryWithoutProfile"
            (installed |> List.map _.Reference = [ ThunderstoreSamples.bep
                                                   ThunderstoreSamples.jotunn ]
             && entries.Length = 2
             && scalar state "SELECT count(*) FROM profiles" = 0)

        check
            "PackagePayloadRootsAreNotBethesdaData"
            (entries
             |> List.forall (fun entry -> paths store entry = [ "plugins/Fixture.dll" ]))

        check
            "StagingDoesNotCreateGameContextOrDeployment"
            (scalar state "SELECT count(*) FROM game_contexts" = 0
             && scalar state "SELECT count(*) FROM deployment_receipts" = 0)

        check
            "ProviderIdentitySurvivesArtifactAndLibrary"
            (entries
             |> List.forall (fun entry ->
                 VersionReference.tryDecode entry.Metadata.Source |> Option.isSome)
             && scalar state "SELECT count(*) FROM version_nexus_origins" = 0)

        check
            "AcquisitionReportsActualTransferAndInstallation"
            (progress
             |> Seq.exists (fun value -> value.Stage = "download" && value.Bytes > 0L)
             && progress |> Seq.exists (fun value -> value.Stage = "install"))

        let requests = server.Seen.Length

        acquisition.Acquire(
            workspace,
            ThunderstoreSamples.jotunn,
            (fun _ -> Task.CompletedTask),
            token
        )
        |> wait
        |> result
        |> ignore

        check
            "RepeatedExactAcquisitionDoesNotDownloadOrDuplicate"
            (server.Seen.Length = requests && (inventory store workspace).Length = 2)

        let changedUrl =
            { Reference = ThunderstoreSamples.jotunn
              Url = server.Url + "/changed-cdn" }

        check
            "PackageDownloadIdentityDoesNotDependOnCdnUrl"
            (store.Downloads.FindThunderstore(workspace, changedUrl) |> wait |> Option.isSome)

        let nexus =
            { Account = "fixture"
              Game = "skyrimspecialedition"
              ModId = 1L
              FileId = 1L
              Keyed = false
              Version = Some "2.30.2" }

        check
            "ThunderstoreDownloadIsNotANexusFile"
            (store.Downloads.FindNexus(workspace, nexus) |> wait |> Option.isNone)

        let opened =
            (store.Workspaces :> IWorkspaceState).Read(workspace, None) |> wait |> result

        (store.Workspaces :> IWorkspaceState)
            .Edit(
                workspace,
                opened.Workspace.Revision,
                ProfileEdit.Create
                    { Id = Guid.NewGuid()
                      Name = "Later profile" }
            )
        |> wait
        |> result
        |> ignore

        check
            "LaterProfileDoesNotEnableAcquiredPackages"
            (scalar state "SELECT count(*) FROM profile_mods WHERE enabled=1" = 0
             && scalar state "SELECT count(*) FROM profile_mods" = 2)

    let private cancellation (check: string -> bool -> unit) area =
        let state = Path.Combine(area, "state")

        use store =
            new OperationStore(
                state,
                downloadPolicy =
                    { DownloadPolicy.Default with
                        CheckpointBytes = 16384L }
            )

        let workspace = create store area
        use server = new DownloadServer(ThunderstoreSamples.payload ())

        let package reference path dependencies =
            ThunderstoreSamples.package
                reference
                (server.Url + path)
                (int64 server.Payload.Length)
                dependencies

        let reader =
            ThunderstoreSamples.reader
                [ package
                      ThunderstoreSamples.jotunn
                      "/slow"
                      [ ThunderstoreSamples.dependency ThunderstoreSamples.bep ]
                  package ThunderstoreSamples.bep "/good" [] ]

        use cancel = new CancellationTokenSource(TimeSpan.FromSeconds 30.)

        let emit (value: ThunderstoreProgress) =
            if
                value.Reference = ThunderstoreSamples.jotunn
                && value.Stage = "download"
                && value.Bytes > 0L
            then
                cancel.Cancel()

            Task.CompletedTask

        let stopped =
            (coordinator store reader)
                .Acquire(workspace, ThunderstoreSamples.jotunn, emit, cancel.Token)
            |> wait

        let source =
            { Reference = ThunderstoreSamples.jotunn
              Url = server.Url + "/slow" }

        let paused = store.Downloads.FindThunderstore(workspace, source) |> wait

        check
            "CancelPausesCurrentTransferAndKeepsCompletedDependency"
            (stopped = Error Problem.Cancelled
             && (inventory store workspace).Length = 1
             && paused
                |> Option.exists (fun artifact ->
                    artifact.Download.Value.State = DownloadState.Paused))

        server.Release()

        let unavailable =
            package
                ThunderstoreSamples.jotunn
                "/good"
                [ { ThunderstoreSamples.dependency ThunderstoreSamples.bep with
                      Available = false } ]

        let requests = server.Seen.Length

        let refused =
            (coordinator store (ThunderstoreSamples.reader [ unavailable ]))
                .Acquire(
                    workspace,
                    ThunderstoreSamples.jotunn,
                    (fun _ -> Task.CompletedTask),
                    token
                )
            |> wait

        check
            "RequirementRefusalStartsNoPayloadTransfer"
            (Result.isError refused && server.Seen.Length = requests)

    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject "thunderstore"

        let check (name: string) (passed: bool) =
            writer.WriteBoolean(name, passed)
            writer.Flush()

            if not passed then
                invalidOp ("Thunderstore fixture failed: " + name)

        ThunderstoreReaderFixtures.observe check
        ThunderstoreReaderFixtures.requirements check
        ThunderstoreReaderFixtures.portable check
        staging check (Path.Combine(area, "staging"))
        cancellation check (Path.Combine(area, "cancellation"))
        writer.WriteEndObject()

    let publicPackages (writer: Utf8JsonWriter) area =
        writer.WriteStartObject "thunderstorePublic"
        let state = Path.Combine(area, "state")
        use store = new OperationStore(state)
        let existing = (store.Workspaces :> IWorkspaceState).Recent None |> wait

        let workspace =
            existing.Workspaces
            |> List.tryHead
            |> Option.map _.Id
            |> Option.defaultWith (fun () -> create store area)

        use reader = new PackageReader()
        use deadline = new CancellationTokenSource(TimeSpan.FromMinutes 3.)

        let entries =
            (coordinator store reader)
                .Acquire(
                    workspace,
                    ThunderstoreSamples.jotunn,
                    (fun _ -> Task.CompletedTask),
                    deadline.Token
                )
            |> wait
            |> Result.defaultWith (Problem.message >> invalidOp)

        if
            entries |> List.map _.Reference
            <> [ ThunderstoreSamples.bep; ThunderstoreSamples.jotunn ]
        then
            invalidOp "The required public version changed."

        writer.WriteBoolean(
            "ExactPublicVersionsAddedWithoutProfileOrGame",
            scalar state "SELECT count(*) FROM profiles" = 0
            && scalar state "SELECT count(*) FROM game_contexts" = 0
            && scalar state "SELECT count(*) FROM deployment_receipts" = 0
        )

        writer.WriteStartArray "packages"

        for entry in inventory store workspace do
            writer.WriteStartObject()
            writer.WriteString("source", entry.Metadata.Source)
            writer.WriteStartArray "paths"
            paths store entry |> List.iter writer.WriteStringValue
            writer.WriteEndArray()
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()
