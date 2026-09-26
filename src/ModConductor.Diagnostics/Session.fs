namespace ModConductor.Diagnostics

open System
open ModConductor.Deployment
open ModConductor.FilePlanning
open ModConductor.GameLaunching
open ModConductor.GameContexts
open ModConductor.ProfileGameData
open ModConductor.Workspaces

type DiagnosticSession
    (
        workspaces: IWorkspaceState,
        plans: IFilePlans,
        deployments: IDeploymentBackend,
        launches: IGameLaunching,
        profileData: IProfileGameData,
        gameContexts: IGameContexts,
        pluginOrders: IProfilePluginOrders,
        ?components: SkyrimComponentDiagnosticSource,
        ?helperDiagnostic: unit -> string option
    ) =
    let cache = SessionCache()
    let context = DiagnosticContext(workspaces, deployments, gameContexts)

    let checks =
        DiagnosticCheck(
            plans,
            deployments,
            launches,
            profileData,
            pluginOrders,
            context,
            components,
            helperDiagnostic
        )

    let remediation = RemediationSession(plans, deployments, context)

    interface IDiagnostics with
        member _.Check(request, token) =
            task {
                let! result = checks.Run(request, token)
                result |> Result.iter (fun view -> cache.RememberSnapshot(view, request))
                return result
            }

        member _.Preview(snapshotId, findingId, token) =
            task {
                token.ThrowIfCancellationRequested()

                match cache.ReadSnapshot snapshotId with
                | None -> return Error DiagnosticError.Expired
                | Some snapshot ->
                    let! preview = remediation.Preview(snapshotId, findingId, snapshot)
                    preview |> Result.iter cache.RememberPreview
                    return preview |> Result.map _.View
            }

        member _.Apply(previewId, token) =
            task {
                match cache.ClaimPreview previewId with
                | None -> return Error DiagnosticError.Expired
                | Some preview ->
                    match cache.ReadSnapshot preview.View.SnapshotId with
                    | None -> return Error DiagnosticError.Expired
                    | Some snapshot ->
                        return! remediation.Apply(previewId, preview, snapshot, token)
            }

        member _.Export(snapshotId, token) =
            task {
                token.ThrowIfCancellationRequested()

                match cache.ReadSnapshot snapshotId with
                | None -> return Error DiagnosticError.Expired
                | Some snapshot -> return SupportExport.write snapshot.View
            }
