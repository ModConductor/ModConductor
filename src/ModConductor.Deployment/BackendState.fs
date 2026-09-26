namespace ModConductor.Deployment

open System
open System.Collections.Generic
open System.Threading.Tasks
open ModConductor.DeploymentRecovery

type internal DeploymentBackendState() =
    let gate = obj ()
    let active = HashSet<Guid>()
    let prepared = Dictionary<Guid, PreparedState>()
    let order = Queue<Guid>()
    let mutable closed = false

    let mutable drained =
        new TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do drained.SetResult()

    let abandon value = PreparedState.abandon value

    member _.Abandon(value) = abandon value

    member _.Cache(id, value) =
        lock gate (fun () ->
            match prepared.TryGetValue id with
            | true, previous ->
                prepared.Remove id |> ignore
                abandon previous
            | _ -> ()

            while prepared.Count >= 2 do
                let candidate = order.Dequeue()

                match prepared.TryGetValue candidate with
                | true, evicted ->
                    prepared.Remove candidate |> ignore
                    abandon evicted
                | _ -> ()

            prepared[id] <- value
            order.Enqueue id)

    member _.Take(id) =
        lock gate (fun () ->
            match prepared.TryGetValue id with
            | true, value ->
                prepared.Remove id |> ignore
                Some value
            | _ -> None)

    member _.Enter(workspace) =
        lock gate (fun () ->
            if closed || active.Count >= 2 || active.Contains workspace then
                false
            else
                if active.Count = 0 then
                    drained <-
                        new TaskCompletionSource<unit>(
                            TaskCreationOptions.RunContinuationsAsynchronously
                        )

                active.Add workspace)

    member _.Leave(workspace) =
        lock gate (fun () ->
            active.Remove workspace |> ignore

            if active.Count = 0 then
                drained.TrySetResult() |> ignore)

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        let abandoned =
            lock gate (fun () ->
                if active.Count <> 0 || not (next ()) then
                    None
                else
                    closed <- true
                    let values = prepared.Values |> Seq.toList
                    prepared.Clear()
                    order.Clear()
                    Some values)

        match abandoned with
        | None -> false
        | Some values ->
            let mutable failure = None

            for value in values do
                try
                    abandon value
                with error ->
                    if failure.IsNone then
                        failure <- Some error

            match failure with
            | Some error -> raise error
            | None -> true

    member this.Lease(workspace) =
        let mutable released = false

        { new IDisposable with
            member _.Dispose() =
                lock gate (fun () ->
                    if not released then
                        released <- true
                        this.Leave workspace) }

    member this.TryAcquireWorkspace(workspace) =
        if this.Enter workspace then
            Some(this.Lease workspace)
        else
            None
