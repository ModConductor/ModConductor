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

    let private stageRolloverEvidence (writer: Utf8JsonWriter) =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let existingMod, existingVersion = Guid.NewGuid(), Guid.NewGuid()
        let childMod, childVersion = Guid.NewGuid(), Guid.NewGuid()
        let companionMod, companionVersion = Guid.NewGuid(), Guid.NewGuid()
        let unrelatedMod, unrelatedVersion = Guid.NewGuid(), Guid.NewGuid()
        let beforeGeneration, afterGeneration = Guid.NewGuid(), Guid.NewGuid()
        let beforeDeployment = String.replicate 64 "a"
        let expectedDeployment = String.replicate 64 "b"
        let extraDeployment = String.replicate 64 "c"

        let sources: SourceStamp =
            { WorkspaceId = workspace
              ProfileId = profile
              SelectionRevision = 7L
              ContextRevision = 11L
              ExclusionRevision = 13L
              OutputRevision = 17L
              Versions = [ existingMod, Some existingVersion ]
              Deployment = Some beforeDeployment }

        let before =
            { Sources = sources
              DeploymentRevision = 23L
              ActiveGeneration = Some beforeGeneration }

        let expectedChildDeployment (versions: (Guid * Guid) list) (generation: Guid option) =
            { Sources =
                { sources with
                    SelectionRevision = sources.SelectionRevision + int64 versions.Length + 1L
                    Versions =
                        sources.Versions
                        @ (versions |> List.map (fun (modId, versionId) -> modId, Some versionId))
                    Deployment = Some expectedDeployment }
              DeploymentRevision = before.DeploymentRevision + 1L
              ActiveGeneration = generation }

        let deploymentBefore =
            { before with
                Sources = { sources with Deployment = None }
                DeploymentRevision = 0L
                ActiveGeneration = None }

        let deploymentAfter =
            { deploymentBefore with
                Sources =
                    { deploymentBefore.Sources with
                        Deployment = Some expectedDeployment }
                DeploymentRevision = deploymentBefore.DeploymentRevision + 1L
                ActiveGeneration = Some afterGeneration }

        let skseAfter =
            expectedChildDeployment [ childMod, childVersion ] (Some afterGeneration)

        let enbAfter =
            expectedChildDeployment
                [ childMod, childVersion; companionMod, companionVersion ]
                (Some afterGeneration)

        let fnisInstallAfter =
            expectedChildDeployment [ childMod, childVersion ] (Some afterGeneration)

        let fnisRunAfter =
            { before with
                Sources =
                    { sources with
                        SelectionRevision = sources.SelectionRevision + 2L
                        Versions = sources.Versions @ [ childMod, Some childVersion ] } }

        let recorded snapshot =
            SkyrimSetupPlan.token workspace profile SetupSelection.none sources.ContextRevision snapshot
            |> SkyrimSetupPlan.snapshot workspace profile SetupSelection.none sources.ContextRevision
            |> Option.defaultWith (fun () -> failwith "The Skyrim setup plan snapshot was lost.")

        let accepted =
            [ SkyrimSetupPlan.permits
                  (recorded deploymentBefore)
                  deploymentAfter
                  (SkyrimSetupStageChange.Deployment afterGeneration)
              SkyrimSetupPlan.permits
                  (recorded before)
                  skseAfter
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  enbAfter
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion; companionMod, companionVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  fnisInstallAfter
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  fnisRunAfter
                  (SkyrimSetupStageChange.FnisOutput(childMod, childVersion)) ]

        let withExtraDeployment (snapshot: SkyrimSetupPlanSnapshot) =
            { snapshot with
                DeploymentRevision = snapshot.DeploymentRevision + 1L
                Sources =
                    { snapshot.Sources with
                        Deployment = Some extraDeployment } }

        let withUnrelatedVersion (snapshot: SkyrimSetupPlanSnapshot) =
            { snapshot with
                Sources =
                    { snapshot.Sources with
                        SelectionRevision = snapshot.Sources.SelectionRevision + 1L
                        Versions =
                            snapshot.Sources.Versions @ [ unrelatedMod, Some unrelatedVersion ] } }

        let withChangedContext snapshot =
            let extra = withExtraDeployment snapshot

            { extra with
                Sources =
                    { extra.Sources with
                        ContextRevision = extra.Sources.ContextRevision + 1L } }

        let rejected =
            [ SkyrimSetupPlan.permits
                  (recorded deploymentBefore)
                  (withExtraDeployment deploymentAfter)
                  (SkyrimSetupStageChange.Deployment afterGeneration)
              SkyrimSetupPlan.permits
                  (recorded before)
                  (withExtraDeployment (withUnrelatedVersion skseAfter))
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  (withChangedContext enbAfter)
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion; companionMod, companionVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  { withExtraDeployment fnisInstallAfter with
                      ActiveGeneration = Some(Guid.NewGuid()) }
                  (SkyrimSetupStageChange.ComponentDeployment(
                      afterGeneration,
                      [ childMod, childVersion ]
                  ))
              SkyrimSetupPlan.permits
                  (recorded before)
                  (withExtraDeployment (withUnrelatedVersion fnisRunAfter))
                  (SkyrimSetupStageChange.FnisOutput(childMod, childVersion)) ]

        check writer "expectedChildOnlyDeltasAdvanceEveryRollover" (accepted |> List.forall id)

        check
            writer
            "combinedChildAndUnrelatedDeltasInvalidateEveryRollover"
            (rejected |> List.forall not)

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
        stageRolloverEvidence writer

        let state = Directory.CreateDirectory(Path.Combine(area, "skyrim-setup-state")).FullName
        use store = new OperationStore(state)
        let workspace, profile, _ = createWorkspace store area "selected" true
        let workflow = WorkflowState()
        use coordinator = new SkyrimSetupCoordinator(store, workflow.Dependencies)
        let noChoice = SetupSelection.none
        let initial = coordinator.Read(workspace, profile, noChoice, CancellationToken.None) |> wait
        let before = store.Deployments.Read profile |> wait |> result

        check writer "noDefaultComponentChoice" (initial.Changes.IsEmpty && not initial.CanStart)
        check writer "noDefaultDeployment" (before.ActiveGeneration.IsNone)
        check writer "noDefaultIntent" ((store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone)

        let cancelledBeforeApply = coordinator.Cancel(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "cancelBeforeApplyDoesNotWrite"
            (not cancelledBeforeApply.ConsentRecorded
             && (store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone
             && (store.Deployments.Read profile |> wait |> result).ActiveGeneration.IsNone)

        let enbWithoutArchive =
            { noChoice with Enb = SetupAction.Install }

        let enbBlocked =
            coordinator.Read(workspace, profile, enbWithoutArchive, CancellationToken.None) |> wait

        check writer "enbNeedsArchiveBeforeApply" (not enbBlocked.CanStart)
        check writer "enbOnlyPlan" (enbBlocked.Changes |> List.exists (fun change -> change.Title = "ENBSeries"))
        check writer "enbDoesNotSelectSkseOrFnis" (enbBlocked.Changes |> List.forall (fun change -> change.Title <> "SKSE" && change.Title <> "FNIS"))

        let enbWithArchive =
            { enbWithoutArchive with EnbArchive = Some "downloaded-enb.zip" }

        let enbPlan = coordinator.Read(workspace, profile, enbWithArchive, CancellationToken.None) |> wait
        check writer "enbArchiveEnablesReview" enbPlan.CanStart

        let fnisOnly = { noChoice with Fnis = SetupAction.Install }
        let fnisPlan = coordinator.Read(workspace, profile, fnisOnly, CancellationToken.None) |> wait

        check
            writer
            "fnisOnlyPlan"
            (fnisPlan.CanStart
             && (fnisPlan.Changes |> List.map _.Title) = [ "FNIS"; "Initial profile deployment" ])

        let combined =
            { Skse = SetupAction.Install
              Enb = SetupAction.Install
              Fnis = SetupAction.Install
              EnbArchive = Some "downloaded-enb.zip" }

        let combinedPlan = coordinator.Read(workspace, profile, combined, CancellationToken.None) |> wait

        check
            writer
            "combinedPlanNamesOnlySelectedComponents"
            (combinedPlan.CanStart
             && (combinedPlan.Changes |> List.filter (fun item -> not item.Supporting) |> List.map _.Title)
                = [ "SKSE"; "ENBSeries"; "FNIS" ])

        let skseOnly = { noChoice with Skse = SetupAction.Install }
        let sksePlan = coordinator.Read(workspace, profile, skseOnly, CancellationToken.None) |> wait
        check writer "skseOnlyPlan" (sksePlan.CanStart && (sksePlan.Changes |> List.map _.Title = [ "SKSE"; "Initial profile deployment" ]))

        let staleSelection =
            coordinator.Start(workspace, profile, enbWithoutArchive, sksePlan.PlanToken, true, CancellationToken.None)
            |> wait

        check writer "selectionBoundToPlan" (not staleSelection.ConsentRecorded)
        check writer "staleSelectionDoesNotWrite" ((store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone)

        let unconfirmed =
            coordinator.Start(workspace, profile, skseOnly, sksePlan.PlanToken, false, CancellationToken.None)
            |> wait

        check writer "unconfirmedPlanDoesNotWrite" (not unconfirmed.ConsentRecorded && (store.SkyrimSetups.Read(workspace, profile) |> wait).IsNone)

        let started =
            coordinator.Start(workspace, profile, skseOnly, sksePlan.PlanToken, true, CancellationToken.None)
            |> wait

        let retained = store.SkyrimSetups.Read(workspace, profile) |> wait
        check writer "confirmedChoiceRetained" (retained |> Option.exists (fun item -> item.Selection = skseOnly))
        check writer "unselectedComponentsNotStarted" (started.Selection.Enb = SetupAction.Unchanged && started.Selection.Fnis = SetupAction.Unchanged)

        use resumed = new SkyrimSetupCoordinator(store, workflow.Dependencies)
        let restored = resumed.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "confirmedChoiceSurvivesCoordinatorRestart"
            (restored.ConsentRecorded && restored.Selection = skseOnly)

        let _ = resumed.Continue(workspace, profile, CancellationToken.None) |> wait

        check
            writer
            "selectedSkseOnlyExecutes"
            (workflow.SkseStarts = 1 && workflow.EnbSelections = 0 && workflow.FnisInstalls = 0)

        use reopened = new OperationStore(state)
        use afterRestart = new SkyrimSetupCoordinator(reopened, workflow.Dependencies)
        let retainedAfterRestart = afterRestart.Read(workspace, profile, noChoice, CancellationToken.None) |> wait

        check
            writer
            "confirmedChoiceSurvivesStoreRestart"
            (retainedAfterRestart.Selection = skseOnly)

        let execute name selection expected =
            let freshWorkspace, freshProfile, _ = createWorkspace store area name true
            let state = WorkflowState()
            use owner = new SkyrimSetupCoordinator(store, state.Dependencies)
            let plan = owner.Read(freshWorkspace, freshProfile, selection, CancellationToken.None) |> wait
            let initial = owner.Start(freshWorkspace, freshProfile, selection, plan.PlanToken, true, CancellationToken.None) |> wait

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
             && (enbOnlyIntent |> Option.exists (fun item -> item.Selection = enbWithArchive)))

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

        writer.WriteEndObject()
