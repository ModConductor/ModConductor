module ModConductor.Engine.DiagnosticComposition

open System.Threading
open System.Threading.Tasks
open ModConductor.Persistence

let private applicableComponents skseInstalled fnisInstalled enbInstalled =
    [ if skseInstalled then
          ModConductor.Diagnostics.SkyrimComponent.Skse
      if fnisInstalled then
          ModConductor.Diagnostics.SkyrimComponent.Fnis
      if enbInstalled then
          ModConductor.Diagnostics.SkyrimComponent.Enb ]
    |> Set.ofList

let private fnisDiagnostic (value: ModConductor.Fnis.FnisInspection) =
    let stale =
        match value.Phase with
        | ModConductor.Fnis.FnisOutputPhase.Missing
        | ModConductor.Fnis.FnisOutputPhase.Stale
        | ModConductor.Fnis.FnisOutputPhase.Running
        | ModConductor.Fnis.FnisOutputPhase.Failed
        | ModConductor.Fnis.FnisOutputPhase.Cancelled
        | ModConductor.Fnis.FnisOutputPhase.Abandoned -> true
        | _ -> false

    let diagnostic: ModConductor.Diagnostics.FnisDiagnosticState =
        { Stale = stale
          Status = value.Status
          Detail = value.Detail
          Fingerprint = value.Fingerprint }

    diagnostic

let private components (store: OperationStore) =
    (fun workspace profile (token: CancellationToken) ->
        task {
            token.ThrowIfCancellationRequested()
            let! deployment = store.Deployments.Read profile

            match deployment with
            | Ok state when state.WorkspaceId = workspace ->
                let! skse =
                    store.SkseLoaders.ReadStored(workspace, profile, state.ActiveGeneration)

                let! fnis = store.FnisSetups.ReadStored(workspace, profile, state.ActiveGeneration)

                let! enb =
                    (store.EnbSetups
                    :> ModConductor.GameLaunching.IComponentLaunchConfigurationSelection)
                        .Read(workspace, profile, state.ActiveGeneration)

                let applicable = applicableComponents skse.IsSome fnis.IsSome enb.IsSome

                let! output =
                    match state.ActiveGeneration, fnis with
                    | Some generation, Some _ ->
                        task {
                            let! inspected =
                                store.FnisExecution.Inspect(workspace, profile, generation)

                            return Result.toOption inspected
                        }
                    | _ -> Task.FromResult None

                token.ThrowIfCancellationRequested()

                let diagnostic = output |> Option.map fnisDiagnostic

                let result: ModConductor.Diagnostics.SkyrimComponentDiagnosticState =
                    { Applicable = applicable
                      FnisOutput = diagnostic }

                return result
            | _ ->
                let result: ModConductor.Diagnostics.SkyrimComponentDiagnosticState =
                    { Applicable = Set.empty
                      FnisOutput = None }

                return result
        })

let internal create (store: OperationStore) =
    ModConductor.Diagnostics.DiagnosticSession(
        store.Workspaces,
        store.FilePlans,
        store.Deployments,
        store.GameLaunching,
        store.ProfileGameData,
        store.GameContexts,
        store.PluginOrders,
        helperDiagnostic = store.Loot.HelperDiagnostic,
        components = components store
    )
