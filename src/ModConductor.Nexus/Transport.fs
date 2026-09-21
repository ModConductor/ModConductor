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
            let at =
                lock scheduling (fun () ->
                    let now = DateTimeOffset.UtcNow

                    if blockedUntil > now then
                        raise (NexusException(NexusProblem.RateLimited blockedUntil))

                    let at = max now nextRequest
                    nextRequest <- at + interval
                    at)

            let delay = at - DateTimeOffset.UtcNow

            if delay > TimeSpan.Zero then
                do! Task.Delay(delay, token)
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
                let mutable result = None
                let mutable attempt = 0

                while result.IsNone do
                    attempt <- attempt + 1

                    if fields.IsNone then
                        do! wait token

                    use request =
                        new HttpRequestMessage(
                            (if fields.IsSome then HttpMethod.Post else HttpMethod.Get),
                            uri
                        )

                    request.Headers.UserAgent.ParseAdd("ModConductor/0.1.0")

                    request.Headers.TryAddWithoutValidation("Application-Name", "ModConductor")
                    |> ignore

                    request.Headers.TryAddWithoutValidation("Application-Version", "0.1.0")
                    |> ignore

                    authorization |> Option.iter (authorize request)

                    fields
                    |> Option.iter (fun values ->
                        request.Content <-
                            new FormUrlEncodedContent(
                                values |> Seq.map (fun (k, v) -> KeyValuePair(k, v))
                            ))

                    use timeout = CancellationTokenSource.CreateLinkedTokenSource token
                    timeout.CancelAfter(TimeSpan.FromSeconds 30.)

                    use! response =
                        task {
                            try
                                return! client.SendAsync(request, timeout.Token)
                            with :? OperationCanceledException when
                                not token.IsCancellationRequested ->
                                return raise (NexusException NexusProblem.TimedOut)
                        }

                    let code = int response.StatusCode
                    let retry = code = 429 || code = 408 || code >= 500
                    let after = if retry then Some(retryAfter response) else None
                    let reject problem = raise (NexusException problem)

                    if code = 429 then
                        lock scheduling (fun () -> blockedUntil <- max blockedUntil after.Value)

                    if
                        retry
                        && (fields.IsSome
                            || attempt >= 3
                            || after.Value > DateTimeOffset.UtcNow.AddSeconds 2.)
                    then
                        reject (
                            if code = 429 then
                                NexusProblem.RateLimited after.Value
                            else
                                NexusProblem.Offline
                        )

                    if not retry then
                        if code = 401 || (fields.IsSome && code = 400) then
                            reject (
                                match authorization with
                                | Some(NexusAuthorization.PersonalApiKey _) ->
                                    NexusProblem.InvalidApiKey
                                | _ -> NexusProblem.SignInRequired
                            )

                        if code = 403 then
                            reject (
                                if entitlement then
                                    NexusProblem.Entitlement
                                else
                                    NexusProblem.Forbidden
                            )

                        if code = 404 then
                            reject NexusProblem.NotFound

                        if code < 200 || code >= 300 then
                            reject NexusProblem.InvalidResponse

                        let! bytes = response.Content.ReadAsByteArrayAsync token
                        result <- Some(JsonDocument.Parse(ReadOnlyMemory bytes))
                    else
                        do!
                            Task.Delay(
                                max TimeSpan.Zero (after.Value - DateTimeOffset.UtcNow),
                                token
                            )

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

        NexusBoundary.protect (fun () ->
            task {
                do! slots.WaitAsync token

                try
                    do! wait token

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

                    request.Content <- new ByteArrayContent(MetadataJson.write fields)
                    request.Content.Headers.ContentType <- MediaTypeHeaderValue("application/json")
                    use deadline = CancellationTokenSource.CreateLinkedTokenSource token
                    deadline.CancelAfter(TimeSpan.FromSeconds 30.)

                    try
                        use! response = client.SendAsync(request, deadline.Token)
                        let code = int response.StatusCode

                        if code = 429 then
                            let until = retryAfter response
                            lock scheduling (fun () -> blockedUntil <- max blockedUntil until)
                            raise (NexusException(NexusProblem.RateLimited until))

                        if code = 401 then
                            raise (NexusException rejected)

                        if code = 403 || code = 400 || code = 422 then
                            raise (NexusException NexusProblem.Forbidden)

                        if code = 404 then
                            raise (NexusException NexusProblem.NotFound)

                        if code = 405 || code = 501 then
                            raise (NexusException NexusProblem.InteractionUnavailable)

                        if code <> 200 && code <> 201 then
                            raise (NexusException NexusProblem.InteractionUnknown)

                        let! bytes = response.Content.ReadAsByteArrayAsync deadline.Token
                        return JsonDocument.Parse(ReadOnlyMemory bytes)
                    with
                    | :? NexusException as error -> return raise error
                    | _ -> return raise (NexusException NexusProblem.InteractionUnknown)
                finally
                    slots.Release() |> ignore
            })

    interface IDisposable with
        member _.Dispose() =
            client.Dispose()
            slots.Dispose()
