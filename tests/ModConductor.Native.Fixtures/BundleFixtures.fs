namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.BundleInstallation
open ModConductor.ArtifactLibrary
open ModConductor.ArchiveInstallation
open ModConductor.ModLibrary
open ModConductor.ModMaintenance
open ModConductor.Platform
open ModConductor.Persistence
open ModConductor.Workspaces

module BundleFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None

    let private zip (entries: (string * byte array) list) =
        use bytes = new MemoryStream()

        do
            use archive = new ZipArchive(bytes, ZipArchiveMode.Create, true)

            for name, data in entries do
                use entry = archive.CreateEntry(name).Open()
                entry.Write(data)

        bytes.ToArray()

    let private bytes (value: string) = Encoding.UTF8.GetBytes value

    let create area =
        Directory.CreateDirectory area |> ignore
        let leaf = zip [ "Data/textures/water.dds", bytes "selected water bytes" ]

        let xml =
            zip
                [ "fomod/ModuleConfig.xml",
                  bytes
                      "<config><moduleName>XML mod</moduleName><requiredInstallFiles><file source='Data/textures/road.dds' destination='textures/road.dds'/></requiredInstallFiles></config>"
                  "Data/textures/road.dds", bytes "road" ]

        let extras = zip [ "Second.zip", leaf; "XML.zip", xml ]

        File.WriteAllBytes(
            Path.Combine(area, "Weekend collection.zip"),
            zip [ "First.zip", leaf; "Extras.zip", extras ]
        )

    let private reference (artifact: Artifact) : ArtifactRef =
        { WorkspaceId = artifact.WorkspaceId
          Id = artifact.Id
          Revision = artifact.Revision }

    let private finished (store: OperationStore) workspace id =
        let mutable value = store.Installations.Read(workspace, id) |> wait
        let until = DateTime.UtcNow.AddSeconds 20

        while value.State = InstallationState.Running && DateTime.UtcNow < until do
            Thread.Sleep 10
            value <- store.Installations.Read(workspace, id) |> wait

        if value.State = InstallationState.Running then
            failwith "Bundle fixture installation did not stop."

        value

    let worker state (workspace: string) (bundleId: string) =
        use store = new OperationStore(state)
        let workspace, bundleId = Guid.Parse workspace, Guid.Parse bundleId
        let bundle = store.Bundles.Read(workspace, bundleId) |> wait |> result

        let prepared =
            store.Bundles.Prepare(bundle.Reference, bundle.Mods.Head.Id, token)
            |> wait
            |> result

        store.Installations.StartAtCheckpoint(
            workspace,
            prepared.Draft.Id,
            prepared.Draft.Revision,
            Guid.NewGuid(),
            fun point ->
                if point = "after-publication" then
                    StorageWorker.pause ()
        )
        |> result
        |> ignore

        Thread.Sleep Timeout.Infinite

    let private processLoss (writer: Utf8JsonWriter) area =
        let area =
            Directory.CreateDirectory(Path.Combine(area, "publication-loss")).FullName

        create area
        let state = Path.Combine(area, "state")
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspace = Guid.NewGuid()

        let bundleId, modId =
            use store = new OperationStore(state)

            (store.Workspaces :> IWorkspaceState)
                .Create(workspace, "Publication window", StorageWorker.select root)
            |> wait
            |> result
            |> ignore

            let artifact =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = Path.Combine(area, "Weekend collection.zip")
                      Storage = ArtifactStorage.Copy },
                    token
                )
                |> wait
                |> result

            let view = store.Bundles.Discover(reference artifact, token) |> wait |> result

            let bundle =
                store.Bundles.Create(
                    workspace,
                    view.Draft.Id,
                    view.Draft.Revision,
                    [ (view.Archives
                       |> List.find (fun a -> LogicalPath.display a.Path = "First.zip"))
                          .Index ]
                )
                |> result

            bundle.Reference.Id, bundle.Mods.Head.ModId

        use child =
            new NativeChild(
                Environment.ProcessPath,
                [ "--bundle-worker"; state; string workspace; string bundleId ]
            )

        if child.Line() <> "ready" then
            failwith "Bundle child did not reach the publication checkpoint."

        child.Terminate()
        use store = new OperationStore(state)
        let bundle = store.Bundles.Read(workspace, bundleId) |> wait |> result
        let item = bundle.Mods.Head
        let before = store.Bundles.Status(workspace, bundleId, item.Id) |> wait |> result
        let retried = store.Bundles.Retry(bundle.Reference, item.Id) |> wait |> result
        let after = store.Bundles.Status(workspace, bundleId, item.Id) |> wait |> result

        let inventory =
            (store.ModLibrary :> IModLibrary).Scan(workspace, 100) |> wait |> result

        let passed =
            item.State = ModState.Installed
            && before.State = InstallationState.Complete
            && before.Id = after.Id
            && before.VersionId = after.VersionId
            && (inventory.Entries |> List.filter (fun m -> m.Id = modId)).Length = 1

        writer.WriteBoolean(
            "ProcessLossAfterPublicationKeepsOneCommittedChildWithoutRestartWork",
            passed
        )

        if not passed then
            failwith "Bundle publication process-loss observation failed."

        let target = inventory.Entries |> List.find (fun m -> m.Id = modId)

        store.Deletions.Delete(workspace, target.Id, target.Revision) |> wait

        let passed =
            (store.Bundles.Find(workspace, bundle.Artifact.Id) |> wait |> result).IsNone
            && Directory.GetFiles(root, "bundle-*.archive", SearchOption.AllDirectories).Length = 0
            && (store.Artifacts.Read(workspace, bundle.Artifact.Id) |> wait) = Error
                ArtifactError.NotFound
            && File.Exists(Path.Combine(area, "Weekend collection.zip"))

        writer.WriteBoolean(
            "DeletingLastChildRemovesExclusiveBundleAndParentCopyWithoutTombstones",
            passed
        )

        if not passed then
            failwith "Last bundle child deletion closure failed."

    let observe (writer: Utf8JsonWriter) area =
        create area

        let check name value =
            writer.WriteBoolean((name: string), value)

            if not value then
                failwith ("Bundle fixture failed: " + name)

        writer.WriteStartObject("bundles")
        processLoss writer area
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let state = Path.Combine(area, "state")
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let original = File.ReadAllBytes(Path.Combine(area, "Weekend collection.zip"))

        let phaseOne () =
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState

            let created =
                workspaces.Create(workspace, "Bundle fixture", StorageWorker.select root)
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = profile; Name = "Everyday" }
            )
            |> wait
            |> result
            |> ignore

            let artifact =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = Path.Combine(area, "Weekend collection.zip")
                      Storage = ArtifactStorage.Copy },
                    token
                )
                |> wait
                |> result

            let discovered = store.Bundles.Discover(reference artifact, token) |> wait |> result

            let order =
                [ "First.zip"; "Extras.zip" ]
                |> List.map (fun name ->
                    (discovered.Archives |> List.find (fun c -> LogicalPath.display c.Path = name))
                        .Index)

            let mutable bundle =
                store.Bundles.Create(
                    workspace,
                    discovered.Draft.Id,
                    discovered.Draft.Revision,
                    order
                )
                |> result

            let first = bundle.Mods.Head

            let stale =
                store.Bundles.Rename(
                    { bundle.Reference with
                        Revision = bundle.Reference.Revision + 1L },
                    first.Id,
                    "Different name"
                )

            let unchanged = store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result

            check
                "StaleBundleRenameIsRefusedWithoutChangingBundle"
                (Result.isError stale
                 && unchanged.Reference.Revision = bundle.Reference.Revision
                 && unchanged.Mods.Head.Name = first.Name)

            let prepared =
                store.Bundles.Prepare(bundle.Reference, first.Id, token) |> wait |> result

            let firstDigest = prepared.Draft.Manifest.Sha256

            check
                "NestedInputUsesOrdinaryManifestAndExplicitNewDestination"
                (prepared.Draft.Plan.IsSome
                 && prepared.Draft.Nested.IsSome
                 && prepared.Draft.Bundle.Value.ModId = first.ModId
                 && prepared.Draft.Name = first.Name)

            let job =
                store.Installations.Start(
                    workspace,
                    prepared.Draft.Id,
                    prepared.Draft.Revision,
                    Guid.NewGuid()
                )
                |> result

            let complete = finished store workspace job.Id

            check
                "FirstChildCommitsThroughExistingOwner"
                (complete.State = InstallationState.Complete && complete.ModId = Some first.ModId)

            bundle <- store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result
            let extras = bundle.Mods[1]

            let inside =
                store.Bundles.Prepare(bundle.Reference, extras.Id, token) |> wait |> result

            bundle <- store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result

            let nestedOrder =
                [ "Second.zip"; "XML.zip" ]
                |> List.map (fun name ->
                    (inside.Archives |> List.find (fun c -> LogicalPath.display c.Path = name))
                        .Index)

            bundle <-
                store.Bundles.ChooseNested(
                    bundle.Reference,
                    extras.Id,
                    inside.Draft.Id,
                    inside.Draft.Revision,
                    nestedOrder
                )
                |> result

            let second = bundle.Mods[1]

            let prepared =
                store.Bundles.Prepare(bundle.Reference, second.Id, token) |> wait |> result

            check
                "DuplicateBytesAtDifferentPathsHaveDistinctModIdentities"
                (first.ModId <> second.ModId
                 && second.Path.Length = 2
                 && prepared.Draft.Manifest.Sha256 = firstDigest)

            let job =
                store.Installations.StartAtCheckpoint(
                    workspace,
                    prepared.Draft.Id,
                    prepared.Draft.Revision,
                    Guid.NewGuid(),
                    fun point ->
                        if point = "before-publication" then
                            raise (OperationCanceledException())
                )
                |> result

            let stopped = finished store workspace job.Id
            bundle <- store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result

            check
                "FailedChildLeavesEarlierCommitAndNoOverallSuccess"
                (stopped.State = InstallationState.Stopped
                 && bundle.Mods[0].State = ModState.Installed
                 && bundle.Mods[1].State = ModState.Failed
                 && bundle.Mods[2].State = ModState.NeedsReview)

            store.Installations.Stop() |> wait
            artifact.Id, bundle.Reference.Id, first, second, complete.VersionId.Value

        let artifact, bundleId, first, second, firstVersion = phaseOne ()

        let phaseTwo () =
            use store = new OperationStore(state)
            let mutable bundle = store.Bundles.Read(workspace, bundleId) |> wait |> result

            check
                "RestartKeepsCompletedAndStoppedChildrenWithoutStartingWork"
                (bundle.Mods[0].State = ModState.Installed
                 && bundle.Mods[1].State = ModState.Failed
                 && not (bundle.Mods |> List.exists (fun m -> m.State = ModState.Installing)))

            bundle <- store.Bundles.Retry(bundle.Reference, second.Id) |> wait |> result

            let prepared =
                store.Bundles.Prepare(bundle.Reference, second.Id, token) |> wait |> result

            let job =
                store.Installations.Start(
                    workspace,
                    prepared.Draft.Id,
                    prepared.Draft.Revision,
                    Guid.NewGuid()
                )
                |> result

            let complete = finished store workspace job.Id

            let repeated =
                store.Installations.Start(
                    workspace,
                    prepared.Draft.Id,
                    prepared.Draft.Revision,
                    Guid.NewGuid()
                )
                |> result

            check
                "RetryReusesDestinationAndRepeatedPublicationReturnsTheCommittedChild"
                (complete.State = InstallationState.Complete
                 && complete.ModId = Some second.ModId
                 && repeated.Id = complete.Id
                 && repeated.VersionId = complete.VersionId)

            let version =
                (store.ModLibrary :> IModLibrary).Version(complete.VersionId.Value, 0)
                |> wait
                |> result

            check
                "IndividualNestedProvenanceSurvivesSourceWork"
                (match version.Origin with
                 | VersionOrigin.Bundle(id, _, paths, digests) ->
                     id = artifact && paths.Length = 2 && digests.Length = 2
                 | _ -> false)

            store.Installations.Stop() |> wait

        phaseTwo ()
        use store = new OperationStore(state)
        let library = store.ModLibrary :> IModLibrary
        let inventory = library.Scan(workspace, 100) |> wait |> result
        let target = inventory.Entries |> List.find (fun m -> m.Id = second.ModId)

        let privateCopy =
            Directory.GetFiles(
                root,
                "bundle-" + second.SourceId.ToString("N") + ".archive",
                SearchOption.AllDirectories
            )
            |> Array.exactlyOne

        let allCopies =
            Directory.GetFiles(root, "bundle-*.archive", SearchOption.AllDirectories)
            |> Set.ofArray

        File.AppendAllText(privateCopy, "changed owned bytes")

        store.Deletions.Delete(workspace, target.Id, target.Revision) |> wait

        let bundle = store.Bundles.Read(workspace, bundleId) |> wait |> result

        check
            "DeletedChildCannotResumeAndSharedBytesRemain"
            (not (File.Exists privateCopy)
             && allCopies |> Set.remove privateCopy |> Set.forall File.Exists
             && bundle.Mods |> List.forall (fun m -> m.Id <> second.Id)
             && (store.Artifacts.Read(workspace, artifact) |> wait |> result).State = ArtifactState.Installed)

        let xmlItem = bundle.Mods |> List.find (fun m -> m.Name = "XML")

        let xml =
            store.Bundles.Prepare(bundle.Reference, xmlItem.Id, token) |> wait |> result

        let choices =
            store.Installations.Fomod.Open(workspace, xml.Draft.Id, xml.Draft.Revision, profile)
            |> wait
            |> result

        check
            "NestedXmlUsesExistingChoicesAndKeepsTheChosenDestination"
            (choices.Draft.Plan.IsSome
             && choices.Draft.Name = xmlItem.Name
             && choices.Draft.Nested.IsSome)

        let bundle = store.Bundles.Read(workspace, bundleId) |> wait |> result
        store.Bundles.Delete(bundle.Reference) |> wait |> result |> ignore
        let firstSaved = library.Version(firstVersion, 0) |> wait |> result

        check
            "ExplicitBundleCleanupKeepsInstalledModAndProvenance"
            (firstSaved.Entries.Length = 1
             && Directory.GetFiles(root, "bundle-*.archive", SearchOption.AllDirectories).Length = 0
             && (store.Bundles.Find(workspace, artifact) |> wait |> result).IsNone)

        check
            "OriginalOuterArchiveWasNotChanged"
            (original = File.ReadAllBytes(Path.Combine(area, "Weekend collection.zip")))

        let openBundle file (data: byte array) =
            let path = Path.Combine(area, file)
            File.WriteAllBytes(path, data)

            let artifact =
                store.Artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Reference },
                    token
                )
                |> wait
                |> result

            let view = store.Bundles.Discover(reference artifact, token) |> wait |> result

            store.Bundles.Create(
                workspace,
                view.Draft.Id,
                view.Draft.Revision,
                view.Archives |> List.map _.Index
            )
            |> result

        let bain =
            zip
                [ "00 Core/textures/water.dds", bytes "water"
                  "10 Other/textures/water.dds", bytes "other"
                  "package.txt", bytes "Nested package notes" ]

        let bundle = openBundle "Package bundle.zip" (zip [ "Water.zip", bain ])

        let prepared =
            store.Bundles.Prepare(bundle.Reference, bundle.Mods.Head.Id, token)
            |> wait
            |> result

        let choices =
            store.Installations.Bain.Open(workspace, prepared.Draft.Id, prepared.Draft.Revision)
            |> result

        let notes =
            store.Installations.Bain.Notes(
                workspace,
                choices.Draft.Id,
                choices.Draft.Revision,
                token
            )
            |> wait
            |> result

        let review =
            store.Installations.Bain.Review(workspace, choices.Draft.Id, choices.Draft.Revision)
            |> result

        check
            "NestedBainUsesExistingSelectionAndLazyNotes"
            (notes = "Nested package notes"
             && review.Draft.Plan.IsSome
             && review.Draft.Nested.IsSome)

        store.Bundles.Delete(
            (store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result).Reference
        )
        |> wait
        |> result
        |> ignore

        let leaf = zip [ "Data/textures/file", bytes "leaf" ]
        let deep = [ 1..3 ] |> List.fold (fun inner _ -> zip [ "Next.zip", inner ]) leaf
        let mutable bundle = openBundle "Deep bundle.zip" (zip [ "First.zip", deep ])
        let mutable refused = false

        for depth in 1..3 do
            let prepared =
                store.Bundles.Prepare(bundle.Reference, bundle.Mods.Head.Id, token)
                |> wait
                |> result

            bundle <- store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result

            try
                bundle <-
                    store.Bundles.ChooseNested(
                        bundle.Reference,
                        bundle.Mods.Head.Id,
                        prepared.Draft.Id,
                        prepared.Draft.Revision,
                        prepared.Archives |> List.map _.Index
                    )
                    |> result
            with :? BundleException when depth = 3 ->
                refused <- true

        check
            "NestedDepthFailureKeepsTheLastExplicitPlanWithoutPublishing"
            (refused
             && bundle.Mods.Length = 1
             && bundle.Mods.Head.Path.Length = 3
             && bundle.Mods.Head.Attempt.IsNone)

        store.Bundles.Delete(
            (store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result).Reference
        )
        |> wait
        |> result
        |> ignore

        let many =
            zip [ for i in 1..10001 -> "Data/textures/" + string i + ".bin", Array.empty<byte> ]

        let bundle = openBundle "Many files.zip" (zip [ "A.zip", many; "B.zip", many ])

        store.Bundles.Prepare(bundle.Reference, bundle.Mods[0].Id, token)
        |> wait
        |> result
        |> ignore

        let bundle = store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result
        let mutable refused = false

        try
            store.Bundles.Prepare(bundle.Reference, bundle.Mods[1].Id, token)
            |> wait
            |> ignore
        with :? BundleException ->
            refused <- true

        let current = store.Bundles.Read(workspace, bundle.Reference.Id) |> wait |> result

        check
            "AggregateEntryBudgetStopsLaterPreparationBeforePublication"
            (refused
             && current.Mods[1].State = ModState.Failed
             && current.Mods |> List.forall (fun m -> m.Attempt.IsNone))

        store.Bundles.Delete(current.Reference) |> wait |> result |> ignore
        store.Installations.Stop() |> wait
        writer.WriteEndObject()
