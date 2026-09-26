namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
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
            ModConductor.Deployment.GameProcesses.validate >> ignore,
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
            ModConductor.Deployment.GameProcesses.validate
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
            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository)
                    .Read(expected.ProfileId)

            if sources.Stamp <> expected then
                raise (
                    ModConductor.DeploymentRecovery.RecoveryException
                        ModConductor.DeploymentRecovery.RecoveryError.Stale
                )

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

    let connection = database.Connection
    let changesGate = obj ()

    let mutable changes =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let notifyChanges () =
        lock changesGate (fun () ->
            let prior = changes
            changes <- TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
            prior.TrySetResult() |> ignore)

    let state transaction =
        OperationJournal.state connection transaction

    let find transaction id =
        OperationJournal.find connection transaction id

    let save transaction snapshot =
        OperationJournal.save connection transaction snapshot

    let enqueue action = database.Enqueue action
    let enqueueInternal action = database.EnqueueInternal action

    let feed initial requested =
        use transaction = connection.BeginTransaction(deferred = true)
        let revision, cursor = state transaction

        let gap =
            requested
            |> Option.exists (fun after -> after < max 0L (cursor - 128L) || after > cursor)

        let result =
            if initial || gap then
                { Cursor = cursor
                  Revision = revision
                  ResyncRequired = gap
                  Snapshot =
                    Some(
                        OperationRows.list
                            connection
                            transaction
                            ("SELECT "
                             + OperationRows.columns
                             + " FROM operations ORDER BY last_cursor DESC LIMIT 16")
                            []
                    )
                  Changes = [] }
            else
                let after = requested |> Option.defaultValue cursor

                use statement =
                    Sqlite.command
                        connection
                        transaction
                        ("SELECT "
                         + OperationRows.columns
                         + ",cursor FROM operation_events WHERE cursor>$after ORDER BY cursor LIMIT 16")
                        [ "$after", box after ]

                use reader = statement.ExecuteReader()

                let changes =
                    [ while reader.Read() do
                          yield
                              { Cursor = reader.GetInt64 9
                                Operation = OperationRows.read reader } ]

                { Cursor =
                    changes
                    |> List.tryLast
                    |> Option.map (fun change -> change.Cursor)
                    |> Option.defaultValue after
                  Revision = revision
                  ResyncRequired = false
                  Snapshot = None
                  Changes = changes }

        transaction.Commit()
        result

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

    member _.SqliteVersion = connection.ServerVersion

    interface IOperationStore with
        member _.Begin(request) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction request.Id with
                    | Some snapshot when snapshot.Request = request -> Ok(snapshot, false)
                    | Some _ -> Error IdentityConflict
                    | None ->
                        let revision, _ = state transaction

                        if revision <> request.ExpectedRevision then
                            Error StaleRevision
                        elif
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM operations WHERE phase=1"
                                []
                            >= 16L
                        then
                            Error Capacity
                        else
                            let snapshot =
                                { Request = request
                                  Phase = Running
                                  Progress = 0
                                  Result = None
                                  ResultRevision = 0L }

                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO operations(id,owner,expected_revision,count,phase,progress,result_revision,last_cursor) VALUES($id,$owner,$expected,$count,1,0,0,0)"
                                [ "$id", box request.Id
                                  "$owner", box database.OwnerId
                                  "$expected", box request.ExpectedRevision
                                  "$count", box request.Count ]

                            save transaction snapshot
                            Ok(snapshot, true)

                transaction.Commit()

                match result with
                | Ok(_, true) -> notifyChanges ()
                | _ -> ()

                result)

        member _.Advance(id, progress, runtime) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = find transaction id |> Option.get

                let snapshot =
                    if current.Phase <> Running then
                        current
                    elif progress = current.Request.Count then
                        let revision, _ = state transaction

                        if revision <> current.Request.ExpectedRevision then
                            { current with
                                Phase = Stale
                                Progress = progress }
                        else
                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE operation_state SET revision=revision+1 WHERE id=1"
                                []

                            { current with
                                Phase = Completed
                                Progress = progress
                                Result = Some runtime
                                ResultRevision = revision + 1L }
                    else
                        { current with Progress = progress }

                if snapshot <> current then
                    save transaction snapshot

                transaction.Commit()

                if snapshot <> current then
                    notifyChanges ()

                snapshot)

        member _.Cancel(id) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction id with
                    | None -> Error NotFound
                    | Some snapshot when snapshot.Phase = Running ->
                        let cancelled = { snapshot with Phase = Cancelled }
                        save transaction cancelled
                        Ok cancelled
                    | Some snapshot -> Ok snapshot

                transaction.Commit()

                match result with
                | Ok snapshot when snapshot.Phase = Cancelled -> notifyChanges ()
                | _ -> ()

                result)

        member _.Get(id) =
            enqueue (fun () ->
                find null id |> Option.map Ok |> Option.defaultValue (Error NotFound))

        member _.InitialFeed(cursor) = enqueue (fun () -> feed true cursor)

        member _.Changes(cursor) =
            enqueue (fun () -> feed false (Some cursor))

        member _.WaitForChanges(cursor, token) =
            task {
                let! pending =
                    enqueue (fun () ->
                        let _, current = state null

                        if current > cursor then
                            Task.CompletedTask
                        else
                            lock changesGate (fun () -> changes.Task))

                do! pending.WaitAsync(token)
            }
            :> Task

        member _.Interrupt(id) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                match find transaction id with
                | Some snapshot when snapshot.Phase = Running ->
                    save transaction { snapshot with Phase = Interrupted }
                    transaction.Commit()
                    notifyChanges ()
                | Some _
                | None -> transaction.Commit())

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

    member internal this.InstallFnis
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Fnis.FnisRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            token: Threading.CancellationToken
        ) =
        task {
            let fail detail = raise (IO.IOException detail)

            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, artifact.Id)

            let artifact =
                currentArtifact
                |> Result.defaultWith (fun _ -> fail "The verified FNIS archive is unavailable.")

            if
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
            then
                fail "The verified FNIS archive is not ready."

            let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                { WorkspaceId = workspace
                  Id = artifact.Id
                  Revision = artifact.Revision }

            let! draft = installations.Prepare(reference, token)

            let plan =
                ModConductor.Fnis.FnisArchiveLayout.review draft
                |> Result.defaultWith (ModConductor.Fnis.FnisProblem.message >> fail)

            let reviewed =
                installations.SelectReviewed(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    "FNIS Behavior SE",
                    string release.ComponentVersion,
                    plan.Files
                )

            let installationId = Guid.NewGuid()

            let mutable installed =
                installations.Start(workspace, reviewed.Id, reviewed.Revision, installationId)

            while installed.State = ModConductor.ArchiveInstallation.InstallationState.Running do
                do! installations.WaitForChange(workspace, installationId, installed, token)
                let! current = installations.Read(workspace, installationId)
                installed <- current

            do! installations.WaitForWorker(installationId, token)

            if
                installed.State <> ModConductor.ArchiveInstallation.InstallationState.Complete
                || installed.ModId.IsNone
                || installed.VersionId.IsNone
            then
                fail (
                    installed.Problem
                    |> Option.defaultValue
                        "FNIS installation did not complete. No component was published."
                )

            let! version =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null installed.VersionId.Value 0 20001
                    |> Option.map (fun value -> { value with NextOffset = None }))

            let version =
                version
                |> Option.defaultWith (fun () -> fail "The installed FNIS version is unavailable.")

            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

            let context =
                contextResult
                |> Result.defaultWith (fun _ ->
                    fail "The checked Skyrim installation is unavailable.")

            let evidence =
                context.Binding
                |> Option.map _.Evidence
                |> Option.defaultWith (fun () ->
                    fail "The checked Skyrim installation is unavailable.")

            if
                evidence.DefinitionId <> ModConductor.GameContexts.Skyrim.definition.Id
                || ModConductor.GameContexts.Skyrim.definition.Storefront <> "Steam"
            then
                fail "FNIS setup supports Skyrim Special Edition from Steam."

            let gameRoot =
                ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence
                |> Result.defaultWith fail

            let reviewedComponent =
                ModConductor.DeploymentPlanning.ComponentManifests.review
                    workspace
                    gameRoot
                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                    { ModId = installed.ModId.Value
                      Version = version
                      Priority = 0
                      Files = plan.ComponentFiles }
                |> Result.defaultWith (fun _ ->
                    fail "The reviewed FNIS component no longer matches the installed archive.")

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let! previous =
                fnisSetups.ReadStored(workspace, profile, existing |> Option.bind _.Active)

            let previousMod = previous |> Option.map _.ModId

            let stagedMods =
                sources.Profile.Mods
                |> List.map (fun selected ->
                    if selected.ModId = installed.ModId.Value then
                        { selected with Enabled = true }
                    elif previousMod = Some selected.ModId then
                        { selected with Enabled = false }
                    else
                        selected)

            if
                stagedMods
                |> List.exists (fun selected -> selected.ModId = installed.ModId.Value)
                |> not
            then
                fail "The installed FNIS component is unavailable to this profile."

            let! profileName =
                database.Enqueue(fun () ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT name FROM profiles WHERE id=$id"
                            [ "$id", box (string profile) ]

                    match query.ExecuteScalar() with
                    | :? string as value -> value
                    | _ -> fail "The selected profile is unavailable.")

            let retained: ModConductor.DeploymentRecovery.SavedProfile =
                { Id = profile
                  Name = profileName
                  Revision = sources.Profile.Revision
                  Mods =
                    stagedMods
                    |> List.map (fun selected ->
                        { ModId = selected.ModId
                          VersionId = selected.Version |> Option.map _.Id
                          Priority = selected.Priority
                          Enabled = selected.Enabled })
                  Hidden = sources.Hidden }

            let deploymentId = Guid.NewGuid()

            let! prepared =
                this.PrepareComponents(
                    deploymentId,
                    sources.Stamp,
                    [ reviewedComponent ],
                    ignore,
                    token,
                    retainedProfile = retained
                )

            let generator: StoredFnisGenerator =
                { GenerationId = prepared.Switch.Generation.Id
                  ModId = installed.ModId.Value
                  VersionId = installed.VersionId.Value
                  ArtifactId = artifact.Id
                  FileName = release.File.Name
                  FileVersion = release.File.Version
                  Executable = IO.Path.Combine(evidence.RootPath, plan.Generator)
                  ComponentVersion = string release.ComponentVersion
                  ArchiveSha256 = artifact.Sha256.Value
                  Provider = ModConductor.Fnis.FnisCatalogue.Provider
                  Source = ModConductor.Fnis.FnisCatalogue.Source
                  Terms = ModConductor.Fnis.FnisCatalogue.Terms
                  NexusModId = release.ModId
                  NexusFileId = release.File.Id
                  AcquiredAt = DateTimeOffset.UtcNow }

            do!
                fnisSetups.StageInstall(
                    deploymentId,
                    sources.Profile.Revision,
                    previousMod,
                    generator,
                    workspace,
                    profile
                )

            let! started = generations.Start(prepared, [], cancellation = token)

            let receipt =
                match started with
                | Ok value -> value
                | Error _ ->
                    fnisSetups.RemoveIntent deploymentId
                    |> fun pending -> pending.GetAwaiter().GetResult()

                    fail "The FNIS deployment could not start."

            let! completed =
                generations.Run(
                    receipt.Id,
                    receipt.Revision,
                    false,
                    token,
                    defaultArg fnisCheckpoint (fun _ _ -> ()),
                    []
                )

            match completed with
            | Ok value -> return value.Proposed
            | Error _ ->
                return
                    fail
                        "The FNIS deployment did not complete. Recover the previous setup before retrying."
        }

    member internal this.RemoveFnis
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
            let fail detail = raise (IO.IOException detail)

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let active = existing |> Option.bind _.Active
            let! generator = fnisSetups.ReadStored(workspace, profile, active)

            match generator with
            | None -> return active
            | Some generator ->
                let staged =
                    sources.Profile.Mods
                    |> List.map (fun selected ->
                        if selected.ModId = generator.ModId then
                            { selected with Enabled = false }
                        else
                            selected)

                let! profileName =
                    database.Enqueue(fun () ->
                        use query =
                            Sqlite.command
                                database.Connection
                                null
                                "SELECT name FROM profiles WHERE id=$id"
                                [ "$id", box (string profile) ]

                        match query.ExecuteScalar() with
                        | :? string as value -> value
                        | _ -> fail "The selected profile is unavailable.")

                let retained: ModConductor.DeploymentRecovery.SavedProfile =
                    { Id = profile
                      Name = profileName
                      Revision = sources.Profile.Revision
                      Mods =
                        staged
                        |> List.map (fun selected ->
                            { ModId = selected.ModId
                              VersionId = selected.Version |> Option.map _.Id
                              Priority = selected.Priority
                              Enabled = selected.Enabled })
                      Hidden = sources.Hidden }

                let deploymentId = Guid.NewGuid()

                let! prepared =
                    this.PrepareComponents(
                        deploymentId,
                        sources.Stamp,
                        [],
                        ignore,
                        token,
                        retainedProfile = retained
                    )

                do!
                    fnisSetups.StageRemoval(
                        deploymentId,
                        sources.Profile.Revision,
                        generator.ModId,
                        prepared.Switch.Generation.Id,
                        workspace,
                        profile
                    )

                let! started = generations.Start(prepared, [], cancellation = token)

                let receipt =
                    match started with
                    | Ok value -> value
                    | Error _ ->
                        fnisSetups.RemoveIntent deploymentId
                        |> fun pending -> pending.GetAwaiter().GetResult()

                        fail "FNIS removal could not start."

                let! completed =
                    generations.Run(
                        receipt.Id,
                        receipt.Revision,
                        false,
                        token,
                        defaultArg fnisCheckpoint (fun _ _ -> ()),
                        []
                    )

                match completed with
                | Ok value -> return Some value.Proposed
                | Error _ -> return fail "FNIS removal needs deployment recovery."
        }

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
