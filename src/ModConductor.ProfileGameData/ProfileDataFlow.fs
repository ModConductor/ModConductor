namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

module internal ProfileDataResultFlow =
    type Builder() =
        member _.Return value = Ok value
        member _.ReturnFrom value = value
        member _.Bind(value, next) = Result.bind next value
        member _.Zero() = Ok()
        member _.Delay(next) = next
        member _.Run(next) = next ()
        member _.Combine(value, next) = Result.bind (fun () -> next ()) value

    let result = Builder()

    let traverse map items =
        items
        |> List.fold
            (fun collected item ->
                collected
                |> Result.bind (fun values ->
                    map item |> Result.map (fun value -> value :: values)))
            (Ok [])
        |> Result.map List.rev

module internal ProfileDataResultTask =
    type Builder() =
        member _.Return value = Task.FromResult(Ok value)
        member _.ReturnFrom(value: Task<Result<'a, ProfileDataError>>) = value
        member _.ReturnFrom(value: Result<'a, ProfileDataError>) = Task.FromResult value

        member _.Bind
            (value: Result<'a, ProfileDataError>, next: 'a -> Task<Result<'b, ProfileDataError>>)
            =
            match value with
            | Ok item -> next item
            | Error error -> Task.FromResult(Error error)

        member _.Bind(value: Task<'a>, next: 'a -> Task<Result<'b, ProfileDataError>>) =
            task {
                let! item = value
                return! next item
            }

        member _.Zero() = Task.FromResult(Ok())
        member _.Delay(next) = next
        member _.Run(next) = next ()

        member _.Combine(value: Task<Result<unit, ProfileDataError>>, next) =
            task {
                let! result = value

                match result with
                | Ok() -> return! next ()
                | Error error -> return Error error
            }

        member _.TryWith(body, handler) =
            task {
                try
                    return! body ()
                with error ->
                    return! handler error
            }

        member _.TryFinally(body, cleanup) =
            task {
                try
                    return! body ()
                finally
                    cleanup ()
            }

        member this.Using(resource: #IDisposable, body) =
            this.TryFinally(
                (fun () -> body resource),
                fun () ->
                    if not (isNull (box resource)) then
                        resource.Dispose()
            )

    let resultTask = Builder()
