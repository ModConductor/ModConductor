namespace ModConductor.Persistence

open System
open ModConductor.Operations

type OperationStore
    (
        directory: string,
        ?downloadPolicy: ModConductor.HttpDownloads.DownloadPolicy,
        ?nexusLinks: ModConductor.HttpDownloads.INexusDownloadLinks,
        ?configurationCheckpoint: string -> unit
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

    let deploymentBackend =
        ModConductor.Deployment.DeploymentBackend(
            DeploymentBackendRepository(
                database,
                modLibrary.Access,
                filePlans,
                deployment,
                generations
            )
        )

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
        ProfileDataMutations(database, modLibrary.Access, deploymentBackend.TryAcquireWorkspace)

    let workspaces =
        WorkspaceStateStore(
            database,
            workspaceRoots,
            profileMutations.Edit,
            profileMutations.Resume
        )

    let executables =
        ModConductor.Executables.ExecutableSession(ExecutableRepository(database))

    let gameLaunching =
        ModConductor.GameLaunching.GameLaunchSession(
            gameContexts,
            deploymentBackend,
            executables,
            profileGameData
        )

    let connection = database.Connection

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

    member _.ModLibrary = modLibrary
    member _.ArtifactSource = artifacts :> ModConductor.ArtifactLibrary.IArtifactSource
    member _.ArchiveInspection = archiveInspection
    member _.Installations = installations
    member _.Bundles = bundles
    member _.Deletions = deletions
    member _.NexusMetadata = nexusMetadata

    member _.Downloads = downloads

    member _.Artifacts = artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary

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
                result)

        member _.Get(id) =
            enqueue (fun () ->
                find null id |> Option.map Ok |> Option.defaultValue (Error NotFound))

        member _.InitialFeed(cursor) = enqueue (fun () -> feed true cursor)

        member _.Changes(cursor) =
            enqueue (fun () -> feed false (Some cursor))

        member _.Interrupt(id) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                match find transaction id with
                | Some snapshot when snapshot.Phase = Running ->
                    save transaction { snapshot with Phase = Interrupted }
                | Some _
                | None -> ()

                transaction.Commit())

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

    interface IDisposable with
        member _.Dispose() =
            if
                not (
                    plugins.TryClose()
                    && archivePolicies.TryClose()
                    && installations.TryClose()
                    && deletions.TryClose()
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
