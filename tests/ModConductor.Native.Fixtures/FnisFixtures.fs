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
open ModConductor.Engine
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.HttpDownloads
open ModConductor.ModSelection
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Workspaces

module FnisFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private check (writer: Utf8JsonWriter) (name: string) (value: bool) =
        writer.WriteBoolean(name, value)
        writer.Flush()

        if not value then
            failwith ("FNIS fixture failed: " + name)

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

    let private archive marker valid padding =
        use output = new MemoryStream()
        use zip = new ZipArchive(output, ZipArchiveMode.Create, true)

        let write name (bytes: byte array) =
            use target = zip.CreateEntry(name, CompressionLevel.NoCompression).Open()
            target.Write bytes

        let root = "FNIS Behavior SE 7_6/"

        if valid then
            write
                (root + FnisCatalogue.GeneratorPath)
                (Encoding.UTF8.GetBytes("generator-" + marker))

            write
                (root + "Data/meshes/actors/character/behaviors/0_master.hkx")
                (Encoding.UTF8.GetBytes("behavior-" + marker))
        else
            write (root + "Data/readme.txt") (Encoding.UTF8.GetBytes marker)

        if padding > 0 then
            write
                (root + "Data/tools/GenerateFNIS_for_Users/padding.bin")
                (Array.init padding (fun index -> byte (index % 251)))

        zip.Dispose()
        output.ToArray()

    let private policy =
        { DownloadPolicy.Default with
            Attempts = 1
            RetryDelay = TimeSpan.Zero
            CheckpointBytes = 4096L }

    let private createWorkspace (store: OperationStore) area =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))

        if OperatingSystem.IsLinux() then
            let launcher = Path.Combine(proton.RuntimeDirectory, "proton")
            File.WriteAllText(launcher, "#!/bin/sh\nexit 0\n")

            File.SetUnixFileMode(
                launcher,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

            File.WriteAllText(
                Path.Combine(proton.RuntimeDirectory, "toolmanifest.vdf"),
                "manifest { version 2 commandline \"/proton %verb%\" }"
            )

        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "FNIS fixture", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "FNIS fixture" }
        )
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        workspace, profile, game

    let private configure (server: NexusServer) id bytes =
        server.Payload <- bytes

        server.FnisFiles <-
            [ id,
              "FNIS Behavior SE 7_6-" + string id + ".zip",
              FnisCatalogue.SupportedVersion,
              "FNIS Behavior SE main file" ]

    let private view (coordinator: FnisCoordinator) workspace profile =
        coordinator.Read(workspace, profile) |> wait

    let private waitForPhase coordinator workspace profile expected =
        until
            ("FNIS phase " + string expected)
            (fun () -> view coordinator workspace profile)
            (fun value -> value.Phase = expected)

    let private enabled (store: OperationStore) profile =
        InventoryObservations.read store profile
        |> _.Entries
        |> List.choose (fun row ->
            match row.Entry.Selection with
            | SelectionState.Managed(_, true) -> Some row.Entry.Mod.Id
            | _ -> None)
        |> Set.ofList

    let private active (store: OperationStore) workspace profile =
        let deployment = store.Deployments.Read profile |> wait |> result

        let generator =
            store.FnisSetups.ReadStored(workspace, profile, deployment.ActiveGeneration)
            |> wait

        deployment.ActiveGeneration, enabled store profile, generator

    let private layoutEvidence writer =
        let manifest (bytes: byte array) : ModConductor.ArchiveInspection.ArchiveManifest =
            use input = new MemoryStream(bytes)
            use zip = new ZipArchive(input, ZipArchiveMode.Read)

            { Sha256 = Convert.ToHexStringLower(SHA256.HashData bytes)
              Format = "zip"
              Entries =
                zip.Entries
                |> Seq.mapi (fun index entry ->
                    let value: ModConductor.ArchiveInspection.ArchiveEntry =
                        { Index = index
                          Path =
                            ModConductor.Platform.LogicalPath.create (
                                entry.FullName.TrimEnd('/').Split('/') |> Array.toList
                            )
                            |> Result.defaultWith (fun _ -> invalidOp "invalid archive path")
                          Directory = entry.FullName.EndsWith('/')
                          Size = entry.Length
                          CompressedSize = Some entry.CompressedLength }

                    value)
                |> Seq.toList
              TotalSize = zip.Entries |> Seq.sumBy _.Length }

        let valid = FnisArchiveLayout.review (archive "valid" true 0 |> manifest)
        let incomplete = FnisArchiveLayout.review (archive "invalid" false 0 |> manifest)

        let release =
            FnisCatalogue.release
                { Id = FnisCatalogue.NexusModId
                  Game = "skyrimspecialedition"
                  Name = "FNIS"
                  Summary = ""
                  Files =
                    [ { Id = 1L
                        Name = "FNIS Behavior SE 7_6.zip"
                        Version = "7.6"
                        Category = "Main files"
                        Description = ""
                        Bytes = None }
                      { Id = 2L
                        Name = "FNIS Behavior VR.zip"
                        Version = "7.6"
                        Category = "Main files"
                        Description = ""
                        Bytes = None } ] }

        check
            writer
            "reviewedLayoutRegistersExactGenerator"
            (valid
             |> Result.exists (fun plan ->
                 plan.Generator = FnisCatalogue.GeneratorPath
                 && plan.ComponentFiles
                    |> List.forall (fun file ->
                        file.Root = ModConductor.DeploymentPlanning.ComponentRoot.Data
                        && file.Use = ModConductor.DeploymentPlanning.ComponentFileUse.Immutable)))

        check writer "incompleteArchiveIsRefused" (Result.isError incomplete)

        check
            writer
            "catalogueSelectsReviewedSkyrimSeMainFile"
            (release |> Result.exists (fun value -> value.File.Id = 1L))

    let private lifecycleEvidence writer area =
        let scenario = Directory.CreateDirectory(Path.Combine(area, "lifecycle")).FullName
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
        let failurePoint = ref ""

        let store =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy,
                fnisCheckpoint =
                    (fun name _ ->
                        if name = lock failurePoint (fun () -> failurePoint.Value) then
                            raise (OperationCanceledException("fixture " + name)))
            )

        let workspace, profile, game = createWorkspace store scenario
        let foreign = Path.Combine(game, "foreign-user-file.txt")
        File.WriteAllText(foreign, "keep")
        configure server 701L (archive "initial" true 0)

        let coordinator =
            new FnisCoordinator(session, store.Downloads, store, server.Handoff)

        let started = coordinator.Install(workspace, profile) |> wait
        let ready = waitForPhase coordinator workspace profile FnisPhase.Ready

        let initialGeneration, initialEnabled, initialGenerator =
            active store workspace profile

        let generator = initialGenerator.Value
        let expectedExecutable = Path.Combine(game, FnisCatalogue.GeneratorPath)

        check
            writer
            "directAcquisitionPublishesImmutableGenerationAndProvenance"
            (started.Phase = FnisPhase.Downloading
             && ready.Version = FnisCatalogue.SupportedVersion
             && initialGeneration.IsSome
             && initialEnabled.Contains generator.ModId
             && generator.Executable = expectedExecutable
             && File.Exists expectedExecutable
             && generator.ArchiveSha256.Length = 64
             && generator.Provider = FnisCatalogue.Provider
             && generator.ArtifactId <> Guid.Empty
             && generator.FileName.Contains("FNIS Behavior SE 7_6")
             && generator.FileVersion = FnisCatalogue.SupportedVersion
             && generator.Source = FnisCatalogue.Source
             && generator.Terms = FnisCatalogue.Terms
             && generator.NexusFileId = 701L
             && generator.AcquiredAt > DateTimeOffset.MinValue
             && File.ReadAllText foreign = "keep")

        configure server 702L (archive "cancelled" true (2 * 1024 * 1024))
        server.Slow <- true
        let updateAvailable = coordinator.Read(workspace, profile) |> wait
        let updating = coordinator.Update(workspace, profile) |> wait
        let cancelled = coordinator.Cancel(workspace, profile) |> wait
        server.Slow <- false
        let afterCancel = active store workspace profile

        check
            writer
            "cancelledUpdatePreservesPriorGeneration"
            (updateAvailable.Phase = FnisPhase.UpdateAvailable
             && updating.Phase = FnisPhase.Downloading
             && cancelled.Phase = FnisPhase.UpdateAvailable
             && afterCancel = (initialGeneration, initialEnabled, initialGenerator))

        let retried = coordinator.Update(workspace, profile) |> wait
        let updated = waitForPhase coordinator workspace profile FnisPhase.Ready
        let updatedState = active store workspace profile
        let updatedGeneration, _, updatedGenerator = updatedState

        check
            writer
            "retryResumesAndPublishesSelectedUpdate"
            (retried.Phase = FnisPhase.Downloading
             && updated.Status = "FNIS is ready"
             && updatedState <> afterCancel
             && updatedState
                |> fun (_, _, value) -> value |> Option.exists (fun item -> item.NexusFileId = 702L))

        configure server 703L (archive "rollback" true 0)
        lock failurePoint (fun () -> failurePoint.Value <- "install-intent")
        coordinator.Update(workspace, profile) |> wait |> ignore

        let recovery =
            until
                "FNIS recovery requirement"
                (fun () -> view coordinator workspace profile)
                (fun value -> value.Phase = FnisPhase.RecoveryRequired)

        let beforeRecovery = active store workspace profile
        lock failurePoint (fun () -> failurePoint.Value <- "")

        let recovered =
            coordinator.Recover(workspace, profile, CancellationToken.None) |> wait

        let afterRecovery = active store workspace profile

        check
            writer
            "failedReplacementRecoveryPreservesActiveSetup"
            (recovery.Phase = FnisPhase.RecoveryRequired
             && beforeRecovery = updatedState
             && (recovered.Phase = FnisPhase.Ready || recovered.Phase = FnisPhase.UpdateAvailable)
             && afterRecovery = updatedState)

        let removed = coordinator.Remove(workspace, profile, CancellationToken.None) |> wait
        let removedState = active store workspace profile
        let removedGeneration, removedSelection, removedGenerator = removedState

        check
            writer
            "removalPublishesOwnedGenerationAndPreservesForeignFiles"
            (removed.Phase = FnisPhase.Available
             && removedGenerator.IsNone
             && not (removedSelection.Contains updatedGenerator.Value.ModId)
             && File.ReadAllText foreign = "keep")

        (coordinator :> IDisposable).Dispose()
        (store :> IDisposable).Dispose()

        server.Mode <- "offline"
        use reopened = new OperationStore(statePath)
        let persisted = reopened.Deployments.Read profile |> wait |> result

        check
            writer
            "restartKeepsRemovalAndRetainedProvenanceDurable"
            (persisted.ActiveGeneration = removedGeneration
             && reopened.FnisSetups.ReadStored(workspace, profile, Some updatedGeneration.Value)
                |> wait
                |> Option.exists (fun value ->
                    value.NexusFileId = 702L
                    && value.ArchiveSha256 = updatedGenerator.Value.ArchiveSha256))

    let private nxmEvidence writer area =
        let scenario = Directory.CreateDirectory(Path.Combine(area, "nxm")).FullName
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
                Path.Combine(scenario, "state"),
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let workspace, profile, _ = createWorkspace store scenario
        configure server 801L (archive "nxm" true 0)

        use coordinator =
            new FnisCoordinator(session, store.Downloads, store, server.Handoff)

        let waiting = coordinator.Install(workspace, profile) |> wait
        let id = Guid.NewGuid()
        let expiry = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()

        let link =
            "nxm://skyrimspecialedition/mods/3038/files/801?key=synthetic-nxm-private-grant&expires="
            + string expiry
            + "&user_id=42"

        if not (session.AcceptNxm(id, link)) then
            failwith "FNIS NXM fixture link was not admitted."

        coordinator.AcceptNxm id
        let ready = waitForPhase coordinator workspace profile FnisPhase.Ready

        check
            writer
            "accountBoundNxmCompletesWithoutManualArchiveSelection"
            (waiting.Phase = FnisPhase.WaitingForNexus
             && ready.Status = "FNIS is ready"
             && server.NxmRequests > 0)

        let second = Guid.NewGuid()
        configure server 802L (archive "wrong-account" true 0)
        coordinator.Update(workspace, profile) |> wait |> ignore

        let wrong =
            "nxm://skyrimspecialedition/mods/3038/files/802?key=synthetic-nxm-private-grant&expires="
            + string expiry
            + "&user_id=77"

        if not (session.AcceptNxm(second, wrong)) then
            failwith "FNIS wrong-account fixture link was not admitted."

        coordinator.AcceptNxm second
        let failed = waitForPhase coordinator workspace profile FnisPhase.Failed
        let preserved = active store workspace profile

        check
            writer
            "wrongAccountHandoffFailsDurablyWithoutChangingInstalledSetup"
            (failed.Detail.Contains("account", StringComparison.OrdinalIgnoreCase)
             && preserved
                |> fun (_, _, registered) ->
                    registered |> Option.exists (fun value -> value.NexusFileId = 801L))

    let private restartEvidence writer area =
        let scenario = Directory.CreateDirectory(Path.Combine(area, "restart")).FullName
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
        let mutable before = None

        do
            let store =
                new OperationStore(
                    statePath,
                    nexusLinks = NexusDownloadLinks(session),
                    downloadPolicy = policy
                )

            let workspaceId, profileId, _ = createWorkspace store scenario
            workspace <- workspaceId
            profile <- profileId
            configure server 901L (archive "restart-initial" true 0)

            let coordinator =
                new FnisCoordinator(session, store.Downloads, store, server.Handoff)

            coordinator.Install(workspace, profile) |> wait |> ignore
            waitForPhase coordinator workspace profile FnisPhase.Ready |> ignore
            before <- Some(active store workspace profile)

            configure server 902L (archive "restart-update" true (2 * 1024 * 1024))
            server.Slow <- true
            coordinator.Update(workspace, profile) |> wait |> ignore
            store.Downloads.Stop() |> wait
            (coordinator :> IDisposable).Dispose()
            (store :> IDisposable).Dispose()

        server.Slow <- false

        use restarted =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let context =
            (restarted.GameContexts :> IGameContexts).Read workspace |> wait |> result

        (restarted.GameContexts :> IGameContexts).Refresh(workspace, context.Revision)
        |> wait
        |> result
        |> ignore

        use coordinator =
            new FnisCoordinator(session, restarted.Downloads, restarted, server.Handoff)

        let resumed = coordinator.Read(workspace, profile) |> wait
        let ready = waitForPhase coordinator workspace profile FnisPhase.Ready
        let after = active restarted workspace profile

        check
            writer
            "interruptedDownloadResumesAfterColdRestart"
            (resumed.Phase = FnisPhase.Downloading
             && ready.Status = "FNIS is ready"
             && before.IsSome
             && after <> before.Value
             && after
                |> fun (_, _, registered) ->
                    registered |> Option.exists (fun value -> value.NexusFileId = 902L))

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "fnis")).FullName
        writer.WriteStartObject("fnis")
        layoutEvidence writer
        lifecycleEvidence writer area
        nxmEvidence writer area
        restartEvidence writer area
        GenerationCleanup.normalize area
        writer.WriteEndObject()
