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
        let mutable skseReads = 0
        let mutable enbCancels = 0
        let mutable runCalls = 0

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
              LatestRunId = None
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

        member _.SkseReads = skseReads
        member _.EnbCancels = enbCancels
        member _.RunCalls = runCalls

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
                fun _ _ _ _ _ ->
                    enb <-
                        { enb with
                            Phase = EnbPhase.Ready
                            Status = "Lean ENB is ready" }

                    Task.FromResult enb
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
                fun _ _ ->
                    runCalls <- runCalls + 1
                    output <- ModConductor.Fnis.FnisOutputPhase.Current
                    Task.FromResult(Ok(inspection ()))
              CancelFnisRun = fun _ _ -> Task.FromResult(Ok(inspection ()))
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

    let private completeFlow (coordinator: SkyrimSetupCoordinator) workspace profile existing =
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

        let stale = coordinator.Continue(workspace, profile, CancellationToken.None) |> wait
        let ready = coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        let completed =
            coordinator.Continue(workspace, profile, CancellationToken.None) |> wait

        planned, started, afterSkse, waiting, afterEnb, stale, ready, completed

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
            let coordinator = SkyrimSetupCoordinator(store, workflow.Dependencies)
            let before = store.Deployments.Read profile |> wait |> result

            let planned, started, afterSkse, waiting, afterEnb, stale, ready, completed =
                completeFlow coordinator workspace profile false

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
                (afterEnb.Phase = SkyrimSetupPhase.SettingUpFnis
                 && stale.Phase = SkyrimSetupPhase.FnisStale)

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

            let cancelled =
                coordinator.Cancel(workspace, profile, CancellationToken.None) |> wait

            check
                writer
                "combinedCancelOwnsEnbWait"
                (cancelWaiting.Phase = SkyrimSetupPhase.WaitingForEnbArchive
                 && cancelled.Phase = SkyrimSetupPhase.Cancelled
                 && workflow.EnbCancels = 1)

        use reopened = new OperationStore(state)

        let context =
            (reopened.GameContexts :> IGameContexts).Read workspace |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, context.Revision)
        |> wait
        |> result
        |> ignore

        let restarted = SkyrimSetupCoordinator(reopened, workflow.Dependencies)

        let cancelledAfterRestart =
            restarted.Read(workspace, profile, false, CancellationToken.None) |> wait

        check
            writer
            "combinedCancellationSurvivesRestart"
            (cancelledAfterRestart.Phase = SkyrimSetupPhase.Cancelled)

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

        writer.WriteEndObject()
