namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open Grpc.Core.Interceptors
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
open ModConductor.Protocol.V1
open ModConductor.Workspaces

module EnbFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result

    type private GrpcContext(headers: Metadata) =
        inherit ServerCallContext()
        let mutable status = Status.DefaultSuccess
        let mutable writeOptions = null
        let trailers = Metadata()
        override _.MethodCore = "/modconductor.v1.EnbOperations/fixture"
        override _.HostCore = "localhost"
        override _.PeerCore = "fixture"
        override _.DeadlineCore = DateTime.MaxValue
        override _.RequestHeadersCore = headers
        override _.CancellationTokenCore = CancellationToken.None
        override _.ResponseTrailersCore = trailers

        override _.StatusCore
            with get () = status
            and set value = status <- value

        override _.WriteOptionsCore
            with get () = writeOptions
            and set value = writeOptions <- value

        override _.AuthContextCore = Unchecked.defaultof<AuthContext>

        override _.CreatePropagationTokenCore _ =
            Unchecked.defaultof<ContextPropagationToken>

        override _.WriteResponseHeadersAsyncCore _ = Task.CompletedTask

    let private authenticated (capability: string) request continuation =
        let headers = Metadata()
        headers.Add("mc-session", capability)
        let context = GrpcContext(headers)
        let authentication = SessionAuthentication(Encoding.ASCII.GetBytes capability)
        let handler = UnaryServerMethod<_, _>(continuation)
        authentication.UnaryServerHandler(request, context, handler) |> wait

    let private rejectsMissingCapability (capability: string) request continuation =
        let context = GrpcContext(Metadata())
        let authentication = SessionAuthentication(Encoding.ASCII.GetBytes capability)
        let handler = UnaryServerMethod<_, _>(continuation)

        try
            authentication.UnaryServerHandler(request, context, handler) |> wait |> ignore
            false
        with :? RpcException as error ->
            error.StatusCode = StatusCode.Unauthenticated

    let private until label read predicate =
        let deadline = DateTime.UtcNow.AddSeconds 30.
        let mutable value = read ()

        while not (predicate value) && DateTime.UtcNow < deadline do
            Thread.Sleep 20
            value <- read ()

        if not (predicate value) then
            failwith ("Timed out waiting for " + label + ".")

        value

    let private unusedCombinedDependency<'value> () =
        Task.FromException<'value>(
            InvalidOperationException(
                "The combined ENB cancellation fixture used an unrelated dependency."
            )
        )

    let private combinedEnbDependencies (enb: EnbCoordinator) : SkyrimSetupDependencies =
        { ReadSkse = fun _ _ -> unusedCombinedDependency ()
          StartSkse = fun _ _ -> unusedCombinedDependency ()
          CancelSkse = fun _ _ -> unusedCombinedDependency ()
          RemoveSkse = fun _ _ _ -> unusedCombinedDependency ()
          ReadEnb = fun workspace profile -> enb.Read(workspace, profile)
          SelectEnb =
            fun workspace profile operation path token ->
                enb.SelectArchive(workspace, profile, operation, path, token)
          CancelEnb = fun workspace profile -> enb.Cancel(workspace, profile)
          RemoveEnb = fun _ _ _ -> unusedCombinedDependency ()
          RecoverEnb = fun workspace profile token -> enb.Recover(workspace, profile, token)
          ReadFnis = fun _ _ -> unusedCombinedDependency ()
          InstallFnis = fun _ _ -> unusedCombinedDependency ()
          UpdateFnis = fun _ _ -> unusedCombinedDependency ()
          CancelFnis = fun _ _ -> unusedCombinedDependency ()
          RemoveFnis = fun _ _ _ -> unusedCombinedDependency ()
          RecoverFnis = fun _ _ _ -> unusedCombinedDependency ()
          InspectFnis = fun _ _ _ -> unusedCombinedDependency ()
          RunFnis = fun _ _ -> unusedCombinedDependency ()
          CancelFnisRun = fun _ _ -> unusedCombinedDependency ()
          ReadLaunch = fun _ _ -> unusedCombinedDependency ()
          PluginPreflight = fun _ _ _ -> unusedCombinedDependency () }

    let private signIn (session: NexusSession) =
        session.SignIn() |> wait |> ignore

        until "Nexus sign-in" (fun () -> session.Status) (fun status ->
            not status.Waiting && status.Account.IsSome)
        |> ignore

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
                profile,
                0L,
                { GameId = GameId.SkyrimSpecialEditionSteam
                  Path = game
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

    let private archiveBytes (entries: (string * string) list) =
        use output = new MemoryStream()
        use zip = new ZipArchive(output, ZipArchiveMode.Create, true)

        for name, value in entries do
            use target = zip.CreateEntry(name).Open()
            let bytes = Encoding.UTF8.GetBytes value
            target.Write bytes

        zip.Dispose()
        output.ToArray()

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

    let private coordinatorEvidence
        (writer: Utf8JsonWriter)
        (area: string)
        (row: EnbCompatibilityRow)
        =
        let policy =
            { ModConductor.HttpDownloads.DownloadPolicy.Default with
                Attempts = 1
                RetryDelay = TimeSpan.Zero
                CheckpointBytes = 4096L }

        let runtimeEntries =
            [ "WrapperVersion/d3d11.dll", "runtime"
              "WrapperVersion/d3dcompiler_46e.dll", "compiler" ]

        let presetBytes =
            archiveBytes
                [ "Lean ENB/enbseries.ini", "preset"
                  "Lean ENB/enblocal.ini", "local"
                  "Lean ENB/enbseries/enbeffect.fx", "effect" ]

        let companionBytes =
            archiveBytes
                [ "Cathedral Weathers/Data/Cathedral Weathers.esp", "plugin"
                  "Cathedral Weathers/Data/Textures/sky.dds", "texture" ]

        let run (premium: bool) (name: string) =
            let scenario = Directory.CreateDirectory(Path.Combine(area, name)).FullName
            use server = new NexusServer()
            server.Premium <- premium

            server.EnbFiles <-
                Map.ofList
                    [ EnbCatalogue.LeanModId, (7001L, "lean-enb.zip", "1.0.0", presetBytes)
                      EnbCatalogue.CathedralModId, (7002L, "cathedral.zip", "2.50", companionBytes) ]

            use credentials = new CredentialSession(NexusMemoryStore())

            use nexus =
                new NexusSession(
                    credentials,
                    Some server.Registration,
                    server.Handoff,
                    (fun _ -> Task.CompletedTask),
                    requestInterval = TimeSpan.Zero
                )

            signIn nexus

            let mutable deploymentInterrupt = false

            use store =
                new OperationStore(
                    Path.Combine(scenario, "state"),
                    nexusLinks = NexusDownloadLinks(nexus),
                    downloadPolicy = policy,
                    enbCheckpoint =
                        (fun boundary _ ->
                            if deploymentInterrupt && boundary = "install-intent" then
                                raise (OperationCanceledException("fixture interruption")))
                )

            let workspace, profile, _, _ = createWorkspace store scenario
            let runtimePath = Path.Combine(scenario, "enbseries_skyrimse_v0505.zip")
            archive runtimePath runtimeEntries

            use coordinator =
                new EnbCoordinator(
                    nexus,
                    store.Downloads,
                    store,
                    server.Handoff,
                    row,
                    eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
                )

            let request =
                ModConductor.Protocol.V1.EnbRequest(
                    WorkspaceId = workspace.ToString("N"),
                    ProfileId = profile.ToString("N")
                )

            let service = EnbService(coordinator)
            let capability = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

            let waiting =
                authenticated capability request (fun input context ->
                    service.OpenEnbAuthorPage(input, context))

            let unauthenticatedRejected =
                rejectsMissingCapability capability request (fun input context ->
                    service.ReadEnb(input, context))

            let selecting =
                authenticated
                    capability
                    (ModConductor.Protocol.V1.EnbArchiveRequest(
                        WorkspaceId = workspace.ToString("N"),
                        ProfileId = profile.ToString("N"),
                        OperationId = Guid.NewGuid().ToString("N"),
                        Path = runtimePath
                    ))
                    (fun input context -> service.SelectEnbArchive(input, context))

            if not premium then
                let accept modId fileId =
                    let id = Guid.NewGuid()
                    let expiry = DateTimeOffset.UtcNow.AddMinutes(5.).ToUnixTimeSeconds()

                    let link =
                        "nxm://skyrimspecialedition/mods/"
                        + string modId
                        + "/files/"
                        + string fileId
                        + "?key=synthetic-nxm-private-grant&expires="
                        + string expiry
                        + "&user_id=42"

                    if not (nexus.AcceptNxm(id, link)) then
                        failwith "The ENB NXM fixture link was not admitted."

                    coordinator.AcceptNxm id

                accept EnbCatalogue.LeanModId 7001L

                until
                    "Cathedral NXM handoff"
                    (fun () -> coordinator.Read(workspace, profile) |> wait)
                    (fun value ->
                        value.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
                        || value.Detail.Contains("cathedral", StringComparison.OrdinalIgnoreCase))
                |> ignore

                accept EnbCatalogue.CathedralModId 7002L

            let ready =
                until
                    (name + " ENB coordinator")
                    (fun () ->
                        authenticated capability request (fun input context ->
                            service.ReadEnb(input, context)))
                    (fun value ->
                        value.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
                        || value.Phase = ModConductor.Protocol.V1.EnbPhase.Failed
                        || value.Phase = ModConductor.Protocol.V1.EnbPhase.Conflict)

            let deployed = store.Deployments.Read profile |> wait |> result
            let initial = deployed.ActiveGeneration

            let interrupted =
                if premium then
                    deploymentInterrupt <- true

                    let failed =
                        authenticated capability request (fun input context ->
                            service.UpdateEnb(input, context))

                    deploymentInterrupt <- false
                    let preserved = store.Deployments.Read profile |> wait |> result

                    failed.Phase = ModConductor.Protocol.V1.EnbPhase.Failed
                    && preserved.ActiveGeneration = initial
                    && preserved.PendingReceipt.IsNone
                else
                    true

            let updated =
                if premium then
                    authenticated capability request (fun input context ->
                        service.UpdateEnb(input, context))
                    |> ignore

                    until
                        "ENB coordinator update"
                        (fun () ->
                            authenticated capability request (fun input context ->
                                service.ReadEnb(input, context)))
                        (fun value ->
                            value.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
                            || value.Phase = ModConductor.Protocol.V1.EnbPhase.Failed)
                else
                    ready

            let afterUpdate = store.Deployments.Read profile |> wait |> result

            let outcome =
                waiting.Phase = ModConductor.Protocol.V1.EnbPhase.WaitingForArchive
                && selecting.Phase = ModConductor.Protocol.V1.EnbPhase.Acquiring
                && ready.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
                && updated.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
                && initial.IsSome
                && interrupted
                && unauthenticatedRejected
                && (not premium || afterUpdate.ActiveGeneration <> initial)

            outcome

        check writer "authenticatedGrpcDirectAcquisitionReachesReadyAndUpdates" (run true "direct")
        check writer "nxmAcquisitionReachesReady" (run false "nxm")

    let private combinedCancellationEvidence writer area =
        let scenario =
            Directory.CreateDirectory(Path.Combine(area, "combined-cancellation")).FullName

        let statePath = Path.Combine(scenario, "state")
        use server = new NexusServer()
        server.Premium <- true

        server.EnbFiles <-
            Map.ofList
                [ EnbCatalogue.LeanModId,
                  (7001L,
                   "lean-enb.zip",
                   "1.0.0",
                   archiveBytes
                       [ "Lean ENB/enbseries.ini", "preset"
                         "Lean ENB/enblocal.ini", "local"
                         "Lean ENB/enbseries/enbeffect.fx", "effect" ])
                  EnbCatalogue.CathedralModId,
                  (7002L,
                   "cathedral.zip",
                   "2.50",
                   archiveBytes
                       [ "Cathedral Weathers/Data/Cathedral Weathers.esp", "plugin"
                         "Cathedral Weathers/Data/Textures/sky.dds", "texture" ]) ]

        use credentials = new CredentialSession(NexusMemoryStore())

        use nexus =
            new NexusSession(
                credentials,
                Some server.Registration,
                server.Handoff,
                (fun _ -> Task.CompletedTask),
                requestInterval = TimeSpan.Zero
            )

        signIn nexus

        let store =
            new OperationStore(
                statePath,
                nexusLinks = NexusDownloadLinks(nexus),
                downloadPolicy =
                    { ModConductor.HttpDownloads.DownloadPolicy.Default with
                        Attempts = 1
                        RetryDelay = TimeSpan.Zero
                        CheckpointBytes = 4096L }
            )

        let workspace, profile, _, _ = createWorkspace store scenario
        let runtimePath = Path.Combine(scenario, "enbseries_skyrimse_v0505.zip")

        archive
            runtimePath
            [ "WrapperVersion/d3d11.dll", "runtime"
              "WrapperVersion/d3dcompiler_46e.dll", "compiler" ]

        let owner =
            new EnbCoordinator(
                nexus,
                store.Downloads,
                store,
                server.Handoff,
                EnbCatalogue.lean,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        owner.OpenAuthorPage(workspace, profile) |> wait |> ignore

        let operation = Guid.NewGuid()

        store.SkyrimSetups.Save
            { WorkspaceId = workspace
              ProfileId = profile
              Selection = { SetupSelection.none with Enb = SetupAction.Install; EnbArchive = Some runtimePath }
              Cancelled = false
              Completed = false
              Stage = "enb"
              ActionId = Some operation
              CancelRequested = false
              CancelDetail = ""
              RequestedAt = DateTimeOffset.UtcNow }
        |> wait

        let _metadataHold = server.HoldMetadata()

        let selecting =
            owner.SelectArchive(workspace, profile, operation, runtimePath, CancellationToken.None)

        until
            "active combined ENB acquisition"
            (fun () -> store.EnbSetups.ReadStatus(workspace, profile) |> wait)
            (Option.exists (fun value -> value.Phase = "acquiring"))
        |> ignore

        let combined = new SkyrimSetupCoordinator(store, combinedEnbDependencies owner)
        let combinedService = SkyrimSetupService combined

        let combinedCapability =
            Convert.ToBase64String(Array.init 32 (fun index -> byte (index + 61)))

        let combinedRequest =
            SkyrimSetupRequest(
                WorkspaceId = workspace.ToString("N"),
                ProfileId = profile.ToString("N")
            )

        let unauthenticatedCombinedCancellationRejected =
            rejectsMissingCapability combinedCapability combinedRequest (fun input context ->
                combinedService.CancelSkyrimSetup(input, context))

        let cancelled =
            authenticated combinedCapability combinedRequest (fun input context ->
                combinedService.CancelSkyrimSetup(input, context))

        server.ReleaseMetadata()
        selecting |> wait |> ignore

        let ownerAfterCancel = owner.Read(workspace, profile) |> wait
        let cancelledIntent = store.SkyrimSetups.Read(workspace, profile) |> wait

        (combined :> IDisposable).Dispose()
        (owner :> IDisposable).Dispose()
        (store :> IDisposable).Dispose()

        use reopened = new OperationStore(statePath)

        let reopenedContext =
            (reopened.GameContexts :> IGameContexts).Read(workspace, profile) |> wait |> result

        (reopened.GameContexts :> IGameContexts).Refresh(workspace, profile, reopenedContext.Revision)
        |> wait
        |> result
        |> ignore

        use restartedOwner =
            new EnbCoordinator(
                nexus,
                reopened.Downloads,
                reopened,
                server.Handoff,
                EnbCatalogue.lean,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        use restartedCombined =
            new SkyrimSetupCoordinator(reopened, combinedEnbDependencies restartedOwner)

        let afterRestart =
            restartedCombined.Read(workspace, profile, { SetupSelection.none with Enb = SetupAction.Install; EnbArchive = Some runtimePath }, CancellationToken.None)
            |> wait

        check
            writer
            "combinedCancelUsesProductionEnbOwner"
            (cancelled.Phase = SkyrimSetupPhase.Cancelled
             && ownerAfterCancel.Phase <> ModConductor.Protocol.V1.EnbPhase.Validating
             && ownerAfterCancel.Phase <> ModConductor.Protocol.V1.EnbPhase.Acquiring
             && ownerAfterCancel.Phase <> ModConductor.Protocol.V1.EnbPhase.Installing
             && (cancelledIntent
                 |> Option.exists (fun value ->
                     value.Cancelled && not value.CancelRequested && value.ActionId.IsNone)))

        check
            writer
            "authenticatedGrpcCombinedCancellationUsesProductionEnbOwner"
            (unauthenticatedCombinedCancellationRejected
             && cancelled.Phase = SkyrimSetupPhase.Cancelled)

        check
            writer
            "combinedEnbCancellationSurvivesOwnerRestart"
            (afterRestart.Phase = SkyrimSetupPhase.Cancelled)

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
        let mutable configurationFailure = false

        use store =
            new OperationStore(
                Path.Combine(area, "state"),
                enbCheckpoint =
                    (fun name _ ->
                        if
                            (interrupt && name = "install-intent")
                            || (configurationFailure && name = "configuration-restore")
                        then
                            raise (OperationCanceledException()))
            )

        let workspace, profile, game, prefs = createWorkspace store area
        let handoff = Handoff()
        use credentials = new CredentialSession(EmptyCredentialStore())

        use nexus =
            new NexusSession(credentials, None, handoff, (fun _ -> Task.CompletedTask))

        let blockedRow =
            { EnbCatalogue.lean with
                TermsApproved = false }

        use blocked =
            new EnbCoordinator(
                nexus,
                store.Downloads,
                store,
                handoff,
                blockedRow,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        let blockedRead = blocked.Read(workspace, profile) |> wait
        let blockedOpen = blocked.OpenAuthorPage(workspace, profile) |> wait

        let blockedSelection =
            blocked.SelectArchive(
                workspace,
                profile,
                Guid.NewGuid(),
                Path.Combine(area, "not-read.zip"),
                CancellationToken.None
            )
            |> wait

        check
            writer
            "unapprovedCatalogueBlocksAcquisition"
            (blockedRead.Phase = ModConductor.Protocol.V1.EnbPhase.Blocked
             && blockedOpen.Phase = ModConductor.Protocol.V1.EnbPhase.Blocked
             && blockedSelection.Phase = ModConductor.Protocol.V1.EnbPhase.Blocked
             && handoff.Opened.IsEmpty)

        use coordinator =
            new EnbCoordinator(
                nexus,
                store.Downloads,
                store,
                handoff,
                row,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        let coordinatorService = EnbService(coordinator)

        let coordinatorCapability =
            "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"

        let coordinatorRequest =
            ModConductor.Protocol.V1.EnbRequest(
                WorkspaceId = workspace.ToString("N"),
                ProfileId = profile.ToString("N")
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
        let viewRoot = installedState.RunnableRoot

        let installedComponents =
            store.EnbSetups.Components(workspace, profile, installedState.ActiveGeneration)
            |> wait

        let launch = store.GameLaunching.Read(workspace, profile) |> wait |> result

        let installedEndToEnd =
            installedState.ActiveGeneration = Some installedGeneration
            && File.Exists(Path.Combine(viewRoot, "d3d11.dll"))
            && File.Exists(Path.Combine(viewRoot, "Data", "Cathedral Weathers.esp"))
            && not (File.Exists(Path.Combine(game, "d3d11.dll")))
            && File.ReadAllText(prefs).Contains("bSAOEnable=0")
            && launch.Problem.IsNone
            && installedComponents.Length = 3
            && installedComponents
               |> List.forall (fun value -> value.Sha256.Length = 64 && value.Terms <> "")

        writer.WriteBoolean(
            "setupActiveGeneration",
            installedState.ActiveGeneration = Some installedGeneration
        )

        writer.WriteBoolean("setupRootDll", File.Exists(Path.Combine(viewRoot, "d3d11.dll")))

        writer.WriteBoolean(
            "setupDataCompanion",
            File.Exists(Path.Combine(viewRoot, "Data", "Cathedral Weathers.esp"))
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

        let currentPrefs () =
            let state = store.ProfileGameData.Read(workspace, profile) |> wait |> result
            Path.Combine(state.SettingsPath, "SkyrimPrefs.ini")

        configurationFailure <- true

        let failedRemoval =
            authenticated coordinatorCapability coordinatorRequest (fun input context ->
                coordinatorService.RemoveEnb(input, context))

        let durableFailure =
            store.EnbSetups.ConfigurationOperation(workspace, profile) |> wait

        configurationFailure <- false

        let recoveredRemoval =
            authenticated coordinatorCapability coordinatorRequest (fun input context ->
                coordinatorService.RecoverEnb(input, context))

        let removedState = store.Deployments.Read profile |> wait |> result

        let removedEndToEnd =
            removedState.ActiveGeneration <> Some installedGeneration
            && not (File.Exists(Path.Combine(viewRoot, "d3d11.dll")))
            && File.ReadAllText(currentPrefs ()).Contains("bSAOEnable=1")

        check
            writer
            "configurationFailureRemainsRecoverable"
            (failedRemoval.Phase = ModConductor.Protocol.V1.EnbPhase.Failed
             && durableFailure.IsSome
             && recoveredRemoval.Phase = ModConductor.Protocol.V1.EnbPhase.Available
             && removedEndToEnd)

        let _ =
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

        let conflictPrefs = currentPrefs ()

        File.WriteAllText(
            conflictPrefs,
            File.ReadAllText(conflictPrefs).Replace("bSAOEnable=0", "bSAOEnable=2")
        )

        let conflictRemoval =
            authenticated coordinatorCapability coordinatorRequest (fun input context ->
                coordinatorService.RemoveEnb(input, context))

        let preservedEdit = File.ReadAllText(currentPrefs ()).Contains("bSAOEnable=2")

        let conflictOperation =
            store.EnbSetups.ConfigurationOperation(workspace, profile) |> wait

        let recoveryPrefs = currentPrefs ()

        File.WriteAllText(
            recoveryPrefs,
            File.ReadAllText(recoveryPrefs).Replace("bSAOEnable=2", "bSAOEnable=0")
        )

        let conflictRecovery =
            authenticated coordinatorCapability coordinatorRequest (fun input context ->
                coordinatorService.RecoverEnb(input, context))

        check
            writer
            "compareBeforeRestorePreservesConflictAndRecovers"
            (conflictRemoval.Phase = ModConductor.Protocol.V1.EnbPhase.Conflict
             && preservedEdit
             && (conflictOperation |> Option.exists (fun value -> value.Phase = "conflict"))
             && conflictRecovery.Phase = ModConductor.Protocol.V1.EnbPhase.Available
             && File.ReadAllText(currentPrefs ()).Contains("bSAOEnable=1"))

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
                Some row.Preset.Version,
                runtimeHash,
                Some presetHash,
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

        let _ =
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

        let beforeRuntimeRemoval = store.Deployments.Read profile |> wait |> result

        let retainedBefore =
            store.EnbSetups.Components(workspace, profile, beforeRuntimeRemoval.ActiveGeneration)
            |> wait
            |> List.filter (fun item -> item.Kind <> "runtime")

        let _ = store.RemoveEnb(workspace, profile, CancellationToken.None, runtimeOnly = true) |> wait
        let afterRuntimeRemoval = store.Deployments.Read profile |> wait |> result

        let retainedAfter =
            store.EnbSetups.Components(workspace, profile, afterRuntimeRemoval.ActiveGeneration)
            |> wait

        check
            writer
            "runtimeOnlyRemovalKeepsPresetAndCompanion"
            (retainedBefore.Length = 2
             && (retainedAfter |> List.map _.ModId) = (retainedBefore |> List.map _.ModId)
             && not (File.Exists(Path.Combine(viewRoot, "d3d11.dll")))
             && File.Exists(Path.Combine(viewRoot, "Data", "Cathedral Weathers.esp")))

        let runtimeRow =
            { EnbCatalogue.lean with
                Runtime =
                    EnbCatalogue.withHash runtimeArtifact.Sha256.Value EnbCatalogue.lean.Runtime }

        use runtimeOwner =
            new EnbCoordinator(
                nexus,
                store.Downloads,
                store,
                handoff,
                runtimeRow,
                eligibilityOverride = (fun _ -> Task.FromResult(Ok()))
            )

        let runtimeResult =
            runtimeOwner.SelectRuntimeArchive(
                workspace,
                profile,
                Guid.NewGuid(),
                runtimePath,
                CancellationToken.None
            )
            |> wait

        let afterRuntimeInstall = store.Deployments.Read profile |> wait |> result

        let componentsAfterRuntimeInstall =
            store.EnbSetups.Components(workspace, profile, afterRuntimeInstall.ActiveGeneration)
            |> wait

        check
            writer
            "runtimeOnlySelectionAvoidsPresetAcquisition"
            (runtimeResult.Phase = ModConductor.Protocol.V1.EnbPhase.Ready
             && componentsAfterRuntimeInstall.Length = 3
             && (componentsAfterRuntimeInstall
                 |> List.filter (fun item -> item.Kind <> "runtime")
                 |> List.map _.ModId) = (retainedBefore |> List.map _.ModId))


        coordinatorEvidence writer area EnbCatalogue.lean
        combinedCancellationEvidence writer area

        writer.WriteEndObject()
        GenerationCleanup.normalize area
