namespace ModConductor.Nexus

open System
open System.Security.Cryptography
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

    let acceptKey epoch identity key token =
        lock gate (fun () ->
            require epoch token
            account <- Some identity
            boundSubject <- Some identity.Subject
            tokens <- None
            authorization <- Some(NexusAuthorization.PersonalApiKey key)
            problem <- None
            changed ())

    let accountCredentials =
        AccountCredentials(
            credentials,
            transport,
            commit,
            require,
            (fun () -> lock gate (fun () -> boundSubject)),
            (fun () -> lock gate (fun () -> waiting || disconnecting)),
            acceptKey
        )

    let publish epoch (value: NexusJson.Tokens) expected token =
        task {
            match registration with
            | None -> return Error NexusProblem.NotConfigured
            | Some config ->
                let! response = transport.UserInfo(config.UserInfo, value.Access, token)

                match response with
                | Error error -> return Error error
                | Ok response ->
                    use response = response
                    let identity = NexusJson.account response.RootElement

                    if expected |> Option.exists ((<>) identity.Subject) then
                        return Error NexusProblem.AccountChanged
                    else
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
                                | Error error -> return Error(NexusProblem.Storage error)
                                | Ok() ->
                                    lock gate (fun () ->
                                        require epoch token
                                        account <- Some identity
                                        boundSubject <- Some identity.Subject
                                        tokens <- Some value

                                        authorization <-
                                            Some(NexusAuthorization.OAuth value.Access)

                                        waiting <- false
                                        problem <- None
                                        changed ())

                                    return Ok()
                            finally
                                commit.Release() |> ignore
                        finally
                            CryptographicOperations.ZeroMemory packet
        }

    let oauth =
        OAuthFlow(handoff, transport, publish, (fun () -> lock gate (fun () -> boundSubject)))

    let restore epoch token =
        task {
            let! read = accountCredentials.ReadSaved token

            match read with
            | Error error -> return Error error
            | Ok(NexusJson.SavedCredential.OAuth saved) ->
                match registration with
                | None -> return Error NexusProblem.NotConfigured
                | Some config ->

                    if
                        saved.Issuer <> config.Issuer.AbsoluteUri || saved.Client <> config.ClientId
                    then
                        return Error NexusProblem.SignInRequired
                    elif
                        lock gate (fun () -> boundSubject |> Option.exists ((<>) saved.Subject))
                    then
                        return Error NexusProblem.AccountChanged
                    else
                        lock gate (fun () ->
                            require epoch token
                            boundSubject <- Some saved.Subject)

                        let! reply =
                            transport.Token(
                                config.Token,
                                [ "grant_type", "refresh_token"
                                  "refresh_token", saved.Refresh
                                  "client_id", config.ClientId ],
                                token
                            )

                        match reply with
                        | Error error -> return Error error
                        | Ok reply ->
                            use reply = reply
                            let value = NexusJson.tokens (Some saved.Refresh) reply.RootElement
                            let! saved = publish epoch value (Some saved.Subject) token

                            return
                                saved
                                |> Result.map (fun () -> NexusAuthorization.OAuth value.Access)
            | Ok(NexusJson.SavedCredential.PersonalApiKey(savedSubject, key)) ->
                return! accountCredentials.RestoreKey(savedSubject, key, epoch, token)
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
                    return Ok current
                | _, Some(NexusAuthorization.PersonalApiKey key) when not force ->
                    return Ok(NexusAuthorization.PersonalApiKey key)
                | None, None when not force -> return Error NexusProblem.SignInRequired
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

            let! protectedResult =
                NexusBoundary.protect (fun () ->
                    task {
                        if lock gate (fun () -> disconnecting) then
                            return Error NexusProblem.SignInRequired
                        else
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
                                    oauth.Execute(config, epoch, expiry.Token))

                            match result with
                            | Error error
                            | Ok(Error error) -> fail epoch error
                            | Ok(Ok()) -> ()
                        }

                    lock gate (fun () -> signIn <- pending)

            return status ()
        }

    member _.SubmitPersonalApiKey(key: string) =
        task {
            let epoch, token = context ()

            let! result =
                NexusBoundary.protectResult (fun () -> accountCredentials.Submit(key, epoch, token))

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
                    | Error error
                    | Ok(Error error) -> fail epoch error
                    | Ok(Ok _) -> ()
            }

        lock gate (fun () -> savedConnection <- pending)
        pending

    member _.CheckAccount() =
        task {
            let! _ =
                run (fun epoch token ->
                    task {
                        let! authorization = access epoch token false

                        match authorization with
                        | Error error -> return Error error
                        | Ok authorization ->
                            let! response =
                                match authorization with
                                | NexusAuthorization.OAuth bearer ->
                                    match registration with
                                    | None -> Task.FromResult(Error NexusProblem.NotConfigured)
                                    | Some config ->
                                        transport.UserInfo(config.UserInfo, bearer, token)
                                | NexusAuthorization.PersonalApiKey key ->
                                    transport.ValidatePersonalApiKey(key, token)

                            match response with
                            | Error error -> return Error error
                            | Ok response ->
                                use response = response

                                let value =
                                    match authorization with
                                    | NexusAuthorization.OAuth _ ->
                                        NexusJson.account response.RootElement
                                    | NexusAuthorization.PersonalApiKey _ ->
                                        NexusJson.apiKeyAccount response.RootElement

                                return
                                    lock gate (fun () ->
                                        require epoch token

                                        if
                                            account
                                            |> Option.exists (fun prior ->
                                                prior.Subject <> value.Subject)
                                        then
                                            Error NexusProblem.AccountChanged
                                        else
                                            account <- Some value
                                            problem <- None
                                            changed ()
                                            Ok())
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
                    return Error NexusProblem.NotFound
                else
                    let! bearer = access epoch token false

                    match bearer with
                    | Error error -> return Error error
                    | Ok bearer -> return! metadata.ReadMetadata(identity, bearer, token)
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
                    return Error NexusProblem.NotFound
                else
                    let! bearer = access epoch token false

                    match bearer with
                    | Error error -> return Error error
                    | Ok bearer -> return! metadata.ReadFile(game, modId, fileId, bearer, token)
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
        run (fun epoch token ->
            task {
                if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                    return Error NexusProblem.NotFound
                else
                    let! bearer = access epoch token false

                    match bearer with
                    | Error error -> return Error error
                    | Ok bearer ->
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
