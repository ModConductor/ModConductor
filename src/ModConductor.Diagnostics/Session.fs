namespace ModConductor.Diagnostics

open System
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.Operations
open ModConductor.ProfileGameData
open ModConductor.Workspaces

[<Struct>]
type private StoredSnapshot =
    { View: DiagnosticSnapshot
      Request: DiagnosticRequest }

/// Owns short-lived diagnostic and remediation views. Product owners remain the only writers.
type DiagnosticSession(
    workspaces: IWorkspaceState,
    plans: IFilePlans,
    deployments: IDeploymentBackend,
    launches: IGameLaunching,
    profileData: IProfileGameData,
    operations: IOperationStore
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
                            let! deploymentFindings =
                                match request.DeploymentReceipt with
                                | None -> Task.FromResult(Ok [])
                                | Some(id, revision) ->
                                    task {
                                        let! value = deployments.Receipt id
                                        return
                                            value
                                            |> Result.mapError mapDeploymentError
                                            |> Result.bind (fun receipt ->
                                                if receipt.WorkspaceId <> workspace.Id then Error DiagnosticError.Foreign
                                                elif receipt.Revision <> revision then Error DiagnosticError.Stale
                                                else Ok(Checks.deployment workspace profile game receipt))
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

                                let! operationFindings =
                                    match request.OperationId with
                                    | None -> Task.FromResult []
                                    | Some id ->
                                        task {
                                            let! value = operations.Get id
                                            return value |> Result.toOption |> Option.map (Checks.operation workspace profile game) |> Option.defaultValue []
                                        }

                                token.ThrowIfCancellationRequested()
                                let findings =
                                    (launchFindings @ fileFindings @ deploymentFindings @ profileFindings @ operationFindings)
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
                                        let remainingName =
                                            problem.Sources
                                            |> List.tryFind (fun source ->
                                                source.Copy <> copy && not source.Hidden)
                                            |> Option.map _.Name
                                            |> Option.defaultValue "The remaining mod"

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
                                                remainingName
                                                DateTimeOffset.UtcNow

                                        rememberPreview stored
                                        return Ok stored.View
                                | Error error, _ -> return Error(mapFileError error)
                                | _, Error error -> return Error(mapFileError error)
                                | _ -> return Error DiagnosticError.Foreign
                            | DiagnosticAction.RecoverDeployment(receipt, revision) ->
                                let! value = deployments.PreviewRecovery(receipt, revision)

                                match value with
                                | Error error -> return Error(mapDeploymentError error)
                                | Ok value when value.WorkspaceId <> snapshot.View.WorkspaceId -> return Error DiagnosticError.Foreign
                                | Ok value when value.Paths.Length > Limits.recoveryPaths || Remediation.pathsBytes value.Paths > Limits.recoveryBytes ->
                                    return Error DiagnosticError.Oversized
                                | Ok value ->
                                    let stored = Remediation.deploymentPreview snapshotId findingId snapshot.View.WorkspaceId profile.Id value DateTimeOffset.UtcNow
                                    rememberPreview stored
                                    return Ok stored.View
                            | _ -> return Error DiagnosticError.Unsupported
            }

        member _.Apply(previewId, actionId, token) =
            task {
                if actionId = Guid.Empty then return Error DiagnosticError.NotOwned
                else
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
                                    let! changed = deployments.Recover(receipt, revision, true, ignore, token)
                                    return
                                        changed
                                        |> Result.mapError mapDeploymentError
                                        |> Result.map (fun _ ->
                                            { PreviewId = previewId
                                              Complete = true
                                              Result = "Mod Conductor continued the deployment restore."
                                              Detail = None })
            }

        member _.Export(snapshotId, token) =
            task {
                token.ThrowIfCancellationRequested()
                match readSnapshot snapshotId with
                | None -> return Error DiagnosticError.Expired
                | Some snapshot -> return SupportExport.write snapshot.View
            }
