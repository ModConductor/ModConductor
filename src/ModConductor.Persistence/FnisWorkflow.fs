namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal FnisWorkflow
    (
        database: StateDatabase,
        componentInstaller: FnisComponentInstaller,
        gameContexts: GameContextStore,
        deploymentRepository: DeploymentBackendRepository,
        fnisSetups: FnisStore,
        generations: DeploymentGenerationStore,
        prepareComponents:
            (Guid *
            ModConductor.FilePlanning.SourceStamp *
            ModConductor.DeploymentPlanning.ReviewedComponent list *
            (ModConductor.Deployment.DeploymentProgress -> unit) *
            Threading.CancellationToken *
            ModConductor.DeploymentRecovery.SavedProfile option
                -> Threading.Tasks.Task<
                    Result<
                        ModConductor.Deployment.PreparedState,
                        ModConductor.DeploymentRecovery.RecoveryError
                     >
                 >),
        fnisCheckpoint: string -> int -> unit
    ) =
    let savedProfile
        (profile: Guid)
        (sources: ModConductor.FilePlanning.PlanSources)
        (mods: ModConductor.DeploymentPlanning.SelectedMod list)
        =
        task {
            let! name =
                database.Enqueue(fun () ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT name FROM profiles WHERE id=$id"
                            [ "$id", box (string profile) ]

                    match query.ExecuteScalar() with
                    | :? string as value -> Some value
                    | _ -> None)

            match name with
            | None -> return Error "The selected profile is unavailable."
            | Some name ->
                let retained: ModConductor.DeploymentRecovery.SavedProfile =
                    { Id = profile
                      Name = name
                      Revision = sources.Profile.Revision
                      Mods =
                        mods
                        |> List.map (fun selected ->
                            { ModId = selected.ModId
                              VersionId = selected.Version |> Option.map _.Id
                              Priority = selected.Priority
                              Enabled = selected.Enabled })
                      Hidden = sources.Hidden }

                return Ok retained
        }

    let checkedComponent workspace profile modId version componentFiles =
        task {
            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

            match contextResult |> Result.toOption |> Option.bind _.Binding with
            | None -> return Error "The checked Skyrim installation is unavailable."
            | Some binding ->
                let evidence = binding.Evidence

                if
                    evidence.DefinitionId <> ModConductor.GameContexts.Skyrim.definition.Id
                    || ModConductor.GameContexts.Skyrim.definition.Storefront <> "Steam"
                then
                    return Error "FNIS setup supports Skyrim Special Edition from Steam."
                else
                    match
                        ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence
                    with
                    | Error detail -> return Error detail
                    | Ok gameRoot ->
                        let reviewed =
                            ModConductor.DeploymentPlanning.ComponentManifests.review
                                workspace
                                gameRoot
                                ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                { ModId = modId
                                  Version = version
                                  Priority = 0
                                  Files = componentFiles }

                        return
                            reviewed
                            |> Result.mapError (fun _ ->
                                "The reviewed FNIS component no longer matches the installed archive.")
                            |> Result.map (fun reviewed -> evidence, reviewed)
        }

    member internal _.InstallFnis
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Fnis.FnisRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            token: Threading.CancellationToken
        ) =
        task {
            let! preparation =
                task {
                    let! installed = componentInstaller.Install(workspace, release, artifact, token)

                    match installed with
                    | Error detail -> return Error detail
                    | Ok(artifact, modId, versionId, version, plan) ->
                        let! componentCheck =
                            checkedComponent workspace profile modId version plan.ComponentFiles

                        match componentCheck with
                        | Error detail -> return Error detail
                        | Ok(evidence, reviewedComponent) ->
                            let! read =
                                (deploymentRepository
                                :> ModConductor.Deployment.IDeploymentRepository)
                                    .Read
                                    profile

                            match read with
                            | Error error ->
                                return Error(DeploymentPreparation.refusalMessage error)
                            | Ok(sources, existing) ->
                                if sources.Stamp.WorkspaceId <> workspace then
                                    return Error "The profile deployment is unavailable."
                                else
                                    let! previous =
                                        fnisSetups.ReadStored(
                                            workspace,
                                            profile,
                                            existing |> Option.bind _.Active
                                        )

                                    let previousMod = previous |> Option.map _.ModId

                                    let stagedMods =
                                        sources.Profile.Mods
                                        |> List.map (fun selected ->
                                            if selected.ModId = modId then
                                                { selected with Enabled = true }
                                            elif previousMod = Some selected.ModId then
                                                { selected with Enabled = false }
                                            else
                                                selected)

                                    if
                                        stagedMods
                                        |> List.exists (fun selected -> selected.ModId = modId)
                                        |> not
                                    then
                                        return
                                            Error
                                                "The installed FNIS component is unavailable to this profile."
                                    else
                                        let! retained = savedProfile profile sources stagedMods

                                        return
                                            retained
                                            |> Result.map (fun retained ->
                                                artifact,
                                                modId,
                                                versionId,
                                                plan,
                                                evidence,
                                                reviewedComponent,
                                                sources,
                                                previousMod,
                                                retained)
                }

            match preparation with
            | Error detail -> return Error detail
            | Ok(artifact,
                 modId,
                 versionId,
                 plan,
                 evidence,
                 reviewedComponent,
                 sources,
                 previousMod,
                 retained) ->
                let deploymentId = Guid.NewGuid()

                let! preparation =
                    prepareComponents (
                        deploymentId,
                        sources.Stamp,
                        [ reviewedComponent ],
                        ignore,
                        token,
                        Some retained
                    )

                match preparation with
                | Error error -> return Error(DeploymentPreparation.refusalMessage error)
                | Ok prepared ->
                    let generator: StoredFnisGenerator =
                        { GenerationId = prepared.Switch.Generation.Id
                          ModId = modId
                          VersionId = versionId
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

                    match started with
                    | Error _ ->
                        do! fnisSetups.RemoveIntent deploymentId
                        return Error "The FNIS deployment could not start."
                    | Ok receipt ->
                        let mutable checkpointCancelled = false

                        let checkpoint name index =
                            try
                                fnisCheckpoint name index
                            with :? OperationCanceledException as error ->
                                checkpointCancelled <- true
                                raise error

                        let! completed =
                            generations.Run(
                                receipt.Id,
                                receipt.Revision,
                                false,
                                token,
                                checkpoint,
                                []
                            )

                        match completed with
                        | Ok value -> return Ok value.Proposed
                        | Error _ when checkpointCancelled || token.IsCancellationRequested ->
                            return
                                raise (
                                    IO.IOException
                                        "The FNIS deployment did not complete. Recover the previous setup before retrying."
                                )
                        | Error _ ->
                            return
                                Error
                                    "The FNIS deployment did not complete. Recover the previous setup before retrying."
        }

    member internal _.RemoveFnis
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
            let! read =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            match read with
            | Error error -> return Error(DeploymentPreparation.refusalMessage error)
            | Ok(sources, existing) ->
                if sources.Stamp.WorkspaceId <> workspace then
                    return Error "The profile deployment is unavailable."
                else
                    let active = existing |> Option.bind _.Active
                    let! generator = fnisSetups.ReadStored(workspace, profile, active)

                    match generator with
                    | None -> return Ok active
                    | Some generator ->
                        let staged =
                            sources.Profile.Mods
                            |> List.map (fun selected ->
                                if selected.ModId = generator.ModId then
                                    { selected with Enabled = false }
                                else
                                    selected)

                        let! retained = savedProfile profile sources staged

                        match retained with
                        | Error detail -> return Error detail
                        | Ok retained ->
                            let deploymentId = Guid.NewGuid()

                            let! preparation =
                                prepareComponents (
                                    deploymentId,
                                    sources.Stamp,
                                    [],
                                    ignore,
                                    token,
                                    Some retained
                                )

                            match preparation with
                            | Error error ->
                                return Error(DeploymentPreparation.refusalMessage error)
                            | Ok prepared ->
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

                                match started with
                                | Error _ ->
                                    do! fnisSetups.RemoveIntent deploymentId
                                    return Error "FNIS removal could not start."
                                | Ok receipt ->
                                    let mutable checkpointCancelled = false

                                    let checkpoint name index =
                                        try
                                            fnisCheckpoint name index
                                        with :? OperationCanceledException as error ->
                                            checkpointCancelled <- true
                                            raise error

                                    let! completed =
                                        generations.Run(
                                            receipt.Id,
                                            receipt.Revision,
                                            false,
                                            token,
                                            checkpoint,
                                            []
                                        )

                                    match completed with
                                    | Ok value -> return Ok(Some value.Proposed)
                                    | Error _ when
                                        checkpointCancelled || token.IsCancellationRequested
                                        ->
                                        return
                                            raise (
                                                IO.IOException
                                                    "FNIS removal needs deployment recovery."
                                            )
                                    | Error _ ->
                                        return Error "FNIS removal needs deployment recovery."
        }
