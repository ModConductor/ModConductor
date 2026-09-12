namespace ModConductor.Native.Fixtures

open System
open System.Collections.Concurrent
open System.IO
open System.Net
open System.Net.Sockets
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks

type DownloadRequestSeen =
    { Path: string
      Range: string
      Validator: string
      At: DateTimeOffset }

type DownloadServer() =
    let payload = Array.init (4 * 1024 * 1024) (fun n -> byte (n % 251))
    let checksum = Convert.ToHexString(SHA256.HashData payload).ToLowerInvariant()
    let probe = new TcpListener(IPAddress.Loopback, 0)
    do probe.Start()
    let port = (probe.LocalEndpoint :?> IPEndPoint).Port
    do probe.Stop()
    let url = "http://127.0.0.1:" + port.ToString()
    let listener = new HttpListener()
    let stop = new CancellationTokenSource()

    let hold =
        TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

    let seen = ConcurrentQueue<DownloadRequestSeen>()
    let counts = ConcurrentDictionary<string, int>()
    let jobs = ConcurrentBag<Task>()

    let send (context: HttpListenerContext) =
        task {
            let response = context.Response

            try
                let path = context.Request.Url.AbsolutePath

                if path = "/stats" then
                    let count =
                        match counts.TryGetValue "/slow" with
                        | true, value -> value
                        | _ -> 0

                    let body = System.Text.Encoding.UTF8.GetBytes(count.ToString())
                    response.ContentLength64 <- int64 body.Length
                    do! response.OutputStream.WriteAsync(ReadOnlyMemory<byte>(body), stop.Token)
                elif path = "/release" then
                    hold.TrySetResult() |> ignore
                    response.StatusCode <- 204
                else
                    let number = counts.AddOrUpdate(path, 1, fun _ value -> value + 1)
                    let range = context.Request.Headers["Range"]

                    seen.Enqueue
                        { Path = path
                          Range = range
                          Validator = context.Request.Headers["If-Range"]
                          At = DateTimeOffset.UtcNow }

                    let offset =
                        if isNull range then
                            0
                        else
                            Int32.Parse(range.Substring(6).TrimEnd('-'))

                    if path = "/headers-timeout" then
                        do! Task.Delay(2000, stop.Token)

                    if path = "/mirror-fail" || (path = "/partial-fail" && number > 1) then
                        response.StatusCode <- 503
                    elif path = "/always429" || (path = "/retry429" && number = 1) then
                        response.StatusCode <- 429
                        response.Headers["Retry-After"] <- "1"
                    else
                        let ranged = offset > 0 && path <> "/ignore-range"
                        let start = if ranged then offset else 0
                        response.StatusCode <- if ranged then 206 else 200

                        if path <> "/no-etag" && path <> "/no-etag-slow" then
                            response.Headers["ETag"] <-
                                if path = "/changed-etag" && ranged then
                                    "\"fixture-2\""
                                else
                                    "\"fixture-1\""

                        if ranged then
                            let first = if path = "/wrong-range" then offset - 1 else offset

                            let total =
                                if path = "/changed-total" then
                                    payload.Length + 1
                                else
                                    payload.Length

                            response.Headers["Content-Range"] <-
                                "bytes "
                                + first.ToString()
                                + "-"
                                + (total - 1).ToString()
                                + "/"
                                + total.ToString()

                        if path = "/encoding" then
                            response.Headers["Content-Encoding"] <- "gzip"

                        response.ContentLength64 <- int64 (payload.Length - start)

                        let data =
                            if path = "/corrupt" then
                                Array.map ((^^^) 1uy) payload
                            else
                                payload

                        if path = "/timeout" then
                            do!
                                response.OutputStream.WriteAsync(
                                    ReadOnlyMemory<byte>(data, 0, 16384),
                                    stop.Token
                                )

                            do! response.OutputStream.FlushAsync stop.Token
                            do! Task.Delay(2000, stop.Token)
                        elif
                            path = "/truncate"
                            || (path = "/truncate-once" && number = 1)
                            || (path = "/partial-fail" && number = 1)
                        then
                            do!
                                response.OutputStream.WriteAsync(
                                    ReadOnlyMemory<byte>(data, start, 32768),
                                    stop.Token
                                )

                            do! response.OutputStream.FlushAsync stop.Token
                            response.Abort()
                        elif
                            not ranged
                            && (path = "/slow"
                                || path = "/ignore-range"
                                || path = "/changed-etag"
                                || path = "/wrong-range"
                                || path = "/changed-total"
                                || path = "/no-etag-slow")
                        then
                            do!
                                response.OutputStream.WriteAsync(
                                    ReadOnlyMemory<byte>(data, 0, 2 * 1024 * 1024),
                                    stop.Token
                                )

                            do! response.OutputStream.FlushAsync stop.Token
                            do! hold.Task.WaitAsync stop.Token

                            do!
                                response.OutputStream.WriteAsync(
                                    ReadOnlyMemory<byte>(
                                        data,
                                        2 * 1024 * 1024,
                                        data.Length - 2 * 1024 * 1024
                                    ),
                                    stop.Token
                                )
                        else
                            do!
                                response.OutputStream.WriteAsync(
                                    ReadOnlyMemory<byte>(data, start, data.Length - start),
                                    stop.Token
                                )
            with
            | :? IOException
            | :? HttpListenerException
            | :? ObjectDisposedException
            | :? OperationCanceledException -> ()

            response.Close()
        }

    do
        listener.Prefixes.Add(url + "/")
        listener.Start()

    let accepting =
        task {
            try
                while not stop.IsCancellationRequested do
                    let! context = listener.GetContextAsync().WaitAsync stop.Token
                    jobs.Add(send context)
            with :? OperationCanceledException ->
                ()
        }

    member _.Url = url
    member _.Payload = payload
    member _.Checksum = checksum
    member _.Seen = seen.ToArray()

    member _.Count path =
        match counts.TryGetValue path with
        | true, value -> value
        | _ -> 0

    member _.Release() = hold.TrySetResult() |> ignore

    interface IDisposable with
        member _.Dispose() =
            stop.Cancel()
            accepting.GetAwaiter().GetResult()
            Task.WhenAll(jobs).GetAwaiter().GetResult()
            listener.Close()
            stop.Dispose()
