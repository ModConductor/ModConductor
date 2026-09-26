namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal SkseWorkflow
    (
        database: StateDatabase,
        componentInstaller: SkseComponentInstaller,
        gameContexts: GameContextStore,
        deploymentRepository: DeploymentBackendRepository,
        skseLoaders: SkseLoaderStore,
        generations: DeploymentGenerationStore,
        deployment: ModConductor.DeploymentRecovery.Recovery,
        prepareComponents:
            (Guid *
            ModConductor.FilePlanning.SourceStamp *
            ModConductor.DeploymentPlanning.ReviewedComponent list *
            (ModConductor.Deployment.DeploymentProgress -> unit) *
            Threading.CancellationToken *
            ModConductor.DeploymentRecovery.SavedProfile option
                -> Threading.Tasks.Task<ModConductor.Deployment.PreparedState>),
        skseCheckpoint: string -> int -> unit
    ) =
    let checkedComponent
        (workspace: Guid)
        (profile: Guid)
        (release: ModConductor.Skse.SkseRelease)
        (modId: Guid)
        (version: ModConductor.ModLibrary.ModVersion)
        (componentFiles: ModConductor.DeploymentPlanning.ComponentFile list)
        =
        task {
            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

            match contextResult |> Result.toOption |> Option.bind _.Binding with
            | None -> return Error "The checked Skyrim installation is unavailable."
            | Some binding ->
                let evidence = binding.Evidence

                let currentRuntime =
                    match Version.TryParse evidence.Executable.Value.FileVersion with
                    | true, value -> Some value
                    | _ -> None

                if currentRuntime <> Some release.RuntimeVersion then
                    return Error "Skyrim changed after the compatibility check. Check SKSE again."
                else
                    match
                        ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence
                    with
                    | Error detail -> return Error detail
                    | Ok gameRoot ->
                        let reviewedComponent =
                            ModConductor.DeploymentPlanning.ComponentManifests.review
                                workspace
                                gameRoot
                                ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                { ModId = modId
                                  Version = version
                                  Priority = 0
                                  Files = componentFiles }

                        return
                            reviewedComponent
                            |> Result.mapError (fun _ ->
                                "The reviewed SKSE component no longer matches the installed archive.")
                            |> Result.map (fun reviewed -> evidence, reviewed)
        }

    let replacementProfile (workspace: Guid) (profile: Guid) (modId: Guid) =
        task {
            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                return Error "The profile deployment is unavailable."
            else
                let! previousLoader =
                    skseLoaders.ReadStored(workspace, profile, existing |> Option.bind _.Active)

                let previousMod = previousLoader |> Option.map _.ModId

                let stagedMods =
                    sources.Profile.Mods
                    |> List.map (fun selected ->
                        if selected.ModId = modId then
                            { selected with Enabled = true }
                        elif previousMod = Some selected.ModId then
                            { selected with Enabled = false }
                        else
                            selected)

                if stagedMods |> List.exists (fun selected -> selected.ModId = modId) |> not then
                    return Error "The installed SKSE component is unavailable to this profile."
                else
                    let! profileName =
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

                    match profileName with
                    | None -> return Error "The selected profile is unavailable."
                    | Some profileName ->
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

                        return Ok(sources, previousMod, stagedProfile)
        }

    member internal _.InstallSkse
        (
            workspace: Guid,
            profile: Guid,
            release: ModConductor.Skse.SkseRelease,
            artifact: ModConductor.ArtifactLibrary.Artifact,
            sourceCheckedAt: DateTimeOffset,
            token: Threading.CancellationToken
        ) =
        task {
            let! preparation =
                task {
                    let! installed =
                        componentInstaller.Install(workspace, profile, release, artifact, token)

                    match installed with
                    | Error detail -> return Error detail
                    | Ok(artifact, modId, versionId, version, componentFiles, loader) ->
                        let! componentCheck =
                            checkedComponent workspace profile release modId version componentFiles

                        match componentCheck with
                        | Error detail -> return Error detail
                        | Ok(evidence, reviewedComponent) ->
                            let! replacement = replacementProfile workspace profile modId

                            return
                                replacement
                                |> Result.map (fun (sources, previousMod, stagedProfile) ->
                                    artifact,
                                    modId,
                                    versionId,
                                    loader,
                                    evidence,
                                    reviewedComponent,
                                    sources,
                                    previousMod,
                                    stagedProfile)
                }

            match preparation with
            | Error detail -> return Error detail
            | Ok(artifact,
                 modId,
                 versionId,
                 loader,
                 evidence,
                 reviewedComponent,
                 sources,
                 previousMod,
                 stagedProfile) ->
                let deploymentId = Guid.NewGuid()

                let! prepared =
                    prepareComponents (
                        deploymentId,
                        sources.Stamp,
                        [ reviewedComponent ],
                        ignore,
                        token,
                        Some stagedProfile
                    )

                do!
                    skseLoaders.StageReplacement(
                        deploymentId,
                        sources.Profile.Revision,
                        previousMod,
                        { Loader =
                            { GenerationId = prepared.Switch.Generation.Id
                              Executable = IO.Path.Combine(evidence.RootPath, loader)
                              ComponentVersion = string release.ComponentVersion
                              RuntimeVersion = string release.RuntimeVersion
                              GameSha256 = evidence.Executable.Value.Sha256 }
                          ModId = modId
                          VersionId = versionId
                          ArchiveSha256 = artifact.Sha256.Value
                          NexusModId = release.ModId
                          NexusFileId = release.File.Id
                          SourceCheckedAt = sourceCheckedAt },
                        workspace,
                        profile
                    )

                let! started = generations.Start(prepared, [], cancellation = token)

                match started with
                | Error _ ->
                    do! skseLoaders.RemoveReplacement deploymentId
                    return Error "The SKSE deployment could not start."
                | Ok receipt ->
                    let mutable checkpointCancelled = false

                    let checkpoint name index =
                        try
                            skseCheckpoint name index
                        with :? OperationCanceledException as error ->
                            checkpointCancelled <- true
                            raise error

                    let! completed =
                        generations.Run(receipt.Id, receipt.Revision, false, token, checkpoint, [])

                    match completed with
                    | Ok value -> return Ok value.Proposed
                    | Error _ ->
                        let! pending = deployment.Read(receipt.Id)

                        match pending with
                        | Some pending ->
                            let! restored =
                                generations.Run(
                                    pending.Id,
                                    pending.Revision,
                                    true,
                                    Threading.CancellationToken.None,
                                    (fun _ _ -> ()),
                                    []
                                )

                            if Result.isError restored then
                                return
                                    Error "The failed SKSE replacement needs deployment recovery."
                            elif checkpointCancelled || token.IsCancellationRequested then
                                return
                                    raise (
                                        IO.IOException
                                            "The SKSE deployment did not complete. The previous setup was restored."
                                    )
                            else
                                return
                                    Error
                                        "The SKSE deployment did not complete. The previous setup was restored."
                        | None ->
                            if checkpointCancelled || token.IsCancellationRequested then
                                return
                                    raise (
                                        IO.IOException
                                            "The SKSE deployment did not complete. The previous setup was restored."
                                    )
                            else
                                return
                                    Error
                                        "The SKSE deployment did not complete. The previous setup was restored."
        }

    member internal _.RemoveSkse
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                return Error "The profile deployment is unavailable."
            else
                let active = existing |> Option.bind _.Active
                let! loader = skseLoaders.ReadStored(workspace, profile, active)

                match loader with
                | None -> return Ok active
                | Some loader ->
                    let staged =
                        sources.Profile.Mods
                        |> List.map (fun selected ->
                            if selected.ModId = loader.ModId then
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
                            | :? string as value -> Some value
                            | _ -> None)

                    match profileName with
                    | None -> return Error "The selected profile is unavailable."
                    | Some profileName ->
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
                            prepareComponents (
                                deploymentId,
                                sources.Stamp,
                                [],
                                ignore,
                                token,
                                Some retained
                            )

                        let! started = generations.Start(prepared, [], cancellation = token)

                        match started with
                        | Error _ -> return Error "SKSE removal could not start."
                        | Ok receipt ->
                            let! completed =
                                generations.Run(
                                    receipt.Id,
                                    receipt.Revision,
                                    false,
                                    token,
                                    (fun _ _ -> ()),
                                    []
                                )

                            match completed with
                            | Ok value -> return Ok(Some value.Proposed)
                            | Error _ when token.IsCancellationRequested ->
                                return invalidOp "SKSE removal needs deployment recovery."
                            | Error _ -> return Error "SKSE removal needs deployment recovery."
        }
