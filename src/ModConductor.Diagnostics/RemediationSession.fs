namespace ModConductor.Diagnostics

open System
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.Workspaces

type internal RemediationSession
    (plans: IFilePlans, deployments: IDeploymentBackend, context: DiagnosticContext) =
    let previewFile snapshotId findingId (snapshot: StoredSnapshot) (profile: Profile) plan copy =
        task {
            let! summary = plans.Read plan
            let! problems = plans.DiagnosticProblems plan

            match summary, problems with
            | Ok summary, Ok problems when
                summary.WorkspaceId = snapshot.View.WorkspaceId
                && summary.ProfileId = snapshot.View.ProfileId
                && problems |> List.exists (fun problem -> "mod-files:" + problem.Id = findingId)
                ->
                let problem =
                    problems |> List.find (fun problem -> "mod-files:" + problem.Id = findingId)

                match problem.Target with
                | None -> return Error DiagnosticError.NotOwned
                | Some target ->
                    let selectedSource =
                        problem.Sources |> List.tryFind (fun source -> source.Copy = copy)

                    let remainingName =
                        problem.Sources
                        |> List.tryFind (fun source -> source.Copy <> copy && not source.Hidden)
                        |> Option.map _.Name
                        |> Option.defaultValue "The remaining mod"

                    match selectedSource with
                    | None -> return Error DiagnosticError.NotOwned
                    | Some selectedSource ->
                        return
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
                            |> Ok
            | Error error, _ -> return Error(DiagnosticErrors.file error)
            | _, Error error -> return Error(DiagnosticErrors.file error)
            | _ -> return Error DiagnosticError.Foreign
        }

    let previewDeployment
        snapshotId
        findingId
        (snapshot: StoredSnapshot)
        (profile: Profile)
        receipt
        revision
        =
        task {
            let! qualified =
                context.QualifiedDeployment(
                    snapshot.View.WorkspaceId,
                    snapshot.View.ProfileId,
                    receipt,
                    revision
                )

            match qualified with
            | Error error -> return Error error
            | Ok _ ->
                let! value = deployments.PreviewRecovery(receipt, revision)

                match value with
                | Error error -> return Error(DiagnosticErrors.deployment error)
                | Ok value when value.WorkspaceId <> snapshot.View.WorkspaceId ->
                    return Error DiagnosticError.Foreign
                | Ok value when
                    value.Paths.Length > Limits.recoveryPaths
                    || Remediation.pathsBytes value.Paths > Limits.recoveryBytes
                    ->
                    return Error DiagnosticError.Oversized
                | Ok value ->
                    return
                        Remediation.deploymentPreview
                            snapshotId
                            findingId
                            snapshot.View.WorkspaceId
                            profile.Id
                            value
                            DateTimeOffset.UtcNow
                        |> Ok
        }

    member _.Preview(snapshotId, findingId, snapshot: StoredSnapshot) =
        task {
            let! current = context.CurrentWorkspace snapshot.Request

            match current with
            | Error error -> return Error error
            | Ok(_, profile) ->
                match
                    snapshot.View.Findings |> List.tryFind (fun value -> value.Id = findingId)
                with
                | None -> return Error DiagnosticError.NotFound
                | Some finding ->
                    match finding.Action with
                    | DiagnosticAction.HideFileCopy(plan, copy) ->
                        return! previewFile snapshotId findingId snapshot profile plan copy
                    | DiagnosticAction.RecoverDeployment(receipt, revision) ->
                        return!
                            previewDeployment snapshotId findingId snapshot profile receipt revision
                    | _ -> return Error DiagnosticError.Unsupported
        }

    member _.Apply(previewId, preview: StoredPreview, snapshot: StoredSnapshot, token) =
        task {
            let! current = context.CurrentWorkspace snapshot.Request

            match current with
            | Error error -> return Error error
            | Ok _ ->
                match preview.Command with
                | RemediationCommand.Hide(plan, copy, remainingName) ->
                    let! changed = plans.Change(plan, copy, true, token)

                    return
                        changed
                        |> Result.mapError DiagnosticErrors.file
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
                        context.QualifiedDeployment(
                            preview.View.WorkspaceId,
                            preview.View.ProfileId,
                            receipt,
                            revision
                        )

                    match qualified with
                    | Error error -> return Error error
                    | Ok _ ->
                        let! changed = deployments.Recover(receipt, revision, true, ignore, token)

                        return
                            changed
                            |> Result.mapError DiagnosticErrors.deployment
                            |> Result.map (fun _ ->
                                { PreviewId = previewId
                                  Complete = true
                                  Result = "Mod Conductor continued the deployment restore."
                                  Detail = None })
        }
