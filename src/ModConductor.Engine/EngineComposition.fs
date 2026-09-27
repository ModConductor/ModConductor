module ModConductor.Engine.EngineComposition

open ModConductor.Operations
open ModConductor.Persistence
open Microsoft.Extensions.DependencyInjection

let internal registerComponents
    (services: IServiceCollection)
    directory
    capability
    (credentials: ModConductor.Credentials.CredentialSession)
    (nexus: ModConductor.Nexus.NexusSession)
    (handoff: ModConductor.Nexus.IOAuthHandoff)
    (nxmIngress: ModConductor.Desktop.PrivateIngress)
    (skse: SkseCoordinator)
    (enb: EnbCoordinator)
    (fnis: FnisCoordinator)
    (fnisRunner: FnisRunner)
    (skyrimSetup: SkyrimSetupCoordinator)
    (store: OperationStore)
    =
    services.AddSingleton<ModConductor.ProfileGameData.IProfilePluginOrders>(store.PluginOrders)
    |> ignore

    services.AddSingleton<ModConductor.Engine.PluginOrderService>() |> ignore

    services.AddSingleton<ModConductor.Loot.ILootSorting>(store.Loot) |> ignore

    services.AddSingleton<ModConductor.Engine.LootService>() |> ignore

    services.AddSingleton<ModConductor.ProfileGameData.IProfileArchivePolicies>(
        store.ArchivePolicies
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.ArchivePolicyService>() |> ignore

    services.AddSingleton<ModConductor.Bethesda.PluginSession>(store.Plugins)
    |> ignore

    services.AddSingleton<ModConductor.Engine.BethesdaPluginService>() |> ignore

    services.AddSingleton<ModConductor.Engine.SessionAuthentication>(
        ModConductor.Engine.SessionAuthentication(capability)
    )
    |> ignore

    services.AddSingleton<ModConductor.Credentials.CredentialSession>(credentials)
    |> ignore

    services.AddSingleton<ModConductor.Engine.CredentialService>() |> ignore
    services.AddSingleton<ModConductor.Nexus.NexusSession>(nexus) |> ignore

    services.AddSingleton<ModConductor.Nexus.IOAuthHandoff>(handoff) |> ignore

    services.AddSingleton<ModConductor.Desktop.ILinkSetup>(
        ModConductor.Desktop.LinkSetup.create directory
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.LinkSetupService>() |> ignore

    services.AddSingleton<ModConductor.Desktop.PrivateIngress>(nxmIngress) |> ignore

    services.AddSingleton<ModConductor.Engine.NxmService>() |> ignore
    services.AddSingleton<ModConductor.Engine.NexusService>() |> ignore

    services.AddSingleton<ModConductor.Engine.SkseCoordinator>(skse) |> ignore

    services.AddSingleton<ModConductor.Engine.SkseService>() |> ignore
    services.AddSingleton<ModConductor.Engine.EnbCoordinator>(enb) |> ignore
    services.AddSingleton<ModConductor.Engine.EnbService>() |> ignore

    services.AddSingleton<ModConductor.Engine.FnisCoordinator>(fnis) |> ignore

    services.AddSingleton<ModConductor.Fnis.IFnisExecution>(fnisRunner) |> ignore

    services.AddSingleton<ModConductor.Fnis.IFnisInspection>(fnisRunner) |> ignore

    services.AddSingleton<ModConductor.Engine.FnisService>() |> ignore

    services.AddSingleton<ModConductor.Engine.SkyrimSetupCoordinator>(skyrimSetup)
    |> ignore

    services.AddSingleton<ModConductor.Engine.SkyrimSetupService>() |> ignore

    services.AddSingleton<ModConductor.Nexus.NexusModDetails>(
        ModConductor.Nexus.NexusModDetails(nexus, store.NexusMetadata)
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.NexusMetadataService>() |> ignore

    services.AddSingleton<ModConductor.Engine.NexusInteractionsService>() |> ignore

    services.AddSingleton<ModConductor.Engine.DesktopService>() |> ignore


let internal registerWorkspaceServices
    (services: IServiceCollection)
    directory
    workspaceDirectory
    (store: OperationStore)
    =
    services.AddSingleton<IOperationStore>(store) |> ignore

    services.AddSingleton<ModConductor.Workspaces.IWorkspaceState>(store.Workspaces)
    |> ignore

    services.AddSingleton<ModConductor.Workspaces.IProfileImages>(store.ProfileImages)
    |> ignore

    services.AddSingleton<ModConductor.ModLibrary.IModLibrary>(store.ModLibrary)
    |> ignore

    services.AddSingleton<ModConductor.ModSelection.IModSelection>(store.ModSelection)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ProfileModService>() |> ignore

    services.AddSingleton<ModConductor.ModOrganization.IModOrganization>(store.ModOrganization)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ModOrganizationService>() |> ignore

    services.AddSingleton<ModConductor.ModOrganization.InventoryExportSession>(
        ModConductor.ModOrganization.InventoryExportSession(store.Workspaces, store.ModOrganization)
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.InventoryExportService>() |> ignore

    services.AddSingleton<ModConductor.FilePlanning.IFilePlans>(store.FilePlans)
    |> ignore

    services.AddSingleton<ModConductor.Engine.FilePlanService>() |> ignore

    services.AddSingleton<ModConductor.Diagnostics.IDiagnostics>(DiagnosticComposition.create store)
    |> ignore

    services.AddSingleton<ModConductor.Engine.DiagnosticService>() |> ignore

    services.AddSingleton<ModConductor.Engine.ModLibraryService>() |> ignore

    services.AddSingleton<ModConductor.Engine.WorkspaceLocations>(
        ModConductor.Engine.WorkspaceLocations(workspaceDirectory)
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.WorkspaceService>() |> ignore

    services.AddSingleton<ModConductor.Settings.SettingsOwner>(
        ModConductor.Settings.SettingsOwner(directory)
    )
    |> ignore

    services.AddSingleton<ModConductor.Engine.SettingsService>() |> ignore

    services.AddSingleton<ModConductor.Migration.IStore>(store.Migrations) |> ignore

    services.AddSingleton<ModConductor.Engine.MigrationService>() |> ignore

    services.AddSingleton<ModConductor.GameContexts.IGameContexts>(store.GameContexts)
    |> ignore

    services.AddSingleton<ModConductor.Engine.GameContextService>() |> ignore

    services.AddSingleton<ModConductor.Engine.SteamDiscoveryService>() |> ignore

    services.AddSingleton<ModConductor.Engine.ProtonContextService>() |> ignore

let internal registerOperationServices
    (services: IServiceCollection)
    (coordinator: Coordinator)
    (store: OperationStore)
    =
    services.AddSingleton<ModConductor.GeneratedOutputs.IGeneratedOutputs>(store.GeneratedOutputs)
    |> ignore

    services.AddSingleton<ModConductor.Engine.OutputService>() |> ignore

    services.AddSingleton<ModConductor.Deployment.IDeploymentBackend>(store.Deployments)
    |> ignore

    services.AddSingleton<ModConductor.Engine.DeploymentService>() |> ignore

    services.AddSingleton<ModConductor.Executables.IExecutables>(store.Executables)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ExecutableService>() |> ignore

    services.AddSingleton<ModConductor.GameLaunching.IGameLaunching>(store.GameLaunching)
    |> ignore

    services.AddSingleton<ModConductor.Engine.GameLaunchService>() |> ignore

    services.AddSingleton<ModConductor.ProfileGameData.IProfileGameData>(store.ProfileGameData)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ProfileDataService>() |> ignore

    services.AddSingleton<ModConductor.ArtifactLibrary.IArtifactLibrary>(store.Artifacts)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ArtifactService>() |> ignore

    services.AddSingleton<ModConductor.ArchiveInspection.Inspection>(store.ArchiveInspection)
    |> ignore

    services.AddSingleton<ModConductor.Engine.ArchiveInspectionService>() |> ignore

    services.AddSingleton<ModConductor.Persistence.BundleStore>(store.Bundles)
    |> ignore

    services.AddSingleton<ModConductor.Persistence.InstallationStore>(store.Installations)
    |> ignore

    services.AddSingleton<ModConductor.Persistence.DeletionStore>(store.Deletions)
    |> ignore

    services.AddSingleton<ModConductor.Engine.UpdateService>() |> ignore
    services.AddSingleton<ModConductor.Engine.DeletionService>() |> ignore

    services.AddSingleton<ModConductor.Engine.InstallationService>() |> ignore

    services.AddSingleton<ModConductor.HttpDownloads.DownloadSession>(store.Downloads)
    |> ignore

    services.AddSingleton<ModConductor.Engine.DownloadService>() |> ignore

    services.AddSingleton<Coordinator>(coordinator) |> ignore
    services.AddSingleton<ModConductor.Engine.OperationService>() |> ignore
