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

    let api =
        registration
        |> Option.map _.Api
        |> Option.defaultValue (Uri "https://api.nexusmods.com/v1/")

    let transport =
        new NexusTransport(api, defaultArg requestInterval (TimeSpan.FromSeconds 1.))

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
    let nxm = NxmAuthorizations()
    let interactions = InteractionMemory()

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
                    authorization <- None
                    account <- None
                    interactions.Clear()

                if error = NexusProblem.InvalidApiKey then
                    authorization <- None
                    account <- None
                    interactions.Clear())

    let require epoch (token: CancellationToken) =
        token.ThrowIfCancellationRequested()

        if not (current epoch) then
            raise (OperationCanceledException())

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
                            problem <- None)
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

    member _.Status = status ()

    member _.SavedConnection = lock gate (fun () -> savedConnection)

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

                                        problem <- None)
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
                        waiting <- false)
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
                    interactions.Clear()
                    boundSubject <- None
                    tokens <- None
                    authorization <- None
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

    member _.ReadMetadata(identity: NexusIdentity) =
        run (fun epoch token ->
            task {
                if identity.Game <> "skyrimspecialedition" || identity.Mod <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false

                use! game = transport.Api("games/" + identity.Game + ".json", bearer, false, token)

                let path =
                    "games/"
                    + identity.Game
                    + "/mods/"
                    + identity.Mod.ToString(Globalization.CultureInfo.InvariantCulture)

                use! modReply = transport.Api(path + ".json", bearer, false, token)

                use! files =
                    if MetadataJson.boolean "available" modReply.RootElement then
                        transport.Api(path + "/files.json", bearer, false, token)
                    else
                        Task.FromResult(JsonDocument.Parse("{\"files\":[],\"file_updates\":[]}"))

                return
                    MetadataJson.metadata
                        identity
                        game.RootElement
                        modReply.RootElement
                        files.RootElement
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

    member _.ForgetInteractions(identity: NexusIdentity) =
        lock gate (fun () -> interactions.Forget identity)

    member _.InteractionState(identity: NexusIdentity) =
        lock gate (fun () ->
            { interactions.Get(account |> Option.map (fun value -> value.Subject), identity) with
                AccountName = account |> Option.map _.Name })

    member this.RefreshInteractions(identity: NexusIdentity) =
        task {
            let mutable started = None

            let! result =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false

                        let state =
                            lock gate (fun () ->
                                require epoch token

                                let subject =
                                    account
                                    |> Option.map (fun value -> value.Subject)
                                    |> Option.defaultWith (fun () ->
                                        raise (NexusException NexusProblem.SignInRequired))

                                interactions.Begin(subject, identity, None)
                                |> Result.defaultWith (fun error -> raise (NexusException error)))

                        started <- Some state

                        let! tracked =
                            NexusBoundary.protect (fun () ->
                                task {
                                    use! reply =
                                        transport.Api(
                                            "user/tracked_mods.json",
                                            bearer,
                                            false,
                                            token
                                        )

                                    return MetadataJson.tracking identity reply.RootElement
                                })

                        match tracked with
                        | Error NexusProblem.InvalidApiKey ->
                            raise (NexusException NexusProblem.InvalidApiKey)
                        | _ -> ()

                        let! endorsed =
                            NexusBoundary.protect (fun () ->
                                task {
                                    use! reply =
                                        transport.Api(
                                            "user/endorsements.json",
                                            bearer,
                                            false,
                                            token
                                        )

                                    return MetadataJson.endorsements identity reply.RootElement
                                })

                        match endorsed with
                        | Error NexusProblem.InvalidApiKey ->
                            raise (NexusException NexusProblem.InvalidApiKey)
                        | _ -> ()

                        return tracked, endorsed
                    })

            lock gate (fun () ->
                started
                |> Option.iter (fun value ->
                    match result with
                    | Ok(tracking, endorsement) ->
                        let problem =
                            match tracking, endorsement with
                            | Error error, _
                            | _, Error error -> Some error
                            | _ -> None

                        interactions.Finish(
                            identity,
                            value,
                            Result.toOption tracking,
                            Result.toOption endorsement,
                            problem
                        )
                    | Error error -> interactions.Finish(identity, value, None, None, Some error)))

            return this.InteractionState identity
        }

    member this.ChangeInteraction
        (identity: NexusIdentity, expected: int64, action: NexusInteraction, version: string)
        =
        task {
            let mutable started = None
            let mutable submitted = false

            let! result =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false

                        let state, already =
                            lock gate (fun () ->
                                require epoch token

                                let subject =
                                    account
                                    |> Option.map (fun value -> value.Subject)
                                    |> Option.defaultWith (fun () ->
                                        raise (NexusException NexusProblem.SignInRequired))

                                let value = interactions.Get(Some subject, identity)

                                if value.Busy then
                                    raise (NexusException NexusProblem.InteractionBusy)

                                if value.Revision <> expected then
                                    raise (NexusException NexusProblem.InteractionUnknown)

                                let already =
                                    match action with
                                    | NexusInteraction.Track -> value.Tracking |> Option.map id
                                    | NexusInteraction.Untrack -> value.Tracking |> Option.map not
                                    | NexusInteraction.Endorse ->
                                        value.Endorsement
                                        |> Option.map ((=) NexusEndorsement.Endorsed)
                                    | NexusInteraction.Abstain ->
                                        value.Endorsement
                                        |> Option.map ((=) NexusEndorsement.Abstained)

                                if already.IsNone then
                                    raise (NexusException NexusProblem.InteractionUnknown)

                                if already.Value then
                                    value, true
                                else
                                    interactions.Begin(subject, identity, Some expected)
                                    |> Result.defaultWith (fun error ->
                                        raise (NexusException error)),
                                    false)

                        if already then
                            return state.Tracking, state.Endorsement
                        else
                            started <- Some state

                            let tracking =
                                action = NexusInteraction.Track
                                || action = NexusInteraction.Untrack

                            let path, fields =
                                if tracking then
                                    "user/tracked_mods.json",
                                    [ "domain_name", Choice1Of2 identity.Game
                                      "mod_id", Choice2Of2 identity.Mod ]
                                else
                                    "games/"
                                    + identity.Game
                                    + "/mods/"
                                    + identity.Mod.ToString(
                                        Globalization.CultureInfo.InvariantCulture
                                    )
                                    + (if action = NexusInteraction.Endorse then
                                           "/endorse.json"
                                       else
                                           "/abstain.json"),
                                    [ "Version", Choice1Of2 version ]

                            submitted <- true

                            let! written = transport.Mutate(path, bearer, action, fields, token)

                            match written with
                            | Error error -> return raise (NexusException error)
                            | Ok response ->
                                use response = response

                                if tracking then
                                    use! reply =
                                        transport.Api(
                                            "user/tracked_mods.json",
                                            bearer,
                                            false,
                                            token
                                        )

                                    let value = MetadataJson.tracking identity reply.RootElement

                                    if value <> (action = NexusInteraction.Track) then
                                        raise (NexusException NexusProblem.InteractionUnknown)

                                    return Some value, state.Endorsement
                                else
                                    let value =
                                        MetadataJson.endorsement (
                                            NexusJson.text "status" response.RootElement
                                        )

                                    if
                                        value
                                        <> (if action = NexusInteraction.Endorse then
                                                NexusEndorsement.Endorsed
                                            else
                                                NexusEndorsement.Abstained)
                                    then
                                        raise (NexusException NexusProblem.InteractionUnknown)

                                    return state.Tracking, Some value
                    })

            lock gate (fun () ->
                started
                |> Option.iter (fun value ->
                    match result with
                    | Ok(tracking, endorsement) ->
                        interactions.Finish(identity, value, tracking, endorsement, None)
                    | Error error ->
                        let issue =
                            if
                                submitted
                                && (error = NexusProblem.Cancelled
                                    || error = NexusProblem.TimedOut
                                    || error = NexusProblem.Offline
                                    || error = NexusProblem.InvalidResponse
                                    || error = NexusProblem.Failed)
                            then
                                NexusProblem.InteractionUnknown
                            else
                                error

                        let tracking =
                            if
                                action = NexusInteraction.Track
                                || action = NexusInteraction.Untrack
                            then
                                None
                            else
                                value.Tracking

                        let endorsement =
                            if
                                action = NexusInteraction.Endorse
                                || action = NexusInteraction.Abstain
                            then
                                None
                            else
                                value.Endorsement

                        interactions.Finish(identity, value, tracking, endorsement, Some issue)))

            let current = this.InteractionState identity

            return
                match started, result with
                | None, Error error -> { current with Problem = Some error }
                | _, Error error when current.Subject.IsNone ->
                    { current with Problem = Some error }
                | _ -> current
        }

    member _.ReadFile(game: string, modId: int64, fileId: int64) =
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    raise (NexusException NexusProblem.NotFound)

                let! bearer = access epoch token false

                use! reply =
                    transport.Api(
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
                        transport.Api(
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

                    if url.UserInfo <> "" || url.Fragment <> "" then
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

    member _.Stop() =
        task {
            let pending =
                lock gate (fun () ->
                    lifetime.Cancel()
                    tokens <- None
                    authorization <- None
                    leases.Clear()
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
            nxmExpiry.Dispose()
            lifetime.Dispose()
            refreshGate.Dispose()
            commit.Dispose()
