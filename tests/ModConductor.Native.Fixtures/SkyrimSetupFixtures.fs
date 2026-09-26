namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.ArtifactLibrary
open ModConductor.Engine
open ModConductor.Enb
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1
open ModConductor.Skse
open ModConductor.Workspaces

module SkyrimSetupFixtures =
    let private wait (pending: Task<'T>) = pending.GetAwaiter().GetResult()

    let private until name read accept =
        let deadline = DateTime.UtcNow.AddSeconds 10.
        let mutable current = read ()

        while not (accept current) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            current <- read ()

        if not (accept current) then
            failwith ("Skyrim setup fixture timed out: " + name)

        current

    let private result =
        function
        | Ok value -> value
        | Error error -> failwith (string error)

    let private check (writer: Utf8JsonWriter) (name: string) (value: bool) =
        writer.WriteBoolean(name, value)
        writer.Flush()

        if not value then
            failwith ("Skyrim setup fixture failed: " + name)

    let private createWorkspace (store: OperationStore) area name includeProton =
        let workspace, profile, _, _, saved =
            SkyrimFixtureWorkspace.create
                store
                area
                name
                (name + "-workspace")
                (name + "-installation")
                includeProton

        match saved with
        | Ok context -> workspace, profile, context.Revision
        | Error error -> failwith ("Game context setup failed: " + string error)

    type private WorkflowState() =
        let generation = Guid.NewGuid()

        let mutable skse =
            { Phase = SksePhase.Available
              GameVersion = "1.6.1170.0"
              ComponentVersion = "2.2.6"
              Status = "SKSE is available"
              Detail = "The matching version is ready to install."
              FileId = None }

        let mutable enb =
            { Phase = EnbPhase.Available
              Status = "Lean ENB is available"
              Detail = "Choose the author archive."
              RuntimeVersion = "0.505"
              PresetVersion = "1" }

        let mutable fnis =
            { Phase = FnisPhase.Available
              Version = "7.6"
              Status = "FNIS is available"
              Detail = "FNIS is ready to install."
              FileId = None
              ArtifactId = None }

        let mutable output = ModConductor.Fnis.FnisOutputPhase.Stale
        let mutable latestRun = None
        let mutable fnisExitCode = None
        let mutable skseReads = 0
        let mutable skseStarts = 0
        let mutable failSkse = false
        let mutable holdSkse = false
        let mutable enbSelections = 0
        let mutable failEnb = false
        let mutable fnisInstalls = 0
        let mutable waitForFnisNexus = false
        let mutable enbCancels = 0
        let mutable runCalls = 0
        let mutable blockEnb = false
        let enbStarted = new ManualResetEventSlim(false)
        let mutable blockFnis = false
        let fnisRelease = new ManualResetEventSlim(false)
        let mutable retainActiveFnisCancellation = false

        let inspection () =
            let exitWarning =
                match output, fnisExitCode with
                | ModConductor.Fnis.FnisOutputPhase.Current, Some code when code <> 0 -> Some code
                | _ -> None

            { WorkspaceId = Guid.Empty
              ProfileId = Guid.Empty
              GenerationId = generation
              Generator = "GenerateFNISforUsers.exe"
              Fingerprint = "fixture-fingerprint"
              Phase = output
              Status =
                match exitWarning with
                | Some code -> "FNIS output is available, but FNIS exited with code " + string code
                | None when output = ModConductor.Fnis.FnisOutputPhase.Current -> "FNIS output is current"
                | None -> "FNIS output is stale"
              Detail =
                if exitWarning.IsSome then
                    "Check the FNIS messages before you use these files."
                else
                    "The combined coordinator owns the next action."
              LatestRunId = latestRun
              ExitCode = if output = ModConductor.Fnis.FnisOutputPhase.Current then fnisExitCode else None
              StandardOutput = ""
              StandardError = ""
              RunLog = "" }

        member _.Reset() =
            skse <-
                { skse with
                    Phase = SksePhase.Available }

            enb <- { enb with Phase = EnbPhase.Available }

            fnis <-
                { fnis with
                    Phase = FnisPhase.Available }

            output <- ModConductor.Fnis.FnisOutputPhase.Stale
            latestRun <- None
            fnisExitCode <- None
            failSkse <- false
            holdSkse <- false
            blockEnb <- false
            failEnb <- false
            enbStarted.Reset()
            blockFnis <- false
            fnisRelease.Reset()
            retainActiveFnisCancellation <- false

        member _.ReadyWithStaleFnis() =
            skse <- { skse with Phase = SksePhase.Ready }
            enb <- { enb with Phase = EnbPhase.Ready }
            fnis <- { fnis with Phase = FnisPhase.Ready }
            output <- ModConductor.Fnis.FnisOutputPhase.Stale

        member _.FailedFnisOutput() =
            skse <- { skse with Phase = SksePhase.Ready }
            enb <- { enb with Phase = EnbPhase.Ready }
            fnis <- { fnis with Phase = FnisPhase.Ready }
            output <- ModConductor.Fnis.FnisOutputPhase.Failed

        member _.ReadyWithCurrentFnis(run) =
            skse <- { skse with Phase = SksePhase.Ready }
            enb <- { enb with Phase = EnbPhase.Ready }
            fnis <- { fnis with Phase = FnisPhase.Ready }
            output <- ModConductor.Fnis.FnisOutputPhase.Current
            latestRun <- run

        member _.RunningFnis(run) =
            skse <- { skse with Phase = SksePhase.Ready }
            enb <- { enb with Phase = EnbPhase.Ready }
            fnis <- { fnis with Phase = FnisPhase.Ready }
            output <- ModConductor.Fnis.FnisOutputPhase.Running
            latestRun <- Some run

        member _.SkseReads = skseReads
        member _.SkseStarts = skseStarts
        member _.FailSkse() = failSkse <- true
        member _.AllowSkse() = failSkse <- false
        member _.HoldSkse() = holdSkse <- true
        member _.CompleteSkse() = skse <- { skse with Phase = SksePhase.Ready; Status = "SKSE is current"; Detail = "" }
        member _.SkseUpdate(version) =
            skse <- { skse with Phase = SksePhase.UpdateAvailable; ComponentVersion = version }

        member _.EnbSelections = enbSelections
        member _.FailEnb() = failEnb <- true
        member _.AllowEnb() = failEnb <- false
        member _.FnisInstalls = fnisInstalls
        member _.FnisExitCode(code) = fnisExitCode <- code
        member _.WaitForFnisNexus() = waitForFnisNexus <- true
        member _.CompleteFnisNexusSelection() =
            fnis <- { fnis with Phase = FnisPhase.Ready; Status = "FNIS is ready" }
        member _.EnbCancels = enbCancels
        member _.RunCalls = runCalls

        member _.BlockEnb() =
            blockEnb <- true
            enbStarted.Reset()

        member _.WaitForEnb() =
            enbStarted.Wait(TimeSpan.FromSeconds 5.)

        member _.BlockFnis() =
            blockFnis <- true
            fnisRelease.Reset()

        member _.ReleaseFnis() = fnisRelease.Set()

        member _.RetainActiveFnisCancellation() = retainActiveFnisCancellation <- true

        member _.CompleteFnisCancellation() =
            retainActiveFnisCancellation <- false
            output <- ModConductor.Fnis.FnisOutputPhase.Cancelled

        member _.Dependencies =
            { ReadSkse =
                fun _ _ ->
                    skseReads <- skseReads + 1
                    Task.FromResult skse
              StartSkse =
                fun _ _ ->
                    skseStarts <- skseStarts + 1
                    skse <-
                        { skse with
                            Phase =
                                if failSkse then SksePhase.Failed
                                elif holdSkse then SksePhase.Installing
                                else SksePhase.Ready
                            Status =
                                if failSkse then "SKSE install failed"
                                elif holdSkse then "Installing SKSE"
                                else "SKSE is ready"
                            Detail = if failSkse then "The archive could not be installed." else "" }

                    Task.FromResult skse
              CancelSkse = fun _ _ -> Task.FromResult skse
              RemoveSkse = fun _ _ _ -> Task.FromResult skse
              ReadEnb = fun _ _ -> Task.FromResult enb
              SelectEnb =
                fun _ _ _ _ token ->
                    task {
                        enbSelections <- enbSelections + 1
                        if blockEnb then
                            enb <-
                                { enb with
                                    Phase = EnbPhase.Installing
                                    Status = "Installing Lean ENB" }

                            enbStarted.Set()
                            do! Task.Delay(Timeout.Infinite, token)

                        enb <-
                            { enb with
                                Phase = if failEnb then EnbPhase.Failed else EnbPhase.Ready
                                Status = if failEnb then "ENB setup failed" else "Lean ENB is ready"
                                Detail = if failEnb then "The profile settings could not be initialized." else "" }

                        return enb
                    }
              RemoveEnb = fun _ _ _ -> Task.FromResult enb
              CancelEnb =
                fun _ _ ->
                    enbCancels <- enbCancels + 1

                    enb <-
                        { enb with
                            Phase = EnbPhase.Available
                            Status = "ENB setup cancelled" }

                    Task.FromResult enb
              RecoverEnb = fun _ _ _ -> Task.FromResult enb
              ReadFnis = fun _ _ -> Task.FromResult fnis
              InstallFnis =
                fun _ _ ->
                    fnisInstalls <- fnisInstalls + 1
                    fnis <-
                        { fnis with
                            Phase = if waitForFnisNexus then FnisPhase.WaitingForNexus else FnisPhase.Ready
                            Status = if waitForFnisNexus then "Waiting for Nexus Mods" else "FNIS is ready" }

                    Task.FromResult fnis
              UpdateFnis = fun _ _ -> Task.FromResult fnis
              CancelFnis = fun _ _ -> Task.FromResult fnis
              RemoveFnis = fun _ _ _ -> Task.FromResult fnis
              RecoverFnis = fun _ _ _ -> Task.FromResult fnis
              InspectFnis = fun _ _ _ -> Task.FromResult(Ok(inspection ()))
              RunFnis =
                fun request token ->
                    task {
                        runCalls <- runCalls + 1
                        latestRun <- Some request.Id
                        output <- ModConductor.Fnis.FnisOutputPhase.Running

                        if blockFnis then
                            fnisRelease.Wait token

                        output <- ModConductor.Fnis.FnisOutputPhase.Current
                        return Ok(inspection ())
                    }
              CancelFnisRun =
                fun _ _ ->
                    if not retainActiveFnisCancellation then
                        output <- ModConductor.Fnis.FnisOutputPhase.Cancelled

                    Task.FromResult(Ok(inspection ()))
              ReadLaunch =
                fun workspace profile ->
                    Task.FromResult(
                        Ok
                            { WorkspaceId = workspace
                              ProfileId = profile
                              ContextRevision = 1L
                              SourceToken = "fixture-source"
                              Name = "SKSE"
                              Runtime = "Proton fixture"
                              Problem = None
                              Latest = None }
                    )
              PluginPreflight = fun _ _ _ -> Task.FromResult(Ok()) }

    let private fnisNexusWarningEvidence writer area state (store: OperationStore) noChoice fnisOnly =
        let waitingWorkspace, waitingProfile, _ = createWorkspace store area "waiting-fnis" true
        let waitingWorkflow = WorkflowState()
        waitingWorkflow.WaitForFnisNexus()
        waitingWorkflow.FnisExitCode(Some 7)
        let waitingChanges = Event<Guid * Guid>()
        use waitingOwner =
            new SkyrimSetupCoordinator(
                store,
                waitingWorkflow.Dependencies,
                childChanges = [ waitingChanges.Publish ]
            )
        let _ = waitingOwner.Start(waitingWorkspace, waitingProfile, fnisOnly, CancellationToken.None) |> wait

        let waiting =
            until
                "FNIS waits for Nexus selection"
                (fun () ->
                    let current = waitingOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None) |> wait

                    if current.CanContinue then
                        waitingOwner.Continue(waitingWorkspace, waitingProfile, CancellationToken.None) |> wait
                    else
                        current)
                (fun _ -> waitingWorkflow.FnisInstalls = 1)

        let repeatedWait =
            waitingOwner.Continue(waitingWorkspace, waitingProfile, CancellationToken.None) |> wait

        check
            writer
            "waitingFnisDoesNotReopenNexus"
            (waiting.Active
             && not waiting.CanContinue
             && repeatedWait.Active
             && not repeatedWait.CanContinue
             && waitingWorkflow.FnisInstalls = 1)

        let waitingGeneration =
            (store.Deployments.Read waitingProfile |> wait |> result).ActiveGeneration
            |> Option.defaultWith (fun () -> failwith "FNIS setup did not deploy the profile.")

        use fnisDatabase =
            new Microsoft.Data.Sqlite.SqliteConnection(
                "Data Source=" + Path.Combine(state, "state.db") + ";Pooling=False"
            )

        fnisDatabase.Open()

        Sqlite.execute
            fnisDatabase
            null
            "INSERT INTO fnis_generators(profile_id,workspace_id,generation_id,mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at) VALUES($profile,$workspace,$generation,$mod,$version,$artifact,$name,$fileVersion,$executable,$component,$sha,$provider,$source,$terms,$nexusMod,$nexusFile,$acquired)"
            [ "$profile", box (string waitingProfile)
              "$workspace", box (string waitingWorkspace)
              "$generation", box (string waitingGeneration)
              "$mod", box (string (Guid.NewGuid()))
              "$version", box (string (Guid.NewGuid()))
              "$artifact", box (string (Guid.NewGuid()))
              "$name", box "fixture FNIS"
              "$fileVersion", box "7.6"
              "$executable", box "fixture generator"
              "$component", box "7.6"
              "$sha", box (String.replicate 64 "a")
              "$provider", box "fixture"
              "$source", box "fixture"
              "$terms", box "fixture"
              "$nexusMod", box 1L
              "$nexusFile", box 1L
              "$acquired", box (DateTimeOffset.UtcNow.ToString("O")) ]

        waitingWorkflow.CompleteFnisNexusSelection()
        waitingChanges.Trigger(waitingWorkspace, waitingProfile)

        let afterNexusIntent =
            until
                "FNIS continues after Nexus selection"
                (fun () -> store.SkyrimSetups.Read(waitingWorkspace, waitingProfile) |> wait)
                (fun current -> (current |> Option.exists _.Completed) && waitingWorkflow.RunCalls = 1)
        let afterNexus =
            waitingOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None)
            |> wait

        check
            writer
            "fnisContinuesAfterNexusSelection"
            ((afterNexusIntent |> Option.exists _.Completed)
             && waitingWorkflow.FnisInstalls = 1
             && waitingWorkflow.RunCalls = 1)

        check
            writer
            "fnisExitWarningVisibleAfterCompletion"
            (afterNexus.Phase = SkyrimSetupPhase.Available
             && not afterNexus.Active
             && afterNexus.Status.Contains("FNIS exited with code 7")
             && afterNexus.Detail.Contains("Check the FNIS messages")
             && (afterNexus.Components
                 |> List.exists (fun item -> item.Id = "fnis" && item.Ready)))

        let completedIntent =
            until
                "FNIS warning setup completes without Continue"
                (fun () -> store.SkyrimSetups.Read(waitingWorkspace, waitingProfile) |> wait)
                (Option.exists _.Completed)
        let refreshedWarning =
            waitingOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None)
            |> wait

        use reopenedWarningOwner = new SkyrimSetupCoordinator(store, waitingWorkflow.Dependencies)
        let reopenedWarning =
            reopenedWarningOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None)
            |> wait

        check
            writer
            "fnisExitWarningRemainsAfterAutomaticContinueAndRefresh"
            ((completedIntent |> Option.exists _.Completed)
             && refreshedWarning.Phase = SkyrimSetupPhase.Available
             && refreshedWarning.Status.Contains("FNIS exited with code 7")
             && reopenedWarning.Status = refreshedWarning.Status
             && reopenedWarning.Detail = refreshedWarning.Detail)

        use restartedWarningStore = new OperationStore(state)
        let restartedWarningContext =
            (restartedWarningStore.GameContexts :> IGameContexts)
                .Read(waitingWorkspace, waitingProfile)
            |> wait
            |> result

        (restartedWarningStore.GameContexts :> IGameContexts)
            .Refresh(waitingWorkspace, waitingProfile, restartedWarningContext.Revision)
        |> wait
        |> result
        |> ignore

        use restartedWarningOwner =
            new SkyrimSetupCoordinator(restartedWarningStore, waitingWorkflow.Dependencies)

        let restartedWarning =
            restartedWarningOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None)
            |> wait

        check
            writer
            "fnisExitWarningRemainsAfterStoreRestart"
            (restartedWarning.Phase = SkyrimSetupPhase.Available
             && restartedWarning.Status = refreshedWarning.Status
             && restartedWarning.Detail = refreshedWarning.Detail)

        waitingWorkflow.ReadyWithCurrentFnis(Some(Guid.NewGuid()))
        waitingWorkflow.FnisExitCode(Some 0)

        let afterSuccessfulRun =
            restartedWarningOwner.Read(waitingWorkspace, waitingProfile, noChoice, CancellationToken.None)
            |> wait

        check
            writer
            "laterSuccessfulFnisRunClearsSetupWarning"
            (afterSuccessfulRun.Phase = SkyrimSetupPhase.Available
             && afterSuccessfulRun.Status = ""
             && afterSuccessfulRun.Detail = "")


    let private heldEnbGenerationEvidence writer area noChoice enbWithArchive =
        let enbArea = Directory.CreateDirectory(Path.Combine(area, "paused-enb")).FullName
        use releaseEnbGeneration = new ManualResetEventSlim(true)
        use enteredEnbGeneration = new ManualResetEventSlim(false)

        use enbStore =
            new OperationStore(
                Path.Combine(enbArea, "state"),
                enbCheckpoint =
                    (fun name _ ->
                        if name = "install-intent" && not releaseEnbGeneration.IsSet then
                            enteredEnbGeneration.Set()
                            releaseEnbGeneration.Wait(TimeSpan.FromSeconds 30.) |> ignore)
            )

        let enbWorkspace, enbProfile, _ = createWorkspace enbStore enbArea "selected" true
        let enbArchive = Path.Combine(enbArea, "enbseries_skyrimse_v0505.zip")

        use archiveOutput = File.Create enbArchive
        use enbZip = new ZipArchive(archiveOutput, ZipArchiveMode.Create, true)

        for name in [ "WrapperVersion/d3d11.dll"; "WrapperVersion/d3dcompiler_46e.dll" ] do
            use entry = enbZip.CreateEntry(name).Open()
            entry.Write(Encoding.UTF8.GetBytes name)

        enbZip.Dispose()
        archiveOutput.Dispose()

        let enbArtifact =
            enbStore.Artifacts.Add(
                { Id = Guid.NewGuid()
                  WorkspaceId = enbWorkspace
                  Path = enbArchive
                  Storage = ArtifactStorage.Reference },
                CancellationToken.None
            )
            |> wait
            |> result

        let enbWorkflow = WorkflowState()
        let mutable enbChild =
            { Phase = EnbPhase.Available
              Status = "ENBSeries is available"
              Detail = ""
              RuntimeVersion = "0.505"
              PresetVersion = "" }

        let enbDependencies =
            { enbWorkflow.Dependencies with
                ReadEnb = fun _ _ -> Task.FromResult enbChild
                SelectEnb =
                    fun workspace profile _ _ token ->
                        task {
                            enbChild <-
                                { enbChild with
                                    Phase = EnbPhase.Installing
                                    Status = "Installing ENBSeries" }

                            let! _ =
                                enbStore.InstallEnb(
                                    workspace,
                                    profile,
                                    EnbCatalogue.lean,
                                    enbArtifact,
                                    [],
                                    token,
                                    runtimeOnly = true
                                )

                            enbChild <-
                                { enbChild with
                                    Phase = EnbPhase.Ready
                                    Status = "ENBSeries is installed" }

                            return enbChild
                        } }

        use enbOwner = new SkyrimSetupCoordinator(enbStore, enbDependencies)
        releaseEnbGeneration.Reset()
        let _ = enbOwner.Start(enbWorkspace, enbProfile, enbWithArchive, CancellationToken.None) |> wait

        try
            if not (enteredEnbGeneration.Wait(TimeSpan.FromSeconds 10.)) then
                failwith "ENB did not reach the held generation step."

            let deployed = enbStore.Deployments.Read enbProfile |> wait |> result
            let startedEnb = enbOwner.Read(enbWorkspace, enbProfile, noChoice, CancellationToken.None) |> wait
            let during = enbOwner.Read(enbWorkspace, enbProfile, noChoice, CancellationToken.None) |> wait
            let continued = enbOwner.Continue(enbWorkspace, enbProfile, CancellationToken.None) |> wait
            let afterContinue = enbStore.Deployments.Read enbProfile |> wait |> result

            check
                writer
                "activeEnbGenerationDoesNotTriggerParentRecovery"
                (startedEnb.Phase = SkyrimSetupPhase.SettingUpEnb
                 && deployed.ActiveGeneration.IsSome
                 && deployed.PendingReceipt.IsSome
                 && during.Phase = SkyrimSetupPhase.SettingUpEnb
                 && during.Active
                 && not during.CanContinue
                 && continued.Phase = SkyrimSetupPhase.SettingUpEnb
                 && afterContinue.PendingReceipt = deployed.PendingReceipt)
        finally
            releaseEnbGeneration.Set()

        let afterEnb =
            until
                "finished ENB generation"
                (fun () -> enbOwner.Read(enbWorkspace, enbProfile, noChoice, CancellationToken.None) |> wait)
                (fun value -> value.Phase = SkyrimSetupPhase.Ready || value.Phase = SkyrimSetupPhase.Available)

        let finalEnbIntent =
            until
                "ENB child completion finishes parent setup"
                (fun () -> enbStore.SkyrimSetups.Read(enbWorkspace, enbProfile) |> wait)
                (Option.exists _.Completed)
        let finalEnbDeployment = enbStore.Deployments.Read enbProfile |> wait |> result

        check
            writer
            "finishedEnbGenerationCompletesParentSetup"
            ((afterEnb.Phase = SkyrimSetupPhase.Ready || afterEnb.Phase = SkyrimSetupPhase.Available)
             && finalEnbDeployment.PendingReceipt.IsNone
             && (finalEnbIntent |> Option.exists _.Completed))


    let private heldSkseGenerationEvidence
        writer area (store: OperationStore) noChoice skseOnly
        (releaseSkseGeneration: ManualResetEventSlim)
        (enteredSkseGeneration: ManualResetEventSlim) =
        let pausedWorkspace, pausedProfile, _ = createWorkspace store area "paused-skse" true
        let pausedWorkflow = WorkflowState()
        pausedWorkflow.HoldSkse()
        let pausedChanges = Event<Guid * Guid>()
        use pausedOwner =
            new SkyrimSetupCoordinator(
                store,
                pausedWorkflow.Dependencies,
                childChanges = [ pausedChanges.Publish ]
            )
        let _ = pausedOwner.Start(pausedWorkspace, pausedProfile, skseOnly, CancellationToken.None) |> wait
        until "held SKSE component starts" (fun () -> pausedWorkflow.SkseStarts) ((=) 1)
        |> ignore
        let installing = pausedOwner.Read(pausedWorkspace, pausedProfile, noChoice, CancellationToken.None) |> wait
        let context =
            (store.GameContexts :> IGameContexts).Read(pausedWorkspace, pausedProfile)
            |> wait
            |> result

        let runtime = context.Binding.Value.Evidence.Executable.Value.FileVersion
        use archive = new MemoryStream()

        use zip = new ZipArchive(archive, ZipArchiveMode.Create, true)

        for name in
            [ "skse64_paused/skse64_loader.exe"
              "skse64_paused/skse64_" + runtime.Replace('.', '_') + ".dll"
              "skse64_paused/Data/Scripts/skse.pex" ] do
            use entry = zip.CreateEntry(name).Open()
            entry.Write(Encoding.UTF8.GetBytes name)

        zip.Dispose()
        let bytes = archive.ToArray()
        use downloadServer = new DownloadServer(bytes)
        let artifactId = Guid.NewGuid()

        store.Downloads.Start
            { Id = artifactId
              WorkspaceId = pausedWorkspace
              Name = "skse-paused.zip"
              Sources = [ DownloadSource.Url(downloadServer.Url + "/good") ]
              ExpectedLength = Some(int64 bytes.Length)
              ExpectedSha256 = Some(Convert.ToHexStringLower(SHA256.HashData bytes)) }
        |> wait
        |> result
        |> ignore

        let artifact =
            until
                "paused SKSE artifact"
                (fun () -> store.Artifacts.Read(pausedWorkspace, artifactId) |> wait |> result)
                (fun value -> value.State = ArtifactState.Ready)

        let release: SkseRelease =
            { ModId = SkseResolver.NexusModId
              File =
                { Id = 911L
                  Name = "skse-paused.zip"
                  Version = "2.3.1"
                  Category = "MAIN"
                  Description = "Compatible with Skyrim Special Edition " + runtime + " from Steam"
                  Bytes = Some(int64 bytes.Length) }
              ComponentVersion = Version(2, 3, 1)
              RuntimeVersion = Version.Parse runtime }

        releaseSkseGeneration.Reset()

        let installation =
            store.InstallSkse(
                pausedWorkspace,
                pausedProfile,
                release,
                artifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )

        try
            if not (enteredSkseGeneration.Wait(TimeSpan.FromSeconds 10.)) then
                failwith "SKSE did not reach the held generation step."

            let deployed = store.Deployments.Read pausedProfile |> wait |> result
            let during = pausedOwner.Read(pausedWorkspace, pausedProfile, noChoice, CancellationToken.None) |> wait
            let continued =
                pausedOwner.Continue(pausedWorkspace, pausedProfile, CancellationToken.None) |> wait
            let afterContinue = store.Deployments.Read pausedProfile |> wait |> result

            check
                writer
                "activeSkseGenerationDoesNotTriggerParentRecovery"
                (installing.Phase = SkyrimSetupPhase.SettingUpSkse
                 && deployed.ActiveGeneration.IsSome
                 && deployed.PendingReceipt.IsSome
                 && during.Phase = SkyrimSetupPhase.SettingUpSkse
                 && during.Active
                 && not during.CanContinue
                 && continued.Phase = SkyrimSetupPhase.SettingUpSkse
                 && afterContinue.PendingReceipt = deployed.PendingReceipt
                 && not installation.IsCompleted)
        finally
            releaseSkseGeneration.Set()

        let installedGeneration = installation |> wait |> result
        pausedWorkflow.CompleteSkse()
        pausedChanges.Trigger(pausedWorkspace, pausedProfile)
        let finalIntent =
            until
                "SKSE child completion finishes parent setup"
                (fun () -> store.SkyrimSetups.Read(pausedWorkspace, pausedProfile) |> wait)
                (Option.exists _.Completed)
        let finalDeployment = store.Deployments.Read pausedProfile |> wait |> result

        check
            writer
            "finishedSkseGenerationCompletesParentSetup"
            (finalDeployment.ActiveGeneration = Some installedGeneration
             && finalDeployment.PendingReceipt.IsNone
             && (finalIntent |> Option.exists _.Completed))


    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject("skyrimSetup")

        let state = Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-state")).FullName
        use releaseSkseGeneration = new ManualResetEventSlim(true)
        use enteredSkseGeneration = new ManualResetEventSlim(false)

        use store =
            new OperationStore(
                state,
                skseCheckpoint =
                    (fun name _ ->
                        if name = "install-intent" && not releaseSkseGeneration.IsSet then
                            enteredSkseGeneration.Set()
                            releaseSkseGeneration.Wait(TimeSpan.FromSeconds 30.) |> ignore)
            )
        let workspace, profile, _ = createWorkspace store area "selected" true
        let workflow = WorkflowState()
        use coordinator = new SkyrimSetupCoordinator(store, workflow.Dependencies)
        let noChoice = SetupSelection.none
        let initial = coordinator.Read(workspace, profile, noChoice, CancellationToken.None) |> wait
        let before = store.Deployments.Read profile |> wait |> result

        check writer "noDefaultComponentChoice" (not initial.CanStart)
        check writer "noDefaultDeployment" (before.ActiveGeneration.IsNone)
        check writer "noDefaultIntent" ((store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone)

        let cancelledBeforeApply = coordinator.Cancel(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "cancelBeforeApplyDoesNotWrite"
            (not cancelledBeforeApply.CanCancel
             && (store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone
             && (store.Deployments.Read profile |> wait |> result).ActiveGeneration.IsNone)

        let enbWithoutArchive = { noChoice with Enb = SetupAction.Install }
        let enbBlocked = coordinator.Start(workspace, profile, enbWithoutArchive, CancellationToken.None) |> wait

        check
            writer
            "missingEnbArchiveDoesNotStart"
            (not enbBlocked.CanStart
             && (store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone)

        let enbWithArchive = { enbWithoutArchive with EnbArchive = Some "downloaded-enb.zip" }
        let fnisOnly = { noChoice with Fnis = SetupAction.Install }
        let combined =
            { Skse = SetupAction.Install
              Enb = SetupAction.Install
              Fnis = SetupAction.Install
              EnbArchive = Some "downloaded-enb.zip" }
        let skseOnly = { noChoice with Skse = SetupAction.Install }

        let started = coordinator.Start(workspace, profile, skseOnly, CancellationToken.None) |> wait

        let retained = store.SkyrimSetups.Read(workspace, profile) |> wait
        check writer "appliedChoiceRetained" (retained |> Option.exists (fun item -> item.Selection = skseOnly))
        check writer "unselectedComponentsNotStarted" (started.Selection.Enb = SetupAction.Unchanged && started.Selection.Fnis = SetupAction.Unchanged)

        let _ =
            until
                "engine starts the selected SKSE component"
                (fun () -> workflow.SkseStarts)
                ((=) 1)

        check
            writer
            "selectedSkseOnlyExecutes"
            (workflow.SkseStarts = 1 && workflow.EnbSelections = 0 && workflow.FnisInstalls = 0)

        let completed =
            until
                "setup completes without a view or Continue request"
                (fun () -> store.SkyrimSetups.Read(workspace, profile) |> wait)
                (Option.exists _.Completed)

        check writer "engineCompletesWithoutView" (completed |> Option.exists _.Completed)

        let resumeWorkspace, resumeProfile, _ = createWorkspace store area "restart-active" true
        let resumeWorkflow = WorkflowState()
        resumeWorkflow.HoldSkse()
        let originalOwner = new SkyrimSetupCoordinator(store, resumeWorkflow.Dependencies)
        originalOwner.Start(resumeWorkspace, resumeProfile, skseOnly, CancellationToken.None)
        |> wait
        |> ignore
        until "SKSE starts before owner restart" (fun () -> resumeWorkflow.SkseStarts) ((=) 1)
        |> ignore
        (originalOwner :> IDisposable).Dispose()
        resumeWorkflow.CompleteSkse()
        use resumedStore = new OperationStore(state)
        use resumedOwner = new SkyrimSetupCoordinator(resumedStore, resumeWorkflow.Dependencies)
        let resumedContext =
            (resumedStore.GameContexts :> IGameContexts).Read(resumeWorkspace, resumeProfile)
            |> wait
            |> result
        (resumedStore.GameContexts :> IGameContexts)
            .Refresh(resumeWorkspace, resumeProfile, resumedContext.Revision)
        |> wait
        |> result
        |> ignore
        resumedOwner.Read(resumeWorkspace, resumeProfile, noChoice, CancellationToken.None)
        |> wait
        |> ignore
        let resumedIntent =
            until
                "persisted active setup completes after owner restart"
                (fun () -> resumedStore.SkyrimSetups.Read(resumeWorkspace, resumeProfile) |> wait)
                (Option.exists _.Completed)

        check
            writer
            "activeSetupResumesOnInitialReadAfterRestart"
            ((resumedIntent |> Option.exists _.Completed) && resumeWorkflow.SkseStarts = 1)

        use reopened = new OperationStore(state)
        use afterRestart = new SkyrimSetupCoordinator(reopened, workflow.Dependencies)
        let gameContext =
            (reopened.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, profile, gameContext.Revision)
        |> wait
        |> result
        |> ignore

        let availableAgain = afterRestart.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "completedSetupAcceptsNewChoices"
            ((completed |> Option.exists _.Completed)
             && availableAgain.Phase = SkyrimSetupPhase.Available
             && availableAgain.Selection = noChoice)

        let failedWorkspace, failedProfile, _ = createWorkspace store area "failed-skse" true
        let failing = WorkflowState()
        failing.FailSkse()
        use failedOwner = new SkyrimSetupCoordinator(store, failing.Dependencies)
        let _ = failedOwner.Start(failedWorkspace, failedProfile, skseOnly, CancellationToken.None) |> wait

        let failed =
            until
                "SKSE setup failure"
                (fun () ->
                    let current =
                        failedOwner.Read(failedWorkspace, failedProfile, noChoice, CancellationToken.None)
                        |> wait

                    if current.CanContinue && current.Phase <> SkyrimSetupPhase.Failed then
                        failedOwner.Continue(failedWorkspace, failedProfile, CancellationToken.None)
                        |> wait
                    else
                        current)
                (fun current -> current.Phase = SkyrimSetupPhase.Failed)

        let repeated =
            failedOwner.Continue(failedWorkspace, failedProfile, CancellationToken.None)
            |> wait

        check
            writer
            "automaticContinueKeepsSkseFailureWithoutRetry"
            (failing.SkseStarts = 1
             && repeated.Phase = SkyrimSetupPhase.Failed
             && repeated.Status = failed.Status
             && repeated.Detail = failed.Detail)

        failing.AllowSkse()

        let explicitRetry =
            failedOwner.Start(failedWorkspace, failedProfile, skseOnly, CancellationToken.None)
            |> wait

        check
            writer
            "explicitApplyRetriesFailedSkse"
            (failing.SkseStarts = 2
             && explicitRetry.Phase <> SkyrimSetupPhase.Failed)

        let failedEnbWorkspace, failedEnbProfile, _ =
            createWorkspace store area "failed-enb" true

        let failingEnb = WorkflowState()
        failingEnb.FailEnb()
        use failedEnbOwner = new SkyrimSetupCoordinator(store, failingEnb.Dependencies)

        let _ =
            failedEnbOwner.Start(
                failedEnbWorkspace,
                failedEnbProfile,
                enbWithArchive,
                CancellationToken.None
            )
            |> wait

        let failedEnb =
            until
                "ENB setup failure"
                (fun () ->
                    let current =
                        failedEnbOwner.Read(
                            failedEnbWorkspace,
                            failedEnbProfile,
                            noChoice,
                            CancellationToken.None
                        )
                        |> wait

                    if current.CanContinue && current.Phase <> SkyrimSetupPhase.Failed then
                        failedEnbOwner.Continue(failedEnbWorkspace, failedEnbProfile, CancellationToken.None)
                        |> wait
                    else
                        current)
                (fun current -> current.Phase = SkyrimSetupPhase.Failed)

        let repeatedEnb =
            failedEnbOwner.Continue(failedEnbWorkspace, failedEnbProfile, CancellationToken.None)
            |> wait

        check
            writer
            "automaticContinueKeepsEnbFailureWithoutRetry"
            (failingEnb.EnbSelections = 1
             && repeatedEnb.Phase = SkyrimSetupPhase.Failed
             && repeatedEnb.Status = failedEnb.Status
             && repeatedEnb.Detail = failedEnb.Detail)

        failingEnb.AllowEnb()

        let _ =
            failedEnbOwner.Start(
                failedEnbWorkspace,
                failedEnbProfile,
                enbWithArchive,
                CancellationToken.None
            )
            |> wait

        let readyEnb =
            until
                "explicit ENB setup retry"
                (fun () ->
                    failedEnbOwner.Read(
                        failedEnbWorkspace,
                        failedEnbProfile,
                        noChoice,
                        CancellationToken.None
                    )
                    |> wait)
                (fun current ->
                    failingEnb.EnbSelections = 2
                    && current.Phase <> SkyrimSetupPhase.Failed)

        check
            writer
            "explicitApplyRetriesFailedEnb"
            (failingEnb.EnbSelections = 2
             && readyEnb.Phase <> SkyrimSetupPhase.Failed)

        let execute name selection expected =
            let freshWorkspace, freshProfile, _ = createWorkspace store area name true
            let state = WorkflowState()
            use owner = new SkyrimSetupCoordinator(store, state.Dependencies)
            let initial = owner.Start(freshWorkspace, freshProfile, selection, CancellationToken.None) |> wait

            let _ =
                until
                    (name + " selected component call")
                    (fun () ->
                        let current = owner.Read(freshWorkspace, freshProfile, noChoice, CancellationToken.None) |> wait

                        if current.CanContinue then
                            owner.Continue(freshWorkspace, freshProfile, CancellationToken.None) |> wait
                        else
                            current)
                    (fun _ -> expected state)

            let retained = store.SkyrimSetups.Read(freshWorkspace, freshProfile) |> wait
            initial, state, retained

        let _, enbOnlyState, enbOnlyIntent = execute "enb-only" enbWithArchive (fun state -> state.EnbSelections = 1)

        check
            writer
            "selectedEnbOnlyExecutes"
            (enbOnlyState.SkseStarts = 0
             && enbOnlyState.EnbSelections = 1
             && enbOnlyState.FnisInstalls = 0
             && (enbOnlyIntent
                 |> Option.exists (fun item ->
                     item.Selection.Enb = SetupAction.Install
                     && item.Selection.Skse = SetupAction.Unchanged
                     && item.Selection.Fnis = SetupAction.Unchanged)))

        let _, fnisOnlyState, fnisOnlyIntent = execute "fnis-only" fnisOnly (fun state -> state.FnisInstalls = 1)

        check
            writer
            "selectedFnisOnlyExecutes"
            (fnisOnlyState.SkseStarts = 0
             && fnisOnlyState.EnbSelections = 0
             && fnisOnlyState.FnisInstalls = 1
             && (fnisOnlyIntent |> Option.exists (fun item -> item.Selection = fnisOnly)))

        fnisNexusWarningEvidence writer area state store noChoice fnisOnly

        let _, allState, _ =
            execute
                "all-selected"
                combined
                (fun state -> state.SkseStarts = 1 && state.EnbSelections = 1 && state.FnisInstalls = 1)

        check
            writer
            "combinedChoicesExecuteOnceEach"
            (allState.SkseStarts = 1 && allState.EnbSelections = 1 && allState.FnisInstalls = 1)

        let retryWorkspace, retryProfile, _ = createWorkspace store area "cancel-and-retry" true
        let retryWorkflow = WorkflowState()
        retryWorkflow.BlockEnb()
        use retryOwner = new SkyrimSetupCoordinator(store, retryWorkflow.Dependencies)

        let _ =
            retryOwner.Start(retryWorkspace, retryProfile, enbWithArchive, CancellationToken.None)
            |> wait

        let _ =
            until
                "ENB acquisition starts after Apply"
                (fun () ->
                    let current = retryOwner.Read(retryWorkspace, retryProfile, noChoice, CancellationToken.None) |> wait

                    if current.CanContinue then
                        retryOwner.Continue(retryWorkspace, retryProfile, CancellationToken.None) |> wait
                    else
                        current)
                (fun _ -> retryWorkflow.EnbSelections = 1)

        if not (retryWorkflow.WaitForEnb()) then
            failwith "Setup did not enter the ENB wait."

        let activeGeneration =
            (store.Deployments.Read retryProfile |> wait |> result).ActiveGeneration
            |> Option.defaultWith (fun () -> failwith "Setup did not deploy the profile.")

        let installedLoader = Path.Combine(area, "cancel-and-retry-skse64_loader.exe")
        File.WriteAllText(installedLoader, "installed SKSE fixture")

        store.SkseLoaders.Save(
            retryWorkspace,
            retryProfile,
            Guid.NewGuid(),
            Guid.NewGuid(),
            activeGeneration,
            installedLoader,
            "2.2.6",
            "1.6.1170",
            String.replicate 64 "a",
            String.replicate 64 "b",
            1L,
            2L
        )
        |> wait

        let observedWhileActorRuns =
            retryOwner.Continue(retryWorkspace, retryProfile, CancellationToken.None)
            |> wait

        check
            writer
            "concurrentContinueObservesActorWithoutDuplicateWork"
            (observedWhileActorRuns.Phase = SkyrimSetupPhase.SettingUpEnb
             && retryWorkflow.EnbSelections = 1)

        let cancelledActive =
            retryOwner.Cancel(retryWorkspace, retryProfile, CancellationToken.None) |> wait

        let cancelledRead =
            retryOwner.Read(retryWorkspace, retryProfile, noChoice, CancellationToken.None)
            |> wait

        check
            writer
            "activeCancellationShowsInstalledComponentsWithoutRetry"
            (cancelledActive.Phase = SkyrimSetupPhase.Cancelled
             && not cancelledActive.CanStart
             && cancelledActive.Selection = noChoice
             && (cancelledRead.Components |> List.exists (fun item -> item.Id = "skse" && item.Installed))
             && (cancelledRead.Components |> List.exists (fun item -> item.Id = "enb" && not item.Installed))
             && retryWorkflow.EnbSelections = 1
             && retryWorkflow.FnisInstalls = 0)

        let recoveryWorkspace, recoveryProfile, _ = createWorkspace store area "cancel-recovery" true

        store.SkyrimSetups.Save
            { WorkspaceId = recoveryWorkspace
              ProfileId = recoveryProfile
              Selection = skseOnly
              Cancelled = false
              Completed = false
              Stage = "deployment"
              ActionId = None
              CancelRequested = true
              CancelDetail = "Cancellation was requested."
              RequestedAt = DateTimeOffset.UtcNow }
        |> wait

        use recoveryStore = new OperationStore(state)
        use recoveryOwner = new SkyrimSetupCoordinator(recoveryStore, retryWorkflow.Dependencies)
        let recoveryContext =
            (recoveryStore.GameContexts :> IGameContexts).Read(recoveryWorkspace, recoveryProfile)
            |> wait
            |> result
        (recoveryStore.GameContexts :> IGameContexts)
            .Refresh(recoveryWorkspace, recoveryProfile, recoveryContext.Revision)
        |> wait
        |> result
        |> ignore
        let recoveryBefore =
            recoveryOwner.Read(recoveryWorkspace, recoveryProfile, noChoice, CancellationToken.None)
            |> wait
        let recoveryAfter =
            recoveryOwner.Continue(recoveryWorkspace, recoveryProfile, CancellationToken.None)
            |> wait
        let recoveredIntent = recoveryStore.SkyrimSetups.Read(recoveryWorkspace, recoveryProfile) |> wait

        check
            writer
            "cancelRecoveryContinuesAfterRestart"
            (recoveryBefore.Phase = SkyrimSetupPhase.RecoveryRequired
             && recoveryBefore.CanContinue
             && recoveryAfter.Phase = SkyrimSetupPhase.Cancelled
             && (recoveredIntent |> Option.exists _.Cancelled))

        let retrySelection = { noChoice with Fnis = SetupAction.Install }

        let fresh =
            retryOwner.Read(retryWorkspace, retryProfile, retrySelection, CancellationToken.None)
            |> wait

        check
            writer
            "cancelledSetupAcceptsNewSelection"
            (fresh.CanStart && fresh.Selection = retrySelection)

        let skseUpdate = { noChoice with Skse = SetupAction.Update }
        let withoutUpdate = retryOwner.Read(retryWorkspace, retryProfile, skseUpdate, CancellationToken.None) |> wait
        retryWorkflow.SkseUpdate "2.3.0"
        let withUpdate = retryOwner.Read(retryWorkspace, retryProfile, skseUpdate, CancellationToken.None) |> wait
        retryWorkflow.CompleteSkse()
        let clearedUpdate = retryOwner.Read(retryWorkspace, retryProfile, skseUpdate, CancellationToken.None) |> wait

        check
            writer
            "skseUpdateRequiresConfirmedVersion"
            (not withoutUpdate.CanStart
             && withUpdate.CanStart
             && (withUpdate.Components |> List.exists (fun item -> item.Id = "skse" && item.UpdateVersion = Some "2.3.0"))
             && not clearedUpdate.CanStart
             && (clearedUpdate.Components |> List.exists (fun item -> item.Id = "skse" && item.UpdateVersion.IsNone)))

        let _ =
            retryOwner.Start(retryWorkspace, retryProfile, retrySelection, CancellationToken.None)
            |> wait

        let _ =
            until
                "fresh attempt applies after cancellation"
                (fun () ->
                    let current = retryOwner.Read(retryWorkspace, retryProfile, noChoice, CancellationToken.None) |> wait

                    if current.CanContinue then
                        retryOwner.Continue(retryWorkspace, retryProfile, CancellationToken.None) |> wait
                    else
                        current)
                (fun _ -> retryWorkflow.FnisInstalls = 1)

        check
            writer
            "explicitNewAttemptRunsOnlyChosenComponent"
            (retryWorkflow.EnbSelections = 1 && retryWorkflow.FnisInstalls = 1)

        heldSkseGenerationEvidence
            writer area store noChoice skseOnly releaseSkseGeneration enteredSkseGeneration

        heldEnbGenerationEvidence writer area noChoice enbWithArchive

        writer.WriteEndObject()
