namespace ModConductor.Deployment

open System
open System.IO
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery

module internal DeploymentReports =
    let phase =
        function
        | ReceiptPhase.Applying -> DeploymentPhase.Applying
        | ReceiptPhase.Restoring -> DeploymentPhase.Restoring
        | ReceiptPhase.Complete -> DeploymentPhase.Complete
        | ReceiptPhase.Restored -> DeploymentPhase.Restored
        | ReceiptPhase.Blocked -> DeploymentPhase.Blocked

    let receipt (value: Receipt) =
        { Id = value.Id
          WorkspaceId = value.Context.Roots.Head.Root.Id
          Revision = value.Revision
          Phase = phase value.Phase
          Previous = value.Previous
          Proposed = value.Proposed
          Completed =
            value.Changes
            |> List.filter (fun change ->
                change.Phase = EntryPhase.Installed || change.Phase = EntryPhase.Restored)
            |> List.length
          Total = value.Changes.Length
          Detail = value.Detail }

    let error =
        function
        | RecoveryError.NotFound -> DeploymentError.NotFound
        | RecoveryError.Busy -> DeploymentError.Busy
        | RecoveryError.Stale -> DeploymentError.Stale
        | RecoveryError.InvalidPlan -> DeploymentError.Blocked "The file plan is not valid."
        | RecoveryError.Limit ->
            DeploymentError.Unavailable "The deployment exceeds its supported bounds."
        | RecoveryError.Mismatch text
        | RecoveryError.Corrupt text -> DeploymentError.Blocked text
        | RecoveryError.Unavailable text -> DeploymentError.Unavailable text

