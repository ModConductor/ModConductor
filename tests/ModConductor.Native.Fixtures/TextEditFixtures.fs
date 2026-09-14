namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.FilePlanning
open ModConductor.Deployment
open ModConductor.DeploymentRecovery
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module TextEditFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private check name condition =
        if not condition then
            invalidOp ("Text edit fixture failed: " + name)

        condition

    let private path names = LogicalPath.create names |> result

    let private hash (bytes: byte array) =
        SHA256.HashData bytes |> Convert.ToHexStringLower

    let private metadata name =
        { Name = name
          Notes = ""
          Comment = ""
          Version = "1"
          Source = "Fixture"
          Categories = [] }

    let private encodingCases (writer: Utf8JsonWriter) =
        let cases =
            [ TextDocumentEncoding.Utf8, Encoding.UTF8.GetBytes "one\ntwo\n"
              TextDocumentEncoding.Utf8Bom,
              Array.append [| 0xEFuy; 0xBBuy; 0xBFuy |] (Encoding.UTF8.GetBytes "one\ntwo\n")
              TextDocumentEncoding.Utf16Little,
              Array.append [| 0xFFuy; 0xFEuy |] (Encoding.Unicode.GetBytes "one\r\ntwo")
              TextDocumentEncoding.Utf16Big,
              Array.append [| 0xFEuy; 0xFFuy |] (Encoding.BigEndianUnicode.GetBytes "one\r\ntwo") ]

        let roundTrips =
            cases
            |> List.forall (fun (kind, bytes) ->
                match TextDocuments.editable bytes with
                | Error _ -> false
                | Ok document ->
                    document.Encoding = kind
                    && (TextDocuments.encode document document.Content |> result) = bytes)

        writer.WriteBoolean("encodingAndNewlineRoundTrips", check "encoding round trips" roundTrips)

        let unsupported bytes =
            TextDocuments.editable bytes |> Result.isError

        writer.WriteBoolean(
            "mixedAndLoneCarriageReturnRefuse",
            check
                "mixed newline refusal"
                (unsupported (Encoding.UTF8.GetBytes "one\r\ntwo\n")
                 && unsupported (Encoding.UTF8.GetBytes "one\rtwo"))
        )

        writer.WriteBoolean(
            "malformedAndNulRefuse",
            check
                "malformed text refusal"
                (unsupported [| 0xC3uy; 0x28uy |]
                 && unsupported (Encoding.UTF8.GetBytes "one\u0000two"))
        )

        let original = TextDocuments.editable (Encoding.UTF8.GetBytes "one") |> result

        writer.WriteBoolean(
            "draftCarriageReturnAndLimitsRefuse",
            check
                "draft limits"
                ((TextDocuments.encode original "one\rtwo" |> Result.isError)
                 && (TextDocuments.encode
                         original
                         (String.replicate (TextDocuments.linesLimit + 1) "x\n")
                     |> Result.isError)
                 && (TextDocuments.encode original (String('x', TextDocuments.bytesLimit + 1))
                     |> Result.isError))
        )

    let private rootOf directory =
        let selected = StorageWorker.select directory

        let identity =
            match ModConductor.Platform.RootSelection.facts selected with
            | { File = ModConductor.Platform.Known value } -> value
            | _ -> invalidOp "Fixture root identity is unavailable."

        { Path = ModConductor.Platform.RootSelection.path selected
          Identity = identity }
        : DataRoot

    let private managedSource (plans: IFilePlans) profile =
        let snapshot = plans.Acquire(profile, true, ignore, token) |> wait |> result

        let source =
            plans.Inspect(snapshot.Id, path [ "edited.ini" ], None)
            |> wait
            |> result
            |> _.Copies
            |> List.find _.Winner
            |> _.Source
            |> function
                | FilePreviewSource.ManagedCopy value -> value
                | _ -> invalidOp "Expected managed source"

        snapshot, source

    let private seedPublicationScenario area =
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))

        let workspace, profile, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
        File.WriteAllText(Path.Combine(source, "edited.ini"), "original\n")
        File.WriteAllText(Path.Combine(source, "retained.txt"), "retained\n")
        let store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        let library = store.ModLibrary :> IModLibrary
        let selections = store.ModSelection :> IModSelection
        let contexts = store.GameContexts :> IGameContexts

        let created =
            workspaces.Create(workspace, "Publication recovery", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Recovery" }
        )
        |> wait
        |> result
        |> ignore

        let registered =
            library.Register(
                workspace,
                modId,
                metadata "Recovery mod",
                Registration.Directory(ModKind.Regular, path [ "source" ])
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
        let inventory = InventoryObservations.read store profile

        selections.Change(
            profile,
            inventory.SelectionRevision,
            [ modId ],
            SelectionEdit.Enable true
        )
        |> wait
        |> result
        |> ignore

        let context =
            contexts.Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
            |> wait
            |> result

        store, state, root, workspace, profile, modId, version, context

    let private publicationRecovery (writer: Utf8JsonWriter) area =
        let scenario = Path.Combine(area, "publication-recovery")

        let store, state, _, workspace, profile, modId, originalVersion, context =
            seedPublicationScenario scenario

        let deployment = store.Deployments
        let deploymentState = deployment.Read profile |> wait |> result
        let generationId = Guid.NewGuid()

        deployment.Prepare(generationId, deploymentState.Sources, ignore, token)
        |> wait
        |> result
        |> ignore

        deployment.Activate(generationId, deploymentState.Sources, ignore, token)
        |> wait
        |> result
        |> ignore

        let contextId =
            DeploymentContextId.create
                workspace
                (DeploymentContextId.fingerprint context.Binding.Value.Evidence)

        let retainedBefore =
            store.Deployment.Generation(contextId, generationId) |> wait |> Option.get

        RecoveryFiles.verifyGeneration retainedBefore

        let interruptedPlans =
            store.FilePlansAtTextPublicationCheckpoint(
                ignore,
                (fun () -> raise (IOException "stop"))
            )
            :> IFilePlans

        let snapshot, source = managedSource interruptedPlans profile
        let action = Guid.NewGuid()

        let stopped =
            interruptedPlans.SaveManagedText(snapshot.Id, action, source, "continued\n", token)
            |> wait

        let noFalseCurrent =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = modId)
            |> _.Entry.Mod.CurrentVersion
            |> (=) (Some originalVersion)

        let persistedBeforeRestart = store.EditTransientBytes action |> wait
        (store :> IDisposable).Dispose()

        use reopened = new OperationStore(state)
        let contexts = reopened.GameContexts :> IGameContexts
        let staleContext = contexts.Read workspace |> wait |> result
        contexts.Refresh(workspace, staleContext.Revision) |> wait |> result |> ignore
        let resumedPlans = reopened.FilePlans :> IFilePlans
        let resumedSnapshot, resumedSource = managedSource resumedPlans profile

        let completed =
            resumedPlans.SaveManagedText(
                resumedSnapshot.Id,
                action,
                resumedSource,
                "different client bytes\n",
                token
            )
            |> wait
            |> result

        let library = reopened.ModLibrary :> IModLibrary
        let completedVersion = library.Version(completed.VersionId, 0) |> wait |> result

        let edited =
            completedVersion.Entries
            |> List.find (fun entry -> entry.Path = path [ "edited.ini" ])

        let bytes =
            library.ReadPayload(completed.VersionId, edited.Payload.Id, 0L, 1024)
            |> wait
            |> result

        let retainedAfter =
            reopened.Deployment.Generation(contextId, generationId) |> wait |> Option.get

        RecoveryFiles.verifyGeneration retainedAfter

        writer.WriteBoolean(
            "interruptedPublicationRestartsSameReceipt",
            check
                "publication recovery"
                (Result.isError stopped
                 && noFalseCurrent
                 && persistedBeforeRestart > 0L
                 && completed.Id = action
                 && completed.VersionId = action
                 && Encoding.UTF8.GetString bytes = "continued\n"
                 && (reopened.EditTransientBytes action |> wait) = 0L
                 && retainedAfter = retainedBefore)
        )

    let private cancellationAndPayloadRace (writer: Utf8JsonWriter) area =
        let cancelledArea = Path.Combine(area, "publication-cancel")

        let store, _, cancelledRoot, _, profile, modId, originalVersion, _ =
            seedPublicationScenario cancelledArea

        use store = store
        use entered = new ManualResetEventSlim(false)
        use release = new ManualResetEventSlim(false)

        let plansAtCancel =
            store.FilePlansAtTextObservation(fun () ->
                entered.Set()
                release.Wait())
            :> IFilePlans

        let snapshot, source = managedSource plansAtCancel profile
        let action = Guid.NewGuid()
        use cancellation = new CancellationTokenSource()

        let pending =
            plansAtCancel.SaveManagedText(
                snapshot.Id,
                action,
                source,
                "cancelled\n",
                cancellation.Token
            )

        entered.Wait()

        let beforeCancelVersion, beforeCancelOrigin, beforeCancelManifest, pendingPayloads =
            store.EditPublicationResidue action |> wait

        let pendingPaths =
            pendingPayloads
            |> List.map (fun payload ->
                Directory.GetFiles(
                    cancelledRoot,
                    payload.ToString("N") + ".payload",
                    SearchOption.AllDirectories
                )
                |> Array.exactlyOne)

        cancellation.Cancel()
        release.Set()
        let cancelled = pending |> wait
        let abandoned = plansAtCancel.AbandonManagedText action |> wait

        let afterCancelVersion, afterCancelOrigin, afterCancelManifest, afterCancelPayloads =
            store.EditPublicationResidue action |> wait

        let current =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = modId)
            |> _.Entry.Mod.CurrentVersion

        writer.WriteBoolean(
            "cancelledPublicationIsNotCurrentAndClearsInput",
            check
                "publication cancellation"
                (cancelled = Error FilePlanError.Cancelled
                 && abandoned = Error FilePlanError.NotFound
                 && current = Some originalVersion
                 && beforeCancelVersion = 1L
                 && beforeCancelOrigin = 1L
                 && beforeCancelManifest > 0L
                 && not pendingPayloads.IsEmpty
                 && afterCancelVersion = 0L
                 && afterCancelOrigin = 0L
                 && afterCancelManifest = 0L
                 && afterCancelPayloads.IsEmpty
                 && (pendingPaths |> List.forall (File.Exists >> not))
                 && (store.EditTransientBytes action |> wait) = -1L)
        )

        let abandonArea = Path.Combine(area, "publication-abandon")

        let abandonStore, _, abandonRoot, _, abandonProfile, abandonMod, abandonCurrent, _ =
            seedPublicationScenario abandonArea

        use abandonStore = abandonStore

        let interruptedPlans =
            abandonStore.FilePlansAtTextObservation(fun () ->
                raise (IOException "stop after publication effects"))
            :> IFilePlans

        let abandonSnapshot, abandonSource = managedSource interruptedPlans abandonProfile
        let abandonAction = Guid.NewGuid()

        let interrupted =
            interruptedPlans.SaveManagedText(
                abandonSnapshot.Id,
                abandonAction,
                abandonSource,
                "abandoned\n",
                token
            )
            |> wait

        let beforeAbandonVersion, beforeAbandonOrigin, beforeAbandonManifest, abandonedPayloads =
            abandonStore.EditPublicationResidue abandonAction |> wait

        let abandonedPaths =
            abandonedPayloads
            |> List.map (fun payload ->
                Directory.GetFiles(
                    abandonRoot,
                    payload.ToString("N") + ".payload",
                    SearchOption.AllDirectories
                )
                |> Array.exactlyOne)

        let abandoned = interruptedPlans.AbandonManagedText abandonAction |> wait

        let afterAbandonVersion, afterAbandonOrigin, afterAbandonManifest, afterAbandonPayloads =
            abandonStore.EditPublicationResidue abandonAction |> wait

        let abandonCurrentAfter =
            (InventoryObservations.read abandonStore abandonProfile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = abandonMod)
            |> _.Entry.Mod.CurrentVersion

        let originalStillReadable =
            let library = abandonStore.ModLibrary :> IModLibrary
            let original = library.Version(abandonCurrent, 0) |> wait |> result

            original.Entries
            |> List.forall (fun entry ->
                library.ReadPayload(abandonCurrent, entry.Payload.Id, 0L, 1024)
                |> wait
                |> Result.isOk)

        writer.WriteBoolean(
            "abandonedPublicationRemovesOwnedFilesAndRows",
            check
                "publication abandonment"
                (Result.isError interrupted
                 && beforeAbandonVersion = 1L
                 && beforeAbandonOrigin = 1L
                 && beforeAbandonManifest > 0L
                 && not abandonedPayloads.IsEmpty
                 && abandoned = Ok abandonAction
                 && afterAbandonVersion = 0L
                 && afterAbandonOrigin = 0L
                 && afterAbandonManifest = 0L
                 && afterAbandonPayloads.IsEmpty
                 && (abandonedPaths |> List.forall (File.Exists >> not))
                 && abandonCurrentAfter = Some abandonCurrent
                 && originalStillReadable)
        )

        let raceArea = Path.Combine(area, "payload-race")

        let raceStore, _, raceRoot, _, raceProfile, raceMod, raceVersion, _ =
            seedPublicationScenario raceArea

        use raceStore = raceStore
        let basePlans = raceStore.FilePlans :> IFilePlans
        let _, baseSource = managedSource basePlans raceProfile
        let payloadName = baseSource.PayloadId.ToString("N") + ".payload"

        let payloadPath =
            Directory.GetFiles(raceRoot, payloadName, SearchOption.AllDirectories)
            |> Array.exactlyOne

        let racePlans =
            raceStore.FilePlansAtTextEffect(fun () ->
                let prior = File.ReadAllBytes payloadPath
                prior[0] <- prior[0] ^^^ 1uy

                if OperatingSystem.IsWindows() then
                    File.SetAttributes(payloadPath, FileAttributes.Normal)
                else
                    File.SetUnixFileMode(
                        payloadPath,
                        UnixFileMode.UserRead ||| UnixFileMode.UserWrite
                    )

                File.WriteAllBytes(payloadPath, prior))
            :> IFilePlans

        let raceSnapshot, raceSource = managedSource racePlans raceProfile
        let raceAction = Guid.NewGuid()

        let refused =
            racePlans.SaveManagedText(raceSnapshot.Id, raceAction, raceSource, "changed\n", token)
            |> wait

        let raceCurrent =
            (InventoryObservations.read raceStore raceProfile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = raceMod)
            |> _.Entry.Mod.CurrentVersion

        let noCompletedEdit =
            (raceStore.ModLibrary :> IModLibrary).Version(raceAction, 0)
            |> wait
            |> Result.isError

        let raceStale =
            match refused with
            | Error FilePlanError.Stale -> true
            | _ -> false

        writer.WriteBoolean(
            "replacedPayloadRaceRefusesBeforeEffect",
            check
                "replaced payload race"
                (raceStale && raceCurrent = Some raceVersion && noCompletedEdit)
        )

    let private persistedProfileRestoreConflict (writer: Utf8JsonWriter) area =
        let root =
            Directory.CreateDirectory(Path.Combine(area, "profile-public-workspace")).FullName

        let state =
            Directory.CreateDirectory(Path.Combine(area, "profile-public-state")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "profile-public-game"))
        let workspace, profile, action = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let mutable interrupted = false

        let checkpoint phase =
            if phase = "file-recorded" && not interrupted then
                interrupted <- true
                raise (IOException "stop after the installed effect was recorded")

        let store = new OperationStore(state, configurationCheckpoint = checkpoint)
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "Profile restore conflict", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Recovery" }
        )
        |> wait
        |> result
        |> ignore

        let contexts = store.GameContexts :> IGameContexts

        let context =
            contexts.Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
            |> wait
            |> result

        let documents =
            match context.Binding.Value.Evidence.Locations.Documents with
            | Location.Located(value, _) -> value
            | Location.Unavailable problem -> invalidOp problem

        File.WriteAllText(Path.Combine(documents, "Skyrim.ini"), "[Archive]\noriginal=1\n")

        let profileData = store.ProfileGameData
        let initial = profileData.Read(workspace, profile) |> wait |> result

        let enabled =
            profileData.Edit(
                { Id = Guid.NewGuid()
                  Expected = initial.Reference
                  Options = { Settings = true; Saves = false }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            )
            |> wait
            |> result

        let opened =
            profileData.ReadConfiguration(enabled.State.Reference, "Skyrim.ini", token)
            |> wait
            |> result

        let saved =
            profileData.SaveConfiguration(
                { Id = action
                  PreviewId = opened.PreviewId
                  Expected = opened.Expected
                  Name = opened.Name
                  Content = "[Archive]\nchanged=1\n" },
                ignore,
                token
            )
            |> wait
            |> result

        let target = Path.Combine(enabled.State.SettingsPath, "Skyrim.ini")

        let stage =
            Directory.GetFiles(root, "previous-Skyrim.ini", SearchOption.AllDirectories)
            |> Array.find (fun candidate ->
                candidate.Contains(action.ToString("N"), StringComparison.OrdinalIgnoreCase))

        let backupBefore = File.ReadAllBytes stage
        File.Delete target
        (store :> IDisposable).Dispose()

        use reopened = new OperationStore(state)
        let actionBefore = reopened.ProfileDataActionBytes action |> wait

        let resumed = reopened.ProfileGameData.Resume(workspace, action, token) |> wait

        let restored =
            reopened.ProfileGameData.RestoreConfiguration(workspace, action, token) |> wait

        let after = reopened.ProfileGameData.Read(workspace, profile) |> wait |> result
        let actionAfter = reopened.ProfileDataActionBytes action |> wait

        let resumeConflict =
            match resumed with
            | Error(ProfileDataError.Conflict _) -> true
            | _ -> false

        let restoreConflict =
            match restored with
            | Error(ProfileDataError.Conflict _) -> true
            | _ -> false

        writer.WriteBoolean(
            "persistedDeletedProfileEditRefusesResumeAndRestore",
            check
                "persisted deleted profile edit"
                (not saved.Complete
                 && saved.CompletedFiles = 1
                 && resumeConflict
                 && restoreConflict
                 && after.Pending = Some action
                 && not (File.Exists target)
                 && File.ReadAllBytes stage = backupBefore
                 && actionAfter = actionBefore)
        )

    let private interruptedProfileRecovery (writer: Utf8JsonWriter) area =
        let targetPath =
            Directory.CreateDirectory(Path.Combine(area, "recovery-target")).FullName

        let stagePath =
            Directory.CreateDirectory(Path.Combine(area, "recovery-stage")).FullName

        let targetRoot, stageRoot = rootOf targetPath, rootOf stagePath
        let originalBytes = Encoding.UTF8.GetBytes "original\n"
        let replacementBytes = Encoding.UTF8.GetBytes "replacement\n"
        File.WriteAllBytes(Path.Combine(targetPath, "Skyrim.ini"), originalBytes)

        use target = HeldDirectory.Open(targetRoot.Path, targetRoot.Identity)
        use stage = HeldDirectory.Open(stageRoot.Path, stageRoot.Identity)
        let before = DataFiles.observe target "Skyrim.ini" token |> Option.get
        let replacement = DataFiles.stage stage "edit-Skyrim.ini" replacementBytes token

        let effect =
            { Target = targetRoot
              Backups = stageRoot
              Change =
                { Name = "Skyrim.ini"
                  Before = Some before
                  Replacement =
                    Some
                        { Root = stageRoot
                          Name = "edit-Skyrim.ini"
                          File = replacement }
                  BackupName = "previous-Skyrim.ini" } }

        let action =
            { Id = Guid.NewGuid()
              ContextId = Guid.NewGuid()
              ProfileId = Guid.NewGuid()
              ExpectedRevision = 1L
              Kind =
                ProfileDataActionKind.EditConfiguration
                    { PreviewId = Guid.NewGuid()
                      Name = "Skyrim.ini"
                      Before = Some before
                      Bytes = replacementBytes }
              Deletion = None
              CloneTarget = None
              Prepared = true
              WorkspaceStage = Some stageRoot
              DocumentsStage = None
              PluginStage = None
              ChangedProfile = None
              Files = [ effect ]
              CompletedFiles = 0
              Link = SaveLinkEffect.Unchanged
              LinkRemoved = false
              LinkCreated = None
              Proposed = None
              Complete = false
              Problem = None }

        try
            DataFiles.apply target stage effect.Change token (fun phase ->
                if phase = "preserved" then
                    raise (OperationCanceledException()))
        with :? OperationCanceledException ->
            ()

        ConfigurationFiles.restoreOriginal action token

        writer.WriteBoolean(
            "interruptedProfileEditRestoresExactOriginal",
            check
                "profile recovery"
                (File.ReadAllBytes(Path.Combine(targetPath, "Skyrim.ini")) = originalBytes
                 && not (File.Exists(Path.Combine(stagePath, "edit-Skyrim.ini")))
                 && not (File.Exists(Path.Combine(stagePath, "previous-Skyrim.ini"))))
        )

        let deletedTargetPath =
            Directory.CreateDirectory(Path.Combine(area, "deleted-recovery-target")).FullName

        let deletedStagePath =
            Directory.CreateDirectory(Path.Combine(area, "deleted-recovery-stage")).FullName

        let deletedTargetRoot, deletedStageRoot =
            rootOf deletedTargetPath, rootOf deletedStagePath

        File.WriteAllBytes(Path.Combine(deletedTargetPath, "Skyrim.ini"), originalBytes)

        use deletedTarget =
            HeldDirectory.Open(deletedTargetRoot.Path, deletedTargetRoot.Identity)

        use deletedStage =
            HeldDirectory.Open(deletedStageRoot.Path, deletedStageRoot.Identity)

        let deletedBefore = DataFiles.observe deletedTarget "Skyrim.ini" token |> Option.get

        let deletedReplacement =
            DataFiles.stage deletedStage "edit-Skyrim.ini" replacementBytes token

        let deletedEffect =
            { Target = deletedTargetRoot
              Backups = deletedStageRoot
              Change =
                { Name = "Skyrim.ini"
                  Before = Some deletedBefore
                  Replacement =
                    Some
                        { Root = deletedStageRoot
                          Name = "edit-Skyrim.ini"
                          File = deletedReplacement }
                  BackupName = "previous-Skyrim.ini" } }

        DataFiles.apply deletedTarget deletedStage deletedEffect.Change token ignore
        let installed = DataFiles.observe deletedTarget "Skyrim.ini" token |> Option.get
        deletedTarget.RemoveFile("Skyrim.ini", installed.Identity)

        let deletedAction =
            { action with
                Id = Guid.NewGuid()
                Files = [ deletedEffect ]
                CompletedFiles = 1 }

        let deletionRefused =
            try
                ConfigurationFiles.restoreOriginal deletedAction token
                false
            with ProfileDataException(ProfileDataError.Conflict _) ->
                true

        writer.WriteBoolean(
            "deletedInstalledProfileEditRefusesRestore",
            check
                "deleted installed profile edit"
                (deletionRefused
                 && not (File.Exists(Path.Combine(deletedTargetPath, "Skyrim.ini")))
                 && File.ReadAllBytes(Path.Combine(deletedStagePath, "previous-Skyrim.ini")) = originalBytes
                 && not (File.Exists(Path.Combine(deletedStagePath, "edit-Skyrim.ini"))))
        )

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("textEdits")
        encodingCases writer

        let area = Directory.CreateDirectory(Path.Combine(primary, "text-edits")).FullName
        interruptedProfileRecovery writer area
        persistedProfileRestoreConflict writer area
        publicationRecovery writer area
        cancellationAndPayloadRace writer area
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))

        let workspace, profile, modId, originalVersion =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let source = Directory.CreateDirectory(Path.Combine(root, "source")).FullName
        File.WriteAllText(Path.Combine(source, "edited.ini"), "alpha\nbeta\n")
        File.WriteAllText(Path.Combine(source, "same.txt"), "shared")

        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        let library = store.ModLibrary :> IModLibrary
        let selections = store.ModSelection :> IModSelection
        let contexts = store.GameContexts :> IGameContexts
        let plans = store.FilePlans :> IFilePlans
        let profileData = store.ProfileGameData

        let created =
            workspaces.Create(workspace, "Text edit fixture", StorageWorker.select root)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Daily" }
        )
        |> wait
        |> result
        |> ignore

        let registered =
            library.Register(
                workspace,
                modId,
                metadata "Text mod",
                Registration.Directory(ModKind.Regular, path [ "source" ])
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, originalVersion)
        |> wait
        |> result
        |> ignore

        let inventory = InventoryObservations.read store profile

        selections.Change(
            profile,
            inventory.SelectionRevision,
            [ modId ],
            SelectionEdit.Enable true
        )
        |> wait
        |> result
        |> ignore

        let context =
            contexts.Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
            |> wait
            |> result

        let documents =
            match context.Binding.Value.Evidence.Locations.Documents with
            | Location.Located(value, _) -> value
            | Location.Unavailable problem -> invalidOp problem

        let globalIni = Path.Combine(documents, "Skyrim.ini")

        let globalBytes =
            Array.append
                [| 0xEFuy; 0xBBuy; 0xBFuy |]
                (Encoding.UTF8.GetBytes "[Archive]\r\nvalue=global\r\n")

        File.WriteAllBytes(globalIni, globalBytes)

        let acquired = plans.Acquire(profile, true, ignore, token) |> wait |> result

        let inspection =
            plans.Inspect(acquired.Id, path [ "edited.ini" ], None) |> wait |> result

        let managed =
            inspection.Copies
            |> List.find _.Winner
            |> _.Source
            |> function
                | FilePreviewSource.ManagedCopy value -> value
                | _ -> invalidOp "Expected managed source"

        let beforeOpen =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = modId)
            |> _.Entry.Mod

        let opened = plans.OpenManagedText(acquired.Id, managed, token) |> wait |> result

        let afterOpen =
            (InventoryObservations.read store profile).Entries
            |> List.find (fun value -> value.Entry.Mod.Id = modId)
            |> _.Entry.Mod

        writer.WriteBoolean(
            "managedOpenIsReadOnly",
            check
                "managed open is read-only"
                (beforeOpen = afterOpen && opened.Document.Content = "alpha\nbeta\n")
        )

        let _ =
            library.Edit(
                modId,
                beforeOpen.Revision,
                { beforeOpen.Metadata with
                    Name = "Renamed" }
            )
            |> wait
            |> result

        let staleAction = Guid.NewGuid()

        writer.WriteBoolean(
            "modRevisionChangeRefusesSave",
            check
                "mod revision stale"
                ((plans.SaveManagedText(acquired.Id, staleAction, managed, "changed\n", token)
                  |> wait) = Error FilePlanError.Stale
                 && (library.Version(staleAction, 0) |> wait) = Error LibraryError.NotFound)
        )

        let refreshed = plans.Open(profile, token) |> wait |> result

        let refreshedSource =
            plans.Inspect(refreshed.Id, path [ "edited.ini" ], None)
            |> wait
            |> result
            |> _.Copies
            |> List.find _.Winner
            |> _.Source
            |> function
                | FilePreviewSource.ManagedCopy value -> value
                | _ -> invalidOp "Expected managed source"

        let editId = Guid.NewGuid()

        let edit =
            plans.SaveManagedText(refreshed.Id, editId, refreshedSource, "changed\n", token)
            |> wait
            |> result

        let old = library.Version(originalVersion, 0) |> wait |> result
        let current = library.Version(edit.VersionId, 0) |> wait |> result

        let entry name (version: ModVersion) =
            version.Entries |> List.find (fun value -> value.Path = path [ name ])

        let editedEntry = entry "edited.ini" current
        let oldEntry = entry "edited.ini" old

        let editedBytes =
            library.ReadPayload(current.Id, editedEntry.Payload.Id, 0L, 65536)
            |> wait
            |> result

        let oldBytes =
            library.ReadPayload(old.Id, oldEntry.Payload.Id, 0L, 65536) |> wait |> result

        writer.WriteBoolean(
            "modEditIsImmutableAndSharesUnchangedPayloads",
            check
                "immutable mod edit"
                (Encoding.UTF8.GetString editedBytes = "changed\n"
                 && Encoding.UTF8.GetString oldBytes = "alpha\nbeta\n"
                 && (entry "same.txt" old).Payload.Id = (entry "same.txt" current).Payload.Id
                 && File.ReadAllText(Path.Combine(source, "edited.ini")) = "alpha\nbeta\n"
                 && match current.Origin with
                    | VersionOrigin.Edited(action, sourceVersion, editedPath, digest) ->
                        action = editId
                        && sourceVersion = originalVersion
                        && editedPath = path [ "edited.ini" ]
                        && digest = hash editedBytes
                    | _ -> false)
        )

        let beforeProfileOpen = profileData.Read(workspace, profile) |> wait |> result

        let enabled =
            profileData.Edit(
                { Id = Guid.NewGuid()
                  Expected = beforeProfileOpen.Reference
                  Options = { Settings = true; Saves = false }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                token
            )
            |> wait
            |> result

        let privateIni = Path.Combine(enabled.State.SettingsPath, "Skyrim.ini")
        let beforePrivate = File.ReadAllBytes privateIni

        let profileOpened =
            profileData.ReadConfiguration(enabled.State.Reference, "skyrim.ini", token)
            |> wait
            |> result

        writer.WriteBoolean(
            "profileOpenPreservesBytesAndWritesNothing",
            check
                "profile open is read-only"
                (beforePrivate = File.ReadAllBytes privateIni
                 && profileOpened.Name = "Skyrim.ini"
                 && profileOpened.Document.Encoding = TextDocumentEncoding.Utf8Bom
                 && profileOpened.Document.Newline = TextDocumentNewline.CrLf)
        )

        let saved =
            profileData.SaveConfiguration(
                { Id = Guid.NewGuid()
                  PreviewId = profileOpened.PreviewId
                  Expected = profileOpened.Expected
                  Name = profileOpened.Name
                  Content = "[Archive]\nvalue=private\n" },
                ignore,
                token
            )
            |> wait
            |> result

        let privateBytes = File.ReadAllBytes privateIni

        writer.WriteBoolean(
            "profileSavePreservesFormatAndLeavesDocumentsAlone",
            check
                "profile format and private target"
                (saved.Complete
                 && privateBytes.AsSpan().StartsWith([| 0xEFuy; 0xBBuy; 0xBFuy |])
                 && Encoding.UTF8.GetString(privateBytes, 3, privateBytes.Length - 3) = "[Archive]\r\nvalue=private\r\n"
                 && File.ReadAllBytes globalIni = globalBytes)
        )

        let stalePreview =
            profileData.ReadConfiguration(saved.State.Reference, "Skyrim.ini", token)
            |> wait
            |> result

        let external = Encoding.UTF8.GetBytes "external\n"
        File.WriteAllBytes(privateIni, external)

        let refused =
            profileData.SaveConfiguration(
                { Id = Guid.NewGuid()
                  PreviewId = stalePreview.PreviewId
                  Expected = stalePreview.Expected
                  Name = stalePreview.Name
                  Content = "overwrite\n" },
                ignore,
                token
            )
            |> wait

        let afterRefusal = profileData.Read(workspace, profile) |> wait |> result

        let conflict =
            match refused with
            | Error(ProfileDataError.Conflict _) -> true
            | _ -> false

        writer.WriteBoolean(
            "externalProfileChangeRefusesOverwrite",
            check
                "profile conflict"
                (conflict
                 && afterRefusal.Pending.IsNone
                 && File.ReadAllBytes privateIni = external)
        )

        let prefs = Path.Combine(afterRefusal.SettingsPath, "SkyrimPrefs.ini")
        File.Delete prefs

        let absent =
            profileData.ReadConfiguration(afterRefusal.Reference, "SkyrimPrefs.ini", token)
            |> wait
            |> result

        let createdFile =
            profileData.SaveConfiguration(
                { Id = Guid.NewGuid()
                  PreviewId = absent.PreviewId
                  Expected = absent.Expected
                  Name = absent.Name
                  Content = "[Display]\nvalue=1\n" },
                ignore,
                token
            )
            |> wait
            |> result

        writer.WriteBoolean(
            "declaredAbsentProfileFileCanBeCreated",
            check
                "absent profile file"
                (createdFile.Complete
                 && File.ReadAllText prefs = "[Display]\nvalue=1\n"
                 && File.ReadAllBytes globalIni = globalBytes)
        )

        writer.WriteEndObject()
