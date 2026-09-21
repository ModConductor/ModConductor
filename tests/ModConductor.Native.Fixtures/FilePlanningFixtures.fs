namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Diagnostics
open System.Text.Json
open System.Threading
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module FilePlanningFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path text = LogicalPath.create [ text ] |> result

    let private metadata name =
        { Name = name
          Notes = ""
          Comment = ""
          Version = "1"
          Source = ""
          Categories = [] }

    let private hash file =
        use stream = File.OpenRead file in SHA256.HashData stream |> Convert.ToHexStringLower

    let private denyReads (paths: string list) =
        if OperatingSystem.IsLinux() then
            let modes = paths |> List.map (fun path -> path, File.GetUnixFileMode path)

            for path, _ in modes do
                File.SetUnixFileMode(path, enum<UnixFileMode> 0)

            let refused =
                paths
                |> List.forall (fun path ->
                    try
                        use _ = File.OpenRead path
                        false
                    with :? UnauthorizedAccessException ->
                        true)

            refused,
            (fun () -> modes |> List.iter (fun (path, mode) -> File.SetUnixFileMode(path, mode)))
        else
            true, ignore

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "file-plans")).FullName
        let state = Directory.CreateDirectory(Path.Combine(area, "state")).FullName
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let game, proton = ProtonFixtures.create (Path.Combine(area, "game-inputs"))
        let data = Path.Combine(game, "Data")
        File.WriteAllText(Path.Combine(data, "shared.txt"), "game-folder copy")
        File.WriteAllText(Path.Combine(data, "opaque.bsa"), "opaque container bytes")

        let workspace, first, second, low, high =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let lowVersion, highVersion = Guid.NewGuid(), Guid.NewGuid()

        let lowCopy =
            { ModId = low
              VersionId = lowVersion
              Path = path "shared.txt" }

        let highCopy =
            { ModId = high
              VersionId = highVersion
              Path = path "shared.txt" }

        let absentCopy = { highCopy with Path = path "only.txt" }
        writer.WriteStartObject("filePlanning")
        let mutable retained = []
        let mutable finalContextRevision = 0L

        do
            use store = new OperationStore(state)
            let workspaces = store.Workspaces :> IWorkspaceState
            let library = store.ModLibrary :> IModLibrary
            let selections = store.ModSelection :> IModSelection
            let contexts = store.GameContexts :> IGameContexts
            let plans = store.FilePlans :> IFilePlans

            let created =
                workspaces.Create(workspace, "File view fixture", StorageWorker.select root)
                |> wait
                |> result

            let created =
                workspaces.Edit(
                    workspace,
                    created.Workspace.Revision,
                    ProfileEdit.Create { Id = first; Name = "First" }
                )
                |> wait
                |> result

            workspaces.Edit(
                workspace,
                created.Workspace.Revision,
                ProfileEdit.Create { Id = second; Name = "Second" }
            )
            |> wait
            |> result
            |> ignore

            for id, version, name in [ low, lowVersion, "Low"; high, highVersion, "High" ] do
                let folder = Directory.CreateDirectory(Path.Combine(root, name)).FullName
                File.WriteAllText(Path.Combine(folder, "shared.txt"), name + " content")

                if id = high then
                    File.WriteAllText(Path.Combine(folder, "only.txt"), "only mod content")

                    for n in 1..70 do
                        File.WriteAllText(
                            Path.Combine(folder, "file-" + n.ToString("D3") + ".txt"),
                            string n
                        )

                if id = high then
                    Directory.CreateDirectory(Path.Combine(folder, "branch")) |> ignore

                    for n in 1..70 do
                        File.WriteAllText(
                            Path.Combine(folder, "branch", "leaf-" + n.ToString("D3") + ".txt"),
                            string n
                        )

                let registered =
                    library.Register(
                        workspace,
                        id,
                        metadata name,
                        Registration.Directory(ModKind.Regular, path name)
                    )
                    |> wait
                    |> result

                library.Publish(id, registered.Revision, version) |> wait |> result |> ignore

            for profile in [ first; second ] do
                let selected = InventoryObservations.read store profile

                selections.Change(
                    profile,
                    selected.SelectionRevision,
                    [ low; high ],
                    SelectionEdit.Enable true
                )
                |> wait
                |> result
                |> ignore

            let selection =
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }

            let context = contexts.Save(workspace, 0L, selection) |> wait |> result
            finalContextRevision <- context.Revision

            let concurrentReads =
                [ for _ in 1..16 do
                      let inventory =
                          (store.ModOrganization :> ModConductor.ModOrganization.IModOrganization)
                              .Query(
                                  first,
                                  { Text = ""
                                    Mode = ModConductor.ModOrganization.FilterMode.All
                                    Filters = []
                                    View = ModConductor.ModOrganization.OrganizationView.Flat
                                    Sort = ModConductor.ModOrganization.OrganizationSort.Priority },
                                  None,
                                  None
                              )

                      let files = plans.Open(first, CancellationToken.None)
                      let inventoryResult, fileResult = inventory |> wait, files |> wait
                      yield Result.isOk inventoryResult && Result.isOk fileResult ]

            writer.WriteBoolean(
                "concurrentInventoryAndFileReads",
                concurrentReads |> List.forall id
            )

            let beforeProfile = InventoryObservations.read store first
            let openOnly = plans.Open(first, CancellationToken.None) |> wait |> result

            writer.WriteBoolean(
                "coldViewNotComplete",
                not openOnly.Loaded && not openOnly.Problems.IsEmpty
            )

            let acquire profile refresh =
                plans.Acquire(profile, refresh, ignore, CancellationToken.None)
                |> wait
                |> result

            let inspect (snapshot: FilePlanSummary) target =
                plans.Inspect(snapshot.Id, target, None) |> wait |> result

            let gameReadRefused, restoreGame = denyReads [ Path.Combine(data, "opaque.bsa") ]

            let timer = Stopwatch.StartNew()

            let metadataInitial =
                try
                    acquire first true
                finally
                    restoreGame ()

            plans.Children(metadataInitial.Id, None, "", None) |> wait |> result |> ignore
            timer.Stop()

            writer.WriteBoolean("initialViewDoesNotReadGameContent", gameReadRefused)

            writer.WriteBoolean(
                "initialUsefulPageWithinOneSecond",
                timer.Elapsed < TimeSpan.FromSeconds 1.0
            )

            let payloads =
                Directory.GetFiles(root, "*.payload", SearchOption.AllDirectories)
                |> Array.toList

            let payloadReadsRefused, restorePayloads = denyReads payloads

            let initial =
                try
                    acquire first true
                finally
                    restorePayloads ()

            writer.WriteBoolean("initialViewDoesNotRehashManagedPayloads", payloadReadsRefused)
            let sources = inspect initial (path "shared.txt")

            writer.WriteBoolean(
                "priorityWinnerAndBasePins",
                sources.Copies.Length = 3
                && (sources.Copies
                    |> List.exists (fun row -> row.Copy = Some highCopy && row.Winner))
                && (sources.Copies |> List.exists (fun row -> row.Copy.IsNone && row.Sha256.IsNone))
            )

            let managedSource =
                sources.Copies |> List.find (fun row -> row.Copy = Some highCopy) |> _.Source

            let gameSource =
                sources.Copies |> List.find (fun row -> row.Copy.IsNone) |> _.Source

            let preview source =
                plans.Preview(
                    initial.Id,
                    source,
                    FilePreviewRepresentation.Text,
                    CancellationToken.None
                )
                |> wait
                |> result

            writer.WriteBoolean(
                "managedWinnerPreviewIsPinned",
                match preview managedSource with
                | { Standing = FileSourceStanding.Winner
                    Outcome = FilePreviewOutcome.Ready(FilePreviewContent.Text text) } ->
                    text.Content = "High content"
                | _ -> false
            )

            writer.WriteBoolean(
                "gameAlternativePreviewIsPinned",
                match preview gameSource with
                | { Standing = FileSourceStanding.Alternative
                    Outcome = FilePreviewOutcome.Ready(FilePreviewContent.Text text) } ->
                    text.Content = "game-folder copy"
                | _ -> false
            )

            writer.WriteBoolean(
                "opaqueArchiveIsAFile",
                (inspect initial (path "opaque.bsa")).Copies.Head.Sha256.IsNone
            )

            let existing =
                (InventoryObservations.read store first).Entries
                |> List.find (fun row -> row.Entry.Mod.Id = high)
                |> fun row -> row.Entry.Mod

            library.Edit(
                high,
                existing.Revision,
                { existing.Metadata with
                    Name = "Renamed textures" }
            )
            |> wait
            |> result
            |> ignore

            let renamed = plans.Open(first, CancellationToken.None) |> wait |> result

            writer.WriteBoolean(
                "labelsDoNotChangePlanPins",
                renamed.Fingerprint = initial.Fingerprint
                && (inspect renamed (path "shared.txt")).Copies
                   |> List.exists (fun row ->
                       row.Copy = Some highCopy && row.Name = "Renamed textures")
            )

            let initial = renamed

            let firstPage = plans.Children(initial.Id, None, "", None) |> wait |> result

            let secondPage =
                plans.Children(initial.Id, None, "", firstPage.Next) |> wait |> result

            writer.WriteBoolean(
                "boundedCursorKeepsIdentity",
                firstPage.Next.IsSome
                && (Set.intersect
                        (firstPage.Nodes |> Seq.map _.Path |> Set.ofSeq)
                        (secondPage.Nodes |> Seq.map _.Path |> Set.ofSeq))
                    .IsEmpty
                && (plans.Children(initial.Id, None, "shared", firstPage.Next) |> wait) = Error
                    FilePlanError.Stale
            )

            let branchPage =
                plans.Children(initial.Id, Some(path "branch"), "", None) |> wait |> result

            let hidden =
                plans.Change(initial.Id, highCopy, true, CancellationToken.None)
                |> wait
                |> result

            let continued =
                plans.Children(hidden.Snapshot.Id, Some(path "branch"), "", branchPage.Next)
                |> wait
                |> result

            let rootContinued =
                plans.Children(hidden.Snapshot.Id, None, "", firstPage.Next) |> wait |> result

            writer.WriteBoolean(
                "visibilityKeepsPagingLineage",
                continued.Nodes.Length > 0
                && continued.Snapshot.Id = hidden.Snapshot.Id
                && rootContinued.Nodes = secondPage.Nodes
                && (Set.intersect
                        (branchPage.Nodes |> Seq.map _.Path |> Set.ofSeq)
                        (continued.Nodes |> Seq.map _.Path |> Set.ofSeq))
                    .IsEmpty
            )

            writer.WriteBoolean(
                "staleSnapshotPreviewRefuses",
                plans.Preview(
                    initial.Id,
                    managedSource,
                    FilePreviewRepresentation.Text,
                    CancellationToken.None
                )
                |> wait =
                    Error FilePlanError.Stale
            )

            writer.WriteBoolean(
                "hidePromotesNext",
                (inspect hidden.Snapshot (path "shared.txt")).Copies
                |> List.exists (fun row -> row.Copy = Some lowCopy && row.Winner)
            )

            writer.WriteBoolean(
                "staleWriteHasNoAudit",
                plans.Change(initial.Id, lowCopy, true, CancellationToken.None) |> wait = Error
                    FilePlanError.Stale
                && (plans.History(hidden.Snapshot.Id, lowCopy, None) |> wait |> result)
                    .Changes.IsEmpty
            )

            let fresh = acquire first true

            writer.WriteBoolean(
                "incrementalMatchesFresh",
                fresh.Fingerprint = hidden.Snapshot.Fingerprint
                && fresh.PlannedFiles = hidden.Snapshot.PlannedFiles
            )

            let hiddenBoth =
                plans.Change(fresh.Id, lowCopy, true, CancellationToken.None) |> wait |> result

            writer.WriteBoolean(
                "gameFolderFallback",
                (inspect hiddenBoth.Snapshot (path "shared.txt")).Copies
                |> List.exists (fun row -> row.Copy.IsNone && row.Winner)
            )

            let hiddenOnly =
                plans.Change(hiddenBoth.Snapshot.Id, absentCopy, true, CancellationToken.None)
                |> wait
                |> result

            writer.WriteBoolean(
                "allHiddenRemainsInspectable",
                hiddenOnly.Snapshot.AbsentTargets = 1
                && (inspect hiddenOnly.Snapshot (path "only.txt")).Copies
                   |> List.exists (fun row -> row.Hidden && row.CanUnhide && not row.Winner)
            )

            let shared = acquire second false

            writer.WriteBoolean(
                "sharedAcrossProfiles",
                (inspect shared (path "shared.txt")).Copies
                |> List.filter (fun row -> row.Hidden)
                |> List.length =
                    2
            )

            let restored =
                plans.Change(shared.Id, highCopy, false, CancellationToken.None)
                |> wait
                |> result

            writer.WriteBoolean(
                "unhideRestoresEligibility",
                (inspect restored.Snapshot (path "shared.txt")).Copies
                |> List.exists (fun row -> row.Copy = Some highCopy && row.Winner)
            )

            let firstAgain = acquire first false
            File.WriteAllText(Path.Combine(data, "shared.txt"), "external fixture update")

            let changedGameSource =
                (inspect firstAgain (path "shared.txt")).Copies
                |> List.find (fun row -> row.Copy.IsNone)
                |> _.Source

            writer.WriteBoolean(
                "changedGamePreviewRefuses",
                plans.Preview(
                    firstAgain.Id,
                    changedGameSource,
                    FilePreviewRepresentation.Text,
                    CancellationToken.None
                )
                |> wait =
                    Error FilePlanError.Stale
            )

            writer.WriteBoolean(
                "changedGameRejectsHide",
                plans.Change(firstAgain.Id, highCopy, true, CancellationToken.None) |> wait = Error
                    FilePlanError.Stale
                && (plans.Read firstAgain.Id |> wait |> result).Stale
            )

            let staleUnhide =
                plans.Change(firstAgain.Id, lowCopy, false, CancellationToken.None)
                |> wait
                |> result

            writer.WriteBoolean(
                "staleGameAllowsUnhideOnly",
                staleUnhide.Snapshot.Stale
                && (plans.Change(staleUnhide.Snapshot.Id, highCopy, true, CancellationToken.None)
                    |> wait) = Error FilePlanError.Blocked
            )

            let refreshed = acquire first true

            writer.WriteBoolean(
                "refreshPinsChangedContent",
                refreshed.Fingerprint <> initial.Fingerprint
                && not refreshed.Stale
                && (inspect refreshed (path "shared.txt")).Copies
                   |> List.exists (fun row -> row.Copy.IsNone && row.Sha256.IsNone)
            )

            use cancelled = new CancellationTokenSource()
            cancelled.Cancel()

            writer.WriteBoolean(
                "cancelPreservesPrevious",
                plans.Acquire(first, true, ignore, cancelled.Token) |> wait = Error
                    FilePlanError.Cancelled
                && (plans.Read refreshed.Id |> wait |> result).Fingerprint = refreshed.Fingerprint
            )

            let selected = InventoryObservations.read store first

            selections.Change(
                first,
                selected.SelectionRevision,
                [ high ],
                SelectionEdit.Enable false
            )
            |> wait
            |> result
            |> ignore

            let disabled = acquire first false
            let disabledCopy = (inspect disabled (path "only.txt")).Copies.Head

            writer.WriteBoolean(
                "disabledCopyCanUnhideWithoutEnabling",
                not disabledCopy.Enabled && disabledCopy.Hidden && disabledCopy.CanUnhide
            )

            let unhidden =
                plans.Change(disabled.Id, absentCopy, false, CancellationToken.None)
                |> wait
                |> result

            writer.WriteBoolean(
                "disabledCopyDoesNotEnterPlan",
                unhidden.Snapshot.PlannedFiles = disabled.PlannedFiles
                && not ((inspect unhidden.Snapshot (path "only.txt")).Copies.Head.Winner)
            )

            let hiddenAgain =
                plans.Change(unhidden.Snapshot.Id, absentCopy, true, CancellationToken.None)
                |> wait
                |> result

            let entry =
                (InventoryObservations.read store first).Entries
                |> List.find (fun row -> row.Entry.Mod.Id = high)
                |> fun row -> row.Entry.Mod

            let nextVersion = Guid.NewGuid()
            let published = library.Publish(high, entry.Revision, nextVersion) |> wait |> result
            let newPlan = acquire first false
            let newCopy = (inspect newPlan (path "only.txt")).Copies.Head

            writer.WriteBoolean(
                "newVersionDoesNotInherit",
                published.CurrentVersion = Some nextVersion
                && not newCopy.Hidden
                && newCopy.Copy.Value.VersionId = nextVersion
                && (plans.History(newPlan.Id, absentCopy, None) |> wait |> result).Changes.Length = 3
            )

            let historical = plans.InspectCopy(newPlan.Id, absentCopy) |> wait |> result

            writer.WriteBoolean(
                "historicalCopyIsReadOnly",
                historical.Copies.Head.Historical
                && historical.Copies.Head.Hidden
                && not historical.Copies.Head.CanUnhide
                && not historical.Copies.Head.CanHide
            )

            let history = (plans.History(newPlan.Id, highCopy, None) |> wait |> result).Changes

            writer.WriteBoolean(
                "auditRetainsExactCopyTransitions",
                history.Length = 2
                && not history.Head.Hidden
                && history.Head.BeforeHidden
                && history.Tail.Head.Hidden
                && not history.Tail.Head.BeforeHidden
            )

            writer.WriteBoolean(
                "rulesDoNotChangeProfileOrSource",
                (InventoryObservations.read store second).SelectionRevision = beforeProfile.SelectionRevision
                && (sources.Copies |> List.find (fun row -> row.Copy = Some highCopy)).Sha256 = Some(
                    hash (Path.Combine(root, "High", "shared.txt"))
                )
            )

            retained <- history
            store.FilePlans.Drain().GetAwaiter().GetResult()

        do
            use store = new OperationStore(state)
            let contexts = store.GameContexts :> IGameContexts
            let plans = store.FilePlans :> IFilePlans
            let context = contexts.Read workspace |> wait |> result
            let opened = plans.Open(first, CancellationToken.None) |> wait |> result

            writer.WriteBoolean(
                "restartRequiresObservation",
                context.Revision = finalContextRevision
                && context.Binding.Value.NeedsCheck
                && not opened.Loaded
                && (plans.History(opened.Id, highCopy, None) |> wait |> result).Changes = retained
            )

            store.FilePlans.Drain().GetAwaiter().GetResult()

        for file in Directory.EnumerateFiles(root, "*.payload", SearchOption.AllDirectories) do
            if OperatingSystem.IsWindows() then
                File.SetAttributes(file, FileAttributes.Normal)

        writer.WriteEndObject()
