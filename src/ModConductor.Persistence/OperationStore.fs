namespace ModConductor.Persistence

open System
open ModConductor.Operations

type OperationStore
    (
        directory: string,
        ?downloadPolicy: ModConductor.HttpDownloads.DownloadPolicy,
        ?nexusLinks: ModConductor.HttpDownloads.INexusDownloadLinks,
        ?configurationCheckpoint: string -> unit,
        ?migrationCheckpoint: string -> unit,
        ?skseCheckpoint: string -> int -> unit,
        ?enbCheckpoint: string -> int -> unit,
        ?fnisCheckpoint: string -> int -> unit
    ) =
    let database = new StateDatabase(directory)
    let workspaceRoots = OwnedWorkspaceRootStore(database)
    let modLibrary = ModLibraryStore(database, workspaceRoots)

    let nexusMetadata =
        NexusMetadataStore(database) :> ModConductor.Nexus.INexusMetadataStore

    let artifacts = ArtifactStore(database, modLibrary.Access)

    let downloads =
        new ModConductor.HttpDownloads.DownloadSession(
            DownloadRepository(database, modLibrary.Access),
            ?policy = downloadPolicy,
            ?nexusLinks = nexusLinks
        )

    let bundleSources = BundleSources(database, modLibrary.Access)

    let archiveInspection =
        ModConductor.ArchiveInspection.Inspection(
            artifacts :> ModConductor.ArtifactLibrary.IArtifactSource,
            nested = (bundleSources :> ModConductor.ArchiveInspection.INestedArchiveSource)
        )

    let installations =
        InstallationStore(database, modLibrary.Access, artifacts, archiveInspection)

    let bundles = BundleStore(database, installations, bundleSources, archiveInspection)

    let deletions = DeletionStore(database, modLibrary.Access)

    let organization = ModOrganizationStore(database, modLibrary.Access)
    let selection = ModSelectionStore(database, modLibrary.Access)
    let gameContexts = GameContextStore(database, workspaceRoots)

    let filePlans =
        ModConductor.FilePlanning.FilePlanSession(
            FilePlanRepository(database, modLibrary.Access, modLibrary.PublicationOwner)
        )

    let plugins =
        ModConductor.Bethesda.PluginSession(FilePlanRepository(database, modLibrary.Access))

    let archivePolicies =
        ModConductor.Bethesda.ArchivePolicySession(
            FilePlanRepository(database, modLibrary.Access),
            archiveInspection
        )

    let deployment =
        ModConductor.DeploymentRecovery.Recovery(DeploymentRepository(database))

    let generations = DeploymentGenerationStore(database, modLibrary.Access, deployment)

    let outputs =
        ModConductor.GeneratedOutputs.GeneratedOutputSession(
            OutputRepository(database, modLibrary.Access, modLibrary.PublicationOwner)
        )

    let deploymentRepository =
        DeploymentBackendRepository(database, modLibrary.Access, filePlans, deployment, generations)

    let deploymentBackend =
        ModConductor.Deployment.DeploymentBackend(deploymentRepository)

    let profileGameData =
        ModConductor.ProfileGameData.ProfileGameDataSession(
            ProfileDataRepository(database, modLibrary.Access),
            deploymentBackend.TryAcquireWorkspace,
            (ModConductor.Deployment.GameProcesses.validate
             >> Result.map ignore
             >> Result.mapError ModConductor.ProfileGameData.ProfileDataError.Unavailable),
            plugins,
            archivePolicies,
            ?configurationCheckpoint = configurationCheckpoint
        )

    let loot =
        let executable =
            IO.Path.Combine(
                AppContext.BaseDirectory,
                if OperatingSystem.IsWindows() then
                    "modconductor-loot-helper.exe"
                else
                    "modconductor-loot-helper"
            )

        ModConductor.Loot.LootSession(
            FilePlanRepository(database, modLibrary.Access),
            directory,
            executable,
            (ModConductor.Deployment.GameProcesses.validate
             >> Result.mapError ModConductor.Loot.LootError.Unsupported)
        )

    let profileMutations =
        ProfileDataMutations(
            database,
            modLibrary.Access,
            deployment,
            deploymentBackend.TryAcquireWorkspace
        )

    let workspaces =
        WorkspaceStateStore(
            database,
            workspaceRoots,
            profileMutations.Edit,
            profileMutations.Resume
        )

    let migrations =
        MigrationStore(database, workspaceRoots, defaultArg migrationCheckpoint ignore)

    let executables =
        ModConductor.Executables.ExecutableSession(ExecutableRepository(database))

    let skseLoaders = SkseLoaderStore(database)
    let enbSetups = EnbStore(database)
    let fnisSetups = FnisStore(database)
    let skyrimSetups = SkyrimSetupStore(database)

    let fnisExecution =
        FnisExecutionStore(
            directory,
            database,
            modLibrary.Access,
            modLibrary.PublicationOwner,
            fnisSetups
        )

    let gameLaunching =
        ModConductor.GameLaunching.GameLaunchSession(
            gameContexts,
            deploymentBackend,
            executables,
            profileGameData,
            skseLoaders,
            configuration = enbSetups
        )

    let prepareComponents
        (
            id,
            expected: ModConductor.FilePlanning.SourceStamp,
            reviewed,
            progress,
            token,
            retainedProfile
        ) =
        task {
            let! read =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository)
                    .Read(expected.ProfileId)

            match read with
            | Error error -> return Error error
            | Ok(sources, existing) when sources.Stamp <> expected ->
                return Error ModConductor.DeploymentRecovery.RecoveryError.Stale
            | Ok(sources, existing) ->
                return!
                    DeploymentPreparation.components
                        database
                        modLibrary.Access
                        filePlans
                        generations
                        deployment
                        id
                        sources
                        existing
                        reviewed
                        retainedProfile
                        progress
                        token
        }

    let enbConfiguration =
        EnbConfigurationWorkflow(
            enbSetups,
            profileGameData,
            deployment,
            defaultArg enbCheckpoint (fun _ _ -> ())
        )

    let enbComponentInstaller =
        EnbComponentInstaller(database, artifacts, installations)

    let enbWorkflow =
        EnbWorkflow(
            database,
            gameContexts,
            deploymentRepository,
            enbSetups,
            profileGameData,
            enbComponentInstaller,
            enbConfiguration,
            generations,
            deployment,
            prepareComponents,
            defaultArg enbCheckpoint (fun _ _ -> ())
        )

    let skseComponentInstaller =
        SkseComponentInstaller(database, artifacts, installations, skseLoaders)

    let skseWorkflow =
        SkseWorkflow(
            database,
            skseComponentInstaller,
            gameContexts,
            deploymentRepository,
            skseLoaders,
            generations,
            deployment,
            prepareComponents,
            defaultArg skseCheckpoint (fun _ _ -> ())
        )

    let fnisComponentInstaller =
        FnisComponentInstaller(database, artifacts, installations)

    let fnisWorkflow =
        FnisWorkflow(
            database,
            fnisComponentInstaller,
            gameContexts,
            deploymentRepository,
            fnisSetups,
            generations,
            prepareComponents,
            defaultArg fnisCheckpoint (fun _ _ -> ())
        )

    let operations = OperationSession(database) :> IOperationStore

    member _.WorkspaceRoots = workspaceRoots

    member _.Workspaces = workspaces

    member _.Migrations = migrations :> ModConductor.Migration.IStore

    member internal _.MigrateAtCheckpoint(request, progress, token, checkpoint) =
        ModConductor.Migration.ModOrganizer.migrateAtCheckpoint
            (migrations :> ModConductor.Migration.IStore)
            request
            progress
            token
            checkpoint

    member internal _.MigrateVortexAtCheckpoint(request, progress, token, checkpoint) =
        ModConductor.Migration.Vortex.migrateAtCheckpoint
            (migrations :> ModConductor.Migration.IStore)
            request
            progress
            token
            checkpoint

    member _.ModLibrary = modLibrary
    member _.ArtifactSource = artifacts :> ModConductor.ArtifactLibrary.IArtifactSource
    member _.ArchiveInspection = archiveInspection
    member _.Installations = installations
    member _.Bundles = bundles
    member _.Deletions = deletions
    member _.NexusMetadata = nexusMetadata

    member _.Downloads = downloads

    member _.Artifacts = artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary
    member internal _.EnbSetups = enbSetups
    member internal _.FnisSetups = fnisSetups
    member internal _.SkyrimSetups = skyrimSetups
    member internal _.FnisExecution = fnisExecution

    member internal _.AddArtifactAtCheckpoint(request, token, checkpoint) =
        artifacts.AddAtCheckpoint(request, token, checkpoint)

    member _.ModSelection = selection
    member _.ModOrganization = organization

    member _.GameContexts = gameContexts
    member _.FilePlans = filePlans

    member internal _.FilePlansAtTextEffect(checkpoint) =
        ModConductor.FilePlanning.FilePlanSession(
            FilePlanRepository(database, modLibrary.Access, modLibrary.PublicationOwner, checkpoint)
        )

    member internal _.FilePlansAtTextPublicationCheckpoint(beforeEffect, afterEffect) =
        ModConductor.FilePlanning.FilePlanSession(
            FilePlanRepository(
                database,
                modLibrary.Access,
                modLibrary.PublicationOwner,
                beforeEffect,
                afterEffect
            )
        )

    member internal _.FilePlansAtTextObservation(afterObservation) =
        ModConductor.FilePlanning.FilePlanSession(
            FilePlanRepository(
                database,
                modLibrary.Access,
                modLibrary.PublicationOwner,
                afterTextObservation = afterObservation
            )
        )

    member internal _.EditTransientBytes action =
        database.Enqueue(fun () ->
            Sqlite.number
                database.Connection
                null
                "SELECT COALESCE((SELECT length(content) FROM mod_edit_origins WHERE edit_id=$id),-1)"
                [ "$id", box (string action) ])

    member internal _.EditPublicationResidue action =
        database.Enqueue(fun () ->
            let scalar table column =
                Sqlite.number
                    database.Connection
                    null
                    ("SELECT count(*) FROM " + table + " WHERE " + column + "=$id")
                    [ "$id", box (string action) ]

            let version =
                Sqlite.number
                    database.Connection
                    null
                    "SELECT count(*) FROM mod_versions WHERE id=$id"
                    [ "$id", box (string action) ]

            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT id FROM mod_payloads WHERE publication_id=$id"
                    [ "$id", box (string action) ]

            use reader = command.ExecuteReader()

            let payloads =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            version,
            scalar "mod_edit_origins" "version_id",
            scalar "mod_manifest" "version_id",
            payloads)

    member internal _.ProfileDataActionBytes action =
        database.Enqueue(fun () ->
            use command =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT body FROM profile_data_actions WHERE id=$id"
                    [ "$id", box (string action) ]

            command.ExecuteScalar() :?> byte array)

    member _.Plugins = plugins
    member _.GeneratedOutputs = outputs :> ModConductor.GeneratedOutputs.IGeneratedOutputs
    member _.Deployments = deploymentBackend :> ModConductor.Deployment.IDeploymentBackend

    member _.PluginOrders =
        profileGameData :> ModConductor.ProfileGameData.IProfilePluginOrders

    member _.Loot = loot :> ModConductor.Loot.ILootSorting

    member internal _.LootProjectionForFixture(order, token) =
        loot.ProjectionForFixture(order, token)

    member internal _.LootForFixture(helperPath, validator) =
        ModConductor.Loot.LootSession(
            FilePlanRepository(database, modLibrary.Access),
            directory,
            helperPath,
            validator
        )
        :> ModConductor.Loot.ILootSorting

    member _.ArchivePolicies =
        profileGameData :> ModConductor.ProfileGameData.IProfileArchivePolicies

    member _.ProfileGameData =
        profileGameData :> ModConductor.ProfileGameData.IProfileGameData

    member internal _.RetainedProfileSavePreviewCount =
        profileGameData.RetainedSavePreviewCount

    member _.GameLaunching = gameLaunching :> ModConductor.GameLaunching.IGameLaunching

    member internal _.ToolLaunching =
        gameLaunching :> ModConductor.GameLaunching.IToolLaunchProjection

    member internal _.SkseLoaders = skseLoaders
    member _.CloseExecutables() = executables.Close()
    member _.ExecutablesFailed = executables.Failed

    member _.Executables = executables :> ModConductor.Executables.IExecutables

    member _.SqliteVersion = database.Connection.ServerVersion

    interface IOperationStore with
        member _.Begin(request) = operations.Begin(request)

        member _.Advance(id, progress, runtime) =
            operations.Advance(id, progress, runtime)

        member _.Cancel(id) = operations.Cancel(id)
        member _.Get(id) = operations.Get(id)
        member _.InitialFeed(cursor) = operations.InitialFeed(cursor)
        member _.Changes(cursor) = operations.Changes(cursor)

        member _.WaitForChanges(cursor, token) =
            operations.WaitForChanges(cursor, token)

        member _.Interrupt(id) = operations.Interrupt(id)

    member internal _.ApplyOutputAtCheckpoint
        (id, snapshot, selected, action, token, afterPublication)
        =
        outputs.ApplyAtCheckpoint(id, snapshot, selected, action, token, afterPublication)

    member internal _.CloneProfileDataAtCheckpoint
        (workspace, expected, source, target, token, checkpoint)
        =
        profileMutations.CloneAtCaptureCheckpoint(
            workspace,
            expected,
            source,
            target,
            token,
            checkpoint
        )

    member internal _.ApplyProfileDataAtCheckpoint
        (id, workspace, profile, expected, token, checkpoint)
        =
        task {
            match deploymentBackend.TryAcquireWorkspace workspace with
            | None -> return Error ModConductor.ProfileGameData.ProfileDataError.Busy
            | Some lease ->
                use lease = lease

                return!
                    profileGameData.ApplyForLaunchAtCheckpoint(
                        id,
                        workspace,
                        profile,
                        expected,
                        token,
                        (fun _ -> System.Threading.Tasks.Task.FromResult()),
                        checkpoint
                    )
        }

    member internal _.RestoreProfileDataAtCheckpoint(id, expected, token, checkpoint) =
        profileGameData.RestoreAtCheckpoint(id, expected, token, checkpoint)

    member _.DrainOutputs() = outputs.Drain()

    member _.DrainDeployments() =
        task {
            do! plugins.Drain()
            do! archivePolicies.Drain()
            do! deploymentBackend.Drain()
            do! profileGameData.Drain()
        }

    member internal _.Deployment = deployment
    member internal _.Generations = generations

    member internal _.EnbConfigurationDeploymentState(receipt: Guid) =
        enbConfiguration.EnbConfigurationDeploymentState receipt

    member internal _.RecoverEnbConfigurationAction(operation, token) =
        enbConfiguration.RecoverEnbConfigurationAction(operation, token)

    member internal _.RestoreEnbConfiguration(operation, token) =
        enbConfiguration.RestoreEnbConfiguration(operation, token)

    member internal _.PrepareComponents
        (
            id: Guid,
            expected: ModConductor.FilePlanning.SourceStamp,
            reviewed: ModConductor.DeploymentPlanning.ReviewedComponent list,
            progress: ModConductor.Deployment.DeploymentProgress -> unit,
            token: Threading.CancellationToken,
            ?retainedProfile: ModConductor.DeploymentRecovery.SavedProfile
        ) =
        prepareComponents (id, expected, reviewed, progress, token, retainedProfile)

    member internal _.InstallSkse
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Skse.SkseRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            sourceCheckedAt: DateTimeOffset,
            token: Threading.CancellationToken
        ) =
        skseWorkflow.InstallSkse(workspace, profile, release, artifact, sourceCheckedAt, token)

    member internal _.InstallFnis
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Fnis.FnisRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            token: Threading.CancellationToken
        ) =
        fnisWorkflow.InstallFnis(workspace, profile, release, artifact, token)

    member internal _.RemoveFnis
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        fnisWorkflow.RemoveFnis(workspace, profile, token)

    member internal _.RemoveSkse
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        skseWorkflow.RemoveSkse(workspace, profile, token)

    member internal _.InstallEnb
        (workspace, profile, row, runtimeArtifact, acquired, token, ?runtimeOnly)
        =
        enbWorkflow.InstallEnb(
            workspace,
            profile,
            row,
            runtimeArtifact,
            acquired,
            token,
            ?runtimeOnly = runtimeOnly
        )

    member internal _.RemoveEnb(workspace, profile, token, ?runtimeOnly) =
        enbWorkflow.RemoveEnb(workspace, profile, token, ?runtimeOnly = runtimeOnly)

    interface IDisposable with
        member _.Dispose() =
            if
                not (
                    plugins.TryClose()
                    && archivePolicies.TryClose()
                    && installations.TryClose()
                    && downloads.TryClose()
                    && outputs.TryClose(fun () ->
                        deploymentBackend.TryClose(fun () ->
                            profileGameData.TryClose(fun () ->
                                generations.TryClose(fun () ->
                                    deployment.TryClose()
                                    && filePlans.TryClose()
                                    && gameContexts.TryClose()
                                    && modLibrary.TryClose(fun () ->
                                        workspaces.TryClose(workspaceRoots.TryClose))))))
                )
            then
                invalidOp
                    "A workspace change or root file check is still active. Wait for it before closing the store."


            (downloads :> IDisposable).Dispose()
            executables.Close().GetAwaiter().GetResult()
            (database :> IDisposable).Dispose()
