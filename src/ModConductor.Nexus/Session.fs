namespace ModConductor.Nexus

open System
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
    let discovery = DiscoveryReader(transport)

    let mutable lifetime = new CancellationTokenSource()
    let mutable generation = 0L

    let accountState =
        { Account = None
          BoundSubject = None
          Tokens = None
          Authorization = None }

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
            (fun () -> accountState.Account |> Option.map _.Subject),
            (fun () -> generation, lifetime.IsCancellationRequested)
        )

    let statusUnsafe () =
        { Configured = registration.IsSome
          Waiting = waiting
          Account = accountState.Account
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
                    accountState.Tokens <- None
                    accountState.Authorization <- None
                    accountState.Account <- None
                    interactions.Clear()

                if error = NexusProblem.InvalidApiKey then
                    accountState.Authorization <- None
                    accountState.Account <- None
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
            (fun () -> accountState.Account |> Option.map _.Subject)
        )

    let auth =
        SessionAuthentication(
            credentials,
            registration,
            handoff,
            transport,
            accountState,
            gate,
            commit,
            refreshGate,
            require,
            (fun () -> lock gate (fun () -> waiting || disconnecting)),
            (fun change ->
                match change with
                | NexusConnectionChange.OAuthPublished -> waiting <- false
                | NexusConnectionChange.AccountValidated -> ()

                problem <- None
                changed ())
        )

    let interactionCoordinator =
        InteractionCoordinator(
            gate,
            interactions,
            (fun () -> accountState.Account),
            require,
            (fun epoch token force -> auth.Access(epoch, token, force)),
            transport
        )

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
                        if waiting || disconnecting || accountState.Account.IsSome then
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
                                    auth.Execute(config, epoch, expiry.Token))

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

            let! result = NexusBoundary.protectResult (fun () -> auth.Submit(key, epoch, token))

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
            let! _ = run (fun epoch token -> auth.Access(epoch, token, true))
            return status ()
        }

    member _.ConnectSaved() =
        let pending =
            task {
                let epoch, token = context ()
                let! saved = credentials.Status token

                if saved.Saved = SavedPresence.Present then
                    let! result = NexusBoundary.protect (fun () -> auth.Access(epoch, token, true))

                    match result with
                    | Error error
                    | Ok(Error error) -> fail epoch error
                    | Ok(Ok _) -> ()
            }

        lock gate (fun () -> savedConnection <- pending)
        pending

    member _.CheckAccount() =
        task {
            let! _ = run (fun epoch token -> auth.CheckAccount(epoch, token))
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
                    let subject = accountState.BoundSubject
                    disconnecting <- true
                    generation <- generation + 1L
                    lifetime.Cancel()
                    lifetime.Dispose()
                    lifetime <- new CancellationTokenSource()
                    accountState.Account <- None
                    downloads.Clear()
                    nxm.Clear()
                    interactions.Clear()
                    accountState.BoundSubject <- None
                    accountState.Tokens <- None
                    accountState.Authorization <- None
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
                    let! bearer = auth.Access(epoch, token, false)

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
                              Author = value.Author
                              Category = value.Category |> Option.map snd |> Option.defaultValue ""
                              Picture = value.Picture
                              Files = value.Files |> List.map (fun file -> file.File) })
        }

    member _.ReadDiscovery(game: string, feed: string) =
        task {
            let epoch, token = context ()

            if game <> "skyrimspecialedition" then
                return Error NexusProblem.NotFound
            elif feed = "trending" then
                let! result =
                    NexusBoundary.protectResult (fun () -> discovery.Trending(game, token))

                if Result.isOk result && (not (current epoch) || token.IsCancellationRequested) then
                    return Error NexusProblem.Cancelled
                else
                    return result
            elif feed = "latest_added" || feed = "latest_updated" || feed = "tracked" then
                let! result =
                    run (fun epoch token ->
                        task {
                            let! bearer = auth.Access(epoch, token, false)

                            match bearer with
                            | Error error -> return Error error
                            | Ok bearer ->
                                let! feedResult = discovery.Legacy(game, feed, bearer, token)

                                return
                                    match feedResult with
                                    | Error NexusProblem.NotFound ->
                                        Ok(Error NexusProblem.NotFound)
                                    | Error error -> Error error
                                    | Ok cards -> Ok(Ok cards)
                        })

                return result |> Result.bind id
            else
                return Error NexusProblem.NotFound
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
                    let! bearer = auth.Access(epoch, token, false)

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
                    let! bearer = auth.Access(epoch, token, false)

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
                    accountState.Tokens <- None
                    accountState.Authorization <- None
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
