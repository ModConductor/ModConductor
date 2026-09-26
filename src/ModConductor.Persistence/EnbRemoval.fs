namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks

type internal EnbRemoval
    (
        database: StateDatabase,
        deploymentRepository: DeploymentBackendRepository,
        enbSetups: EnbStore,
        configuration: EnbConfigurationWorkflow,
        generations: DeploymentGenerationStore,
        prepareComponents: EnbPrepareComponents
    ) =
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
                            | Error _ when token.IsCancellationRequested ->
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
