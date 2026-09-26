namespace ModConductor.Nexus

open System
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open ModConductor.Credentials

type internal NexusAccountState =
    { mutable Account: Account option
      mutable BoundSubject: string option
      mutable Tokens: NexusJson.Tokens option
      mutable Authorization: NexusAuthorization option }

[<RequireQualifiedAccess>]
type internal NexusConnectionChange =
    | AccountValidated
    | OAuthPublished

type internal SessionAuthentication
    (
        credentials: CredentialSession,
        registration: NexusRegistration option,
        handoff: IOAuthHandoff,
        transport: NexusTransport,
        state: NexusAccountState,
        gate: obj,
        commit: SemaphoreSlim,
        refreshGate: SemaphoreSlim,
        requireCurrent: int64 -> CancellationToken -> unit,
        unavailable: unit -> bool,
        connected: NexusConnectionChange -> unit
    ) =
    let acceptKey epoch identity key token =
        lock gate (fun () ->
            requireCurrent epoch token
            state.Account <- Some identity
            state.BoundSubject <- Some identity.Subject
            state.Tokens <- None
            state.Authorization <- Some(NexusAuthorization.PersonalApiKey key)
            connected NexusConnectionChange.AccountValidated)

    let accountCredentials =
        AccountCredentials(
            credentials,
            transport,
            commit,
            requireCurrent,
            (fun () -> lock gate (fun () -> state.BoundSubject)),
            unavailable,
            acceptKey
        )

    let saveOAuth
        epoch
        (config: NexusRegistration)
        (identity: Account)
        (value: NexusJson.Tokens)
        (token: CancellationToken)
        =
        task {
            let packet =
                CredentialJson.writeSaved
                    { Issuer = config.Issuer.AbsoluteUri
                      Client = config.ClientId
                      Subject = identity.Subject
                      Refresh = value.Refresh }

            try
                do! commit.WaitAsync token

                try
                    requireCurrent epoch token
                    let! saved = credentials.Save(packet, token)

                    match saved with
                    | Error error -> return Error(NexusProblem.Storage error)
                    | Ok() ->
                        lock gate (fun () ->
                            requireCurrent epoch token
                            state.Account <- Some identity
                            state.BoundSubject <- Some identity.Subject
                            state.Tokens <- Some value
                            state.Authorization <- Some(NexusAuthorization.OAuth value.Access)
                            connected NexusConnectionChange.OAuthPublished)

                        return Ok()
                finally
                    commit.Release() |> ignore
            finally
                CryptographicOperations.ZeroMemory packet
        }

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
                        return! saveOAuth epoch config identity value token
        }

    let oauth =
        OAuthFlow(handoff, transport, publish, (fun () -> lock gate (fun () -> state.BoundSubject)))

    let restoreOAuth epoch (saved: CredentialJson.Saved) token =
        task {
            match registration with
            | None -> return Error NexusProblem.NotConfigured
            | Some config ->
                if saved.Issuer <> config.Issuer.AbsoluteUri || saved.Client <> config.ClientId then
                    return Error NexusProblem.SignInRequired
                elif
                    lock gate (fun () -> state.BoundSubject |> Option.exists ((<>) saved.Subject))
                then
                    return Error NexusProblem.AccountChanged
                else
                    lock gate (fun () ->
                        requireCurrent epoch token
                        state.BoundSubject <- Some saved.Subject)

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
                        let! published = publish epoch value (Some saved.Subject) token

                        return
                            published
                            |> Result.map (fun () -> NexusAuthorization.OAuth value.Access)
        }

    let restore epoch token =
        task {
            let! read = accountCredentials.ReadSaved token

            match read with
            | Error error -> return Error error
            | Ok(CredentialJson.SavedCredential.OAuth saved) ->
                return! restoreOAuth epoch saved token
            | Ok(CredentialJson.SavedCredential.PersonalApiKey(savedSubject, key)) ->
                return! accountCredentials.RestoreKey(savedSubject, key, epoch, token)
        }

    let access epoch (token: CancellationToken) force =
        task {
            do! refreshGate.WaitAsync token

            try
                requireCurrent epoch token

                match lock gate (fun () -> state.Tokens, state.Authorization) with
                | Some value, Some(NexusAuthorization.OAuth _) when
                    not force && value.Expires > DateTimeOffset.UtcNow.AddSeconds 30.
                    ->
                    let current = NexusAuthorization.OAuth value.Access
                    lock gate (fun () -> state.Authorization <- Some current)
                    return Ok current
                | _, Some(NexusAuthorization.PersonalApiKey key) when not force ->
                    return Ok(NexusAuthorization.PersonalApiKey key)
                | None, None when not force -> return Error NexusProblem.SignInRequired
                | _ -> return! restore epoch token
            finally
                refreshGate.Release() |> ignore
        }

    let readAccount authorization token =
        task {
            let! response =
                match authorization with
                | NexusAuthorization.OAuth bearer ->
                    match registration with
                    | None -> Task.FromResult(Error NexusProblem.NotConfigured)
                    | Some config -> transport.UserInfo(config.UserInfo, bearer, token)
                | NexusAuthorization.PersonalApiKey key ->
                    transport.ValidatePersonalApiKey(key, token)

            match response with
            | Error error -> return Error error
            | Ok response ->
                use response = response

                return
                    match authorization with
                    | NexusAuthorization.OAuth _ -> NexusJson.account response.RootElement |> Ok
                    | NexusAuthorization.PersonalApiKey _ ->
                        NexusJson.apiKeyAccount response.RootElement |> Ok
        }

    let updateAccount epoch token (value: Account) =
        lock gate (fun () ->
            requireCurrent epoch token

            if state.Account |> Option.exists (fun prior -> prior.Subject <> value.Subject) then
                Error NexusProblem.AccountChanged
            else
                state.Account <- Some value
                connected NexusConnectionChange.AccountValidated
                Ok())

    member _.Access(epoch, token, force) = access epoch token force
    member _.Execute(config, epoch, token) = oauth.Execute(config, epoch, token)

    member _.Submit(key, epoch, token) =
        accountCredentials.Submit(key, epoch, token)

    member _.CheckAccount(epoch, token) =
        task {
            let! authorization = access epoch token false

            match authorization with
            | Error error -> return Error error
            | Ok authorization ->
                let! response = readAccount authorization token

                match response with
                | Error error -> return Error error
                | Ok value -> return updateAccount epoch token value
        }
