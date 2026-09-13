namespace ModConductor.HttpDownloads

open System
open System.IO
open System.Net
open System.Net.Http
open System.Net.Http.Headers
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks

type internal TransferFailure
    (message, retry: bool, restart: bool, retryAt: DateTimeOffset option, ?rejectedLink: bool) =
    inherit Exception(message)
    member _.Retry = retry
    member _.Restart = restart
    member _.RetryAt = retryAt
    member _.RejectedLink = defaultArg rejectedLink false

module internal HttpTransfer =
    let private stop message restart =
        raise (TransferFailure(message, false, restart, None))

    let private observation privateSource (work: DownloadWork) (response: HttpResponseMessage) =
        let url = response.RequestMessage.RequestUri.AbsoluteUri

        let actual =
            if privateSource then
                Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes url))
            else
                url

        if privateSource && work.Bytes > 0L && work.EffectiveUrl <> Some actual then
            stop "The download link changed. Restart to download this file again." true

        let tag = response.Headers.ETag

        let entity =
            if isNull tag || tag.IsWeak then
                None
            else
                Some(tag.ToString())

        let content = response.Content.Headers

        if
            content.ContentEncoding
            |> Seq.exists (fun e ->
                not (String.Equals(e, "identity", StringComparison.OrdinalIgnoreCase)))
        then
            stop "The server sent an incompatible file encoding." true

        let suppliedLength =
            if content.ContentLength.HasValue then
                Some content.ContentLength.Value
            else
                None

        let total =
            if work.Bytes = 0L then
                if response.StatusCode <> HttpStatusCode.OK then
                    stop "The server did not send the requested file." true

                suppliedLength
            else
                let range = content.ContentRange

                if
                    response.StatusCode <> HttpStatusCode.PartialContent
                    || work.EntityTag.IsNone
                    || entity <> work.EntityTag
                    || work.EffectiveUrl <> Some actual
                    || isNull range
                    || range.Unit <> "bytes"
                    || not range.HasRange
                    || not range.HasLength
                    || range.From.Value <> work.Bytes
                    || range.To.Value <> range.Length.Value - 1L
                    || range.Length.Value <= work.Bytes
                    || (work.Total |> Option.exists ((<>) range.Length.Value))
                    || (suppliedLength |> Option.exists ((<>) (range.Length.Value - work.Bytes)))
                then
                    stop
                        "The server cannot resume this download. Restart it from the beginning."
                        true

                Some range.Length.Value

        if
            work.Request.ExpectedLength.IsSome
            && total.IsSome
            && work.Request.ExpectedLength <> total
        then
            stop "The file size does not match the expected size." true

        { Total = total |> Option.orElse work.Request.ExpectedLength
          EntityTag = entity
          EffectiveUrl = actual }

    let private checkStatus privateSource (response: HttpResponseMessage) =
        let code = int response.StatusCode

        if code = 408 || code = 429 || code >= 500 then
            let after = response.Headers.RetryAfter

            let at =
                if isNull after then
                    None
                elif after.Date.HasValue then
                    Some after.Date.Value
                elif after.Delta.HasValue then
                    Some(DateTimeOffset.UtcNow + after.Delta.Value)
                else
                    None

            raise (
                TransferFailure(
                    "The server is unavailable. The partial copy is saved.",
                    true,
                    false,
                    at
                )
            )
        elif privateSource && (code = 401 || code = 403) then
            raise (
                TransferFailure(
                    "The download link was not accepted. Try again.",
                    false,
                    false,
                    None,
                    rejectedLink = true
                )
            )
        elif code >= 300 then
            stop
                (if code = 416 then
                     "The server cannot resume this download. Restart it from the beginning."
                 else
                     "The server refused the download (HTTP " + code.ToString() + ").")
                (code = 416)

    let rec private send
        (client: HttpClient)
        (privateDownload: PrivateDownload option)
        (work: DownloadWork)
        (token: CancellationToken)
        (uri: Uri)
        redirects
        =
        task {
            match privateDownload with
            | Some source ->
                if source.Expires <= DateTimeOffset.UtcNow then
                    stop "The download link expired. Try again." false

                if
                    not (
                        source.Origins
                        |> List.exists (fun origin ->
                            origin.GetLeftPart(UriPartial.Authority) = uri.GetLeftPart(
                                UriPartial.Authority
                            ))
                    )
                    || uri.UserInfo <> ""
                    || uri.Fragment <> ""
                then
                    stop "Nexus Mods returned an unexpected download location." false
            | None -> ()

            use request = new HttpRequestMessage(HttpMethod.Get, uri)

            request.Headers.AcceptEncoding.Add(StringWithQualityHeaderValue("identity"))

            if work.Bytes > 0L then
                request.Headers.Range <- RangeHeaderValue(Nullable work.Bytes, Nullable())

                request.Headers.IfRange <-
                    RangeConditionHeaderValue(EntityTagHeaderValue.Parse(work.EntityTag.Value))

            let! response =
                client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, token)

            let code = int response.StatusCode

            if
                privateDownload.IsSome
                && (code = 301 || code = 302 || code = 303 || code = 307 || code = 308)
            then
                let location = response.Headers.Location
                response.Dispose()

                if redirects >= 5 || isNull location then
                    stop "The download redirect could not be followed." false

                return! send client privateDownload work token (Uri(uri, location)) (redirects + 1)
            else
                return response
        }


    let run
        (client: HttpClient)
        (privateDownload: PrivateDownload option)
        (url: Uri)
        (policy: DownloadPolicy)
        (repository: IDownloadRepository)
        (work: DownloadWork)
        (token: CancellationToken)
        =
        task {
            if work.Bytes > 0L && work.EntityTag.IsNone then
                stop "The server did not supply a resume validator. Restart the download." true

            use! target = repository.Open work
            let output = target.Stream

            let! length, checksum =
                task {
                    try
                        use headers = CancellationTokenSource.CreateLinkedTokenSource token
                        headers.CancelAfter policy.HeaderTimeout

                        use! response = send client privateDownload work headers.Token url 0
                        headers.CancelAfter Timeout.InfiniteTimeSpan
                        checkStatus privateDownload.IsSome response
                        let observed = observation privateDownload.IsSome work response
                        do! target.Observe observed
                        use! body = response.Content.ReadAsStreamAsync token
                        let buffer = Array.zeroCreate<byte> 65536
                        let mutable doneReading = false
                        let mutable checkpoint = output.Position

                        while not doneReading do
                            use idle = CancellationTokenSource.CreateLinkedTokenSource token
                            idle.CancelAfter policy.ReadTimeout
                            let! count = body.ReadAsync(buffer.AsMemory(), idle.Token)

                            if count = 0 then
                                doneReading <- true
                            else
                                if
                                    observed.Total
                                    |> Option.exists (fun n -> output.Position + int64 count > n)
                                then
                                    stop
                                        "The server sent more bytes than the expected file size."
                                        true

                                do! output.WriteAsync(buffer.AsMemory(0, count), token)

                                if output.Position - checkpoint >= policy.CheckpointBytes then
                                    output.Flush true
                                    do! target.Checkpoint output.Position
                                    checkpoint <- output.Position

                        let length = output.Position
                        output.Flush true
                        do! target.Checkpoint length

                        if observed.Total |> Option.exists ((<>) length) then
                            raise (
                                TransferFailure(
                                    "The connection ended before the file was complete.",
                                    true,
                                    false,
                                    None
                                )
                            )

                        if work.Request.ExpectedLength |> Option.exists ((<>) length) then
                            stop "The file size does not match the expected size." true

                        output.Position <- 0L
                        let! digest = SHA256.HashDataAsync(output, token)
                        let checksum = Convert.ToHexString(digest).ToLowerInvariant()

                        if
                            work.Request.ExpectedSha256
                            |> Option.exists (fun expected ->
                                not (
                                    String.Equals(
                                        checksum,
                                        expected,
                                        StringComparison.OrdinalIgnoreCase
                                    )
                                ))
                        then
                            stop "The SHA-256 does not match the supplied checksum." true

                        token.ThrowIfCancellationRequested()
                        return length, checksum
                    with error ->
                        output.Flush true
                        do! target.Checkpoint output.Length
                        return raise error
                }

            output.Dispose()
            do! target.Publish(length, checksum)
        }
