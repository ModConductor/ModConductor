namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.Deployment
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.ModOrganization
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Skse
open ModConductor.Workspaces

type private SkseScenario =
    { Area: string
      WorkspacePath: string
      Workspace: Guid
      Profile: Guid
      Game: string
      Proton: ProtonSelection
      Store: OperationStore
      State: GameContextState
      Evidence: InstallationEvidence
      Runtime: string }

type private ReleaseEvidence =
    { Premium: SkseSelection
      Regular: SkseSelection
      Manifest: ArchiveManifest
      ExactRuntimeWins: bool
      NewerIncompatibleRejected: bool
      LabelWithoutRuntimeRejected: bool
      PublicSteamVersionMatches: bool
      OtherStorefrontsRemainIncompatible: bool
      OrdinaryNexusRoutes: bool
      ReviewedArchiveLayout: bool }

type private InstalledEvidence =
    { FirstGeneration: Guid
      FirstStored: StoredSkseLoader option
      FirstEnabled: ModQueryPage
      LoaderPath: string
      GenerationBoundLoader: bool
      ProtonUsesLoader: bool
      TransferArchiveInstallGeneration: bool
      OrdinaryRedeployRetainsComponentRouteAndLaunch: bool }

type private UpdatedEvidence =
    { Release: SkseRelease
      Artifact: Artifact
      Generation: Guid
      Stored: StoredSkseLoader option
      FailedReplacementPreservesSelectionGenerationAndLoader: bool
      UpdatedLoaderCorrect: bool
      RetainedFirstCorrect: bool }

type private DurableEvidence =
    { RestartedGenerationBound: bool
      ColdRestartRetainsCacheAndLoaderProvenance: bool
      NxmWaitingAndFailureAreDurable: bool }

type private ReuseEvidence =
    { SameSkseSourceReusesImportedVersionAfterRemoval: bool
      SecondProfileUsesAvailableSkseVersion: bool
      DifferentSkseReleaseStaysDistinct: bool
      DeletingOldSkseModRemovesOnlyItsLoaderHistory: bool
      NewSkseReleaseImportsAfterDeletingOlderMod: bool }

module SkseFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private required label (value: Result<'a, DeploymentError>) =
        match value with
        | Ok value -> value
        | Error(DeploymentError.Blocked detail)
        | Error(DeploymentError.Unavailable detail) -> failwith (label + ": " + detail)
        | Error DeploymentError.NotFound -> failwith (label + ": not found")
        | Error DeploymentError.Busy -> failwith (label + ": busy")
        | Error DeploymentError.Stale -> failwith (label + ": stale")
        | Error DeploymentError.Cancelled -> failwith (label + ": cancelled")

    let private archiveEntry index (value: string) =
        { Index = index
          Path =
            LogicalPath.create (value.Split('/') |> Array.toList)
            |> Result.defaultWith (fun _ -> invalidOp "Invalid fixture path.")
          Directory = false
          Size = 10L
          CompressedSize = Some 5L }

    let private nexusFile id name version description =
        { Id = id
          Name = name
          Version = version
          Category = "MAIN"
          Description = description
          Bytes = Some 100L }

    let private createArchive (runtime: string) (marker: string) : byte array =
        use output = new MemoryStream()
        use zip = new ZipArchive(output, ZipArchiveMode.Create, true)

        for name, content in
            [ "skse64_" + marker + "/skse64_loader.exe", "loader-" + marker
              "skse64_" + marker + "/skse64_" + runtime.Replace('.', '_') + ".dll",
              "runtime-" + marker
              "skse64_" + marker + "/Data/Scripts/skse.pex", "script-" + marker
              "skse64_" + marker + "/src/readme.txt", "source-" + marker ] do
            use target = zip.CreateEntry(name).Open()
            let bytes = Encoding.UTF8.GetBytes content
            target.Write(bytes)

        zip.Dispose()
        output.ToArray()

    let private downloaded
        (store: OperationStore)
        (workspace: Guid)
        (name: string)
        (bytes: byte array)
        =
        use server = new DownloadServer(bytes)
        let id = Guid.NewGuid()
        let hash = Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant()

        store.Downloads.Start
            { Id = id
              WorkspaceId = workspace
              Name = name
              Sources = [ DownloadSource.Url(server.Url + "/good") ]
              ExpectedLength = Some(int64 bytes.Length)
              ExpectedSha256 = Some hash }
        |> wait
        |> result
        |> ignore

        let deadline = DateTime.UtcNow.AddSeconds 10.
        let mutable artifact = store.Artifacts.Read(workspace, id) |> wait |> result

        while artifact.State = ArtifactState.Incomplete && DateTime.UtcNow < deadline do
            Thread.Sleep 10
            artifact <- store.Artifacts.Read(workspace, id) |> wait |> result

        if artifact.State <> ArtifactState.Ready then
            failwith "The SKSE fixture transfer did not publish a verified archive."

        artifact

    let private resolveReleases (scenario: SkseScenario) : ReleaseEvidence =
        let state = scenario.State
        let runtime = scenario.Runtime

        let modInfo =
            { Game = "skyrimspecialedition"
              Id = SkseResolver.NexusModId
              Name = "SKSE"
              Summary = "Fixture"
              Files =
                [ nexusFile 10L "older" "2.0.0" ("For game version " + runtime + " from Steam")
                  nexusFile 11L "matching" "2.2.0" ("Current game version " + runtime + " from Steam")
                  nexusFile 12L "newer incompatible" "3.0.0" "Current game version 9.9.9.9 from Steam"
                  nexusFile 13L "label only" "4.0.0" "Anniversary Edition" ] }

        let releases = SkseResolver.releases modInfo

        let publicFiles =
            { modInfo with
                Files =
                    [ nexusFile
                          20L
                          "Skyrim Script Extender (SKSE64) Steam"
                          "2.3.1"
                          "Compatible with Skyrim Special Edition 1.7.104 from Steam"
                      nexusFile
                          21L
                          "Skyrim Script Extender (SKSE64) GOG"
                          "9.0.0"
                          "Compatible with Skyrim Special Edition 1.7.104 from GOG.com"
                      nexusFile
                          22L
                          "Skyrim Script Extender (SKSE64) VR"
                          "9.0.0"
                          "Compatible with Skyrim Special Edition 1.7.104 from Steam"
                      nexusFile
                          23L
                          "Skyrim Script Extender (SKSE64) Steam"
                          "9.0.0"
                          "Compatible with Skyrim Special Edition 1.7.104.1 from Steam"
                      nexusFile
                          24L
                          "Skyrim Script Extender (SKSE64)"
                          "9.0.0"
                          "Compatible with Skyrim Special Edition 1.7.104 from Steam and GOG"
                      nexusFile
                          25L
                          "Skyrim Script Extender (SKSE64)"
                          "9.0.0"
                          "Current game version 1.7.104" ] }

        let publicReleases = SkseResolver.releases publicFiles
        let publicSelection = SkseResolver.resolve state publicReleases

        let incompatibleSelection =
            SkseResolver.resolve
                state
                (SkseResolver.releases
                    { publicFiles with
                        Files = publicFiles.Files |> List.filter (fun file -> file.Id <> 20L) })

        let publicSteamMatches =
            publicSelection
            |> Result.toOption
            |> Option.exists (fun release -> release.File.Id = 20L)

        let incompatibleVersionsRejected =
            match incompatibleSelection with
            | Error SkseProblem.UnknownCompatibility -> true
            | _ -> false

        let premium =
            SkseResolver.select
                state
                releases
                (Some
                    { Subject = "42"
                      Name = "Premium"
                      Premium = Some true
                      ProfileImage = None })
            |> Result.defaultWith (fun _ -> invalidOp "Premium SKSE resolution failed.")

        let regular =
            SkseResolver.select
                state
                releases
                (Some
                    { Subject = "43"
                      Name = "Regular"
                      Premium = Some false
                      ProfileImage = None })
            |> Result.defaultWith (fun _ -> invalidOp "Regular SKSE resolution failed.")

        let manifest =
            { Sha256 = String.replicate 64 "a"
              Format = "7z"
              Entries =
                [ archiveEntry 0 "skse64_2_02_00/skse64_loader.exe"
                  archiveEntry 1 "skse64_2_02_00/skse64_1_7_104.dll"
                  archiveEntry 2 "skse64_2_02_00/skse64_steam_loader.dll"
                  archiveEntry 3 "skse64_2_02_00/Data/Scripts/skse.pex"
                  archiveEntry 4 "skse64_2_02_00/readme.txt" ]
              TotalSize = 50L }

        let plan =
            SkseArchiveLayout.review premium.Release manifest
            |> Result.defaultWith (fun _ -> invalidOp "SKSE archive review failed.")

        let currentReleaseLayout =
            SkseArchiveLayout.review
                premium.Release
                { manifest with
                    Entries = manifest.Entries |> List.filter (fun entry -> entry.Index <> 2) }
            |> Result.toOption

        let invalidLayout =
            SkseArchiveLayout.review
                premium.Release
                { manifest with
                    Entries = manifest.Entries |> List.filter (fun entry -> entry.Index <> 3) }
            |> Result.isError

        { Premium = premium
          Regular = regular
          Manifest = manifest
          ExactRuntimeWins = premium.Release.File.Id = 11L
          NewerIncompatibleRejected = premium.Release.File.Id <> 12L
          LabelWithoutRuntimeRejected = releases.Length = 3
          PublicSteamVersionMatches = publicSteamMatches
          OtherStorefrontsRemainIncompatible = incompatibleVersionsRejected
          OrdinaryNexusRoutes =
            premium.Acquisition = SkseAcquisition.Direct
            && regular.Acquisition = SkseAcquisition.NexusPage
          ReviewedArchiveLayout =
            plan.Files.Length = 4
            && plan.ComponentFiles.Length = 4
            && (currentReleaseLayout
                |> Option.exists (fun current ->
                    current.Files.Length = 3 && current.ComponentFiles.Length = 3))
            && invalidLayout }

    let private installInitialRelease (scenario: SkseScenario) (releases: ReleaseEvidence) : InstalledEvidence =
        let store = scenario.Store
        let workspace = scenario.Workspace
        let profile = scenario.Profile
        let game = scenario.Game
        let workspacePath = scenario.WorkspacePath
        let state = scenario.State
        let evidence = scenario.Evidence
        let runtime = scenario.Runtime
        let premium = releases.Premium
        let manifest = releases.Manifest

        let loaderPath = Path.Combine(game, "skse64_loader.exe")
        File.WriteAllText(loaderPath, "fixture loader")
        let generation = Guid.NewGuid()

        store.SkseLoaders.Save(
            workspace,
            profile,
            Guid.NewGuid(),
            Guid.NewGuid(),
            generation,
            loaderPath,
            string premium.Release.ComponentVersion,
            string premium.Release.RuntimeVersion,
            evidence.Executable.Value.Sha256,
            manifest.Sha256,
            premium.Release.ModId,
            premium.Release.File.Id
        )
        |> wait

        let selection =
            (store.SkseLoaders :> IComponentLoaderSelection)
                .Read(workspace, profile, Some generation)
            |> wait

        let wrongGeneration =
            (store.SkseLoaders :> IComponentLoaderSelection)
                .Read(workspace, profile, Some(Guid.NewGuid()))
            |> wait

        let launch =
            ModConductor.GameLaunching.Descriptor.create
                state
                (Path.Combine(workspacePath, ".mc-game-views", profile.ToString("N"), "game"))
                selection
            |> Result.defaultWith invalidOp

        let stale =
            ModConductor.GameLaunching.Descriptor.create
                state
                (Path.Combine(workspacePath, ".mc-game-views", profile.ToString("N"), "game"))
                (selection
                 |> Option.map (fun value ->
                     { value with
                         GameSha256 = String.replicate 64 "0" }))
            |> Result.isError

        let _, runtimeName, descriptor = launch

        let firstArtifact =
            downloaded store workspace "skse-first.zip" (createArchive runtime "first")

        store.SkseLoaders.SaveArtifactSelection(
            firstArtifact,
            { ArtifactId = Some firstArtifact.Id
              WorkspaceId = workspace
              ProfileId = Some profile
              AccountId = "42"
              GameVersion = runtime
              GameSha256 = evidence.Executable.Value.Sha256
              Selection = premium
              CheckedAt = DateTimeOffset.UtcNow }
        )
        |> wait

        let genericDraft =
            store.Installations.Prepare(
                { WorkspaceId = workspace
                  Id = firstArtifact.Id
                  Revision = firstArtifact.Revision },
                CancellationToken.None
            )
            |> wait
            |> result

        let installedGeneration =
            store.InstallSkse(
                workspace,
                profile,
                premium.Release,
                firstArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let ordinarySource =
            store.Deployments.Read profile |> wait |> required "ordinary redeploy source"

        let ordinaryPrepared =
            store.Deployments.Prepare(
                Guid.NewGuid(),
                ordinarySource.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> required "ordinary redeploy preparation"

        let ordinaryReceipt =
            store.Deployments.Activate(
                ordinaryPrepared.Id,
                ordinaryPrepared.Sources,
                ignore,
                CancellationToken.None
            )
            |> wait
            |> required "ordinary redeploy activation"

        let firstGeneration =
            store.Deployments.Read profile
            |> wait
            |> required "ordinary redeploy state"
            |> _.ActiveGeneration.Value

        let deployedFirst =
            store.Deployments.Read profile |> wait |> required "first deployment"

        let firstStored =
            store.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration) |> wait

        let genericComponentContinuity =
            ordinaryReceipt.Phase = DeploymentPhase.Complete
            && installedGeneration <> firstGeneration
            && (firstStored |> Option.exists (fun value ->
                value.Loader.GenerationId = firstGeneration
                && File.Exists(Path.Combine(deployedFirst.RunnableRoot, "skse64_loader.exe"))))

        let genericLaunch =
            (store.GameLaunching.Read(workspace, profile) |> wait)
            |> Result.toOption
            |> Option.exists (fun value -> value.Problem.IsNone)

        let firstEnabled = InventoryObservations.read store profile

        let runnableRoot =
            Path.Combine(workspacePath, ".mc-game-views", profile.ToString("N"), "game")

        let runnableLoader = Path.Combine(runnableRoot, "skse64_loader.exe")

        { FirstGeneration = firstGeneration
          FirstStored = firstStored
          FirstEnabled = firstEnabled
          LoaderPath = loaderPath
          GenerationBoundLoader = selection.IsSome && wrongGeneration.IsNone && stale
          ProtonUsesLoader =
            if OperatingSystem.IsLinux() then
                descriptor.Arguments |> List.tryLast = Some runnableLoader
                && descriptor.WorkingDirectory = runnableRoot
                && runtimeName = evidence.Proton.Value.RuntimeName
            else
                descriptor.Executable = runnableLoader && descriptor.WorkingDirectory = runnableRoot
          TransferArchiveInstallGeneration =
            genericDraft.Installer = InstallationMode.Bain
            && (firstArtifact.Download |> Option.exists (fun value -> value.ChecksumMatched))
            && deployedFirst.ActiveGeneration = Some firstGeneration
            && (firstStored |> Option.exists (fun value -> value.Loader.Executable = loaderPath))
          OrdinaryRedeployRetainsComponentRouteAndLaunch =
            genericComponentContinuity && genericLaunch }

    let private replaceInterruptedRelease
        (scenario: SkseScenario)
        (releases: ReleaseEvidence)
        (installed: InstalledEvidence)
        setInterruptReplacement
        : UpdatedEvidence =
        let store = scenario.Store
        let workspace = scenario.Workspace
        let profile = scenario.Profile
        let runtime = scenario.Runtime
        let premium = releases.Premium
        let firstGeneration = installed.FirstGeneration
        let firstEnabled = installed.FirstEnabled

        let updateRelease =
            { premium.Release with
                File = nexusFile 14L "matching update" "2.3.0" ("Current game version " + runtime + " from Steam")
                ComponentVersion = Version(2, 3, 0) }

        let updateArtifact =
            downloaded store workspace "skse-update.zip" (createArchive runtime "update")

        setInterruptReplacement true

        let interruptedReplacement =
            try
                store.InstallSkse(
                    workspace,
                    profile,
                    updateRelease,
                    updateArtifact,
                    DateTimeOffset.UtcNow,
                    CancellationToken.None
                )
                |> wait
                |> ignore

                false
            with _ ->
                true

        let afterInterrupted =
            store.Deployments.Read profile |> wait |> required "interrupted deployment"

        let afterInterruptedLoader =
            store.SkseLoaders.ReadStored(workspace, profile, afterInterrupted.ActiveGeneration)
            |> wait

        let afterInterruptedSelection = InventoryObservations.read store profile

        let enabled (page: ModQueryPage) =
            page.Entries
            |> List.choose (fun row ->
                match row.Entry.Selection with
                | SelectionState.Managed(_, true) -> Some row.Entry.Mod.Id
                | _ -> None)
            |> Set.ofList

        let recoveredReplacement = afterInterrupted.PendingReceipt.IsNone

        setInterruptReplacement false

        let updatedGeneration =
            store.InstallSkse(
                workspace,
                profile,
                updateRelease,
                updateArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let updatedStored =
            store.SkseLoaders.ReadStored(workspace, profile, Some updatedGeneration) |> wait

        let retainedFirst =
            store.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration) |> wait

        { Release = updateRelease
          Artifact = updateArtifact
          Generation = updatedGeneration
          Stored = updatedStored
          FailedReplacementPreservesSelectionGenerationAndLoader =
            interruptedReplacement
            && recoveredReplacement
            && afterInterrupted.ActiveGeneration = Some firstGeneration
            && (afterInterruptedLoader
                |> Option.exists (fun value -> value.Loader.GenerationId = firstGeneration))
            && enabled firstEnabled = enabled afterInterruptedSelection
          UpdatedLoaderCorrect =
            updatedStored
            |> Option.exists (fun value -> value.Loader.ComponentVersion = "2.3.0")
          RetainedFirstCorrect =
            retainedFirst
            |> Option.exists (fun value ->
                value.Loader.ComponentVersion = string premium.Release.ComponentVersion) }

    let private removeInstalledRelease
        (scenario: SkseScenario)
        (installed: InstalledEvidence)
        (updated: UpdatedEvidence)
        : bool =
        let store = scenario.Store
        let workspace = scenario.Workspace
        let profile = scenario.Profile
        let loaderPath = installed.LoaderPath
        let updatedStored = updated.Stored

        let selectedAfterUpdate = InventoryObservations.read store profile
        let updatedMod = updatedStored.Value.ModId

        (store.ModSelection :> IModSelection)
            .Change(
                profile,
                selectedAfterUpdate.SelectionRevision,
                [ updatedMod ],
                SelectionEdit.Enable false
            )
        |> wait
        |> result
        |> ignore

        let removalSources =
            store.Deployments.Read profile |> wait |> required "removal sources"

        let removal =
            store.PrepareComponents(
                Guid.NewGuid(),
                removalSources.Sources,
                [],
                ignore,
                CancellationToken.None
            )
            |> wait
            |> Result.mapError DeploymentReports.error
            |> required "SKSE removal preparation"

        let removalReceipt =
            store.Generations.Start(removal, [])
            |> wait
            |> Result.defaultWith (fun _ -> failwith "SKSE removal did not start.")

        store.Generations.Run(
            removalReceipt.Id,
            removalReceipt.Revision,
            false,
            CancellationToken.None,
            (fun _ _ -> ()),
            []
        )
        |> wait
        |> Result.defaultWith (fun _ -> failwith "SKSE removal did not complete.")
        |> ignore

        let removedDeployment =
            store.Deployments.Read profile |> wait |> required "removed deployment"

        let removedLoader =
            store.SkseLoaders.ReadStored(workspace, profile, removedDeployment.ActiveGeneration)
            |> wait

        let foreignLoaderRestored = File.ReadAllText(loaderPath) = "fixture loader"

        removedLoader.IsNone && foreignLoaderRestored

    let private persistedLoaderAndStatus
        (scenario: SkseScenario)
        (releases: ReleaseEvidence)
        (installed: InstalledEvidence)
        (updated: UpdatedEvidence)
        : DurableEvidence =
        let store = scenario.Store
        let area = scenario.Area
        let workspace = scenario.Workspace
        let profile = scenario.Profile
        let evidence = scenario.Evidence
        let runtime = scenario.Runtime
        let regular = releases.Regular
        let firstGeneration = installed.FirstGeneration
        let updatedGeneration = updated.Generation

        let cachedBeforeRestart =
            store.SkseLoaders.Cached(workspace, "42", evidence.Executable.Value.Sha256)
            |> wait

        let pendingSelection =
            { ArtifactId = None
              WorkspaceId = workspace
              ProfileId = Some profile
              AccountId = "43"
              GameVersion = runtime
              GameSha256 = evidence.Executable.Value.Sha256
              Selection = regular
              CheckedAt = DateTimeOffset.UtcNow }

        store.SkseLoaders.SavePending pendingSelection |> wait

        store.SkseLoaders.SaveStatus
            { WorkspaceId = workspace
              ProfileId = profile
              Phase = "waiting"
              GameVersion = runtime
              ComponentVersion = string regular.Release.ComponentVersion
              Status = "Waiting for Nexus Mods"
              Detail = "Select the matching file."
              NexusFileId = Some regular.Release.File.Id
              CheckedAt = DateTimeOffset.UtcNow }
        |> wait

        let restartedGenerationBound, coldCached, durableWaiting =
            use reopened = new OperationStore(Path.Combine(area, "state"))

            let prior =
                reopened.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration)
                |> wait

            let update =
                reopened.SkseLoaders.ReadStored(workspace, profile, Some updatedGeneration)
                |> wait

            let cached =
                reopened.SkseLoaders.Cached(workspace, "42", evidence.Executable.Value.Sha256)
                |> wait

            let pending = reopened.SkseLoaders.Pending() |> wait
            let status = reopened.SkseLoaders.ReadStatus(workspace, profile) |> wait

            prior.IsSome && update.IsSome,
            cached.IsSome,
            (pending |> List.exists (fun value -> value.ProfileId = Some profile))
            && (status |> Option.exists (fun value -> value.Phase = "waiting"))

        store.SkseLoaders.RemovePending profile |> wait

        store.SkseLoaders.SaveStatus
            { WorkspaceId = workspace
              ProfileId = profile
              Phase = "failed"
              GameVersion = runtime
              ComponentVersion = string regular.Release.ComponentVersion
              Status = "This link belongs to another Nexus account"
              Detail = "Use the Nexus account that started this SKSE setup."
              NexusFileId = Some regular.Release.File.Id
              CheckedAt = DateTimeOffset.UtcNow }
        |> wait

        let durableFailure =
            use reopened = new OperationStore(Path.Combine(area, "state"))

            reopened.SkseLoaders.ReadStatus(workspace, profile)
            |> wait
            |> Option.exists (fun value ->
                value.Phase = "failed"
                && value.Status = "This link belongs to another Nexus account")

        { RestartedGenerationBound = restartedGenerationBound
          ColdRestartRetainsCacheAndLoaderProvenance =
            cachedBeforeRestart.IsSome && restartedGenerationBound && coldCached
          NxmWaitingAndFailureAreDurable = durableWaiting && durableFailure }

    let private reuseAndDeleteReleases
        (scenario: SkseScenario)
        (installed: InstalledEvidence)
        (updated: UpdatedEvidence)
        : ReuseEvidence =
        let store = scenario.Store
        let workspaces = store.Workspaces :> IWorkspaceState
        let workspace = scenario.Workspace
        let profile = scenario.Profile
        let game = scenario.Game
        let proton = scenario.Proton
        let runtime = scenario.Runtime
        let firstStored = installed.FirstStored
        let firstGeneration = installed.FirstGeneration
        let updateRelease = updated.Release
        let updateArtifact = updated.Artifact
        let updatedStored = updated.Stored

        let otherProfile = Guid.NewGuid()
        let workspaceRevision =
            (workspaces.Read(workspace, None) |> wait |> result).Workspace.Revision

        workspaces.Edit(
            workspace,
            workspaceRevision,
            ProfileEdit.Create { Id = otherProfile; Name = "Other profile" }
        )
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                otherProfile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let sameArchive =
            downloaded store workspace "skse-update-again.zip" (File.ReadAllBytes updateArtifact.Path)

        let otherGeneration =
            store.InstallSkse(
                workspace,
                otherProfile,
                updateRelease,
                sameArchive,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let otherInstalled =
            store.SkseLoaders.ReadStored(workspace, otherProfile, Some otherGeneration)
            |> wait
            |> Option.get

        let otherFirstInstall =
            otherInstalled.ModId = updatedStored.Value.ModId
            && otherInstalled.VersionId = updatedStored.Value.VersionId
            && ((store.Artifacts.Read(workspace, sameArchive.Id) |> wait |> result).Links
                |> List.exists (fun link ->
                    link.ModId = otherInstalled.ModId
                    && link.VersionId = otherInstalled.VersionId))

        let otherBefore = InventoryObservations.read store otherProfile

        let library = store.ModLibrary :> IModLibrary
        let imported = updatedStored.Value
        let importedContents = library.Version(imported.VersionId, 0) |> wait |> result
        let linksBefore = (store.Artifacts.Read(workspace, updateArtifact.Id) |> wait |> result).Links

        let reusedGeneration =
            store.InstallSkse(
                workspace,
                profile,
                updateRelease,
                updateArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let reused =
            store.SkseLoaders.ReadStored(workspace, profile, Some reusedGeneration)
            |> wait
            |> Option.get

        store.RemoveSkse(workspace, profile, CancellationToken.None) |> wait |> result |> ignore

        let restoredGeneration =
            store.InstallSkse(
                workspace,
                profile,
                updateRelease,
                updateArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let restored =
            store.SkseLoaders.ReadStored(workspace, profile, Some restoredGeneration)
            |> wait
            |> Option.get

        let linksAfter = (store.Artifacts.Read(workspace, updateArtifact.Id) |> wait |> result).Links
        let restoredContents = library.Version(restored.VersionId, 0) |> wait |> result
        let otherAfter = InventoryObservations.read store otherProfile

        let sameReleaseReused =
            reused.ModId = imported.ModId
            && reused.VersionId = imported.VersionId
            && restored.ModId = imported.ModId
            && restored.VersionId = imported.VersionId
            && linksAfter = linksBefore
            && restoredContents.Entries = importedContents.Entries
            && otherAfter.SelectionRevision = otherBefore.SelectionRevision
            && otherAfter.Entries = otherBefore.Entries

        let firstMod = firstStored.Value.ModId

        let firstEntry =
            (library.Scan(workspace, 100) |> wait |> result).Entries
            |> List.find (fun entry -> entry.Id = firstMod)

        store.Deletions.Delete(workspace, firstMod, firstEntry.Revision)
        |> wait
        |> result
        |> ignore

        let deletedSkseReferences =
            (store.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration) |> wait).IsNone
            && (store.SkseLoaders.ReadStored(workspace, profile, Some restoredGeneration)
                |> wait
                |> Option.exists (fun value -> value.ModId = imported.ModId))

        let nextRelease =
            { updateRelease with
                File = nexusFile 15L "later update" "2.4.0" ("Current game version " + runtime + " from Steam")
                ComponentVersion = Version(2, 4, 0) }

        let nextArtifact =
            downloaded store workspace "skse-after-delete.zip" (createArchive runtime "after-delete")

        let afterDeleteGeneration =
            store.InstallSkse(
                workspace,
                profile,
                nextRelease,
                nextArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait
            |> result

        let importAfterDeletion =
            store.SkseLoaders.ReadStored(workspace, profile, Some afterDeleteGeneration)
            |> wait
            |> Option.exists (fun value ->
                value.ModId <> firstMod && value.ModId <> imported.ModId)

        { SameSkseSourceReusesImportedVersionAfterRemoval = sameReleaseReused
          SecondProfileUsesAvailableSkseVersion = otherFirstInstall
          DifferentSkseReleaseStaysDistinct = firstMod <> imported.ModId
          DeletingOldSkseModRemovesOnlyItsLoaderHistory = deletedSkseReferences
          NewSkseReleaseImportsAfterDeletingOlderMod = importAfterDeletion }

    let observe (writer: Utf8JsonWriter) primary =
        let area = Directory.CreateDirectory(Path.Combine(primary, "skse")).FullName

        let workspacePath =
            Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName

        let game, proton = ProtonFixtures.create (Path.Combine(area, "installation"))

        if OperatingSystem.IsLinux() then
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

        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()

        let mutable interruptReplacement = false

        use store =
            new OperationStore(
                Path.Combine(area, "state"),
                skseCheckpoint =
                    (fun name _ ->
                        if interruptReplacement && name = "install-intent" then
                            raise (OperationCanceledException()))
            )

        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "SKSE", StorageWorker.select workspacePath)
            |> wait
            |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "SKSE" }
        )
        |> wait
        |> result
        |> ignore

        (store.GameContexts :> IGameContexts)
            .Save(
                workspace,
                profile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let state = (store.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result
        let evidence = state.Binding.Value.Evidence
        let runtime = evidence.Executable.Value.FileVersion

        let scenario =
            { Area = area
              WorkspacePath = workspacePath
              Workspace = workspace
              Profile = profile
              Game = game
              Proton = proton
              Store = store
              State = state
              Evidence = evidence
              Runtime = runtime }

        let releases = resolveReleases scenario

        let installed = installInitialRelease scenario releases

        let updated =
            replaceInterruptedRelease scenario releases installed (fun value -> interruptReplacement <- value)

        let removed = removeInstalledRelease scenario installed updated

        let durable = persistedLoaderAndStatus scenario releases installed updated

        let reused = reuseAndDeleteReleases scenario installed updated

        writer.WriteStartObject("skse")
        writer.WriteBoolean("exactRuntimeWins", releases.ExactRuntimeWins)
        writer.WriteBoolean("newerIncompatibleRejected", releases.NewerIncompatibleRejected)
        writer.WriteBoolean("labelWithoutRuntimeRejected", releases.LabelWithoutRuntimeRejected)
        writer.WriteBoolean("publicSteamVersionMatchesPeVersion", releases.PublicSteamVersionMatches)

        writer.WriteBoolean(
            "otherStorefrontsMissingDeclarationsAndRevisionsRemainIncompatible",
            releases.OtherStorefrontsRemainIncompatible
        )

        writer.WriteBoolean("ordinaryNexusRoutes", releases.OrdinaryNexusRoutes)
        writer.WriteBoolean("reviewedArchiveLayout", releases.ReviewedArchiveLayout)
        writer.WriteBoolean("generationBoundLoader", installed.GenerationBoundLoader)
        writer.WriteBoolean("protonUsesLoader", installed.ProtonUsesLoader)
        writer.WriteBoolean("transferArchiveInstallGeneration", installed.TransferArchiveInstallGeneration)

        writer.WriteBoolean(
            "ordinaryRedeployRetainsComponentRouteAndLaunch",
            installed.OrdinaryRedeployRetainsComponentRouteAndLaunch
        )

        writer.WriteBoolean(
            "failedReplacementPreservesSelectionGenerationAndLoader",
            updated.FailedReplacementPreservesSelectionGenerationAndLoader
        )

        writer.WriteBoolean(
            "updateRetainsImmutableGenerationLoaders",
            updated.UpdatedLoaderCorrect
            && updated.RetainedFirstCorrect
            && durable.RestartedGenerationBound
        )

        writer.WriteBoolean(
            "removalRestoresForeignLoaderAndDropsActiveProvenance",
            removed
        )

        writer.WriteBoolean(
            "coldRestartRetainsCacheAndLoaderProvenance",
            durable.ColdRestartRetainsCacheAndLoaderProvenance
        )

        writer.WriteBoolean("nxmWaitingAndFailureAreDurable", durable.NxmWaitingAndFailureAreDurable)

        writer.WriteBoolean(
            "sameSkseSourceReusesImportedVersionAfterRemoval",
            reused.SameSkseSourceReusesImportedVersionAfterRemoval
        )

        writer.WriteBoolean(
            "secondProfileUsesAvailableSkseVersion",
            reused.SecondProfileUsesAvailableSkseVersion
        )

        writer.WriteBoolean(
            "differentSkseReleaseStaysDistinct",
            reused.DifferentSkseReleaseStaysDistinct
        )

        writer.WriteBoolean(
            "deletingOldSkseModRemovesOnlyItsLoaderHistory",
            reused.DeletingOldSkseModRemovesOnlyItsLoaderHistory
        )

        writer.WriteBoolean(
            "newSkseReleaseImportsAfterDeletingOlderMod",
            reused.NewSkseReleaseImportsAfterDeletingOlderMod
        )

        GenerationCleanup.normalize area
        writer.WriteEndObject()
