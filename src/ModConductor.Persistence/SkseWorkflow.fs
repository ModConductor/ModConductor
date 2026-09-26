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
            let fail detail = raise (IO.IOException detail)

            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

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
                    { ModId = modId
                      Version = version
                      Priority = 0
                      Files = componentFiles }
                |> Result.defaultWith (fun _ ->
                    fail "The reviewed SKSE component no longer matches the installed archive.")

            return evidence, reviewedComponent
        }

    let replacementProfile (workspace: Guid) (profile: Guid) (modId: Guid) =
        task {
            let fail detail = raise (IO.IOException detail)

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
                    if selected.ModId = modId then
                        { selected with Enabled = true }
                    elif previousMod = Some selected.ModId then
                        { selected with Enabled = false }
                    else
                        selected)

            if stagedMods |> List.exists (fun selected -> selected.ModId = modId) |> not then
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

            return sources, previousMod, stagedProfile
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
            let fail detail = raise (IO.IOException detail)

            let! artifact, modId, versionId, version, componentFiles, loader =
                componentInstaller.Install(workspace, profile, release, artifact, token)

            let! evidence, reviewedComponent =
                checkedComponent workspace profile release modId version componentFiles

            let! sources, previousMod, stagedProfile = replacementProfile workspace profile modId

            let deploymentId = Guid.NewGuid()

            let! prepared =
                (prepareComponents (
                    deploymentId,
                    sources.Stamp,
                    [ reviewedComponent ],
                    ignore,
                    token,
                    Some stagedProfile
                ))

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

            let! receipt = generations.Start(prepared, [], cancellation = token)

            let receipt =
                match receipt with
                | Ok value -> value
                | Error _ ->
                    skseLoaders.RemoveReplacement deploymentId
                    |> fun pending -> pending.GetAwaiter().GetResult()

                    fail "The SKSE deployment could not start."

            let! completed =
                generations.Run(receipt.Id, receipt.Revision, false, token, skseCheckpoint, [])

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

    member internal _.RemoveSkse
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                invalidOp "The profile deployment is unavailable."

            let active = existing |> Option.bind _.Active
            let! loader = skseLoaders.ReadStored(workspace, profile, active)

            match loader with
            | None -> return active
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
                        | :? string as value -> value
                        | _ -> invalidOp "The selected profile is unavailable.")

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

                let receipt =
                    started
                    |> Result.defaultWith (fun _ -> invalidOp "SKSE removal could not start.")

                let! completed =
                    generations.Run(receipt.Id, receipt.Revision, false, token, (fun _ _ -> ()), [])

                return
                    completed
                    |> Result.map (fun value -> Some value.Proposed)
                    |> Result.defaultWith (fun _ ->
                        invalidOp "SKSE removal needs deployment recovery.")
        }
