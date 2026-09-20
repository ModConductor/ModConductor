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
                    0L,
                    { Path = game
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
                    skse <-
                        { skse with
                            Phase = SksePhase.Ready
                            Status = "SKSE is ready" }

                    Task.FromResult skse
              CancelSkse = fun _ _ -> Task.FromResult skse
              ReadEnb = fun _ _ -> Task.FromResult enb
              OpenEnb =
                fun _ _ ->
                    enb <-
                        { enb with
                            Phase = EnbPhase.WaitingForArchive
                            Status = "Waiting for the ENBSeries archive" }

                    Task.FromResult enb
              SelectEnb =
                fun _ _ _ _ token ->
                    task {
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
                    fnis <-
                        { fnis with
                            Phase = FnisPhase.Ready
                            Status = "FNIS is ready" }

                    Task.FromResult fnis
              UpdateFnis = fun _ _ -> Task.FromResult fnis
              CancelFnis = fun _ _ -> Task.FromResult fnis
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

    let private completeFlow
        (coordinator: SkyrimSetupCoordinator)
        (workflow: WorkflowState)
        workspace
        profile
        existing
        =
        let planned =
            coordinator.Read(workspace, profile, true, CancellationToken.None) |> wait

        let started =
            coordinator.Start(
                workspace,
                profile,
                true,
                planned.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        let afterSkse =
            if existing then
                started
            else
                coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        let waiting =
            coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        let afterEnb =
            coordinator.SelectEnbArchive(
                workspace,
                profile,
                Guid.NewGuid(),
                "enbseries_skyrimse_v0505.zip",
                CancellationToken.None
            )
            |> wait

        let afterEnbCompleted =
            until
                "ENB child completion"
                (fun () ->
                    coordinator.Read(workspace, profile, true, CancellationToken.None) |> wait)
                (fun value -> value.Phase = SkyrimSetupPhase.SettingUpFnis)

        let stale = coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        workflow.BlockFnis()

        let running =
            coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        workflow.ReleaseFnis()

        let ready =
            until
                "FNIS output completion"
                (fun () ->
                    coordinator.Read(workspace, profile, true, CancellationToken.None) |> wait)
                (fun value -> value.Phase = SkyrimSetupPhase.Ready)

        let completed =
            coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        planned,
        started,
        afterSkse,
        waiting,
        afterEnb,
        afterEnbCompleted,
        stale,
        running,
        ready,
        completed

    let observe (writer: Utf8JsonWriter) area =
        let state =
            Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-state")).FullName

        let workflow = WorkflowState()
        let mutable workspace = Guid.Empty
        let mutable profile = Guid.Empty
        let mutable completedToken = ""

        writer.WriteStartObject("skyrimSetup")

        do
            use store = new OperationStore(state)
            let createdWorkspace, createdProfile, _ = createWorkspace store area "combined" true

            workspace <- createdWorkspace
            profile <- createdProfile
            use coordinator = new SkyrimSetupCoordinator(store, workflow.Dependencies)
            let before = store.Deployments.Read profile |> wait |> result

            let (planned,
                 started,
                 afterSkse,
                 waiting,
                 afterEnb,
                 afterEnbCompleted,
                 stale,
                 running,
                 ready,
                 completed) =
                completeFlow coordinator workflow workspace profile false

            completedToken <- completed.PlanToken
            let deployed = store.Deployments.Read profile |> wait |> result

            check writer "cleanPlanIncludesInitialDeployment" (before.ActiveGeneration.IsNone)

            check
                writer
                "initialDeploymentPrecedesSkse"
                (started.Phase = SkyrimSetupPhase.WaitingForSkse
                 && deployed.ActiveGeneration.IsSome)

            check
                writer
                "combinedSkseThenEnbPause"
                (afterSkse.Phase = SkyrimSetupPhase.SettingUpEnb
                 && waiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive)

            check
                writer
                "combinedEnbThenOptionalFnis"
                (afterEnb.Phase = SkyrimSetupPhase.SettingUpEnb
                 && afterEnb.CanCancel
                 && afterEnbCompleted.Phase = SkyrimSetupPhase.SettingUpFnis
                 && stale.Phase = SkyrimSetupPhase.FnisStale
                 && running.Phase = SkyrimSetupPhase.FnisRunning
                 && running.CanCancel)

            check
                writer
                "combinedPluginLaunchReady"
                (ready.Phase = SkyrimSetupPhase.Ready
                 && completed.Phase = SkyrimSetupPhase.Ready
                 && planned.IncludeFnis)

            let retained = store.SkyrimSetups.Read(workspace, profile) |> wait

            check
                writer
                "completedFnisChoiceIsDurable"
                (retained |> Option.exists (fun value -> value.Completed && value.IncludeFnis))

            let active = deployed.ActiveGeneration
            store.SkyrimSetups.Remove(workspace, profile) |> wait
            workflow.Reset()

            let existingPlan =
                coordinator.Read(workspace, profile, true, CancellationToken.None) |> wait

            let existingStart =
                coordinator.Start(
                    workspace,
                    profile,
                    true,
                    existingPlan.PlanToken,
                    true,
                    CancellationToken.None
                )
                |> wait

            let existingDeployment = store.Deployments.Read profile |> wait |> result

            check
                writer
                "existingWorkspaceKeepsActiveDeployment"
                (existingStart.Phase = SkyrimSetupPhase.SettingUpEnb
                 && existingDeployment.ActiveGeneration = active
                 && (existingPlan.Changes
                     |> List.forall (fun change -> change.Title <> "Prepare the first deployment")))

            store.SkyrimSetups.Remove(workspace, profile) |> wait
            workflow.Reset()

            let cancelPlan =
                coordinator.Read(workspace, profile, false, CancellationToken.None) |> wait

            let cancelStarted =
                coordinator.Start(
                    workspace,
                    profile,
                    false,
                    cancelPlan.PlanToken,
                    true,
                    CancellationToken.None
                )
                |> wait

            let cancelWaiting =
                if cancelStarted.Phase = SkyrimSetupPhase.WaitingForEnbArchive then
                    cancelStarted
                else
                    coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

            workflow.BlockEnb()

            let activeSelection =
                coordinator.SelectEnbArchive(
                    workspace,
                    profile,
                    Guid.NewGuid(),
                    "enbseries-active-cancel.zip",
                    CancellationToken.None
                )
                |> wait

            let childStarted = workflow.WaitForEnb()

            let cancelled =
                coordinator.Cancel(workspace, profile, CancellationToken.None) |> wait

            let cancelledIntent = store.SkyrimSetups.Read(workspace, profile) |> wait

            check
                writer
                "combinedCancelOwnsActiveEnb"
                (cancelWaiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive
                 && activeSelection.Phase = SkyrimSetupPhase.SettingUpEnb
                 && activeSelection.CanCancel
                 && childStarted
                 && cancelled.Phase = SkyrimSetupPhase.Cancelled
                 && cancelled.Detail.Contains("ENB setup cancelled", StringComparison.Ordinal)
                 && (cancelledIntent
                     |> Option.exists (fun value ->
                         value.Cancelled
                         && not value.CancelRequested
                         && value.CancelDetail.Contains(
                             "ENB setup cancelled",
                             StringComparison.Ordinal
                         )))
                 && workflow.EnbCancels = 1)

            store.SkyrimSetups.Remove(workspace, profile) |> wait
            workflow.Reset()

            let crashPlan =
                coordinator.Read(workspace, profile, false, CancellationToken.None) |> wait

            let crashStarted =
                coordinator.Start(
                    workspace,
                    profile,
                    false,
                    crashPlan.PlanToken,
                    true,
                    CancellationToken.None
                )
                |> wait

            let crashWaiting =
                if crashStarted.Phase = SkyrimSetupPhase.WaitingForEnbArchive then
                    crashStarted
                else
                    coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

            workflow.BlockEnb()

            coordinator.SelectEnbArchive(
                workspace,
                profile,
                Guid.NewGuid(),
                "enbseries-crash-cancel.zip",
                CancellationToken.None
            )
            |> wait
            |> ignore

            if not (workflow.WaitForEnb()) then
                failwith "The ENB child did not reach its active cancellation boundary."

            let crashIntent =
                store.SkyrimSetups.Read(workspace, profile)
                |> wait
                |> Option.defaultWith (fun () -> failwith "The setup intent is missing.")

            store.SkyrimSetups.Save
                { crashIntent with
                    CancelRequested = true
                    Cancelled = false
                    Completed = false
                    CancelDetail = "Cancellation was requested before restart." }
            |> wait

            check
                writer
                "activeCancellationIntentIsDurableBeforeRestart"
                (crashWaiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive)

        use reopened = new OperationStore(state)

        let context =
            (reopened.GameContexts :> IGameContexts).Read workspace |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, context.Revision)
        |> wait
        |> result
        |> ignore

        use restarted = new SkyrimSetupCoordinator(reopened, workflow.Dependencies)

        let cancellationRecovery =
            restarted.Read(workspace, profile, false, CancellationToken.None) |> wait

        let cancelledAfterRestart =
            restarted.Continue(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "combinedCancellationCompletesAfterRestart"
            (cancellationRecovery.Phase = SkyrimSetupPhase.RecoveryRequired
             && cancelledAfterRestart.Phase = SkyrimSetupPhase.Cancelled
             && cancelledAfterRestart.Detail.Contains(
                 "ENB setup cancelled",
                 StringComparison.Ordinal
             )
             && workflow.EnbCancels = 2)

        reopened.SkyrimSetups.Remove(workspace, profile) |> wait
        workflow.Reset()

        let activePlan =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let recoveryStarted =
            restarted.Start(
                workspace,
                profile,
                true,
                activePlan.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        let waiting =
            if recoveryStarted.Phase = SkyrimSetupPhase.WaitingForEnbArchive then
                recoveryStarted
            else
                restarted.Continue(workspace, profile, CancellationToken.None) |> wait

        let deployed = reopened.Deployments.Read profile |> wait |> result

        let prepared =
            reopened.Deployments.Prepare(
                Guid.NewGuid(),
                deployed.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        use interruptedCancellation = new CancellationTokenSource()

        let interrupted =
            reopened.Deployments.Activate(
                prepared.Id,
                prepared.Sources,
                (fun _ -> interruptedCancellation.Cancel()),
                interruptedCancellation.Token
            )
            |> wait

        let readsBeforeRecovery = workflow.SkseReads

        let recovery =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let childReadsBlocked = workflow.SkseReads = readsBeforeRecovery

        let recovered =
            restarted.Continue(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "pendingDeploymentBlocksChildReads"
            (waiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive
             && recovery.Phase = SkyrimSetupPhase.RecoveryRequired
             && childReadsBlocked
             && Result.isError interrupted
             && recovered.Phase <> SkyrimSetupPhase.RecoveryRequired
             && prepared.Id <> Guid.Empty)

        let currentDeployment = reopened.Deployments.Read profile |> wait |> result

        let nextGeneration =
            reopened.Deployments.Prepare(
                Guid.NewGuid(),
                currentDeployment.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        reopened.Deployments.Activate(
            nextGeneration.Id,
            nextGeneration.Sources,
            ignore,
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let changedGeneration =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        check
            writer
            "changedGenerationRequiresNewPlan"
            (changedGeneration.Phase = SkyrimSetupPhase.NeedsConsent)

        let resumed =
            restarted.Start(
                workspace,
                profile,
                true,
                changedGeneration.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        let currentContext =
            (reopened.GameContexts :> IGameContexts).Read workspace |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, currentContext.Revision)
        |> wait
        |> result
        |> ignore

        let stalePlan =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        check
            writer
            "changedContextRequiresNewPlan"
            (resumed.ConsentRecorded
             && stalePlan.Phase = SkyrimSetupPhase.NeedsConsent
             && stalePlan.PlanToken <> completedToken)

        workflow.ReadyWithStaleFnis()

        let fnisPlan =
            restarted.Start(
                workspace,
                profile,
                true,
                stalePlan.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        check
            writer
            "fnisChoiceSurvivesReadyRestart"
            (fnisPlan.IncludeFnis
             && (fnisPlan.Components |> List.exists (fun item -> item.Name = "FNIS")))

        reopened.SkyrimSetups.Remove(workspace, profile) |> wait
        workflow.FailedFnisOutput()
        let runsBeforeRetry = workflow.RunCalls

        let retryPlan =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let retried =
            restarted.Start(
                workspace,
                profile,
                true,
                retryPlan.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        check
            writer
            "failedFnisOutputRetriesThroughOwner"
            (workflow.RunCalls = runsBeforeRetry + 1
             && retried.Phase = SkyrimSetupPhase.Ready)

        let unrelatedChangeAt stage =
            reopened.SkyrimSetups.Remove(workspace, profile) |> wait
            let observedRun = Guid.NewGuid()
            workflow.ReadyWithCurrentFnis(Some observedRun)

            let planned =
                restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

            let currentContext =
                (reopened.GameContexts :> IGameContexts).Read workspace |> wait |> result

            let expectedAction = Guid.NewGuid()

            reopened.SkyrimSetups.Save
                { WorkspaceId = workspace
                  ProfileId = profile
                  IncludeFnis = true
                  PlanToken = planned.PlanToken
                  Cancelled = false
                  Completed = false
                  Stage = stage
                  ContextRevision = currentContext.Revision
                  ActionId = Some expectedAction
                  ArchivePath = if stage = "enb" then Some "expected-enb.zip" else None
                  CancelRequested = false
                  CancelDetail = ""
                  RequestedAt = DateTimeOffset.UtcNow }
            |> wait

            let deployment = reopened.Deployments.Read profile |> wait |> result

            let external =
                reopened.Deployments.Prepare(
                    Guid.NewGuid(),
                    deployment.Sources,
                    ignore,
                    CancellationToken.None
                )
                |> wait
                |> result

            reopened.Deployments.Activate(
                external.Id,
                external.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result
            |> ignore

            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let deploymentRollover = unrelatedChangeAt "deployment-running"
        let skseRollover = unrelatedChangeAt "skse"
        let enbRollover = unrelatedChangeAt "enb"
        let fnisInstallRollover = unrelatedChangeAt "fnis-install"
        let fnisRunRollover = unrelatedChangeAt "fnis-run"

        check
            writer
            "externalChangesInvalidateEveryRolloverPath"
            ([ deploymentRollover
               skseRollover
               enbRollover
               fnisInstallRollover
               fnisRunRollover ]
             |> List.forall (fun value ->
                 value.Phase = SkyrimSetupPhase.NeedsConsent
                 && not value.ConsentRecorded
                 && value.CanStart))

        reopened.SkyrimSetups.Remove(workspace, profile) |> wait
        workflow.Reset()

        let activeChangePlan =
            restarted.Read(workspace, profile, false, CancellationToken.None) |> wait

        let activeChangeStarted =
            restarted.Start(
                workspace,
                profile,
                false,
                activeChangePlan.PlanToken,
                true,
                CancellationToken.None
            )
            |> wait

        let activeChangeAfterSkse =
            if activeChangeStarted.Phase = SkyrimSetupPhase.WaitingForSkse then
                restarted.Continue(workspace, profile, CancellationToken.None) |> wait
            else
                activeChangeStarted

        let activeChangeWaiting =
            if activeChangeAfterSkse.Phase = SkyrimSetupPhase.WaitingForEnbArchive then
                activeChangeAfterSkse
            else
                restarted.Continue(workspace, profile, CancellationToken.None) |> wait

        workflow.BlockEnb()

        restarted.SelectEnbArchive(
            workspace,
            profile,
            Guid.NewGuid(),
            "enbseries-external-change.zip",
            CancellationToken.None
        )
        |> wait
        |> ignore

        if not (workflow.WaitForEnb()) then
            failwith "The ENB child did not reach the external-change boundary."

        let beforeActiveChange = reopened.Deployments.Read profile |> wait |> result

        let activeExternal =
            reopened.Deployments.Prepare(
                Guid.NewGuid(),
                beforeActiveChange.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        reopened.Deployments.Activate(
            activeExternal.Id,
            activeExternal.Sources,
            ignore,
            CancellationToken.None
        )
        |> wait
        |> result
        |> ignore

        let changedWhileActive =
            restarted.Read(workspace, profile, false, CancellationToken.None) |> wait

        let cancelledAfterChange =
            restarted.Cancel(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "externalChangeInvalidatesActiveChildConsent"
            (activeChangeWaiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive
             && changedWhileActive.Phase = SkyrimSetupPhase.NeedsConsent
             && not changedWhileActive.ConsentRecorded
             && changedWhileActive.Active
             && changedWhileActive.CanCancel
             && not changedWhileActive.CanStart
             && cancelledAfterChange.Phase = SkyrimSetupPhase.Cancelled)

        reopened.SkyrimSetups.Remove(workspace, profile) |> wait
        workflow.Reset()
        workflow.ReadyWithStaleFnis()

        let fnisCancelPlan =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let fnisCancelRun = Guid.NewGuid()
        workflow.RunningFnis(fnisCancelRun)
        workflow.RetainActiveFnisCancellation()

        let fnisCancelContext =
            (reopened.GameContexts :> IGameContexts).Read workspace |> wait |> result

        reopened.SkyrimSetups.Save
            { WorkspaceId = workspace
              ProfileId = profile
              IncludeFnis = true
              PlanToken = fnisCancelPlan.PlanToken
              Cancelled = false
              Completed = false
              Stage = "fnis-run"
              ContextRevision = fnisCancelContext.Revision
              ActionId = Some fnisCancelRun
              ArchivePath = None
              CancelRequested = false
              CancelDetail = ""
              RequestedAt = DateTimeOffset.UtcNow }
        |> wait

        let fnisRunning =
            restarted.Read(workspace, profile, true, CancellationToken.None) |> wait

        let fnisCancellationPending =
            restarted.Cancel(workspace, profile, CancellationToken.None) |> wait

        let pendingFnisIntent = reopened.SkyrimSetups.Read(workspace, profile) |> wait

        workflow.CompleteFnisCancellation()

        let fnisCancellationCompleted =
            restarted.Continue(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "activeChildOutcomeKeepsCancellationDurableUntilTerminal"
            (fnisRunning.Phase = SkyrimSetupPhase.FnisRunning
             && fnisCancellationPending.Phase = SkyrimSetupPhase.RecoveryRequired
             && (pendingFnisIntent
                 |> Option.exists (fun value -> value.CancelRequested && not value.Cancelled))
             && fnisCancellationCompleted.Phase = SkyrimSetupPhase.Cancelled)

        if OperatingSystem.IsLinux() then
            let noPrefixWorkspace, noPrefixProfile, _ =
                createWorkspace reopened area "missing-prefix" false

            let before = reopened.Deployments.Read noPrefixProfile |> wait |> result

            let missing =
                restarted.Read(noPrefixWorkspace, noPrefixProfile, false, CancellationToken.None)
                |> wait

            let after = reopened.Deployments.Read noPrefixProfile |> wait |> result

            check
                writer
                "missingProtonPausesBeforeDeploymentWrite"
                (missing.Phase = SkyrimSetupPhase.Unavailable
                 && missing.Detail = "Start Skyrim once through Steam. Close it, then select Refresh."
                 && before.ActiveGeneration.IsNone
                 && after.ActiveGeneration.IsNone
                 && after.PendingReceipt.IsNone)

            let pendingWorkspace, pendingProfile = Guid.NewGuid(), Guid.NewGuid()

            let pendingRoot =
                Directory.CreateDirectory(Path.Combine(area, "pending-prefix-workspace")).FullName

            let pendingGame, pendingProton =
                ProtonFixtures.create (Path.Combine(area, "pending-prefix-installation"))

            prepareProton pendingProton.RuntimeDirectory
            let workspaces = reopened.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(
                    pendingWorkspace,
                    "Pending prefix",
                    StorageWorker.select pendingRoot
                )
                |> wait
                |> result

            workspaces.Edit(
                pendingWorkspace,
                created.Workspace.Revision,
                ProfileEdit.Create
                    { Id = pendingProfile
                      Name = "Pending prefix" }
            )
            |> wait
            |> result
            |> ignore

            let prefix = Path.Combine(pendingProton.CompatData, "pfx")
            let completedPrefix = prefix + ".after-first-run"
            Directory.Move(prefix, completedPrefix)

            let pendingContext =
                (reopened.GameContexts :> IGameContexts)
                    .Save(
                        pendingWorkspace,
                        0L,
                        { Path = pendingGame
                          Proton = Some pendingProton }
                    )
                |> wait
                |> result

            let pendingDeployment = reopened.Deployments.Read pendingProfile |> wait |> result

            let firstRun =
                restarted.Read(pendingWorkspace, pendingProfile, false, CancellationToken.None)
                |> wait

            Directory.Move(completedPrefix, prefix)

            let refreshed =
                (reopened.GameContexts :> IGameContexts)
                    .Refresh(pendingWorkspace, pendingContext.Revision)
                |> wait
                |> result

            let continued =
                restarted.Read(pendingWorkspace, pendingProfile, false, CancellationToken.None)
                |> wait

            let afterRefresh = reopened.Deployments.Read pendingProfile |> wait |> result

            check
                writer
                "failedPrefixChoiceSurvivesSteamFirstRunRefresh"
                (pendingContext.Binding
                 |> Option.exists (fun binding ->
                     binding.Proton = Some pendingProton
                     && binding.NeedsCheck
                     && not binding.Evidence.Valid)
                 && firstRun.Phase = SkyrimSetupPhase.Unavailable
                 && firstRun.Detail = "Start Skyrim once through Steam. Close it, then select Refresh."
                 && pendingDeployment.ActiveGeneration.IsNone
                 && pendingDeployment.PendingReceipt.IsNone
                 && (refreshed.Binding
                     |> Option.exists (fun binding ->
                         binding.Proton = Some pendingProton
                         && not binding.NeedsCheck
                         && binding.Evidence.Valid))
                 && continued.Phase = SkyrimSetupPhase.NeedsConsent
                 && continued.CanStart
                 && afterRefresh.ActiveGeneration.IsNone
                 && afterRefresh.PendingReceipt.IsNone)

        writer.WriteEndObject()
