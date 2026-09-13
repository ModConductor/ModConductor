namespace ModConductor.Native.Fixtures

open System
open System.Collections.Concurrent
open System.IO
open System.Net
open System.Net.Http
open System.Net.Sockets
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks
open Microsoft.AspNetCore.WebUtilities
open ModConductor.Nexus
open ModConductor.Engine

/// Isolated HTTP fixtures model the observed Nexus OAuth reply, not OIDC ID tokens.
type NexusServer() =
    let probe = new TcpListener(IPAddress.Loopback, 0)
    do probe.Start()
    let port = (probe.LocalEndpoint :?> IPEndPoint).Port
    do probe.Stop()

    let root =
        ("http://127.0.0.1:"
         + (port).ToString(System.Globalization.CultureInfo.InvariantCulture)
         + "/")

    let listener = new HttpListener()
    let stop = new CancellationTokenSource()
    let jobs = ConcurrentBag<Task>()
    let counts = ConcurrentDictionary<string, int>()
    let mutable mode = "good"
    let mutable challenge = ""
    let mutable redirect = ""
    let mutable tokenCount = 0
    let mutable expires = 600
    let mutable subject = "42"
    let mutable held: TaskCompletionSource<unit> option = None
    let payload = Array.init (1024 * 1024) (fun n -> byte (n % 251))
    let mutable downloadKey = "synthetic-signed-key-A"
    let mutable privateHeader = false
    let mutable ranges = 0
    let mutable slow = false

    let send (context: HttpListenerContext) =
        task {
            use response = context.Response

            try
                let request = context.Request
                let path = request.Url.AbsolutePath
                counts.AddOrUpdate(path, 1, fun _ n -> n + 1) |> ignore

                let write code text =
                    task {
                        response.StatusCode <- code
                        response.ContentType <- "application/json"
                        let bytes = Encoding.UTF8.GetBytes(text: string)
                        response.ContentLength64 <- int64 bytes.Length
                        do! response.OutputStream.WriteAsync(ReadOnlyMemory bytes, stop.Token)
                    }

                if path = "/authorize" then
                    let q = request.QueryString
                    challenge <- q["code_challenge"]
                    redirect <- q["redirect_uri"]

                    if q["code_challenge_method"] <> "S256" || q["response_type"] <> "code" then
                        failwith "PKCE request differed."

                    let state = if mode = "state" then "wrong-state" else q["state"]
                    let issuer = if mode = "issuer" then "https://wrong.invalid/" else root
                    response.StatusCode <- 302

                    response.RedirectLocation <-
                        (if mode = "redirect" then
                             redirect.Replace("/oauth/callback", "/wrong-path")
                         else
                             redirect)
                        + "?code=synthetic-code&state="
                        + Uri.EscapeDataString(state)
                        + "&iss="
                        + Uri.EscapeDataString(issuer)
                        + (if mode = "duplicate" then "&state=duplicate" else "")
                elif path = "/token" then
                    use reader = new StreamReader(request.InputStream)
                    let! body = reader.ReadToEndAsync(stop.Token)
                    let fields = QueryHelpers.ParseQuery body

                    if fields["grant_type"].ToString() = "authorization_code" then
                        let verifier = fields["code_verifier"].ToString()

                        let actual =
                            Convert
                                .ToBase64String(SHA256.HashData(Encoding.ASCII.GetBytes verifier))
                                .TrimEnd('=')
                                .Replace('+', '-')
                                .Replace('/', '_')

                        if
                            actual <> challenge
                            || fields["redirect_uri"].ToString() <> redirect
                            || fields["code"].ToString() <> "synthetic-code"
                        then
                            failwith "Code or verifier binding differed."

                    tokenCount <- tokenCount + 1

                    match held with
                    | Some hold -> do! hold.Task.WaitAsync(stop.Token)
                    | None -> ()

                    if mode = "token-uncertain" then
                        do!
                            write
                                503
                                "{\"error\":\"synthetic-access-secret request=https://signed.invalid/?key=secret\"}"
                    else
                        do!
                            write
                                200
                                (("{"
                                  + "\"access_token\":\"synthetic-access-secret-"
                                  + (tokenCount)
                                      .ToString(System.Globalization.CultureInfo.InvariantCulture)
                                  + "\",\"refresh_token\":\"synthetic-refresh-secret-"
                                  + (tokenCount)
                                      .ToString(System.Globalization.CultureInfo.InvariantCulture)
                                  + "\",\"token_type\":\"Bearer\",\"expires_in\":"
                                  + (expires)
                                      .ToString(System.Globalization.CultureInfo.InvariantCulture)
                                  + ",\"created_at\":1789257600,\"scope\":\"public\"}"))

                        expires <- 600
                elif path = "/userinfo" then
                    if
                        not (
                            (request.Headers["Authorization"]
                             |> Option.ofObj
                             |> Option.defaultValue "")
                                .StartsWith
                                "Bearer synthetic-access-secret-"
                        )
                    then
                        do! write 401 "{}"
                    elif mode = "userinfo-error" then
                        do!
                            write
                                503
                                "{\"error\":\"synthetic-access-secret https://signed.invalid/?key=secret\"}"
                    else
                        do!
                            write
                                200
                                (("{"
                                  + "\"sub\":\""
                                  + subject
                                  + "\",\"name\":\"Rowan\",\"membership_roles\":[\"premium\"]}"))
                elif path.StartsWith "/api/" then
                    if mode = "rate" then
                        response.Headers["Retry-After"] <- "15"
                        do! write 429 "{\"error\":\"synthetic-refresh-secret\"}"
                    elif mode = "offline" then
                        do! write 503 "{\"error\":\"synthetic-access-secret\"}"
                    elif path.EndsWith "/download_link.json" then
                        if mode = "entitlement" then
                            do! write 403 "{\"error\":\"synthetic-signed-secret\"}"
                        else
                            do!
                                write
                                    200
                                    (("[{"
                                      + "\"name\":\"Fixture CDN\",\"short_name\":\"fixture\",\"URI\":\""
                                      + root
                                      + "payload?key="
                                      + downloadKey
                                      + "\"}"
                                      + "]"))
                    elif path.EndsWith "/games/skyrimspecialedition.json" then
                        do! write 200 "{\"id\":1704,\"domain_name\":\"skyrimspecialedition\"}"
                    elif path.EndsWith "/mods/64012.json" then
                        do!
                            write
                                200
                                "{\"mod_id\":64012,\"game_id\":1704,\"name\":\"Quiet rivers\",\"summary\":\"River textures\"}"
                    else
                        let file (id: int) (name: string) (category: string) =
                            ("{"
                             + "\"file_id\":"
                             + (id).ToString(System.Globalization.CultureInfo.InvariantCulture)
                             + ",\"file_name\":\""
                             + name
                             + "\",\"version\":\"1.4\",\"category_name\":\""
                             + category
                             + "\",\"description\":\"Adds river textures for Skyrim Special Edition.\",\"size_in_bytes\":1048576}")

                        if path.EndsWith "/files.json" then
                            do!
                                write
                                    200
                                    ("{\"files\":["
                                     + file 501 "Quiet rivers.7z" "Main files"
                                     + ","
                                     + file 502 "River foam.7z" "Optional files"
                                     + ","
                                     + file 503 "Landscape patch.zip" "Optional files"
                                     + "]}")
                        elif path.EndsWith "/files/501.json" then
                            do! write 200 (file 501 "Quiet rivers.7z" "Main files")
                        else
                            do! write 404 "{}"
                elif path = "/payload" && mode = "link-refused" then
                    do! write 403 "{\"error\":\"synthetic-signed-key-expired\"}"
                elif path = "/payload" then
                    if
                        request.Headers["Authorization"] <> null
                        || request.Headers["Cookie"] <> null
                    then
                        privateHeader <- true

                    let range = request.Headers["Range"]

                    let offset =
                        if isNull range then
                            0
                        else
                            ranges <- ranges + 1
                            Int32.Parse(range.Substring(6).TrimEnd('-'))

                    response.StatusCode <- (if offset = 0 then 200 else 206)
                    response.Headers["ETag"] <- "\"fixture-entity\""
                    response.ContentLength64 <- int64 (payload.Length - offset)

                    if offset > 0 then
                        response.Headers["Content-Range"] <-
                            ("bytes "
                             + (offset).ToString(System.Globalization.CultureInfo.InvariantCulture)
                             + "-"
                             + (payload.Length - 1)
                                 .ToString(System.Globalization.CultureInfo.InvariantCulture)
                             + "/"
                             + (payload.Length)
                                 .ToString(System.Globalization.CultureInfo.InvariantCulture))

                    for start in [ offset..16384 .. payload.Length - 1 ] do
                        do!
                            response.OutputStream.WriteAsync(
                                payload.AsMemory(start, min 16384 (payload.Length - start)),
                                stop.Token
                            )

                        do! response.OutputStream.FlushAsync(stop.Token)

                        if slow then
                            do! Task.Delay(100, stop.Token)
                elif path = "/fixture/mode" then
                    mode <- request.QueryString["value"]
                    slow <- mode = "slow"
                    do! write 200 "{}"
                else
                    do! write 404 "{}"
            with
            | :? HttpListenerException
            | :? IOException
            | :? OperationCanceledException -> ()

        }

    do
        listener.Prefixes.Add root
        listener.Start()

    let loop =
        task {
            try
                while not stop.IsCancellationRequested do
                    let! context = listener.GetContextAsync().WaitAsync(stop.Token)
                    let job = send context
                    jobs.Add(job)
            with :? OperationCanceledException ->
                ()
        }

    member _.Registration =
        { Issuer = Uri root
          Authorize = Uri(root + "authorize")
          Token = Uri(root + "token")
          UserInfo = Uri(root + "userinfo")
          Api = Uri(root + "api/")
          ClientId = "isolated-fixture-client"
          Scopes = [ "openid"; "profile" ]
          RedirectPath = "/oauth/callback"
          RedirectPort = 0
          DownloadOrigins = [ Uri root ] }

    member _.Handoff: IOAuthHandoff =
        OAuthHandoff(fun (uri, token) ->
            task {
                if uri.Host = "127.0.0.1" then
                    use client = new HttpClient()
                    use! response = client.GetAsync(uri, token)
                    response.EnsureSuccessStatusCode() |> ignore
            })

    member _.Mode
        with get () = mode
        and set value = mode <- value

    member _.Subject
        with get () = subject
        and set value = subject <- value

    member _.TokenSeconds
        with set value = expires <- value

    member _.Slow
        with set value = slow <- value

    member _.DownloadKey
        with set value = downloadKey <- value

    member _.TokenCount = tokenCount

    member _.Count path =
        match counts.TryGetValue path with
        | true, n -> n
        | _ -> 0

    member _.PrivateHeader = privateHeader
    member _.Ranges = ranges
    member _.Root = root

    member _.HoldToken() =
        let value =
            TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

        held <- Some value
        value

    interface IDisposable with
        member _.Dispose() =
            stop.Cancel()
            listener.Close()
            loop.GetAwaiter().GetResult()
            Task.WhenAll(jobs.ToArray()).GetAwaiter().GetResult()
            stop.Dispose()
