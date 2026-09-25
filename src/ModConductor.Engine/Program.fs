module ModConductor.Engine.Program

open System
open System.IO
open ModConductor.Operations
open ModConductor.Persistence
open System.Net
open System.Threading.Tasks
open Microsoft.AspNetCore.Builder
open Microsoft.AspNetCore.Hosting
open Microsoft.AspNetCore.Hosting.Server
open Microsoft.AspNetCore.Hosting.Server.Features
open Microsoft.AspNetCore.Server.Kestrel.Core
open Microsoft.Extensions.DependencyInjection
open Microsoft.Extensions.Hosting
open Microsoft.Extensions.Logging

let runWithNexus registration (handoff: ModConductor.Nexus.IOAuthHandoff) args =
    let directory, workspaceDirectory =
        match args with
        | [||] ->
            let application =
                Path.Combine(
                    Environment.GetFolderPath(
                        Environment.SpecialFolder.LocalApplicationData,
                        Environment.SpecialFolderOption.Create
                    ),
                    "ModConductor"
                )

            Path.Combine(application, "state"), Path.Combine(application, "workspaces")
        | [| "--state-directory"; path |] when Path.IsPathFullyQualified path ->
            path, Path.Combine(path, "workspaces")
        | _ -> invalidArg "args" "Invalid engine arguments."

    use input = Console.OpenStandardInput()

    let capability =
        ModConductor.Engine.Bootstrap.readCapability input
        |> fun pending -> pending.GetAwaiter().GetResult()

    use sessionKey = ModConductor.Engine.SessionKey.create ()
    use certificate = ModConductor.Engine.Bootstrap.createCertificate sessionKey.Rsa

    use stateLease = ModConductor.Desktop.StateLease.acquire directory

    use credentials =
        new ModConductor.Credentials.CredentialSession(
            ModConductor.Credentials.CredentialStore.create ()
        )

    let mutable downloads: ModConductor.HttpDownloads.DownloadSession option = None

    use nexus =
        new ModConductor.Nexus.NexusSession(
            credentials,
            registration,
            handoff,
            fun subject ->
                match downloads with
                | Some value -> value.PauseAccount(subject) :> Task
                | None -> Task.CompletedTask
        )

    use store =
        new OperationStore(directory, nexusLinks = ModConductor.Engine.NexusDownloadLinks(nexus))

    downloads <- Some store.Downloads

    use skse =
        new ModConductor.Engine.SkseCoordinator(
            nexus,
            store.Downloads,
            store.GameContexts,
            store,
            handoff
        )

    use enb =
        new ModConductor.Engine.EnbCoordinator(
            nexus,
            store.Downloads,
            store,
            handoff,
            ModConductor.Enb.EnbCatalogue.lean
        )

    use fnis =
        new ModConductor.Engine.FnisCoordinator(nexus, store.Downloads, store, handoff)

    use fnisRunner = new ModConductor.Engine.FnisRunner(store)

    use skyrimSetup =
        new ModConductor.Engine.SkyrimSetupCoordinator(
            store,
            skse,
            enb,
            fnis,
            fnisRunner,
            store.GameLaunching,
            store.PluginOrders
        )

    use nxmIngress =
        new ModConductor.Desktop.PrivateIngress(
            (fun (id, input) ->
                let accepted = nexus.AcceptNxm(id, input)

                if accepted then
                    match nexus.ReadNxm id with
                    | Ok file when file.ModId = ModConductor.Skse.SkseResolver.NexusModId ->
                        skse.AcceptNxm id
                    | Ok file when
                        file.ModId = ModConductor.Enb.EnbCatalogue.LeanModId
                        || file.ModId = ModConductor.Enb.EnbCatalogue.CathedralModId
                        ->
                        enb.AcceptNxm id
                    | Ok file when file.ModId = ModConductor.Fnis.FnisCatalogue.NexusModId ->
                        fnis.AcceptNxm id
                    | Ok _ -> ()
                    | Error _ ->
                        skse.AcceptNxm id
                        enb.AcceptNxm id
                        fnis.AcceptNxm id

                accepted),
            nexus.DismissNxm
        )

    let sqliteVersion = store.SqliteVersion

    let coordinator =
        Coordinator(store, fun () -> ModConductor.Engine.Probe.runtime sqliteVersion)

    let builder =
        WebApplication.CreateSlimBuilder(
            WebApplicationOptions(ContentRootPath = AppContext.BaseDirectory, Args = [||])
        )

    builder.Logging.ClearProviders() |> ignore

    builder.WebHost.ConfigureKestrel(fun options ->
        options.Listen(
            IPAddress.Loopback,
            0,
            fun endpoint ->
                endpoint.Protocols <- HttpProtocols.Http2
                endpoint.UseHttps(certificate) |> ignore
        ))
    |> ignore

    builder.Services.AddSingleton<ModConductor.ProfileGameData.IProfilePluginOrders>(
        store.PluginOrders
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.PluginOrderService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Loot.ILootSorting>(store.Loot)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.LootService>() |> ignore

    builder.Services.AddSingleton<ModConductor.ProfileGameData.IProfileArchivePolicies>(
        store.ArchivePolicies
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ArchivePolicyService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Bethesda.PluginSession>(store.Plugins)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.BethesdaPluginService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SessionAuthentication>(
        ModConductor.Engine.SessionAuthentication(capability)
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Credentials.CredentialSession>(credentials)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.CredentialService>() |> ignore
    builder.Services.AddSingleton<ModConductor.Nexus.NexusSession>(nexus) |> ignore

    builder.Services.AddSingleton<ModConductor.Nexus.IOAuthHandoff>(handoff)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Desktop.ILinkSetup>(
        ModConductor.Desktop.LinkSetup.create directory
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.LinkSetupService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Desktop.PrivateIngress>(nxmIngress)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.NxmService>() |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.NexusService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SkseCoordinator>(skse)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SkseService>() |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.EnbCoordinator>(enb) |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.EnbService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.FnisCoordinator>(fnis)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Fnis.IFnisExecution>(fnisRunner)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Fnis.IFnisInspection>(fnisRunner)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.FnisService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SkyrimSetupCoordinator>(skyrimSetup)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SkyrimSetupService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Nexus.NexusModDetails>(
        ModConductor.Nexus.NexusModDetails(nexus, store.NexusMetadata)
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.NexusMetadataService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.NexusInteractionsService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.DesktopService>() |> ignore

    builder.Services.AddSingleton<IOperationStore>(store) |> ignore

    builder.Services.AddSingleton<ModConductor.Workspaces.IWorkspaceState>(store.Workspaces)
    |> ignore

    builder.Services.AddSingleton<ModConductor.ModLibrary.IModLibrary>(store.ModLibrary)
    |> ignore

    builder.Services.AddSingleton<ModConductor.ModSelection.IModSelection>(store.ModSelection)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ProfileModService>() |> ignore

    builder.Services.AddSingleton<ModConductor.ModOrganization.IModOrganization>(
        store.ModOrganization
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ModOrganizationService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.ModOrganization.InventoryExportSession>(
        ModConductor.ModOrganization.InventoryExportSession(store.Workspaces, store.ModOrganization)
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.InventoryExportService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.FilePlanning.IFilePlans>(store.FilePlans)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.FilePlanService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Diagnostics.IDiagnostics>(
        ModConductor.Diagnostics.DiagnosticSession(
            store.Workspaces,
            store.FilePlans,
            store.Deployments,
            store.GameLaunching,
            store.ProfileGameData,
            store.GameContexts,
            store.PluginOrders,
            fnis =
                (fun workspace profile token ->
                    task {
                        let! value =
                            (fnisRunner :> ModConductor.Fnis.IFnisInspection)
                                .Inspect(workspace, profile, token)

                        return
                            value
                            |> Result.toOption
                            |> Option.map (fun value ->
                                let stale =
                                    match value.Phase with
                                    | ModConductor.Fnis.FnisOutputPhase.Missing
                                    | ModConductor.Fnis.FnisOutputPhase.Stale
                                    | ModConductor.Fnis.FnisOutputPhase.Running
                                    | ModConductor.Fnis.FnisOutputPhase.Failed
                                    | ModConductor.Fnis.FnisOutputPhase.Cancelled
                                    | ModConductor.Fnis.FnisOutputPhase.Abandoned -> true
                                    | _ -> false

                                let diagnostic: ModConductor.Diagnostics.FnisDiagnosticState =
                                    { Stale = stale
                                      Status = value.Status
                                      Detail = value.Detail
                                      Fingerprint = value.Fingerprint }

                                diagnostic)
                    })
        )
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.DiagnosticService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ModLibraryService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.WorkspaceLocations>(
        ModConductor.Engine.WorkspaceLocations(workspaceDirectory)
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.WorkspaceService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Settings.SettingsOwner>(
        ModConductor.Settings.SettingsOwner(directory)
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SettingsService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Migration.IStore>(store.Migrations)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.MigrationService>() |> ignore

    builder.Services.AddSingleton<ModConductor.GameContexts.IGameContexts>(store.GameContexts)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.GameContextService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.SteamDiscoveryService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ProtonContextService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.GeneratedOutputs.IGeneratedOutputs>(
        store.GeneratedOutputs
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.OutputService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Deployment.IDeploymentBackend>(store.Deployments)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.DeploymentService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Executables.IExecutables>(store.Executables)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ExecutableService>() |> ignore

    builder.Services.AddSingleton<ModConductor.GameLaunching.IGameLaunching>(store.GameLaunching)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.GameLaunchService>() |> ignore

    builder.Services.AddSingleton<ModConductor.ProfileGameData.IProfileGameData>(
        store.ProfileGameData
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ProfileDataService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.ArtifactLibrary.IArtifactLibrary>(store.Artifacts)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ArtifactService>() |> ignore

    builder.Services.AddSingleton<ModConductor.ArchiveInspection.Inspection>(
        store.ArchiveInspection
    )
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.ArchiveInspectionService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.Persistence.BundleStore>(store.Bundles)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Persistence.InstallationStore>(store.Installations)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Persistence.DeletionStore>(store.Deletions)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.UpdateService>() |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.DeletionService>() |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.InstallationService>()
    |> ignore

    builder.Services.AddSingleton<ModConductor.HttpDownloads.DownloadSession>(store.Downloads)
    |> ignore

    builder.Services.AddSingleton<ModConductor.Engine.DownloadService>() |> ignore

    builder.Services.AddSingleton<Coordinator>(coordinator) |> ignore
    builder.Services.AddSingleton<ModConductor.Engine.OperationService>() |> ignore

    builder.Services
        .AddGrpc(fun options ->
            options.Interceptors.Add<ModConductor.Engine.SessionAuthentication>()
            options.MaxReceiveMessageSize <- Nullable 4096
            options.MaxSendMessageSize <- Nullable 65536
            options.EnableDetailedErrors <- Nullable false)
        .AddServiceOptions<ModConductor.Engine.PluginOrderService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(1024 * 1024)
            options.MaxSendMessageSize <- Nullable(17 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ArchivePolicyService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(1024 * 1024)
            options.MaxSendMessageSize <- Nullable(17 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.BethesdaPluginService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 4096
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.UpdateService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(16 * 1024 * 1024)
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.DeletionService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 4096
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.BundleService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(16 * 1024)
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.BainService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(16 * 1024)
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.FomodService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(16 * 1024)
            options.MaxSendMessageSize <- Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.InstallationService>(fun options ->
            options.MaxReceiveMessageSize <- System.Nullable(16 * 1024 * 1024)
            options.MaxSendMessageSize <- System.Nullable(16 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ArchiveInspectionService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(16 * 1024)
            options.MaxSendMessageSize <- Nullable(9 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.DesktopService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(40 * 1024)
            options.MaxSendMessageSize <- Nullable(16 * 1024))
        .AddServiceOptions<ModConductor.Engine.NexusService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 4096
            options.MaxSendMessageSize <- Nullable(4 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.DownloadService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(128 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ArtifactService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(128 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ProfileDataService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(2 * 1024 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.GameLaunchService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(256 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ExecutableService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(256 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.OutputService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(256 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.DeploymentService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 4096
            options.MaxSendMessageSize <- Nullable(256 * 1024))
        .AddServiceOptions<ModConductor.Engine.FilePlanService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(2 * 1024 * 1024)
            options.MaxSendMessageSize <- Nullable(9 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.DiagnosticService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(32 * 1024)
            options.MaxSendMessageSize <- Nullable(320 * 1024))
        .AddServiceOptions<ModConductor.Engine.ModLibraryService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 65536
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ModOrganizationService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 65536
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.InventoryExportService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(4 * 1024 * 1024)
            options.MaxSendMessageSize <- Nullable 65536)
        .AddServiceOptions<ModConductor.Engine.ProfileModService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 65536
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.ProtonContextService>(fun options ->
            options.MaxReceiveMessageSize <- 80 * 1024
            options.MaxSendMessageSize <- 512 * 1024)
        .AddServiceOptions<ModConductor.Engine.SteamDiscoveryService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(256 * 1024)
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.GameContextService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 65536
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
        .AddServiceOptions<ModConductor.Engine.WorkspaceService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable 65536
            options.MaxSendMessageSize <- Nullable(2 * 1024 * 1024))
    |> ignore

    use app = builder.Build()
    app.MapGrpcService<ModConductor.Engine.OutputService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ExecutableService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.GameLaunchService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ProfileDataService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ArtifactService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ArchiveInspectionService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.InstallationService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.FomodService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.BainService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.BundleService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.UpdateService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.DeletionService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.CredentialService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.NexusService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.NexusMetadataService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.NexusInteractionsService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.NxmService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.SkseService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.EnbService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.FnisService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.SkyrimSetupService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.LinkSetupService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.DesktopService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.DownloadService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.DeploymentService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.PluginOrderService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.LootService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ArchivePolicyService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.BethesdaPluginService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.FilePlanService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.DiagnosticService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.SteamDiscoveryService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ProtonContextService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.GameContextService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.OperationService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.WorkspaceService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.SettingsService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.MigrationService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ModOrganizationService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.InventoryExportService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ModLibraryService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ProfileModService>() |> ignore
    let savedNexusConnection = nexus.ConnectSaved()
    app.StartAsync().GetAwaiter().GetResult()

    let address =
        app.Services.GetRequiredService<IServer>().Features.Get<IServerAddressesFeature>().Addresses
        |> Seq.exactlyOne

    ModConductor.Engine.Bootstrap.announce (Uri(address).Port) certificate
    let lifetime = app.Services.GetRequiredService<IHostApplicationLifetime>()

    store.ModLibrary.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    store.ExecutablesFailed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    coordinator.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    skyrimSetup.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    Task.Run(fun () ->
        input.ReadByte() |> ignore
        lifetime.StopApplication())
    |> ignore

    store.Downloads.Failed.ContinueWith(fun (_: Task) -> lifetime.StopApplication())
    |> ignore

    app.WaitForShutdownAsync().GetAwaiter().GetResult()
    fnisRunner.Stop().GetAwaiter().GetResult()
    nxmIngress.Stop().GetAwaiter().GetResult()
    store.Installations.Stop().GetAwaiter().GetResult()
    store.Downloads.Stop().GetAwaiter().GetResult()
    nexus.Stop().GetAwaiter().GetResult()
    savedNexusConnection.GetAwaiter().GetResult()
    coordinator.Drain().GetAwaiter().GetResult()
    store.DrainOutputs().GetAwaiter().GetResult()
    store.CloseExecutables().GetAwaiter().GetResult()
    store.DrainDeployments().GetAwaiter().GetResult()
    store.FilePlans.Drain().GetAwaiter().GetResult()
    store.ModLibrary.Drain().GetAwaiter().GetResult()
    store.Workspaces.Drain().GetAwaiter().GetResult()
    0

let run args =
    runWithNexus
        None
        (ModConductor.Engine.OAuthHandoff(ModConductor.Engine.OAuthHandoff.SystemBrowser))
        args

[<EntryPoint>]
let main args =
    try
        run args
    with _ ->
        Console.Error.WriteLine("The engine could not start or stop.")
        1
