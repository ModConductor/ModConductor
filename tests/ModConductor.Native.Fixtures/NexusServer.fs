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
    let mutable payload = Array.init (1024 * 1024) (fun n -> byte (n % 251))
    let mutable downloadKey = "synthetic-signed-key-A"
    let mutable downloadBase = root
    let mutable payloadRedirect = None
    let mutable nxmRequests = 0
    let mutable apiKeyRequests = 0
    let mutable privateHeader = false
    let mutable ranges = 0
    let mutable slow = false
    let mutable metadata = false
    let mutable tracked = false
    let mutable endorsement = "Undecided"
    let mutable writes = 0
    let mutable metadataHold: TaskCompletionSource<unit> option = None
    let mutable lastVersion = ""
    let mutable premium = true
    let mutable skseFiles: (int64 * string * string * string) list = []
    let mutable fnisFiles: (int64 * string * string * string) list = []
    let mutable enbFiles: Map<int64, int64 * string * string * byte array> = Map.empty


    let sendAuthorize (request: HttpListenerRequest) (response: HttpListenerResponse) =
        task {
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
        }

    let sendToken (request: HttpListenerRequest) write =
        task {
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
        }

    let sendUserInfo (request: HttpListenerRequest) write =
        task {
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
                          + "\",\"name\":\"Rowan\",\"picture\":\"https://static.nexusmods.com/avatar.png\",\"membership_roles\":"
                          + (if premium then "[\"premium\"]" else "[]")
                          + "}"))
        }

    let sendDownloadLink (request: HttpListenerRequest) (path: string) write =
        task {
            if request.QueryString["key"] = "synthetic-nxm-private-grant" then
                nxmRequests <- nxmRequests + 1

            if
                mode = "nxm"
                && request.QueryString["key"] <> "synthetic-nxm-private-grant"
            then
                do! write 403 "{\"error\":\"synthetic-nxm-private-grant\"}"
            elif mode = "entitlement" then
                do! write 403 "{\"error\":\"synthetic-signed-secret\"}"
            elif mode = "malformed-download-link" then
                do! write 200 "[{\"URI\":\"not a URL\"}]"
            else
                do!
                    let modId =
                        path.Split('/')
                        |> Array.tryFindIndex ((=) "mods")
                        |> Option.bind (fun index ->
                            if index + 1 < path.Split('/').Length then
                                match Int64.TryParse(path.Split('/')[index + 1]) with
                                | true, value -> Some value
                                | _ -> None
                            else
                                None)

                    write
                        200
                        (("[{"
                          + "\"name\":\"Fixture CDN\",\"short_name\":\"fixture\",\"URI\":\""
                          + downloadBase
                          + "payload?mod="
                          + (modId |> Option.map string |> Option.defaultValue "")
                          + "&key="
                          + downloadKey
                          + "\"}"
                          + "]"))
        }

    let sendTracking (request: HttpListenerRequest) write =
        task {
            if request.HttpMethod = "GET" then
                do!
                    write
                        200
                        (if mode = "tracking-mixed" then
                             """[{"domain_name":"skyrimspecialedition","mod_id":64012},{"domain_name":"fallout4","mod_id":64012}]"""
                         elif tracked then
                             """[{"domain_name":"skyrimspecialedition","mod_id":64012}]"""
                         else
                             "[]")
            else
                writes <- writes + 1
                use body = new StreamReader(request.InputStream)
                let! content = body.ReadToEndAsync(stop.Token)
                use json = System.Text.Json.JsonDocument.Parse content

                if
                    json.RootElement.GetProperty("domain_name").GetString()
                    <> "skyrimspecialedition"
                    || json.RootElement.GetProperty("mod_id").GetInt64() <> 64012L
                then
                    failwith "Tracking identity differed."

                if mode = "write-refused" then
                    do! write 403 "{}"
                else
                    tracked <- request.HttpMethod = "POST"

                    do!
                        write
                            (if mode = "write-uncertain" then 202 else 200)
                            """{"message":"Updated"}"""
        }

    let sendEndorsements write =
        task {
            if mode = "endorsements-refused" then
                do! write 403 "{}"
            else
                do!
                    write
                        200
                        ("[{\"domain_name\":\"skyrimspecialedition\",\"mod_id\":64012,\"status\":\""
                         + endorsement
                         + "\"}]")
        }

    let sendEndorsement (request: HttpListenerRequest) (path: string) write =
        task {
            writes <- writes + 1
            use body = new StreamReader(request.InputStream)
            let! content = body.ReadToEndAsync(stop.Token)
            use json = System.Text.Json.JsonDocument.Parse content
            lastVersion <- json.RootElement.GetProperty("Version").GetString()

            if mode = "write-refused" then
                do! write 403 "{}"
            else
                endorsement <-
                    if path.EndsWith "/endorse.json" then
                        "Endorsed"
                    else
                        "Abstained"

                do! write 200 ("{\"status\":\"" + endorsement + "\"}")
        }

    let sendFiles (path: string) write =
        task {
            let file (id: int) (name: string) (category: string) =
                ("{"
                 + "\"file_id\":"
                 + (id).ToString(System.Globalization.CultureInfo.InvariantCulture)
                 + ",\"file_name\":\""
                 + name
                 + "\",\"version\":\"1.4\",\"category_name\":\""
                 + category
                 + "\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\"Adds river textures for Skyrim Special Edition.\",\"size_in_bytes\":"
                 + string payload.Length
                 + "}")

            let enbMod =
                enbFiles
                |> Map.toSeq
                |> Seq.map fst
                |> Seq.tryFind (fun modId ->
                    path.Contains("/mods/" + string modId + "/"))

            if enbMod.IsSome && path.EndsWith "/files.json" then
                let fileId, fileName, version, bytes = enbFiles[enbMod.Value]

                do!
                    write
                        200
                        ("{\"files\":[{\"file_id\":"
                         + string fileId
                         + ",\"file_name\":\""
                         + fileName
                         + "\",\"version\":\""
                         + version
                         + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\"ENB fixture\",\"size_in_bytes\":"
                         + string bytes.Length
                         + "}],\"file_updates\":[]}")
            elif enbMod.IsSome && path.Contains "/files/" && path.EndsWith ".json" then
                let fileId, fileName, version, bytes = enbFiles[enbMod.Value]

                do!
                    write
                        200
                        ("{\"file_id\":"
                         + string fileId
                         + ",\"file_name\":\""
                         + fileName
                         + "\",\"version\":\""
                         + version
                         + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\"ENB fixture\",\"size_in_bytes\":"
                         + string bytes.Length
                         + "}")
            elif path.Contains "/mods/30379/" && path.EndsWith "/files.json" then
                let entry
                    (id: int64, name: string, version: string, description: string)
                    =
                    "{\"file_id\":"
                    + id.ToString(Globalization.CultureInfo.InvariantCulture)
                    + ",\"file_name\":\""
                    + name
                    + "\",\"version\":\""
                    + version
                    + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\""
                    + description
                    + "\",\"size_in_bytes\":"
                    + payload.Length.ToString(
                        Globalization.CultureInfo.InvariantCulture
                    )
                    + "}"

                do!
                    write
                        200
                        ("{\"files\":["
                         + (skseFiles |> List.map entry |> String.concat ",")
                         + "],\"file_updates\":[]}")
            elif path.Contains "/mods/30379/files/" && path.EndsWith ".json" then
                let name = Path.GetFileNameWithoutExtension path

                if mode = "metadata-error" then
                    do! write 404 "{}"
                else
                    match Int64.TryParse name with
                    | true, id ->
                        match
                            skseFiles
                            |> List.tryFind (fun (value, _, _, _) -> value = id)
                        with
                        | Some(id, fileName, version, description) ->
                            do!
                                write
                                    200
                                    ("{\"file_id\":"
                                     + id.ToString(
                                         Globalization.CultureInfo.InvariantCulture
                                     )
                                     + ",\"file_name\":\""
                                     + fileName
                                     + "\",\"version\":\""
                                     + version
                                     + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\""
                                     + description
                                     + "\",\"size_in_bytes\":"
                                     + payload.Length.ToString(
                                         Globalization.CultureInfo.InvariantCulture
                                     )
                                     + "}")
                        | None -> do! write 404 "{}"
                    | _ -> do! write 404 "{}"
            elif path.Contains "/mods/3038/" && path.EndsWith "/files.json" then
                let entry
                    (id: int64, name: string, version: string, description: string)
                    =
                    "{\"file_id\":"
                    + string id
                    + ",\"file_name\":\""
                    + name
                    + "\",\"version\":\""
                    + version
                    + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\""
                    + description
                    + "\",\"size_in_bytes\":"
                    + (if mode = "null-size" && id = 7001L then
                           "null"
                       else
                           string payload.Length)
                    + "}"

                do!
                    write
                        200
                        ("{\"files\":["
                         + (fnisFiles |> List.map entry |> String.concat ",")
                         + "],\"file_updates\":[]}")
            elif path.Contains "/mods/3038/files/" && path.EndsWith ".json" then
                let name = Path.GetFileNameWithoutExtension path

                if mode = "metadata-error" then
                    do! write 404 "{}"
                else
                    match Int64.TryParse name with
                    | true, id ->
                        match
                            fnisFiles
                            |> List.tryFind (fun (value, _, _, _) -> value = id)
                        with
                        | Some(id, fileName, version, description) ->
                            do!
                                write
                                    200
                                    ("{\"file_id\":"
                                     + string id
                                     + ",\"file_name\":\""
                                     + fileName
                                     + "\",\"version\":\""
                                     + version
                                     + "\",\"category_name\":\"Main files\",\"category_id\":1,\"uploaded_timestamp\":1789238400,\"description\":\""
                                     + description
                                     + "\",\"size_in_bytes\":"
                                     + string payload.Length
                                     + "}")
                        | None -> do! write 404 "{}"
                    | _ -> do! write 404 "{}"
            elif metadata && path.EndsWith "/files.json" then
                let entry (id: int) (name: string) (version: string) (category: int) =
                    "{\"file_id\":"
                    + id.ToString(Globalization.CultureInfo.InvariantCulture)
                    + ",\"file_name\":\""
                    + name
                    + "\",\"version\":\""
                    + version
                    + "\",\"category_name\":\""
                    + (if category = 1 then "Main files"
                       elif category = 3 then "Optional files"
                       else "Old files")
                    + "\",\"category_id\":"
                    + category.ToString(Globalization.CultureInfo.InvariantCulture)
                    + ",\"uploaded_timestamp\":1789238400,\"description\":\"Water textures\",\"size_in_bytes\":"
                    + payload.Length.ToString(
                        Globalization.CultureInfo.InvariantCulture
                    )
                    + "}"

                do!
                    write
                        200
                        ("""{"files":["""
                         + entry 501 "Quiet rivers — full.zip" "1.4" 4
                         + ","
                         + entry 502 "Quiet rivers — full.zip" "1.5" 1
                         + ","
                         + entry 503 "River sounds patch.zip" "1.2" 3
                         + ","
                         + entry 504 "Quiet rivers — light.zip" "1.5" 3
                         + """],"file_updates":[{"old_file_id":501,"new_file_id":502},{"old_file_id":501,"new_file_id":504}]}""")
            elif path.EndsWith "/files.json" then
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
            elif metadata && path.EndsWith "/files/503.json" then
                do!
                    write
                        200
                        ("{\"file_id\":503,\"file_name\":\"River sounds patch.zip\",\"version\":\"1.2\",\"category_name\":\"Optional files\",\"category_id\":3,\"uploaded_timestamp\":1789238400,\"description\":\"Water textures\",\"size_in_bytes\":"
                         + payload.Length.ToString(Globalization.CultureInfo.InvariantCulture)
                         + "}")
            else
                do! write 404 "{}"
        }

    let sendApi (request: HttpListenerRequest) (path: string) (response: HttpListenerResponse) write =
        task {
            let apiKey = request.Headers["APIKEY"]
            let bearer = request.Headers["Authorization"]

            if not (isNull apiKey) then
                apiKeyRequests <- apiKeyRequests + 1

            let keyRevoked =
                mode = "invalid-key"
                || (mode = "invalid-tracking-key" && path.EndsWith "/user/tracked_mods.json")
                || (mode = "invalid-endorsement-key"
                    && path.EndsWith "/user/endorsements.json")

            if path.EndsWith "/users/validate.json" then
                if apiKey <> "synthetic-personal-key" || mode = "invalid-key" then
                    do! write 401 "{}"
                elif mode = "rate" then
                    response.Headers["Retry-After"] <- "15"
                    do! write 429 "{}"
                elif mode = "offline" then
                    do! write 503 "{}"
                else
                    do!
                        write
                            200
                            ("{\"user_id\":"
                             + subject
                             + ",\"key\":\"synthetic-personal-key\",\"name\":\"Rowan\",\"profile_url\":\"https://static.nexusmods.com/avatar.png\",\"is_premium\":"
                             + (if premium then "true" else "false")
                             + "}")
            elif
                (not (isNull apiKey) && (apiKey <> "synthetic-personal-key" || keyRevoked))
                || (isNull apiKey
                    && (isNull bearer
                        || not (bearer.StartsWith "Bearer synthetic-access-secret-")))
            then
                do! write 401 "{}"
            elif mode = "rate" then
                response.Headers["Retry-After"] <- "15"
                do! write 429 "{\"error\":\"synthetic-refresh-secret\"}"
            elif mode = "offline" then
                do! write 503 "{\"error\":\"synthetic-access-secret\"}"
            elif path.EndsWith "/download_link.json" then
                do! sendDownloadLink request path write
            elif path.EndsWith "/user/tracked_mods.json" then
                do! sendTracking request write
            elif path.EndsWith "/user/endorsements.json" then
                do! sendEndorsements write
            elif path.EndsWith "/mods/latest_added.json" then
                do!
                    write
                        200
                        """[{"domain_name":"skyrimspecialedition","mod_id":64012,"name":"Quiet Rivers","summary":"River textures","author":"Rowan","picture_url":"https://staticdelivery.nexusmods.com/river.jpg"},{"domain_name":"fallout4","mod_id":900,"name":"Other game"}]"""
            elif path.EndsWith "/mods/latest_updated.json" then
                do!
                    write
                        200
                        """[{"domain_name":"skyrimspecialedition","mod_id":64012,"name":"Quiet Rivers","summary":"River textures","author":"Rowan"}]"""
            elif path.EndsWith "/endorse.json" || path.EndsWith "/abstain.json" then
                do! sendEndorsement request path write
            elif path.EndsWith "/games/skyrimspecialedition.json" then
                do!
                    write
                        200
                        """{"id":1704,"domain_name":"skyrimspecialedition","categories":[{"category_id":29,"name":"Visuals and Graphics"}]}"""
            elif
                enbFiles
                |> Map.exists (fun modId _ ->
                    path.EndsWith("/mods/" + string modId + ".json"))
            then
                let modId =
                    enbFiles
                    |> Map.toSeq
                    |> Seq.map fst
                    |> Seq.find (fun modId ->
                        path.EndsWith("/mods/" + string modId + ".json"))

                do!
                    write
                        200
                        ("{\"mod_id\":"
                         + string modId
                         + ",\"game_id\":1704,\"name\":\"ENB fixture\",\"summary\":\"ENB fixture\",\"version\":\"fixture\",\"author\":\"fixture\",\"uploaded_by\":\"fixture\",\"category_id\":29,\"updated_timestamp\":1789238400,\"allow_rating\":true,\"available\":true}")
            elif path.EndsWith "/mods/30379.json" then
                match metadataHold with
                | Some hold -> do! hold.Task.WaitAsync(stop.Token)
                | None -> ()

                if mode = "metadata-error" then
                    do! write 404 "{}"
                else
                    do!
                        write
                            200
                            ("""{"mod_id":30379,"game_id":1704,"name":"Skyrim Script Extender","summary":"Fixture SKSE metadata","version":"fixture","author":"SKSE team","uploaded_by":"SKSE team","category_id":1,"updated_timestamp":1789238400,"allow_rating":true,"available":"""
                             + (if mode = "unavailable" then "false" else "true")
                             + "}")
            elif path.EndsWith "/mods/3038.json" then
                if mode = "metadata-error" then
                    do! write 404 "{}"
                else
                    do!
                        write
                            200
                            """{"mod_id":3038,"game_id":1704,"name":"FNIS Behavior SE","summary":"Fixture FNIS metadata","version":"7.6","author":"fore","uploaded_by":"fore","category_id":1,"updated_timestamp":1789238400,"allow_rating":true,"available":true}"""
            elif path.EndsWith "/mods/64012.json" then
                match metadataHold with
                | Some hold -> do! hold.Task.WaitAsync(stop.Token)
                | None -> ()

                if mode = "metadata-error" then
                    do! write 404 "{}"
                else
                    do!
                        write
                            200
                            ("""{"mod_id":64012,"game_id":1704,"name":"Quiet Rivers — Water and Foam","summary":"River textures","picture_url":"https://staticdelivery.nexusmods.com/river.jpg","version":"1.5","author":"Rowan","uploaded_by":"Rowan","category_id":29,"updated_timestamp":1789238400,"allow_rating":true,"available":"""
                             + (if mode = "unavailable" then "false" else "true")
                             + "}")
            else
                do! sendFiles path write
        }

    let sendPayload (request: HttpListenerRequest) (response: HttpListenerResponse) write =
        task {
            if payloadRedirect.IsSome then
                if
                    request.Headers["Authorization"] <> null
                    || request.Headers["APIKEY"] <> null
                    || request.Headers["Cookie"] <> null
                then
                    privateHeader <- true

                response.StatusCode <- 302

                response.RedirectLocation <-
                    payloadRedirect.Value + "payload" + request.Url.Query
            elif mode = "link-refused" then
                do! write 403 "{\"error\":\"synthetic-signed-key-expired\"}"
            else
                if
                    request.Headers["Authorization"] <> null
                    || request.Headers["APIKEY"] <> null
                    || request.Headers["Cookie"] <> null
                then
                    privateHeader <- true

                let selectedPayload =
                    match Int64.TryParse(request.QueryString["mod"]) with
                    | true, modId when enbFiles.ContainsKey modId ->
                        let _, _, _, bytes = enbFiles[modId]
                        bytes
                    | _ -> payload

                let range = request.Headers["Range"]

                let offset =
                    if isNull range then
                        0
                    else
                        ranges <- ranges + 1
                        Int32.Parse(range.Substring(6).TrimEnd('-'))

                response.StatusCode <- (if offset = 0 then 200 else 206)
                response.Headers["ETag"] <- "\"fixture-entity\""
                response.ContentLength64 <- int64 (selectedPayload.Length - offset)

                if offset > 0 then
                    response.Headers["Content-Range"] <-
                        ("bytes "
                         + (offset).ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + "-"
                         + (selectedPayload.Length - 1)
                             .ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + "/"
                         + (selectedPayload.Length)
                             .ToString(System.Globalization.CultureInfo.InvariantCulture))

                for start in [ offset..16384 .. selectedPayload.Length - 1 ] do
                    do!
                        response.OutputStream.WriteAsync(
                            selectedPayload.AsMemory(
                                start,
                                min 16384 (selectedPayload.Length - start)
                            ),
                            stop.Token
                        )

                    do! response.OutputStream.FlushAsync(stop.Token)

                    if slow then
                        do! Task.Delay(100, stop.Token)
        }

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
                    do! sendAuthorize request response
                elif path = "/token" then
                    do! sendToken request write
                elif path = "/userinfo" then
                    do! sendUserInfo request write
                elif path.StartsWith "/api/" then
                    do! sendApi request path response write
                elif path = "/v3/games/skyrimspecialedition/trending-mods" then
                    if mode = "trending-unavailable" then
                        do! write 404 "{}"
                    elif mode = "trending-empty" then
                        do! write 200 """{"data":{"mods":[]}}"""
                    else
                        do!
                            write
                                200
                                """{"data":{"mods":[{"name":"Quiet Rivers","author":"Rowan","summary":"River textures","picture_url":"https://staticdelivery.nexusmods.com/river.jpg","mod_page_url":"https://www.nexusmods.com/games/skyrimspecialedition/mods/64012"},{"name":"Other game","mod_page_url":"https://www.nexusmods.com/games/fallout4/mods/99"}]}}"""
                elif path = "/payload" then
                    do! sendPayload request response write
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
          RedirectPort = 0 }

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

    member _.Premium
        with get () = premium
        and set value = premium <- value

    member _.SkseFiles
        with get () = skseFiles
        and set value = skseFiles <- value

    member _.FnisFiles
        with get () = fnisFiles
        and set value = fnisFiles <- value

    member _.EnbFiles
        with get () = enbFiles
        and set value = enbFiles <- value

    member _.TokenSeconds
        with set value = expires <- value

    member _.Slow
        with set value = slow <- value

    member _.DownloadKey
        with set value = downloadKey <- value

    member _.DownloadBase
        with set value = downloadBase <- value

    member _.PayloadRedirect
        with set value = payloadRedirect <- Some value

    member _.Metadata
        with set value = metadata <- value

    member _.Tracked
        with set value = tracked <- value

    member _.Payload
        with set value = payload <- value

    member _.Writes = writes
    member _.LastVersion = lastVersion

    member _.HoldMetadata() =
        let value =
            TaskCompletionSource<unit>(TaskCreationOptions.RunContinuationsAsynchronously)

        metadataHold <- Some value
        value

    member _.ReleaseMetadata() =
        metadataHold |> Option.iter (fun hold -> hold.TrySetResult(()) |> ignore)
        metadataHold <- None

    member _.TokenCount = tokenCount

    member _.Count path =
        match counts.TryGetValue path with
        | true, n -> n
        | _ -> 0

    member _.NxmRequests = nxmRequests
    member _.ApiKeyRequests = apiKeyRequests
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
