namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Credentials
open ModConductor.Enb
open ModConductor.Engine
open ModConductor.GameLaunching
open ModConductor.GameContexts
open ModConductor.DeploymentRecovery
open ModConductor.ProfileGameData
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Platform
open ModConductor.Workspaces

module EnbFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    let private check (writer: Utf8JsonWriter) (name: string) (value: bool) =
        writer.WriteBoolean(name, value)
        writer.Flush()

        if not value then
            failwith ("ENB fixture failed: " + name)

    let private entry index parts size =
        { Index = index
          Path =
            LogicalPath.create parts
            |> Result.defaultWith (fun _ -> invalidOp "Invalid fixture path.")
          Directory = false
          Size = size
          CompressedSize = Some(max 1L (size / 2L)) }

    let private manifest hash entries =
        { Sha256 = hash
          Format = "ZIP"
          Entries = entries
          TotalSize = entries |> List.sumBy _.Size }

    let private createWorkspace (store: OperationStore) area =
        let workspace, profile = Guid.NewGuid(), Guid.NewGuid()
        let root = Directory.CreateDirectory(Path.Combine(area, "workspace")).FullName
        let workspaces = store.Workspaces :> IWorkspaceState

        let created =
            workspaces.Create(workspace, "ENB", StorageWorker.select root) |> wait |> result

        workspaces.Edit(
            workspace,
            created.Workspace.Revision,
            ProfileEdit.Create { Id = profile; Name = "ENB" }
        )
        |> wait
        |> result
        |> ignore

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

        let data = store.ProfileGameData
        let current = data.Read(workspace, profile) |> wait |> result

        let enabled =
            data.Edit(
                { Id = Guid.NewGuid()
                  Expected = current.Reference
                  Options = { Settings = true; Saves = false }
                  InitialSaves = InitialSaves.Empty
                  DisabledFiles = DisabledFiles.Keep },
                ignore,
                CancellationToken.None
            )
            |> wait
            |> result

        let prefs = Path.Combine(enabled.State.SettingsPath, "SkyrimPrefs.ini")
        File.WriteAllText(prefs, "[Display]\nbSAOEnable=1\nbEnableImprovedSnow=1\n")
        workspace, profile, game, prefs

    let private archive path (entries: (string * string) list) =
        use output = File.Create path
        use zip = new ZipArchive(output, ZipArchiveMode.Create)

        for name, value in entries do
            use target = zip.CreateEntry(name).Open()
            let bytes = Encoding.UTF8.GetBytes value
            target.Write bytes

    let private artifact (store: OperationStore) workspace path =
        store.Artifacts.Add(
            { Id = Guid.NewGuid()
              WorkspaceId = workspace
              Path = path
              Storage = ArtifactStorage.Reference },
            CancellationToken.None
        )
        |> wait
        |> result

    type private Handoff() =
        let opened = ResizeArray<Uri>()
        member _.Opened = List.ofSeq opened

        interface IOAuthHandoff with
            member _.Listen(_, _) = raise (NotSupportedException())

            member _.Open(uri, _) =
                opened.Add uri
                Task.CompletedTask

    type private EmptyCredentialStore() =
        interface ICredentialStore with
            member _.Kind = StorageKind.Unavailable

            member _.Inspect _ =
                { Saved = SavedPresence.Absent
                  Problem = None }

            member _.Save(_, _) = Ok()
            member _.Read _ = Ok None
            member _.Delete _ = Ok()

    let private unsafeArchive path entryName =
        use output = File.Create path
        use archive = new ZipArchive(output, ZipArchiveMode.Create)
        use target = archive.CreateEntry(entryName).Open()
        let bytes = Encoding.UTF8.GetBytes "payload"
        target.Write bytes

    let private inspectFails (store: OperationStore) workspace path =
        let id = Guid.NewGuid()

        let artifact =
            store.Artifacts.Add(
                { Id = id
                  WorkspaceId = workspace
                  Path = path
                  Storage = ArtifactStorage.Reference },
                CancellationToken.None
            )
            |> wait
            |> result

        let reference =
            { WorkspaceId = workspace
              Id = artifact.Id
              Revision = artifact.Revision }

        try
            store.ArchiveInspection.Inspect(reference, CancellationToken.None)
            |> wait
            |> result
            |> ignore

            false
        with _ ->
            true

    let observe (writer: Utf8JsonWriter) primary =
        writer.WriteStartObject("enb")
        let area = Directory.CreateDirectory(Path.Combine(primary, "enb")).FullName
        let runtimeHash = String.replicate 64 "a"
        let presetHash = String.replicate 64 "b"
        let companionHash = String.replicate 64 "c"

        let catalogue = EnbCatalogue.lean

        let row =
            { catalogue with
                Runtime = EnbCatalogue.withHash runtimeHash catalogue.Runtime
                Preset = EnbCatalogue.withHash presetHash catalogue.Preset
                Companions = catalogue.Companions |> List.map (EnbCatalogue.withHash companionHash) }

        let runtimeManifest =
            manifest
                runtimeHash
                [ entry 0 [ "WrapperVersion"; "d3d11.dll" ] 10L
                  entry 1 [ "WrapperVersion"; "d3dcompiler_46e.dll" ] 20L
                  entry 2 [ "InjectorVersion"; "ENBInjector.exe" ] 30L ]

        check
            writer
            "exactRuntimeLayout"
            (match EnbArchiveLayouts.runtime row.Runtime runtimeManifest with
             | Ok plan ->
                 plan.ComponentFiles.Length = 2
                 && plan.ComponentFiles
                    |> List.forall (fun file ->
                        file.Root = ModConductor.DeploymentPlanning.ComponentRoot.GameRoot)
             | Error _ -> false)

        let wrongHash =
            EnbArchiveLayouts.runtime
                row.Runtime
                { runtimeManifest with
                    Sha256 = String.replicate 64 "0" }

        check
            writer
            "wrongRuntimeHashRejected"
            (match wrongHash with
             | Error EnbProblem.WrongArchiveHash -> true
             | _ -> false)

        check
            writer
            "incompleteRuntimeRejected"
            (EnbArchiveLayouts.runtime
                row.Runtime
                { runtimeManifest with
                    Entries = [ runtimeManifest.Entries.Head ] }
             |> Result.isError)

        let presetManifest =
            manifest
                presetHash
                [ entry 0 [ "Lean ENB"; "enbseries.ini" ] 10L
                  entry 1 [ "Lean ENB"; "enblocal.ini" ] 10L
                  entry 2 [ "Lean ENB"; "enbseries"; "enbeffect.fx" ] 10L
                  entry 3 [ "Lean Reshade"; "Lean_Cinematic.ini" ] 10L ]

        check
            writer
            "presetKeepsConfigurationWritable"
            (match EnbArchiveLayouts.leanPreset row.Preset presetManifest with
             | Ok plan ->
                 plan.ComponentFiles
                 |> List.exists (fun file ->
                     LogicalPath.display file.Destination = "enblocal.ini"
                     && file.Use = ModConductor.DeploymentPlanning.ComponentFileUse.WritableConfiguration)
             | Error _ -> false)

        let companionManifest =
            manifest
                companionHash
                [ entry 0 [ "Cathedral Weathers"; "Data"; "Cathedral Weathers.esp" ] 10L
                  entry 1 [ "Cathedral Weathers"; "Data"; "Textures"; "sky.dds" ] 10L ]

        check
            writer
            "companionMapsOnlyData"
            (match EnbArchiveLayouts.dataCompanion row.Companions.Head companionManifest with
             | Ok plan ->
                 plan.ComponentFiles.Length = 2
                 && plan.ComponentFiles
                    |> List.forall (fun file ->
                        file.Root = ModConductor.DeploymentPlanning.ComponentRoot.Data)
             | Error _ -> false)

        let leanMod =
            { Game = "skyrimspecialedition"
              Id = EnbCatalogue.LeanModId
              Name = "Lean ENB"
              Summary = ""
              Files =
                [ { Id = 100L
                    Name = "Lean ENB"
                    Version = "1.0.0"
                    Category = "Main files"
                    Description = ""
                    Bytes = Some 100L }
                  { Id = 101L
                    Name = "Unpinned update"
                    Version = "1.1.0"
                    Category = "MAIN"
                    Description = ""
                    Bytes = Some 100L } ] }

        check
            writer
            "pinnedPresetProvenance"
            (EnbCatalogue.resolveNexusFile row.Preset leanMod
             |> Result.exists (fun file -> file.Id = 100L)
             && row.Companions.Head.NexusModId = Some EnbCatalogue.CathedralModId
             && row.Preset.ExpectedSha256 = Some presetHash
             && row.Companions.Head.ExpectedSha256 = Some companionHash)

        check
            writer
            "approvedCatalogueResolvesHashesAtAcquisition"
            (EnbCatalogue.lean.Runtime.Terms.AbsoluteUri = EnbCatalogue.OfficialTerms
             && EnbCatalogue.lean.Preset.Terms.Query = "?tab=description"
             && EnbCatalogue.lean.Companions.Head.Terms.Query = "?tab=description"
             && EnbCatalogue.lean.Runtime.ExpectedSha256.IsNone
             && EnbCatalogue.lean.Preset.ExpectedSha256.IsNone
             && EnbCatalogue.lean.Companions.Head.ExpectedSha256.IsNone)

        let previous =
            Map.ofList
                [ ("SkyrimPrefs.ini", "Display", "bSAOEnable"), "1"
                  ("SkyrimPrefs.ini", "Display", "bEnableImprovedSnow"), "1" ]

        let generation = Guid.NewGuid()

        let launch =
            EnbSetupPlanning.runtime generation "game-hash" "GE-Proton" row.DllOverrides previous
            |> EnbSetupPlanning.validate

        check
            writer
            "runtimePlanPreservesPriorValues"
            (match launch with
             | Ok plan ->
                 plan.PreservedRuntime = "GE-Proton"
                 && not plan.SteamOptionsChanged
                 && plan.ExternalTools.IsEmpty
                 && plan.Configuration |> List.forall _.PreviousValue.IsSome
                 && plan.Environment = [ "WINEDLLOVERRIDES", Some "d3d11=n,b" ]
             | Error _ -> false)

        let foreignConflict =
            EnbSetupPlanning.reviewForeignFiles [ "d3d11.dll" ] |> Result.isError

        let profileConflict =
            EnbSetupPlanning.reviewOwnership
                (Guid.NewGuid())
                generation
                (Some
                    { ProfileId = Guid.NewGuid()
                      GenerationId = Guid.NewGuid()
                      Renderer = "Community Shaders"
                      Preset = "Custom" })
            |> Result.isError

        check writer "profileAndForeignConflictsRefused" (foreignConflict && profileConflict)

        let mutable interrupt = false

        use store =
            new OperationStore(
                Path.Combine(area, "state"),
                enbCheckpoint =
                    (fun name _ ->
                        if interrupt && name = "install-intent" then
                            raise (OperationCanceledException()))
            )

        let workspace, profile, game, prefs = createWorkspace store area
        let handoff = Handoff()
        use credentials = new CredentialSession(EmptyCredentialStore())

        use nexus =
            new NexusSession(credentials, None, handoff, (fun _ -> Task.CompletedTask))

        use coordinator =
            new EnbCoordinator(
                nexus,
                store.Downloads,
                store,
                handoff,
                row,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        let opened = coordinator.OpenAuthorPage(workspace, profile) |> wait
        let restarted = coordinator.Read(workspace, profile) |> wait
        let cancelled = coordinator.Cancel(workspace, profile) |> wait
        let openedAgain = coordinator.OpenAuthorPage(workspace, profile) |> wait

        let onlyOfficialPage =
            handoff.Opened
            |> List.forall (fun uri -> string uri = EnbCatalogue.OfficialPage)

        check
            writer
            "authorPageWaitCancelRestart"
            (handoff.Opened.Length = 2
             && onlyOfficialPage
             && opened.Phase = ModConductor.Protocol.V1.EnbPhase.WaitingForArchive
             && restarted.Phase = ModConductor.Protocol.V1.EnbPhase.WaitingForArchive
             && cancelled.Phase = ModConductor.Protocol.V1.EnbPhase.Available
             && openedAgain.Phase = ModConductor.Protocol.V1.EnbPhase.WaitingForArchive)

        let traversal = Path.Combine(area, "traversal.zip")
        unsafeArchive traversal "../d3d11.dll"
        let corrupt = Path.Combine(area, "corrupt.zip")
        File.WriteAllBytes(corrupt, [| 1uy; 2uy; 3uy; 4uy |])

        check writer "traversalArchiveRejected" (inspectFails store workspace traversal)
        check writer "corruptArchiveRejected" (inspectFails store workspace corrupt)

        let runtimePath = Path.Combine(area, "enbseries_skyrimse_v0505.zip")

        archive
            runtimePath
            [ "WrapperVersion/d3d11.dll", "runtime"
              "WrapperVersion/d3dcompiler_46e.dll", "compiler" ]

        let presetPath = Path.Combine(area, "lean-enb.zip")

        archive
            presetPath
            [ "Lean ENB/enbseries.ini", "preset"
              "Lean ENB/enblocal.ini", "local"
              "Lean ENB/enbseries/enbeffect.fx", "effect" ]

        let companionPath = Path.Combine(area, "cathedral.zip")

        archive
            companionPath
            [ "Cathedral Weathers/Data/Cathedral Weathers.esp", "plugin"
              "Cathedral Weathers/Data/Textures/sky.dds", "texture" ]

        let runtimeArtifact = artifact store workspace runtimePath
        let presetArtifact = artifact store workspace presetPath
        let companionArtifact = artifact store workspace companionPath

        let presetFile =
            { Id = 100L
              Name = "Lean ENB"
              Version = "1.0.0"
              Category = "MAIN"
              Description = ""
              Bytes = presetArtifact.Length }

        let companionFile =
            { Id = 200L
              Name = "Cathedral Weathers"
              Version = "2.50"
              Category = "MAIN"
              Description = ""
              Bytes = companionArtifact.Length }

        let installedGeneration =
            store.InstallEnb(
                workspace,
                profile,
                EnbCatalogue.lean,
                runtimeArtifact,
                [ EnbCatalogue.lean.Preset, presetFile, presetArtifact
                  EnbCatalogue.lean.Companions.Head, companionFile, companionArtifact ],
                CancellationToken.None
            )
            |> wait

        let installedState = store.Deployments.Read profile |> wait |> result

        let installedComponents =
            store.EnbSetups.Components(workspace, profile, installedState.ActiveGeneration)
            |> wait

        let launch = store.GameLaunching.Read(workspace, profile) |> wait |> result

        let installedEndToEnd =
            installedState.ActiveGeneration = Some installedGeneration
            && File.Exists(Path.Combine(game, "d3d11.dll"))
            && File.Exists(Path.Combine(game, "Data", "Cathedral Weathers.esp"))
            && File.ReadAllText(prefs).Contains("bSAOEnable=0")
            && launch.Problem.IsNone
            && installedComponents.Length = 3
            && installedComponents
               |> List.forall (fun value -> value.Sha256.Length = 64 && value.Terms <> "")

        writer.WriteBoolean(
            "setupActiveGeneration",
            installedState.ActiveGeneration = Some installedGeneration
        )

        writer.WriteBoolean("setupRootDll", File.Exists(Path.Combine(game, "d3d11.dll")))

        writer.WriteBoolean(
            "setupDataCompanion",
            File.Exists(Path.Combine(game, "Data", "Cathedral Weathers.esp"))
        )

        writer.WriteBoolean("setupConfiguration", File.ReadAllText(prefs).Contains("bSAOEnable=0"))
        writer.WriteBoolean("setupLaunch", launch.Problem.IsNone)
        writer.WriteString("setupLaunchProblem", launch.Problem |> Option.defaultValue "")

        interrupt <- true

        let interrupted =
            try
                store.InstallEnb(
                    workspace,
                    profile,
                    EnbCatalogue.lean,
                    runtimeArtifact,
                    [ EnbCatalogue.lean.Preset, presetFile, presetArtifact
                      EnbCatalogue.lean.Companions.Head, companionFile, companionArtifact ],
                    CancellationToken.None
                )
                |> wait
                |> ignore

                false
            with _ ->
                true

        interrupt <- false
        let afterInterruption = store.Deployments.Read profile |> wait |> result

        let recovered =
            interrupted
            && afterInterruption.ActiveGeneration = Some installedGeneration
            && afterInterruption.PendingReceipt.IsNone

        store.RemoveEnb(workspace, profile, CancellationToken.None) |> wait |> ignore
        let removedState = store.Deployments.Read profile |> wait |> result

        let removedEndToEnd =
            removedState.ActiveGeneration <> Some installedGeneration
            && not (File.Exists(Path.Combine(game, "d3d11.dll")))
            && File.ReadAllText(prefs).Contains("bSAOEnable=1")

        check writer "setupPublishesReadyGeneration" installedEndToEnd
        check writer "interruptedUpdateRestoresActiveGeneration" recovered
        check writer "removalRestoresPriorFilesAndConfiguration" removedEndToEnd

        let firstGeneration, secondGeneration = Guid.NewGuid(), Guid.NewGuid()

        let save generation game =
            store.EnbSetups.SaveLaunchPlan(
                workspace,
                profile,
                generation,
                game,
                row.Runtime.Version,
                row.Preset.Version,
                runtimeHash,
                presetHash,
                "cathedral:" + companionHash,
                row.DllOverrides,
                "GE-Proton",
                "bSAOEnable=1",
                None
            )
            |> wait

        save firstGeneration "first-game"
        save secondGeneration "second-game"

        let owner = store.EnbSetups :> IComponentLaunchConfigurationSelection
        let first = owner.Read(workspace, profile, Some firstGeneration) |> wait
        let second = owner.Read(workspace, profile, Some secondGeneration) |> wait
        let removed = owner.Read(workspace, profile, None) |> wait

        let firstMatches =
            first |> Option.exists (fun value -> value.GameSha256 = "first-game")

        let secondMatches =
            second |> Option.exists (fun value -> value.GameSha256 = "second-game")

        check
            writer
            "generationScopedUpdateRemovalRecovery"
            (firstMatches && secondMatches && removed.IsNone)

        writer.WriteEndObject()
        GenerationCleanup.normalize area
