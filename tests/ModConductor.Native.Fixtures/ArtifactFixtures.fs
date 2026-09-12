namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Text.Json
open System.Threading
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module ArtifactFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private reference (a: Artifact) : ArtifactRef =
        { WorkspaceId = a.WorkspaceId
          Id = a.Id
          Revision = a.Revision }

    let private mkdir path =
        Directory.CreateDirectory(path).FullName

    let private metadata name =
        { Name = name
          Version = "1.0"
          Notes = ""
          Comment = ""
          Source = ""
          Categories = [] }

    let worker state (workspace: string) (id: string) path checkpoint =
        use store = new OperationStore(state)

        store.AddArtifactAtCheckpoint(
            { WorkspaceId = Guid.Parse workspace
              Id = Guid.Parse id
              Path = path
              Storage = ArtifactStorage.Copy },
            token,
            fun name ->
                if name = checkpoint then
                    StorageWorker.pause ()
        )
        |> wait
        |> result
        |> ignore

    let observe (writer: Utf8JsonWriter) primary =
        let check (name: string) condition =
            writer.WriteBoolean(name, condition)

            if not condition then
                invalidOp ("Artifact fixture failed: " + name)

        writer.WriteStartObject("artifacts")
        let area = mkdir (Path.Combine(primary, "artifacts"))
        let state = mkdir (Path.Combine(area, "state"))
        let root = mkdir (Path.Combine(area, "workspace"))
        let outside = mkdir (Path.Combine(area, "originals"))
        let path = Path.Combine(outside, "Textures — rivière.zip")
        let moved = Path.Combine(outside, "renamed archive.7z")
        let bad = Path.Combine(outside, "different.zip")
        File.WriteAllBytes(path, Array.init 150000 (fun n -> byte (n % 251)))
        File.WriteAllText(bad, "different")
        let original = File.ReadAllBytes(path)

        let workspace, other, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let referenced, copied = Guid.NewGuid(), Guid.NewGuid()

        do
            use store = new OperationStore(state)

            (store.Workspaces :> IWorkspaceState)
                .Create(workspace, "Archive fixture", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

            let source = mkdir (Path.Combine(root, "mod"))
            File.WriteAllText(Path.Combine(source, "file.txt"), "mod data")
            let mods = store.ModLibrary :> IModLibrary

            let modEntry =
                mods.Register(
                    workspace,
                    modId,
                    metadata "Original name",
                    Registration.Directory(ModKind.Regular, LogicalPath.create [ "mod" ] |> result)
                )
                |> wait
                |> result

            let published = mods.Publish(modId, modEntry.Revision, version) |> wait |> result

            let a =
                store.Artifacts.Add(
                    { Id = referenced
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Reference },
                    token
                )
                |> wait
                |> result

            let b =
                store.Artifacts.Add(
                    { Id = copied
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Copy },
                    token
                )
                |> wait
                |> result

            check
                "sameNameAndContentRemainDistinct"
                (a.Id <> b.Id && a.OriginalName = b.OriginalName && a.Sha256 = b.Sha256)

            check
                "adoptionPreservesOriginalBytes"
                (File.ReadAllBytes(path) = original && a.Path = path && b.Path <> path)

            let replay =
                store.Artifacts.Add(
                    { Id = referenced
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Reference },
                    token
                )
                |> wait
                |> result

            check
                "registrationReplayKeepsIdentity"
                (replay.Id = a.Id && replay.Revision = a.Revision)

            let linked =
                store.Artifacts.Link(reference a, modId, version, false) |> wait |> result

            store.Artifacts.Link(reference b, modId, version, false)
            |> wait
            |> result
            |> ignore

            check
                "linkedMetadataCannotBeRemoved"
                (store.Artifacts.Remove(reference linked) |> wait = Error ArtifactError.Linked)

            check
                "staleProvenanceCannotOverwrite"
                (store.Artifacts.Link(reference a, modId, version, true) |> wait = Error
                    ArtifactError.Stale)

            mods.Edit(modId, published.Revision, metadata "Renamed mod")
            |> wait
            |> result
            |> ignore

            let root2 = mkdir (Path.Combine(area, "other-workspace"))

            (store.Workspaces :> IWorkspaceState).Create(other, "Other", StorageWorker.select root2)
            |> wait
            |> result
            |> ignore

            let foreign =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = other
                      Path = path
                      Storage = ArtifactStorage.Reference },
                    token
                )
                |> wait
                |> result

            check
                "provenanceCannotCrossWorkspace"
                (store.Artifacts.Link(reference foreign, modId, version, false) |> wait = Error
                    ArtifactError.InvalidLink)

        File.Move(path, moved)

        do
            use store = new OperationStore(state)
            let firstRead = store.Artifacts.Read(workspace, referenced) |> wait |> result

            check
                "firstReadReconcilesMissingReference"
                (firstRead.State = ArtifactState.Detached
                 && firstRead.Links.Head.VersionId = version)

            let page = store.Artifacts.List(workspace, None, false, token) |> wait |> result
            let detached = page.Entries |> List.find (fun a -> a.Id = referenced)

            check
                "restartRetainsDetachedIdentityAndProvenance"
                (detached.State = ArtifactState.Detached
                 && detached.OriginalName = "Textures — rivière.zip"
                 && detached.OriginalPath = path
                 && detached.Links.Head.VersionId = version
                 && detached.Links.Head.ModName = "Renamed mod")

            check
                "wrongLocatePreservesProvenance"
                (store.Artifacts.Locate(reference detached, bad, token) |> wait = Error
                    ArtifactError.Unavailable
                 && (store.Artifacts.Read(workspace, referenced) |> wait |> result).Path = path)

            let located =
                store.Artifacts.Locate(reference detached, moved, token) |> wait |> result

            check
                "locateChangesOnlyPathAndObservation"
                (located.Id = referenced
                 && located.OriginalPath = path
                 && located.Path = moved
                 && located.State = ArtifactState.Installed
                 && located.Links.Head.VersionId = version)

            let copy = store.Artifacts.Read(workspace, copied) |> wait |> result
            let deleted = store.Artifacts.DeleteCopy(reference copy) |> wait |> result

            check
                "explicitCopyCleanupKeepsLinksWithoutFalseReady"
                (not (File.Exists copy.Path)
                 && deleted.State = ArtifactState.Detached
                 && deleted.Links.Length = 1
                 && File.ReadAllBytes(moved) = original)

        do
            use store = new OperationStore(state)
            let page = store.Artifacts.List(workspace, None, false, token) |> wait |> result
            let copy = page.Entries |> List.find (fun a -> a.Id = copied)

            check
                "restartDoesNotPromoteDetachedLinkedCopy"
                (copy.State = ArtifactState.Detached && copy.Links.Length = 1)

            let unlinked =
                store.Artifacts.Link(reference copy, modId, version, true) |> wait |> result

            store.Artifacts.Remove(reference unlinked) |> wait |> result
            let a = store.Artifacts.Read(workspace, referenced) |> wait |> result

            let unlinked =
                store.Artifacts.Link(reference a, modId, version, true) |> wait |> result

            store.Artifacts.Remove(reference unlinked) |> wait |> result

            let removed = store.Artifacts.Read(workspace, referenced) |> wait

            check
                "explicitReferenceCleanupNeverDeletesOriginal"
                (File.ReadAllBytes(moved) = original && removed = Error ArtifactError.NotFound)

        do
            let emptyState = mkdir (Path.Combine(area, "empty-state"))
            let emptyRoot = mkdir (Path.Combine(area, "empty-workspace"))
            let emptyWorkspace, id = Guid.NewGuid(), Guid.NewGuid()
            use store = new OperationStore(emptyState)

            (store.Workspaces :> IWorkspaceState)
                .Create(emptyWorkspace, "Empty", StorageWorker.select emptyRoot)
            |> wait
            |> result
            |> ignore

            check
                "failedCopyAdmissionIsRetained"
                (store.Artifacts.Add(
                    { Id = id
                      WorkspaceId = emptyWorkspace
                      Path = Path.Combine(area, "missing.zip")
                      Storage = ArtifactStorage.Copy },
                    token
                 )
                 |> wait = Error ArtifactError.Unavailable)

            let incomplete =
                (store.Artifacts.List(emptyWorkspace, None, false, token) |> wait |> result).Entries
                |> List.exactlyOne

            check "earlyFailureRemainsIncomplete" (incomplete.State = ArtifactState.Incomplete)
            let cleaned = store.Artifacts.DeleteCopy(reference incomplete) |> wait |> result
            store.Artifacts.Remove(reference cleaned) |> wait |> result

            check
                "earlyFailureAllowsExplicitCleanup"
                ((store.Artifacts.List(emptyWorkspace, None, true, token) |> wait |> result)
                    .Entries.IsEmpty)

        writer.WriteStartArray("restartWindows")

        for checkpoint in [ "stage"; "bytes"; "observed"; "final"; "committed"; "collision" ] do
            let area = mkdir (Path.Combine(primary, "artifact-" + checkpoint))
            let state = mkdir (Path.Combine(area, "state"))
            let root = mkdir (Path.Combine(area, "workspace"))
            let source = Path.Combine(area, "original.zip")
            File.WriteAllBytes(source, original)
            let workspace, id = Guid.NewGuid(), Guid.NewGuid()

            do
                use store = new OperationStore(state)

                (store.Workspaces :> IWorkspaceState)
                    .Create(workspace, "Interruption", StorageWorker.select root)
                |> wait
                |> result
                |> ignore

            use child =
                new NativeChild(
                    Environment.ProcessPath,
                    [ "--artifact-worker"
                      state
                      string workspace
                      string id
                      source
                      if checkpoint = "collision" then "observed" else checkpoint ]
                )

            child.Line() |> ignore
            // Recovery must not claim another live owner's accepted copy.
            do
                use observer = new OperationStore(state)
                let pending = observer.Artifacts.Read(workspace, id) |> wait |> result

                if checkpoint <> "committed" then
                    if pending.State <> ArtifactState.Incomplete then
                        invalidOp "A pending copy was ready."

                    if
                        observer.Artifacts.Retry(reference pending, token) |> wait
                        <> Error ArtifactError.Busy
                    then
                        invalidOp "A live copy was claimed."

            child.Terminate()

            let final =
                Directory.GetDirectories(root, ".mod-conductor-library-*")
                |> Array.exactlyOne
                |> fun folder -> Path.Combine(folder, ArtifactFiles.final id)

            if checkpoint = "collision" then
                File.WriteAllText(final, "occupied destination")

            use restarted = new OperationStore(state)

            let a =
                (restarted.Artifacts.List(workspace, None, false, token) |> wait |> result).Entries
                |> List.exactlyOne

            writer.WriteStartObject()
            writer.WriteString("checkpoint", checkpoint)

            if checkpoint = "stage" || checkpoint = "bytes" then
                check "incompleteNotReady" (a.State = ArtifactState.Incomplete)
                let retried = restarted.Artifacts.Retry(reference a, token) |> wait |> result

                check
                    "explicitRetryCompletesSameId"
                    (retried.Id = id
                     && retried.State = ArtifactState.Ready
                     && File.ReadAllBytes(retried.Path) = original)
            elif checkpoint = "collision" then
                check
                    "occupiedFinalIsNotOverwrittenOrReady"
                    (a.State = ArtifactState.Incomplete
                     && File.ReadAllText(final) = "occupied destination")

                File.Delete final
                File.WriteAllBytes(source, Array.zeroCreate original.Length)

                check
                    "retryRejectsChangedObservedSource"
                    (restarted.Artifacts.Retry(reference a, token) |> wait = Error
                        ArtifactError.Unavailable
                     && (restarted.Artifacts.Read(workspace, id) |> wait |> result).Sha256 = a.Sha256)

                File.WriteAllBytes(source, original)
            else
                check
                    "completeObservedBytesRecover"
                    (a.State = ArtifactState.Ready && File.ReadAllBytes(a.Path) = original)

            check "sourceSurvivesInterruption" (File.ReadAllBytes(source) = original)
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()
