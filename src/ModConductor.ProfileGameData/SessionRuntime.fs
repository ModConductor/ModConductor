namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading.Tasks

[<Sealed>]
type internal ProfileDataSessionRuntime(enter: Guid -> IDisposable option) =
    let gate = obj ()
    let mutable active = 0
    let mutable closed = false

    let mutable drained =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    do drained.SetResult()

    let admit () =
        lock gate (fun () ->
            if closed || active >= 2 then
                false
            else
                if active = 0 then
                    drained <-
                        TaskCompletionSource<unit>(
                            TaskCreationOptions.RunContinuationsAsynchronously
                        )

                active <- active + 1
                true)

    let release () =
        lock gate (fun () ->
            active <- active - 1

            if active = 0 then
                drained.TrySetResult() |> ignore)

    let invoke (action: unit -> Task<Result<'a, ProfileDataError>>) =
        task {
            try
                return! action ()
            with
            | ProfileDataException error -> return Error error
            | :? OperationCanceledException -> return Error ProfileDataError.Cancelled
            | :? IOException as error -> return Error(ProfileDataError.Unavailable error.Message)
            | :? UnauthorizedAccessException ->
                return
                    Error(ProfileDataError.Unavailable "The settings or saves cannot be accessed.")
        }

    member _.Protect(action: unit -> Task<Result<'a, ProfileDataError>>) =
        task {
            if not (admit ()) then
                return Error ProfileDataError.Busy
            else
                try
                    return! invoke action
                finally
                    release ()
        }

    member this.Run(workspace, action: unit -> Task<Result<'a, ProfileDataError>>) =
        this.Protect(fun () ->
            task {
                match enter workspace with
                | None -> return Error ProfileDataError.Busy
                | Some lease ->
                    use lease = lease
                    return! action ()
            })

    member _.Drain() = lock gate (fun () -> drained.Task)

    member _.TryClose(next: unit -> bool) =
        lock gate (fun () ->
            if active <> 0 || not (next ()) then
                false
            else
                closed <- true
                true)
