namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbInstallDeployment
    (
        enbSetups: EnbStore,
        configuration: EnbConfigurationWorkflow,
        generations: DeploymentGenerationStore,
        deployment: ModConductor.DeploymentRecovery.Recovery,
        prepareComponents: EnbPrepareComponents,
        enbCheckpoint: string -> int -> unit
    ) =
    member private _.PrepareGeneration
        (
            deploymentId,
            sources: ModConductor.FilePlanning.PlanSources,
            components: ModConductor.DeploymentPlanning.ReviewedComponent list,
            retained: ModConductor.DeploymentRecovery.SavedProfile,
            token
        ) =
        task {
            let describe =
                function
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
                | ModConductor.DeploymentRecovery.RecoveryError.Corrupt detail -> detail

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

                return prepared |> Result.mapError describe
            with ModConductor.DeploymentRecovery.RecoveryException error ->
                return Error(describe error)
        }

    member private _.StageLaunch
        (
            workspace: Guid,
            profile: Guid,
            row: ModConductor.Enb.EnbCompatibilityRow,
            evidence: ModConductor.GameContexts.InstallationEvidence,
            records: StoredEnbComponent list,
            sources: ModConductor.FilePlanning.PlanSources,
            desired: (Guid * bool) list,
            prepared: ModConductor.Deployment.PreparedState,
            previousConfiguration: (string * Guid option) option,
            priorValues: Map<string * string * string, string option>,
            configurationAction: Guid option,
            deploymentId: Guid
        ) =
        task {
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

            match launch with
            | Error problem -> return Error(ModConductor.Enb.EnbProblem.message problem)
            | Ok launch ->
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

                return Ok()
        }

    member private _.RunGeneration
        (
            prepared: ModConductor.Deployment.PreparedState,
            deploymentId: Guid,
            configurationStaged: bool,
            token: CancellationToken
        ) =
        task {
            let! started = generations.Start(prepared, [], cancellation = token)

            match started with
            | Error _ -> return Error "The ENB deployment could not start."
            | Ok receipt ->
                let mutable checkpointCancelled = false

                let checkpoint name index =
                    try
                        enbCheckpoint name index
                    with :? OperationCanceledException as error ->
                        checkpointCancelled <- true
                        raise error

                let! completed =
                    generations.Run(receipt.Id, receipt.Revision, false, token, checkpoint, [])

                match completed with
                | Ok value ->
                    if configurationStaged then
                        do! enbSetups.RemoveConfiguration deploymentId

                    return Ok value.Proposed
                | Error _ ->
                    let! pending = deployment.Read(receipt.Id)

                    match pending with
                    | Some pending ->
                        let! _ =
                            generations.Run(
                                pending.Id,
                                pending.Revision,
                                true,
                                CancellationToken.None,
                                (fun _ _ -> ()),
                                []
                            )

                        ()
                    | None -> ()

                    if checkpointCancelled || token.IsCancellationRequested then
                        return raise (IO.IOException "The ENB deployment did not complete.")
                    else
                        return Error "The ENB deployment did not complete."
        }

    member internal this.Publish
        (
            workspace: Guid,
            profile: Guid,
            row: ModConductor.Enb.EnbCompatibilityRow,
            evidence: ModConductor.GameContexts.InstallationEvidence,
            active: Guid option,
            records: StoredEnbComponent list,
            sources: ModConductor.FilePlanning.PlanSources,
            desired: (Guid * bool) list,
            retained: ModConductor.DeploymentRecovery.SavedProfile,
            components: ModConductor.DeploymentPlanning.ReviewedComponent list,
            token: CancellationToken
        ) =
        task {
            let deploymentId = Guid.NewGuid()
            let! previousConfiguration = enbSetups.ConfigurationPlan(workspace, profile, active)
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
                                this.PrepareGeneration(
                                    deploymentId,
                                    sources,
                                    components,
                                    retained,
                                    token
                                )

                            match prepared with
                            | Error detail -> return Error detail
                            | Ok prepared ->
                                let! launched =
                                    this.StageLaunch(
                                        workspace,
                                        profile,
                                        row,
                                        evidence,
                                        records,
                                        sources,
                                        desired,
                                        prepared,
                                        previousConfiguration,
                                        priorValues,
                                        configurationAction,
                                        deploymentId
                                    )

                                match launched with
                                | Error detail -> return Error detail
                                | Ok() ->
                                    return!
                                        this.RunGeneration(
                                            prepared,
                                            deploymentId,
                                            configurationStaged,
                                            token
                                        )
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
                    | Some detail -> raise (IO.IOException(error.Message + " " + detail, error))
                    | None -> raise error
        }
