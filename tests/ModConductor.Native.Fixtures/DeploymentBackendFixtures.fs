namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.GameContexts
open ModConductor.FilePlanning
open ModConductor.Deployment
open ModConductor.Persistence
open ModConductor.DeploymentRecovery

module DeploymentBackendFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "backend")).FullName

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let data = Path.Combine(game, "Data")
        let mixed = Directory.CreateDirectory(Path.Combine(data, "Mixed")).FullName
        let original = Path.Combine(mixed, "Original.TXT")
        File.WriteAllText(original, "original game bytes")
        File.WriteAllText(Path.Combine(data, "untouched.txt"), "untouched")

        let source =
            Directory.CreateDirectory(Path.Combine(workspacePath, "Managed")).FullName

        let sourceMixed = Directory.CreateDirectory(Path.Combine(source, "mixed")).FullName
        File.WriteAllText(Path.Combine(sourceMixed, "original.txt"), "managed winner")
        let nested = Directory.CreateDirectory(Path.Combine(sourceMixed, "New")).FullName
        File.WriteAllText(Path.Combine(nested, "child.txt"), "managed child")

        let workspace, profile, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        use store = new OperationStore(Path.Combine(area, "state"))
        let ws = store.Workspaces :> IWorkspaceState

        let created =
            ws.Create(workspace, "Deployment backend", StorageWorker.select workspacePath)
            |> wait
            |> result

        ws.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Selected" }
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
        let selected = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, selected.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let backend = store.Deployments

        let deploymentContext () =
            let saved = (store.GameContexts :> IGameContexts).Read workspace |> wait |> result

            DeploymentContextId.create
                workspace
                (DeploymentContextId.fingerprint saved.Binding.Value.Evidence)

        let state = backend.Read profile |> wait |> result
        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()
        let cancelledId = Guid.NewGuid()

        let cancelledResult =
            backend.Prepare(cancelledId, state.Sources, ignore, cancelled.Token) |> wait

        let cancelledSafe =
            cancelledResult = Error DeploymentError.Cancelled
            && (store.Deployment.Read cancelledId |> wait).IsNone

        let stalePlan =
            backend.Prepare(Guid.NewGuid(), state.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let oldSelection = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, oldSelection.SelectionRevision, [ modId ], SelectionEdit.Enable false)
        |> wait
        |> result
        |> ignore

        let stale =
            backend.Activate(stalePlan.Id, stalePlan.Sources, ignore, CancellationToken.None)
            |> wait

        let staleSafe =
            stale = Error DeploymentError.Stale
            && (store.Deployment.Read stalePlan.Id |> wait).IsNone
            && File.ReadAllText original = "original game bytes"

        let oldSelection = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, oldSelection.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let state = backend.Read profile |> wait |> result

        let prepared =
            backend.Prepare(Guid.NewGuid(), state.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let activated =
            backend.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        writer.WriteStartObject("deploymentBackend")
        writer.WriteBoolean("cancelledPreparationNoReceipt", cancelledSafe)
        writer.WriteBoolean("stalePreparationNoEffects", staleSafe)

        writer.WriteBoolean(
            "contextDerivedTarget",
            activated.Phase = DeploymentPhase.Complete
            && File.ReadAllText original = "managed winner"
        )

        writer.WriteBoolean(
            "caseVariantSingleEntry",
            Directory.GetFiles(mixed) |> Array.map Path.GetFileName = [| "Original.TXT" |]
        )

        writer.WriteBoolean(
            "missingParentCreated",
            File.ReadAllText(Path.Combine(mixed, "New", "child.txt")) = "managed child"
        )

        let beforeEvidence =
            (store.GameContexts :> IGameContexts).Read workspace |> wait |> result

        let ownedContext = deploymentContext ()
        GameContextFixtures.create game 105

        if OperatingSystem.IsLinux() then
            File.AppendAllText(
                Path.Combine(proton.CompatData, "pfx", "user.reg"),
                "\n[Software\\FixtureRefresh]\n\"Unrelated\"=\"changed\"\n"
            )

        let refreshed =
            (store.GameContexts :> IGameContexts).Refresh(workspace, beforeEvidence.Revision)
            |> wait
            |> result

        writer.WriteBoolean(
            "refreshedEvidenceKeepsTargetOwnership",
            refreshed.Binding.Value.Evidence.Fingerprint
            <> beforeEvidence.Binding.Value.Evidence.Fingerprint
            && deploymentContext () = ownedContext
            && (store.Deployment.Context ownedContext |> wait).Value.Active.IsSome
        )

        let plans = store.FilePlans :> IFilePlans

        let loaded =
            plans.Acquire(profile, false, ignore, CancellationToken.None) |> wait |> result

        let inspected =
            plans.Inspect(loaded.Id, path "mixed/original.txt", None) |> wait |> result

        writer.WriteBoolean("activeReaderReconstructsBase", inspected.Copies.Length = 2)

        let generation =
            (store.Deployment.Context(deploymentContext ()) |> wait).Value.Active.Value

        let current = backend.Read profile |> wait |> result

        let baseline =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                None,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        let restored =
            backend.Activate(baseline.Id, baseline.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        writer.WriteBoolean(
            "originalRestored",
            restored.Phase = DeploymentPhase.Complete
            && File.ReadAllText original = "original game bytes"
        )

        writer.WriteBoolean(
            "ownedParentRemoved",
            not (Directory.Exists(Path.Combine(mixed, "New")))
        )

        writer.WriteBoolean(
            "unrelatedBasePreserved",
            File.ReadAllText(Path.Combine(data, "untouched.txt")) = "untouched"
        )

        let current = backend.Read profile |> wait |> result

        let old =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                Some generation,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        let rollback =
            backend.Activate(old.Id, old.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        writer.WriteBoolean(
            "retainedGenerationReactivated",
            rollback.Phase = DeploymentPhase.Complete
            && File.ReadAllText original = "managed winner"
        )

        let current = backend.Read profile |> wait |> result

        let final =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                None,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        backend.Activate(final.Id, final.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let current = backend.Read profile |> wait |> result

        let old =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                Some generation,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        backend.Activate(old.Id, old.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let context = (store.Deployment.Context(deploymentContext ()) |> wait).Value

        let baseGeneration =
            (store.Deployment.Generation(deploymentContext (), final.Id) |> wait).Value

        let request id selected : SwitchRequest =
            { Id = id
              ContextId = deploymentContext ()
              ContextFingerprint = context.Fingerprint
              ExpectedRevision =
                (store.Deployment.Context(deploymentContext ()) |> wait).Value.Revision
              Roots = context.Roots
              Generation = selected
              DirectoryBoundaries = []
              PreserveOriginals = context.Originals |> List.map _.Target
              ExpectedSources = Some((backend.Read profile |> wait |> result).Sources) }

        let cleared =
            store.Generations.Start(request (Guid.NewGuid()) baseGeneration, [])
            |> wait
            |> result

        store.Generations.Run(
            cleared.Id,
            cleared.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> result
        |> ignore

        let leafGeneration =
            (store.Deployment.Generation(deploymentContext (), old.Id) |> wait).Value

        let leafRequest = request (Guid.NewGuid()) leafGeneration
        let leafReceipt = store.Generations.Start(leafRequest, []) |> wait |> result

        store.Generations.Run(
            leafReceipt.Id,
            leafReceipt.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> result
        |> ignore

        let removing =
            store.Generations.Start(request (Guid.NewGuid()) baseGeneration, [])
            |> wait
            |> result

        let interrupted =
            store.Generations.Run(
                removing.Id,
                removing.Revision,
                false,
                CancellationToken.None,
                (fun name _ ->
                    if name = "parent-removed" then
                        raise (OperationCanceledException())),
                []
            )
            |> wait

        let pending = (store.Deployment.Read removing.Id |> wait).Value

        writer.WriteBoolean(
            "removedParentInterruptionRecorded",
            Result.isError interrupted
            && pending.Phase = ReceiptPhase.Blocked
            && not (Directory.Exists(Path.Combine(mixed, "New")))
        )

        let unavailable =
            plans.Acquire(profile, false, ignore, CancellationToken.None) |> wait

        writer.WriteBoolean("pendingReaderUnavailable", (unavailable = Error FilePlanError.Blocked))

        let resumed =
            backend.Recover(pending.Id, pending.Revision, true, ignore, CancellationToken.None)
            |> wait
            |> result

        writer.WriteBoolean(
            "removedParentRestored",
            resumed.Phase = DeploymentPhase.Restored
            && File.ReadAllText(Path.Combine(mixed, "New", "child.txt")) = "managed child"
        )

        let current = backend.Read profile |> wait |> result

        let finalBase =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                None,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        backend.Activate(finalBase.Id, finalBase.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let oldGeneration =
            (store.Deployment.Generation(deploymentContext (), generation) |> wait).Value

        let creating =
            store.Generations.Start(request (Guid.NewGuid()) oldGeneration, [])
            |> wait
            |> result

        let interrupted =
            store.Generations.Run(
                creating.Id,
                creating.Revision,
                false,
                CancellationToken.None,
                (fun name _ ->
                    if name = "parent-created" then
                        raise (OperationCanceledException())),
                []
            )
            |> wait

        let pending = (store.Deployment.Read creating.Id |> wait).Value
        let unrecorded = DeploymentFixtureData.location (Path.Combine(mixed, "New"))

        let refused =
            backend.Recover(pending.Id, pending.Revision, false, ignore, CancellationToken.None)
            |> wait

        writer.WriteBoolean(
            "unknownCreatedParentRefused",
            Result.isError interrupted
            && Result.isError refused
            && (DeploymentFixtureData.location (Path.Combine(mixed, "New"))).Identity = unrecorded.Identity
        )
        // The fixture acts as the operator after proving the untouched manual-review outcome.
        Directory.Delete(Path.Combine(mixed, "New"), false)
        let pending = (store.Deployment.Read creating.Id |> wait).Value

        backend.Recover(pending.Id, pending.Revision, false, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let current = backend.Read profile |> wait |> result

        let cleanup =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                None,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        backend.Activate(cleanup.Id, cleanup.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let contexts = store.GameContexts :> IGameContexts

        let originalSelection =
            { Path = game
              Proton = if OperatingSystem.IsLinux() then Some proton else None }

        let replacementGame, replacementProton =
            ProtonFixtures.create (Path.Combine(area, "replacement-game"))

        let replacementSelection =
            { Path = replacementGame
              Proton =
                if OperatingSystem.IsLinux() then
                    Some replacementProton
                else
                    None }

        let select selection =
            let saved = contexts.Read workspace |> wait |> result
            contexts.Save(workspace, saved.Revision, selection) |> wait |> result |> ignore

        let originalContext = deploymentContext ()
        select replacementSelection
        let replacementContext = deploymentContext ()
        let current = backend.Read profile |> wait |> result

        let newPlan =
            backend.Prepare(Guid.NewGuid(), current.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        backend.Activate(newPlan.Id, newPlan.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        writer.WriteBoolean(
            "newInstallationAfterDeactivation",
            replacementContext <> originalContext
            && File.ReadAllText(Path.Combine(replacementGame, "Data", "mixed", "original.txt")) = "managed winner"
        )

        let oldReceiptRefused =
            backend.Recover(activated.Id, activated.Revision, true, ignore, CancellationToken.None)
            |> wait

        writer.WriteBoolean(
            "oldReceiptCannotRetarget",
            (oldReceiptRefused = Error DeploymentError.Stale)
        )

        select originalSelection
        let current = backend.Read profile |> wait |> result

        let blockedPlan =
            backend.Prepare(Guid.NewGuid(), current.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let blocked =
            backend.Activate(blockedPlan.Id, blockedPlan.Sources, ignore, CancellationToken.None)
            |> wait

        writer.WriteBoolean(
            "otherActiveContextRefused",
            (blocked = Error DeploymentError.Busy
             && (store.Deployment.Read blockedPlan.Id |> wait).IsNone
             && File.ReadAllText original = "original game bytes")
        )

        select replacementSelection
        let current = backend.Read profile |> wait |> result

        let basePlan =
            backend.PrepareRetained(
                Guid.NewGuid(),
                current.Sources,
                None,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        backend.Activate(basePlan.Id, basePlan.Sources, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        select originalSelection
        let originalContextState = (store.Deployment.Context originalContext |> wait).Value

        let pendingRequest =
            { request (Guid.NewGuid()) oldGeneration with
                Roots = originalContextState.Roots
                ExpectedRevision = originalContextState.Revision }

        let pending = store.Generations.Start(pendingRequest, []) |> wait |> result
        select replacementSelection
        let current = backend.Read profile |> wait |> result

        let pendingPlan =
            backend.Prepare(Guid.NewGuid(), current.Sources, ignore, CancellationToken.None)
            |> wait
            |> result

        let pendingRefused =
            backend.Activate(pendingPlan.Id, pendingPlan.Sources, ignore, CancellationToken.None)
            |> wait

        writer.WriteBoolean(
            "otherPendingContextRefused",
            (pendingRefused = Error DeploymentError.Busy
             && (store.Deployment.Read pendingPlan.Id |> wait).IsNone)
        )

        select originalSelection

        backend.Recover(pending.Id, pending.Revision, true, ignore, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        writer.WriteBoolean(
            "sourceBytesPreserved",
            File.ReadAllText(Path.Combine(sourceMixed, "original.txt")) = "managed winner"
            && File.ReadAllText(Path.Combine(nested, "child.txt")) = "managed child"
        )

        writer.WriteEndObject()
        GenerationCleanup.normalize area
