namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Diagnostics
open System.Text.Json
open System.Threading
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.Deployment
open ModConductor.Executables
open ModConductor.Persistence

module GameLaunchFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path
    let private quote (text: string) = "'" + text.Replace("'", "'\\''") + "'"

    let private until (api: IExecutables) workspace id predicate =
        let deadline = DateTime.UtcNow.AddSeconds 30.
        let mutable value = api.Read(workspace, id) |> wait |> result

        while not (predicate value) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            value <- api.Read(workspace, id) |> wait |> result

        if not (predicate value) then
            invalidOp (
                "Game launch did not finish: " + string value.Phase + " " + string value.Problem
            )

        value

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("gameLaunch")

        if not (OperatingSystem.IsLinux()) then
            writer.WriteString("status", "Windows verification deferred under MC-D-032")
        else
            let check (name: string) condition =
                writer.WriteBoolean(name, condition)

                if not condition then
                    invalidOp ("Game launch fixture failed: " + name)

            let area = Directory.CreateDirectory(Path.Combine(primary, "game-launch")).FullName

            let workspacePath =
                Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

            let controls = Directory.CreateDirectory(Path.Combine(area, "controls Ω")).FullName
            let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))
            let target = Path.Combine(game, "Data", "Marker.TXT")
            File.WriteAllText(target, "original base")

            let source =
                Directory.CreateDirectory(Path.Combine(workspacePath, "Managed")).FullName

            File.WriteAllText(Path.Combine(source, "marker.txt"), "intended managed bytes Ω")
            let executable, prefix = ExecutableChild.invocation ()
            let launcher = Path.Combine(proton.RuntimeDirectory, "proton")

            let script =
                "#!/bin/sh\nexec "
                + String.concat
                    " "
                    (List.map quote (executable :: prefix @ [ "--game-load"; controls ]))
                + " \"$2\"\n"

            File.WriteAllText(launcher, script)

            File.SetUnixFileMode(
                launcher,
                UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
            )

            let manifest = Path.Combine(proton.RuntimeDirectory, "toolmanifest.vdf")
            File.WriteAllText(manifest, "manifest { version 2 commandline \"/proton %verb%\" }")
            File.WriteAllText(Path.Combine(controls, "finish"), "finish")

            let workspace, profile, emptyProfile, modId, version =
                Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

            let statePath = Path.Combine(area, "state")
            let mutable retained = Guid.Empty

            do
                use store = new OperationStore(statePath)
                let ws = store.Workspaces :> IWorkspaceState

                let created =
                    ws.Create(workspace, "Game launch", StorageWorker.select workspacePath)
                    |> wait
                    |> result

                ws.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "Selected mods" }
                )
                |> wait
                |> result
                |> ignore

                let library = store.ModLibrary :> IModLibrary

                let registered =
                    library.Register(
                        workspace,
                        modId,
                        { Name = "Managed"
                          Version = "1"
                          Notes = ""
                          Comment = ""
                          Source = ""
                          Categories = [] },
                        Registration.Directory(ModKind.Regular, path "Managed")
                    )
                    |> wait
                    |> result

                library.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
                let selection = InventoryObservations.read store profile

                (store.ModSelection :> IModSelection)
                    .Change(
                        profile,
                        selection.SelectionRevision,
                        [ modId ],
                        SelectionEdit.Enable true
                    )
                |> wait
                |> result
                |> ignore

                (store.GameContexts :> IGameContexts)
                    .Save(workspace, 0L, { Path = game; Proton = Some proton })
                |> wait
                |> result
                |> ignore

                let checkedContext =
                    (store.GameContexts :> IGameContexts).Read workspace |> wait |> result

                GameLaunchProcessFixture.observe writer area checkedContext.Binding.Value.Evidence
                let api = store.GameLaunching

                let request profile =
                    let current = ws.Read(workspace, None) |> wait |> result
                    let launch = api.Read(workspace, profile) |> wait |> result

                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      WorkspaceRevision = current.Workspace.Revision
                      ProfileId = profile
                      ContextRevision = launch.ContextRevision
                      SourceToken = launch.SourceToken }

                let play request = api.Begin request |> wait |> result

                let finished id =
                    until store.Executables workspace id (fun value ->
                        value.Phase = RunPhase.Finished || value.Phase = RunPhase.Failed)

                let read () =
                    use data =
                        JsonDocument.Parse(File.ReadAllText(Path.Combine(controls, "read.json")))

                    data.RootElement.GetProperty("content").GetString()

                let first = request profile
                let started = play first
                let run = finished started.Id
                retained <- run.Id

                let capture =
                    match run.Source with
                    | RunSource.Game game -> game
                    | _ -> invalidOp "No captured game origin"

                check
                    "linuxNativeChildReadsManagedWinner"
                    (run.RootExitCode = Some 0 && read () = "intended managed bytes Ω")

                let active = store.Deployments.Read profile |> wait |> result

                check
                    "runPinsCompletedDeployment"
                    (run.ProcessId.IsSome
                     && run.Scope.IsSome
                     && capture.Files.Value.GenerationId = active.ActiveGeneration.Value
                     && capture.Files.Value.ReceiptId = run.Id
                     && capture.Files.Value.Fingerprint = active.Active.Value.Fingerprint)

                GameLaunchCancellationFixture.observe writer capture

                check
                    "normalExitLeavesDeployment"
                    (File.ReadAllText target = "intended managed bytes Ω")

                let replay = play first

                check
                    "completedReplayDoesNotSpawn"
                    (replay.Id = run.Id && File.ReadAllText(Path.Combine(controls, "count")) = "1")

                let stale = request profile
                let selected = InventoryObservations.read store profile

                (store.ModSelection :> IModSelection)
                    .Change(
                        profile,
                        selected.SelectionRevision,
                        [ modId ],
                        SelectionEdit.Enable false
                    )
                |> wait
                |> result
                |> ignore

                check
                    "changedSelectionRejectsOldRequest"
                    (api.Begin stale |> wait = Error ExecutableError.StaleRevision)

                check
                    "staleRequestHasNoRunOrEffects"
                    (store.Executables.Read(workspace, stale.Id) |> wait = Error
                        ExecutableError.NotFound
                     && File.ReadAllText target = "intended managed bytes Ω")

                let selected = InventoryObservations.read store profile

                (store.ModSelection :> IModSelection)
                    .Change(
                        profile,
                        selected.SelectionRevision,
                        [ modId ],
                        SelectionEdit.Enable true
                    )
                |> wait
                |> result
                |> ignore

                File.WriteAllText(manifest, "manifest { version 2 commandline \"/unsupported\" }")
                let sameSession = play (request profile) |> fun value -> finished value.Id

                check
                    "launchReusesSessionDescriptor"
                    (sameSession.RootExitCode = Some 0 && read () = "intended managed bytes Ω")

                let launcherBackup = launcher + ".fixture-backup"
                File.Move(launcher, launcherBackup)

                try
                    let failedRequest = request profile
                    let failed = play failedRequest |> fun value -> finished value.Id

                    let captured =
                        match failed.Source with
                        | RunSource.Game game -> game
                        | _ -> invalidOp "No game origin"

                    check
                        "runtimeFailureKeepsAppliedFilesAndReceipt"
                        (failed.Phase = RunPhase.Finished
                         && failed.RootExitCode.IsSome
                         && failed.RootExitCode <> Some 0
                         && captured.Files.IsSome
                         && File.ReadAllText target = "intended managed bytes Ω")

                    check
                        "failedReplayDoesNotLaunchAgain"
                        ((play failedRequest).Revision = failed.Revision)
                finally
                    File.Move(launcherBackup, launcher)

                File.Delete(Path.Combine(controls, "finish"))
                File.Delete(Path.Combine(controls, "read.json"))
                let forced = play (request profile)
                ExecutableChild.waitFile (Path.Combine(controls, "read.json"))

                let running =
                    until store.Executables workspace forced.Id (fun value ->
                        value.ProcessId.IsSome)

                use ownedChild = Process.GetProcessById running.ProcessId.Value
                ownedChild.Kill(false)
                File.WriteAllText(Path.Combine(controls, "finish"), "finish")
                let terminated = finished forced.Id

                check
                    "externalExitLeavesAppliedFiles"
                    (terminated.RootExitCode.IsSome
                     && terminated.RootExitCode <> Some 0
                     && File.ReadAllText target = "intended managed bytes Ω")

                File.WriteAllText(Path.Combine(controls, "finish"), "finish")
                let current = ws.Read(workspace, None) |> wait |> result

                let changed =
                    ws.Edit(
                        workspace,
                        current.Workspace.Revision,
                        ProfileEdit.Create { Id = emptyProfile; Name = "Empty" }
                    )
                    |> wait
                    |> result

                ws.Edit(workspace, changed.Workspace.Revision, ProfileEdit.Select emptyProfile)
                |> wait
                |> result
                |> ignore

                let empty = play (request emptyProfile) |> fun value -> finished value.Id

                check
                    "emptySelectedProfileAppliesBase"
                    (empty.RootExitCode = Some 0
                     && read () = "original base"
                     && empty.ProfileId = Some emptyProfile)

                check "oldRunKeepsItsPins" ((play first).Source = run.Source)
                File.Delete(Path.Combine(controls, "finish"))
                File.Delete(Path.Combine(controls, "read.json"))
                let waiting = play (request emptyProfile)
                ExecutableChild.waitFile (Path.Combine(controls, "read.json"))

                let detached =
                    store.Executables.StopWaiting(workspace, waiting.Id) |> wait |> result

                check
                    "detachLeavesFilesAndChild"
                    (detached.Phase = RunPhase.Detached && File.ReadAllText target = "original base")

                File.WriteAllText(Path.Combine(controls, "finish"), "finish")
                store.CloseExecutables() |> wait

                check
                    "sourceAndOldVersionPreserved"
                    (File.ReadAllText(Path.Combine(source, "marker.txt")) = "intended managed bytes Ω")

            do
                use store = new OperationStore(statePath)
                let old = store.Executables.Read(workspace, retained) |> wait |> result

                check
                    "restartRetainsCapturedGameRun"
                    (old.Phase = RunPhase.Finished && old.ProfileId = Some profile)

                let oldContext =
                    (store.GameContexts :> IGameContexts).Read workspace |> wait |> result

                check "newOwnerRequiresStartupCheck" oldContext.Binding.Value.NeedsCheck

                (store.GameContexts :> IGameContexts).Refresh(workspace, oldContext.Revision)
                |> wait
                |> result
                |> ignore

                let state = store.GameLaunching.Read(workspace, emptyProfile) |> wait |> result
                check "refreshReplacesLaunchDescriptor" state.Problem.IsSome

            GenerationCleanup.normalize area

            writer.WriteString(
                "scope",
                "Owned Linux native file consumer via fixture dispatch; not actual Proton or Skyrim evidence"
            )

        writer.WriteEndObject()
