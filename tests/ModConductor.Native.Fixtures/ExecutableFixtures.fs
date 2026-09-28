namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.Executables
open ModConductor.Engine

module ExecutableFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private read (api: IExecutables) workspace id =
        api.Read(workspace, id) |> wait |> result

    let private until (api: IExecutables) workspace id predicate =
        let deadline = DateTime.UtcNow.AddSeconds 30.0
        let mutable value = read api workspace id

        while not (predicate value) && DateTime.UtcNow < deadline do
            Thread.Sleep 25
            value <- read api workspace id

        if not (predicate value) then
            invalidOp (
                "The executable run did not reach its expected phase: "
                + string value.Phase
                + " "
                + string value.Problem
            )

        value

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "executables")).FullName
        let deployment = DeploymentFixtureData.create (Path.Combine(area, "deployment"))
        let state = deployment.State
        let workspace = Guid.NewGuid()
        let path = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let controls = Directory.CreateDirectory(Path.Combine(area, "roundtrip Ω")).FullName
        let executable, prefix = ExecutableChild.invocation ()

        let check (name: string) condition =
            writer.WriteBoolean(name, condition)

            if not condition then
                invalidOp ("Executable fixture failed: " + name)

        let previousSet = Environment.GetEnvironmentVariable "MC024_SET"
        let previousRemove = Environment.GetEnvironmentVariable "MC024_REMOVE"
        Environment.SetEnvironmentVariable("MC024_SET", "parent")
        Environment.SetEnvironmentVariable("MC024_REMOVE", "parent-remove")

        try
            let settings =
                { Executable = executable
                  Arguments =
                    prefix
                    @ [ "--executable-child"
                        controls
                        "roundtrip"
                        "two words"
                        "雪 Ω"
                        ""
                        "end\\"
                        "say \"hello\""
                        "$(literal); & | $HOME" ]
                  WorkingDirectory = controls
                  Environment =
                    [ "MC024_SET", Some "child Ω"; "MC024_REMOVE", None; "MC024_EMPTY", Some "" ] }

            let mutable retainedRequest = Unchecked.defaultof<RunRequest>
            let mutable retainedPreset = Unchecked.defaultof<ExecutablePreset>
            let mutable ownerLost = Guid.Empty
            let ownerArea = Directory.CreateDirectory(Path.Combine(area, "owner-loss")).FullName

            do
                use store = new OperationStore(state)

                let _activated =
                    DeploymentFixtureData.start
                        store
                        deployment
                        (Guid.NewGuid())
                        0L
                        deployment.First
                    |> DeploymentFixtureData.apply store

                let activeId = (DeploymentFixtureData.context store).Active

                let deployed () =
                    (DeploymentFixtureData.context store).Active = activeId
                    && DeploymentFixtureData.contents deployment "shared.txt" = "shared"
                    && DeploymentFixtureData.contents deployment "outputs/save.dat" = "save-one"

                let ws = store.Workspaces :> IWorkspaceState

                let created =
                    ws.Create(workspace, "Executable fixtures", StorageWorker.select path)
                    |> wait
                    |> result

                let profile =
                    { Id = Guid.NewGuid()
                      Name = "Everyday" }

                let withProfile =
                    ws.Edit(workspace, created.Workspace.Revision, ProfileEdit.Create profile)
                    |> wait
                    |> result

                let selected =
                    ws.Edit(
                        workspace,
                        withProfile.Workspace.Revision,
                        ProfileEdit.Select profile.Id
                    )
                    |> wait
                    |> result

                let api = store.Executables
                let desktop = DesktopService(store.Workspaces, api)

                let canHandOff () =
                    desktop
                        .CheckUpdateHandoff(
                            ModConductor.Protocol.V1.UpdateHandoffRequest(),
                            Unchecked.defaultof<_>
                        )
                        .GetAwaiter()
                        .GetResult()
                        .Ready

                let preset =
                    api.Save
                        { Id = Guid.NewGuid()
                          WorkspaceId = workspace
                          Revision = 0L
                          Name = "Texture audit Ω"
                          Launch = settings }
                    |> wait
                    |> result

                retainedPreset <- preset

                check
                    "presetSaved"
                    (preset.Revision = 1L
                     && (api.List(workspace, None) |> wait |> result).Presets = [ preset ])

                let request =
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      WorkspaceRevision = selected.Workspace.Revision
                      PresetId = preset.Id
                      PresetRevision = preset.Revision }

                retainedRequest <- request
                api.Begin request |> wait |> result |> ignore

                let finished =
                    until api workspace request.Id (fun run -> run.Phase = RunPhase.Finished)

                use json =
                    JsonDocument.Parse(File.ReadAllText(Path.Combine(controls, "roundtrip.json")))

                let data = json.RootElement

                let args =
                    data.GetProperty("arguments").EnumerateArray()
                    |> Seq.map _.GetString()
                    |> Seq.toList

                check
                    "argumentVectorPreserved"
                    (args = (settings.Arguments |> List.skip (prefix.Length + 3)))

                check
                    "workingDirectoryPreserved"
                    (data.GetProperty("directory").GetString() = controls)

                check
                    "environmentIsolated"
                    (data.GetProperty("MC024_SET").GetString() = "child Ω"
                     && not (data.GetProperty("MC024_REMOVE_present").GetBoolean())
                     && data.GetProperty("MC024_EMPTY_present").GetBoolean()
                     && data.GetProperty("MC024_EMPTY").GetString() = ""
                     && Environment.GetEnvironmentVariable("MC024_SET") = "parent"
                     && Environment.GetEnvironmentVariable("MC024_REMOVE") = "parent-remove")

                check "independentNullStreams" (data.GetProperty("stdin").GetInt32() = -1)
                check "rootExitDoesNotUndeploy" (deployed ())

                check
                    "rootExitRecorded"
                    (finished.RootExitCode = Some 0
                     && finished.ActiveProcesses = Some 0
                     && finished.ProfileId = Some profile.Id)

                let replay = api.Begin request |> wait |> result

                check
                    "launchReplayDoesNotSpawn"
                    (replay.Source = RunSource.Preset(request, preset)
                     && replay.Phase = RunPhase.Finished
                     && File.ReadAllText(Path.Combine(controls, "roundtrip.count")) = "1")

                check
                    "stalePresetSaveRefused"
                    (api.Save
                        { preset with
                            Revision = 0L
                            Name = "stale" }
                     |> wait = Error ExecutableError.StaleRevision)

                let renamed = api.Save { preset with Name = "Renamed audit" } |> wait |> result
                retainedPreset <- renamed
                let found = api.ReadPreset(workspace, preset.Id) |> wait |> result
                let listed = api.List(workspace, None) |> wait |> result

                check
                    "presetEditKeepsCapturedRun"
                    (found = renamed
                     && (read api workspace request.Id).Source = RunSource.Preset(request, preset))

                check
                    "presetPageReportsLatestRun"
                    (listed.LatestRuns
                     |> List.exists (fun value ->
                         value.Id = request.Id && value.Source = RunSource.Preset(request, preset)))

                let chain = Directory.CreateDirectory(Path.Combine(area, "chain")).FullName

                let chainPreset =
                    api.Save
                        { preset with
                            Id = Guid.NewGuid()
                            Revision = 0L
                            Name = "Child chain"
                            Launch =
                                { settings with
                                    Arguments = prefix @ [ "--executable-child"; chain; "parent" ] } }
                    |> wait
                    |> result

                let chainRequest =
                    { request with
                        Id = Guid.NewGuid()
                        PresetId = chainPreset.Id
                        PresetRevision = chainPreset.Revision }

                api.Begin chainRequest |> wait |> result |> ignore

                let waiting =
                    until api workspace chainRequest.Id (fun run ->
                        run.Phase = RunPhase.WaitingForChildren)

                check "updateHandoffBlockedByManagedLaunch" (not (canHandOff ()))

                check
                    "earlyRootExitKeepsChildObservation"
                    (waiting.RootExitCode = Some 0
                     && waiting.ActiveProcesses |> Option.exists ((<) 0))

                use changedTimeout = new CancellationTokenSource(TimeSpan.FromSeconds 5.)

                let changed =
                    api.WaitForChange(
                        workspace,
                        chainRequest.Id,
                        waiting.Revision,
                        changedTimeout.Token
                    )

                Thread.Sleep 150
                check "idleExecutableWatchWaitsForChange" (not changed.IsCompleted)

                File.WriteAllText(Path.Combine(chain, "grandchild-now"), "continue")
                ExecutableChild.waitFile (Path.Combine(chain, "grandchild.started"))
                changed.GetAwaiter().GetResult()
                check "childProcessChangeWakesExecutableWatch" changed.IsCompletedSuccessfully

                let grandchildren =
                    until api workspace chainRequest.Id (fun run ->
                        run.ActiveProcesses |> Option.exists (fun count -> count >= 2))

                check
                    "grandchildAfterRootExitObserved"
                    (grandchildren.Phase = RunPhase.WaitingForChildren)

                File.WriteAllText(Path.Combine(chain, "finish"), "complete")

                let ended =
                    until api workspace chainRequest.Id (fun run -> run.Phase = RunPhase.Finished)

                check "updateHandoffReadyAfterManagedLaunch" (canHandOff ())

                check
                    "observedScopeCompletion"
                    (ended.RootExitCode = Some 0 && ended.ActiveProcesses = Some 0)

                let detachedArea =
                    Directory.CreateDirectory(Path.Combine(area, "detached")).FullName

                let detachedPreset =
                    api.Save
                        { preset with
                            Id = Guid.NewGuid()
                            Revision = 0L
                            Name = "Detached"
                            Launch =
                                { settings with
                                    Arguments =
                                        prefix @ [ "--executable-child"; detachedArea; "waiter" ] } }
                    |> wait
                    |> result

                let detachedRequest =
                    { request with
                        Id = Guid.NewGuid()
                        PresetId = detachedPreset.Id
                        PresetRevision = detachedPreset.Revision }

                api.Begin detachedRequest |> wait |> result |> ignore
                ExecutableChild.waitFile (Path.Combine(detachedArea, "waiter.started"))
                let detached = api.StopWaiting(workspace, detachedRequest.Id) |> wait |> result

                check
                    "stopWaitingDoesNotKill"
                    (detached.Phase = RunPhase.Detached
                     && not (File.Exists(Path.Combine(detachedArea, "waiter.finished"))))

                File.WriteAllText(Path.Combine(detachedArea, "finish"), "complete")
                ExecutableChild.waitFile (Path.Combine(detachedArea, "waiter.finished"))
                check "detachDoesNotUndeploy" (deployed ())

                check
                    "detachedStreamsRemainIndependent"
                    (File.ReadAllText(Path.Combine(detachedArea, "waiter.finished")) = "-1")

                let missing =
                    api.Save
                        { preset with
                            Id = Guid.NewGuid()
                            Revision = 0L
                            Name = "Missing"
                            Launch =
                                { settings with
                                    Executable = Path.Combine(area, "not-an-executable") } }
                    |> wait
                    |> result

                let missingRequest =
                    { request with
                        Id = Guid.NewGuid()
                        PresetId = missing.Id
                        PresetRevision = missing.Revision }

                api.Begin missingRequest |> wait |> result |> ignore

                let failed =
                    until api workspace missingRequest.Id (fun run -> run.Phase = RunPhase.Failed)

                check
                    "launchFailureVisible"
                    (Option.isSome failed.Problem && Option.isNone failed.ProcessId)

                let ownerPreset =
                    api.Save
                        { preset with
                            Id = Guid.NewGuid()
                            Revision = 0L
                            Name = "Owner loss"
                            Launch =
                                { settings with
                                    Arguments =
                                        prefix @ [ "--executable-child"; ownerArea; "waiter" ] } }
                    |> wait
                    |> result

                let ownerRequest =
                    { request with
                        Id = Guid.NewGuid()
                        PresetId = ownerPreset.Id
                        PresetRevision = ownerPreset.Revision }

                ownerLost <- ownerRequest.Id
                api.Begin ownerRequest |> wait |> result |> ignore
                ExecutableChild.waitFile (Path.Combine(ownerArea, "waiter.started"))

                let running =
                    until api workspace ownerLost (fun run ->
                        run.Phase = RunPhase.Running && Option.isSome run.ProcessId)

                check "ownerHasLiveRoot" (Option.isSome running.ProcessId)

            File.WriteAllText(Path.Combine(ownerArea, "finish"), "complete after owner closed")
            ExecutableChild.waitFile (Path.Combine(ownerArea, "waiter.finished"))

            check
                "ownerCloseDoesNotKillOrBreakStreams"
                (File.ReadAllText(Path.Combine(ownerArea, "waiter.finished")) = "-1")

            use reopened = new OperationStore(state)

            check
                "ownerCloseDoesNotUndeploy"
                ((DeploymentFixtureData.context reopened).Active = Some deployment.First.Id
                 && DeploymentFixtureData.contents deployment "shared.txt" = "shared"
                 && DeploymentFixtureData.contents deployment "outputs/save.dat" = "save-one")

            let api = reopened.Executables
            let old = read api workspace ownerLost
            check "restartReportsUnknownTracking" (old.Phase = RunPhase.TrackingUnavailable)
            let replay = api.Begin retainedRequest |> wait |> result

            check
                "restartReplayKeepsHistoricalResult"
                (replay.Phase = RunPhase.Finished
                 && File.ReadAllText(Path.Combine(controls, "roundtrip.count")) = "1")

            let presets = api.List(workspace, None) |> wait |> result
            check "presetSurvivesRestart" (presets.Presets |> List.contains retainedPreset)
            let historical = api.Recent(workspace, None) |> wait |> result |> fst

            check
                "runHistorySurvivesRestart"
                (historical |> List.exists (fun row -> row.Id = ownerLost))
        finally
            Environment.SetEnvironmentVariable("MC024_SET", previousSet)
            Environment.SetEnvironmentVariable("MC024_REMOVE", previousRemove)

        GenerationCleanup.normalize area
