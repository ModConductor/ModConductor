namespace ModConductor.Migration

module internal MigrationResult =
    type Builder() =
        member _.Return value = Ok value
        member _.ReturnFrom value = value
        member _.Bind(value, next) = Result.bind next value
        member _.Zero() = Ok()
        member _.Delay(next) = next
        member _.Run(next) = next ()
        member _.Combine(value, next) = Result.bind (fun () -> next ()) value

        member this.While(guard, body) =
            let mutable outcome = Ok()

            while Result.isOk outcome && guard () do
                outcome <- body ()

            outcome

        member this.For(items: seq<'a>, body: 'a -> Result<unit, 'e>) =
            use iterator = items.GetEnumerator()
            this.While(iterator.MoveNext, fun () -> body iterator.Current)

        member _.TryWith(body, handler) =
            try
                body ()
            with error ->
                handler error

        member _.TryFinally(body, cleanup) =
            try
                body ()
            finally
                cleanup ()

        member this.Using(resource: #System.IDisposable, body) =
            this.TryFinally(
                (fun () -> body resource),
                fun () ->
                    if not (isNull (box resource)) then
                        resource.Dispose()
            )

    let result = Builder()

    let traverse (map: 'a -> Result<'b, 'e>) (items: 'a list) =
        let values = ResizeArray<'b>()
        let mutable failure = None

        for item in items do
            if failure.IsNone then
                match map item with
                | Ok value -> values.Add value
                | Error error -> failure <- Some error

        match failure with
        | Some error -> Error error
        | None -> Ok(List.ofSeq values)
