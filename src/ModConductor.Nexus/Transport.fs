namespace ModConductor.Nexus

open System
open System.Collections.Generic
open System.Net
open System.Net.Http
open System.Net.Http.Headers
open System.Text.Json
open System.Threading
open System.Threading.Tasks

module internal NexusBoundary =
    let protect action =
        task {
            try
                let! value = action ()
                return Ok value
            with
            | :? NexusException as error -> return Error error.Problem
            | :? OperationCanceledException -> return Error NexusProblem.Cancelled
            | :? HttpRequestException -> return Error NexusProblem.Offline
            | :? JsonException
            | :? InvalidOperationException
            | :? FormatException -> return Error NexusProblem.InvalidResponse
            | _ -> return Error NexusProblem.Failed
        }

    let protectResult action =
        task {
            let! result = protect action
            return Result.bind id result
        }

type private ResponseDisposition =
    | Retry of DateTimeOffset
    | Reject of NexusProblem
    | ReadBody

type internal NexusTransport(api: Uri, interval: TimeSpan) =
    let handler =
        new SocketsHttpHandler(
            AllowAutoRedirect = false,
            UseCookies = false,
            ConnectTimeout = TimeSpan.FromSeconds 10.
        )

    let client =
        new HttpClient(
            handler,
            Timeout = Timeout.InfiniteTimeSpan,
            MaxResponseContentBufferSize = 4L * 1024L * 1024L
        )

    let slots = new SemaphoreSlim(2, 2)
    let scheduling = obj ()
    let mutable nextRequest = DateTimeOffset.MinValue
    let mutable blockedUntil = DateTimeOffset.MinValue

    let authorize (request: HttpRequestMessage) =
        function
        | NexusAuthorization.OAuth value ->
            request.Headers.Authorization <- AuthenticationHeaderValue("Bearer", value)
        | NexusAuthorization.PersonalApiKey value ->
            request.Headers.TryAddWithoutValidation("APIKEY", value) |> ignore

    let wait (token: CancellationToken) =
        task {
            let scheduled =
                lock scheduling (fun () ->
                    let now = DateTimeOffset.UtcNow

                    if blockedUntil > now then
                        Error(NexusProblem.RateLimited blockedUntil)
                    else
                        let at = max now nextRequest
                        nextRequest <- at + interval
                        Ok at)

            match scheduled with
            | Error error -> return Error error
            | Ok at ->
                let delay = at - DateTimeOffset.UtcNow

                if delay > TimeSpan.Zero then
                    do! Task.Delay(delay, token)

                return Ok()
        }

    let retryAfter (response: HttpResponseMessage) =
        let value = response.Headers.RetryAfter

        if isNull value then
            DateTimeOffset.UtcNow.AddSeconds 1.
        elif value.Date.HasValue then
            value.Date.Value
        elif value.Delta.HasValue then
            DateTimeOffset.UtcNow + value.Delta.Value
        else
            DateTimeOffset.UtcNow.AddSeconds 1.

    let request
        (uri: Uri)
        (authorization: NexusAuthorization option)
        (fields: (string * string) list option)
        =
        let value =
            new HttpRequestMessage((if fields.IsSome then HttpMethod.Post else HttpMethod.Get), uri)

        value.Headers.UserAgent.ParseAdd("ModConductor/0.1.0")

        value.Headers.TryAddWithoutValidation("Application-Name", "ModConductor")
        |> ignore

        value.Headers.TryAddWithoutValidation("Application-Version", "0.1.0") |> ignore
        authorization |> Option.iter (authorize value)

        fields
        |> Option.iter (fun values ->
            value.Content <-
                new FormUrlEncodedContent(values |> Seq.map (fun (k, v) -> KeyValuePair(k, v))))

        value

    let sendAttempt (request: HttpRequestMessage) (token: CancellationToken) =
        task {
            use timeout = CancellationTokenSource.CreateLinkedTokenSource token
            timeout.CancelAfter(TimeSpan.FromSeconds 30.)

            try
                let! response = client.SendAsync(request, timeout.Token)
                return Ok response
            with :? OperationCanceledException when not token.IsCancellationRequested ->
                return Error NexusProblem.TimedOut
        }

    let disposition
        (response: HttpResponseMessage)
        (authorization: NexusAuthorization option)
        (fields: (string * string) list option)
        (entitlement: bool)
        (attempt: int)
        =
        let code = int response.StatusCode
        let retry = code = 429 || code = 408 || code >= 500
        let after = if retry then Some(retryAfter response) else None

        if code = 429 then
            lock scheduling (fun () -> blockedUntil <- max blockedUntil after.Value)

        if retry then
            if
                fields.IsSome
                || attempt >= 3
                || after.Value > DateTimeOffset.UtcNow.AddSeconds 2.
            then
                Reject(
                    if code = 429 then
                        NexusProblem.RateLimited after.Value
                    else
                        NexusProblem.Offline
                )
            else
                Retry after.Value
        elif code = 401 || (fields.IsSome && code = 400) then
            Reject(
                match authorization with
                | Some(NexusAuthorization.PersonalApiKey _) -> NexusProblem.InvalidApiKey
                | _ -> NexusProblem.SignInRequired
            )
        elif code = 403 then
            Reject(
                if entitlement then
                    NexusProblem.Entitlement
                else
                    NexusProblem.Forbidden
            )
        elif code = 404 then
            Reject NexusProblem.NotFound
        elif code < 200 || code >= 300 then
            Reject NexusProblem.InvalidResponse
        else
            ReadBody

    member _.Send
        (
            uri: Uri,
            authorization: NexusAuthorization option,
            fields: (string * string) list option,
            entitlement: bool,
            token: CancellationToken
        ) =
        task {
            do! slots.WaitAsync token

            try
                let mutable result: Result<JsonDocument, NexusProblem> option = None
                let mutable attempt = 0

                while result.IsNone do
                    attempt <- attempt + 1

                    if fields.IsNone then
                        let! admission = wait token

                        match admission with
                        | Error error -> result <- Some(Error error)
                        | Ok() -> ()

                    if result.IsNone then
                        use outgoing = request uri authorization fields
                        let! received = sendAttempt outgoing token

                        match received with
                        | Error error -> result <- Some(Error error)
                        | Ok response ->
                            use response = response

                            match disposition response authorization fields entitlement attempt with
                            | Reject error -> result <- Some(Error error)
                            | Retry after ->
                                do!
                                    Task.Delay(
                                        max TimeSpan.Zero (after - DateTimeOffset.UtcNow),
                                        token
                                    )
                            | ReadBody ->
                                let! bytes = response.Content.ReadAsByteArrayAsync token
                                result <- Some(Ok(JsonDocument.Parse(ReadOnlyMemory bytes)))

                return result.Value
            finally
                slots.Release() |> ignore
        }

    member this.Token(uri, fields, token) =
        this.Send(uri, None, Some fields, false, token)

    member this.UserInfo(uri, access, token) =
        this.Send(uri, Some(NexusAuthorization.OAuth access), None, false, token)

    member this.Api(path: string, authorization, entitlement, token) =
        this.Send(Uri(api, path), Some authorization, None, entitlement, token)

    member this.PublicV3(path: string, token) =
        let root =
            if api.Host.Equals("api.nexusmods.com", StringComparison.OrdinalIgnoreCase) then
                Uri "https://api.nexusmods.com/v3/"
            else
                Uri(api, "../v3/")

        this.Send(Uri(root, path), None, None, false, token)

    member this.ValidatePersonalApiKey(key, token) =
        this.Api("users/validate.json", NexusAuthorization.PersonalApiKey key, false, token)

    member _.Mutate
        (
            path: string,
            authorization: NexusAuthorization,
            action: NexusInteraction,
            fields,
            token: CancellationToken
        ) =
        let bearer, apiKey, rejected =
            match authorization with
            | NexusAuthorization.OAuth value -> Some value, None, NexusProblem.SignInRequired
            | NexusAuthorization.PersonalApiKey value ->
                None, Some value, NexusProblem.InvalidApiKey

        NexusBoundary.protectResult (fun () ->
            task {
                do! slots.WaitAsync token

                try
                    let! admission = wait token

                    match admission with
                    | Error error -> return Error error
                    | Ok() ->
                        use request =
                            new HttpRequestMessage(
                                (if action = NexusInteraction.Untrack then
                                     HttpMethod.Delete
                                 else
                                     HttpMethod.Post),
                                Uri(api, path)
                            )

                        request.Headers.UserAgent.ParseAdd("ModConductor/0.1.0")

                        request.Headers.TryAddWithoutValidation("Application-Name", "ModConductor")
                        |> ignore

                        request.Headers.TryAddWithoutValidation("Application-Version", "0.1.0")
                        |> ignore

                        bearer
                        |> Option.iter (fun value ->
                            request.Headers.Authorization <-
                                AuthenticationHeaderValue("Bearer", value))

                        apiKey
                        |> Option.iter (fun value ->
                            request.Headers.TryAddWithoutValidation("APIKEY", value) |> ignore)

                        request.Content <- new ByteArrayContent(InteractionJson.write fields)

                        request.Content.Headers.ContentType <-
                            MediaTypeHeaderValue("application/json")

                        use deadline = CancellationTokenSource.CreateLinkedTokenSource token
                        deadline.CancelAfter(TimeSpan.FromSeconds 30.)

                        try
                            use! response = client.SendAsync(request, deadline.Token)
                            let code = int response.StatusCode

                            if code = 429 then
                                let until = retryAfter response
                                lock scheduling (fun () -> blockedUntil <- max blockedUntil until)
                                return Error(NexusProblem.RateLimited until)
                            elif code = 401 then
                                return Error rejected
                            elif code = 403 || code = 400 || code = 422 then
                                return Error NexusProblem.Forbidden
                            elif code = 404 then
                                return Error NexusProblem.NotFound
                            elif code = 405 || code = 501 then
                                return Error NexusProblem.InteractionUnavailable
                            elif code <> 200 && code <> 201 then
                                return Error NexusProblem.InteractionUnknown
                            else
                                let! bytes = response.Content.ReadAsByteArrayAsync deadline.Token
                                return Ok(JsonDocument.Parse(ReadOnlyMemory bytes))
                        with
                        | :? OperationCanceledException when token.IsCancellationRequested ->
                            return Error NexusProblem.Cancelled
                        | :? OperationCanceledException when deadline.IsCancellationRequested ->
                            return Error NexusProblem.TimedOut
                        | _ -> return Error NexusProblem.InteractionUnknown
                finally
                    slots.Release() |> ignore
            })

    interface IDisposable with
        member _.Dispose() =
            client.Dispose()
            slots.Dispose()
