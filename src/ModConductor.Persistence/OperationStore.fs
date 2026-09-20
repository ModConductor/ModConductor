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
        ?enbCheckpoint: string -> int -> unit
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
        ProfileDataMutations(database, modLibrary.Access, deploymentBackend.TryAcquireWorkspace)

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

    let gameLaunching =
        ModConductor.GameLaunching.GameLaunchSession(
            gameContexts,
            deploymentBackend,
            executables,
            profileGameData,
            skseLoaders,
            configuration = enbSetups
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

    member internal _.PrepareComponents
        (
            id: Guid,
            expected: ModConductor.FilePlanning.SourceStamp,
            reviewed: ModConductor.DeploymentPlanning.ReviewedComponent list,
            progress: ModConductor.Deployment.DeploymentProgress -> unit,
            token: Threading.CancellationToken,
            ?retainedProfile: ModConductor.DeploymentRecovery.SavedProfile
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

    member internal this.InstallSkse
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Skse.SkseRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            sourceCheckedAt: DateTimeOffset,
            token: Threading.CancellationToken
        ) =
        task {
            let fail detail = raise (IO.IOException detail)

            let! currentArtifact =
                (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                    .Read(workspace, artifact.Id)

            let artifact =
                currentArtifact
                |> Result.defaultWith (fun _ -> fail "The verified SKSE archive is unavailable.")

            if
                artifact.WorkspaceId <> workspace
                || (artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                    && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed)
                || artifact.Sha256.IsNone
            then
                fail "The verified SKSE archive is not ready."

            let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                { WorkspaceId = workspace
                  Id = artifact.Id
                  Revision = artifact.Revision }

            let! draft = installations.Prepare(reference, token)

            let plan =
                ModConductor.Skse.SkseArchiveLayout.review release draft.Manifest
                |> Result.defaultWith (ModConductor.Skse.SkseProblem.message >> fail)

            let reviewed =
                installations.SelectReviewed(
                    workspace,
                    draft.Id,
                    draft.Revision,
                    "Skyrim Script Extender",
                    string release.ComponentVersion,
                    plan.Files
                )

            let installationId = Guid.NewGuid()

            let started =
                installations.Start(workspace, reviewed.Id, reviewed.Revision, installationId)

            let mutable installed = started

            while installed.State = ModConductor.ArchiveInstallation.InstallationState.Running do
                do! System.Threading.Tasks.Task.Delay(25, token)
                let! current = installations.Read(workspace, installationId)
                installed <- current

            if
                installed.State <> ModConductor.ArchiveInstallation.InstallationState.Complete
                || installed.ModId.IsNone
                || installed.VersionId.IsNone
            then
                fail (
                    installed.Problem
                    |> Option.defaultValue
                        "SKSE installation did not complete. No component was published."
                )

            let! version =
                database.Enqueue(fun () ->
                    LibraryRows.version database.Connection null installed.VersionId.Value 0 20001
                    |> Option.map (fun value -> { value with NextOffset = None }))

            let version =
                version
                |> Option.defaultWith (fun () -> fail "The installed SKSE version is unavailable.")

            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read workspace

            let context =
                contextResult
                |> Result.defaultWith (fun _ ->
                    fail "The checked Skyrim installation is unavailable.")

            let evidence = context.Binding.Value.Evidence

            let currentRuntime =
                match Version.TryParse evidence.Executable.Value.FileVersion with
                | true, value -> Some value
                | _ -> None

            if currentRuntime <> Some release.RuntimeVersion then
                fail "Skyrim changed after the compatibility check. Check SKSE again."

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
                    fail "The reviewed SKSE component no longer matches the installed archive.")

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let! previousLoader =
                skseLoaders.ReadStored(workspace, profile, existing |> Option.bind _.Active)

            let previousMod = previousLoader |> Option.map _.ModId

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
                fail "The installed SKSE component is unavailable to this profile."

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

            let stagedProfile: ModConductor.DeploymentRecovery.SavedProfile =
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
                (this.PrepareComponents(
                    deploymentId,
                    sources.Stamp,
                    [ reviewedComponent ],
                    ignore,
                    token,
                    retainedProfile = stagedProfile
                ))

            do!
                skseLoaders.StageReplacement(
                    deploymentId,
                    sources.Profile.Revision,
                    previousMod,
                    { Loader =
                        { GenerationId = prepared.Switch.Generation.Id
                          Executable = IO.Path.Combine(evidence.RootPath, plan.Loader)
                          ComponentVersion = string release.ComponentVersion
                          RuntimeVersion = string release.RuntimeVersion
                          GameSha256 = evidence.Executable.Value.Sha256 }
                      ModId = installed.ModId.Value
                      VersionId = installed.VersionId.Value
                      ArchiveSha256 = artifact.Sha256.Value
                      NexusModId = release.ModId
                      NexusFileId = release.File.Id
                      SourceCheckedAt = sourceCheckedAt },
                    workspace,
                    profile
                )

            let! receipt = generations.Start(prepared, [], cancellation = token)

            let receipt =
                match receipt with
                | Ok value -> value
                | Error _ ->
                    skseLoaders.RemoveReplacement deploymentId
                    |> fun pending -> pending.GetAwaiter().GetResult()

                    fail "The SKSE deployment could not start."

            let! completed =
                generations.Run(
                    receipt.Id,
                    receipt.Revision,
                    false,
                    token,
                    defaultArg skseCheckpoint (fun _ _ -> ()),
                    []
                )

            let completed =
                match completed with
                | Ok value -> value
                | Error _ ->
                    let pending = deployment.Read(receipt.Id).GetAwaiter().GetResult()

                    match pending with
                    | Some pending ->
                        generations.Run(
                            pending.Id,
                            pending.Revision,
                            true,
                            Threading.CancellationToken.None,
                            (fun _ _ -> ()),
                            []
                        )
                        |> fun restore -> restore.GetAwaiter().GetResult()
                        |> Result.defaultWith (fun _ ->
                            fail "The failed SKSE replacement needs deployment recovery.")
                        |> ignore
                    | None -> ()

                    fail "The SKSE deployment did not complete. The previous setup was restored."

            return completed.Proposed
        }

    member internal this.InstallEnb
        (
            workspace: Guid,
            profile: Guid,
            row: ModConductor.Enb.EnbCompatibilityRow,
            runtimeArtifact: ModConductor.ArtifactLibrary.Artifact,
            acquired:
                (ModConductor.Enb.EnbComponentPin *
                ModConductor.Nexus.NexusFile *
                ModConductor.ArtifactLibrary.Artifact) list,
            token: Threading.CancellationToken
        ) =
        task {
            let fail detail = raise (IO.IOException detail)

            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read workspace

            let context =
                contextResult
                |> Result.defaultWith (fun _ ->
                    fail "The checked Skyrim installation is unavailable.")

            let evidence =
                context.Binding
                |> Option.map _.Evidence
                |> Option.defaultWith (fun () ->
                    fail "The checked Skyrim installation is unavailable.")

            let gameRoot =
                ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence
                |> Result.defaultWith fail

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let active = existing |> Option.bind _.Active
            let! owner = enbSetups.Owner(workspace, active)

            if owner |> Option.exists ((<>) profile) then
                fail "Another profile owns the active renderer targets. Remove its ENB setup first."

            let! priorComponents = enbSetups.Components(workspace, profile, active)

            if priorComponents.IsEmpty then
                for name in
                    [ "d3d11.dll"
                      "d3dcompiler_46e.dll"
                      "dxgi.dll"
                      IO.Path.Combine("Data", "SKSE", "Plugins", "CommunityShaders.dll") ] do
                    if IO.File.Exists(IO.Path.Combine(evidence.RootPath, name)) then
                        fail (
                            ModConductor.Enb.EnbProblem.message (
                                ModConductor.Enb.EnbProblem.ForeignDllConflict name
                            )
                        )

            let install
                (pin: ModConductor.Enb.EnbComponentPin)
                fileId
                (artifact: ModConductor.ArtifactLibrary.Artifact)
                =
                task {
                    let! current =
                        (artifacts :> ModConductor.ArtifactLibrary.IArtifactLibrary)
                            .Read(workspace, artifact.Id)

                    let artifact =
                        current
                        |> Result.defaultWith (fun _ ->
                            fail (pin.Name + " archive is unavailable."))

                    if
                        artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Ready
                        && artifact.State <> ModConductor.ArtifactLibrary.ArtifactState.Installed
                    then
                        fail (pin.Name + " archive is not ready.")

                    let hash =
                        artifact.Sha256
                        |> Option.defaultWith (fun () ->
                            fail (pin.Name + " archive has no verified hash."))

                    let pinned = ModConductor.Enb.EnbCatalogue.withHash hash pin

                    let reference: ModConductor.ArtifactLibrary.ArtifactRef =
                        { WorkspaceId = workspace
                          Id = artifact.Id
                          Revision = artifact.Revision }

                    let! draft = installations.Prepare(reference, token)

                    let layout =
                        match pin.Kind with
                        | ModConductor.Enb.EnbComponentKind.Runtime ->
                            ModConductor.Enb.EnbArchiveLayouts.runtime pinned draft.Manifest
                        | ModConductor.Enb.EnbComponentKind.Preset ->
                            ModConductor.Enb.EnbArchiveLayouts.leanPreset pinned draft.Manifest
                        | ModConductor.Enb.EnbComponentKind.Companion ->
                            ModConductor.Enb.EnbArchiveLayouts.dataCompanion pinned draft.Manifest
                        |> Result.defaultWith (ModConductor.Enb.EnbProblem.message >> fail)

                    let reviewed =
                        installations.SelectReviewed(
                            workspace,
                            draft.Id,
                            draft.Revision,
                            pin.Name,
                            pin.Version,
                            layout.Files
                        )

                    let installationId = Guid.NewGuid()

                    let mutable installed =
                        installations.Start(
                            workspace,
                            reviewed.Id,
                            reviewed.Revision,
                            installationId
                        )

                    while installed.State = ModConductor.ArchiveInstallation.InstallationState.Running do
                        do! Threading.Tasks.Task.Delay(25, token)
                        let! current = installations.Read(workspace, installationId)
                        installed <- current

                    if
                        installed.State
                        <> ModConductor.ArchiveInstallation.InstallationState.Complete
                        || installed.ModId.IsNone
                        || installed.VersionId.IsNone
                    then
                        fail (
                            installed.Problem
                            |> Option.defaultValue (pin.Name + " installation did not complete.")
                        )

                    let! version =
                        database.Enqueue(fun () ->
                            LibraryRows.version
                                database.Connection
                                null
                                installed.VersionId.Value
                                0
                                20001
                            |> Option.map (fun value -> { value with NextOffset = None }))

                    let version =
                        version
                        |> Option.defaultWith (fun () ->
                            fail (pin.Name + " installed version is unavailable."))

                    let reviewedComponent =
                        ModConductor.DeploymentPlanning.ComponentManifests.review
                            workspace
                            gameRoot
                            ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                            { ModId = installed.ModId.Value
                              Version = version
                              Priority = 0
                              Files = layout.ComponentFiles }
                        |> Result.defaultWith (fun _ ->
                            fail (pin.Name + " no longer matches its reviewed archive layout."))

                    let stored: StoredEnbComponent =
                        { Kind =
                            match pin.Kind with
                            | ModConductor.Enb.EnbComponentKind.Runtime -> "runtime"
                            | ModConductor.Enb.EnbComponentKind.Preset -> "preset"
                            | ModConductor.Enb.EnbComponentKind.Companion ->
                                "companion:"
                                + (pin.NexusModId
                                   |> Option.map string
                                   |> Option.defaultValue pin.Name)
                          ModId = installed.ModId.Value
                          VersionId = installed.VersionId.Value
                          Version = pin.Version
                          Sha256 = hash
                          NexusModId = pin.NexusModId
                          NexusFileId = fileId
                          Source = pin.Source.AbsoluteUri
                          Terms = pin.Terms.AbsoluteUri
                          CheckedAt = DateTimeOffset.UtcNow }

                    return reviewedComponent, stored
                }

            let! runtime = install row.Runtime None runtimeArtifact
            let mutable installed = [ runtime ]

            for pin, file, artifact in acquired do
                let! value = install pin (Some file.Id) artifact
                installed <- installed @ [ value ]

            let components = installed |> List.map fst
            let records = installed |> List.map snd

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository)
                    .Read(profile)

            if
                sources.Stamp.WorkspaceId <> workspace
                || (existing |> Option.bind _.Active) <> active
            then
                fail "The profile deployment changed while ENB components were installed."

            let previousIds = priorComponents |> List.map _.ModId |> Set.ofList
            let nextIds = records |> List.map _.ModId |> Set.ofList

            let desired =
                ((previousIds - nextIds) |> Set.toList |> List.map (fun id -> id, false))
                @ (nextIds |> Set.toList |> List.map (fun id -> id, true))

            let stagedMods =
                sources.Profile.Mods
                |> List.map (fun selected ->
                    match desired |> List.tryFind (fst >> (=) selected.ModId) with
                    | Some(_, enabled) -> { selected with Enabled = enabled }
                    | None -> selected)

            if
                nextIds
                |> Set.forall (fun id ->
                    stagedMods |> List.exists (fun selected -> selected.ModId = id))
                |> not
            then
                fail "An installed ENB component is unavailable to this profile."

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

            let! previousConfiguration = enbSetups.ConfigurationPlan(workspace, profile, active)
            let previousAction = previousConfiguration |> Option.bind snd
            let mutable configurationAction = previousAction
            let mutable priorValues = Map.empty

            if previousAction.IsNone then
                let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData
                let! state = profiles.Read(workspace, profile)
                let state = state |> Result.defaultWith (fun error -> fail (string error))

                let! document =
                    profiles.ReadConfiguration(state.Reference, "SkyrimPrefs.ini", token)

                let document =
                    document
                    |> Result.defaultWith (fun _ ->
                        fail "Turn on local game settings before setting up ENB.")

                let content, previous =
                    ModConductor.Enb.EnbSetupPlanning.configureSkyrimPrefs document.Document.Content

                let action = Guid.NewGuid()

                let! saved =
                    profiles.SaveConfiguration(
                        { Id = action
                          PreviewId = document.PreviewId
                          Expected = document.Expected
                          Name = document.Name
                          Content = content },
                        ignore,
                        token
                    )

                saved
                |> Result.defaultWith (fun _ ->
                    fail "Skyrim graphics settings could not be applied.")
                |> ignore

                configurationAction <- Some action
                priorValues <- previous

            try
                let deploymentId = Guid.NewGuid()

                let! prepared =
                    task {
                        try
                            return!
                                this.PrepareComponents(
                                    deploymentId,
                                    sources.Stamp,
                                    components,
                                    ignore,
                                    token,
                                    retainedProfile = retained
                                )
                        with ModConductor.DeploymentRecovery.RecoveryException error ->
                            return
                                fail (
                                    match error with
                                    | ModConductor.DeploymentRecovery.RecoveryError.InvalidPlan ->
                                        "The ENB component generation was not a valid deployment plan."
                                    | ModConductor.DeploymentRecovery.RecoveryError.Stale ->
                                        "The profile changed while the ENB generation was prepared."
                                    | ModConductor.DeploymentRecovery.RecoveryError.Busy ->
                                        "Another deployment is using this profile."
                                    | ModConductor.DeploymentRecovery.RecoveryError.NotFound ->
                                        "The profile deployment is unavailable."
                                    | ModConductor.DeploymentRecovery.RecoveryError.Limit ->
                                        "The ENB generation exceeds a deployment limit."
                                    | ModConductor.DeploymentRecovery.RecoveryError.Mismatch detail
                                    | ModConductor.DeploymentRecovery.RecoveryError.Unavailable detail
                                    | ModConductor.DeploymentRecovery.RecoveryError.Corrupt detail ->
                                        detail
                                )
                    }

                let generation = prepared.Switch.Generation.Id

                let runtimeName =
                    evidence.Proton |> Option.map _.RuntimeName |> Option.defaultValue "Windows"

                let previousPresent =
                    priorValues
                    |> Map.toList
                    |> List.choose (fun (key, value) -> value |> Option.map (fun item -> key, item))
                    |> Map.ofList

                let launch =
                    ModConductor.Enb.EnbSetupPlanning.runtime
                        generation
                        evidence.Executable.Value.Sha256
                        runtimeName
                        row.DllOverrides
                        previousPresent
                    |> ModConductor.Enb.EnbSetupPlanning.validate
                    |> Result.defaultWith (ModConductor.Enb.EnbProblem.message >> fail)

                let previousText =
                    if priorValues.IsEmpty then
                        previousConfiguration |> Option.map fst |> Option.defaultValue ""
                    else
                        priorValues
                        |> Map.toList
                        |> List.map (fun ((file, section, key), value) ->
                            String.concat
                                "|"
                                [ file; section; key; value |> Option.defaultValue "<missing>" ])
                        |> String.concat "\n"

                do! enbSetups.SaveGeneration(workspace, profile, generation, records)

                do!
                    enbSetups.SaveLaunchPlan(
                        workspace,
                        profile,
                        generation,
                        launch.GameSha256,
                        row.Runtime.Version,
                        row.Preset.Version,
                        records |> List.find (fun value -> value.Kind = "runtime") |> _.Sha256,
                        records |> List.find (fun value -> value.Kind = "preset") |> _.Sha256,
                        records
                        |> List.filter (fun value -> value.Kind.StartsWith("companion:"))
                        |> List.map (fun value -> value.Kind + ":" + value.Sha256)
                        |> String.concat ";",
                        row.DllOverrides,
                        runtimeName,
                        previousText,
                        configurationAction
                    )

                do!
                    enbSetups.StageSelection(
                        deploymentId,
                        workspace,
                        profile,
                        sources.Profile.Revision,
                        desired
                    )

                let! receipt = generations.Start(prepared, [], cancellation = token)

                let receipt =
                    receipt
                    |> Result.defaultWith (fun _ -> fail "The ENB deployment could not start.")

                let! completed =
                    generations.Run(
                        receipt.Id,
                        receipt.Revision,
                        false,
                        token,
                        defaultArg enbCheckpoint (fun _ _ -> ()),
                        []
                    )

                match completed with
                | Ok value -> return value.Proposed
                | Error _ ->
                    let! pending = deployment.Read(receipt.Id)

                    match pending with
                    | Some pending ->
                        let! _ =
                            generations.Run(
                                pending.Id,
                                pending.Revision,
                                true,
                                Threading.CancellationToken.None,
                                (fun _ _ -> ()),
                                []
                            )

                        ()
                    | None -> ()

                    return
                        fail "The ENB deployment did not complete. The previous setup was restored."
            with error ->
                if previousAction.IsNone then
                    let prior =
                        priorValues
                        |> Map.toList
                        |> List.map (fun ((_, _, key), value) -> key, value)
                        |> Map.ofList

                    let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData
                    let! state = profiles.Read(workspace, profile)

                    match state with
                    | Ok state ->
                        let! document =
                            profiles.ReadConfiguration(
                                state.Reference,
                                "SkyrimPrefs.ini",
                                Threading.CancellationToken.None
                            )

                        match document with
                        | Ok document ->
                            let content =
                                ModConductor.Enb.EnbSetupPlanning.restoreSkyrimPrefs
                                    document.Document.Content
                                    prior

                            let! _ =
                                profiles.SaveConfiguration(
                                    { Id = Guid.NewGuid()
                                      PreviewId = document.PreviewId
                                      Expected = document.Expected
                                      Name = document.Name
                                      Content = content },
                                    ignore,
                                    Threading.CancellationToken.None
                                )

                            ()
                        | Error _ -> ()
                    | Error _ -> ()

                return raise error
        }

    member internal this.RemoveEnb
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
            let fail detail = raise (IO.IOException detail)

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let active = existing |> Option.bind _.Active
            let! components = enbSetups.Components(workspace, profile, active)

            if components.IsEmpty then
                return active
            else
                let removed = components |> List.map (fun value -> value.ModId, false)

                let staged =
                    sources.Profile.Mods
                    |> List.map (fun selected ->
                        if
                            components |> List.exists (fun value -> value.ModId = selected.ModId)
                        then
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
                    enbSetups.StageSelection(
                        deploymentId,
                        workspace,
                        profile,
                        sources.Profile.Revision,
                        removed
                    )

                let! started = generations.Start(prepared, [], cancellation = token)

                let receipt =
                    started |> Result.defaultWith (fun _ -> fail "ENB removal could not start.")

                let! result =
                    generations.Run(receipt.Id, receipt.Revision, false, token, (fun _ _ -> ()), [])

                let completed =
                    result
                    |> Result.defaultWith (fun _ -> fail "ENB removal needs deployment recovery.")

                let! configuration = enbSetups.ConfigurationPlan(workspace, profile, active)

                match configuration with
                | Some(previous, _) when not (String.IsNullOrWhiteSpace previous) ->
                    let prior =
                        previous.Split('\n', StringSplitOptions.RemoveEmptyEntries)
                        |> Array.choose (fun line ->
                            match line.Split('|') with
                            | [| _; _; key; "<missing>" |] -> Some(key, None)
                            | [| _; _; key; value |] -> Some(key, Some value)
                            | _ -> None)
                        |> Map.ofArray

                    let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData
                    let! state = profiles.Read(workspace, profile)

                    let state =
                        state
                        |> Result.defaultWith (fun _ ->
                            fail "The previous Skyrim settings could not be read.")

                    let! document =
                        profiles.ReadConfiguration(state.Reference, "SkyrimPrefs.ini", token)

                    let document =
                        document
                        |> Result.defaultWith (fun _ ->
                            fail "The previous Skyrim settings could not be read.")

                    let restoredContent =
                        ModConductor.Enb.EnbSetupPlanning.restoreSkyrimPrefs
                            document.Document.Content
                            prior

                    let! restored =
                        profiles.SaveConfiguration(
                            { Id = Guid.NewGuid()
                              PreviewId = document.PreviewId
                              Expected = document.Expected
                              Name = document.Name
                              Content = restoredContent },
                            ignore,
                            token
                        )

                    restored
                    |> Result.defaultWith (fun _ ->
                        fail
                            "ENB files were removed, but the previous Skyrim settings still need recovery.")
                    |> ignore
                | None -> ()
                | Some _ -> ()

                return Some completed.Proposed
        }

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
