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
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.ModSelection
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Platform
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

    let private freshnessEvidence writer =
        let path (value: string) =
            LogicalPath.create (value.Split('/') |> Array.toList)
            |> Result.defaultWith (fun _ -> failwith "Invalid FNIS input fixture path.")

        let animation =
            { Path = path "meshes/actors/character/animations/walk.hkx"
              Length = 4L
              Sha256 = String.replicate 64 "a" }

        let skeleton =
            { Path = path "meshes/actors/character/character assets/skeleton.nif"
              Length = 8L
              Sha256 = String.replicate 64 "b" }

        let original = FnisFreshness.compute TargetPolicy.windows [ animation; skeleton ]
        let reordered = FnisFreshness.compute TargetPolicy.windows [ skeleton; animation ]

        let changed =
            FnisFreshness.compute
                TargetPolicy.windows
                [ { animation with
                      Sha256 = String.replicate 64 "c" }
                  skeleton ]

        check writer "effectiveInputFingerprintIgnoresEnumerationOrder" (original = reordered)
        check writer "effectiveInputFingerprintChangesWithAnimationContent" (original <> changed)

        check
            writer
            "effectiveInputFilterRejectsUnrelatedFiles"
            (not (FnisFreshness.relevant (path "textures/a.dds")))

        check writer "effectiveInputFilterIncludesSkeletons" (FnisFreshness.relevant skeleton.Path)

        let windows =
            Descriptor.projectTool
                ContextPlatform.Windows
                "C:\\Skyrim\\Data\\tools\\GenerateFNISforUsers.exe"
                [ "RedirectFiles=C:\\owned"; "InstantExecute=1" ]
                { Executable = "C:\\Skyrim\\SkyrimSE.exe"
                  Arguments = []
                  WorkingDirectory = "C:\\Skyrim"
                  Environment = [ "SteamAppId", Some "489830" ] }

        check
            writer
            "windowsToolProjectionUsesExactDescriptorAndTypedArguments"
            (windows.Executable.EndsWith("GenerateFNISforUsers.exe")
             && windows.Arguments = [ "RedirectFiles=C:\\owned"; "InstantExecute=1" ]
             && windows.WorkingDirectory = "C:\\Skyrim")

    let private until label read predicate =
        let deadline = DateTime.UtcNow.AddSeconds 30.
        let mutable value = read ()

        while not (predicate value) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            value <- read ()

        if not (predicate value) then
            failwith ("Timed out waiting for " + label + ".")

        value

    let private unusedCombinedDependency<'value> () =
        Task.FromException<'value>(
            InvalidOperationException(
                "The combined FNIS cancellation fixture used an unrelated dependency."
            )
        )

    let private combinedFnisDependencies (execution: IFnisExecution) : SkyrimSetupDependencies =
        { ReadSkse = fun _ _ -> unusedCombinedDependency ()
          StartSkse = fun _ _ -> unusedCombinedDependency ()
          CancelSkse = fun _ _ -> unusedCombinedDependency ()
          RemoveSkse = fun _ _ _ -> unusedCombinedDependency ()
          ReadEnb = fun _ _ -> unusedCombinedDependency ()
          SelectEnb = fun _ _ _ _ _ -> unusedCombinedDependency ()
          CancelEnb = fun _ _ -> unusedCombinedDependency ()
          RemoveEnb = fun _ _ _ -> unusedCombinedDependency ()
          RecoverEnb = fun _ _ _ -> unusedCombinedDependency ()
          ReadFnis = fun _ _ -> unusedCombinedDependency ()
          InstallFnis = fun _ _ -> unusedCombinedDependency ()
          UpdateFnis = fun _ _ -> unusedCombinedDependency ()
          CancelFnis = fun _ _ -> unusedCombinedDependency ()
          RemoveFnis = fun _ _ _ -> unusedCombinedDependency ()
          RecoverFnis = fun _ _ _ -> unusedCombinedDependency ()
          InspectFnis = fun workspace profile token -> execution.Inspect(workspace, profile, token)
          RunFnis = fun request token -> execution.Run(request, token)
          CancelFnisRun = fun workspace profile -> execution.Cancel(workspace, profile)
          ReadLaunch = fun _ _ -> unusedCombinedDependency ()
          PluginPreflight = fun _ _ _ -> unusedCombinedDependency () }

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
                profile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
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
        let failureReached = ref false

        let store =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy,
                fnisCheckpoint =
                    (fun name _ ->
                        let fail =
                            lock failurePoint (fun () ->
                                let selected = name = failurePoint.Value

                                if selected then
                                    failureReached.Value <- true

                                selected)

                        if fail then
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
        let runnable = store.Deployments.Read profile |> wait |> result
        let expectedExecutable = Path.Combine(runnable.RunnableRoot, FnisCatalogue.GeneratorPath)
        let registeredExecutable = Path.Combine(game, FnisCatalogue.GeneratorPath)

        check
            writer
            "directAcquisitionPublishesImmutableGenerationAndProvenance"
            (started.Phase = FnisPhase.Downloading
             && ready.Version = FnisCatalogue.SupportedVersion
             && initialGeneration.IsSome
             && initialEnabled.Contains generator.ModId
             && generator.Executable = registeredExecutable
             && File.Exists expectedExecutable
             && not (File.Exists registeredExecutable)
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

        lock failurePoint (fun () ->
            failurePoint.Value <- "publication"
            failureReached.Value <- false)

        coordinator.Update(workspace, profile) |> wait |> ignore

        let recovery =
            until
                "FNIS recovery requirement"
                (fun () -> view coordinator workspace profile)
                (fun value -> value.Phase = FnisPhase.RecoveryRequired)

        let beforeRecovery = active store workspace profile

        let reachedPublication =
            lock failurePoint (fun () ->
                failurePoint.Value <- ""
                failureReached.Value)

        check writer "failedReplacementInterruptionReachedPublication" reachedPublication

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

    let private executionEvidence writer area =
        let scenario = Directory.CreateDirectory(Path.Combine(area, "execution")).FullName
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

        let store =
            new OperationStore(
                Path.Combine(scenario, "state"),
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let workspace, profile, game = createWorkspace store scenario
        configure server 751L (archive "execution" true 0)

        use coordinator =
            new FnisCoordinator(session, store.Downloads, store, server.Handoff)

        coordinator.Install(workspace, profile) |> wait |> ignore
        waitForPhase coordinator workspace profile FnisPhase.Ready |> ignore

        let mode = Path.Combine(scenario, "fnis-mode")
        File.WriteAllText(mode, "success")

        let launcher =
            Path.Combine(
                scenario,
                "installation",
                "Steam",
                "compatibilitytools.d",
                "Custom Ω Proton",
                "proton"
            )

        File.WriteAllText(
            launcher,
            "#!/usr/bin/python3\nimport os,sys,time,subprocess\nmode_path="
            + "r'"
            + mode.Replace("'", "\\'")
            + "'\nmode=open(mode_path).read().strip()\ntarget=next(a.split('=',1)[1] for a in sys.argv if a.startswith('RedirectFiles='))\ngenerator=next((a for a in sys.argv if a.lower().endswith('generatefnisforusers.exe')), '')\nlogs=os.path.join(os.path.dirname(generator),'temporary_logs')\nif mode=='shutdownchild':\n child=subprocess.Popen(['sleep','30'])\n open(mode_path+'.childpid','w').write(str(child.pid))\n time.sleep(30)\nif mode in ('cancel','timeout'): time.sleep(30)\nif mode=='fail':\n print('synthetic failure', file=sys.stderr)\n sys.exit(7)\nif mode=='outputlimit':\n print('x'*300000)\n sys.exit(0)\nif mode in ('successlog','successlognew'):\n parent=os.path.dirname(generator)\n os.chmod(parent,0o700)\n os.makedirs(logs,exist_ok=True)\n os.chmod(logs,0o700)\n existing=os.path.join(logs,'GenerateFNIS_LogFile.txt')\n if os.path.exists(existing): os.chmod(existing,0o600)\n open(existing,'wb').write(b'\\xffmalformed FNIS log')\n newlog=os.path.join(logs,'NewFNIS.log')\n open(newlog,'wb').write(b'new temporary log')\n os.chmod(existing,0o000)\n os.chmod(newlog,0o000)\n os.chmod(logs,0o000)\n os.chmod(parent,0o500)\nos.makedirs(os.path.join(target,'meshes','actors','character','behaviors'),exist_ok=True)\nopen(os.path.join(target,'meshes','actors','character','behaviors','generated.hkx'),'wb').write(('generated-'+mode).encode())\nprint(' '.join(sys.argv[1:]))\n"
        )

        File.SetUnixFileMode(
            launcher,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        let installedGenerator =
            let deployment = store.Deployments.Read profile |> wait |> result

            store.FnisSetups.ReadStored(workspace, profile, deployment.ActiveGeneration)
            |> wait
            |> Option.get

        let runnable = store.Deployments.Read profile |> wait |> result
        let projectedGenerator =
            Path.Combine(
                runnable.RunnableRoot,
                Path.GetRelativePath(game, installedGenerator.Executable)
            )

        let selectedContext =
            (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        let selectedWindowsContext =
            { selectedContext with
                Binding =
                    selectedContext.Binding
                    |> Option.map (fun binding ->
                        { binding with
                            Proton = None
                            Evidence =
                                { binding.Evidence with
                                    Platform = ContextPlatform.Windows
                                    Proton = None } }) }

        let selectedWindowsProjection =
            Descriptor.createToolWithHost
                true
                false
                selectedWindowsContext
                runnable.RunnableRoot
                None
                None
                installedGenerator.GenerationId
                installedGenerator.Executable
                [ "RedirectFiles=C:\\owned"; "InstantExecute=1" ]

        check
            writer
            "selectedWindowsContextProjectsRegisteredGenerator"
            (selectedWindowsProjection
             |> Result.exists (fun projected ->
                 projected.Runtime = "Windows"
                 && projected.Launch.Executable = projectedGenerator
                 && projected.Launch.Arguments = [ "RedirectFiles=C:\\owned"; "InstantExecute=1" ]))

        let generatorDirectory = Path.GetDirectoryName projectedGenerator
        let temporaryLogs = Path.Combine(generatorDirectory, "temporary_logs")

        let generatorBeforeLogs =
            SHA256.HashData(File.ReadAllBytes projectedGenerator)

        if OperatingSystem.IsLinux() then
            let mode = File.GetUnixFileMode generatorDirectory
            File.SetUnixFileMode(generatorDirectory, mode ||| UnixFileMode.UserWrite)
            Directory.CreateDirectory temporaryLogs |> ignore
            File.SetUnixFileMode(generatorDirectory, mode)
        else
            Directory.CreateDirectory temporaryLogs |> ignore

        let pathMetadata (path: string) =
            File.GetLastAccessTimeUtc path,
            File.GetLastWriteTimeUtc path,
            File.GetAttributes path,
            (if OperatingSystem.IsWindows() then
                 None
             else
                 Some(File.GetUnixFileMode path))

        let treeContents (root: string) =
            Directory.EnumerateFileSystemEntries(root, "*", SearchOption.AllDirectories)
            |> Seq.map (fun path ->
                let relative = Path.GetRelativePath(root, path)

                if Directory.Exists path then
                    relative + "/"
                else
                    relative + ":" + Convert.ToHexString(SHA256.HashData(File.ReadAllBytes path)))
            |> Seq.sortWith (fun left right -> StringComparer.Ordinal.Compare(left, right))
            |> Seq.toList

        use runner = new FnisRunner(store)
        let execution = runner :> IFnisExecution

        let waitForRun id expected =
            until
                ("FNIS run " + string id)
                (fun () ->
                    execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result)
                (fun value -> value.LatestRunId = Some id && value.Phase = expected)

        let outputEntry () =
            InventoryObservations.read store profile
            |> _.Entries
            |> List.map _.Entry.Mod
            |> List.tryFind (fun entry -> entry.Metadata.Name = "FNIS generated output")

        let select enabledValue modId =
            let page = InventoryObservations.read store profile

            (store.ModSelection :> IModSelection)
                .Change(
                    profile,
                    page.SelectionRevision,
                    [ modId ],
                    SelectionEdit.Enable enabledValue
                )
            |> wait
            |> result
            |> ignore

        let registerInput name =
            let id = Guid.NewGuid()
            let relative = name
            let directory = Path.Combine(scenario, "workspace", relative)

            let file =
                Path.Combine(directory, "meshes", "actors", "character", "animations", "added.hkx")

            Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
            File.WriteAllText(file, name)
            let library = store.ModLibrary :> ModConductor.ModLibrary.IModLibrary

            let registered =
                library.Register(
                    workspace,
                    id,
                    { Name = name
                      Notes = ""
                      Comment = ""
                      Version = "1"
                      Source = ""
                      Categories = [] },
                    ModConductor.ModLibrary.Registration.Directory(
                        ModConductor.ModLibrary.ModKind.Regular,
                        LogicalPath.create [ relative ] |> result
                    )
                )
                |> wait
                |> result

            library.Publish(id, registered.Revision, Guid.NewGuid())
            |> wait
            |> result
            |> ignore

            id

        let missing =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        let initialFingerprint = missing.Fingerprint
        let inputMod = registerInput "FNIS-input-race"
        select true inputMod

        let added =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        select false inputMod

        let removed =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        check writer "addedEffectiveInputMakesFnisStale" (added.Fingerprint <> initialFingerprint)

        check
            writer
            "removedEffectiveInputRestoresFingerprint"
            (removed.Fingerprint = initialFingerprint)

        let mutable changedFirstRun = false

        use firstStaleRunner =
            new FnisRunner(
                store,
                publicationCheckpoint =
                    (fun _ ->
                        if not changedFirstRun then
                            changedFirstRun <- true
                            select true inputMod)
            )

        let firstStaleExecution = firstStaleRunner :> IFnisExecution
        let firstStaleId = Guid.NewGuid()

        firstStaleExecution.Run(
            { Id = firstStaleId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let firstStale =
            until
                "first stale FNIS publication"
                (fun () ->
                    firstStaleExecution.Inspect(workspace, profile, CancellationToken.None)
                    |> wait
                    |> result)
                (fun value ->
                    value.LatestRunId = Some firstStaleId
                    && value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed)

        let firstShells =
            use connection =
                new Microsoft.Data.Sqlite.SqliteConnection(
                    "Data Source=" + Path.Combine(scenario, "state", "state.db") + ";Pooling=False"
                )

            connection.Open()

            Sqlite.number
                connection
                null
                "SELECT count(*) FROM mods WHERE name='FNIS generated output' OR id=(SELECT output_mod_id FROM fnis_runs WHERE id=$id)"
                [ "$id", box (string firstStaleId) ]

        check
            writer
            "firstStalePublicationRemovesOutputAndProfileShells"
            (firstStale.Detail.Contains("inputs changed")
             && (outputEntry () |> Option.isNone)
             && firstShells = 0L)

        select false inputMod

        let beforeCompleted = enabled store profile
        let completedId = Guid.NewGuid()

        let started =
            execution.Run(
                { Id = completedId
                  WorkspaceId = workspace
                  ProfileId = profile },
                CancellationToken.None
            )
            |> wait
            |> result

        let completed = waitForRun completedId ModConductor.Fnis.FnisOutputPhase.Current
        let afterCompleted = enabled store profile
        let firstOutput = outputEntry () |> Option.get
        let firstVersion = firstOutput.CurrentVersion

        let repeated =
            execution.Run(
                { Id = completedId
                  WorkspaceId = workspace
                  ProfileId = profile },
                CancellationToken.None
            )
            |> wait
            |> result

        check
            writer
            "runReturnsWhileCancellationIsReachable"
            (started.Phase = ModConductor.Fnis.FnisOutputPhase.Running)

        check
            writer
            "successfulRunPublishesAndSelectsOneCurrentOutput"
            (missing.Phase = ModConductor.Fnis.FnisOutputPhase.Missing
             && completed.StandardOutput.Contains("RedirectFiles=")
             && completed.StandardOutput.Contains("InstantExecute=1")
             && Set.count (Set.difference afterCompleted beforeCompleted) = 1
             && repeated.Phase = ModConductor.Fnis.FnisOutputPhase.Current
             && enabled store profile = afterCompleted)

        check
            writer
            "activeGeneratedOutputIsExcludedFromEffectiveInputs"
            (completed.Fingerprint = initialFingerprint)

        File.WriteAllText(mode, "success")
        let distinctId = Guid.NewGuid()

        execution.Run(
            { Id = distinctId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let distinct = waitForRun distinctId ModConductor.Fnis.FnisOutputPhase.Current
        let secondOutput = outputEntry () |> Option.get

        check
            writer
            "distinctRunIdsCreateVersionsOfOneStableOutput"
            (distinct.LatestRunId = Some distinctId
             && secondOutput.Id = firstOutput.Id
             && secondOutput.CurrentVersion <> firstVersion
             && (InventoryObservations.read store profile).Entries
                |> List.filter (fun row -> row.Entry.Mod.Metadata.Name = "FNIS generated output")
                |> List.length = 1)

        File.WriteAllText(mode, "fail")
        let failedId = Guid.NewGuid()

        execution.Run(
            { Id = failedId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let afterFailure = waitForRun failedId ModConductor.Fnis.FnisOutputPhase.Failed

        check
            writer
            "failedRunPreservesPriorOutputAndBoundedExitEvidence"
            (afterFailure.ExitCode = Some 7
             && afterFailure.Detail.Contains("exited with code 7")
             && afterFailure.StandardError.Contains("synthetic failure")
             && enabled store profile = afterCompleted
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", failedId.ToString("N"))
                 )
             ))

        File.WriteAllText(mode, "outputlimit")
        let outputLimitId = Guid.NewGuid()

        execution.Run(
            { Id = outputLimitId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let outputLimited =
            waitForRun outputLimitId ModConductor.Fnis.FnisOutputPhase.Failed

        check
            writer
            "outputLimitFailureRetainsDetailAndRemovesStage"
            (outputLimited.Detail.Contains("exceeded 256 KiB")
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", outputLimitId.ToString("N"))
                 )
             ))

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(launcher, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)

        let launchId = Guid.NewGuid()

        execution.Run(
            { Id = launchId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let launchFailed = waitForRun launchId ModConductor.Fnis.FnisOutputPhase.Failed

        File.SetUnixFileMode(
            launcher,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        check
            writer
            "launchFailureRetainsDetailAndRemovesStage"
            (launchFailed.Detail.Length > 0
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", launchId.ToString("N"))
                 )
             ))

        File.WriteAllText(mode, "cancel")
        let cancelledId = Guid.NewGuid()

        let context = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        store.SkyrimSetups.Save
            { WorkspaceId = workspace
              ProfileId = profile
              Selection = { SetupSelection.none with Fnis = SetupAction.Install }
              PlanToken = "production-fnis-cancellation"
              Cancelled = false
              Completed = false
              Stage = "fnis-run"
              ContextRevision = context.Revision
              ActionId = Some cancelledId
              CancelRequested = false
              CancelDetail = ""
              RequestedAt = DateTimeOffset.UtcNow }
        |> wait

        let combined = new SkyrimSetupCoordinator(store, combinedFnisDependencies execution)

        execution.Run(
            { Id = cancelledId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let combinedCancelled =
            combined.Cancel(workspace, profile, CancellationToken.None) |> wait

        let cancelled =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        let cancelledIntent = store.SkyrimSetups.Read(workspace, profile) |> wait

        (combined :> IDisposable).Dispose()

        check
            writer
            "cancelledRunTerminatesAndPreservesPriorOutput"
            (cancelled.LatestRunId = Some cancelledId
             && cancelled.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
             && enabled store profile = afterCompleted
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", cancelledId.ToString("N"))
                 )
             ))

        check
            writer
            "combinedCancelUsesProductionFnisOwner"
            (combinedCancelled.Phase = SkyrimSetupPhase.Cancelled
             && combinedCancelled.Detail.Contains("FNIS was cancelled", StringComparison.Ordinal)
             && (cancelledIntent
                 |> Option.exists (fun value ->
                     value.Cancelled && not value.CancelRequested && value.ActionId.IsNone)))

        File.WriteAllText(mode, "timeout")
        use timeoutRunner = new FnisRunner(store, timeout = TimeSpan.FromMilliseconds 100.)
        let timeoutExecution = timeoutRunner :> IFnisExecution
        let timeoutId = Guid.NewGuid()

        timeoutExecution.Run(
            { Id = timeoutId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let timedOut =
            until
                "timed-out FNIS run"
                (fun () ->
                    timeoutExecution.Inspect(workspace, profile, CancellationToken.None)
                    |> wait
                    |> result)
                (fun value ->
                    value.LatestRunId = Some timeoutId
                    && value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed)

        check
            writer
            "timedOutRunRetainsDetailAndRemovesStage"
            (timedOut.Detail.Contains("timed out")
             && timedOut.RunLog = ""
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", timeoutId.ToString("N"))
                 )
             ))

        let existingLog = Path.Combine(temporaryLogs, "GenerateFNIS_LogFile.txt")
        let newLog = Path.Combine(temporaryLogs, "NewFNIS.log")
        File.WriteAllText(existingLog, "original temporary log")
        let expectedGeneratorTree = treeContents generatorDirectory

        let originalParentMode = File.GetUnixFileMode generatorDirectory
        let parentAccess = DateTime(2026, 1, 2, 3, 4, 5, DateTimeKind.Utc)
        let parentWrite = DateTime(2026, 1, 2, 3, 4, 6, DateTimeKind.Utc)
        let directoryAccess = DateTime(2026, 1, 2, 3, 4, 7, DateTimeKind.Utc)
        let directoryWrite = DateTime(2026, 1, 2, 3, 4, 8, DateTimeKind.Utc)
        let fileAccess = DateTime(2026, 1, 2, 3, 4, 9, DateTimeKind.Utc)
        let fileWrite = DateTime(2026, 1, 2, 3, 4, 10, DateTimeKind.Utc)
        File.SetLastAccessTimeUtc(generatorDirectory, parentAccess)
        File.SetLastWriteTimeUtc(generatorDirectory, parentWrite)
        File.SetLastAccessTimeUtc(temporaryLogs, directoryAccess)
        File.SetLastWriteTimeUtc(temporaryLogs, directoryWrite)
        File.SetLastAccessTimeUtc(existingLog, fileAccess)
        File.SetLastWriteTimeUtc(existingLog, fileWrite)
        File.SetUnixFileMode(existingLog, UnixFileMode.UserRead)
        File.SetUnixFileMode(temporaryLogs, UnixFileMode.UserRead ||| UnixFileMode.UserExecute)
        let expectedParentMetadata = pathMetadata generatorDirectory
        let expectedDirectoryMetadata = pathMetadata temporaryLogs
        let expectedFileMetadata = pathMetadata existingLog
        File.WriteAllText(mode, "successlog")
        let logId = Guid.NewGuid()

        execution.Run(
            { Id = logId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let logged = waitForRun logId ModConductor.Fnis.FnisOutputPhase.Current
        let restoredParentMetadata = pathMetadata generatorDirectory
        let restoredDirectoryMetadata = pathMetadata temporaryLogs
        let restoredFileMetadata = pathMetadata existingLog
        let restoredGeneratorTree = treeContents generatorDirectory

        check
            writer
            "malformedTemporaryLogIsCapturedBoundedInOwnedState"
            (logged.RunLog.Contains("malformed FNIS log")
             && Encoding.UTF8.GetByteCount logged.RunLog <= 256 * 1024
             && File.ReadAllText(existingLog) = "original temporary log"
             && not (File.Exists newLog))

        check
            writer
            "restrictiveTemporaryLogTreeRestoresContentMetadataModesAndTimestamps"
            (restoredGeneratorTree = expectedGeneratorTree
             && restoredParentMetadata = expectedParentMetadata
             && restoredDirectoryMetadata = expectedDirectoryMetadata
             && restoredFileMetadata = expectedFileMetadata)

        check
            writer
            "temporaryLogCleanupPreservesImmutableGenerator"
            (SHA256.HashData(File.ReadAllBytes projectedGenerator) = generatorBeforeLogs)

        File.WriteAllText(mode, "success")
        let missingLogId = Guid.NewGuid()

        execution.Run(
            { Id = missingLogId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let missingLog = waitForRun missingLogId ModConductor.Fnis.FnisOutputPhase.Current
        check writer "missingTemporaryLogIsAnEmptyOwnedRecord" (missingLog.RunLog = "")

        File.SetUnixFileMode(generatorDirectory, originalParentMode ||| UnixFileMode.UserWrite)

        File.SetUnixFileMode(
            temporaryLogs,
            UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
        )

        File.SetUnixFileMode(existingLog, UnixFileMode.UserRead ||| UnixFileMode.UserWrite)
        Directory.Delete(temporaryLogs, true)
        File.SetUnixFileMode(generatorDirectory, originalParentMode)
        let expectedTreeWithoutTemporaryLogs = treeContents generatorDirectory
        let newParentAccess = DateTime(2026, 2, 3, 4, 5, 6, DateTimeKind.Utc)
        let newParentWrite = DateTime(2026, 2, 3, 4, 5, 7, DateTimeKind.Utc)
        File.SetLastAccessTimeUtc(generatorDirectory, newParentAccess)
        File.SetLastWriteTimeUtc(generatorDirectory, newParentWrite)
        let expectedNewParentMetadata = pathMetadata generatorDirectory
        File.WriteAllText(mode, "successlognew")
        let newLogDirectoryId = Guid.NewGuid()

        execution.Run(
            { Id = newLogDirectoryId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let newDirectoryLog =
            waitForRun newLogDirectoryId ModConductor.Fnis.FnisOutputPhase.Current

        let restoredNewParentMetadata = pathMetadata generatorDirectory
        let restoredTreeWithoutTemporaryLogs = treeContents generatorDirectory

        check
            writer
            "newRestrictiveTemporaryLogDirectoryIsCapturedAndRemoved"
            (newDirectoryLog.RunLog.Contains("malformed FNIS log")
             && not (Directory.Exists temporaryLogs)
             && restoredTreeWithoutTemporaryLogs = expectedTreeWithoutTemporaryLogs
             && restoredNewParentMetadata = expectedNewParentMetadata
             && SHA256.HashData(File.ReadAllBytes projectedGenerator) = generatorBeforeLogs)

        let beforeStale = outputEntry () |> Option.get
        let mutable changedForRace = false

        use staleRunner =
            new FnisRunner(
                store,
                publicationCheckpoint =
                    (fun _ ->
                        if not changedForRace then
                            changedForRace <- true
                            select true inputMod)
            )

        let staleExecution = staleRunner :> IFnisExecution

        let staleId = Guid.NewGuid()

        staleExecution.Run(
            { Id = staleId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let stale =
            until
                "stale FNIS publication"
                (fun () ->
                    staleExecution.Inspect(workspace, profile, CancellationToken.None)
                    |> wait
                    |> result)
                (fun value ->
                    value.LatestRunId = Some staleId
                    && value.Phase = ModConductor.Fnis.FnisOutputPhase.Failed)

        let afterStale = outputEntry () |> Option.get

        let staleResidue =
            use connection =
                new Microsoft.Data.Sqlite.SqliteConnection(
                    "Data Source=" + Path.Combine(scenario, "state", "state.db") + ";Pooling=False"
                )

            connection.Open()

            Sqlite.number
                connection
                null
                "SELECT count(*) FROM mod_versions WHERE id=(SELECT output_version_id FROM fnis_runs WHERE id=$id)"
                [ "$id", box (string staleId) ]

        check
            writer
            "stalePublicationRollsBackVersionAndSelectionAtomically"
            (stale.Detail.Contains("inputs changed")
             && afterStale.Id = beforeStale.Id
             && afterStale.CurrentVersion = beforeStale.CurrentVersion
             && staleResidue = 0L)

        select false inputMod

        let childPidFile = mode + ".childpid"
        File.WriteAllText(mode, "shutdownchild")
        let shutdownId = Guid.NewGuid()

        execution.Run(
            { Id = shutdownId
              WorkspaceId = workspace
              ProfileId = profile },
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        until "sleeping FNIS child" (fun () -> File.Exists childPidFile) id |> ignore

        let childPid = File.ReadAllText(childPidFile).Trim() |> Int32.Parse
        runner.Stop() |> wait

        let stopped =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        check
            writer
            "engineShutdownCancelsAndDrainsSleepingFnisProcessGroup"
            (stopped.LatestRunId = Some shutdownId
             && stopped.Phase = ModConductor.Fnis.FnisOutputPhase.Cancelled
             && not (Directory.Exists("/proc/" + string childPid))
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", shutdownId.ToString("N"))
                 )
             ))

        let beforeRestart = outputEntry () |> Option.get

        let inspected =
            execution.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        let generator =
            store.FnisSetups.ReadStored(workspace, profile, Some inspected.GenerationId)
            |> wait
            |> Option.get

        let abandonedId = Guid.NewGuid()

        let abandonedStage, _, _ =
            store.FnisExecution.Begin(
                { Id = abandonedId
                  WorkspaceId = workspace
                  ProfileId = profile },
                generator,
                inspected.Fingerprint
            )
            |> wait
            |> result

        Directory.CreateDirectory(abandonedStage.Directory) |> ignore
        File.WriteAllText(Path.Combine(abandonedStage.Directory, "partial.log"), "partial")

        store.SkyrimSetups.Save
            { WorkspaceId = workspace
              ProfileId = profile
              Selection = { SetupSelection.none with Fnis = SetupAction.Install }
              PlanToken = "production-fnis-pending-restart"
              Cancelled = false
              Completed = false
              Stage = "fnis-run"
              ContextRevision = context.Revision
              ActionId = Some abandonedId
              CancelRequested = true
              CancelDetail = "Cancellation was recorded before the engine stopped."
              RequestedAt = DateTimeOffset.UtcNow }
        |> wait

        (store :> IDisposable).Dispose()

        use reopened =
            new OperationStore(
                Path.Combine(scenario, "state"),
                nexusLinks = NexusDownloadLinks(session),
                downloadPolicy = policy
            )

        let reopenedContext =
            (reopened.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, profile, reopenedContext.Revision)
        |> wait
        |> result
        |> ignore

        use restartedRunner = new FnisRunner(reopened)
        let restarted = restartedRunner :> IFnisExecution

        use restartedCombined =
            new SkyrimSetupCoordinator(reopened, combinedFnisDependencies restarted)

        let combinedAfterRestart =
            restartedCombined.Read(workspace, profile, { SetupSelection.none with Fnis = SetupAction.Install }, CancellationToken.None) |> wait

        let combinedCancellationCompleted =
            restartedCombined.Continue(workspace, profile, CancellationToken.None) |> wait

        let abandoned =
            restarted.Inspect(workspace, profile, CancellationToken.None) |> wait |> result

        let afterRestart =
            InventoryObservations.read reopened profile
            |> _.Entries
            |> List.map _.Entry.Mod
            |> List.find (fun entry -> entry.Metadata.Name = "FNIS generated output")

        check
            writer
            "restartMarksRunAbandonedRemovesStageAndPreservesOutput"
            (abandoned.LatestRunId = Some abandonedId
             && abandoned.Phase = ModConductor.Fnis.FnisOutputPhase.Abandoned
             && afterRestart.Id = beforeRestart.Id
             && afterRestart.CurrentVersion = beforeRestart.CurrentVersion
             && not (
                 Directory.Exists(
                     Path.Combine(scenario, "state", "fnis-runs", abandonedId.ToString("N"))
                 )
             ))

        check
            writer
            "pendingCombinedFnisCancellationCompletesThroughProductionOwnerAfterRestart"
            (combinedAfterRestart.Phase = SkyrimSetupPhase.RecoveryRequired
             && combinedAfterRestart.Selection.Fnis = SetupAction.Install
             && combinedCancellationCompleted.Phase = SkyrimSetupPhase.Cancelled
             && combinedCancellationCompleted.Detail.Contains(
                 "interrupted",
                 StringComparison.OrdinalIgnoreCase
             ))

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
            (restarted.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (restarted.GameContexts :> IGameContexts).Refresh(workspace, profile, context.Revision)
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
        freshnessEvidence writer
        layoutEvidence writer
        lifecycleEvidence writer area
        executionEvidence writer area
        nxmEvidence writer area
        restartEvidence writer area
        GenerationCleanup.normalize area
        writer.WriteEndObject()
