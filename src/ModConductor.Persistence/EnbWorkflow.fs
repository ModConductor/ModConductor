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
    let cancelledGeneration =
        function
        | ModConductor.DeploymentRecovery.RecoveryError.Unavailable detail ->
            detail = "Deployment preparation was cancelled."
            || detail = "Generation preparation was cancelled."
            || detail = "The operation stopped at a recorded boundary."
        | _ -> false

    member private _.PrepareEnbTarget(workspace, profile, token) =
        task {
            let! contextResult =
                (gameContexts :> ModConductor.GameContexts.IGameContexts).Read(workspace, profile)

            match contextResult |> Result.toOption |> Option.bind _.Binding with
            | None -> return Error "The checked Skyrim installation is unavailable."
            | Some binding ->
                let evidence = binding.Evidence

                match ModConductor.GameContexts.ComponentRoots.gameRootId workspace evidence with
                | Error detail -> return Error detail
                | Ok gameRoot ->
                    let! sources, existing =
                        (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read
                            profile

                    if sources.Stamp.WorkspaceId <> workspace then
                        return Error "The profile deployment is unavailable."
                    else
                        let active = existing |> Option.bind _.Active
                        let! owner = enbSetups.Owner(workspace, active)

                        if owner |> Option.exists ((<>) profile) then
                            return
                                Error
                                    "Another profile owns the active renderer targets. Remove its ENB setup first."
                        else
                            let! priorComponents = enbSetups.Components(workspace, profile, active)

                            let conflict =
                                if priorComponents.IsEmpty then
                                    [ "d3d11.dll"
                                      "d3dcompiler_46e.dll"
                                      "dxgi.dll"
                                      IO.Path.Combine(
                                          "Data",
                                          "SKSE",
                                          "Plugins",
                                          "CommunityShaders.dll"
                                      ) ]
                                    |> List.tryFind (fun name ->
                                        IO.File.Exists(IO.Path.Combine(evidence.RootPath, name)))
                                else
                                    None

                            match conflict with
                            | Some name ->
                                return
                                    Error(
                                        ModConductor.Enb.EnbProblem.message (
                                            ModConductor.Enb.EnbProblem.ForeignDllConflict name
                                        )
                                    )
                            | None ->
                                let profiles =
                                    profileGameData :> ModConductor.ProfileGameData.IProfileGameData

                                let! profileState = profiles.Read(workspace, profile)

                                match profileState with
                                | Error problem -> return Error(EnbProfile.error problem)
                                | Ok profileState ->
                                    if
                                        profileState.Options.Settings
                                        && profileState.SettingsInitialized
                                    then
                                        return Ok(gameRoot, evidence, active, priorComponents)
                                    else
                                        let! initialized =
                                            profiles.Edit(
                                                { Id = Guid.NewGuid()
                                                  Expected = profileState.Reference
                                                  Options =
                                                    { profileState.Options with
                                                        Settings = true }
                                                  InitialSaves =
                                                    ModConductor.ProfileGameData.InitialSaves.Empty
                                                  DisabledFiles =
                                                    ModConductor.ProfileGameData.DisabledFiles.Keep },
                                                ignore,
                                                token
                                            )

                                        match initialized with
                                        | Error problem -> return Error(EnbProfile.error problem)
                                        | Ok initialized when not initialized.Complete ->
                                            return
                                                Error(
                                                    initialized.Problem
                                                    |> Option.defaultValue
                                                        "The profile settings could not be initialized."
                                                )
                                        | Ok _ ->
                                            return Ok(gameRoot, evidence, active, priorComponents)
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
            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository)
                    .Read(profile)

            if
                sources.Stamp.WorkspaceId <> workspace
                || (existing |> Option.bind _.Active) <> active
            then
                return Error "The profile deployment changed while ENB components were installed."
            else
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
                    return Error "An installed ENB component is unavailable to this profile."
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

                        return Ok(sources, desired, retained)
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
            let! target = this.PrepareEnbTarget(workspace, profile, token)

            match target with
            | Error detail -> return Error detail
            | Ok(gameRoot, evidence, active, priorComponents) ->
                let install pin fileId artifact =
                    componentInstaller.Install(workspace, gameRoot, pin, fileId, artifact, token)

                let! runtime = install row.Runtime None runtimeArtifact

                match runtime with
                | Error detail -> return Error detail
                | Ok runtime ->
                    let mutable installed = Ok [ runtime ]

                    for pin, file, artifact in acquired do
                        if Result.isOk installed then
                            let! value = install pin (Some file.Id) artifact

                            installed <-
                                match installed, value with
                                | Ok values, Ok value -> Ok(values @ [ value ])
                                | _, Error detail -> Error detail
                                | Error detail, _ -> Error detail

                    match installed with
                    | Error detail -> return Error detail
                    | Ok installed ->
                        let components = installed |> List.map fst

                        let records =
                            (installed |> List.map snd)
                            @ (if runtimeOnly then
                                   priorComponents
                                   |> List.filter (fun value -> value.Kind <> "runtime")
                               else
                                   [])

                        let! selection =
                            this.PrepareEnbSelection(
                                workspace,
                                profile,
                                active,
                                records,
                                priorComponents
                            )

                        match selection with
                        | Error detail -> return Error detail
                        | Ok(sources, desired, retained) ->
                            let deploymentId = Guid.NewGuid()

                            let! previousConfiguration =
                                enbSetups.ConfigurationPlan(workspace, profile, active)

                            let previousAction = previousConfiguration |> Option.bind snd
                            let mutable configurationStaged = false

                            try
                                let! outcome =
                                    task {
                                        let! staged =
                                            configuration.StageEnbConfiguration(
                                                workspace,
                                                profile,
                                                active,
                                                deploymentId,
                                                previousAction,
                                                (fun () -> configurationStaged <- true),
                                                token
                                            )

                                        match staged with
                                        | Error detail -> return Error detail
                                        | Ok(priorValues, configurationAction) ->
                                            let! prepared =
                                                task {
                                                    try
                                                        let! prepared =
                                                            prepareComponents (
                                                                deploymentId,
                                                                sources.Stamp,
                                                                components,
                                                                ignore,
                                                                token,
                                                                Some retained
                                                            )

                                                        return Ok prepared
                                                    with ModConductor.DeploymentRecovery.RecoveryException error ->
                                                        return
                                                            Error(
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

                                            match prepared with
                                            | Error detail -> return Error detail
                                            | Ok prepared ->
                                                let generation = prepared.Switch.Generation.Id

                                                let runtimeName =
                                                    evidence.Proton
                                                    |> Option.map _.RuntimeName
                                                    |> Option.defaultValue "Windows"

                                                let previousPresent =
                                                    priorValues
                                                    |> Map.toList
                                                    |> List.choose (fun (key, value) ->
                                                        value |> Option.map (fun item -> key, item))
                                                    |> Map.ofList

                                                let launch =
                                                    ModConductor.Enb.EnbSetupPlanning.runtime
                                                        generation
                                                        evidence.Executable.Value.Sha256
                                                        runtimeName
                                                        row.DllOverrides
                                                        previousPresent
                                                    |> ModConductor.Enb.EnbSetupPlanning.validate

                                                match launch with
                                                | Error problem ->
                                                    return
                                                        Error(
                                                            ModConductor.Enb.EnbProblem.message
                                                                problem
                                                        )
                                                | Ok launch ->
                                                    let previousText =
                                                        if priorValues.IsEmpty then
                                                            previousConfiguration
                                                            |> Option.map fst
                                                            |> Option.defaultValue ""
                                                        else
                                                            EnbConfigurationEncoding.values
                                                                priorValues

                                                    do!
                                                        enbSetups.SaveGeneration(
                                                            workspace,
                                                            profile,
                                                            generation,
                                                            records
                                                        )

                                                    let preset =
                                                        records
                                                        |> List.tryFind (fun value ->
                                                            value.Kind = "preset")

                                                    do!
                                                        enbSetups.SaveLaunchPlan(
                                                            workspace,
                                                            profile,
                                                            generation,
                                                            launch.GameSha256,
                                                            row.Runtime.Version,
                                                            (preset |> Option.map _.Version),
                                                            records
                                                            |> List.find (fun value ->
                                                                value.Kind = "runtime")
                                                            |> _.Sha256,
                                                            (preset |> Option.map _.Sha256),
                                                            records
                                                            |> List.filter (fun value ->
                                                                value.Kind.StartsWith("companion:"))
                                                            |> List.map (fun value ->
                                                                value.Kind + ":" + value.Sha256)
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

                                                    let! started =
                                                        generations.Start(
                                                            prepared,
                                                            [],
                                                            cancellation = token
                                                        )

                                                    match started with
                                                    | Error _ ->
                                                        return
                                                            Error
                                                                "The ENB deployment could not start."
                                                    | Ok receipt ->
                                                        let! completed =
                                                            generations.Run(
                                                                receipt.Id,
                                                                receipt.Revision,
                                                                false,
                                                                token,
                                                                enbCheckpoint,
                                                                []
                                                            )

                                                        match completed with
                                                        | Ok value ->
                                                            if configurationStaged then
                                                                do!
                                                                    enbSetups.RemoveConfiguration
                                                                        deploymentId

                                                            return Ok value.Proposed
                                                        | Error failure ->
                                                            let! pending =
                                                                deployment.Read(receipt.Id)

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

                                                            if cancelledGeneration failure then
                                                                return
                                                                    raise (
                                                                        IO.IOException
                                                                            "The ENB deployment did not complete."
                                                                    )
                                                            else
                                                                return
                                                                    Error
                                                                        "The ENB deployment did not complete."
                                    }

                                match outcome with
                                | Ok generation -> return Ok generation
                                | Error detail ->
                                    let! restorationFailure =
                                        configuration.RestoreFailedEnbInstall(
                                            workspace,
                                            profile,
                                            deploymentId,
                                            configurationStaged,
                                            detail
                                        )

                                    return
                                        Error(
                                            match restorationFailure with
                                            | Some restoration -> detail + " " + restoration
                                            | None -> detail
                                        )
                            with error ->
                                let! restorationFailure =
                                    configuration.RestoreFailedEnbInstall(
                                        workspace,
                                        profile,
                                        deploymentId,
                                        configurationStaged,
                                        error.Message
                                    )

                                return
                                    match restorationFailure with
                                    | Some detail ->
                                        raise (IO.IOException(error.Message + " " + detail, error))
                                    | None -> raise error
        }

    member internal _.RemoveEnb
        (workspace: Guid, profile: Guid, token: Threading.CancellationToken, ?runtimeOnly: bool)
        =
        task {
            let runtimeOnly = defaultArg runtimeOnly false

            let! sources, existing =
                (deploymentRepository :> ModConductor.Deployment.IDeploymentRepository).Read profile

            if sources.Stamp.WorkspaceId <> workspace then
                return Error "The profile deployment is unavailable."
            else
                let active = existing |> Option.bind _.Active
                let! components = enbSetups.Components(workspace, profile, active)

                let selected =
                    if runtimeOnly then
                        components |> List.filter (fun value -> value.Kind = "runtime")
                    else
                        components

                if selected.IsEmpty then
                    return Ok active
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

                        let! configurationPlan =
                            enbSetups.ConfigurationPlan(workspace, profile, active)

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

                        match started with
                        | Error _ ->
                            do! enbSetups.RemoveSelection deploymentId
                            do! enbSetups.RemoveConfiguration deploymentId
                            return Error "ENB removal could not start."
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
                            | Error failure when cancelledGeneration failure ->
                                return
                                    raise (IO.IOException "ENB removal needs deployment recovery.")
                            | Error _ -> return Error "ENB removal needs deployment recovery."
                            | Ok completed ->
                                if runtimeOnly then
                                    do!
                                        enbSetups.SaveGeneration(
                                            workspace,
                                            profile,
                                            completed.Proposed,
                                            components
                                            |> List.filter (fun value -> value.Kind <> "runtime")
                                        )

                                do!
                                    enbSetups.UpdateConfiguration(
                                        deploymentId,
                                        "restore_pending",
                                        None,
                                        ""
                                    )

                                let! operation =
                                    enbSetups.ConfigurationOperation(workspace, profile)

                                let! restored =
                                    configuration.RestoreEnbConfiguration(operation.Value, token)

                                return restored |> Result.map (fun () -> Some completed.Proposed)
        }
