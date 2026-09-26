namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Deployment
open ModConductor.Fnis
open ModConductor.Persistence
open ModConductor.Protocol.V1
open SkyrimSetupViews

type internal SkyrimSetupPreview(store: OperationStore, dependencies: SkyrimSetupDependencies) =
    let preview
        workspace
        profile
        (selection: ModConductor.Persistence.SetupSelection)
        (deployed: DeploymentStatus)
        token
        =
        task {
            let! skse = store.SkseLoaders.ReadStored(workspace, profile, deployed.ActiveGeneration)

            let! skseUpdateVersion =
                task {
                    match skse with
                    | None -> return None
                    | Some _ ->
                        let! state = dependencies.ReadSkse workspace profile

                        return
                            if state.Phase = SksePhase.UpdateAvailable then
                                Some state.ComponentVersion
                            else
                                None
                }

            let! enb = store.EnbSetups.Components(workspace, profile, deployed.ActiveGeneration)
            let! fnis = store.FnisSetups.ReadStored(workspace, profile, deployed.ActiveGeneration)

            let installed =
                [ skse.IsSome
                  enb |> List.exists (fun item -> item.Kind = "runtime")
                  fnis.IsSome ]

            let actions = [ selection.Skse; selection.Enb; selection.Fnis ]

            let valid =
                List.zip actions installed
                |> List.forall (fun (action, present) ->
                    match action with
                    | SetupAction.Unchanged -> true
                    | SetupAction.Install -> not present
                    | SetupAction.Update
                    | SetupAction.Remove -> present
                    | _ -> false)
                && (selection.Skse <> SetupAction.Update || skseUpdateVersion.IsSome)

            let archiveRequired =
                selection.Enb = SetupAction.Install || selection.Enb = SetupAction.Update

            let archiveSupplied =
                not archiveRequired
                || (selection.EnbArchive |> Option.exists (not << String.IsNullOrWhiteSpace))

            let canStart =
                ModConductor.Persistence.SetupSelection.hasChange selection
                && valid
                && archiveSupplied
                && deployed.PendingReceipt.IsNone
                && (deployed.ActiveGeneration.IsSome
                    || actions |> List.exists (fun action -> action = SetupAction.Install))

            let! output =
                if fnis.IsSome then
                    task {
                        let! inspected = dependencies.InspectFnis workspace profile token
                        return Result.toOption inspected
                    }
                else
                    Task.FromResult None

            let status, detail =
                if not archiveSupplied then
                    "Choose an ENBSeries archive", ""
                elif not valid then
                    "Check the selected components", ""
                else
                    fnisExitWarning output |> Option.defaultValue ("", "")

            let components =
                [ "SKSE", "skse", installed[0]
                  "ENBSeries", "enb", installed[1]
                  "FNIS", "fnis", installed[2] ]
                |> List.map (fun (name, id, present) ->
                    { Id = id
                      Name = name
                      Status = if present then "Installed" else "Not installed"
                      Detail = ""
                      UpdateVersion = if id = "skse" then skseUpdateVersion else None
                      Installed = present
                      Ready = present
                      Active = false
                      Blocked = false })

            return
                view
                    SkyrimSetupPhase.Available
                    status
                    detail
                    components
                    selection
                    false
                    canStart
                    false
                    false
                    false
        }


    member _.Preview workspace profile selection deployed token =
        preview workspace profile selection deployed token
