namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open System.Text.Json
open ModConductor.Desktop
open ModConductor.Credentials
open ModConductor.Nexus
open ModConductor.HttpDownloads
open ModConductor.ArtifactLibrary
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.Engine
open ModConductor.Protocol.V1

module NxmFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private until predicate =
        let endAt = DateTime.UtcNow.AddSeconds 20.

        while not (predicate ()) && DateTime.UtcNow < endAt do
            Thread.Sleep 10

        if not (predicate ()) then
            failwith "The NXM fixture did not reach the expected state."

    let ingress (writer: Utf8JsonWriter) =
        let mutable accepted = 0

        use owner =
            new PrivateIngress(
                (fun _ ->
                    accepted <- accepted + 1
                    true),
                ignore
            )

        let descriptor = owner.Configure Environment.ProcessId

        use socket =
            new System.Net.Sockets.Socket(
                System.Net.Sockets.AddressFamily.Unix,
                System.Net.Sockets.SocketType.Stream,
                System.Net.Sockets.ProtocolType.Unspecified
            )

        socket.Connect(System.Net.Sockets.UnixDomainSocketEndPoint descriptor.Endpoint)
        use stream = new System.Net.Sockets.NetworkStream(socket, false)
        stream.ReadTimeout <- 5000
        let frame = Array.zeroCreate<byte> 53
        frame[0] <- 1uy
        // The caller has the right process identity, but not the ingress capability.
        Guid.NewGuid().ToByteArray().CopyTo(frame, 33)
        BitConverter.GetBytes(1).CopyTo(frame, 49)
        stream.Write(frame)
        let rejected = stream.ReadByte() = -1 && accepted = 0
        writer.WriteBoolean("privateIngressRejectsWrongCapabilityBeforeAdmission", rejected)
        writer.Flush()

        if not rejected then
            failwith "Private ingress accepted an unauthenticated frame."

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                failwith name

        Directory.CreateDirectory primary |> ignore
        use server = new NexusServer()
        let memory = NexusMemoryStore()
        use credentials = new CredentialSession(memory)

        use session =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        session.SignIn() |> wait |> ignore
        until (fun () -> session.Status.Account.IsSome)
        let state = Path.Combine(primary, "state")
        let workspace = Guid.NewGuid()
        let profile = Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(primary, "workspace")).FullName
        let mutable original = Guid.Empty
        let mutable kept = 0L
        let mutable acceptedReference = Guid.Empty

        do
            use store =
                new OperationStore(
                    state,
                    nexusLinks = NexusDownloadLinks(session),
                    downloadPolicy =
                        { DownloadPolicy.Default with
                            CheckpointBytes = 16384L }
                )

            let created =
                (store.Workspaces :> IWorkspaceState)
                    .Create(workspace, "NXM fixture", StorageWorker.select root)
                |> wait
                |> result

            (store.Workspaces :> IWorkspaceState)
                .Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "NXM" }
                )
            |> wait
            |> result
            |> ignore

            let game = Path.Combine(primary, "synthetic-game")
            GameContextFixtures.create game 104

            (store.GameContexts :> ModConductor.GameContexts.IGameContexts)
                .Save(workspace, profile, 0L, { GameId = GameId.SkyrimSpecialEditionSteam
                                                Path = game; Proton = None })
            |> wait
            |> result
            |> ignore

            use ingress =
                new PrivateIngress(
                    (fun (id, input) -> session.AcceptNxm(id, input)),
                    session.DismissNxm
                )

            use service = new NxmService(session, ingress, store.Downloads, store.GameContexts)

            let link (user: string) (expiry: int64) =
                "nxm://skyrimspecialedition/mods/64012/files/501?key=synthetic-nxm-private-grant&expires="
                + expiry.ToString()
                + "&user_id="
                + user

            let reference input =
                let id = Guid.NewGuid()

                if not (session.AcceptNxm(id, input)) then
                    failwith "NXM fixture admission failed."

                NexusLinkRequest(
                    Reference = id.ToString("N"),
                    WorkspaceId = workspace.ToString("N"),
                    ProfileId = profile.ToString("N")
                )

            let invoke request =
                service.DownloadNexusLink(request, Unchecked.defaultof<_>) |> wait

            let validUntil = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()
            let rejected = invoke (reference (link "77" validUntil))
            let expired = invoke (reference (link "42" 1L))

            let malformed =
                invoke (
                    reference (
                        "nxm://skyrimspecialedition/mods/64012/files/501?key=synthetic-nxm-private-grant"
                    )
                )

            let collections =
                invoke (reference "nxm://skyrimspecialedition/collections/synthetic/revisions/1")

            let wrongGame = invoke (reference "nxm://fallout4/mods/64012/files/501")

            check
                "rejectedLinksDoNotAcquireProviderFiles"
                (rejected.Problem <> ""
                 && expired.Problem <> ""
                 && malformed.Problem <> ""
                 && collections.Problem <> ""
                 && wrongGame.Problem <> ""
                 && server.NxmRequests = 0
                 && server.Count
                     "/api/games/skyrimspecialedition/mods/64012/files/501/download_link.json" = 0)

            let replyBytes = Google.Protobuf.MessageExtensions.ToByteArray rejected

            check
                "mismatchedAccountReplyDoesNotContainPrivateGrant"
                (not (
                    System.Text.Encoding.UTF8.GetString(replyBytes).Contains
                        "synthetic-nxm-private-grant"
                ))

            server.Slow <- true
            original <- Guid.NewGuid()

            let request =
                { Id = original
                  WorkspaceId = workspace
                  Name = "Quiet rivers.7z"
                  Sources =
                    [ DownloadSource.Nexus
                          { Account = "42"
                            Game = "skyrimspecialedition"
                            ModId = 64012L
                            FileId = 501L
                            Keyed = false
                            Version = None } ]
                  ExpectedLength = Some 1048576L
                  ExpectedSha256 = None }

            store.Downloads.Start request |> wait |> result |> ignore

            let read () =
                store.Artifacts.Read(workspace, original) |> wait |> result

            until (fun () -> (read ()).Download.Value.Bytes >= 65536L)

            let paused =
                store.Downloads.Control(workspace, original, DownloadAction.Pause)
                |> wait
                |> result

            kept <- paused.Download.Value.Bytes
            server.Mode <- "nxm"
            server.DownloadKey <- "synthetic-signed-key-B"
            let incoming = reference (link "42" validUntil)
            acceptedReference <- Guid.Parse incoming.Reference
            let started = invoke incoming
            service.DismissNexusLink(incoming, Unchecked.defaultof<_>) |> wait |> ignore
            let duplicate = invoke (reference (link "42" validUntil))

            check
                "keyedDuplicateKeepsOrdinaryPartialIdentityAndBytes"
                (started.Artifact.Id = original.ToString("N")
                 && duplicate.Artifact.Id = started.Artifact.Id
                 && (read ()).Download.Value.Bytes = kept
                 && (read ()).Download.Value.State = DownloadState.Paused)

            store.Downloads.Control(workspace, original, DownloadAction.Resume)
            |> wait
            |> result
            |> ignore

            until (fun () -> (read ()).Download.Value.State = DownloadState.Failed)

            check
                "freshKeyedGrantReachesProviderAfterPendingDismissal"
                (server.NxmRequests > 0
                 && (read ()).Download.Value.RestartRequired
                 && (read ()).Download.Value.Bytes = kept)

            use db =
                new Microsoft.Data.Sqlite.SqliteConnection(
                    "Data Source=" + Path.Combine(state, "state.db")
                )

            db.Open()
            use query = db.CreateCommand()

            query.CommandText <-
                "SELECT sources || coalesce(effective_url,'') FROM artifact_downloads WHERE artifact_id=$id"

            query.Parameters.AddWithValue("$id", string original) |> ignore
            let durable = string (query.ExecuteScalar())

            check
                "keyedDurableStateHasOnlyPublicIdentityAndFingerprint"
                (durable.StartsWith "nexus-link:/42/"
                 && not (durable.Contains "synthetic-nxm-private-grant")
                 && not (durable.Contains "http"))

        session.Stop() |> wait

        do
            use reopened = new OperationStore(state, nexusLinks = NexusDownloadLinks(session))

            let read () =
                reopened.Artifacts.Read(workspace, original) |> wait |> result

            check
                "restartRetainsPartialBytesWithoutReplayingAuthorization"
                ((read ()).Download.Value.Bytes = kept
                 && (session.ReadNxm acceptedReference |> Result.isError))

        use restoredSession =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        restoredSession.Connect() |> wait |> ignore

        let noGrant =
            restoredSession.Resolve("skyrimspecialedition", 64012L, 501L, "42", requiresLink = true)
            |> wait

        check
            "restartRequiresFreshGrantEvenWithRestoredAccount"
            (noGrant = Error NexusProblem.DownloadLinkNeeded)

        let id = Guid.NewGuid()

        let link =
            "nxm://skyrimspecialedition/mods/64012/files/501?key=synthetic-nxm-private-grant&expires="
            + DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds().ToString()
            + "&user_id=42"

        restoredSession.AcceptNxm(id, link) |> ignore

        use prepared =
            restoredSession.AdmitNxm(id, "42")
            |> Result.defaultWith (fun _ -> failwith "grant")

        prepared.Complete()
        server.Slow <- false

        use resumed =
            new OperationStore(state, nexusLinks = NexusDownloadLinks(restoredSession))

        resumed.Downloads.Control(workspace, original, DownloadAction.Restart)
        |> wait
        |> result
        |> ignore

        let readResumed () =
            resumed.Artifacts.Read(workspace, original) |> wait |> result

        until (fun () -> (readResumed ()).Download.Value.State = DownloadState.Complete)
        let complete = readResumed ()

        check
            "explicitRestartPublishesThroughExistingArtifactOwner"
            (complete.Length = Some 1048576L)

        let detached =
            resumed.Artifacts.DeleteCopy
                { WorkspaceId = workspace
                  Id = original
                  Revision = complete.Revision }
            |> wait
            |> result

        let newRequest =
            { Id = Guid.NewGuid()
              WorkspaceId = workspace
              Name = "Quiet rivers.7z"
              Sources =
                [ DownloadSource.Nexus
                      { Account = "42"
                        Game = "skyrimspecialedition"
                        ModId = 64012L
                        FileId = 501L
                        Keyed = true
                        Version = None } ]
              ExpectedLength = Some 1048576L
              ExpectedSha256 = None }

        let replacement = resumed.Downloads.Start newRequest |> wait |> result

        let duplicate =
            resumed.Downloads.Start { newRequest with Id = Guid.NewGuid() }
            |> wait
            |> result

        check
            "missingCopyAllowsNewWorkWithoutResurrectingOldIdentity"
            (detached.State = ArtifactState.Detached
             && replacement.Id <> original
             && duplicate.Id = replacement.Id
             && (readResumed ()).State = ArtifactState.Detached)

        resumed.Downloads.Stop() |> wait

    let setup (writer: Utf8JsonWriter) primary =
        let check (name: string) value =
            writer.WriteBoolean(name, value)
            writer.Flush()

            if not value then
                failwith name

        let config = Directory.CreateDirectory(Path.Combine(primary, "config")).FullName
        let data = Directory.CreateDirectory(Path.Combine(primary, "data")).FullName
        let apps = Directory.CreateDirectory(Path.Combine(data, "applications")).FullName

        let before =
            "[Default Applications]\nx-scheme-handler/nxm=previous.desktop;\nx-scheme-handler/mailto=mail.desktop;\n"

        let mime = Path.Combine(config, "fixture-mimeapps.list")
        File.WriteAllText(mime, before)

        for name in [ "previous.desktop"; "later.desktop" ] do
            File.WriteAllText(
                Path.Combine(apps, name),
                "[Desktop Entry]\nType=Application\nExec=/bin/false %u\nMimeType=x-scheme-handler/nxm;\n"
            )

        let linux =
            LinuxLinkSetup(
                Path.Combine(primary, "setup-state"),
                config,
                data,
                [ "fixture" ],
                [],
                []
            )
            :> ILinkSetup

        let added = linux.Add Environment.ProcessPath
        let removed = linux.Remove()

        check
            "linuxOptOutRestoresOnlyOwnedDefaultEntry"
            (added.Default = ModConductor.Desktop.LinkDefault.ModConductor
             && removed.Default = ModConductor.Desktop.LinkDefault.AnotherApp
             && File.ReadAllText mime = before)

        linux.Add Environment.ProcessPath |> ignore
        let later = before.Replace("previous.desktop", "later.desktop")
        File.WriteAllText(mime, later)
        linux.Remove() |> ignore

        check
            "linuxOptOutPreservesLaterChoiceAndOtherAssociations"
            (File.ReadAllText mime = later
             && File.Exists(Path.Combine(apps, "later.desktop")))

        let entries = System.Collections.Generic.Dictionary<string * string, string>()
        entries[("Software\\Classes\\Previous.Nxm", "")] <- "previous app"

        entries[("Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\nxm\\UserChoice",
                 "ProgId")] <- "Previous.Nxm"

        let mutable settings = 0

        let values =
            { new IWindowsLinkValues with
                member _.Read(path, name) =
                    match entries.TryGetValue((path, name)) with
                    | true, value -> Some value
                    | _ -> None

                member _.Write value =
                    entries[(value.Path, value.Name)] <- value.Value

                member _.Remove(path, name) = entries.Remove((path, name)) |> ignore

                member _.Default() =
                    ModConductor.Desktop.LinkDefault.AnotherApp

                member _.Changed() = () }

        let windows =
            WindowsLinkSetup(
                Path.Combine(primary, "windows-state"),
                values,
                fun () -> settings <- settings + 1
            )
            :> ILinkSetup

        let added = windows.Add Environment.ProcessPath
        windows.OpenSettings() |> ignore

        entries[("Software\\ModConductor\\NexusLinks\\Capabilities", "ApplicationName")] <-
            "later user value"

        windows.Remove() |> ignore

        check
            "windowsAbstractEffectsPreservePriorAndLaterValues"
            (added.Available = Some true
             && added.Default = ModConductor.Desktop.LinkDefault.AnotherApp
             && settings = 1
             && entries.Count = 3
             && entries[("Software\\Classes\\Previous.Nxm", "")] = "previous app"
             && entries[("Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\nxm\\UserChoice",
                         "ProgId")] = "Previous.Nxm")
