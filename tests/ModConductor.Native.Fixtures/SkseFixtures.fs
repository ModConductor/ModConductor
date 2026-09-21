namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Deployment
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.HttpDownloads
open ModConductor.ModSelection
open ModConductor.ModOrganization
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Skse
open ModConductor.Workspaces

module SkseFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

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
              "skse64_" + marker + "/skse64_steam_loader.dll", "steam-" + marker
              "skse64_" + marker + "/Data/Scripts/skse.pex", "script-" + marker ] do
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

    let observe (writer: Utf8JsonWriter) primary =
        let required label (value: Result<'a, DeploymentError>) =
            match value with
            | Ok value -> value
            | Error(DeploymentError.Blocked detail)
            | Error(DeploymentError.Unavailable detail) -> failwith (label + ": " + detail)
            | Error DeploymentError.NotFound -> failwith (label + ": not found")
            | Error DeploymentError.Busy -> failwith (label + ": busy")
            | Error DeploymentError.Stale -> failwith (label + ": stale")
            | Error DeploymentError.Cancelled -> failwith (label + ": cancelled")

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
                0L,
                { Path = game
                  Proton = if OperatingSystem.IsLinux() then Some proton else None }
            )
        |> wait
        |> result
        |> ignore

        let state = (store.GameContexts :> IGameContexts).Read workspace |> wait |> result
        let evidence = state.Binding.Value.Evidence
        let runtime = evidence.Executable.Value.FileVersion

        let modInfo =
            { Game = "skyrimspecialedition"
              Id = SkseResolver.NexusModId
              Name = "SKSE"
              Summary = "Fixture"
              Files =
                [ nexusFile 10L "older" "2.0.0" ("For game version " + runtime)
                  nexusFile 11L "matching" "2.2.0" ("Current game version " + runtime)
                  nexusFile 12L "newer incompatible" "3.0.0" "Current game version 9.9.9.9"
                  nexusFile 13L "label only" "4.0.0" "Anniversary Edition" ] }

        let releases = SkseResolver.releases modInfo

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

        let invalidLayout =
            SkseArchiveLayout.review
                premium.Release
                { manifest with
                    Entries = manifest.Entries |> List.filter (fun entry -> entry.Index <> 3) }
            |> Result.isError

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
            ModConductor.GameLaunching.Descriptor.create state selection
            |> Result.defaultWith invalidOp

        let stale =
            ModConductor.GameLaunching.Descriptor.create
                state
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

        let firstGeneration =
            store.InstallSkse(
                workspace,
                profile,
                premium.Release,
                firstArtifact,
                DateTimeOffset.UtcNow,
                CancellationToken.None
            )
            |> wait

        let deployedFirst =
            store.Deployments.Read profile |> wait |> required "first deployment"

        let firstStored =
            store.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration) |> wait

        let firstEnabled = InventoryObservations.read store profile

        let updateRelease =
            { premium.Release with
                File = nexusFile 14L "matching update" "2.3.0" ("Current game version " + runtime)
                ComponentVersion = Version(2, 3, 0) }

        let updateArtifact =
            downloaded store workspace "skse-update.zip" (createArchive runtime "update")

        interruptReplacement <- true

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

        interruptReplacement <- false

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

        let updatedStored =
            store.SkseLoaders.ReadStored(workspace, profile, Some updatedGeneration) |> wait

        let retainedFirst =
            store.SkseLoaders.ReadStored(workspace, profile, Some firstGeneration) |> wait

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

        writer.WriteStartObject("skse")
        writer.WriteBoolean("exactRuntimeWins", premium.Release.File.Id = 11L)
        writer.WriteBoolean("newerIncompatibleRejected", premium.Release.File.Id <> 12L)
        writer.WriteBoolean("labelWithoutRuntimeRejected", releases.Length = 3)

        writer.WriteBoolean(
            "ordinaryNexusRoutes",
            premium.Acquisition = SkseAcquisition.Direct
            && regular.Acquisition = SkseAcquisition.NexusPage
        )

        writer.WriteBoolean(
            "reviewedArchiveLayout",
            plan.Files.Length = 4 && plan.ComponentFiles.Length = 4 && invalidLayout
        )

        writer.WriteBoolean(
            "generationBoundLoader",
            selection.IsSome && wrongGeneration.IsNone && stale
        )

        writer.WriteBoolean(
            "protonUsesLoader",
            if OperatingSystem.IsLinux() then
                descriptor.Arguments |> List.tryLast = Some loaderPath
                && descriptor.WorkingDirectory = game
                && runtimeName = evidence.Proton.Value.RuntimeName
            else
                descriptor.Executable = loaderPath && descriptor.WorkingDirectory = game
        )

        writer.WriteBoolean(
            "transferArchiveInstallGeneration",
            firstArtifact.Download |> Option.exists (fun value -> value.ChecksumMatched)
            && deployedFirst.ActiveGeneration = Some firstGeneration
            && (firstStored |> Option.exists (fun value -> value.Loader.Executable = loaderPath))
        )

        writer.WriteBoolean(
            "failedReplacementPreservesSelectionGenerationAndLoader",
            interruptedReplacement
            && recoveredReplacement
            && afterInterrupted.ActiveGeneration = Some firstGeneration
            && (afterInterruptedLoader
                |> Option.exists (fun value -> value.Loader.GenerationId = firstGeneration))
            && enabled firstEnabled = enabled afterInterruptedSelection
        )

        writer.WriteBoolean(
            "updateRetainsImmutableGenerationLoaders",
            (updatedStored
             |> Option.exists (fun value -> value.Loader.ComponentVersion = "2.3.0"))
            && (retainedFirst
                |> Option.exists (fun value ->
                    value.Loader.ComponentVersion = string premium.Release.ComponentVersion))
            && restartedGenerationBound
        )

        writer.WriteBoolean(
            "removalRestoresForeignLoaderAndDropsActiveProvenance",
            removedLoader.IsNone && foreignLoaderRestored
        )

        writer.WriteBoolean(
            "coldRestartRetainsCacheAndLoaderProvenance",
            cachedBeforeRestart.IsSome && restartedGenerationBound && coldCached
        )

        writer.WriteBoolean("nxmWaitingAndFailureAreDurable", durableWaiting && durableFailure)

        GenerationCleanup.normalize area
        writer.WriteEndObject()
