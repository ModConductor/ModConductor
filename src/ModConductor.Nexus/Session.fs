namespace ModConductor.Nexus

open System
open System.Security.Cryptography
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

    let api =
        registration
        |> Option.map _.Api
        |> Option.defaultValue (Uri "https://api.nexusmods.com/v1/")

    let transport =
        new NexusTransport(api, defaultArg requestInterval (TimeSpan.FromSeconds 1.))

    let metadata = MetadataReader(transport)

    let mutable lifetime = new CancellationTokenSource()
    let mutable generation = 0L
    let mutable account: Account option = None
    let mutable boundSubject: string option = None
    let mutable tokens: NexusJson.Tokens option = None
    let mutable authorization: NexusAuthorization option = None
    let mutable waiting = false
    let mutable disconnecting = false
    let mutable problem = None
    let mutable signIn: Task = Task.CompletedTask
    let mutable savedConnection: Task = Task.CompletedTask
    let mutable statusRevision = 0L

    let mutable statusChanged =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let interactions = InteractionMemory()

    let nxm =
        new NxmIngress(
            gate,
            (fun () -> account |> Option.map _.Subject),
            (fun () -> generation, lifetime.IsCancellationRequested)
        )

    let configured () =
        registration
        |> Option.defaultWith (fun () -> raise (NexusException NexusProblem.NotConfigured))

    let statusUnsafe () =
        { Configured = registration.IsSome
          Waiting = waiting
          Account = account
          Problem = problem }

    let status () = lock gate (fun () -> statusUnsafe ())

    let changed () =
        let previous = statusChanged
        statusRevision <- statusRevision + 1L
        statusChanged <- TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
        previous.TrySetResult() |> ignore

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
                    authorization <- None
                    account <- None
                    interactions.Clear()

                if error = NexusProblem.InvalidApiKey then
                    authorization <- None
                    account <- None
                    interactions.Clear()

                changed ())

    let require epoch (token: CancellationToken) =
        token.ThrowIfCancellationRequested()

        if not (current epoch) then
            raise (OperationCanceledException())

    let downloads =
        DownloadLeases(
            gate,
            transport,
            require,
            (fun key -> nxm.Grant key),
            (fun () -> account |> Option.map _.Subject)
        )

    let publish epoch (value: NexusJson.Tokens) expected token =
        task {
            let config = configured ()
            use! response = transport.UserInfo(config.UserInfo, value.Access, token)
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
                            authorization <- Some(NexusAuthorization.OAuth value.Access)
                            waiting <- false
                            problem <- None
                            changed ())
                finally
                    commit.Release() |> ignore
            finally
                CryptographicOperations.ZeroMemory packet
        }

    let restore epoch token =
        task {
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

            match saved with
            | NexusJson.SavedCredential.OAuth saved ->
                let config = configured ()

                if saved.Issuer <> config.Issuer.AbsoluteUri || saved.Client <> config.ClientId then
                    raise (NexusException NexusProblem.SignInRequired)

                let existing = lock gate (fun () -> boundSubject)

                if existing |> Option.exists ((<>) saved.Subject) then
                    raise (NexusException NexusProblem.AccountChanged)

                lock gate (fun () ->
                    require epoch token
                    boundSubject <- Some saved.Subject)

                use! reply =
                    transport.Token(
                        config.Token,
                        [ "grant_type", "refresh_token"
                          "refresh_token", saved.Refresh
                          "client_id", config.ClientId ],
                        token
                    )

                let value = NexusJson.tokens (Some saved.Refresh) reply.RootElement
                do! publish epoch value (Some saved.Subject) token
                return NexusAuthorization.OAuth value.Access
            | NexusJson.SavedCredential.PersonalApiKey(savedSubject, key) ->
                use! response = transport.ValidatePersonalApiKey(key, token)
                let identity = NexusJson.apiKeyAccount response.RootElement

                if identity.Subject <> savedSubject then
                    raise (NexusException NexusProblem.AccountChanged)

                return
                    lock gate (fun () ->
                        require epoch token
                        let value = NexusAuthorization.PersonalApiKey key
                        account <- Some identity
                        boundSubject <- Some identity.Subject
                        tokens <- None
                        authorization <- Some value
                        problem <- None
                        changed ()
                        value)
        }

    let access epoch (token: CancellationToken) force =
        task {
            do! refreshGate.WaitAsync token

            try
                require epoch token

                match lock gate (fun () -> tokens, authorization) with
                | Some value, Some(NexusAuthorization.OAuth _) when
                    not force && value.Expires > DateTimeOffset.UtcNow.AddSeconds 30.
                    ->
                    let current = NexusAuthorization.OAuth value.Access
                    lock gate (fun () -> authorization <- Some current)
                    return current
                | _, Some(NexusAuthorization.PersonalApiKey key) when not force ->
                    return NexusAuthorization.PersonalApiKey key
                | None, None when not force ->
                    return raise (NexusException NexusProblem.SignInRequired)
                | _ -> return! restore epoch token
            finally
                refreshGate.Release() |> ignore
        }

    let interactionCoordinator =
        InteractionCoordinator(gate, interactions, (fun () -> account), require, access, transport)

    let run action =
        task {
            do! lock gate (fun () -> savedConnection)
            let epoch, token = context ()

            let! result =
                NexusBoundary.protect (fun () ->
                    task {
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

    let runExpected action =
        task {
            do! lock gate (fun () -> savedConnection)
            let epoch, token = context ()

            let! protectedResult =
                NexusBoundary.protect (fun () ->
                    task {
                        if lock gate (fun () -> disconnecting) then
                            raise (NexusException NexusProblem.SignInRequired)

                        let! result = action epoch token

                        if Result.isOk result then
                            require epoch token

                        return result
                    })

            match protectedResult with
            | Error error ->
                fail epoch error
                return Error error
            | Ok(Error error) ->
                fail epoch error
                return Error error
            | Ok(Ok value) -> return Ok value
        }

    member _.Status = status ()

    member _.StatusWithRevision = lock gate (fun () -> statusRevision, statusUnsafe ())

    member _.WaitForStatusChange(revision, token: CancellationToken) =
        let pending =
            lock gate (fun () ->
                if statusRevision <> revision then
                    Task.CompletedTask
                else
                    statusChanged.Task)

        pending.WaitAsync(token)

    member _.SavedConnection = lock gate (fun () -> savedConnection)

    member _.SignIn() =
        task {
            match registration with
            | None ->
                lock gate (fun () ->
                    problem <- Some NexusProblem.NotConfigured
                    changed ())
            | Some config ->
                let attempt =
                    lock gate (fun () ->
                        if waiting || disconnecting || account.IsSome then
                            None
                        else
                            waiting <- true
                            problem <- None
                            changed ()
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
                                                transport.Token(
                                                    config.Token,
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

    member _.SubmitPersonalApiKey(key: string) =
        task {
            let epoch, token = context ()

            let! result =
                NexusBoundary.protect (fun () ->
                    task {
                        if String.IsNullOrWhiteSpace key then
                            raise (NexusException NexusProblem.InvalidApiKey)

                        if lock gate (fun () -> waiting || disconnecting) then
                            raise (NexusException NexusProblem.SignInRequired)

                        use! response = transport.ValidatePersonalApiKey(key, token)
                        let identity = NexusJson.apiKeyAccount response.RootElement

                        if
                            lock gate (fun () ->
                                boundSubject |> Option.exists ((<>) identity.Subject))
                        then
                            raise (NexusException NexusProblem.AccountChanged)

                        let packet = NexusJson.writeSavedApiKey identity.Subject key

                        try
                            do! commit.WaitAsync token

                            try
                                require epoch token

                                if
                                    lock gate (fun () ->
                                        boundSubject |> Option.exists ((<>) identity.Subject))
                                then
                                    raise (NexusException NexusProblem.AccountChanged)

                                let! saved = credentials.Save(packet, token)

                                match saved with
                                | Error error -> raise (NexusException(NexusProblem.Storage error))
                                | Ok() ->
                                    lock gate (fun () ->
                                        require epoch token
                                        account <- Some identity
                                        boundSubject <- Some identity.Subject
                                        tokens <- None

                                        authorization <-
                                            Some(NexusAuthorization.PersonalApiKey key)

                                        problem <- None
                                        changed ())
                            finally
                                commit.Release() |> ignore
                        finally
                            CryptographicOperations.ZeroMemory packet
                    })

            match result with
            | Error error ->
                lock gate (fun () ->
                    if generation = epoch then
                        problem <- Some error
                        waiting <- false
                        changed ())
            | Ok() -> ()

            return status ()
        }

    member _.Connect() =
        task {
            let! _ = run (fun epoch token -> access epoch token true)
            return status ()
        }

    member _.ConnectSaved() =
        let pending =
            task {
                let epoch, token = context ()
                let! saved = credentials.Status token

                if saved.Saved = SavedPresence.Present then
                    let! result = NexusBoundary.protect (fun () -> access epoch token true)

                    match result with
                    | Error error -> fail epoch error
                    | Ok _ -> ()
            }

        lock gate (fun () -> savedConnection <- pending)
        pending

    member _.CheckAccount() =
        task {
            let! _ =
                run (fun epoch token ->
                    task {
                        let! authorization = access epoch token false

                        use! response =
                            match authorization with
                            | NexusAuthorization.OAuth bearer ->
                                let config = configured ()
                                transport.UserInfo(config.UserInfo, bearer, token)
                            | NexusAuthorization.PersonalApiKey key ->
                                transport.ValidatePersonalApiKey(key, token)

                        let value =
                            match authorization with
                            | NexusAuthorization.OAuth _ -> NexusJson.account response.RootElement
                            | NexusAuthorization.PersonalApiKey _ ->
                                NexusJson.apiKeyAccount response.RootElement

                        lock gate (fun () ->
                            require epoch token

                            if
                                account
                                |> Option.exists (fun prior -> prior.Subject <> value.Subject)
                            then
                                raise (NexusException NexusProblem.AccountChanged)

                            account <- Some value
                            problem <- None
                            changed ())
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
                        changed ()

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
                    downloads.Clear()
                    nxm.Clear()
                    interactions.Clear()
                    boundSubject <- None
                    tokens <- None
                    authorization <- None
                    waiting <- false
                    problem <- None
                    changed ()
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
                        disconnecting <- false
                        changed ())

                commit.Release() |> ignore
        }

    member _.ReadMetadata(identity: NexusIdentity) =
        run (fun epoch token ->
            task {
                if identity.Game <> "skyrimspecialedition" || identity.Mod <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false
                return! metadata.ReadMetadata(identity, bearer, token)
            })

    member this.ReadMod(game: string, modId: int64) =
        task {
            let! result = this.ReadMetadata { Game = game; Mod = modId }

            return
                result
                |> Result.bind (fun value ->
                    if not value.Available then
                        Error NexusProblem.NotFound
                    else
                        Ok
                            { Game = game
                              Id = modId
                              Name = value.Name
                              Summary = value.Summary
                              Files = value.Files |> List.map (fun file -> file.File) })
        }

    member _.ForgetInteractions(identity: NexusIdentity) = interactionCoordinator.Forget identity

    member _.InteractionState(identity: NexusIdentity) = interactionCoordinator.State identity

    member _.RefreshInteractions(identity: NexusIdentity) =
        interactionCoordinator.Refresh(identity, run)

    member _.ChangeInteraction
        (identity: NexusIdentity, expected: int64, action: NexusInteraction, version: string)
        =
        interactionCoordinator.Change(identity, expected, action, version, run)

    member _.ReadFile(game: string, modId: int64, fileId: int64) =
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false
                return! metadata.ReadFile(game, modId, fileId, bearer, token)
            })

    member _.AcceptNxm(id, input) = nxm.Accept(id, input)

    member _.ReadNxm id = nxm.Read id

    member _.ValidateNxm(id, subject) = nxm.Validate(id, subject)

    member _.AdmitNxm(id, subject) =
        nxm.Admit(id, subject, downloads.Invalidate)

    member _.DismissNxm id = nxm.Dismiss id

    member _.Resolve
        (game: string, modId: int64, fileId: int64, subject: string, ?requiresLink: bool)
        =
        runExpected (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    return Error NexusProblem.NotFound
                else
                    let! bearer = access epoch token false

                    return!
                        downloads.Resolve(
                            epoch,
                            token,
                            bearer,
                            game,
                            modId,
                            fileId,
                            subject,
                            defaultArg requiresLink false
                        )
            })

    member _.RejectLease(game, modId, fileId, subject, url) =
        lock gate (fun () ->
            let key = game, modId, fileId, subject

            downloads.Reject(key, url))

    member _.Stop() =
        task {
            let pending =
                lock gate (fun () ->
                    lifetime.Cancel()
                    tokens <- None
                    authorization <- None
                    downloads.Clear()
                    nxm.Clear()
                    interactions.Clear()
                    signIn)

            do! pending
            do! refreshGate.WaitAsync()
            refreshGate.Release() |> ignore
        }

    interface IDisposable with
        member this.Dispose() =
            this.Stop().GetAwaiter().GetResult()
            (transport :> IDisposable).Dispose()
            (nxm :> IDisposable).Dispose()
            lifetime.Dispose()
            refreshGate.Dispose()
            commit.Dispose()
