namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Net.Http
open System.Net.Sockets
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Credentials
open ModConductor.Desktop
open ModConductor.Engine
open ModConductor.Fnis
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

module NxmComponentFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private until label predicate =
        let deadline = DateTime.UtcNow.AddSeconds 20.

        while not (predicate ()) && DateTime.UtcNow < deadline do
            Thread.Sleep 10

        if not (predicate ()) then
            failwith ("The component NXM fixture timed out: " + label)

    let private deliver (descriptor: PrivateIngressDescriptor) id input =
        use socket =
            new Socket(AddressFamily.Unix, SocketType.Stream, ProtocolType.Unspecified)

        socket.Connect(UnixDomainSocketEndPoint descriptor.Endpoint)
        use stream = new NetworkStream(socket, false)
        stream.ReadTimeout <- 5000
        let payload = Encoding.UTF8.GetBytes(input: string)
        let header = Array.zeroCreate<byte> 53
        header[0] <- 1uy
        descriptor.Capability.CopyTo(header, 1)
        (id: Guid).ToByteArray().CopyTo(header, 33)
        BitConverter.GetBytes(payload.Length).CopyTo(header, 49)
        stream.Write header
        stream.Write payload
        let reply = Array.zeroCreate<byte> 16
        stream.ReadExactly reply
        Guid reply

    let private archive (runtime: string) =
        use output = new MemoryStream()
        use zip = new ZipArchive(output, ZipArchiveMode.Create, true)

        for name in
            [ "skse64_loader.exe"
              "skse64_steam_loader.dll"
              "skse64_" + runtime.Replace('.', '_') + ".dll"
              "Data/Scripts/skse.pex" ] do
            use target = zip.CreateEntry("skse64_fixture/" + name).Open()
            target.Write(Encoding.UTF8.GetBytes("synthetic-component-" + name))

        zip.Dispose()
        output.ToArray()

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                failwith name

        let area = Directory.CreateDirectory(Path.Combine(primary, "components")).FullName
        let state = Path.Combine(area, "state")
        let handled, componentId = Guid.NewGuid(), Guid.NewGuid()
        use credentials = new CredentialSession(NexusMemoryStore())
        use server = new NexusServer()
        server.Premium <- false
        server.Mode <- "nxm"

        let handoff = OAuthHandoff(fun _ -> Task.CompletedTask) :> IOAuthHandoff

        let link modId fileId =
            "nxm://skyrimspecialedition/mods/"
            + string modId
            + "/files/"
            + string fileId
            + "?key=synthetic-nxm-private-grant&expires="
            + string (DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds())
            + "&user_id=42"

        do
            use session =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            session.SignIn() |> wait |> ignore
            until "sign-in" (fun () -> not session.Status.Waiting && session.Status.Account.IsSome)

            use store =
                new OperationStore(
                    state,
                    nexusLinks = NexusDownloadLinks(session),
                    downloadPolicy =
                        { DownloadPolicy.Default with
                            Attempts = 1 }
                )

            session.AttachNxmInbox store.NxmInbox

            let workspace, profile, _, _, context =
                SkyrimFixtureWorkspace.create
                    store
                    state
                    area
                    "NXM component lifecycle"
                    "workspace"
                    "installation"
                    true

            let runtime =
                (context |> result).Binding.Value.Evidence.Executable.Value.FileVersion

            server.Payload <- archive runtime

            server.SkseFiles <-
                [ 301L, "skse.zip", "2.2.0", "Current game version " + runtime + " from Steam" ]

            server.FnisFiles <-
                [ 801L,
                  "FNIS Behavior SE.zip",
                  FnisCatalogue.SupportedVersion,
                  "FNIS Behavior SE main file" ]

            use skse =
                new SkseCoordinator(session, store.Downloads, store.GameContexts, store, handoff)

            use enb =
                new EnbCoordinator(
                    session,
                    store.Downloads,
                    store,
                    handoff,
                    ModConductor.Enb.EnbCatalogue.lean
                )

            use fnis = new FnisCoordinator(session, store.Downloads, store, handoff)
            use ingress = ModConductor.Engine.NxmIngress.create session skse enb fnis
            let descriptor = ingress.Configure Environment.ProcessId

            let waitingSkse = skse.Start(workspace, profile) |> wait
            let waitingFnis = fnis.Install(workspace, profile) |> wait

            if
                waitingSkse.Phase <> SksePhase.WaitingForNexus
                || waitingFnis.Phase <> FnisPhase.WaitingForNexus
            then
                failwith "The explicit component setup did not enter its Nexus handoff state."

            let unrelated = link 64012L 501L

            if deliver descriptor handled unrelated <> handled then
                failwith "The component fixture request was not acknowledged."

            let mutable retirementFailed = false

            do
                use blocker =
                    new SqliteConnection(
                        "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
                    )

                blocker.Open()
                use transaction = blocker.BeginTransaction(deferred = false)

                do
                    use admitted =
                        session.AdmitNxm(handled, "42")
                        |> Result.defaultWith (fun p -> failwith p.Title)

                    try
                        admitted.Complete()
                    with :? SqliteException ->
                        retirementFailed <- true

                transaction.Rollback()

            let retained =
                session.Resolve("skyrimspecialedition", 64012L, 501L, "42", true) |> wait

            check
                "retirementFailureKeepsPendingIntentAndAdmittedTransfer"
                (retirementFailed
                 && not (session.NxmHandled handled)
                 && session.PendingNxm().Length = 1
                 && Result.isOk retained)

            do
                use admitted =
                    session.AdmitNxm(handled, "42")
                    |> Result.defaultWith (fun p -> failwith p.Title)

                admitted.Complete()
                admitted.Complete()

            let before = server.NxmRequests

            let lease =
                session.Resolve("skyrimspecialedition", 64012L, 501L, "42", true) |> wait

            check
                "sharedConsumptionRetiresIntentWithoutLosingAdmittedGrant"
                (session.NxmHandled handled
                 && session.PendingNxm().IsEmpty
                 && Result.isOk lease
                 && server.NxmRequests > before)

            let acknowledged = deliver descriptor handled unrelated = handled
            let mutable preserved = true
            let deadline = DateTime.UtcNow.AddMilliseconds 500.

            while preserved && DateTime.UtcNow < deadline do
                preserved <-
                    (store.SkseLoaders.Pending() |> wait).Length = 1
                    && (store.FnisSetups.Pending() |> wait).Length = 1

                Thread.Sleep 10

            check
                "handledPrivateReplayPreservesUnrelatedComponentHandoffs"
                (acknowledged && preserved)

            fnis.Cancel(workspace, profile) |> wait |> ignore

            if deliver descriptor componentId (link 30379L 301L) <> componentId then
                failwith "The SKSE component link was not acknowledged."

            until "component consumption" (fun () -> session.NxmHandled componentId)

            until "component installation" (fun () ->
                let phase = (skse.Read(workspace, profile) |> wait).Phase
                phase = SksePhase.Ready || phase = SksePhase.Failed)

            check
                "componentIngressConsumesDurableIntentThroughSharedAdmission"
                ((skse.Read(workspace, profile) |> wait).Phase = SksePhase.Ready
                 && (store.SkseLoaders.Pending() |> wait).IsEmpty
                 && session.PendingNxm().IsEmpty
                 && server.NxmRequests > before + 1)

        do
            use session =
                new NexusSession(credentials, None, handoff, fun _ -> Task.CompletedTask)

            use store = new OperationStore(state)
            session.AttachNxmInbox store.NxmInbox

            check
                "consumedComponentAndSharedIntentStayHandledAfterSessionAndStoreReopen"
                (session.PendingNxm().IsEmpty
                 && session.NxmHandled handled
                 && session.NxmHandled componentId
                 && session.AcceptNxm(componentId, link 30379L 301L)
                 && session.PendingNxm().IsEmpty)

        for _ in 1..12 do
            let active = new NexusServer()
            active.Slow <- true
            use client = new HttpClient()

            use response =
                client.GetAsync(active.Root + "payload", HttpCompletionOption.ResponseHeadersRead)
                |> wait

            use stream = response.Content.ReadAsStream()
            stream.ReadByte() |> ignore
            (active :> IDisposable).Dispose()

        check "fixtureServerCancellationDrainsInflightResponsesBeforeClosingListener" true
