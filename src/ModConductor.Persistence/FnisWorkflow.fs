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
                -> Threading.Tasks.Task<ModConductor.Deployment.PreparedState>),
        fnisCheckpoint: string -> int -> unit
    ) =
    let fail detail = raise (IO.IOException detail)

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
                    | :? string as value -> value
                    | _ -> fail "The selected profile is unavailable.")

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

            return retained
        }

    let checkedComponent workspace profile modId version componentFiles =
        task {
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

            let reviewed =
                ModConductor.DeploymentPlanning.ComponentManifests.review
                    workspace
                    gameRoot
                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                    { ModId = modId
                      Version = version
                      Priority = 0
                      Files = componentFiles }
                |> Result.defaultWith (fun _ ->
                    fail "The reviewed FNIS component no longer matches the installed archive.")

            return evidence, reviewed
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
            let! artifact, modId, versionId, version, plan =
                componentInstaller.Install(workspace, release, artifact, token)

            let! evidence, reviewedComponent =
                checkedComponent workspace profile modId version plan.ComponentFiles

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
                    if selected.ModId = modId then
                        { selected with Enabled = true }
                    elif previousMod = Some selected.ModId then
                        { selected with Enabled = false }
                    else
                        selected)

            if stagedMods |> List.exists (fun selected -> selected.ModId = modId) |> not then
                fail "The installed FNIS component is unavailable to this profile."

            let! retained = savedProfile profile sources stagedMods

            let deploymentId = Guid.NewGuid()

            let! prepared =
                prepareComponents (
                    deploymentId,
                    sources.Stamp,
                    [ reviewedComponent ],
                    ignore,
                    token,
                    Some retained
                )

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

            let receipt =
                match started with
                | Ok value -> value
                | Error _ ->
                    fnisSetups.RemoveIntent deploymentId
                    |> fun pending -> pending.GetAwaiter().GetResult()

                    fail "The FNIS deployment could not start."

            let! completed =
                generations.Run(receipt.Id, receipt.Revision, false, token, fnisCheckpoint, [])

            match completed with
            | Ok value -> return value.Proposed
            | Error _ ->
                return
                    fail
                        "The FNIS deployment did not complete. Recover the previous setup before retrying."
        }

    member internal _.RemoveFnis
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken)
        =
        task {
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

                let! retained = savedProfile profile sources staged

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
                    generations.Run(receipt.Id, receipt.Revision, false, token, fnisCheckpoint, [])

                match completed with
                | Ok value -> return Some value.Proposed
                | Error _ -> return fail "FNIS removal needs deployment recovery."
        }
