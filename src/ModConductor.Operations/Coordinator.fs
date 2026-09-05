namespace ModConductor.Operations

open System
open System.Threading.Tasks

type Coordinator(store: IOperationStore, inspect: unit -> RuntimeResult) =
    let gate = obj ()

    let drained =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let failed =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let mutable accepting = true
    let mutable admissions = 0
    let mutable jobs = 0

    let checkDrained () =
        if not accepting && admissions = 0 && jobs = 0 then
            drained.TrySetResult() |> ignore

    let run (request: Request) =
        task {
            try
                try
                    let result = inspect ()
                    let mutable active = true
                    let mutable sequence = 0

                    while active && sequence < request.Count do
                        do! Task.Delay 40
                        sequence <- sequence + 1
                        let! snapshot = store.Advance(request.Id, sequence, result)
                        active <- snapshot.Phase = Running
                with _ ->
                    try
                        do! store.Interrupt request.Id
                    with _ ->
                        lock gate (fun () -> accepting <- false)
                        failed.TrySetResult() |> ignore
            finally
                lock gate (fun () ->
                    jobs <- jobs - 1
                    checkDrained ())
        }

    member _.Begin(request) =
        task {
            let admitted =
                lock gate (fun () ->
                    if not accepting || admissions >= 32 then
                        false
                    else
                        admissions <- admissions + 1
                        true)

            if not admitted then
                return Error Capacity
            else
                try
                    let! outcome = store.Begin request

                    match outcome with
                    | Ok(snapshot, inserted) ->
                        if inserted then
                            lock gate (fun () -> jobs <- jobs + 1)
                            run request |> ignore

                        return Ok snapshot
                    | Error rejection -> return Error rejection
                finally
                    lock gate (fun () ->
                        admissions <- admissions - 1
                        checkDrained ())
        }

    member _.Failed = failed.Task

    member _.Drain() =
        lock gate (fun () ->
            accepting <- false
            checkDrained ())

        drained.Task
