namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Credentials
open ModConductor.Deployment
open ModConductor.Engine
open ModConductor.Executables
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.ModSelection
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse
open ModConductor.Workspaces

module SkseCoordinatorFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private check (writer: Utf8JsonWriter) (name: string) (value: bool) =
        writer.WriteBoolean(name, value)
        writer.Flush()

        if not value then
            failwith ("SKSE coordinator fixture failed: " + name)

    let private until label read predicate =
        let deadline = DateTime.UtcNow.AddSeconds 30.
        let mutable value = read ()

        while not (predicate value) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            value <- read ()

        if not (predicate value) then
            failwith ("Timed out waiting for " + label + ".")

        value

    let private signIn (session: NexusSession) =
        session.SignIn() |> wait |> ignore

        until "Nexus sign-in" (fun () -> session.Status) (fun status ->
            not status.Waiting && status.Account.IsSome)
        |> ignore

    let private archive (runtime: string) (marker: string) (includeScripts: bool) (padding: int) =
        use output = new MemoryStream()
        use zip = new ZipArchive(output, ZipArchiveMode.Create, true)

        let write name (bytes: byte array) =
            use target = zip.CreateEntry(name, CompressionLevel.NoCompression).Open()
            target.Write bytes

        let root = "skse64_" + marker + "/"
        write (root + "skse64_loader.exe") (Encoding.UTF8.GetBytes("loader-" + marker))

        write
            (root + "skse64_" + runtime.Replace('.', '_') + ".dll")
            (Encoding.UTF8.GetBytes("runtime-" + marker))

        write (root + "skse64_steam_loader.dll") (Encoding.UTF8.GetBytes("steam-" + marker))

        if includeScripts then
            write (root + "Data/Scripts/skse.pex") (Encoding.UTF8.GetBytes("script-" + marker))

        if padding > 0 then
            write (root + "padding.bin") (Array.init padding (fun index -> byte (index % 251)))

        zip.Dispose()
        output.ToArray()

    let private policy =
        { DownloadPolicy.Default with
            Attempts = 1
            RetryDelay = TimeSpan.Zero
            CheckpointBytes = 4096L }

    let private createWorkspace (store: OperationStore) area =
        let workspace, profile, game, proton, saved =
            SkyrimFixtureWorkspace.create store area "SKSE coordinator" "workspace" "installation" true

        saved |> result |> ignore
        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result
        workspace, profile, game, proton, context

    let private configure
        (server: NexusServer)
        (runtime: string)
        (id: int64)
        (version: string)
        (bytes: byte array)
        =
        server.Payload <- bytes

        server.SkseFiles <-
            [ id, "skse-" + string id + ".zip", version, "Current game version " + runtime + " from Steam" ]

    let private nxm id user expiry =
        "nxm://skyrimspecialedition/mods/30379/files/"
        + string id
        + "?key=synthetic-nxm-private-grant&expires="
        + string expiry
        + "&user_id="
        + user

    let private accept (session: NexusSession) (coordinator: SkseCoordinator) input =
        let id = Guid.NewGuid()

        if not (session.AcceptNxm(id, input)) then
            failwith "The SKSE NXM fixture link was not admitted."

        coordinator.AcceptNxm id

    let private view (coordinator: SkseCoordinator) workspace profile =
        coordinator.Read(workspace, profile) |> wait

    let private status (store: OperationStore) workspace profile =
        store.SkseLoaders.ReadStatus(workspace, profile) |> wait

    let private waitForStatus store workspace profile expected =
        until
            ("durable SKSE status " + expected)
            (fun () -> status store workspace profile)
            (Option.exists (fun value -> value.Phase = expected))
        |> Option.get

    let private download (store: OperationStore) workspace name bytes =
        use server = new DownloadServer(bytes)
        let id = Guid.NewGuid()
        let hash = Convert.ToHexStringLower(SHA256.HashData bytes)

        store.Downloads.Start
            { Id = id
              WorkspaceId = workspace
              Name = name
              Sources = [ DownloadSource.Url(server.Url + "/good") ]
              ExpectedLength = Some(int64 bytes.Length)
              ExpectedSha256 = Some hash }
        |> wait
        |> result
        |> ignore

        until
            "validated cached SKSE artifact"
            (fun () -> store.Artifacts.Read(workspace, id) |> wait |> result)
            (fun artifact -> artifact.State = ArtifactState.Ready)

    type private SetupSnapshot =
        { Active: Guid option
          Enabled: Set<Guid>
          Loader: ComponentLoader option }

    let private snapshot (store: OperationStore) workspace profile =
        let deployed = store.Deployments.Read profile |> wait |> result
        let inventory = InventoryObservations.read store profile

        let enabled =
            inventory.Entries
            |> List.choose (fun row ->
                match row.Entry.Selection with
                | SelectionState.Managed(_, true) -> Some row.Entry.Mod.Id
                | _ -> None)
            |> Set.ofList

        { Active = deployed.ActiveGeneration
          Enabled = enabled
          Loader =
            (store.SkseLoaders :> IComponentLoaderSelection)
                .Read(workspace, profile, deployed.ActiveGeneration)
            |> wait }

    let private nxmFailure
        (area: string)
        (mode: string)
        (linkUser: string)
        (expiry: int64)
        (stopDownloads: bool)
        (expected: string)
        =
        Directory.CreateDirectory area |> ignore
        use server = new NexusServer()
        server.Premium <- false
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

        signIn session

        let store =
            new OperationStore(
                Path.Combine(area, "state"),
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let workspace, profile, _, _, context = createWorkspace store area
        let runtime = context.Binding.Value.Evidence.Executable.Value.FileVersion
        let fileId = 300L
        configure server runtime fileId "2.2.0" (archive runtime "nxm-failure" true 0)

        let coordinator =
            new SkseCoordinator(session, store.Downloads, store.GameContexts, store, server.Handoff)

        let waiting = coordinator.Start(workspace, profile) |> wait

        if waiting.Phase <> SksePhase.WaitingForNexus then
            failwith "The SKSE fixture did not enter the Nexus handoff state."

        if stopDownloads then
            store.Downloads.Stop() |> wait

        server.Mode <- mode
        accept session coordinator (nxm fileId linkUser expiry)

        let failed =
            until
                "coordinator NXM failure"
                (fun () -> view coordinator workspace profile)
                (fun value -> value.Phase = SksePhase.Failed)

        let observed =
            failed.Status.Contains(expected, StringComparison.OrdinalIgnoreCase)
            || failed.Detail.Contains(expected, StringComparison.OrdinalIgnoreCase)

        (coordinator :> IDisposable).Dispose()
        (store :> IDisposable).Dispose()

        use reopened = new OperationStore(Path.Combine(area, "state"))

        observed
        && (reopened.SkseLoaders.ReadStatus(workspace, profile)
            |> wait
            |> Option.exists (fun value ->
                value.Phase = "failed"
                && value.Status = failed.Status
                && value.Detail = failed.Detail))

    let private nxmEvidence writer area =
        let correctArea =
            Directory.CreateDirectory(Path.Combine(area, "nxm-correct")).FullName

        use server = new NexusServer()
        server.Premium <- false
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

        signIn session

        use store =
            new OperationStore(
                Path.Combine(correctArea, "state"),
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let workspace, profile, _, _, context = createWorkspace store correctArea
        let runtime = context.Binding.Value.Evidence.Executable.Value.FileVersion
        let fileId = 301L
        configure server runtime fileId "2.2.0" (archive runtime "nxm-correct" true 0)

        use coordinator =
            new SkseCoordinator(session, store.Downloads, store.GameContexts, store, server.Handoff)

        let waiting = coordinator.Start(workspace, profile) |> wait
        let expiry = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()
        accept session coordinator (nxm fileId "42" expiry)

        let ready =
            until
                "coordinator NXM installation"
                (fun () -> view coordinator workspace profile)
                (fun value -> value.Phase = SksePhase.Ready || value.Phase = SksePhase.Failed)

        let launch = store.GameLaunching.Read(workspace, profile) |> wait |> result

        check
            writer
            "acceptNxmCompletesExpectedHandoff"
            (waiting.Phase = SksePhase.WaitingForNexus
             && ready.Phase = SksePhase.Ready
             && launch.Problem.IsNone)

        check
            writer
            "acceptNxmWrongAccountIsDurable"
            (nxmFailure
                (Path.Combine(area, "nxm-wrong-account"))
                "good"
                "77"
                expiry
                false
                "another Nexus account")

        check
            writer
            "acceptNxmExpiredIsDurable"
            (nxmFailure (Path.Combine(area, "nxm-expired")) "good" "42" 1L false "expired")

        check
            writer
            "acceptNxmMetadataFailureIsDurable"
            (nxmFailure
                (Path.Combine(area, "nxm-metadata"))
                "metadata-error"
                "42"
                expiry
                false
                "not available")

        check
            writer
            "acceptNxmRateLimitIsDurable"
            (nxmFailure (Path.Combine(area, "nxm-rate")) "rate" "42" expiry false "limit")

        check
            writer
            "acceptNxmOutageIsDurable"
            (nxmFailure
                (Path.Combine(area, "nxm-outage"))
                "offline"
                "42"
                expiry
                false
                "not available")

        check
            writer
            "acceptNxmDownloadStartFailureIsDurable"
            (nxmFailure
                (Path.Combine(area, "nxm-download-start"))
                "good"
                "42"
                expiry
                true
                "could not start")

    let private offlineCacheEvidence writer area =
        let scenario =
            Directory.CreateDirectory(Path.Combine(area, "offline-cache")).FullName

        let statePath = Path.Combine(scenario, "state")
        use server = new NexusServer()
        server.Premium <- true
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

        signIn session
        let mutable workspace = Guid.Empty
        let mutable profile = Guid.Empty
        let mutable gamePath = ""
        let mutable protonSelection = None

        do
            use store =
                new OperationStore(
                    statePath,
                    nexusLinks = NexusDownloadLinks(session),
                    downloadPolicy = policy
                )

            let workspaceId, profileId, game, proton, context = createWorkspace store scenario
            workspace <- workspaceId
            profile <- profileId
            gamePath <- game
            protonSelection <- if OperatingSystem.IsLinux() then Some proton else None
            let evidence = context.Binding.Value.Evidence.Executable.Value
            let bytes = archive evidence.FileVersion "cached" true 0
            let artifact = download store workspace "cached-skse.zip" bytes

            let file =
                { Id = 401L
                  Name = "cached-skse.zip"
                  Version = "2.2.0"
                  Category = "Main files"
                  Description = "Current game version " + evidence.FileVersion + " from Steam"
                  Bytes = Some(int64 bytes.Length) }

            store.SkseLoaders.SaveArtifactSelection(
                artifact,
                { ArtifactId = Some artifact.Id
                  WorkspaceId = workspace
                  ProfileId = Some profile
                  AccountId = "42"
                  GameVersion = evidence.FileVersion
                  GameSha256 = evidence.Sha256
                  Selection =
                    { Release =
                        { ModId = SkseResolver.NexusModId
                          File = file
                          ComponentVersion = Version(2, 2, 0)
                          RuntimeVersion = Version.Parse evidence.FileVersion }
                      Acquisition = SkseAcquisition.Direct }
                  CheckedAt = DateTimeOffset.UtcNow }
            )
            |> wait

        server.Mode <- "offline"

        use restarted =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let staleContext =
            (restarted.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (restarted.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                staleContext.Revision,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = gamePath
                  Proton = protonSelection }
            )
        |> wait
        |> result
        |> ignore

        use coordinator =
            new SkseCoordinator(
                session,
                restarted.Downloads,
                restarted.GameContexts,
                restarted,
                server.Handoff
            )

        let metadataRequests () =
            [ "/api/games/skyrimspecialedition.json"
              "/api/games/skyrimspecialedition/mods/30379.json"
              "/api/games/skyrimspecialedition/mods/30379/files.json" ]
            |> List.sumBy server.Count

        let beforeLocal = metadataRequests ()
        let cold = coordinator.Read(workspace, profile) |> wait
        let absentCheck = coordinator.CheckUpdate(workspace, profile) |> wait
        let beforeChoice = restarted.SkseLoaders.ReadStored(workspace, profile, None) |> wait
        let started = coordinator.Start(workspace, profile) |> wait
        let afterLocal = metadataRequests ()
        let ready = waitForStatus restarted workspace profile "current"
        let launch = restarted.GameLaunching.Read(workspace, profile) |> wait |> result

        check
            writer
            "coldCoordinatorUsesRetainedArchiveWithoutNexus"
            (cold.Phase = SksePhase.Available
             && absentCheck.Phase = SksePhase.Available
             && beforeChoice.IsNone
             && started.Phase = SksePhase.Downloading
             && afterLocal = beforeLocal
             && ready.Phase = "current"
             && launch.Problem.IsNone)

        let deployed = restarted.Deployments.Read profile |> wait |> result

        let firstLoader =
            restarted.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)
            |> wait
            |> Option.get

        let beforeRemove = metadataRequests ()
        let removed = coordinator.Remove(workspace, profile, CancellationToken.None) |> wait
        let afterRemove = metadataRequests ()
        let restartedSetup = coordinator.Start(workspace, profile) |> wait
        waitForStatus restarted workspace profile "current" |> ignore
        let afterReinstall = metadataRequests ()
        let deployed = restarted.Deployments.Read profile |> wait |> result

        let secondLoader =
            restarted.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)
            |> wait
            |> Option.get

        check
            writer
            "localRemovalAndReinstallReuseRetainedSkseImport"
            (removed.Phase = SksePhase.Available
             && restartedSetup.Phase = SksePhase.Downloading
             && beforeRemove = afterRemove
             && afterRemove = afterReinstall
             && firstLoader.ModId = secondLoader.ModId
             && firstLoader.VersionId = secondLoader.VersionId)

    let private restoredLaunchEvidence
        writer statePath workspace profile restoredGeneration targetModId activeModId runtime =
        use restarted = new OperationStore(statePath)

        let restartedContext =
            (restarted.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (restarted.GameContexts :> IGameContexts).Refresh(workspace, profile, restartedContext.Revision)
        |> wait
        |> result
        |> ignore

        let active =
            restarted.Deployments.Read profile
            |> wait
            |> Result.defaultWith (fun error -> failwith ("restarted deployment: " + string error))

        let ordinary =
            restarted.GameLaunching.Read(workspace, profile)
            |> wait
            |> Result.defaultWith (fun error ->
                failwith ("restarted launch lookup: " + string error))

        let workspaceState =
            (restarted.Workspaces :> IWorkspaceState).Read(workspace, None)
            |> wait
            |> Result.defaultWith (fun error -> failwith ("restarted workspace: " + string error))

        let request =
            { Id = Guid.NewGuid()
              WorkspaceId = workspace
              WorkspaceRevision = workspaceState.Workspace.Revision
              ProfileId = profile
              ContextRevision = ordinary.ContextRevision
              SourceToken = ordinary.SourceToken }

        let started =
            restarted.GameLaunching.Begin request
            |> wait
            |> Result.defaultWith (fun error -> failwith ("restarted launch: " + string error))

        let finished =
            until
                "rolled-back SKSE launch"
                (fun () -> restarted.Executables.Read(workspace, started.Id) |> wait |> result)
                (fun run -> run.Phase = RunPhase.Finished || run.Phase = RunPhase.Failed)

        let selected =
            restarted.SkseLoaders.ReadStored(workspace, profile, active.ActiveGeneration)
            |> wait

        let restoredSelection = InventoryObservations.read restarted profile

        let restoredEnabled =
            restoredSelection.Entries
            |> List.choose (fun row ->
                match row.Entry.Selection with
                | SelectionState.Managed(_, true) -> Some row.Entry.Mod.Id
                | _ -> None)
            |> Set.ofList

        let launchUsesLoader =
            match finished.Source with
            | RunSource.Game gameRun ->
                let selectedPath =
                    selected
                    |> Option.map (fun value ->
                        Path.Combine(active.RunnableRoot, Path.GetFileName value.Loader.Executable))

                if OperatingSystem.IsLinux() then
                    (gameRun.Launch.Arguments |> List.tryLast) = selectedPath
                else
                    selectedPath = Some gameRun.Launch.Executable
            | _ -> false

        check
            writer
            "savedGenerationRestoreRebuildsLoaderAfterRestart"
            (active.ActiveGeneration = Some restoredGeneration
             && ordinary.Problem.IsNone
             && selected
                |> Option.exists (fun value ->
                    value.Loader.GenerationId = restoredGeneration
                    && value.Loader.ComponentVersion = "2.2.0"
                    && value.Loader.RuntimeVersion = runtime)
             && restoredEnabled.Contains targetModId
             && not (restoredEnabled.Contains activeModId)
             && launchUsesLoader)


    let private installedEvidence writer area =
        let scenario =
            Directory.CreateDirectory(Path.Combine(area, "installed-orchestration")).FullName

        let statePath = Path.Combine(scenario, "state")
        use server = new NexusServer()
        server.Premium <- true
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

        signIn session
        let mutable failurePoint = ""

        let store =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy,
                skseCheckpoint =
                    (fun name _ ->
                        if name = failurePoint then
                            raise (OperationCanceledException("fixture " + name)))
            )

        let workspace, profile, game, proton, context = createWorkspace store scenario
        let runtime = context.Binding.Value.Evidence.Executable.Value.FileVersion
        let initialId = 501L
        configure server runtime initialId "2.2.0" (archive runtime "initial" true 0)

        let coordinator =
            new SkseCoordinator(session, store.Downloads, store.GameContexts, store, server.Handoff)

        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "current" |> ignore
        let initial = snapshot store workspace profile
        let initialGeneration = initial.Active.Value

        let requests () =
            [ "/api/games/skyrimspecialedition.json"
              "/api/games/skyrimspecialedition/mods/30379.json"
              "/api/games/skyrimspecialedition/mods/30379/files.json" ]
            |> List.sumBy server.Count
        let mutable localRequests = true
        let before = requests ()
        let current = coordinator.Read(workspace, profile) |> wait
        localRequests <- localRequests && requests () = before
        let before = requests ()
        let currentGate = coordinator.CheckBeforePlay(workspace, profile) |> wait
        localRequests <- localRequests && requests () = before

        let beforeHeld = server.Count "/api/games/skyrimspecialedition/mods/30379.json"
        server.HoldMetadata() |> ignore
        let pending = coordinator.CheckUpdate(workspace, profile)

        until
            "held SKSE update metadata"
            (fun () -> server.Count "/api/games/skyrimspecialedition/mods/30379.json")
            (fun count -> count > beforeHeld)
        |> ignore

        let duringCheck = coordinator.Read(workspace, profile) |> wait
        let duringPlay = coordinator.CheckBeforePlay(workspace, profile) |> wait
        let background = not pending.IsCompleted
        server.ReleaseMetadata()
        let noUpdate = pending |> wait

        check
            writer
            "backgroundUpdateCheckDoesNotHoldLocalActions"
            (background
             && duringCheck.Phase = SksePhase.Ready
             && Result.isOk duringPlay
             && noUpdate.Phase = SksePhase.Ready)

        let updateId = 502L
        configure server runtime updateId "2.3.0" (archive runtime "update" true 0)
        let before = requests ()
        let update = coordinator.Read(workspace, profile) |> wait
        localRequests <- localRequests && requests () = before
        let before = requests ()
        let updateGate = coordinator.CheckBeforePlay(workspace, profile) |> wait
        localRequests <- localRequests && requests () = before

        let beforeCheck = requests ()
        let confirmed = coordinator.CheckUpdate(workspace, profile) |> wait
        let visible = coordinator.Read(workspace, profile) |> wait
        let confirmedPlay = coordinator.CheckBeforePlay(workspace, profile) |> wait

        check
            writer
            "confirmedNewerSkseAppearsWithoutBlockingPlay"
            (confirmed.Phase = SksePhase.UpdateAvailable
             && confirmed.ComponentVersion = "2.3.0"
             && visible.Phase = SksePhase.UpdateAvailable
             && Result.isOk confirmedPlay
             && requests () > beforeCheck)

        configure server runtime initialId "2.2.0" (archive runtime "initial" true 0)
        let cleared = coordinator.CheckUpdate(workspace, profile) |> wait
        let clearedRead = coordinator.Read(workspace, profile) |> wait

        check
            writer
            "confirmedNoUpdateClearsPreviousUpdate"
            (cleared.Phase = SksePhase.Ready && clearedRead.Phase = SksePhase.Ready)

        let holdUpdate label =
            let endpoint = "/api/games/skyrimspecialedition/mods/30379.json"
            let before = server.Count endpoint
            server.HoldMetadata() |> ignore
            let pending = coordinator.CheckUpdate(workspace, profile)
            until label (fun () -> server.Count endpoint) (fun count -> count > before)
            |> ignore
            pending

        configure server runtime updateId "2.3.0" (archive runtime "update" true 0)
        let failedCheck = holdUpdate "held update check before failed SKSE setup"
        coordinator.Remove(workspace, profile, CancellationToken.None) |> wait |> ignore
        failurePoint <- "install-intent"
        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "failed" |> ignore
        failurePoint <- ""
        server.ReleaseMetadata()
        let failedCheckResult = failedCheck |> wait
        let retainedFailure = store.SkseLoaders.ReadStatus(workspace, profile) |> wait

        check
            writer
            "heldUpdateCannotReplaceConcurrentSetupFailure"
            (failedCheckResult.Phase = SksePhase.Failed
             && (retainedFailure |> Option.exists (fun state -> state.Phase = "failed")))

        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "current" |> ignore

        let cancelledCheck = holdUpdate "held update check before cancelled SKSE setup"
        coordinator.Remove(workspace, profile, CancellationToken.None) |> wait |> ignore
        coordinator.Cancel(workspace, profile) |> wait |> ignore
        server.ReleaseMetadata()
        cancelledCheck |> wait |> ignore
        let retainedCancellation = store.SkseLoaders.ReadStatus(workspace, profile) |> wait

        check
            writer
            "heldUpdateCannotReplaceConcurrentSetupCancellation"
            (retainedCancellation
             |> Option.exists (fun state ->
                 state.Phase = "available" && state.Status = "SKSE setup was cancelled"))

        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "current" |> ignore

        let beforeReplacementGeneration = (store.Deployments.Read profile |> wait |> result).ActiveGeneration.Value
        let beforeReplacementLoader =
            store.SkseLoaders.ReadStored(workspace, profile, Some beforeReplacementGeneration)
            |> wait
            |> Option.get

        let concurrentCheck = holdUpdate "held update check before SKSE reinstall"

        coordinator.Remove(workspace, profile, CancellationToken.None) |> wait |> ignore
        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "current" |> ignore
        server.ReleaseMetadata()
        let afterConcurrent = concurrentCheck |> wait
        let installedAfterConcurrent = coordinator.Read(workspace, profile) |> wait
        let currentStatus = store.SkseLoaders.ReadStatus(workspace, profile) |> wait
        let staleGenerationPublished =
            store.SkseLoaders.SaveCheckedUpdateStatus(
                beforeReplacementGeneration,
                beforeReplacementLoader.VersionId,
                currentStatus,
                { currentStatus.Value with Phase = "update"; ComponentVersion = "2.3.0" }
            )
            |> wait

        check
            writer
            "concurrentReinstallDoesNotPublishOldUpdateCheck"
            (afterConcurrent.Phase = SksePhase.Ready
             && installedAfterConcurrent.Phase = SksePhase.Ready
             && not staleGenerationPublished
             && (store.SkseLoaders.ReadStatus(workspace, profile) |> wait) = currentStatus)

        server.Mode <- "good"
        configure server runtime updateId "2.3.0" (archive runtime "update" true 0)
        coordinator.Start(workspace, profile) |> wait |> ignore
        waitForStatus store workspace profile "current" |> ignore
        let installedUpdate = snapshot store workspace profile

        let deployed = store.Deployments.Read profile |> wait |> result

        let targetLoader =
            store.SkseLoaders.ReadStored(workspace, profile, Some initialGeneration)
            |> wait
            |> Option.get

        let activeLoader =
            store.SkseLoaders.ReadStored(workspace, profile, installedUpdate.Active)
            |> wait
            |> Option.get

        let selectionRevision = (InventoryObservations.read store profile).SelectionRevision
        let operation = Guid.NewGuid()

        store.SkseLoaders.StageReplacement(
            operation,
            selectionRevision,
            Some activeLoader.ModId,
            { targetLoader with Loader = { targetLoader.Loader with GenerationId = operation } },
            workspace,
            profile
        )
        |> wait

        let prepared =
            store.Deployments.PrepareRetained(
                operation,
                deployed.Sources,
                Some initialGeneration,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        let restored =
            store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let preservedSetup = snapshot store workspace profile

        if
            installedUpdate.Active = Some initialGeneration
            || preservedSetup.Active <> Some restored.Proposed
        then
            failwith "The retained SKSE generation was not activated."

        GameContextFixtures.create game 105
        let changed = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                changed.Revision,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let incompatible = coordinator.Read(workspace, profile) |> wait
        let incompatibleGate = coordinator.CheckBeforePlay(workspace, profile) |> wait

        GameContextFixtures.create game 104

        let changedAgain =
            (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                changedAgain.Revision,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        server.Mode <- "offline"
        let beforeUnavailable = requests ()
        let unavailable = coordinator.Read(workspace, profile) |> wait
        let unavailableGate = coordinator.CheckBeforePlay(workspace, profile) |> wait
        localRequests <- localRequests && requests () = beforeUnavailable

        check
            writer
            "localSkseReadsAndPlayIgnoreNexusButRejectChangedGame"
            (current.Phase = SksePhase.Ready
             && localRequests
             && Result.isOk currentGate
             && update.Phase = SksePhase.Ready
             && Result.isOk updateGate
             && incompatible.Phase = SksePhase.Incompatible
             && Result.isError incompatibleGate
             && unavailable.Phase = SksePhase.Ready
             && Result.isOk unavailableGate)

        let failedReplacement fileId version bytes mode point changeGame =
            failurePoint <- point
            server.Mode <- mode
            configure server runtime fileId version bytes
            let started = coordinator.Start(workspace, profile) |> wait
            let during = coordinator.Read(workspace, profile) |> wait

            if changeGame then
                GameContextFixtures.create game 105
                let state = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

                (store.GameContexts :> IGameContexts)
                    .Save(
                        workspace,
                        profile,
                        state.Revision,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Proton = if OperatingSystem.IsLinux() then Some proton else None }
                    )
                |> wait
                |> result
                |> ignore

            let failed = waitForStatus store workspace profile "failed"
            let afterFailure = coordinator.Read(workspace, profile) |> wait
            let preserved = snapshot store workspace profile = preservedSetup
            failurePoint <- ""
            server.Mode <- "good"

            if changeGame then
                GameContextFixtures.create game 104
                let state = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

                (store.GameContexts :> IGameContexts)
                    .Save(
                        workspace,
                        profile,
                        state.Revision,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Proton = if OperatingSystem.IsLinux() then Some proton else None }
                    )
                |> wait
                |> result
                |> ignore

            started.Phase = SksePhase.Downloading
            && (during.Phase = SksePhase.Downloading
                || during.Phase = SksePhase.Installing
                || during.Phase = SksePhase.Failed)
            && afterFailure.Phase = SksePhase.Failed
            && afterFailure.Detail = failed.Detail
            && failed.Detail <> ""
            && preserved

        let beforeFailureStatus = store.SkseLoaders.ReadStatus(workspace, profile) |> wait
        let beforeFailureGeneration = (store.Deployments.Read profile |> wait |> result).ActiveGeneration.Value
        let beforeFailureLoader =
            store.SkseLoaders.ReadStored(workspace, profile, Some beforeFailureGeneration)
            |> wait
            |> Option.get

        let transfer =
            failedReplacement
                503L
                "2.4.0"
                (archive runtime "transfer" true 0)
                "link-refused"
                ""
                false

        let layout =
            failedReplacement 504L "2.5.0" (archive runtime "layout" false 0) "good" "" false

        let preparation =
            server.Slow <- true

            let outcome =
                failedReplacement
                    505L
                    "2.6.0"
                    (archive runtime "preparation" true (1024 * 1024))
                    "good"
                    ""
                    true

            server.Slow <- false
            outcome

        let deployment =
            failedReplacement
                506L
                "2.7.0"
                (archive runtime "deployment" true 0)
                "good"
                "install-intent"
                false

        let publication =
            failedReplacement
                507L
                "2.8.0"
                (archive runtime "publication" true 0)
                "good"
                "publication"
                false

        check
            writer
            "failedReplacementBoundariesPreserveInstalledSetup"
            (transfer && layout && preparation && deployment && publication)

        let staleFailurePublished =
            store.SkseLoaders.SaveCheckedUpdateStatus(
                beforeFailureGeneration,
                beforeFailureLoader.VersionId,
                beforeFailureStatus,
                { beforeFailureStatus.Value with Phase = "update"; ComponentVersion = "3.0.0" }
            )
            |> wait

        check
            writer
            "changedSetupStatusRejectsLateUpdatePublication"
            (not staleFailurePublished
             && (store.SkseLoaders.ReadStatus(workspace, profile)
                 |> wait
                 |> Option.exists (fun state -> state.Phase = "failed")))

        let beforeFailedCheck = requests ()
        let failedCheck = coordinator.CheckUpdate(workspace, profile) |> wait
        let afterFailedCheck = coordinator.Read(workspace, profile) |> wait

        check
            writer
            "installedLoaderChecksUpdatesWithoutClearingSetupFailure"
            (requests () > beforeFailedCheck
             && failedCheck.Phase = SksePhase.Failed
             && afterFailedCheck.Phase = SksePhase.Failed)

        (coordinator :> IDisposable).Dispose()
        (store :> IDisposable).Dispose()
        restoredLaunchEvidence
            writer statePath workspace profile restored.Proposed targetLoader.ModId activeLoader.ModId runtime

    let observe (writer: Utf8JsonWriter) primary =
        let area =
            Directory.CreateDirectory(Path.Combine(primary, "skse-coordinator")).FullName

        writer.WriteStartObject("skseCoordinator")
        nxmEvidence writer area
        offlineCacheEvidence writer area
        installedEvidence writer area
        GenerationCleanup.normalize area
        writer.WriteEndObject()
