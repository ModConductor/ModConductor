namespace ModConductor.Thunderstore

open System
open System.Net.Http
open System.Text.Json
open System.Threading

// One response cache follows provider expiry, without accumulating search history.
type internal Transport(client: HttpClient) =
    let gate = obj ()
    let mutable cached: (Uri * byte array * DateTimeOffset) option = None
    let mutable blocked: DateTimeOffset option = None

    let retryAt (response: HttpResponseMessage) =
        let value = response.Headers.RetryAfter

        if isNull value then
            None
        elif value.Date.HasValue then
            Some value.Date.Value
        elif value.Delta.HasValue then
            Some(DateTimeOffset.UtcNow + value.Delta.Value)
        else
            None

    let cache uri (response: HttpResponseMessage) bytes =
        let value = response.Headers.CacheControl

        if not (isNull value) && value.MaxAge.HasValue && not value.NoStore then
            lock gate (fun () ->
                cached <- Some(uri, bytes, DateTimeOffset.UtcNow + value.MaxAge.Value))

    let send (uri: Uri) label (token: CancellationToken) =
        task {
            use request = new HttpRequestMessage(HttpMethod.Get, uri)
            request.Headers.UserAgent.ParseAdd("ModConductor/0.2.0")
            use! response = client.SendAsync(request, token)

            match int response.StatusCode with
            | 429 ->
                let until = retryAt response
                lock gate (fun () -> blocked <- until)
                return Error(Problem.RateLimited until)
            | 403 -> return Error Problem.Forbidden
            | 404
            | 410 -> return Error(Problem.NotFound label)
            | code when code >= 200 && code < 300 ->
                let! bytes = response.Content.ReadAsByteArrayAsync token
                cache uri response bytes
                return Ok bytes
            | _ -> return Error Problem.Offline
        }

    member _.Get(uri, label, token: CancellationToken) =
        task {
            try
                token.ThrowIfCancellationRequested()

                let paused, hit =
                    lock gate (fun () ->
                        blocked |> Option.filter (fun at -> at > DateTimeOffset.UtcNow),
                        cached
                        |> Option.filter (fun (key, _, until) ->
                            key = uri && until > DateTimeOffset.UtcNow))

                match paused, hit with
                | Some until, _ -> return Error(Problem.RateLimited(Some until))
                | None, Some(_, bytes, _) -> return Ok(JsonDocument.Parse(ReadOnlyMemory bytes))
                | None, None ->
                    let! result = send uri label token

                    return
                        result |> Result.map (fun bytes -> JsonDocument.Parse(ReadOnlyMemory bytes))
            with
            | :? OperationCanceledException ->
                return
                    Error(
                        if token.IsCancellationRequested then
                            Problem.Cancelled
                        else
                            Problem.TimedOut
                    )
            | :? HttpRequestException -> return Error Problem.Offline
            | :? JsonException -> return Error Problem.InvalidResponse
        }
