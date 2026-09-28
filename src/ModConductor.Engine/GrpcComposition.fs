module ModConductor.Engine.GrpcComposition

open System
open Microsoft.AspNetCore.Builder
open Microsoft.Extensions.DependencyInjection

let internal configureGrpc (services: IServiceCollection) =
    services
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
        .AddServiceOptions<ModConductor.Engine.ProfileTransportService>(fun options ->
            options.MaxReceiveMessageSize <- Nullable(1024 * 1024)
            options.MaxSendMessageSize <- Nullable(1024 * 1024))
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

let internal mapGrpc (app: WebApplication) =
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
    app.MapGrpcService<ModConductor.Engine.ProfileTransportService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ModLibraryService>() |> ignore
    app.MapGrpcService<ModConductor.Engine.ProfileModService>() |> ignore
