namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.Executables
open ModConductor.ProfileGameData
open ModConductor.Persistence

module ProfileDataFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private identity path =
        let selected = StorageWorker.select (Path.GetDirectoryName(path: string))
        let facts = ModConductor.Platform.RootSelection.facts selected

        let id =
            match facts.File with
            | ModConductor.Platform.Known value -> value
            | _ -> invalidOp "No fixture identity"

        use parent =
            ModConductor.Platform.HeldDirectory.Open(
                ModConductor.Platform.RootSelection.path selected,
                id
            )

        (parent.InspectEntry(Path.GetFileName path)).Value.Identity

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("profileData")

        if not (OperatingSystem.IsLinux()) then
            writer.WriteString("status", "Windows verification deferred under MC-D-032")
        else
            let check (name: string) condition =
                writer.WriteBoolean(name, condition)

                if not condition then
                    invalidOp ("Profile data fixture failed: " + name)

            let area = Directory.CreateDirectory(Path.Combine(primary, "profile-data")).FullName

            let workspacePath =
                Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

            let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
            BethesdaSamples.requiredBaseFiles game
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

            let workspace, first, second = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
            let mutable store = new OperationStore(Path.Combine(area, "state"))

            use lifetime =
                { new IDisposable with
                    member _.Dispose() = (store :> IDisposable).Dispose() }

            let mutable ws = store.Workspaces :> IWorkspaceState

            let created =
                ws.Create(workspace, "Private game files", StorageWorker.select workspacePath)
                |> wait
                |> result

            let firstCreated =
                ws.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = first; Name = "First" }
                )
                |> wait
                |> result

            ws.Edit(
                workspace,
                firstCreated.Workspace.Revision,
                ProfileEdit.Create { Id = second; Name = "Second" }
            )
            |> wait
            |> result
            |> ignore

            let context =
                [ first; second ]
                |> List.map (fun profile ->
                    (store.GameContexts :> IGameContexts)
                        .Save(workspace, profile, 0L, { GameId = GameId.SkyrimSpecialEditionSteam
                                                        Path = game; Proton = Some proton })
                    |> wait
                    |> result)
                |> List.head

            let documents =
                match context.Binding.Value.Evidence.Locations.Documents with
                | Location.Located(path, _) -> path
                | Location.Unavailable problem -> invalidOp problem

            let prefs = Path.Combine(documents, "SkyrimPrefs.ini")
            let ini = Path.Combine(documents, "Skyrim.ini")
            let globalSave = Path.Combine(documents, "Saves", "global.ess")
            let original = "[Display]\r\niSize W=1280\r\n"
            File.WriteAllText(prefs, original)
            File.WriteAllText(globalSave, "synthetic global save")
            let originalIdentity = identity prefs
            let mutable api = store.ProfileGameData

            let read profile =
                api.Read(workspace, profile) |> wait |> result

            let edit profile settings saves initial files =
                let expected = read profile

                api.Edit(
                    { Id = Guid.NewGuid()
                      Expected = expected.Reference
                      Options = { Settings = settings; Saves = saves }
                      InitialSaves = initial
                      DisabledFiles = files },
                    ignore,
                    token
                )
                |> wait
                |> result

            let enabled = edit first true true InitialSaves.Empty DisabledFiles.Keep

            check
                "enablingOnlyCreatesPrivateData"
                (enabled.Complete
                 && File.ReadAllText prefs = original
                 && not (File.Exists ini)
                 && enabled.State.InUse.IsNone)

            check
                "savesStartEmptyWithoutChangingGlobalSaves"
                (Directory.GetFileSystemEntries(enabled.State.SavesPath).Length = 0
                 && File.ReadAllText globalSave = "synthetic global save")

            let start profile =
                let current = ws.Read(workspace, None) |> wait |> result

                if current.Workspace.SelectedProfile.Value.Id <> profile then
                    ws.Edit(workspace, current.Workspace.Revision, ProfileEdit.Select profile)
                    |> wait
                    |> result
                    |> ignore

                let current = ws.Read(workspace, None) |> wait |> result
                let launch = store.GameLaunching.Read(workspace, profile) |> wait |> result

                let request =
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      WorkspaceRevision = current.Workspace.Revision
                      ProfileId = profile
                      ContextRevision = launch.ContextRevision
                      SourceToken = launch.SourceToken }

                store.GameLaunching.Begin request |> wait |> result |> ignore
                let deadline = DateTime.UtcNow.AddSeconds 30.
                let mutable run = store.Executables.Read(workspace, request.Id) |> wait |> result

                while run.Phase = RunPhase.Starting
                      || run.Phase = RunPhase.Running
                      || run.Phase = RunPhase.WaitingForChildren do
                    if DateTime.UtcNow > deadline then
                        invalidOp "Profile game launch timed out."

                    Thread.Sleep 10
                    run <- store.Executables.Read(workspace, request.Id) |> wait |> result

                run

            let play profile =
                let run = start profile

                if run.Phase <> RunPhase.Finished then
                    invalidOp (
                        "Profile launch failed: " + (run.Problem |> Option.defaultValue "Unknown")
                    )

                run

            let run = play first
            let applied = read first

            let capture =
                match run.Source with
                | RunSource.Game value -> value
                | _ -> invalidOp "Expected game run"

            check
                "playRetainsBothApplicationReceipts"
                (capture.Files.IsSome
                 && capture.ProfileData.IsSome
                 && capture.ProfileData.Value.Complete
                 && applied.InUse = Some first)

            let iniText = File.ReadAllText ini

            let savePath =
                iniText.Split('\n')
                |> Array.find (fun line -> line.StartsWith("sLocalSavePath="))
                |> fun line ->
                    line
                        .Substring("sLocalSavePath=".Length)
                        .Trim()
                        .Replace('\\', Path.DirectorySeparatorChar)

            let link = Path.Combine(documents, savePath) |> Path.TrimEndingDirectorySeparator
            File.WriteAllText(Path.Combine(link, "private.ess"), "first profile save")

            check
                "gameSavePathWritesIntoWorkspace"
                (File.ReadAllText(Path.Combine(applied.SavesPath, "private.ess")) = "first profile save"
                 && File.ReadAllText globalSave = "synthetic global save")

            let replacement = prefs + ".new"
            File.WriteAllText(replacement, "[Display]\r\niSize W=1600\r\n")
            File.Move(replacement, prefs, true)
            let secondEnabled = edit second true true InitialSaves.CopyGlobal DisabledFiles.Keep

            check
                "anotherProfileSeedsFromGlobalSettings"
                (File.ReadAllText(Path.Combine(secondEnabled.State.SettingsPath, "SkyrimPrefs.ini")) = original)

            check
                "explicitSaveCopyPreservesGlobalFiles"
                (File.ReadAllText(Path.Combine(secondEnabled.State.SavesPath, "global.ess")) = "synthetic global save")

            play second |> ignore

            check
                "switchCapturesAtomicIniReplacement"
                (File.ReadAllText(Path.Combine(applied.SettingsPath, "SkyrimPrefs.ini")).Contains
                    "1600"
                 && File.ReadAllText prefs = original)

            let restored =
                api.Restore(Guid.NewGuid(), (read second).Reference, token) |> wait |> result

            check
                "restorePreservesOriginalObjectAndAbsence"
                (restored.Complete
                 && identity prefs = originalIdentity
                 && File.ReadAllText prefs = original
                 && not (File.Exists ini)
                 && not (Directory.Exists link))

            check
                "restorationKeepsEnabledOptions"
                ((read second).Options = { Settings = true; Saves = true })

            File.WriteAllText(prefs, "[Display]\r\niSize W=1920\r\n")
            play first |> ignore

            api.Restore(Guid.NewGuid(), (read first).Reference, token)
            |> wait
            |> result
            |> ignore

            check
                "newApplicationCapturesFreshGlobalBaseline"
                (File.ReadAllText(prefs).Contains "1920")

            edit first false false InitialSaves.Empty DisabledFiles.Keep |> ignore
            let kept = read first
            edit first true true InitialSaves.Empty DisabledFiles.Keep |> ignore

            check
                "reenablingReusesRetainedPrivateData"
                (File.ReadAllText(Path.Combine(kept.SavesPath, "private.ess")) = "first profile save"
                 && File.ReadAllText(Path.Combine(kept.SettingsPath, "SkyrimPrefs.ini")).Contains
                     "1600")

            play first |> ignore
            let activeSettings = "[Display]\niSize W=1777\n"
            File.WriteAllText(prefs, activeSettings)
            let cancelledActiveClone = Guid.NewGuid()
            use activeCopyCancellation = new CancellationTokenSource()
            let mutable cancelledAfterSourcePreserved = false
            let privatePrefs = Path.Combine(kept.SettingsPath, "SkyrimPrefs.ini")
            let current = ws.Read(workspace, None) |> wait |> result

            let cancelledCapture =
                store.CloneProfileDataAtCheckpoint(
                    workspace,
                    current.Workspace.Revision,
                    first,
                    { Id = cancelledActiveClone
                      Name = "Cancelled active copy" },
                    activeCopyCancellation.Token,
                    fun phase ->
                        if phase = "preserved" && not (File.Exists privatePrefs) then
                            cancelledAfterSourcePreserved <- true
                            activeCopyCancellation.Cancel()
                )
                |> wait

            let afterActiveCancellation = ws.Read(workspace, None) |> wait |> result
            let retainedSource = read first

            check
                "cancelAfterPreservingActiveSourceFinishesCaptureBeforeCleanup"
                (cancelledAfterSourcePreserved
                 && Result.isError cancelledCapture
                 && afterActiveCancellation.Workspace.Revision = current.Workspace.Revision
                 && not (
                     afterActiveCancellation.Profiles
                     |> List.exists (fun value -> value.Id = cancelledActiveClone)
                 )
                 && retainedSource.Pending.IsNone
                 && retainedSource.InUse = Some first
                 && File.ReadAllText privatePrefs = activeSettings
                 && File.ReadAllText prefs = activeSettings
                 && File.ReadAllText(Path.Combine(kept.SavesPath, "private.ess")) = "first profile save")

            api.Restore(Guid.NewGuid(), retainedSource.Reference, token)
            |> wait
            |> result
            |> ignore

            let clone = Guid.NewGuid()
            let current = ws.Read(workspace, None) |> wait |> result

            let cloned =
                ws.EditWithProgress(
                    workspace,
                    current.Workspace.Revision,
                    ProfileEdit.Clone(first, { Id = clone; Name = "Independent" }),
                    ignore,
                    token
                )
                |> wait
                |> result

            let cloneData = read clone
            let cloneSave = Path.Combine(cloneData.SavesPath, "private.ess")
            File.WriteAllText(cloneSave, "independent edit")

            check
                "cloneHasIndependentSettingsAndSaves"
                (cloned.Changed.Value.Id = clone
                 && cloneData.Options = (read first).Options
                 && File.ReadAllText(Path.Combine(kept.SavesPath, "private.ess")) = "first profile save"
                 && identity cloneSave <> identity (Path.Combine(kept.SavesPath, "private.ess")))

            let nested =
                Directory.CreateDirectory(Path.Combine(cloneData.SavesPath, "Nested")).FullName

            for index in 1..70 do
                File.WriteAllText(
                    Path.Combine(nested, index.ToString("D3") + ".ess"),
                    "owned fixture"
                )

            let mutable next = None
            let mutable loaded = []
            let mutable pages = 0
            let mutable more = true

            while more do
                let page = api.SaveFiles(workspace, clone, [ "Nested" ], next) |> wait |> result
                loaded <- loaded @ (page.Entries |> List.map _.Name)
                next <- page.Next
                pages <- pages + 1
                more <- next.IsSome

            check
                "saveBrowsingContinuesWithoutMissingOrDuplicateFiles"
                (pages = 3 && loaded.Length = 70 && (List.distinct loaded).Length = 70)

            let large = Path.Combine(kept.SavesPath, "copy-cancellation.ess")
            File.WriteAllBytes(large, Array.create (8 * 1024 * 1024) 42uy)
            let cancelledId = Guid.NewGuid()
            use cancellation = new CancellationTokenSource()

            let progress (value: ProfileCopyProgress) =
                if value.Bytes >= 65536L && value.Bytes < 8L * 1024L * 1024L then
                    cancellation.Cancel()

            let current = ws.Read(workspace, None) |> wait |> result

            let cancelled =
                ws.EditWithProgress(
                    workspace,
                    current.Workspace.Revision,
                    ProfileEdit.Clone(first, { Id = cancelledId; Name = "Cancelled" }),
                    progress,
                    cancellation.Token
                )
                |> wait

            let after = ws.Read(workspace, None) |> wait |> result

            check
                "cancelledCopyHasNoSelectableHalfClone"
                (Result.isError cancelled
                 && not (after.Profiles |> List.exists (fun value -> value.Id = cancelledId))
                 && FileInfo(large).Length = 8L * 1024L * 1024L
                 && (read first).Pending.IsNone)

            File.Delete large
            let privateIni = Path.Combine(kept.SettingsPath, "Skyrim.ini")
            File.WriteAllBytes(privateIni, [| 255uy |])
            let failed = start first

            let failedGame =
                match failed.Source with
                | RunSource.Game value -> value
                | _ -> invalidOp "Expected game run"

            check
                "invalidPluginSettingsRetainDeploymentWithoutStarting"
                (failed.Phase = RunPhase.Failed
                 && failed.ProcessId.IsNone
                 && failedGame.Files.IsSome
                 && failedGame.ProfileData.IsNone
                 && (read first).Pending.IsNone)

            File.Delete privateIni

            api.Restore(Guid.NewGuid(), (read first).Reference, token)
            |> wait
            |> result
            |> ignore

            let disabled = edit second false false InitialSaves.Empty DisabledFiles.Delete

            check
                "explicitDeleteOnDisableOnlyRemovesPrivateFiles"
                (disabled.Complete
                 && Directory.GetFileSystemEntries(disabled.State.SettingsPath).Length = 0
                 && Directory.GetFileSystemEntries(disabled.State.SavesPath).Length = 0
                 && File.ReadAllText globalSave = "synthetic global save")

            let current = ws.Read(workspace, None) |> wait |> result

            ws.Edit(workspace, current.Workspace.Revision, ProfileEdit.Delete clone)
            |> wait
            |> result
            |> ignore

            check
                "profileDeletionRemovesItsPrivateCopy"
                (not (Directory.Exists cloneData.SavesPath)
                 && File.Exists(Path.Combine(kept.SavesPath, "private.ess")))

            let beforeInterruptedRestore = File.ReadAllBytes prefs
            start first |> ignore

            File.WriteAllText(
                Path.Combine(documents, "SkyrimPrefs.ini"),
                "[Display]\niSize W=777\n"
            )

            let interruptedId = Guid.NewGuid()

            let interrupted =
                store.RestoreProfileDataAtCheckpoint(
                    interruptedId,
                    (read first).Reference,
                    token,
                    fun phase ->
                        if phase = "installed" then
                            raise (IOException "Controlled interruption after file replacement.")
                )
                |> wait
                |> result

            check
                "interruptedRestoreRetainsItsPartialReceipt"
                (not interrupted.Complete && interrupted.State.Pending = Some interruptedId)

            (store :> IDisposable).Dispose()
            store <- new OperationStore(Path.Combine(area, "state"))
            ws <- store.Workspaces :> IWorkspaceState
            api <- store.ProfileGameData
            let contexts = store.GameContexts :> IGameContexts
            let reloaded = contexts.Read(workspace, first) |> wait |> result
            contexts.Refresh(workspace, first, reloaded.Revision) |> wait |> result |> ignore

            let resumed =
                store.ProfileGameData.Resume(workspace, interruptedId, token) |> wait |> result

            let replayed =
                store.ProfileGameData.Resume(workspace, interruptedId, token) |> wait |> result

            check
                "restartResumesInterruptedRestoreWithoutLosingSettings"
                (resumed.Complete
                 && replayed.Complete
                 && resumed.State.InUse.IsNone
                 && File
                     .ReadAllText(Path.Combine(kept.SettingsPath, "SkyrimPrefs.ini"))
                     .Contains("777")
                 && File.ReadAllBytes prefs = beforeInterruptedRestore)

            start first |> ignore
            let conflictId = Guid.NewGuid()

            let paused =
                store.RestoreProfileDataAtCheckpoint(
                    conflictId,
                    (read first).Reference,
                    token,
                    fun phase ->
                        if phase = "installed" then
                            raise (IOException "Controlled pause before the next settings file.")
                )
                |> wait
                |> result

            let replacement = Path.Combine(documents, "ordinary-save.tmp")
            File.WriteAllText(replacement, "[Display]\niSize W=640\n")
            File.Move(replacement, prefs, true)
            let changedIdentity, changedBytes = identity prefs, File.ReadAllBytes prefs
            let refused = api.Resume(workspace, conflictId, token) |> wait |> result

            check
                "changedFileDuringPausedRestoreIsLeftUntouched"
                (not paused.Complete
                 && not refused.Complete
                 && refused.State.Pending = Some conflictId
                 && identity prefs = changedIdentity
                 && File.ReadAllBytes prefs = changedBytes)

        writer.WriteEndObject()
