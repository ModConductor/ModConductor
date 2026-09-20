namespace ModConductor.Diagnostics

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Workspaces

[<Struct>]
type private StoredSnapshot =
    { View: DiagnosticSnapshot
      Request: DiagnosticRequest }

module internal DiagnosticAdmission =
    let tryBinding workspaceId capabilityId (state: GameContextState) =
        if state.WorkspaceId <> workspaceId then
            None
        else
            state.Binding
            |> Option.filter (fun binding ->
                binding.Evidence.Valid
                && not binding.NeedsCheck
                && (CapabilityPolicy.tryFind
                        binding.Evidence.DefinitionId
                        capabilityId
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
                game.ContextId = binding.Id
                && game.Request.ContextRevision = state.Revision
                ->
                Some run.RequestedAt
            | _ -> None)

/// Owns short-lived diagnostic and remediation views. Product owners remain the only writers.
type DiagnosticSession(
    workspaces: IWorkspaceState,
    plans: IFilePlans,
    deployments: IDeploymentBackend,
    launches: IGameLaunching,
    profileData: IProfileGameData,
    gameContexts: IGameContexts,
    pluginOrders: IProfilePluginOrders,
    ?fnis: FnisDiagnosticSource
) =
    let gate = obj ()
    let snapshots = Dictionary<Guid, StoredSnapshot>()
    let previews = Dictionary<Guid, StoredPreview>()

    let trim now =
        let expired =
            previews
            |> Seq.choose (fun entry -> if entry.Value.View.ExpiresAt <= now then Some entry.Key else None)
            |> Seq.toArray

        for id in expired do previews.Remove id |> ignore

    let removeOldestSnapshot () =
        if snapshots.Count >= Limits.previews then
            snapshots
            |> Seq.minBy (fun entry -> entry.Value.View.CapturedAt)
            |> _.Key
            |> snapshots.Remove
            |> ignore

    let removeOldestPreview () =
        if previews.Count >= Limits.previews then
            previews
            |> Seq.minBy (fun entry -> entry.Value.View.ExpiresAt)
            |> _.Key
            |> previews.Remove
            |> ignore

    let rememberSnapshot (view: DiagnosticSnapshot) (request: DiagnosticRequest) =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            removeOldestSnapshot ()
            snapshots[view.Id] <- { View = view; Request = request }
        )

    let readSnapshot (id: Guid): StoredSnapshot option =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            match snapshots.TryGetValue id with
            | true, value -> Some value
            | _ -> None)

    let rememberPreview (value: StoredPreview) =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            removeOldestPreview ()
            previews[value.View.Id] <- value
        )

    let claimPreview (id: Guid): StoredPreview option =
        lock gate (fun () ->
            trim DateTimeOffset.UtcNow
            match previews.TryGetValue id with
            | true, value ->
                previews.Remove id |> ignore
                Some value
            | _ -> None)

    let mapFileError =
        function
        | FilePlanError.Busy -> DiagnosticError.Busy
        | FilePlanError.Expired -> DiagnosticError.Expired
        | FilePlanError.Stale -> DiagnosticError.Stale
        | FilePlanError.Cancelled -> DiagnosticError.Cancelled
        | FilePlanError.InvalidCopy -> DiagnosticError.NotOwned
        | FilePlanError.LimitExceeded _ -> DiagnosticError.Oversized
        | FilePlanError.NotFound -> DiagnosticError.NotFound
        | _ -> DiagnosticError.Unsupported

    let mapProfileError =
        function
        | ProfileDataError.NotFound -> DiagnosticError.NotFound
        | ProfileDataError.Busy -> DiagnosticError.Busy
        | ProfileDataError.Stale -> DiagnosticError.Stale
        | ProfileDataError.Cancelled -> DiagnosticError.Cancelled
        | _ -> DiagnosticError.Unsupported

    let mapDeploymentError =
        function
        | DeploymentError.NotFound -> DiagnosticError.NotFound
        | DeploymentError.Busy -> DiagnosticError.Busy
        | DeploymentError.Stale -> DiagnosticError.Stale
        | DeploymentError.Cancelled -> DiagnosticError.Cancelled
        | _ -> DiagnosticError.Unsupported

    let currentWorkspace (request: DiagnosticRequest) =
        task {
            let! found = workspaces.Read(request.WorkspaceId, None)

            return
                match found with
                | Error _ -> Error DiagnosticError.NotFound
                | Ok page when page.Workspace.Id <> request.WorkspaceId -> Error DiagnosticError.Foreign
                | Ok page ->
                    match page.Workspace.SelectedProfile with
                    | Some profile when profile.Id = request.ProfileId -> Ok(page.Workspace, profile)
                    | _ -> Error DiagnosticError.Foreign
        }

    let qualifiedDeployment workspace profile receipt revision =
        task {
            let! status = deployments.Read profile

            match status with
            | Error error -> return Error(mapDeploymentError error)
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
                    |> Result.mapError mapDeploymentError
                    |> Result.bind (fun value ->
                        if value.WorkspaceId <> workspace then
                            Error DiagnosticError.Foreign
                        elif value.Revision <> revision then
                            Error DiagnosticError.Stale
                        else
                            Ok value)
        }

    let supportedContext workspace =
        task {
            let! context = gameContexts.Read workspace

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

    let fnisFindings (workspace: Workspace) (profile: Profile) token =
        task {
            match fnis with
            | None -> return []
            | Some owner ->
                let! result = owner workspace.Id profile.Id token

                return
                    match result with
                    | Some value when value.Stale ->
                        [ { Id = "fnis-output"
                            Code = "fnis-output-stale"
                            Severity = DiagnosticSeverity.Warning
                            WorkspaceId = workspace.Id
                            ProfileId = profile.Id
                            WorkspaceName = workspace.Name
                            ProfileName = profile.Name
                            GameName = "Skyrim Special Edition"
                            Title = value.Status
                            Summary = value.Detail
                            Detail = None
                            Area = "FNIS"
                            Evidence = [ { Label = "Input fingerprint"; Value = value.Fingerprint } ]
                            NextAction = "Run FNIS"
                            Fixability = Fixability.NotFixable
                            FixDetail = "Run FNIS from Skyrim setup or the Play check."
                            Correlations =
                                [ { Kind = CorrelationKind.Profile
                                    Id = profile.Id
                                    Revision = None } ]
                            Action = DiagnosticAction.None } ]
                    | _ -> []
        }

    let skseFindings
        (request: DiagnosticRequest)
        (workspace: Workspace)
        (profile: Profile)
        (launch: Result<GameLaunchState, ModConductor.Executables.ExecutableError>)
        (state: GameContextState)
        (binding: GameBinding)
        token
        =
        task {
            let log =
                match binding.Evidence.Locations.Documents with
                | Location.Located(documents, _) ->
                    let launchedAt =
                        DiagnosticAdmission.qualifiedLaunchTime
                            state
                            binding
                            launch

                    SkyrimChecks.readLog documents launchedAt token
                | Location.Unavailable _ ->
                    SkseLogResult.Malformed "The SKSE log folder is unavailable."

            let mutable owners = Map.empty

            match log, request.FileSnapshotId with
            | SkseLogResult.Current issues, Some snapshotId ->
                for issue in issues do
                    let target =
                        ModConductor.Platform.LogicalPath.create
                            [ "SKSE"; "Plugins"; issue.Name ]

                    match target with
                    | Error _ -> ()
                    | Ok target ->
                        let! inspected = plans.Inspect(snapshotId, target, None)

                        inspected
                        |> Result.toOption
                        |> Option.bind (fun value ->
                            value.Copies
                            |> List.tryFind (fun copy -> copy.Winner && copy.Enabled)
                            |> Option.bind (fun copy ->
                                match copy.Source with
                                | FilePreviewSource.ManagedCopy _ -> Some copy.Name
                                | _ -> None))
                        |> Option.iter (fun owner ->
                            owners <- owners.Add(issue.Name.ToLowerInvariant(), owner))
            | _ -> ()

            return
                Checks.skseLog
                    workspace
                    profile
                    binding.Id
                    state.Revision
                    log
                    owners
        }

    let oldFormFindings
        (workspace: Workspace)
        (profile: Profile)
        (state: GameContextState)
        (binding: GameBinding)
        snapshotId
        =
        task {
            let! order = pluginOrders.Read(workspace.Id, profile.Id, snapshotId)

            return
                order
                |> Result.mapError mapProfileError
                |> Result.bind (fun order ->
                    if
                        order.Reference.WorkspaceId <> workspace.Id
                        || order.Reference.ProfileId <> profile.Id
                        || order.Headers.Id <> snapshotId
                        || order.Headers.Stale
                    then
                        Error DiagnosticError.Foreign
                    else
                        SkyrimChecks.oldPluginFormats order.Headers order.View.Order.Entries
                        |> Checks.oldPluginFormats
                            workspace
                            profile
                            binding.Id
                            state.Revision
                            snapshotId
                        |> Ok)
        }

    interface IDiagnostics with
        member _.Check(request, token) =
            task {
                if request.WorkspaceId = Guid.Empty || request.ProfileId = Guid.Empty then
                    return Error DiagnosticError.Foreign
                else
                    let! current = currentWorkspace request

                    match current with
                    | Error error -> return Error error
                    | Ok(workspace, profile) ->
                        token.ThrowIfCancellationRequested()
                        let! launch = launches.Read(request.WorkspaceId, request.ProfileId)
                        let game = launch |> Result.toOption |> Option.map _.Name |> Option.defaultValue "Skyrim Special Edition"

                        let launchFindings =
                            launch
                            |> Result.toOption
                            |> Option.map (Checks.launch workspace profile)
                            |> Option.defaultValue []

                        let! gameContext = supportedContext workspace.Id

                        let! fileFindings =
                            match request.FileSnapshotId with
                            | None -> Task.FromResult(Ok [])
                            | Some id ->
                                task {
                                    let! summary = plans.Read id

                                    match summary with
                                    | Error error -> return Error(mapFileError error)
                                    | Ok summary when summary.WorkspaceId <> workspace.Id || summary.ProfileId <> profile.Id ->
                                        return Error DiagnosticError.Foreign
                                    | Ok summary ->
                                        let! problems = plans.DiagnosticProblems id
                                        return problems |> Result.map (Checks.fileProblems workspace profile summary) |> Result.mapError mapFileError
                                }

                        match fileFindings with
                        | Error error -> return Error error
                        | Ok fileFindings ->
                            let! skyrimFindings =
                                match gameContext with
                                | None -> Task.FromResult []
                                | Some(state, binding) ->
                                    skseFindings request workspace profile launch state binding token

                            let! oldForms =
                                match gameContext, request.PluginSnapshotId with
                                | Some(state, binding), Some snapshotId ->
                                    oldFormFindings workspace profile state binding snapshotId
                                | _ -> Task.FromResult(Ok [])

                            match oldForms with
                            | Error error -> return Error error
                            | Ok oldFormFindings ->
                                let! deploymentFindings =
                                    match request.DeploymentReceipt with
                                    | None -> Task.FromResult(Ok [])
                                    | Some(id, revision) ->
                                        task {
                                            let! value =
                                                qualifiedDeployment
                                                    workspace.Id
                                                    profile.Id
                                                    id
                                                    revision

                                            return value |> Result.map (Checks.deployment workspace profile game)
                                        }

                                match deploymentFindings with
                                | Error error -> return Error error
                                | Ok deploymentFindings ->
                                    let! profileFindings =
                                        task {
                                            let! value = profileData.Read(workspace.Id, profile.Id)
                                            return
                                                match value with
                                                | Ok state when state.WorkspaceId = workspace.Id && state.ProfileId = profile.Id -> Checks.profileData workspace profile game state
                                                | _ -> []
                                        }

                                    let! fnisOutputFindings = fnisFindings workspace profile token

                                    token.ThrowIfCancellationRequested()
                                    let findings =
                                        (launchFindings
                                         @ fileFindings
                                         @ skyrimFindings
                                         @ oldFormFindings
                                         @ deploymentFindings
                                         @ profileFindings
                                         @ fnisOutputFindings)
                                        |> List.truncate Limits.findings

                                    let view =
                                        { Id = Guid.NewGuid()
                                          WorkspaceId = workspace.Id
                                          ProfileId = profile.Id
                                          CapturedAt = DateTimeOffset.UtcNow
                                          Findings = findings }

                                    rememberSnapshot view request
                                    return Ok view
            }

        member _.Preview(snapshotId, findingId, token) =
            task {
                token.ThrowIfCancellationRequested()

                match readSnapshot snapshotId with
                | None -> return Error DiagnosticError.Expired
                | Some snapshot ->
                    let! current = currentWorkspace snapshot.Request

                    match current with
                    | Error error -> return Error error
                    | Ok(_, profile) ->
                        match snapshot.View.Findings |> List.tryFind (fun value -> value.Id = findingId) with
                        | None -> return Error DiagnosticError.NotFound
                        | Some finding ->
                            match finding.Action with
                            | DiagnosticAction.HideFileCopy(plan, copy) ->
                                let! summary = plans.Read plan
                                let! problems = plans.DiagnosticProblems plan

                                match summary, problems with
                                | Ok summary, Ok problems when
                                    summary.WorkspaceId = snapshot.View.WorkspaceId
                                    && summary.ProfileId = snapshot.View.ProfileId
                                    && problems |> List.exists (fun problem -> "mod-files:" + problem.Id = finding.Id)
                                    ->
                                    let problem = problems |> List.find (fun problem -> "mod-files:" + problem.Id = finding.Id)
                                    match problem.Target with
                                    | None -> return Error DiagnosticError.NotOwned
                                    | Some target ->
                                        let selectedSource =
                                            problem.Sources
                                            |> List.tryFind (fun source -> source.Copy = copy)

                                        let remainingName =
                                            problem.Sources
                                            |> List.tryFind (fun source ->
                                                source.Copy <> copy && not source.Hidden)
                                            |> Option.map _.Name
                                            |> Option.defaultValue "The remaining mod"

                                        match selectedSource with
                                        | None -> return Error DiagnosticError.NotOwned
                                        | Some selectedSource ->
                                            let stored =
                                                Remediation.filePreview
                                                    snapshotId
                                                    findingId
                                                    snapshot.View.WorkspaceId
                                                    profile.Id
                                                    profile.Name
                                                    target
                                                    plan
                                                    copy
                                                    selectedSource.Name
                                                    selectedSource.VersionLabel
                                                    remainingName
                                                    DateTimeOffset.UtcNow

                                            rememberPreview stored
                                            return Ok stored.View
                                | Error error, _ -> return Error(mapFileError error)
                                | _, Error error -> return Error(mapFileError error)
                                | _ -> return Error DiagnosticError.Foreign
                            | DiagnosticAction.RecoverDeployment(receipt, revision) ->
                                let! qualified =
                                    qualifiedDeployment
                                        snapshot.View.WorkspaceId
                                        snapshot.View.ProfileId
                                        receipt
                                        revision

                                match qualified with
                                | Error error -> return Error error
                                | Ok _ ->
                                    let! value = deployments.PreviewRecovery(receipt, revision)

                                    match value with
                                    | Error error -> return Error(mapDeploymentError error)
                                    | Ok value when value.WorkspaceId <> snapshot.View.WorkspaceId ->
                                        return Error DiagnosticError.Foreign
                                    | Ok value when
                                        value.Paths.Length > Limits.recoveryPaths
                                        || Remediation.pathsBytes value.Paths > Limits.recoveryBytes
                                        ->
                                        return Error DiagnosticError.Oversized
                                    | Ok value ->
                                        let stored =
                                            Remediation.deploymentPreview
                                                snapshotId
                                                findingId
                                                snapshot.View.WorkspaceId
                                                profile.Id
                                                value
                                                DateTimeOffset.UtcNow

                                        rememberPreview stored
                                        return Ok stored.View
                            | _ -> return Error DiagnosticError.Unsupported
            }

        member _.Apply(previewId, token) =
            task {
                match claimPreview previewId with
                | None -> return Error DiagnosticError.Expired
                | Some preview ->
                    match readSnapshot preview.View.SnapshotId with
                    | None -> return Error DiagnosticError.Expired
                    | Some snapshot ->
                        let! current = currentWorkspace snapshot.Request
                        match current with
                        | Error error -> return Error error
                        | Ok _ ->
                            match preview.Command with
                            | RemediationCommand.Hide(plan, copy, remainingName) ->
                                let! changed = plans.Change(plan, copy, true, token)
                                return
                                    changed
                                    |> Result.mapError mapFileError
                                    |> Result.map (fun _ ->
                                        { PreviewId = previewId
                                          Complete = true
                                          Result = "Mod Conductor updated the mod files"
                                          Detail =
                                            Some(
                                                remainingName
                                                + " now supplies this file in the saved mod files."
                                            ) })
                            | RemediationCommand.Recover(receipt, revision) ->
                                let! qualified =
                                    qualifiedDeployment
                                        preview.View.WorkspaceId
                                        preview.View.ProfileId
                                        receipt
                                        revision

                                match qualified with
                                | Error error -> return Error error
                                | Ok _ ->
                                    let! changed =
                                        deployments.Recover(receipt, revision, true, ignore, token)

                                    return
                                        changed
                                        |> Result.mapError mapDeploymentError
                                        |> Result.map (fun _ ->
                                            { PreviewId = previewId
                                              Complete = true
                                              Result =
                                                "Mod Conductor continued the deployment restore."
                                              Detail = None })
            }

        member _.Export(snapshotId, token) =
            task {
                token.ThrowIfCancellationRequested()
                match readSnapshot snapshotId with
                | None -> return Error DiagnosticError.Expired
                | Some snapshot -> return SupportExport.write snapshot.View
            }
