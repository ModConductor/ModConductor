namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.Persistence
open ModConductor.Deployment
open ModConductor.Platform

module GeneratedOutputFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path
    let private token = CancellationToken.None

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "outputs")).FullName

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))

        let selectedProton =
            if OperatingSystem.IsLinux() then
                match proton.Association with
                | ProtonAssociation.Steam(root, library) ->
                    let alias = Path.Combine(area, "Steam alias")
                    Directory.CreateSymbolicLink(alias, root) |> ignore

                    { proton with
                        Association = ProtonAssociation.Steam(alias, library) }
                | ProtonAssociation.Manual -> proton
            else
                proton

        let workspace, profile, other = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let workspaceRoot = HostPath.create workspacePath |> Result.defaultWith invalidOp

        let profileGameFile =
            Path.Combine(GameViews.rootPath workspaceRoot profile, "Data", "result.txt")

        let check (name: string) (value: bool) =
            writer.WriteBoolean(name, value)

            if not value then
                invalidOp ("Output fixture failed: " + name)

        let preparedId, versionId, actionId, slotPath =
            use store = new OperationStore(Path.Combine(area, "state"))
            let ws = store.Workspaces :> IWorkspaceState

            let created =
                ws.Create(workspace, "Output review", StorageWorker.select workspacePath)
                |> wait
                |> result

            let edit =
                ws.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = profile; Name = "First" }
                )
                |> wait
                |> result

            ws.Edit(
                workspace,
                edit.Workspace.Revision,
                ProfileEdit.Create { Id = other; Name = "Other" }
            )
            |> wait
            |> result
            |> ignore

            let context =
                (store.GameContexts :> IGameContexts)
                    .Save(
                        workspace,
                        profile,
                        0L,
                        { GameId = GameId.SkyrimSpecialEditionSteam
                          Path = game
                          Proton =
                            if OperatingSystem.IsLinux() then
                                Some selectedProton
                            else
                                None }
                    )
                |> wait
                |> result

            let observeSessionDiscoverySnapshot () =
                if OperatingSystem.IsLinux() then
                    let steam, library =
                        match proton.Association with
                        | ProtonAssociation.Steam(root, library) -> root, library
                        | ProtonAssociation.Manual ->
                            invalidOp "Expected the selected Steam fixture."

                    let configuration = Path.Combine(steam, "config", "config.vdf")
                    let replacement = configuration + ".replacement"

                    File.WriteAllText(
                        replacement,
                        File
                            .ReadAllText(configuration)
                            .Replace("name fixture_tool", "name changed_session_tool")
                    )

                    File.Move(replacement, configuration, true)
                    let manifest = Path.Combine(library, "steamapps", "appmanifest_489830.acf")
                    let manifestReplacement = manifest + ".replacement"
                    File.Copy(manifest, manifestReplacement)
                    File.Move(manifestReplacement, manifest, true)
                    let reused = GameProcesses.validateContext context |> result

                    check
                        "sessionDiscoverySnapshotReused"
                        (reused.Fingerprint = context.Binding.Value.Evidence.Fingerprint
                         && reused.Proton.Value.GlobalTool = Some "fixture_tool")

                    let readAgain =
                        (store.GameContexts :> IGameContexts).Read(workspace, profile)
                        |> wait
                        |> result

                    check
                        "ordinaryReadKeepsSessionSnapshot"
                        (readAgain.Revision = context.Revision
                         && readAgain.Binding.Value.Evidence.Fingerprint = reused.Fingerprint)

            observeSessionDiscoverySnapshot ()

            let outputs = store.GeneratedOutputs
            let library = store.ModLibrary :> IModLibrary

            let scope () =
                outputs.Read(workspace, profile, None) |> wait |> result

            let observe () =
                outputs.Observe(scope (), ignore, token) |> wait |> result

            let select location name =
                { LocationId = location
                  Path = path name }

            let observeUnsupportedWritableFile () =
                let location =
                    outputs.Add(
                        Guid.NewGuid(),
                        scope (),
                        "Unexpected folder",
                        OutputPurpose.WritableFile(path "unexpected-output.txt")
                    )
                    |> wait
                    |> result

                Directory.CreateDirectory(location.PhysicalPath) |> ignore

                let refused = outputs.Observe(scope (), ignore, token) |> wait
                Directory.Delete(location.PhysicalPath)
                let recovered = observe ()
                outputs.StopUsing(location.Id, location.Revision) |> wait |> result |> ignore

                check
                    "nonRegularWritableFileReturnsErrorAndReleasesObservation"
                    (refused = Error(
                        OutputError.Unavailable "A writable file is not a regular file."
                     )
                     && recovered.Files = 0)

            observeUnsupportedWritableFile ()

            let observeToolFolder () =
                let tool =
                    outputs.Add(Guid.NewGuid(), scope (), "Tool files", OutputPurpose.ToolFolder)
                    |> wait
                    |> result

                let output = Path.Combine(tool.PhysicalPath, "result.txt")

                let beforeMissing = scope ()
                let missing = outputs.StopUsing(Guid.NewGuid(), 0L) |> wait
                let afterMissing = scope ()

                check
                    "unknownOutputLocationReturnsNotFoundWithoutChangingScope"
                    (missing = Error OutputError.NotFound
                     && afterMissing.Revision = beforeMissing.Revision
                     && afterMissing.Locations = beforeMissing.Locations)

                check
                    "toolFolderStartsEmptyOutsideGame"
                    (Directory.GetFileSystemEntries(tool.PhysicalPath).Length = 0
                     && not (tool.PhysicalPath.StartsWith(game)))

                File.WriteAllText(output, "first output")
                let stale = observe ()
                let replacement = Path.Combine(tool.PhysicalPath, "replacement.tmp")
                File.WriteAllText(replacement, "changed output")
                File.Move(replacement, output, true)

                let staleAction =
                    outputs.Apply(
                        Guid.NewGuid(),
                        stale.Id,
                        [ select tool.Id "result.txt" ],
                        OutputAction.Discard,
                        token
                    )
                    |> wait

                check
                    "changedReviewedFileRemainsUntouched"
                    (staleAction = Error OutputError.Stale
                     && File.ReadAllText(output) = "changed output")

                let invalidName =
                    outputs.Add(Guid.NewGuid(), scope (), " ", OutputPurpose.ToolFolder) |> wait

                let missingSnapshot =
                    outputs.Preview(
                        Guid.NewGuid(),
                        [ select tool.Id "result.txt" ],
                        OutputAction.Keep
                    )
                    |> wait

                let emptySelection =
                    outputs.Apply(Guid.NewGuid(), stale.Id, [], OutputAction.Keep, token) |> wait

                let invalidCursor =
                    outputs.Page(stale.Id, OutputView.ToolOutputs, Some "not a cursor", "") |> wait

                let invalidFilter =
                    outputs.Page(stale.Id, OutputView.ToolOutputs, None, String('x', 1025)) |> wait

                check
                    "invalidOutputRequestsReturnErrorsWithoutChangingFiles"
                    ((match invalidName with
                      | Error(OutputError.Invalid _) -> true
                      | _ -> false)
                     && missingSnapshot = Error OutputError.Stale
                     && emptySelection = Error OutputError.LimitExceeded
                     && invalidCursor = Error OutputError.Stale
                     && (match invalidFilter with
                         | Error(OutputError.Invalid _) -> true
                         | _ -> false)
                     && File.ReadAllText(output) = "changed output")

                let current = observe ()

                outputs.Apply(
                    Guid.NewGuid(),
                    current.Id,
                    [ select tool.Id "result.txt" ],
                    OutputAction.Keep,
                    token
                )
                |> wait
                |> result
                |> ignore

                let kept = observe ()
                check "keepAcknowledgesCurrentBytes" (kept.Unreviewed = 0 && kept.Files = 1)
                File.WriteAllText(output, "new output")
                let changed = observe ()
                check "laterOutputChangeNeedsReview" (changed.Unreviewed = 1)

                tool, output, changed

            let tool, output, changed = observeToolFolder ()

            let observeVersionPublication () =
                let modId, actionId = Guid.NewGuid(), Guid.NewGuid()

                let action =
                    OutputAction.MoveToMod(OutputDestination.NewMod(modId, "Generated", "output 1"))

                use interrupted = new CancellationTokenSource()

                let interruptedResult =
                    store.ApplyOutputAtCheckpoint(
                        actionId,
                        changed.Id,
                        [ select tool.Id "result.txt" ],
                        action,
                        interrupted.Token,
                        interrupted.Cancel
                    )
                    |> wait

                let pending = outputs.Action actionId |> wait |> result

                check
                    "cancelAfterPublicationKeepsDurableVersionAndOutput"
                    (interruptedResult = Error OutputError.Cancelled
                     && pending.Published
                     && not pending.Complete
                     && File.Exists output)

                let promoted = outputs.Resume(actionId, token) |> wait |> result

                let replay =
                    outputs.Apply(
                        actionId,
                        changed.Id,
                        [ select tool.Id "result.txt" ],
                        action,
                        token
                    )
                    |> wait
                    |> result

                let version = library.Version(promoted.VersionId.Value, 0) |> wait |> result

                check
                    "movePublishesOneImmutableVersionBeforeRemoval"
                    (promoted = replay
                     && promoted.Complete
                     && not (File.Exists output)
                     && version.Origin = VersionOrigin.Outputs actionId)

                let first = InventoryObservations.read store profile
                let second = InventoryObservations.read store other

                let row =
                    first.Entries |> List.map _.Entry |> List.find (fun row -> row.Mod.Id = modId)

                check
                    "createdOutputModIsDisabledAcrossProfiles"
                    ((match row.Selection with
                      | SelectionState.Managed(_, false) -> true
                      | _ -> false)
                     && (second.Entries
                         |> List.exists (fun row ->
                             row.Entry.Mod.Id = modId
                             && (match row.Entry.Selection with
                                 | SelectionState.Managed(_, false) -> true
                                 | _ -> false))))

                let scan = library.Scan(workspace, 100) |> wait |> result
                let scanned = scan.Entries |> List.find (fun entry -> entry.Id = modId)

                check
                    "sourceLessModIsReadyWithoutPublish"
                    (scanned.Status = InventoryStatus.Ready
                     && scanned.SourcePath.IsNone
                     && not (List.contains ModAction.Publish scanned.Actions))

                check
                    "ownedOutputFolderIsNotAnUnmanagedMod"
                    (scan.Unmanaged
                     |> List.forall (fun row ->
                         row.Path <> path (Path.GetFileName(tool.PhysicalPath))))

                (store.ModSelection :> IModSelection)
                    .Change(profile, first.SelectionRevision, [ modId ], SelectionEdit.Enable true)
                |> wait
                |> result
                |> ignore

                modId, actionId, promoted

            let modId, actionId, promoted = observeVersionPublication ()

            let observePromotion () =
                let sourcePath =
                    Directory.CreateDirectory(Path.Combine(workspacePath, "Registered")).FullName

                File.WriteAllText(Path.Combine(sourcePath, "result.txt"), "registered source")
                File.WriteAllText(Path.Combine(sourcePath, "retained.txt"), "unchanged source")
                let sourceMod = Guid.NewGuid()

                let registered =
                    library.Register(
                        workspace,
                        sourceMod,
                        { Name = "Registered"
                          Version = "source"
                          Notes = ""
                          Comment = ""
                          Source = ""
                          Categories = [] },
                        Registration.Directory(ModKind.Regular, path "Registered")
                    )
                    |> wait
                    |> result

                let sourceVersion = Guid.NewGuid()

                let publishedSource =
                    library.Publish(sourceMod, registered.Revision, sourceVersion) |> wait |> result

                let oldSource = library.Version(sourceVersion, 0) |> wait |> result
                File.WriteAllText(output, "promoted override")
                let promotionSnapshot = observe ()

                let promotion =
                    OutputAction.MoveToMod(
                        OutputDestination.ExistingMod(
                            sourceMod,
                            publishedSource.Revision,
                            "promoted"
                        )
                    )

                let preview =
                    outputs.Preview(
                        promotionSnapshot.Id,
                        [ select tool.Id "result.txt" ],
                        promotion
                    )
                    |> wait
                    |> result

                check
                    "promotionPreviewReportsActualSavedReplacement"
                    (preview.Replaced = [ path "result.txt" ]
                     && preview.PreviousVersion = Some sourceVersion
                     && preview.RegisteredSource)

                let composition =
                    outputs.Apply(
                        Guid.NewGuid(),
                        promotionSnapshot.Id,
                        [ select tool.Id "result.txt" ],
                        promotion,
                        token
                    )
                    |> wait
                    |> result

                let composed = library.Version(composition.VersionId.Value, 0) |> wait |> result

                let retained entries =
                    entries
                    |> List.find (fun (entry: ManifestEntry) -> entry.Path = path "retained.txt")

                let changedSource =
                    (library.Scan(workspace, 100) |> wait |> result).Entries
                    |> List.find (fun entry -> entry.Id = sourceMod)

                check
                    "promotionPreservesSourceAndSharesUnchangedPayload"
                    (File.ReadAllText(Path.Combine(sourcePath, "result.txt")) = "registered source"
                     && (retained composed.Entries).Payload = (retained oldSource.Entries).Payload
                     && changedSource.SourcePath = Some(path "Registered"))

                let republishedId = Guid.NewGuid()

                library.Publish(sourceMod, changedSource.Revision, republishedId)
                |> wait
                |> result
                |> ignore

                let republished = library.Version(republishedId, 0) |> wait |> result
                let composedAfter = library.Version(composed.Id, 0) |> wait |> result

                check
                    "explicitSourcePublishRetainsPriorOutputVersion"
                    (republished.Origin = VersionOrigin.RegisteredSource
                     && (republished.Entries
                         |> List.map (fun entry ->
                             entry.Path, entry.Payload.Length, entry.Payload.Sha256)) = (oldSource.Entries
                                                                                         |> List.map
                                                                                             (fun
                                                                                                 entry ->
                                                                                                 entry.Path,
                                                                                                 entry.Payload.Length,
                                                                                                 entry.Payload.Sha256))
                     && composedAfter = composed)

            observePromotion ()

            let observePaging () =
                let pages =
                    Directory.CreateDirectory(Path.Combine(tool.PhysicalPath, "pages")).FullName

                for index in 0..69 do
                    File.WriteAllText(Path.Combine(pages, string index + ".txt"), "page output")

                let paged = observe ()

                let firstPage =
                    outputs.Page(paged.Id, OutputView.ToolOutputs, None, "pages/") |> wait |> result

                let mutable cursor = firstPage.NextCursor
                let entries = ResizeArray(firstPage.Entries)

                while cursor.IsSome do
                    let page =
                        outputs.Page(paged.Id, OutputView.ToolOutputs, cursor, "pages/")
                        |> wait
                        |> result

                    entries.AddRange page.Entries
                    cursor <- page.NextCursor

                let wrongView =
                    outputs.Page(paged.Id, OutputView.WritableFiles, firstPage.NextCursor, "pages/")
                    |> wait

                check
                    "outputPagingKeepsCompleteRowsAndViewIdentity"
                    (entries.Count = 70
                     && (entries |> Seq.map _.Path |> Set.ofSeq).Count = 70
                     && firstPage.Files = 70
                     && firstPage.Unreviewed = 70
                     && wrongView = Error OutputError.Stale)

            observePaging ()

            let refreshSessionDiscoverySnapshot () =
                if OperatingSystem.IsLinux() then
                    let contexts = store.GameContexts :> IGameContexts
                    let before = contexts.Read(workspace, profile) |> wait |> result

                    let refreshed =
                        contexts.Refresh(workspace, profile, before.Revision) |> wait |> result

                    check
                        "explicitRefreshReplacesSessionSnapshot"
                        (refreshed.Revision = before.Revision + 1L
                         && refreshed.Binding.Value.Evidence.Proton.Value.GlobalTool = Some
                             "changed_session_tool")

                    let steam =
                        match proton.Association with
                        | ProtonAssociation.Steam(root, _) -> root
                        | ProtonAssociation.Manual -> invalidOp "Expected Steam fixture."

                    let configuration = Path.Combine(steam, "config", "config.vdf")

                    File.WriteAllText(
                        configuration,
                        File
                            .ReadAllText(configuration)
                            .Replace("changed_session_tool", "next_session_tool")
                    )

            let observeWritableSlot () =
                let slot =
                    outputs.Add(
                        Guid.NewGuid(),
                        scope (),
                        "Working file",
                        OutputPurpose.WritableFile(path "result.txt")
                    )
                    |> wait
                    |> result

                let state = store.Deployments.Read profile |> wait |> result

                let prepared =
                    store.Deployments.Prepare(Guid.NewGuid(), state.Sources, ignore, token)
                    |> wait
                    |> result

                store.Deployments.Activate(prepared.Id, prepared.Sources, ignore, token)
                |> wait
                |> result
                |> ignore

                check
                    "exactWritableSlotIsInitialized"
                    (File.Exists slot.PhysicalPath && File.Exists profileGameFile)

                File.WriteAllText(slot.PhysicalPath, "working result")
                let working = observe ()

                let modRow =
                    (InventoryObservations.read store profile).Entries
                    |> List.map _.Entry
                    |> List.find (fun row -> row.Mod.Id = modId)

                let copied =
                    outputs.Apply(
                        Guid.NewGuid(),
                        working.Id,
                        [ select slot.Id "result.txt" ],
                        OutputAction.SaveCopyToMod(
                            OutputDestination.ExistingMod(modId, modRow.Mod.Revision, "output 2")
                        ),
                        token
                    )
                    |> wait
                    |> result

                check
                    "saveCopyKeepsWorkingFile"
                    (copied.Complete
                     && File.ReadAllText(slot.PhysicalPath) = "working result"
                     && copied.VersionId <> promoted.VersionId)

                let reviewed = observe ()

                outputs.Apply(
                    Guid.NewGuid(),
                    reviewed.Id,
                    [ select slot.Id "result.txt" ],
                    OutputAction.Discard,
                    token
                )
                |> wait
                |> result
                |> ignore

                let next = store.Deployments.Read profile |> wait |> result

                let nextPrepared =
                    store.Deployments.Prepare(Guid.NewGuid(), next.Sources, ignore, token)
                    |> wait
                    |> result

                store.Deployments.Activate(nextPrepared.Id, nextPrepared.Sources, ignore, token)
                |> wait
                |> result
                |> ignore

                check "discardedSlotIsNotReseeded" (not (File.Exists slot.PhysicalPath))
                outputs.StopUsing(slot.Id, slot.Revision) |> wait |> result |> ignore

                let saved = store.Deployments.Read profile |> wait |> result

                let restore =
                    store.Deployments.PrepareRetained(
                        Guid.NewGuid(),
                        saved.Sources,
                        Some prepared.Id,
                        ignore,
                        token
                    )
                    |> wait
                    |> result

                store.Deployments.Activate(restore.Id, restore.Sources, ignore, token)
                |> wait
                |> result
                |> ignore

                check
                    "savedRestoreKeepsExactVersionAndCurrentStoppedDeclarations"
                    (not (File.Exists slot.PhysicalPath)
                     && File.ReadAllText(profileGameFile) = "new output")

                let final = store.Deployments.Read profile |> wait |> result

                let deactivate =
                    store.Deployments.PrepareRetained(
                        Guid.NewGuid(),
                        final.Sources,
                        None,
                        ignore,
                        token
                    )
                    |> wait
                    |> result

                store.Deployments.Activate(deactivate.Id, deactivate.Sources, ignore, token)
                |> wait
                |> result
                |> ignore

                check
                    "deactivationPreservesReviewStorage"
                    (Directory.Exists tool.PhysicalPath
                     && Directory.Exists(Path.GetDirectoryName slot.PhysicalPath))

                prepared.Id, slot.PhysicalPath

            let preparedId, slotPath = observeWritableSlot ()
            refreshSessionDiscoverySnapshot ()

            preparedId, promoted.VersionId.Value, actionId, slotPath

        do
            use reopened = new OperationStore(Path.Combine(area, "state"))
            let action = reopened.GeneratedOutputs.Action actionId |> wait |> result

            check
                "publicationResultSurvivesRestart"
                (action.Published && action.Complete && action.VersionId = Some versionId)

            let saved = reopened.Deployments.Saved(profile, None) |> wait |> result

            check
                "savedRecipeSurvivesRestart"
                (saved.Entries
                 |> List.exists (fun value ->
                     value.Id = preparedId
                     && value.CanRestore
                     && value.Profile
                        |> Option.exists (fun value -> value.Id = profile && value.EnabledMods = 1)))

            let observeRestartedSessionSnapshot () =
                let contexts = reopened.GameContexts :> IGameContexts
                let context = contexts.Read(workspace, profile) |> wait |> result

                let refused = GameProcesses.validateContext context |> Result.isError

                check "restartRequiresSessionCheck" (context.Binding.Value.NeedsCheck && refused)

                let initialized =
                    contexts.Refresh(workspace, profile, context.Revision) |> wait |> result

                check
                    "restartRefreshReadsCurrentDiscovery"
                    (not initialized.Binding.Value.NeedsCheck
                     && (not (OperatingSystem.IsLinux())
                         || initialized.Binding.Value.Evidence.Proton.Value.GlobalTool = Some
                             "next_session_tool"))

            observeRestartedSessionSnapshot ()

            let current = reopened.Deployments.Read profile |> wait |> result

            let restored =
                reopened.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    current.Sources,
                    Some preparedId,
                    ignore,
                    token
                )
                |> wait
                |> result

            reopened.Deployments.Activate(restored.Id, restored.Sources, ignore, token)
            |> wait
            |> result
            |> ignore

            check
                "restartRestoreKeepsPinsAndAbsentStoppedSlot"
                (File.ReadAllText(profileGameFile) = "new output" && not (File.Exists slotPath))

            let otherSelection = InventoryObservations.read reopened other

            check
                "restoreDoesNotChangeConfiguredProfileSelection"
                (otherSelection.Entries
                 |> List.forall (fun row ->
                     match row.Entry.Selection with
                     | SelectionState.Managed(_, false) -> true
                     | _ -> false))

            let current = reopened.Deployments.Read profile |> wait |> result

            let deactivated =
                reopened.Deployments.PrepareRetained(
                    Guid.NewGuid(),
                    current.Sources,
                    None,
                    ignore,
                    token
                )
                |> wait
                |> result

            reopened.Deployments.Activate(deactivated.Id, deactivated.Sources, ignore, token)
            |> wait
            |> result
            |> ignore

        GenerationCleanup.normalize area
        GeneratedOutputRecoveryFixtures.observe writer primary
