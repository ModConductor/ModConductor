namespace ModConductor.Engine

open System
open System.Threading.Tasks
open ModConductor.Fnis
open ModConductor.Persistence
open ModConductor.Protocol.V1

type internal SkyrimSetupCancellation
    (
        store: OperationStore,
        dependencies: SkyrimSetupDependencies,
        inspection: SkyrimSetupInspection,
        recovery: SkyrimSetupRecovery,
        cancelWorker: Guid * Guid -> unit
    ) =
    let inspect = inspection.Inspect
    let recoverPending = recovery.Pending

    let completeCancellation workspace profile (intent: StoredSkyrimSetupIntent) token =
        task {
            let key = workspace, profile

            cancelWorker key

            let! childResult =
                task {
                    match intent.Stage with
                    | "enb-start"
                    | "enb-wait"
                    | "enb" ->
                        let! result = dependencies.CancelEnb workspace profile

                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = EnbPhase.Validating
                                || result.Phase = EnbPhase.Acquiring
                                || result.Phase = EnbPhase.Installing
                                || result.Phase = EnbPhase.Failed
                                || result.Phase = EnbPhase.Conflict
                            then
                                Error detail
                            else
                                Ok detail
                    | "skse-start"
                    | "skse" ->
                        let! result = dependencies.CancelSkse workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = SksePhase.Downloading
                                || result.Phase = SksePhase.Installing
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-install" ->
                        let! result = dependencies.CancelFnis workspace profile
                        let detail = result.Status + ". " + result.Detail

                        return
                            if
                                result.Phase = FnisPhase.Downloading
                                || result.Phase = FnisPhase.Installing
                                || result.Phase = FnisPhase.RecoveryRequired
                            then
                                Error detail
                            else
                                Ok detail
                    | "fnis-run" ->
                        let! result = dependencies.CancelFnisRun workspace profile

                        return
                            match result with
                            | Ok value when value.Phase = ModConductor.Fnis.FnisOutputPhase.Running ->
                                Error(value.Status + ". " + value.Detail)
                            | Ok value -> Ok(value.Status + ". " + value.Detail)
                            | Error error -> Error("FNIS cancellation result: " + string error)
                    | _ -> return Ok "No child operation remained active."
                }

            let! deployed = store.Deployments.Read profile

            let! recovered =
                match deployed with
                | Ok value when value.PendingReceipt.IsSome ->
                    recoverPending workspace profile value token
                | _ -> Task.FromResult(Ok())

            match childResult, recovered with
            | Error childDetail, Error recoveryDetail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = childDetail + " " + recoveryDetail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.Selection (Some pending) token
            | Error detail, Ok()
            | Ok _, Error detail ->
                let pending =
                    { intent with
                        CancelRequested = true
                        Cancelled = false
                        Completed = false
                        CancelDetail = detail }

                do! store.SkyrimSetups.Save pending
                return! inspect workspace profile intent.Selection (Some pending) token
            | Ok childDetail, Ok() ->
                let cancelled =
                    { intent with
                        CancelRequested = false
                        Cancelled = true
                        Completed = false
                        Stage = "cancelled"
                        ActionId = None
                        Selection =
                            { intent.Selection with
                                EnbArchive = None }
                        CancelDetail = childDetail }

                do! store.SkyrimSetups.Save cancelled

                return!
                    inspect
                        workspace
                        profile
                        ModConductor.Persistence.SetupSelection.none
                        (Some cancelled)
                        token
        }


    member _.Complete workspace profile intent token =
        completeCancellation workspace profile intent token
