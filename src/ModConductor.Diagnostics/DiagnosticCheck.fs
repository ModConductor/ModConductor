namespace ModConductor.Diagnostics

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Workspaces

type internal DiagnosticCheck
    (
        plans: IFilePlans,
        deployments: IDeploymentBackend,
        launches: IGameLaunching,
        profileData: IProfileGameData,
        pluginOrders: IProfilePluginOrders,
        context: DiagnosticContext,
        components: SkyrimComponentDiagnosticSource option,
        helperDiagnostic: (unit -> string option) option
    ) =
    let componentFindings
        (request: DiagnosticRequest)
        (workspace: Workspace)
        (profile: Profile)
        (launch: Result<GameLaunchState, ModConductor.Executables.ExecutableError>)
        (gameContext: (GameContextState * GameBinding) option)
        (token: CancellationToken)
        =
        task {
            let! componentState =
                match gameContext, components with
                | Some _, Some owner -> owner workspace.Id profile.Id token
                | _ ->
                    Task.FromResult
                        { Applicable = Set.empty
                          FnisOutput = None }

            let! skse =
                match gameContext with
                | Some(state, binding) when componentState.Applicable.Contains SkyrimComponent.Skse ->
                    FindingSources.skseFindings
                        plans
                        request
                        workspace
                        profile
                        launch
                        state
                        binding
                        token
                | _ -> Task.FromResult []

            let! oldForms =
                match gameContext, request.PluginSnapshotId with
                | Some(state, binding), Some snapshotId ->
                    FindingSources.oldFormFindings
                        pluginOrders
                        workspace
                        profile
                        state
                        binding
                        snapshotId
                | _ -> Task.FromResult(Ok [])

            return
                oldForms
                |> Result.map (fun oldForms ->
                    let fnis =
                        match gameContext with
                        | Some _ -> FindingSources.fnisFindings workspace profile componentState
                        | None -> []

                    skse, oldForms, fnis)
        }

    let deploymentFindings
        (workspace: Workspace)
        (profile: Profile)
        game
        (request: DiagnosticRequest)
        =
        task {
            match request.DeploymentReceipt with
            | None -> return Ok []
            | Some(id, revision) ->
                let! value = context.QualifiedDeployment(workspace.Id, profile.Id, id, revision)
                return value |> Result.map (Checks.deployment workspace profile game)
        }

    let checkSelected
        (request: DiagnosticRequest)
        (workspace: Workspace)
        (profile: Profile)
        (token: CancellationToken)
        =
        task {
            token.ThrowIfCancellationRequested()
            let! launch = launches.Read(request.WorkspaceId, request.ProfileId)

            let game =
                launch
                |> Result.toOption
                |> Option.map _.Name
                |> Option.defaultValue "Skyrim Special Edition"

            let launchFindings =
                launch
                |> Result.toOption
                |> Option.map (Checks.launch workspace profile)
                |> Option.defaultValue []

            let! gameContext = context.SupportedContext(workspace.Id, profile.Id)

            let! fileFindings =
                match request.FileSnapshotId with
                | None -> Task.FromResult(Ok [])
                | Some id -> FindingSources.fileFindings plans workspace profile id

            match fileFindings with
            | Error error -> return Error error
            | Ok fileFindings ->
                let! skyrim = componentFindings request workspace profile launch gameContext token

                match skyrim with
                | Error error -> return Error error
                | Ok(skseFindings, oldFormFindings, fnisFindings) ->
                    let! deployment = deploymentFindings workspace profile game request

                    match deployment with
                    | Error error -> return Error error
                    | Ok deploymentFindings ->
                        let! profileFindings =
                            FindingSources.profileFindings profileData workspace profile game

                        let helperFindings =
                            match gameContext with
                            | Some _ ->
                                FindingSources.helperFindings
                                    helperDiagnostic
                                    workspace
                                    profile
                                    game
                            | None -> []

                        token.ThrowIfCancellationRequested()

                        let findings =
                            (launchFindings
                             @ fileFindings
                             @ skseFindings
                             @ oldFormFindings
                             @ deploymentFindings
                             @ profileFindings
                             @ fnisFindings
                             @ helperFindings)
                            |> List.truncate Limits.findings

                        return
                            Ok
                                { Id = Guid.NewGuid()
                                  WorkspaceId = workspace.Id
                                  ProfileId = profile.Id
                                  CapturedAt = DateTimeOffset.UtcNow
                                  Findings = findings }
        }

    member _.Run(request: DiagnosticRequest, token: CancellationToken) =
        task {
            if request.WorkspaceId = Guid.Empty || request.ProfileId = Guid.Empty then
                return Error DiagnosticError.Foreign
            else
                let! current = context.CurrentWorkspace request

                match current with
                | Error error -> return Error error
                | Ok(workspace, profile) -> return! checkSelected request workspace profile token
        }
