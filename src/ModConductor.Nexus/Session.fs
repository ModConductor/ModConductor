namespace ModConductor.Nexus

open System
open System.Security.Cryptography
open System.Collections.Generic
open System.Text
open System.Text.Json
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials

type NexusSession
    (
        credentials: CredentialSession,
        registration: NexusRegistration option,
        handoff: IOAuthHandoff,
        pauseDownloads: string -> Task,
        ?requestInterval: TimeSpan
    ) =
    do registration |> Option.iter Registration.validate
    let gate = obj ()
    let commit = new SemaphoreSlim(1, 1)
    let refreshGate = new SemaphoreSlim(1, 1)

    let transport =
        registration
        |> Option.map (fun value ->
            new NexusTransport(value, defaultArg requestInterval (TimeSpan.FromSeconds 1.)))

    let mutable lifetime = new CancellationTokenSource()
    let mutable generation = 0L
    let mutable account: Account option = None
    let mutable boundSubject: string option = None
    let mutable tokens: NexusJson.Tokens option = None
    let mutable waiting = false
    let mutable disconnecting = false
    let mutable problem = None
    let mutable signIn: Task = Task.CompletedTask
    let nxm = NxmAuthorizations()

    let nxmExpiry =
        new Timer(
            TimerCallback(fun _ -> lock gate (fun () -> nxm.Expire())),
            null,
            TimeSpan.FromSeconds 30.,
            TimeSpan.FromSeconds 30.
        )

    let leases = Dictionary<string * int64 * int64 * string, DownloadLease>()

    let configured () =
        registration
        |> Option.defaultWith (fun () -> raise (NexusException NexusProblem.NotConfigured))

    let status () =
        lock gate (fun () ->
            { Configured = registration.IsSome
              Waiting = waiting
              Account = account
              Problem = problem })

    let context () =
        lock gate (fun () -> generation, lifetime.Token)

    let current epoch =
        lock gate (fun () -> generation = epoch)

    let fail epoch error =
        lock gate (fun () ->
            if generation = epoch then
                problem <- Some error
                waiting <- false

                if error = NexusProblem.SignInRequired || error = NexusProblem.AccountChanged then
                    tokens <- None
                    account <- None)

    let require epoch (token: CancellationToken) =
        token.ThrowIfCancellationRequested()

        if not (current epoch) then
            raise (OperationCanceledException())

    let publish epoch (value: NexusJson.Tokens) expected token =
        task {
            let config = configured ()
            use! response = transport.Value.UserInfo(value.Access, token)
            let identity = NexusJson.account response.RootElement

            if expected |> Option.exists ((<>) identity.Subject) then
                raise (NexusException NexusProblem.AccountChanged)

            let packet =
                NexusJson.writeSaved
                    { Issuer = config.Issuer.AbsoluteUri
                      Client = config.ClientId
                      Subject = identity.Subject
                      Refresh = value.Refresh }

            try
                do! commit.WaitAsync token

                try
                    require epoch token
                    let! saved = credentials.Save(packet, token)

                    match saved with
                    | Error error -> raise (NexusException(NexusProblem.Storage error))
                    | Ok() ->
                        lock gate (fun () ->
                            require epoch token
                            account <- Some identity
                            boundSubject <- Some identity.Subject
                            tokens <- Some value
                            waiting <- false
                            problem <- None)
                finally
                    commit.Release() |> ignore
            finally
                CryptographicOperations.ZeroMemory packet
        }

    let refresh epoch token =
        task {
            let config = configured ()
            let! read = credentials.Read token

            let bytes =
                match read with
                | Ok(Some bytes) -> bytes
                | Ok None -> raise (NexusException NexusProblem.SignInRequired)
                | Error error -> raise (NexusException(NexusProblem.Storage error))

            let saved =
                try
                    use document = JsonDocument.Parse(ReadOnlyMemory bytes)
                    NexusJson.saved document.RootElement
                finally
                    CryptographicOperations.ZeroMemory bytes

            if saved.Issuer <> config.Issuer.AbsoluteUri || saved.Client <> config.ClientId then
                raise (NexusException NexusProblem.SignInRequired)

            let existing = lock gate (fun () -> boundSubject)

            if existing |> Option.exists ((<>) saved.Subject) then
                raise (NexusException NexusProblem.AccountChanged)

            lock gate (fun () ->
                require epoch token
                boundSubject <- Some saved.Subject)

            use! reply =
                transport.Value.Token(
                    [ "grant_type", "refresh_token"
                      "refresh_token", saved.Refresh
                      "client_id", config.ClientId ],
                    token
                )

            let value = NexusJson.tokens (Some saved.Refresh) reply.RootElement
            do! publish epoch value (Some saved.Subject) token
            return value.Access
        }

    let access epoch (token: CancellationToken) force =
        task {
            do! refreshGate.WaitAsync token

            try
                require epoch token

                match lock gate (fun () -> tokens) with
                | Some value when not force && value.Expires > DateTimeOffset.UtcNow.AddSeconds 30. ->
                    return value.Access
                | None when not force -> return raise (NexusException NexusProblem.SignInRequired)
                | _ -> return! refresh epoch token
            finally
                refreshGate.Release() |> ignore
        }

    let run action =
        task {
            let epoch, token = context ()

            let! result =
                NexusBoundary.protect (fun () ->
                    task {
                        configured () |> ignore

                        if lock gate (fun () -> disconnecting) then
                            raise (NexusException NexusProblem.SignInRequired)

                        let! value = action epoch token
                        require epoch token
                        return value
                    })

            match result with
            | Error error -> fail epoch error
            | Ok _ -> ()

            return result
        }

    member _.Status = status ()

    member _.SignIn() =
        task {
            match registration with
            | None -> lock gate (fun () -> problem <- Some NexusProblem.NotConfigured)
            | Some config ->
                let attempt =
                    lock gate (fun () ->
                        if waiting || disconnecting || account.IsSome then
                            None
                        else
                            waiting <- true
                            problem <- None
                            Some(generation, lifetime.Token))

                match attempt with
                | None -> ()
                | Some(epoch, token) ->
                    let pending =
                        task {
                            use expiry = CancellationTokenSource.CreateLinkedTokenSource token
                            expiry.CancelAfter(TimeSpan.FromMinutes 10.)

                            let! result =
                                NexusBoundary.protect (fun () ->
                                    task {
                                        let token = expiry.Token

                                        let random () =
                                            Convert
                                                .ToBase64String(RandomNumberGenerator.GetBytes 32)
                                                .TrimEnd('=')
                                                .Replace('+', '-')
                                                .Replace('/', '_')

                                        let verifier = random ()
                                        let state = random ()

                                        let challenge =
                                            Convert
                                                .ToBase64String(
                                                    SHA256.HashData(
                                                        Encoding.ASCII.GetBytes verifier
                                                    )
                                                )
                                                .TrimEnd('=')
                                                .Replace('+', '-')
                                                .Replace('/', '_')

                                        let! listener = handoff.Listen(config, token)

                                        try
                                            let redirect = listener.Redirect

                                            if
                                                redirect.Scheme <> "http"
                                                || redirect.Host <> "127.0.0.1"
                                                || redirect.AbsolutePath <> config.RedirectPath
                                                || (config.RedirectPort <> 0
                                                    && redirect.Port <> config.RedirectPort)
                                            then
                                                raise (NexusException NexusProblem.InvalidCallback)

                                            let query =
                                                [ "response_type", "code"
                                                  "client_id", config.ClientId
                                                  "redirect_uri", redirect.AbsoluteUri
                                                  "scope", String.concat " " config.Scopes
                                                  "state", state
                                                  "code_challenge", challenge
                                                  "code_challenge_method", "S256" ]
                                                |> List.map (fun (k, v) ->
                                                    Uri.EscapeDataString k
                                                    + "="
                                                    + Uri.EscapeDataString v)
                                                |> String.concat "&"

                                            let uri = UriBuilder config.Authorize
                                            uri.Query <- query
                                            do! handoff.Open(uri.Uri, token)
                                            let! callback = listener.Wait token

                                            let callback =
                                                match callback with
                                                | Ok value -> value
                                                | Error error -> raise (NexusException error)

                                            if
                                                callback.State <> state
                                                || String.IsNullOrWhiteSpace callback.Code
                                                || (callback.Issuer
                                                    |> Option.exists (
                                                        (<>) config.Issuer.AbsoluteUri
                                                    ))
                                            then
                                                raise (NexusException NexusProblem.InvalidCallback)

                                            use! reply =
                                                transport.Value.Token(
                                                    [ "grant_type", "authorization_code"
                                                      "code", callback.Code
                                                      "client_id", config.ClientId
                                                      "redirect_uri", redirect.AbsoluteUri
                                                      "code_verifier", verifier ],
                                                    token
                                                )

                                            do!
                                                publish
                                                    epoch
                                                    (NexusJson.tokens None reply.RootElement)
                                                    (lock gate (fun () -> boundSubject))
                                                    token
                                        finally
                                            listener
                                                .DisposeAsync()
                                                .AsTask()
                                                .GetAwaiter()
                                                .GetResult()
                                    })

                            match result with
                            | Error error -> fail epoch error
                            | Ok() -> ()
                        }

                    lock gate (fun () -> signIn <- pending)

            return status ()
        }

    member _.Connect() =
        task {
            let! _ = run (fun epoch token -> access epoch token true)
            return status ()
        }

    member _.CheckAccount() =
        task {
            let! _ =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false
                        use! response = transport.Value.UserInfo(bearer, token)
                        let value = NexusJson.account response.RootElement

                        lock gate (fun () ->
                            require epoch token

                            if
                                account
                                |> Option.exists (fun prior -> prior.Subject <> value.Subject)
                            then
                                raise (NexusException NexusProblem.AccountChanged)

                            account <- Some value
                            problem <- None)
                    })

            return status ()
        }

    member _.CancelSignIn() =
        task {
            let pending =
                lock gate (fun () ->
                    if waiting then
                        generation <- generation + 1L
                        lifetime.Cancel()
                        lifetime.Dispose()
                        lifetime <- new CancellationTokenSource()
                        waiting <- false
                        problem <- None

                    signIn)

            do! pending
            return status ()
        }

    member _.Disconnect(token: CancellationToken) =
        task {
            let subject, pending, epoch =
                lock gate (fun () ->
                    let subject = boundSubject
                    disconnecting <- true
                    generation <- generation + 1L
                    lifetime.Cancel()
                    lifetime.Dispose()
                    lifetime <- new CancellationTokenSource()
                    account <- None
                    leases.Clear()
                    nxm.Clear()
                    boundSubject <- None
                    tokens <- None
                    waiting <- false
                    problem <- None
                    subject, signIn, generation)
            // Invalidating work precedes storage removal; an in-flight save holds the same commit gate.
            do! commit.WaitAsync()

            try
                match subject with
                | Some value -> do! pauseDownloads value
                | None -> ()

                let! result = credentials.Remove token
                do! pending
                return result
            finally
                lock gate (fun () ->
                    if generation = epoch then
                        disconnecting <- false)

                commit.Release() |> ignore
        }

    member _.ReadMod(game: string, modId: int64) =
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false

                use! gameReply =
                    transport.Value.Api(("games/" + game + ".json"), bearer, false, token)

                if NexusJson.text "domain_name" gameReply.RootElement <> game then
                    NexusJson.fail ()

                use! modReply =
                    transport.Value.Api(
                        ("games/"
                         + game
                         + "/mods/"
                         + (modId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + ".json"),
                        bearer,
                        false,
                        token
                    )

                let value = modReply.RootElement

                if
                    NexusJson.number "mod_id" value <> modId
                    || NexusJson.number "game_id" value
                       <> NexusJson.number "id" gameReply.RootElement
                then
                    NexusJson.fail ()

                use! filesReply =
                    transport.Value.Api(
                        ("games/"
                         + game
                         + "/mods/"
                         + (modId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + "/files.json"),
                        bearer,
                        false,
                        token
                    )

                let files =
                    NexusJson.field "files" filesReply.RootElement
                    |> Option.defaultWith NexusJson.fail

                return
                    { Game = game
                      Id = modId
                      Name = NexusJson.text "name" value
                      Summary = NexusJson.optionalText "summary" value |> Option.defaultValue ""
                      Files = files.EnumerateArray() |> Seq.map NexusJson.file |> Seq.toList }
            })

    member _.ReadFile(game: string, modId: int64, fileId: int64) =
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false

                use! reply =
                    transport.Value.Api(
                        ("games/"
                         + game
                         + "/mods/"
                         + (modId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + "/files/"
                         + (fileId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                         + ".json"),
                        bearer,
                        false,
                        token
                    )

                let file = NexusJson.file reply.RootElement

                if file.Id <> fileId then
                    NexusJson.fail ()

                return file
            })

    member _.AcceptNxm(id, input) =
        lock gate (fun () -> nxm.Accept(id, input))

    member _.ReadNxm id =
        lock gate (fun () -> nxm.Read id |> Result.map (fun link -> link.File))

    member _.ValidateNxm(id, subject) =
        lock gate (fun () -> nxm.Validate(id, subject) |> Result.map (fun link -> link.File))

    member _.AdmitNxm(id, subject) =
        lock gate (fun () ->
            let epoch = generation

            if account |> Option.forall (fun value -> value.Subject <> subject) then
                Error Nxm.mismatch
            else
                nxm.Admit(id, subject)
                |> Result.map (fun (file, cancel) ->
                    if file.Keyed then
                        leases.Remove((file.Game, file.ModId, file.FileId, subject)) |> ignore

                    new NxmAdmission(
                        file,
                        fun () ->
                            lock gate (fun () ->
                                if
                                    epoch = generation && not lifetime.IsCancellationRequested
                                then
                                    cancel ())
                    )))

    member _.DismissNxm id = lock gate (fun () -> nxm.Dismiss id)

    member _.Resolve
        (game: string, modId: int64, fileId: int64, subject: string, ?requiresLink: bool)
        =
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false

                if
                    lock gate (fun () ->
                        account |> Option.forall (fun value -> value.Subject <> subject))
                then
                    raise (NexusException NexusProblem.DownloadAccount)

                let key = game, modId, fileId, subject

                let grant = lock gate (fun () -> nxm.Grant key)

                if defaultArg requiresLink false && grant.IsNone then
                    raise (NexusException NexusProblem.DownloadLinkNeeded)

                let query =
                    grant
                    |> Option.map (fun g ->
                        "?key="
                        + Uri.EscapeDataString g.Key
                        + "&expires="
                        + g.Expires
                            .ToUnixTimeSeconds()
                            .ToString(System.Globalization.CultureInfo.InvariantCulture))
                    |> Option.defaultValue ""

                let cached =
                    lock gate (fun () ->
                        leases
                        |> Seq.filter (fun entry -> entry.Value.Expires <= DateTimeOffset.UtcNow)
                        |> Seq.map (fun entry -> entry.Key)
                        |> Seq.toArray
                        |> Array.iter (fun key -> leases.Remove key |> ignore)

                        match leases.TryGetValue key with
                        | true, value -> Some value
                        | _ -> None)

                match cached with
                | Some value -> return value
                | None ->
                    use! reply =
                        transport.Value.Api(
                            ("games/"
                             + game
                             + "/mods/"
                             + (modId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                             + "/files/"
                             + (fileId).ToString(System.Globalization.CultureInfo.InvariantCulture)
                             + "/download_link.json"
                             + query),
                            bearer,
                            true,
                            token
                        )

                    let first =
                        reply.RootElement.EnumerateArray()
                        |> Seq.tryHead
                        |> Option.defaultWith NexusJson.fail

                    let url = Uri(NexusJson.text "URI" first, UriKind.Absolute)
                    let config = configured ()

                    if
                        url.UserInfo <> ""
                        || url.Fragment <> ""
                        || not (
                            config.DownloadOrigins
                            |> List.exists (fun origin ->
                                origin.GetLeftPart(UriPartial.Authority) = url.GetLeftPart(
                                    UriPartial.Authority
                                ))
                        )
                    then
                        NexusJson.fail ()

                    let lease =
                        { Url = url
                          Expires = DateTimeOffset.UtcNow.AddSeconds 60. }

                    lock gate (fun () ->
                        require epoch token
                        leases[key] <- lease)

                    return lease
            })

    member _.RejectLease(game, modId, fileId, subject, url) =
        lock gate (fun () ->
            let key = game, modId, fileId, subject

            match leases.TryGetValue key with
            | true, lease when lease.Url = url -> leases.Remove key |> ignore
            | _ -> ())

    member _.DownloadOrigins =
        registration
        |> Option.map (fun value -> value.DownloadOrigins)
        |> Option.defaultValue []

    member _.Stop() =
        task {
            let pending =
                lock gate (fun () ->
                    lifetime.Cancel()
                    tokens <- None
                    leases.Clear()
                    nxm.Clear()
                    signIn)

            do! pending
            do! refreshGate.WaitAsync()
            refreshGate.Release() |> ignore
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()
            transport |> Option.iter (fun value -> (value :> IDisposable).Dispose())
            nxmExpiry.Dispose()
            lifetime.Dispose()
            refreshGate.Dispose()
            commit.Dispose()
