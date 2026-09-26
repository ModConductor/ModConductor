namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Enb
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal EnbRecovery
    (
        store: OperationStore,
        persist: Guid -> Guid -> Guid option -> string option -> EnbView -> Task<EnbView>,
        view: EnbPhase -> string -> string -> EnbView,
        read: Guid -> Guid -> Task<EnbView>
    ) =
    member _.Recover(workspace, profile, token) =
        task {
            let! operation = store.EnbSetups.ConfigurationOperation(workspace, profile)
            let! state = store.Deployments.Read profile

            let restoreConfiguration operation success =
                task {
                    do!
                        store.EnbSetups.UpdateConfiguration(
                            operation.ReceiptId,
                            "restore_pending",
                            None,
                            operation.Detail
                        )

                    let! actionRecovered = store.RecoverEnbConfigurationAction(operation, token)

                    let! restored =
                        match actionRecovered with
                        | Ok() -> store.RestoreEnbConfiguration(operation, token)
                        | Error detail -> Task.FromResult(Error detail)

                    let outcome =
                        match restored with
                        | Ok() -> success
                        | Error detail ->
                            view EnbPhase.Conflict "Skyrim settings need attention" detail

                    let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                    return!
                        persist
                            workspace
                            profile
                            (if operation.Kind = "remove" then
                                 None
                             else
                                 saved |> Option.bind _.ArtifactId)
                            (if operation.Kind = "remove" then
                                 None
                             else
                                 saved |> Option.bind _.ArchiveSha256)
                            outcome
                }

            match state, operation with
            | Ok state, operation when state.WorkspaceId = workspace && state.PendingReceipt.IsSome ->
                let! receipt = store.Deployments.Receipt(state.PendingReceipt.Value)

                match receipt with
                | Ok receipt ->
                    let! recovered =
                        store.Deployments.Recover(receipt.Id, receipt.Revision, true, ignore, token)

                    match recovered, operation with
                    | Error problem, _ ->
                        return view EnbPhase.Failed "ENB recovery did not complete" (string problem)
                    | Ok _, Some operation when operation.Kind = "install" ->
                        return!
                            restoreConfiguration
                                operation
                                (view
                                    EnbPhase.Failed
                                    "The previous setup was restored"
                                    "Refresh ENB setup when you are ready to try again.")
                    | Ok _, Some operation ->
                        do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                        let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                        return!
                            persist
                                workspace
                                profile
                                (saved |> Option.bind _.ArtifactId)
                                (saved |> Option.bind _.ArchiveSha256)
                                (view
                                    EnbPhase.Ready
                                    "The previous ENB setup was restored"
                                    "Removal did not complete; the active setup and Skyrim settings are unchanged.")
                    | Ok _, None ->
                        return
                            view
                                EnbPhase.Failed
                                "The previous setup was restored"
                                "Refresh ENB setup when you are ready to try again."
                | Error problem ->
                    return view EnbPhase.Failed "ENB recovery is unavailable" (string problem)
            | _, Some operation ->
                let! receipt = store.EnbConfigurationDeploymentState operation.ReceiptId

                match operation.Kind, receipt with
                | "install", Some "complete" ->
                    do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                    let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                    return!
                        persist
                            workspace
                            profile
                            (saved |> Option.bind _.ArtifactId)
                            (saved |> Option.bind _.ArchiveSha256)
                            (view
                                EnbPhase.Ready
                                "Lean ENB is ready"
                                "Play uses the selected profile generation and its preserved runtime settings.")
                | "remove", Some "complete" ->
                    return!
                        restoreConfiguration
                            operation
                            (view
                                EnbPhase.Available
                                "Lean ENB was removed"
                                "The previous Skyrim settings were restored.")
                | "remove", _ ->
                    do! store.EnbSetups.RemoveConfiguration operation.ReceiptId
                    let! saved = store.EnbSetups.ReadStatus(workspace, profile)

                    return!
                        persist
                            workspace
                            profile
                            (saved |> Option.bind _.ArtifactId)
                            (saved |> Option.bind _.ArchiveSha256)
                            (view
                                EnbPhase.Ready
                                "The previous ENB setup was restored"
                                "Removal did not complete; the active setup and Skyrim settings are unchanged.")
                | _ ->
                    return!
                        restoreConfiguration
                            operation
                            (view
                                EnbPhase.Failed
                                "The previous setup was restored"
                                "Refresh ENB setup when you are ready to try again.")
            | _ -> return! read workspace profile
        }
