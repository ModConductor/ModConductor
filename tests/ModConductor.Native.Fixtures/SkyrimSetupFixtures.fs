namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Engine
open ModConductor.Enb
open ModConductor.Executables
open ModConductor.FilePlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.GameLaunching
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

    let private prepareProton runtimeDirectory =
        if OperatingSystem.IsLinux() then
            let launcher = Path.Combine(runtimeDirectory, "proton")
            File.WriteAllText(launcher, "#!/bin/sh\nexit 0\n")

            File.SetUnixFileMode(
                launcher,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

            File.WriteAllText(
                Path.Combine(runtimeDirectory, "toolmanifest.vdf"),
                "manifest { version 2 commandline \"/proton %verb%\" }"
            )

    let private createWorkspace (store: OperationStore) area name includeProton =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()

        let root =
            Directory.CreateDirectory(Path.Combine(area, name + "-workspace")).FullName

        let game, proton =
            ProtonFixtures.create (Path.Combine(area, name + "-installation"))

        prepareProton proton.RuntimeDirectory
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, name, StorageWorker.select root) |> wait |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = name }
        )
        |> wait
        |> result
        |> ignore

        let saved =
            (store.GameContexts :> IGameContexts)
                .Save(
                    workspace,
                    profile,
                    0L,
                    { GameId = GameId.SkyrimSpecialEditionSteam
                      Path = game
                      Proton =
                        if includeProton && OperatingSystem.IsLinux() then
                            Some proton
                        else
                            None }
                )
            |> wait

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
        let mutable skseReads = 0
        let mutable skseStarts = 0
        let mutable enbSelections = 0
        let mutable fnisInstalls = 0
        let mutable enbCancels = 0
        let mutable runCalls = 0
        let mutable blockEnb = false
        let enbStarted = new ManualResetEventSlim(false)
        let mutable blockFnis = false
        let fnisRelease = new ManualResetEventSlim(false)
        let mutable retainActiveFnisCancellation = false

        let inspection () =
            { WorkspaceId = Guid.Empty
              ProfileId = Guid.Empty
              GenerationId = generation
              Generator = "GenerateFNISforUsers.exe"
              Fingerprint = "fixture-fingerprint"
              Phase = output
              Status =
                if output = ModConductor.Fnis.FnisOutputPhase.Current then
                    "FNIS output is current"
                else
                    "FNIS output is stale"
              Detail = "The combined coordinator owns the next action."
              LatestRunId = latestRun
              ExitCode = None
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
            blockEnb <- false
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
        member _.EnbSelections = enbSelections
        member _.FnisInstalls = fnisInstalls
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
                            Phase = SksePhase.Ready
                            Status = "SKSE is ready" }

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
                                Phase = EnbPhase.Ready
                                Status = "Lean ENB is ready" }

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
                            Phase = FnisPhase.Ready
                            Status = "FNIS is ready" }

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

    let observe (writer: Utf8JsonWriter) area =
        writer.WriteStartObject("skyrimSetup")

        let state = Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-state")).FullName
        use store = new OperationStore(state)
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

        use resumed = new SkyrimSetupCoordinator(store, workflow.Dependencies)
        let restored = resumed.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "appliedChoiceSurvivesCoordinatorRestart"
            (restored.CanCancel && restored.Selection = skseOnly)

        let _ = resumed.Continue(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "selectedSkseOnlyExecutes"
            (workflow.SkseStarts = 1 && workflow.EnbSelections = 0 && workflow.FnisInstalls = 0)

        use reopened = new OperationStore(state)
        use afterRestart = new SkyrimSetupCoordinator(reopened, workflow.Dependencies)
        let gameContext =
            (reopened.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, profile, gameContext.Revision)
        |> wait
        |> result
        |> ignore

        let retainedAfterRestart = afterRestart.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "appliedChoiceSurvivesStoreRestart"
            (retainedAfterRestart.Selection = skseOnly)

        let _ = afterRestart.Continue(workspace, profile, CancellationToken.None) |> wait
        let completed = store.SkyrimSetups.Read(workspace, profile) |> wait
        let availableAgain = afterRestart.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "completedSetupAcceptsNewChoices"
            (retainedAfterRestart.CanContinue
             && (completed |> Option.exists _.Completed)
             && availableAgain.Phase = SkyrimSetupPhase.Available
             && availableAgain.Selection = noChoice)

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

        let retrySelection = { noChoice with Fnis = SetupAction.Install }

        let fresh =
            retryOwner.Read(retryWorkspace, retryProfile, retrySelection, CancellationToken.None)
            |> wait

        check
            writer
            "cancelledSetupAcceptsNewSelection"
            (fresh.CanStart && fresh.Selection = retrySelection)

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

        writer.WriteEndObject()
