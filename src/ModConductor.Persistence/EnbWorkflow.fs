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
        prepareComponents:
            (Guid *
            ModConductor.FilePlanning.SourceStamp *
            ModConductor.DeploymentPlanning.ReviewedComponent list *
            (ModConductor.Deployment.DeploymentProgress -> unit) *
            Threading.CancellationToken *
            ModConductor.DeploymentRecovery.SavedProfile option
                -> Threading.Tasks.Task<ModConductor.Deployment.PreparedState>),
        enbCheckpoint: string -> int -> unit
    ) =
    member private _.PrepareEnbTarget(workspace, profile, token) =
        task {
            let fail detail = raise (IO.IOException detail)

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

            let profiles = profileGameData :> ModConductor.ProfileGameData.IProfileGameData
            let! profileState = profiles.Read(workspace, profile)
            let profileState = profileState |> Result.defaultWith (EnbProfile.error >> fail)

            if not (profileState.Options.Settings && profileState.SettingsInitialized) then
                let! initialized =
                    profiles.Edit(
                        { Id = Guid.NewGuid()
                          Expected = profileState.Reference
                          Options =
                            { profileState.Options with
                                Settings = true }
                          InitialSaves = ModConductor.ProfileGameData.InitialSaves.Empty
                          DisabledFiles = ModConductor.ProfileGameData.DisabledFiles.Keep },
                        ignore,
                        token
                    )

                let initialized = initialized |> Result.defaultWith (EnbProfile.error >> fail)

                if not initialized.Complete then
                    fail (
                        initialized.Problem
                        |> Option.defaultValue "The profile settings could not be initialized."
                    )

            return gameRoot, evidence, active, priorComponents
        }

    member private _.PrepareEnbSelection
        (
            workspace,
            profile,
            active,
            records: StoredEnbComponent list,
            priorComponents: StoredEnbComponent list
        ) =
        task {
            let fail detail = raise (IO.IOException detail)

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

            return sources, desired, retained
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
            token: Threading.CancellationToken,
            ?runtimeOnly: bool
        ) =
        task {
            let runtimeOnly = defaultArg runtimeOnly false
            let fail detail = raise (IO.IOException detail)

            let! gameRoot, evidence, active, priorComponents =
                this.PrepareEnbTarget(workspace, profile, token)

            let install pin fileId artifact =
                componentInstaller.Install(workspace, gameRoot, pin, fileId, artifact, token)

            let! runtime = install row.Runtime None runtimeArtifact
            let mutable installed = [ runtime ]

            for pin, file, artifact in acquired do
                let! value = install pin (Some file.Id) artifact
                installed <- installed @ [ value ]

            let components = installed |> List.map fst

            let records =
                (installed |> List.map snd)
                @ (if runtimeOnly then
                       priorComponents |> List.filter (fun value -> value.Kind <> "runtime")
                   else
                       [])

            let! sources, desired, retained =
                this.PrepareEnbSelection(workspace, profile, active, records, priorComponents)

            let deploymentId = Guid.NewGuid()
            let! previousConfiguration = enbSetups.ConfigurationPlan(workspace, profile, active)
            let previousAction = previousConfiguration |> Option.bind snd
            let mutable configurationAction = previousAction
            let mutable priorValues = Map.empty
            let mutable configurationStaged = false

            try
                let! stagedPriorValues, stagedAction =
                    configuration.StageEnbConfiguration(
                        workspace,
                        profile,
                        active,
                        deploymentId,
                        previousAction,
                        (fun () -> configurationStaged <- true),
                        token
                    )

                priorValues <- stagedPriorValues
                configurationAction <- stagedAction

                let! prepared =
                    task {
                        try
                            return!
                                prepareComponents (
                                    deploymentId,
                                    sources.Stamp,
                                    components,
                                    ignore,
                                    token,
                                    Some retained
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
                        EnbConfigurationEncoding.values priorValues

                do! enbSetups.SaveGeneration(workspace, profile, generation, records)

                let preset = records |> List.tryFind (fun value -> value.Kind = "preset")

                do!
                    enbSetups.SaveLaunchPlan(
                        workspace,
                        profile,
                        generation,
                        launch.GameSha256,
                        row.Runtime.Version,
                        (preset |> Option.map _.Version),
                        records |> List.find (fun value -> value.Kind = "runtime") |> _.Sha256,
                        (preset |> Option.map _.Sha256),
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
                    generations.Run(receipt.Id, receipt.Revision, false, token, enbCheckpoint, [])

                match completed with
                | Ok value ->
                    if configurationStaged then
                        do! enbSetups.RemoveConfiguration deploymentId

                    return value.Proposed
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

                    return fail "The ENB deployment did not complete."
            with error ->
                let! restorationFailure =
                    configuration.RestoreFailedEnbInstall(
                        workspace,
                        profile,
                        deploymentId,
                        configurationStaged,
                        error
                    )

                return
                    match restorationFailure with
                    | Some detail -> raise (IO.IOException(error.Message + " " + detail, error))
                    | None -> raise error
        }

    member internal this.RemoveEnb
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken, ?runtimeOnly: bool)
        =
        task {
            let runtimeOnly = defaultArg runtimeOnly false
            let fail detail = raise (IO.IOException detail)

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                fail "The profile deployment is unavailable."

            let active = existing |> Option.bind _.Active
            let! components = enbSetups.Components(workspace, profile, active)

            let selected =
                if runtimeOnly then
                    components |> List.filter (fun value -> value.Kind = "runtime")
                else
                    components

            if selected.IsEmpty then
                return active
            else
                let removed = selected |> List.map (fun value -> value.ModId, false)

                let staged =
                    sources.Profile.Mods
                    |> List.map (fun selected ->
                        if removed |> List.exists (fun (id, _) -> id = selected.ModId) then
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
                    prepareComponents (
                        deploymentId,
                        sources.Stamp,
                        [],
                        ignore,
                        token,
                        Some retained
                    )

                let! configurationPlan = enbSetups.ConfigurationPlan(workspace, profile, active)
                let values = configurationPlan |> Option.map fst |> Option.defaultValue ""

                do!
                    enbSetups.StageConfiguration
                        { ReceiptId = deploymentId
                          WorkspaceId = workspace
                          ProfileId = profile
                          GenerationId = active
                          Kind = "remove"
                          Phase = "deployment_pending"
                          Values = values
                          ActionId = None
                          Detail = "" }

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
                    match started with
                    | Ok receipt -> receipt
                    | Error _ ->
                        enbSetups.RemoveSelection deploymentId
                        |> fun pending -> pending.GetAwaiter().GetResult()

                        enbSetups.RemoveConfiguration deploymentId
                        |> fun pending -> pending.GetAwaiter().GetResult()

                        fail "ENB removal could not start."

                let! result =
                    generations.Run(receipt.Id, receipt.Revision, false, token, (fun _ _ -> ()), [])

                let completed =
                    result
                    |> Result.defaultWith (fun _ -> fail "ENB removal needs deployment recovery.")

                if runtimeOnly then
                    do!
                        enbSetups.SaveGeneration(
                            workspace,
                            profile,
                            completed.Proposed,
                            components |> List.filter (fun value -> value.Kind <> "runtime")
                        )

                do! enbSetups.UpdateConfiguration(deploymentId, "restore_pending", None, "")

                let! operation = enbSetups.ConfigurationOperation(workspace, profile)
                let operation = operation |> Option.get
                let! restored = configuration.RestoreEnbConfiguration(operation, token)

                restored |> Result.defaultWith fail

                return Some completed.Proposed
        }
