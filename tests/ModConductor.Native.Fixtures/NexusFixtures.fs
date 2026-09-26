namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials
open ModConductor.Nexus
open ModConductor.Engine
open ModConductor.HttpDownloads
open ModConductor.ArtifactLibrary
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.Protocol.V1

type internal NexusMemoryStore() =
    let mutable bytes: byte[] option = None
    let mutable saves = 0
    member _.Bytes = bytes |> Option.map Array.copy
    member _.Saves = saves

    interface ICredentialStore with
        member _.Kind = StorageKind.SecretService

        member _.Inspect _ =
            { Saved =
                (if bytes.IsSome then
                     SavedPresence.Present
                 else
                     SavedPresence.Absent)
              Problem = None }

        member _.Save(value, token) =
            token.ThrowIfCancellationRequested()
            bytes <- Some(Array.copy value)
            saves <- saves + 1
            Ok()

        member _.Read _ = Ok(bytes |> Option.map Array.copy)

        member _.Delete token =
            token.ThrowIfCancellationRequested()
            bytes <- None
            Ok()

module NexusFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private until predicate =
        let limit = DateTime.UtcNow.AddSeconds 15.

        while not (predicate ()) && DateTime.UtcNow < limit do
            Thread.Sleep 10

        if not (predicate ()) then
            failwith "The Nexus fixture did not reach the expected state."

    let private signIn (session: NexusSession) =
        session.SignIn() |> wait |> ignore
        until (fun () -> not session.Status.Waiting)

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) condition =
            writer.WriteBoolean(name, condition)
            writer.Flush()

            if not condition then
                failwith ("Nexus fixture failed: " + name)

        writer.WriteStartObject("nexus")
        use server = new NexusServer()
        let memory = NexusMemoryStore()
        use credentials = new CredentialSession(memory)

        let pausedAccounts = ResizeArray<string>()

        use session =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun subject ->
                    pausedAccounts.Add subject
                    Task.CompletedTask),
                requestInterval = TimeSpan.FromMilliseconds 5.
            )

        server.Mode <- "state"
        signIn session

        check
            "wrongStateCannotExchangeOrSave"
            (server.TokenCount = 0
             && memory.Saves = 0
             && session.Status.Problem = Some NexusProblem.InvalidCallback)

        server.Mode <- "issuer"
        signIn session
        check "suppliedWrongIssuerCannotExchangeOrSave" (server.TokenCount = 0 && memory.Saves = 0)
        server.Mode <- "redirect"
        signIn session
        server.Mode <- "duplicate"
        signIn session

        check
            "wrongRedirectAndDuplicateCallbackCannotExchange"
            (server.TokenCount = 0 && memory.Saves = 0)

        server.Mode <- "good"
        server.TokenSeconds <- 1
        signIn session

        writer.WriteString(
            "signInProblem",
            session.Status.Problem
            |> Option.map NexusProblem.message
            |> Option.defaultValue "none"
        )

        writer.WriteNumber("signInTokenPosts", server.TokenCount)
        writer.WriteNumber("signInSaves", memory.Saves)
        writer.WriteNumber("userInfoRequests", server.Count "/userinfo")

        check
            "pkceCallbackUserinfoCommitsRefreshOnly"
            (session.Status.Account |> Option.exists (fun a -> a.Subject = "42")
             && (memory.Bytes
                 |> Option.exists (fun bytes ->
                     let text = Encoding.UTF8.GetString bytes in

                     text.Contains("synthetic-refresh-secret")
                     && not (text.Contains("synthetic-access-secret")))))

        do
            use restored =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            let before = server.TokenCount
            let hold = server.HoldToken()
            let connecting = restored.ConnectSaved()
            until (fun () -> server.TokenCount > before)

            let reference = Guid.NewGuid()

            let link =
                "nxm://skyrimspecialedition/mods/64012/files/501?key=synthetic-nxm-private-grant&expires="
                + DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds().ToString()
                + "&user_id=42"

            if not (restored.AcceptNxm(reference, link)) then
                failwith "The startup NXM fixture link was not accepted."

            let nexus =
                new NexusService(
                    restored,
                    Unchecked.defaultof<_>,
                    Unchecked.defaultof<_>,
                    server.Handoff
                )

            use nxm =
                new NxmService(
                    restored,
                    Unchecked.defaultof<_>,
                    Unchecked.defaultof<_>,
                    Unchecked.defaultof<_>
                )

            let firstStatus =
                nexus.ReadNexusStatus(NexusStatusRequest(), Unchecked.defaultof<_>)

            let firstLink =
                nxm.ReadNexusLink(
                    NexusLinkRequest(Reference = reference.ToString("N")),
                    Unchecked.defaultof<_>
                )

            check
                "firstNexusStatusAndLinkWaitForSavedConnection"
                (not firstStatus.IsCompleted && not firstLink.IsCompleted)

            hold.TrySetResult() |> ignore
            connecting |> wait
            let status = firstStatus |> wait
            let resolved = firstLink |> wait

            check
                "firstNexusStatusAndLinkUseRestoredAccount"
                (status.AccountName = "Rowan"
                 && not resolved.SignInRequired
                 && resolved.Problem = ""
                 && resolved.File.Id = 501L)

        let before = server.TokenCount
        let a = session.ReadMod("skyrimspecialedition", 64012L)
        let b = session.ReadMod("skyrimspecialedition", 64012L)
        Task.WhenAll(a, b) |> wait |> Array.iter (fun value -> result value |> ignore)
        check "parallelReadsShareOneRefresh" (server.TokenCount = before + 1)
        let saved = memory.Saves
        server.Subject <- "99"
        session.Connect() |> wait |> ignore

        check
            "refreshCannotChangeAccountOrReplaceSavedBinding"
            (session.Status.Problem = Some NexusProblem.AccountChanged
             && memory.Saves = saved)

        session.Disconnect token |> wait |> ignore
        check "disconnectRetainsAccountScopeAfterValidationFailure" (pausedAccounts.Contains "42")
        server.Subject <- "42"
        signIn session
        let before = server.TokenCount
        server.Mode <- "token-uncertain"
        session.Connect() |> wait |> ignore

        check
            "uncertainRefreshPostIsNotRetried"
            (server.TokenCount = before + 1
             && session.Status.Problem = Some NexusProblem.Offline)

        server.Mode <- "offline"
        let beforeReads = server.Count "/api/games/skyrimspecialedition.json"
        let unavailable = session.ReadMod("skyrimspecialedition", 64012L) |> wait

        check
            "transientReadsStopAfterThreeAttempts"
            (server.Count "/api/games/skyrimspecialedition.json" = beforeReads + 3
             && unavailable = Error NexusProblem.Offline)

        server.Mode <- "rate"
        let limited = session.ReadMod("skyrimspecialedition", 64012L) |> wait

        check
            "rateWaitIsStructuredAndContainsNoProviderBody"
            (match limited with
             | Error(NexusProblem.RateLimited _) -> true
             | _ -> false)

        server.Mode <- "good"
        // A separate account session does not inherit a different instance's rate window.
        use racer =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        racer.Connect() |> wait |> ignore
        let before = server.TokenCount
        let hold = server.HoldToken()
        let connecting = racer.Connect()
        until (fun () -> server.TokenCount > before)
        let removed = racer.Disconnect token |> wait
        hold.TrySetResult() |> ignore
        connecting |> wait |> ignore

        check
            "disconnectPreventsLateRefreshResurrection"
            (removed.Saved = SavedPresence.Absent
             && memory.Bytes.IsNone
             && racer.Status.Account.IsNone)

        signIn racer
        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()
        let cancelledRemoval = racer.Disconnect cancelled.Token |> wait
        racer.Connect() |> wait |> ignore

        check
            "cancelledRemovalDoesNotBlockExplicitReconnect"
            (cancelledRemoval.Saved = SavedPresence.Present
             && cancelledRemoval.RemovalProblem = Some StorageProblem.Cancelled
             && racer.Status.Account.IsSome)

        do
            use restoring =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            let before = server.TokenCount
            let hold = server.HoldToken()
            let connecting = restoring.ConnectSaved()
            until (fun () -> server.TokenCount > before)
            let firstRead = restoring.ReadMod("skyrimspecialedition", 64012L)
            let removed = restoring.Disconnect token |> wait
            hold.TrySetResult() |> ignore
            connecting |> wait
            let afterDisconnect = firstRead |> wait

            check
                "disconnectWinsDuringSavedConnectionAndFirstRead"
                (removed.Saved = SavedPresence.Absent
                 && restoring.Status.Account.IsNone
                 && afterDisconnect = Error NexusProblem.SignInRequired)

        writer.WriteEndObject()

        writer.WriteStartObject("nexusPersonalApiKey")
        use keyServer = new NexusServer()
        let rejectedMemory = NexusMemoryStore()

        do
            use rejectedCredentials = new CredentialSession(rejectedMemory)

            use rejectedSession =
                new NexusSession(
                    rejectedCredentials,
                    Some keyServer.Registration,
                    keyServer.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            let invalid = rejectedSession.SubmitPersonalApiKey("wrong-key") |> wait

            check
                "invalidPersonalApiKeyIsRejectedBeforeSave"
                (invalid.Problem = Some NexusProblem.InvalidApiKey && rejectedMemory.Saves = 0)

            keyServer.Mode <- "offline"
            let offline = rejectedSession.SubmitPersonalApiKey("synthetic-personal-key") |> wait

            check
                "offlinePersonalApiKeyValidationIsStructured"
                (offline.Problem = Some NexusProblem.Offline && rejectedMemory.Saves = 0)

            let apiRequests = keyServer.ApiKeyRequests
            rejectedSession.ConnectSaved() |> wait

            check
                "startupWithoutSavedKeyDoesNotConnect"
                (rejectedSession.Status.Account.IsNone && keyServer.ApiKeyRequests = apiRequests)

        use rateServer = new NexusServer()
        let rateMemory = NexusMemoryStore()

        do
            use rateCredentials = new CredentialSession(rateMemory)

            use rateSession =
                new NexusSession(
                    rateCredentials,
                    Some rateServer.Registration,
                    rateServer.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            rateServer.Mode <- "rate"
            let limited = rateSession.SubmitPersonalApiKey("synthetic-personal-key") |> wait

            check
                "rateLimitedPersonalApiKeyValidationIsStructured"
                (match limited.Problem with
                 | Some(NexusProblem.RateLimited _) -> rateMemory.Saves = 0
                 | _ -> false)

        let revokedDuringInteraction mode path =
            use server = new NexusServer()
            use credentials = new CredentialSession(NexusMemoryStore())

            use session =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            session.SubmitPersonalApiKey("synthetic-personal-key") |> wait |> ignore
            server.Mode <- mode

            session.RefreshInteractions(
                { Game = "skyrimspecialedition"
                  Mod = 64012L }
            )
            |> wait
            |> ignore

            session.Status, server.Count path

        let revokedByTracking, trackingRequests =
            revokedDuringInteraction "invalid-tracking-key" "/api/user/tracked_mods.json"

        check
            "revokedPersonalApiKeyDuringTrackingClearsActiveAccount"
            (trackingRequests = 1
             && revokedByTracking.Account.IsNone
             && revokedByTracking.Problem = Some NexusProblem.InvalidApiKey)

        let revokedByEndorsement, endorsementRequests =
            revokedDuringInteraction "invalid-endorsement-key" "/api/user/endorsements.json"

        check
            "revokedPersonalApiKeyDuringEndorsementClearsActiveAccount"
            (endorsementRequests = 1
             && revokedByEndorsement.Account.IsNone
             && revokedByEndorsement.Problem = Some NexusProblem.InvalidApiKey)

        use secureServer = new NexusServer()
        let secureMemory = NexusMemoryStore()
        let securePaused = ResizeArray<string>()

        do
            use secureCredentials = new CredentialSession(secureMemory)

            use secureSession =
                new NexusSession(
                    secureCredentials,
                    Some secureServer.Registration,
                    secureServer.Handoff,
                    (fun subject ->
                        securePaused.Add subject
                        Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            let connected = secureSession.SubmitPersonalApiKey("synthetic-personal-key") |> wait

            let queried = secureSession.ReadMod("skyrimspecialedition", 64012L) |> wait

            let linked =
                secureSession.Resolve("skyrimspecialedition", 64012L, 501L, "42") |> wait

            let identity =
                { Game = "skyrimspecialedition"
                  Mod = 64012L }

            let interactions = secureSession.RefreshInteractions(identity) |> wait

            let changed =
                secureSession.ChangeInteraction(
                    identity,
                    interactions.Revision,
                    NexusInteraction.Track,
                    "1.4"
                )
                |> wait

            check
                "personalApiKeyAuthorizesValidationQueriesMutationsAndDownloadLinks"
                (connected.Account
                 |> Option.exists (fun value ->
                     value.Subject = "42" && value.Name = "Rowan" && value.Premium = Some true)
                 && Result.isOk queried
                 && Result.isOk linked
                 && changed.Tracking = Some true
                 && changed.Problem.IsNone
                 && secureServer.ApiKeyRequests >= 3)

            let beforeStaleInteraction, _ = secureSession.StatusWithRevision
            let writesBeforeStaleInteraction = secureServer.Writes

            let staleInteraction =
                secureSession.ChangeInteraction(
                    identity,
                    interactions.Revision,
                    NexusInteraction.Track,
                    "1.4"
                )
                |> wait

            let afterStaleInteraction, staleStatus = secureSession.StatusWithRevision

            check
                "staleInteractionRejectsWithoutWriteAndPreservesConnectionError"
                (staleInteraction.Problem = Some NexusProblem.InteractionUnknown
                 && secureServer.Writes = writesBeforeStaleInteraction
                 && afterStaleInteraction = beforeStaleInteraction + 1L
                 && staleStatus.Problem = Some NexusProblem.InteractionUnknown
                 && (secureSession.InteractionState identity).Tracking = Some true)

            let beforeRejectedDownloads, _ = secureSession.StatusWithRevision
            let downloadRequests = secureServer.ApiKeyRequests

            let invalidDownload =
                secureSession.Resolve("skyrimspecialedition", 64012L, 0L, "42") |> wait

            let afterInvalidDownload, invalidDownloadStatus = secureSession.StatusWithRevision

            let wrongAccount =
                secureSession.Resolve("skyrimspecialedition", 64012L, 501L, "someone-else")
                |> wait

            let afterWrongAccount, wrongAccountStatus = secureSession.StatusWithRevision

            let missingLink =
                secureSession.Resolve(
                    "skyrimspecialedition",
                    64012L,
                    501L,
                    "42",
                    requiresLink = true
                )
                |> wait

            let afterMissingLink, missingLinkStatus = secureSession.StatusWithRevision

            check
                "downloadRejectionsUpdateConnectionProblemWithoutContactingNexus"
                (invalidDownload = Error NexusProblem.NotFound
                 && wrongAccount = Error NexusProblem.DownloadAccount
                 && missingLink = Error NexusProblem.DownloadLinkNeeded
                 && afterInvalidDownload = beforeRejectedDownloads + 1L
                 && invalidDownloadStatus.Problem = Some NexusProblem.NotFound
                 && afterWrongAccount = afterInvalidDownload + 1L
                 && wrongAccountStatus.Problem = Some NexusProblem.DownloadAccount
                 && afterMissingLink = afterWrongAccount + 1L
                 && missingLinkStatus.Problem = Some NexusProblem.DownloadLinkNeeded
                 && (missingLinkStatus.Account |> Option.exists (fun value -> value.Subject = "42"))
                 && secureServer.ApiKeyRequests = downloadRequests)

            let savedBeforeRejectedCandidate = secureMemory.Bytes
            let rejectedCandidate = secureSession.SubmitPersonalApiKey("wrong-key") |> wait

            let queryAfterRejectedCandidate =
                secureSession.ReadMod("skyrimspecialedition", 64012L) |> wait

            check
                "rejectedPersonalApiKeyDoesNotReplaceActiveOrSavedCredential"
                (rejectedCandidate.Problem = Some NexusProblem.InvalidApiKey
                 && rejectedCandidate.Account |> Option.exists (fun value -> value.Subject = "42")
                 && Result.isOk queryAfterRejectedCandidate
                 && secureMemory.Bytes = savedBeforeRejectedCandidate)

            secureServer.Premium <- false
            let freeAccount = secureSession.CheckAccount() |> wait
            secureServer.Mode <- "entitlement"

            let freeDownload =
                secureSession.Resolve("skyrimspecialedition", 64012L, 503L, "42") |> wait

            check
                "personalApiKeyKeepsPremiumAsAccountEntitlement"
                (freeAccount.Account |> Option.exists (fun value -> value.Premium = Some false)
                 && freeDownload = Error NexusProblem.Entitlement)

        do
            use invalidCredentials = new CredentialSession(secureMemory)

            use invalidSession =
                new NexusSession(
                    invalidCredentials,
                    Some secureServer.Registration,
                    secureServer.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            secureServer.Mode <- "invalid-key"
            invalidSession.ConnectSaved() |> wait

            check
                "invalidSavedPersonalApiKeyReportsFailure"
                (invalidSession.Status.Account.IsNone
                 && invalidSession.Status.Problem = Some NexusProblem.InvalidApiKey)

        do
            use restoredCredentials = new CredentialSession(secureMemory)

            use restoredSession =
                new NexusSession(
                    restoredCredentials,
                    Some secureServer.Registration,
                    secureServer.Handoff,
                    (fun subject ->
                        securePaused.Add subject
                        Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            secureServer.Mode <- "good"
            restoredSession.ConnectSaved() |> wait
            let restored = restoredSession.Status

            check
                "savedPersonalApiKeyRestoresOnlyInsideEngine"
                (restored.Account |> Option.exists (fun value -> value.Subject = "42"))

            secureServer.Mode <- "invalid-key"
            let revoked = restoredSession.CheckAccount() |> wait

            check
                "revokedPersonalApiKeyClearsActiveAccount"
                (revoked.Account.IsNone && revoked.Problem = Some NexusProblem.InvalidApiKey)

            secureServer.Mode <- "good"
            let removed = restoredSession.Disconnect token |> wait

            check
                "disconnectRemovesPersonalApiKeyAndPausesItsAccount"
                (removed.Saved = SavedPresence.Absent
                 && secureMemory.Bytes.IsNone
                 && securePaused.Contains "42")

        use sessionServer = new NexusServer()
        let sessionMemory = NexusMemoryStore()

        do
            use sessionCredentials = new CredentialSession(sessionMemory)
            sessionCredentials.SetMode(StorageMode.SessionOnly, token) |> wait |> ignore

            use personalSession =
                new NexusSession(
                    sessionCredentials,
                    Some sessionServer.Registration,
                    sessionServer.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            personalSession.SubmitPersonalApiKey("synthetic-personal-key") |> wait |> ignore

            let status = sessionCredentials.Status token |> wait

            check
                "sessionOnlyPersonalApiKeyIsNotSaved"
                (status.HasSession
                 && status.Saved = SavedPresence.Absent
                 && sessionMemory.Bytes.IsNone)

        do
            use restartedCredentials = new CredentialSession(sessionMemory)

            use restartedSession =
                new NexusSession(
                    restartedCredentials,
                    Some sessionServer.Registration,
                    sessionServer.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            let restarted = restartedSession.Connect() |> wait

            check
                "sessionOnlyPersonalApiKeyDoesNotSurviveRestart"
                (restarted.Account.IsNone && restarted.Problem = Some NexusProblem.SignInRequired)

        writer.WriteEndObject()

        writer.WriteStartObject("nexusDownloads")
        use server = new NexusServer()
        let memory = NexusMemoryStore()
        use credentials = new CredentialSession(memory)
        let mutable storeRef: OperationStore option = None

        use session =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun subject ->
                    match storeRef with
                    | Some store -> store.Downloads.PauseAccount(subject) :> Task
                    | None -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        session.SubmitPersonalApiKey("synthetic-personal-key") |> wait |> ignore

        let area =
            Directory.CreateDirectory(Path.Combine(primary, "nexus-downloads")).FullName

        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace = Guid.NewGuid()

        use store =
            new OperationStore(
                state,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy =
                    { DownloadPolicy.Default with
                        CheckpointBytes = 16384L }
            )

        storeRef <- Some store

        (store.Workspaces :> IWorkspaceState)
            .Create(workspace, "Nexus fixture", StorageWorker.select root)
        |> wait
        |> result
        |> ignore

        let id = Guid.NewGuid()
        server.Slow <- true

        store.Downloads.Start
            { Id = id
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
        |> wait
        |> result
        |> ignore

        let read () =
            store.Artifacts.Read(workspace, id) |> wait |> result

        until (fun () -> (read ()).Download.Value.Bytes >= 32768L)
        session.Disconnect token |> wait |> ignore
        let paused = read ()

        check
            "disconnectPausesOwnedTransferAndRetainsBytes"
            (paused.Download.Value.State = DownloadState.Paused
             && paused.Download.Value.Bytes >= 32768L)

        check "signedArtifactRequestHasNoPrivateCredential" (not server.PrivateHeader)
        server.Subject <- "99"
        signIn session

        store.Downloads.Control(workspace, id, DownloadAction.Resume)
        |> wait
        |> result
        |> ignore

        until (fun () -> (read ()).Download.Value.State = DownloadState.Failed)

        check
            "oldAccountTransferDoesNotClearNewValidAccount"
            (session.Status.Account |> Option.exists (fun account -> account.Subject = "99")
             && (read ()).Download.Value.Bytes = paused.Download.Value.Bytes)

        session.Disconnect token |> wait |> ignore
        server.Subject <- "42"
        signIn session
        server.DownloadKey <- "synthetic-signed-key-B"
        server.Mode <- "link-refused"

        store.Downloads.Control(workspace, id, DownloadAction.Resume)
        |> wait
        |> result
        |> ignore

        until (fun () -> (read ()).Download.Value.State = DownloadState.Failed)
        let refused = read ()

        let linkRequests =
            server.Count "/api/games/skyrimspecialedition/mods/64012/files/501/download_link.json"

        server.Mode <- "good"
        server.DownloadKey <- "synthetic-signed-key-C"

        store.Downloads.Control(workspace, id, DownloadAction.Resume)
        |> wait
        |> result
        |> ignore

        until (fun () -> (read ()).Download.Value.State = DownloadState.Failed)

        check
            "refusedLeaseIsDiscardedBeforeExplicitRetry"
            (not refused.Download.Value.RestartRequired
             && refused.Download.Value.Bytes = paused.Download.Value.Bytes
             && server.Count
                 "/api/games/skyrimspecialedition/mods/64012/files/501/download_link.json" = linkRequests
                                                                                             + 1)

        let changed = read ()

        check
            "changedLinkRequiresExplicitRestart"
            (changed.Download.Value.RestartRequired
             && changed.Download.Value.Bytes = paused.Download.Value.Bytes
             && server.Ranges > 0)

        server.Slow <- false

        store.Downloads.Control(workspace, id, DownloadAction.Restart)
        |> wait
        |> result
        |> ignore

        until (fun () -> (read ()).Download.Value.State = DownloadState.Complete)
        let complete = read ()

        check
            "restartPublishesThroughExistingArtifactOwner"
            (complete.Length = Some 1048576L
             && complete.Download.Value.Source = "Nexus Mods"
             && complete.OriginalPath = "Nexus Mods")

        use redirectServer = new NexusServer()
        server.DownloadBase <- redirectServer.Root
        redirectServer.PayloadRedirect <- server.Root
        let redirectedId = Guid.NewGuid()
        let originalPayloadRequests = server.Count "/payload"

        store.Downloads.Start
            { Id = redirectedId
              WorkspaceId = workspace
              Name = "Redirected rivers.7z"
              Sources =
                [ DownloadSource.Nexus
                      { Account = "42"
                        Game = "skyrimspecialedition"
                        ModId = 64012L
                        FileId = 502L
                        Keyed = false
                        Version = None } ]
              ExpectedLength = Some 1048576L
              ExpectedSha256 = None }
        |> wait
        |> result
        |> ignore

        until (fun () ->
            let redirected = store.Artifacts.Read(workspace, redirectedId) |> wait |> result
            redirected.Download.Value.State = DownloadState.Complete)

        check
            "nexusDownloadFollowsReturnedUrlAndRedirectAcrossServers"
            (redirectServer.Count "/payload" > 0
             && server.Count "/payload" > originalPayloadRequests
             && not redirectServer.PrivateHeader
             && not server.PrivateHeader)

        use db =
            new Microsoft.Data.Sqlite.SqliteConnection(
                "Data Source=" + Path.Combine(state, "state.db")
            )

        db.Open()
        use query = db.CreateCommand()

        query.CommandText <-
            "SELECT sources,effective_url FROM artifact_downloads WHERE artifact_id=$id"

        query.Parameters.AddWithValue("$id", string id) |> ignore
        use row = query.ExecuteReader()

        if not (row.Read()) then
            failwith "The Nexus transfer row is missing."

        let durable = row.GetString(0) + row.GetString(1)

        check
            "durableTransferContainsReferenceAndFingerprintOnly"
            (durable.Contains("nexus:/42/skyrimspecialedition/64012/501")
             && not (durable.Contains("http"))
             && not (durable.Contains("secret"))
             && not (durable.Contains("signed-key")))

        writer.WriteEndObject()

    let engine state info =
        use server = new NexusServer()
        File.WriteAllText(info, server.Root)

        ModConductor.Engine.Program.runWithNexus
            (Some server.Registration)
            server.Handoff
            [| "--state-directory"; state |]
