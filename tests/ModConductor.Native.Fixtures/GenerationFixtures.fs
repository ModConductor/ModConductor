namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Diagnostics
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open System.Security.AccessControl
open System.Security.Principal
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.ModSelection
open ModConductor.Workspaces
open ModConductor.Persistence
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations

module internal GenerationFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private path = DeploymentFixtureData.path
    let private location = DeploymentFixtureData.location

    let private digest file =
        use stream = File.OpenRead file
        SHA256.HashData stream |> Convert.ToHexStringLower

    let private denyReads (path: string) =
        if OperatingSystem.IsLinux() then
            let mode = File.GetUnixFileMode path
            File.SetUnixFileMode(path, enum<UnixFileMode> 0)

            let refused =
                try
                    use _ = File.OpenRead path
                    false
                with :? UnauthorizedAccessException ->
                    true

            refused, (fun () -> File.SetUnixFileMode(path, mode))
        else
            true, ignore

    let private metadata =
        { Name = "Managed"
          Version = "1"
          Notes = ""
          Comment = ""
          Source = ""
          Categories = [] }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "generations")).FullName

        let make name =
            Directory.CreateDirectory(Path.Combine(area, name)).FullName

        let state, workspacePath = make "state", make "workspace"
        let gamePath, proton = ProtonFixtures.create (Path.Combine(area, "game-inputs"))
        let targetPath = Path.Combine(gamePath, "Data")

        let originals, generations, secondary, working =
            make "originals", make "generations", make "secondary", make "working"

        let workspace, profile, modId, version =
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid()

        let gameFile = Path.Combine(targetPath, "base.txt")
        let collision = Path.Combine(targetPath, "shared.txt")
        Directory.CreateDirectory(Path.Combine(targetPath, "mixed")) |> ignore
        File.WriteAllText(Path.Combine(targetPath, "mixed", "base.txt"), "mixed base")
        File.WriteAllText(gameFile, "untouched game bytes")
        File.WriteAllText(collision, "original collision")
        let baseHash, collisionHash = digest gameFile, digest collision
        let target text : TargetFile = { Root = workspace; Path = path text }

        let policy =
            if OperatingSystem.IsWindows() then
                TargetPolicy.windows
            else
                TargetPolicy.linux

        let root = { Id = workspace; Policy = policy }

        let roots =
            [ { Root = root
                Directory = location targetPath
                Originals = location originals } ]

        let sourcePath =
            Directory.CreateDirectory(Path.Combine(workspacePath, "Managed")).FullName

        let write name (contents: string) =
            let file = Path.Combine(sourcePath, name)
            Directory.CreateDirectory(Path.GetDirectoryName file) |> ignore
            File.WriteAllText(file, contents)

        write "mixed/mod.txt" "mixed managed"
        write "branch/unchanged.txt" "unchanged payload"
        write "branch/changed.txt" "old payload"
        write "branch/removed.txt" "removed payload"
        write "shared.txt" "managed collision"
        write "settings.ini" "seed defaults"
        write "hidden.txt" "hidden managed payload"

        let snapshotFiles: SnapshotFile list =
            [ "base.txt"; "shared.txt"; "mixed/base.txt" ]
            |> List.map (fun name ->
                let logical = path name

                let file =
                    RecoveryFiles.withParent (location targetPath) logical (fun parent child ->
                        parent.InspectFile(child, None))

                { Path = logical
                  Identity =
                    SnapshotFileIdentity.Metadata
                        { Identity = file.Identity
                          Length = file.Length
                          Modified = file.Modified } })

        let observed =
            snapshotFiles
            |> List.map (fun file -> file.Path, (SnapshotFile.metadata file).Value.Identity)
            |> Map.ofList

        let snapshot =
            { Snapshot =
                { Id = Guid.NewGuid()
                  Generation = "observed"
                  Kind = ReadOnlyLayerKind.Base
                  Priority = 0
                  Complete = true
                  Files = snapshotFiles
                  Mappings =
                    [ { SourcePrefix = PlanPath.Root
                        TargetRoot = workspace
                        TargetPrefix = PlanPath.Root } ]
                  Archives = [] }
              Directory = location targetPath
              Files = observed
              Originals = Map.empty }

        let extraSource = make "explicit-secondary"
        File.WriteAllText(Path.Combine(extraSource, "extra.txt"), "explicit secondary bytes")

        let extraFile: SnapshotFile =
            { Path = path "extra.txt"
              Identity =
                SnapshotFileIdentity.Content(
                    FileInfo(Path.Combine(extraSource, "extra.txt")).Length,
                    digest (Path.Combine(extraSource, "extra.txt"))
                ) }

        let extraIdentity =
            RecoveryFiles.withParent (location extraSource) extraFile.Path (fun parent name ->
                (parent.InspectEntry name).Value.Identity)

        let extra =
            { Snapshot =
                { snapshot.Snapshot with
                    Id = Guid.NewGuid()
                    Kind = ReadOnlyLayerKind.Secondary
                    Files = [ extraFile ] }
              Directory = location extraSource
              Files = Map.ofList [ extraFile.Path, extraIdentity ]
              Originals = Map.empty }

        let snapshots = [ snapshot; extra ]
        let writableId, outputId = Guid.NewGuid(), Guid.NewGuid()

        let writable =
            [ { Id = writableId
                Target = WritableTarget.File(workspace, path "settings.ini") }
              { Id = outputId
                Target = WritableTarget.Subtree(workspace, PlanPath.At(path "output")) } ]

        writer.WriteStartObject("generations")
        use store = new OperationStore(state)
        let workspaces = store.Workspaces :> IWorkspaceState
        let library = store.ModLibrary :> IModLibrary
        let selection = store.ModSelection :> IModSelection

        let created =
            workspaces.Create(workspace, "Generation fixture", StorageWorker.select workspacePath)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "Selected" }
        )
        |> wait
        |> result
        |> ignore

        let registered =
            library.Register(
                workspace,
                modId,
                metadata,
                Registration.Directory(ModKind.Regular, path "Managed")
            )
            |> wait
            |> result

        library.Publish(modId, registered.Revision, version) |> wait |> result |> ignore
        let page = InventoryObservations.read store profile

        selection.Change(profile, page.SelectionRevision, [ modId ], SelectionEdit.Enable true)
        |> wait
        |> result
        |> ignore

        let contexts = store.GameContexts :> IGameContexts

        contexts.Save(
            workspace,
            profile,
            0L,
            { GameId = GameId.SkyrimSpecialEditionSteam
              Path = gamePath
              Proton = if OperatingSystem.IsLinux() then Some proton else None }
        )
        |> wait
        |> result
        |> ignore

        let plans = store.FilePlans :> IFilePlans

        let loaded =
            plans.Acquire(profile, false, ignore, CancellationToken.None) |> wait |> result

        let hidden =
            { ModId = modId
              VersionId = version
              Path = path "hidden.txt" }

        plans.Change(loaded.Id, hidden, true, CancellationToken.None)
        |> wait
        |> result
        |> ignore

        let buildRequest id previous =
            { Id = id
              Storage = location generations
              SecondaryStorage = location secondary
              Roots = roots
              LinkedBase = false
              Excluded = Set.empty
              OwnedFiles = []
              Working =
                [ { Declaration = writableId
                    Initialized = false
                    Root = location working
                    Path = path "settings.ini" }
                  { Declaration = outputId
                    Initialized = false
                    Root = location working
                    Path = path "output" } ]
              Previous = previous
              Processes = [] }

        let build id previous =
            store.Generations.Build(
                buildRequest id previous,
                profile,
                snapshots,
                writable,
                CancellationToken.None
            )
            |> wait
            |> result

        let sourceFacts () =
            Directory.GetFiles(workspacePath, "*", SearchOption.AllDirectories)
            |> Array.map (fun file ->
                let permissions =
                    if OperatingSystem.IsWindows() then
                        FileInfo(file)
                            .GetAccessControl()
                            .GetSecurityDescriptorSddlForm(AccessControlSections.Access)
                    else
                        string (File.GetUnixFileMode file)

                file, digest file, File.GetAttributes file, permissions)
            |> Array.sortBy (fun (file, _, _, _) -> file)

        let originalSourceFacts = sourceFacts ()
        use entered = new ManualResetEventSlim(false)
        use release = new ManualResetEventSlim(false)

        let delayed =
            store.Generations.Build(
                buildRequest (Guid.NewGuid()) None,
                profile,
                snapshots,
                writable,
                CancellationToken.None,
                fun location ->
                    entered.Set()

                    if not (release.Wait 15000) then
                        invalidOp "The fixture storage observation was not released."

                    GenerationStorage.available location.Path location.Identity
            )

        if not (entered.Wait 15000) then
            invalidOp "The fixture build did not enter storage observation."

        let closeRefused =
            try
                (store :> IDisposable).Dispose()
                false
            with :? InvalidOperationException ->
                true

        let manifest = library.Version(version, 0) |> wait |> result

        let linkedPayload =
            manifest.Entries |> List.find (fun entry -> entry.Path = path "shared.txt")

        let payloadPath =
            Directory.GetFiles(
                workspacePath,
                LibraryFiles.payloadName linkedPayload.Payload.Id,
                SearchOption.AllDirectories
            )
            |> Array.exactlyOne

        let payloadReadRefused, restorePayload = denyReads payloadPath
        release.Set()

        let first =
            try
                delayed |> wait |> result
            finally
                restorePayload ()

        writer.WriteBoolean("closePreservesActivePreparation", closeRefused)
        writer.WriteBoolean("deploymentDoesNotRehashManagedPayloads", payloadReadRefused)

        writer.WriteBoolean(
            "sourceBytesAndPermissionsUnchanged",
            sourceFacts () = originalSourceFacts
        )

        writer.WriteBoolean(
            "exactVisibilityPin",
            first.Generation.Files
            |> List.forall (fun file -> file.Target <> target "hidden.txt")
        )

        let contextId = Guid.NewGuid()

        let switch revision (prepared: PreparedGeneration) stamp =
            { Id = Guid.NewGuid()
              ContextId = contextId
              ContextFingerprint = "owned fixture"
              ExpectedRevision = revision
              Roots = roots
              Generation = prepared.Generation
              DirectoryBoundaries =
                (if
                     prepared.Generation.Files
                     |> List.exists (fun file ->
                         LogicalPath.components file.Target.Path |> List.head = "branch")
                 then
                     [ target "branch" ]
                 else
                     [])
              PreserveOriginals = [ target "shared.txt" ]
              ExpectedSources = stamp }

        let run (receipt: Receipt) =
            store.Generations.Run(
                receipt.Id,
                receipt.Revision,
                false,
                CancellationToken.None,
                (fun _ _ -> ()),
                []
            )
            |> wait
            |> result

        let unstamped = switch 0L first None
        let missingStamp = store.Generations.Start(unstamped, []) |> wait

        writer.WriteBoolean(
            "newGenerationRequiresStamp",
            Result.isError missingStamp
            && (store.Deployment.Read unstamped.Id |> wait).IsNone
            && (store.Deployment.Context contextId |> wait).IsNone
        )

        let baseReadRefused, restoreBase = denyReads gameFile

        let firstReceipt =
            try
                store.Generations.Start(switch 0L first (Some first.Sources), [])
                |> wait
                |> result
            finally
                restoreBase ()

        writer.WriteBoolean("deploymentChecksBaseMetadataWithoutReadingContent", baseReadRefused)

        let timer = Stopwatch.StartNew()
        run firstReceipt |> ignore
        timer.Stop()
        writer.WriteNumber("firstSwitchMilliseconds", timer.Elapsed.TotalMilliseconds)
        writer.WriteNumber("generationLinkCount", first.Measurements.GenerationLinks)
        writer.WriteNumber("requiredBytes", first.Measurements.RequiredBytes)
        writer.WriteNumber("availableBytes", first.Measurements.AvailableBytes)

        writer.WriteBoolean(
            "baseUntouched",
            digest gameFile = baseHash
            && FileInfo(gameFile).LinkTarget = null
            && first.Measurements.BaseCopiedBytes = 0L
        )

        writer.WriteBoolean(
            "managedDirectoryLink",
            DirectoryInfo(Path.Combine(targetPath, "branch")).LinkTarget <> null
        )

        writer.WriteBoolean(
            "mixedBranchUsesLeaf",
            DirectoryInfo(Path.Combine(targetPath, "mixed")).LinkTarget = null
            && FileInfo(Path.Combine(targetPath, "mixed", "mod.txt")).LinkTarget <> null
            && File.ReadAllText(Path.Combine(targetPath, "mixed", "base.txt")) = "mixed base"
        )

        writer.WriteBoolean(
            "individualCollisionLink",
            FileInfo(collision).LinkTarget <> null
            && digest collision = digest (Path.Combine(sourcePath, "shared.txt"))
        )

        let attempts =
            [ (fun () ->
                  File.WriteAllText(
                      Path.Combine(targetPath, "branch", "unchanged.txt"),
                      "overwrite"
                  ))
              (fun () ->
                  File.WriteAllText(Path.Combine(targetPath, "branch", "new.tmp"), "replace"))
              (fun () -> File.Delete(Path.Combine(targetPath, "branch", "unchanged.txt"))) ]
            |> List.map (fun action ->
                try
                    action ()
                    false
                with
                | :? UnauthorizedAccessException
                | :? IOException -> true)

        writer.WriteBoolean("ordinaryWritesRefused", attempts |> List.forall id)
        File.WriteAllText(Path.Combine(targetPath, "settings.ini"), "user settings")
        File.WriteAllText(Path.Combine(targetPath, "output", "save.bin"), "new output")

        writer.WriteBoolean(
            "writableIsolated",
            File.ReadAllText(Path.Combine(sourcePath, "settings.ini")) = "seed defaults"
        )

        let oldFiles =
            first.Generation.Files |> List.map (fun file -> file.Path, file.Backing.Value)

        write "branch/changed.txt" "new changed payload"
        File.Delete(Path.Combine(sourcePath, "branch", "removed.txt"))
        write "branch/added.txt" "added payload"
        let originalManifest = library.Version(version, 0) |> wait |> result
        let current = InventoryObservations.read store profile

        let revision =
            current.Entries
            |> List.find (fun row -> row.Entry.Mod.Id = modId)
            |> _.Entry.Mod.Revision

        let nextVersion = Guid.NewGuid()
        library.Publish(modId, revision, nextVersion) |> wait |> result |> ignore
        let second = build (Guid.NewGuid()) (Some first.Generation)

        let shared =
            second.Generation.Files
            |> List.filter (fun file ->
                oldFiles
                |> List.exists (fun (path, backing) ->
                    path = file.Path && backing = file.Backing.Value))

        writer.WriteBoolean(
            "unchangedPayloadShared",
            shared |> List.exists (fun file -> file.Target = target "branch/unchanged.txt")
        )

        let nextManifest = library.Version(nextVersion, 0) |> wait |> result

        let changed =
            nextManifest.Entries
            |> List.filter (fun file ->
                originalManifest.Entries
                |> List.forall (fun old -> old.Payload.Id <> file.Payload.Id))
            |> List.sumBy _.Payload.Length

        writer.WriteBoolean(
            "newVersionDoesNotInheritHide",
            second.Generation.Files
            |> List.exists (fun file -> file.Target = target "hidden.txt")
        )

        writer.WriteBoolean(
            "secondaryCopiedOnce",
            first.Measurements.CopiedBytes = SnapshotFile.length extraFile
            && second.Measurements.CopiedBytes = 0L
            && shared |> List.exists (fun file -> file.Target = target "extra.txt")
        )

        writer.WriteNumber("changedPublishedBytes", changed)

        writer.WriteNumber(
            "uniquePayloadBytes",
            originalManifest.Entries @ nextManifest.Entries
            |> List.map _.Payload
            |> List.distinctBy _.Id
            |> List.sumBy _.Length
        )

        writer.WriteNumber("secondaryBackingBytes", SnapshotFile.length extraFile)

        writer.WriteBoolean(
            "onlyChangedPublicationBytes",
            (changed = int64 (
                System.Text.Encoding.UTF8.GetByteCount("new changed payload")
                + System.Text.Encoding.UTF8.GetByteCount("added payload")
            ))
        )

        writer.WriteNumber("generationCopiedBytes", second.Measurements.CopiedBytes)

        let neverRecorded = build (Guid.NewGuid()) (Some second.Generation)
        let currentSelection = InventoryObservations.read store profile

        selection.Change(
            profile,
            currentSelection.SelectionRevision,
            [ modId ],
            SelectionEdit.Enable true
        )
        |> wait
        |> result
        |> ignore

        let staleWithoutStamp = switch 1L neverRecorded None
        let unstampedStale = store.Generations.Start(staleWithoutStamp, []) |> wait

        writer.WriteBoolean(
            "staleNewGenerationWithoutStampRefused",
            Result.isError unstampedStale
            && (store.Deployment.Read staleWithoutStamp.Id |> wait).IsNone
            && (store.Deployment.Generation(contextId, neverRecorded.Generation.Id) |> wait).IsNone
        )

        let second = build (Guid.NewGuid()) (Some second.Generation)

        let secondReceipt =
            store.Generations.Start(switch 1L second (Some second.Sources), [])
            |> wait
            |> result

        use interrupted = new CancellationTokenSource()

        let stopped =
            store.Generations.Run(
                secondReceipt.Id,
                secondReceipt.Revision,
                false,
                interrupted.Token,
                (fun phase index ->
                    if phase = "remove-intent" && index = 1 then
                        interrupted.Cancel()),
                []
            )
            |> wait

        let retained = store.Deployment.Read secondReceipt.Id |> wait |> Option.get

        writer.WriteBoolean(
            "interruptedSwitchRecorded",
            Result.isError stopped
            && retained.Phase = ReceiptPhase.Blocked
            && retained.Changes |> List.exists (fun change -> change.Observed.IsSome)
        )

        run retained |> ignore

        writer.WriteBoolean(
            "addedAndRemoved",
            File.Exists(Path.Combine(targetPath, "branch", "added.txt"))
            && not (File.Exists(Path.Combine(targetPath, "branch", "removed.txt")))
        )

        let old =
            store.Deployment.Generation(contextId, first.Generation.Id)
            |> wait
            |> Option.get

        let rollback = { first with Generation = old }
        let back = store.Generations.Start(switch 2L rollback None, []) |> wait |> result
        run back |> ignore

        writer.WriteBoolean(
            "retainedRollback",
            File.ReadAllText(Path.Combine(targetPath, "branch", "changed.txt")) = "old payload"
            && File.Exists(Path.Combine(targetPath, "branch", "removed.txt"))
        )

        writer.WriteBoolean(
            "mutableNotRolledBack",
            File.ReadAllText(Path.Combine(targetPath, "settings.ini")) = "user settings"
            && File.ReadAllText(Path.Combine(targetPath, "output", "save.bin")) = "new output"
        )

        let storedBefore = Directory.GetFileSystemEntries generations |> Array.sort

        let wholeRoot =
            store.Generations.Build(
                buildRequest (Guid.NewGuid()) None,
                profile,
                snapshots,
                [ { Id = Guid.NewGuid()
                    Target = WritableTarget.Subtree(workspace, PlanPath.Root) } ],
                CancellationToken.None
            )
            |> wait

        writer.WriteBoolean(
            "wholeRootRefusedWithoutEffects",
            Result.isError wholeRoot
            && (Directory.GetFileSystemEntries generations |> Array.sort) = storedBefore
        )

        let low =
            store.Generations.Build(
                buildRequest (Guid.NewGuid()) (Some second.Generation),
                profile,
                snapshots,
                writable,
                CancellationToken.None,
                (fun _ -> 0L)
            )
            |> wait

        writer.WriteBoolean("controlledLowSpaceRefused", Result.isError low)

        let stale =
            store.Generations.Start(switch 3L first (Some first.Sources), []) |> wait

        writer.WriteBoolean("staleSelectionRefused", Result.isError stale)

        writer.WriteBoolean(
            "originalRetained",
            Directory.EnumerateFiles originals
            |> Seq.exists (fun file -> digest file = collisionHash)
        )

        writer.WriteBoolean(
            "oldGenerationRetained",
            Directory.Exists(HostPath.value old.Directory.Path)
        )

        let stateBefore = workspaces.Read(workspace, None) |> wait |> result
        let other = Guid.NewGuid()

        workspaces.Edit(
            workspace,
            stateBefore.Workspace.Revision,
            ProfileEdit.Create { Id = other; Name = "Base only" }
        )
        |> wait
        |> result
        |> ignore

        let baseOnly =
            store.Generations.Build(
                buildRequest (Guid.NewGuid()) (Some second.Generation),
                other,
                snapshots,
                writable,
                CancellationToken.None
            )
            |> wait
            |> result

        let baseRequest = switch 3L baseOnly (Some baseOnly.Sources)

        let childInfo =
            ProcessStartInfo(
                Environment.ProcessPath,
                UseShellExecute = false,
                RedirectStandardInput = true,
                RedirectStandardOutput = true
            )

        if Path.GetFileNameWithoutExtension(Environment.ProcessPath) = "dotnet" then
            childInfo.ArgumentList.Add(
                Path.Combine(AppContext.BaseDirectory, "ModConductor.Native.Fixtures.dll")
            )

        childInfo.ArgumentList.Add "--generation-game"
        use running = Process.Start childInfo

        if running.StandardOutput.ReadLine() <> "ready" then
            invalidOp "The owned game fixture did not start."

        let processIdentity =
            { Id = running.Id
              StartedAt = running.StartTime.ToUniversalTime()
              Executable = running.MainModule.FileName }

        let refused = store.Generations.Start(baseRequest, [ processIdentity ]) |> wait

        writer.WriteBoolean(
            "runningGameRefused",
            Result.isError refused && (store.Deployment.Read baseRequest.Id |> wait).IsNone
        )

        running.StandardInput.WriteLine "stop"
        running.StandardInput.Flush()

        if not (running.WaitForExit 15000) || running.ExitCode <> 0 then
            invalidOp "The owned game fixture did not stop."

        let beforeSwitch = Stopwatch.StartNew()
        let baseReceipt = store.Generations.Start(baseRequest, []) |> wait |> result
        run baseReceipt |> ignore
        beforeSwitch.Stop()
        writer.WriteNumber("profileSwitchMilliseconds", beforeSwitch.Elapsed.TotalMilliseconds)

        writer.WriteBoolean(
            "baseOnlyRestored",
            digest collision = collisionHash
            && FileInfo(collision).LinkTarget = null
            && (baseOnly.Generation.Files
                |> List.forall (fun file -> file.Target = target "extra.txt"))
            && not (Directory.Exists(Path.Combine(targetPath, "branch")))
        )

        let foreign = Path.Combine(targetPath, "branch")
        File.WriteAllText(foreign, "foreign destination")
        let foreignRequest = switch 4L second None
        let refusedForeign = store.Generations.Start(foreignRequest, []) |> wait

        writer.WriteBoolean(
            "foreignTargetRefused",
            Result.isError refusedForeign
            && File.ReadAllText(foreign) = "foreign destination"
            && (store.Deployment.Read foreignRequest.Id |> wait).IsNone
        )

        File.Delete foreign
        File.WriteAllText(gameFile, "observed base changed")
        let refusedBase = store.Generations.Start(switch 4L second None, []) |> wait

        writer.WriteBoolean(
            "changedBaseRefused",
            Result.isError refusedBase
            && File.ReadAllText(gameFile) = "observed base changed"
        )

        File.WriteAllText(gameFile, "untouched game bytes")
        writer.WriteString("fingerprint", second.Generation.PlanFingerprint)
        writer.WriteEndObject()
        GenerationCleanup.normalize area
