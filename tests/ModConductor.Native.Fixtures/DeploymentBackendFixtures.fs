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
open ModConductor.Engine
open ModConductor.Persistence

module DeploymentBackendFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "backend")).FullName
        let workspacePath = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game"))
        let original = Path.Combine(game, "Data", "Mixed", "Original.TXT")
        Directory.CreateDirectory(Path.GetDirectoryName original) |> ignore
        File.WriteAllText(original, "original game bytes")
        let source = Directory.CreateDirectory(Path.Combine(workspacePath, "Managed")).FullName
        let mixedSource = Directory.CreateDirectory(Path.Combine(source, "mixed")).FullName
        File.WriteAllText(Path.Combine(mixedSource, "original.txt"), "managed winner")
        let nestedSource = Directory.CreateDirectory(Path.Combine(mixedSource, "New")).FullName
        File.WriteAllText(Path.Combine(nestedSource, "child.txt"), "managed child")

        let workspace, profile, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        use store = new OperationStore(Path.Combine(area, "state"))
        let workspaces = store.Workspaces :> IWorkspaceState
        let created =
            workspaces.Create(workspace, "Deployment backend", StorageWorker.select workspacePath)
            |> wait |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Selected" }
        )
        |> wait |> result |> ignore

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
            |> wait |> result

        library.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
        let selected = InventoryObservations.read store profile

        (store.ModSelection :> IModSelection)
            .Change(profile, selected.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait |> result |> ignore

        let contexts = store.GameContexts :> IGameContexts
        let selection source runtime =
            { GameId = GameId.SkyrimSpecialEditionSteam
              Path = source
              Proton = if OperatingSystem.IsLinux() then Some runtime else None }

        contexts.Save(workspace, profile, 0L, selection game proton)
        |> wait |> result |> ignore

        let backend = store.Deployments
        let state = backend.Read profile |> wait |> result
        let view = state.RunnableRoot
        let viewOriginal = Path.Combine(view, "Data", "Mixed", "Original.TXT")
        let viewChild = Path.Combine(view, "Data", "Mixed", "New", "child.txt")

        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()
        let cancelledId = Guid.NewGuid()
        let cancelledResult =
            backend.Prepare(cancelledId, state.Sources, ignore, cancelled.Token) |> wait

        let cancelledSafe =
            cancelledResult = Error DeploymentError.Cancelled
            && (store.Deployment.Read cancelledId |> wait).IsNone
            && File.ReadAllText original = "original game bytes"

        let stalePlan =
            backend.Prepare(Guid.NewGuid(), state.Sources, ignore, CancellationToken.None)
            |> wait |> result

        let oldSelection = InventoryObservations.read store profile
        (store.ModSelection :> IModSelection)
            .Change(profile, oldSelection.SelectionRevision, [ modId ], SelectionEdit.Enable false)
        |> wait |> result |> ignore

        let stale =
            backend.Activate(stalePlan.Id, stalePlan.Sources, ignore, CancellationToken.None)
            |> wait

        let staleSafe =
            stale = Error DeploymentError.Stale
            && File.ReadAllText original = "original game bytes"
            && not (Directory.Exists(
                Path.Combine(
                    workspacePath,
                    ".mc-generation-" + stalePlan.Id.ToString("N")
                )
            ))

        let oldSelection = InventoryObservations.read store profile
        (store.ModSelection :> IModSelection)
            .Change(profile, oldSelection.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait |> result |> ignore

        let deploy () =
            let state = backend.Read profile |> wait |> result
            let prepared =
                backend.Prepare(Guid.NewGuid(), state.Sources, ignore, CancellationToken.None)
                |> wait |> result
            backend.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
            |> wait |> result

        let active = deploy ()
        let viewHasManaged =
            active.Phase = DeploymentPhase.Complete
            && File.ReadAllText(viewOriginal) = "managed winner"
            && File.ReadAllText viewChild = "managed child"
            && File.ReadAllText original = "original game bytes"

        let plans = store.FilePlans :> IFilePlans
        let loaded = plans.Acquire(profile, false, ignore, CancellationToken.None) |> wait |> result
        let inspected = plans.Inspect(loaded.Id, path "mixed/original.txt", None) |> wait |> result
        let sourceInventoryUnaffected = inspected.Copies.Length = 2

        let generation =
            (backend.Read profile |> wait |> result).ActiveGeneration.Value

        let evidence =
            (contexts.Read(workspace, profile) |> wait |> result).Binding.Value.Evidence

        let contextId =
            DeploymentContextId.create workspace profile (DeploymentContextId.fingerprint evidence)

        let originalTree =
            (store.Deployment.Generation(contextId, generation) |> wait).Value.Directory.Path
            |> HostPath.value

        let retained target =
            let current = backend.Read profile |> wait |> result
            let prepared =
                backend.PrepareRetained(
                    Guid.NewGuid(), current.Sources, target, ignore, CancellationToken.None
                )
                |> wait |> result
            backend.Activate(prepared.Id, prepared.Sources, ignore, CancellationToken.None)
            |> wait |> result

        let baseline = retained None
        let baselineRestored =
            baseline.Phase = DeploymentPhase.Complete
            && File.ReadAllText viewOriginal = "original game bytes"
            && not (File.Exists viewChild)
            && File.ReadAllText original = "original game bytes"
            && not (Directory.Exists originalTree)

        let rollback = retained (Some generation)
        let retainedReactivated =
            rollback.Phase = DeploymentPhase.Complete
            && File.ReadAllText viewOriginal = "managed winner"
            && File.ReadAllText viewChild = "managed child"

        let replacement, replacementProton =
            ProtonFixtures.create (Path.Combine(area, "replacement-game"))

        let replacementOriginal = Path.Combine(replacement, "Data", "Mixed", "Original.TXT")
        Directory.CreateDirectory(Path.GetDirectoryName replacementOriginal) |> ignore
        File.WriteAllText(replacementOriginal, "replacement game bytes")
        let current = contexts.Read(workspace, profile) |> wait |> result
        contexts.Save(workspace, profile, current.Revision, selection replacement replacementProton)
        |> wait |> result |> ignore

        let oldReceipt = store.Deployment.Read rollback.Id |> wait

        let reboundRecovery =
            backend.Recover(
                rollback.Id,
                rollback.Revision,
                true,
                ignore,
                CancellationToken.None
            )
            |> wait

        let reboundRefusedWithoutEffects =
            oldReceipt.IsSome
            && reboundRecovery = Error DeploymentError.NotFound
            && (store.Deployment.Read rollback.Id |> wait) = oldReceipt
            && File.ReadAllText viewOriginal = "managed winner"
            && File.ReadAllText original = "original game bytes"

        let changed = deploy ()
        let sourceChangeRetiresPriorView =
            changed.Phase = DeploymentPhase.Complete
            && File.ReadAllText viewOriginal = "managed winner"
            && File.ReadAllText original = "original game bytes"
            && File.ReadAllText replacementOriginal = "replacement game bytes"

        let admission = DeploymentBackendState()
        let first, second, third = Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()
        let initiallyDrained = admission.Drain().IsCompleted
        let firstLease = admission.TryAcquireWorkspace first |> Option.get
        let secondLease = admission.TryAcquireWorkspace second |> Option.get
        let pending = admission.Drain()
        let rejectsOverlap =
            admission.TryAcquireWorkspace first |> Option.isNone
            && admission.TryAcquireWorkspace third |> Option.isNone
            && not (admission.TryClose(fun () -> true))

        firstLease.Dispose()
        firstLease.Dispose()
        let stillActive = not pending.IsCompleted
        secondLease.Dispose()
        let backendLeaseDrainsBeforeClose =
            initiallyDrained
            && rejectsOverlap
            && stillActive
            && pending.IsCompleted
            && admission.TryClose(fun () -> true)
            && (admission.TryAcquireWorkspace third |> Option.isNone)

        let installed =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = modId)

        let affected =
            store.Deletions.ActiveProfiles(workspace, modId, installed.Revision)
            |> wait
            |> result

        let deletion = DeletionService(store.Deletions, backend)

        deletion.DeleteMod(
            ModConductor.Protocol.V1.DeleteModRequest(
                WorkspaceId = workspace.ToString("N"),
                ModId = modId.ToString("N"),
                Revision = uint64 installed.Revision
            ),
            WatchCountFixtures.StreamContext(CancellationToken.None)
        )
        |> wait
        |> ignore

        let afterDeletion = backend.Read profile |> wait |> result

        let affectedProfileUndeployed =
            affected |> List.exists (fun (id, _) -> id = profile)
            && (afterDeletion.Active
                |> Option.exists (fun value -> value.Known && value.Profile.IsNone))
            && File.ReadAllText(
                Path.Combine(afterDeletion.RunnableRoot, "Data", "Mixed", "Original.TXT")
            ) = "replacement game bytes"
            && File.ReadAllText replacementOriginal = "replacement game bytes"
            && ((library.Scan(workspace, 100) |> wait |> result).Entries
                |> List.forall (fun entry -> entry.Id <> modId))

        writer.WriteStartObject("deploymentBackend")
        writer.WriteBoolean("cancelledPreparationNoReceipt", cancelledSafe)
        writer.WriteBoolean("stalePreparationNoEffects", staleSafe)
        writer.WriteBoolean("abandonedLinkTreeReclaimed", staleSafe)
        writer.WriteBoolean("profileViewContainsManagedWinner", viewHasManaged)
        writer.WriteBoolean("sourceInventoryUnaffected", sourceInventoryUnaffected)
        writer.WriteBoolean("retainedBaselineUsesOriginalSource", baselineRestored)
        writer.WriteBoolean("retiredLinkTreeReclaimed", not (Directory.Exists originalTree))
        writer.WriteBoolean("retainedGenerationReactivated", retainedReactivated)
        writer.WriteBoolean("sourceChangeRetiresPriorView", sourceChangeRetiresPriorView)
        writer.WriteBoolean("reboundRecoveryRefusedWithoutEffects", reboundRefusedWithoutEffects && changed.Phase = DeploymentPhase.Complete)
        writer.WriteBoolean("backendLeaseDrainsBeforeClose", backendLeaseDrainsBeforeClose)
        writer.WriteBoolean("deletingActiveModUndeploysAffectedProfile", affectedProfileUndeployed)
        writer.WriteEndObject()
