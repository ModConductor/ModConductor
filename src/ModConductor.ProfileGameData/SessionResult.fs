namespace ModConductor.ProfileGameData

open System.Threading.Tasks

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

    let resultTask = Builder()