type DeploymentBackend internal (repository: IDeploymentRepository) =
    let gate = obj ()
    let active = HashSet<Guid>()
    let prepared = Dictionary<Guid, PreparedState>()
    let order = Queue<Guid>()
    let mutable closed = false

    let protect action =
        task {
            try
                return! action ()
            with
            | RecoveryException error -> return Error(DeploymentReports.error error)
            | :? OperationCanceledException -> return Error DeploymentError.Cancelled
            | :? IOException as error -> return Error(DeploymentError.Unavailable error.Message)
            | :? UnauthorizedAccessException ->
                return Error(DeploymentError.Unavailable "Deployment storage cannot be accessed.")
        }

    let run workspace action =
        task {
            let entered =
                lock gate (fun () -> not closed && active.Count < 2 && active.Add workspace)

            if not entered then
                return Error DeploymentError.Busy
            else
                try
                    return! protect action
                finally
                    lock gate (fun () -> active.Remove workspace |> ignore)
        }

    let execute (receipt: Receipt) restoring progress token =
        task {
            let mutable completed = 0
            let mutable last = DateTime.MinValue

            let phase =
                if restoring then
                    DeploymentPhase.Restoring
                else
                    DeploymentPhase.Applying

            let notify name _ =
                if name = "installed" || name = "restored" then
                    completed <- completed + 1

                if (DateTime.UtcNow - last).TotalMilliseconds >= 100. then
                    progress
                        { Phase = phase
                          Completed = completed
                          Total = receipt.Changes.Length
                          Bytes = 0L }

                    last <- DateTime.UtcNow

            let! result = repository.Run(receipt.Id, receipt.Revision, restoring, token, notify)

            return
                result
                |> Result.map DeploymentReports.receipt
                |> Result.mapError DeploymentReports.error
        }

    member internal _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active.Count <> 0 || not (next ()) then
                false
            else
                closed <- true
                prepared.Clear()
                true)

    interface IDeploymentBackend with
        member _.Read profile =
            protect (fun () ->
                task {
                    let! sources, context = repository.Read profile

                    return
                        Ok
                            { WorkspaceId = sources.Stamp.WorkspaceId
                              Revision = context |> Option.map _.Revision |> Option.defaultValue 0L
                              ActiveGeneration = context |> Option.bind _.Active
                              PendingReceipt = context |> Option.bind _.Pending
                              Sources = sources.Stamp }
                })

        member _.Prepare(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! sources, context = repository.Read expected.ProfileId

                    if sources.Stamp <> expected then
                        return Error DeploymentError.Stale
                    elif context |> Option.exists (fun value -> value.Pending.IsSome) then
                        return Error DeploymentError.Busy
                    elif id = Guid.Empty then
                        return Error(DeploymentError.Unavailable "Select an operation identity.")
                    else
                        token.ThrowIfCancellationRequested()
                        GameProcesses.validate sources.Context |> ignore
                        let! value = repository.Prepare(id, sources, context, progress, token)
                        let! current = repository.Current expected
                        token.ThrowIfCancellationRequested()

                        if not current then
                            return Error DeploymentError.Stale
                        else
                            lock gate (fun () ->
                                while prepared.Count >= 2 do
                                    prepared.Remove(order.Dequeue()) |> ignore

                                prepared[id] <- value
                                order.Enqueue id)

                            return Ok value.View
                })

        member _.PrepareRetained(id, expected, generation, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! sources, existing = repository.Read expected.ProfileId

                    if sources.Stamp <> expected then
                        return Error DeploymentError.Stale
                    else
                        match existing with
                        | None -> return Error DeploymentError.NotFound
                        | Some context when context.Pending.IsSome ->
                            return Error DeploymentError.Busy
                        | Some context ->
                            let evidence = GameProcesses.validate sources.Context

                            if context.Fingerprint <> DeploymentContextId.fingerprint evidence then
                                return Error DeploymentError.Stale
                            else
                                let! value =
                                    repository.Retained(
                                        id,
                                        sources,
                                        context,
                                        generation,
                                        progress,
                                        token
                                    )

                                let! current = repository.Current expected
                                token.ThrowIfCancellationRequested()

                                if not current then
                                    return Error DeploymentError.Stale
                                else
                                    lock gate (fun () ->
                                        while prepared.Count >= 2 do
                                            prepared.Remove(order.Dequeue()) |> ignore

                                        prepared[id] <- value
                                        order.Enqueue id)

                                    return Ok value.View
                })

        member _.Activate(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let value =
                        lock gate (fun () ->
                            match prepared.TryGetValue id with
                            | true, value -> Some value
                            | _ -> None)

                    match value with
                    | None -> return Error DeploymentError.NotFound
                    | Some value when value.View.Sources <> expected ->
                        return Error DeploymentError.Stale
                    | Some value ->
                        let! context = repository.Context expected.WorkspaceId

                        if context <> value.Context then
                            return Error DeploymentError.Stale
                        else
                            GameProcesses.validate context |> ignore
                            token.ThrowIfCancellationRequested()
                            let! started = repository.Start(value.Switch, token)

                            match started with
                            | Error error -> return Error(DeploymentReports.error error)
                            | Ok receipt ->
                                lock gate (fun () -> prepared.Remove id |> ignore)
                                return! execute receipt false progress token
                })

        member _.Recover(id, revision, restore, progress, token) =
            protect (fun () ->
                task {
                    let! saved = repository.Receipt id

                    match saved with
                    | None -> return Error DeploymentError.NotFound
                    | Some saved ->
                        return!
                            run saved.Context.Roots.Head.Root.Id (fun () ->
                                task {
                                    if saved.Revision <> revision then
                                        return Error DeploymentError.Stale
                                    else
                                        let! context =
                                            repository.Context saved.Context.Roots.Head.Root.Id

                                        let evidence = GameProcesses.validate context

                                        if
                                            DeploymentContextId.fingerprint evidence
                                            <> saved.Context.Fingerprint
                                        then
                                            return Error DeploymentError.Stale
                                        else
                                            return! execute saved restore progress token
                                })
                })

        member _.Receipt id =
            protect (fun () ->
                task {
                    let! value = repository.Receipt id

                    return
                        value
                        |> Option.map (DeploymentReports.receipt >> Ok)
                        |> Option.defaultValue (Error DeploymentError.NotFound)
                })
