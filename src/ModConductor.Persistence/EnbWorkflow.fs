namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbWorkflow
    (
        database: StateDatabase,
        gameContexts: GameContextStore,
        deploymentRepository: DeploymentBackendRepository,
        enbSetups: EnbStore,
        profileGameData: ModConductor.ProfileGameData.ProfileGameDataSession,
        componentInstaller: EnbComponentInstaller,
        configuration: EnbConfigurationWorkflow,
        generations: DeploymentGenerationStore,
        deployment: ModConductor.DeploymentRecovery.Recovery,
        prepareComponents: EnbPrepareComponents,
        enbCheckpoint: string -> int -> unit
    ) =
    let preparation =
        EnbPreparation(database, gameContexts, deploymentRepository, enbSetups, profileGameData)

    let publication =
        EnbInstallDeployment(
            enbSetups,
            configuration,
            generations,
            deployment,
            prepareComponents,
            enbCheckpoint
        )

    let installation = EnbInstallation(preparation, componentInstaller, publication)

    let removal =
        EnbRemoval(
            database,
            deploymentRepository,
            enbSetups,
            configuration,
            generations,
            prepareComponents
        )

    member internal _.InstallEnb
        (
            workspace: Guid,
            profile: Guid,
            row: ModConductor.Enb.EnbCompatibilityRow,
            runtimeArtifact: ModConductor.ArtifactLibrary.Artifact,
            acquired:
                (ModConductor.Enb.EnbComponentPin *
                ModConductor.Nexus.NexusFile *
                ModConductor.ArtifactLibrary.Artifact) list,
            token: CancellationToken,
            ?runtimeOnly: bool
        ) =
        installation.InstallEnb(
            workspace,
            profile,
            row,
            runtimeArtifact,
            acquired,
            token,
            ?runtimeOnly = runtimeOnly
        )

    member internal _.RemoveEnb
        (workspace: Guid, profile: Guid, token: CancellationToken, ?runtimeOnly: bool)
        =
        removal.RemoveEnb(workspace, profile, token, ?runtimeOnly = runtimeOnly)
