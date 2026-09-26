namespace ModConductor.Diagnostics

open System
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.GameLaunching
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal DiagnosticErrors =
    let file =
        function
        | FilePlanError.Busy -> DiagnosticError.Busy
        | FilePlanError.Expired -> DiagnosticError.Expired
        | FilePlanError.Stale -> DiagnosticError.Stale
        | FilePlanError.Cancelled -> DiagnosticError.Cancelled
        | FilePlanError.InvalidCopy -> DiagnosticError.NotOwned
        | FilePlanError.LimitExceeded _ -> DiagnosticError.Oversized
        | FilePlanError.NotFound -> DiagnosticError.NotFound
        | _ -> DiagnosticError.Unsupported

    let profile =
        function
        | ProfileDataError.NotFound -> DiagnosticError.NotFound
        | ProfileDataError.Busy -> DiagnosticError.Busy
        | ProfileDataError.Stale -> DiagnosticError.Stale
        | ProfileDataError.Cancelled -> DiagnosticError.Cancelled
        | _ -> DiagnosticError.Unsupported

    let deployment =
        function
        | DeploymentError.NotFound -> DiagnosticError.NotFound
        | DeploymentError.Busy -> DiagnosticError.Busy
        | DeploymentError.Stale -> DiagnosticError.Stale
        | DeploymentError.Cancelled -> DiagnosticError.Cancelled
        | _ -> DiagnosticError.Unsupported

module internal DiagnosticAdmission =
    let tryBinding workspaceId capabilityId (state: GameContextState) =
        if state.WorkspaceId <> workspaceId then
            None
        else
            state.Binding
            |> Option.filter (fun binding ->
                binding.Evidence.Valid
                && not binding.NeedsCheck
                && (CapabilityPolicy.tryFind binding.Evidence.DefinitionId capabilityId
                    |> Option.exists (fun capability ->
                        capability.Disposition = CapabilityDisposition.Available
                        && CapabilityPolicy.supports
                            binding.Evidence.DefinitionId
                            binding.Evidence.Platform
                            capability)))

    let qualifiedLaunchTime
        (state: GameContextState)
        (binding: GameBinding)
        (launch: Result<GameLaunchState, ModConductor.Executables.ExecutableError>)
        =
        launch
        |> Result.toOption
        |> Option.filter (fun value -> value.ContextRevision = state.Revision)
        |> Option.bind _.Latest
        |> Option.bind (fun run ->
            match run.Source with
            | ModConductor.Executables.RunSource.Game game when
                game.ContextId = binding.Id && game.Request.ContextRevision = state.Revision
                ->
                Some run.RequestedAt
            | _ -> None)

type internal DiagnosticContext
    (workspaces: IWorkspaceState, deployments: IDeploymentBackend, gameContexts: IGameContexts) =
    member _.CurrentWorkspace(request: DiagnosticRequest) =
        task {
            let! found = workspaces.Read(request.WorkspaceId, None)

            return
                match found with
                | Error _ -> Error DiagnosticError.NotFound
                | Ok page when page.Workspace.Id <> request.WorkspaceId ->
                    Error DiagnosticError.Foreign
                | Ok page ->
                    match page.Workspace.SelectedProfile with
                    | Some profile when profile.Id = request.ProfileId ->
                        Ok(page.Workspace, profile)
                    | _ -> Error DiagnosticError.Foreign
        }

    member _.QualifiedDeployment(workspace, profile, receipt, revision) =
        task {
            let! status = deployments.Read profile

            match status with
            | Error error -> return Error(DiagnosticErrors.deployment error)
            | Ok status when
                status.WorkspaceId <> workspace
                || status.Sources.ProfileId <> profile
                || status.PendingReceipt <> Some receipt
                ->
                return Error DiagnosticError.Foreign
            | Ok _ ->
                let! value = deployments.Receipt receipt

                return
                    value
                    |> Result.mapError DiagnosticErrors.deployment
                    |> Result.bind (fun value ->
                        if value.WorkspaceId <> workspace then
                            Error DiagnosticError.Foreign
                        elif value.Revision <> revision then
                            Error DiagnosticError.Stale
                        else
                            Ok value)
        }

    member _.SupportedContext(workspace, profile) =
        task {
            let! context = gameContexts.Read(workspace, profile)

            return
                context
                |> Result.toOption
                |> Option.bind (fun state ->
                    DiagnosticAdmission.tryBinding
                        workspace
                        CapabilityId.SkyrimSpecialEdition
                        state
                    |> Option.map (fun binding -> state, binding))
        }
