namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Net.Sockets
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Microsoft.Data.Sqlite
open ModConductor.Credentials
open ModConductor.Desktop
open ModConductor.Engine
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.HttpDownloads
open ModConductor.ArtifactLibrary
open ModConductor.Protocol.V1

module NxmInboxFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private send (descriptor: PrivateIngressDescriptor) id kind input =
        use socket =
            new Socket(AddressFamily.Unix, SocketType.Stream, ProtocolType.Unspecified)

        socket.Connect(UnixDomainSocketEndPoint descriptor.Endpoint)
        use stream = new NetworkStream(socket, false)
        stream.ReadTimeout <- 5000
        let payload = Encoding.UTF8.GetBytes(input: string)
        let header = Array.zeroCreate<byte> 53
        header[0] <- kind
        descriptor.Capability.CopyTo(header, 1)
        (id: Guid).ToByteArray().CopyTo(header, 33)
        BitConverter.GetBytes(payload.Length).CopyTo(header, 49)
        stream.Write header
        stream.Write payload
        let reply = Array.zeroCreate<byte> 16
        stream.ReadExactly reply
        Guid reply

    let private deliver descriptor id input = send descriptor id 1uy input
    let private dismiss descriptor id = send descriptor id 2uy ""

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                failwith name

        let area = Directory.CreateDirectory(Path.Combine(primary, "inbox")).FullName
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace = Guid.NewGuid()
        let reference, alias, fresh = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let link expiry =
            "nxm://skyrimspecialedition/mods/64012/files/501?key=inbox-private-secret&expires="
            + string expiry
            + "&user_id=42"

        let future = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()
        let dbPath = Path.Combine(state, "state.db")

        do
            use baseline = new OperationStore(state)

            (baseline.Workspaces :> ModConductor.Workspaces.IWorkspaceState)
                .Create(workspace, "Retained workspace", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

        do
            use old = new SqliteConnection("Data Source=" + dbPath + ";Pooling=False")
            old.Open()
            use command = old.CreateCommand()
            command.CommandText <- "DROP TABLE nexus_request_deliveries; DROP TABLE nexus_requests;"
            command.ExecuteNonQuery() |> ignore

        use server = new NexusServer()
        use credentials = new CredentialSession(NexusMemoryStore())
        let mutable directArchive = Guid.Empty
        let mutable nexusArchive = Guid.Empty
        let mutable thunderstoreArchive = Guid.Empty
        let opened = ResizeArray<Uri>()

        let handoff =
            OAuthHandoff(fun (uri, _) ->
                opened.Add uri
                Task.CompletedTask)
            :> IOAuthHandoff

        let context = WatchCountFixtures.StreamContext(CancellationToken.None)

        do
            use session =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    fun _ -> Task.CompletedTask
                )

            use store = new OperationStore(state)
            session.AttachNxmInbox store.NxmInbox

            check
                "oldSupportedDatabaseAddsInboxWithoutLosingWorkspace"
                ((store.Workspaces :> ModConductor.Workspaces.IWorkspaceState).Read(workspace, None)
                 |> wait
                 |> result
                 |> fun page -> page.Workspace.Name = "Retained workspace")

            use ingress =
                new PrivateIngress(
                    (fun (id, input) -> session.AcceptNxm(id, input)),
                    session.DismissNxm
                )

            let descriptor = ingress.Configure Environment.ProcessId

            do
                use blocker = new SqliteConnection("Data Source=" + dbPath + ";Pooling=False")
                blocker.Open()
                use transaction = blocker.BeginTransaction(deferred = false)

                check
                    "persistenceFailureDoesNotAcknowledgePrivateDelivery"
                    (deliver descriptor reference (link future) = Guid.Empty
                     && session.PendingNxm().IsEmpty)

                transaction.Rollback()

            check
                "positivePrivateAcknowledgementFollowsDurableSave"
                (deliver descriptor reference (link 1L) = reference
                 && store.NxmInbox.Read reference |> Option.isSome)

            check
                "duplicateIngressUsesOnePendingIdentity"
                (session.AcceptNxm(alias, link future)
                 && session.PendingNxm().Length = 1
                 && (store.NxmInbox.Read alias).Value.Id = reference)

            use service =
                new NxmService(session, ingress, store.Downloads, store.GameContexts, handoff)

            let viewed =
                service.ReadNexusLink(NexusLinkRequest(Reference = alias.ToString("N")), context)
                |> wait

            check
                "viewingIncomingRequestDoesNotAcquireOrSelectWorkspace"
                (viewed.SignInRequired && isNull viewed.Artifact && server.NxmRequests = 0)

            let start source =
                store.Downloads.Start
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Name = "source.zip"
                      Sources = [ source ]
                      ExpectedLength = None
                      ExpectedSha256 = None }
                |> wait
                |> result

            nexusArchive <-
                (start (
                    DownloadSource.Nexus
                        { Account = "42"
                          Game = "fallout4"
                          ModId = 9L
                          FileId = 10L
                          Keyed = true
                          Version = None }
                ))
                    .Id

            thunderstoreArchive <-
                (start (
                    DownloadSource.Thunderstore
                        { Reference =
                            { Package =
                                { Community = "valheim"
                                  Namespace = "Author"
                                  Name = "Package" }
                              Version = "1.0.0" }
                          Url = "http://127.0.0.1:1/synthetic.zip" }
                ))
                    .Id

            let direct = start (DownloadSource.Url "http://127.0.0.1:1/unknown.zip")
            directArchive <- direct.Id
            check "directDownloadDoesNotInventModPage" direct.Download.Value.ModPage.IsNone
            store.Downloads.Stop() |> wait

        do
            use session =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    fun _ -> Task.CompletedTask
                )

            use store = new OperationStore(state)
            session.AttachNxmInbox store.NxmInbox

            use ingress =
                new PrivateIngress(
                    (fun (id, input) -> session.AcceptNxm(id, input)),
                    session.DismissNxm
                )

            use service =
                new NxmService(session, ingress, store.Downloads, store.GameContexts, handoff)

            let pending = service.ListPendingNexusLinks(NexusStatusRequest(), context) |> wait
            let request = NexusLinkRequest(Reference = alias.ToString("N"))
            let restored = service.ReadNexusLink(request, context) |> wait

            check
                "completeReopenDiscoversCanonicalRequestAndNativeAlias"
                (pending.Entries.Count = 1
                 && pending.Entries[0].Reference = reference.ToString("N")
                 && pending.Entries[0].Deliveries.Contains(alias.ToString("N")))

            check
                "restartKeepsIdentityButNotAuthorizationOrAutomaticConsent"
                (restored.ModId = 64012L
                 && restored.FileId = 501L
                 && restored.FreshLinkRequired
                 && restored.SourcePage.Contains("/skyrimspecialedition/mods/64012")
                 && restored.SignInRequired
                 && server.NxmRequests = 0)

            service.OpenNexusLinkPage(request, context) |> wait |> ignore

            check
                "restoredFreshLinkActionUsesStablePageWithoutAccountOrWorkspace"
                (opened.Count = 1
                 && opened[0].AbsoluteUri.Contains("file_id=501")
                 && not (opened[0].AbsoluteUri.Contains "inbox-private-secret"))

            check
                "freshGrantRecoversExistingCanonicalRequest"
                (session.AcceptNxm(fresh, link future)
                 && session.PendingNxm().Length = 1
                 && not (session.NxmNeedsGrant alias)
                 && session.ValidateNxm(alias, "42") |> Result.isOk)

            check
                "expiryDoesNotEraseSourceIdentity"
                (session.AcceptNxm(Guid.NewGuid(), link 1L)
                 && session.NxmNeedsGrant alias
                 && session.ReadNxm alias |> Result.map _.ModId = Ok 64012L)

            let descriptor = ingress.Configure Environment.ProcessId

            do
                use blocker = new SqliteConnection("Data Source=" + dbPath + ";Pooling=False")
                blocker.Open()
                use transaction = blocker.BeginTransaction(deferred = false)

                check
                    "failedDurableDismissDoesNotAcknowledgeOrLoseIntent"
                    (dismiss descriptor alias = Guid.Empty && session.PendingNxm().Length = 1)

                transaction.Rollback()

            service.DismissNexusLink(request, context) |> wait |> ignore
            service.DismissNexusLink(request, context) |> wait |> ignore

            check
                "dismissalCoversAliasesAndRepeatedDeliveryDoesNotResurrect"
                (session.AcceptNxm(fresh, link future)
                 && session.PendingNxm().IsEmpty
                 && session.NxmHandled fresh)

            let artifacts = ArtifactService(store.Artifacts, handoff)

            let openArchive (id: Guid) =
                artifacts.OpenArtifactModPage(
                    ArtifactReadRequest(
                        WorkspaceId = workspace.ToString("N"),
                        Id = id.ToString("N")
                    ),
                    context
                )
                |> wait
                |> ignore

            openArchive nexusArchive
            openArchive thunderstoreArchive

            check
                "archiveSourceActionsUseRetainedOriginWithoutCurrentGame"
                (opened[1].AbsoluteUri = "https://www.nexusmods.com/fallout4/mods/9"
                 && opened[2].AbsoluteUri = "https://thunderstore.io/c/valheim/p/Author/Package/")

            let invalid = Guid.NewGuid()

            session.AcceptNxm(invalid, "nxm://skyrimspecialedition/collections/unsupported")
            |> ignore

            let unknownRejected =
                try
                    openArchive directArchive
                    false
                with :? Grpc.Core.RpcException ->
                    true

            check
                "unknownArchiveSourceCannotReachBrowserBoundary"
                (unknownRejected && opened.Count = 3)

            let admitted =
                [ for file in 1..15 -> Guid.NewGuid(), "nxm://fallout4/mods/1/files/" + string file ]

            check
                "restoredInboxPreservesPendingBound"
                (admitted |> List.forall (fun (id, input) -> session.AcceptNxm(id, input))
                 && not (session.AcceptNxm(Guid.NewGuid(), "nxm://fallout4/mods/1/files/16")))

            admitted |> List.iter (fun (id, _) -> session.DismissNxm id)
            session.DismissNxm invalid
            store.Downloads.Stop() |> wait

        do
            use session =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    fun _ -> Task.CompletedTask
                )

            use store = new OperationStore(state)
            session.AttachNxmInbox store.NxmInbox

            check
                "dismissedRequestsStayDismissedAcrossCompleteReopen"
                (session.PendingNxm().IsEmpty
                 && session.NxmHandled reference
                 && session.NxmHandled fresh)

        let saved = File.ReadAllBytes dbPath |> Encoding.UTF8.GetString

        check
            "durableInboxContainsNoRawGrantOrPrivateInput"
            (not (saved.Contains "inbox-private-secret")
             && not (saved.Contains "nxm://")
             && not (saved.Contains "user_id="))
