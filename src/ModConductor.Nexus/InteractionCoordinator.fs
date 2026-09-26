namespace ModConductor.Nexus

open System
open System.Threading
open System.Threading.Tasks

type internal InteractionCoordinator
    (
        gate: obj,
        memory: InteractionMemory,
        currentAccount: unit -> Account option,
        requireCurrent: int64 -> CancellationToken -> unit,
        access: int64 -> CancellationToken -> bool -> Task<Result<NexusAuthorization, NexusProblem>>,
        transport: NexusTransport
    ) =
    let readTracking identity bearer token =
        NexusBoundary.protectResult (fun () ->
            task {
                let! response = transport.Api("user/tracked_mods.json", bearer, false, token)

                match response with
                | Error error -> return Error error
                | Ok response ->
                    use response = response
                    return Ok(InteractionJson.tracking identity response.RootElement)
            })

    let readEndorsement identity bearer token =
        NexusBoundary.protectResult (fun () ->
            task {
                let! response = transport.Api("user/endorsements.json", bearer, false, token)

                match response with
                | Error error -> return Error error
                | Ok response ->
                    use response = response
                    return Ok(InteractionJson.endorsements identity response.RootElement)
            })

    let beginRefresh epoch token identity =
        lock gate (fun () ->
            requireCurrent epoch token

            match currentAccount () with
            | None -> Error NexusProblem.SignInRequired
            | Some account -> memory.Begin(account.Subject, identity, None))

    let beginChange epoch token identity expected action =
        lock gate (fun () ->
            requireCurrent epoch token

            match currentAccount () with
            | None -> Error NexusProblem.SignInRequired
            | Some account ->
                let value = memory.Get(Some account.Subject, identity)

                if value.Busy then
                    Error NexusProblem.InteractionBusy
                elif value.Revision <> expected then
                    Error NexusProblem.InteractionUnknown
                else
                    let already =
                        match action with
                        | NexusInteraction.Track -> value.Tracking |> Option.map id
                        | NexusInteraction.Untrack -> value.Tracking |> Option.map not
                        | NexusInteraction.Endorse ->
                            value.Endorsement |> Option.map ((=) NexusEndorsement.Endorsed)
                        | NexusInteraction.Abstain ->
                            value.Endorsement |> Option.map ((=) NexusEndorsement.Abstained)

                    match already with
                    | None -> Error NexusProblem.InteractionUnknown
                    | Some true -> Ok(value, true)
                    | Some false ->
                        memory.Begin(account.Subject, identity, Some expected)
                        |> Result.map (fun started -> started, false))

    let mutation (identity: NexusIdentity) action version =
        match action with
        | NexusInteraction.Track
        | NexusInteraction.Untrack ->
            "user/tracked_mods.json",
            [ "domain_name", Choice1Of2 identity.Game; "mod_id", Choice2Of2 identity.Mod ]
        | NexusInteraction.Endorse
        | NexusInteraction.Abstain ->
            "games/"
            + identity.Game
            + "/mods/"
            + identity.Mod.ToString(Globalization.CultureInfo.InvariantCulture)
            + (if action = NexusInteraction.Endorse then
                   "/endorse.json"
               else
                   "/abstain.json"),
            [ "Version", Choice1Of2 version ]

    member _.Forget(identity: NexusIdentity) =
        lock gate (fun () -> memory.Forget identity)

    member _.State(identity: NexusIdentity) =
        lock gate (fun () ->
            { memory.Get(currentAccount () |> Option.map _.Subject, identity) with
                AccountName = currentAccount () |> Option.map _.Name })

    member this.Refresh(identity: NexusIdentity, run) =
        task {
            let mutable started = None

            let! result =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false

                        match bearer with
                        | Error error -> return Error error
                        | Ok bearer ->
                            match beginRefresh epoch token identity with
                            | Error error -> return Error error
                            | Ok state ->
                                started <- Some state
                                let! tracked = readTracking identity bearer token

                                if tracked = Error NexusProblem.InvalidApiKey then
                                    return Error NexusProblem.InvalidApiKey
                                else
                                    let! endorsed = readEndorsement identity bearer token

                                    if endorsed = Error NexusProblem.InvalidApiKey then
                                        return Error NexusProblem.InvalidApiKey
                                    else
                                        return Ok(tracked, endorsed)
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

                        memory.Finish(
                            identity,
                            value,
                            Result.toOption tracking,
                            Result.toOption endorsement,
                            problem
                        )
                    | Error error -> memory.Finish(identity, value, None, None, Some error)))

            return this.State identity
        }

    member this.Change
        (identity: NexusIdentity, expected: int64, action: NexusInteraction, version: string, run)
        =
        task {
            let mutable started = None
            let mutable submitted = false

            let! result =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false

                        match bearer with
                        | Error error -> return Error error
                        | Ok bearer ->
                            match beginChange epoch token identity expected action with
                            | Error error -> return Error error
                            | Ok(state, true) -> return Ok(state.Tracking, state.Endorsement)
                            | Ok(state, false) ->
                                started <- Some state
                                let path, fields = mutation identity action version
                                submitted <- true

                                let! written =
                                    transport.Mutate(path, bearer, action, fields, token)

                                match written with
                                | Error error -> return Error error
                                | Ok response ->
                                    use response = response

                                    match action with
                                    | NexusInteraction.Track
                                    | NexusInteraction.Untrack ->
                                        let! tracking = readTracking identity bearer token

                                        match tracking with
                                        | Error error -> return Error error
                                        | Ok tracking when
                                            tracking <> (action = NexusInteraction.Track)
                                            ->
                                            return Error NexusProblem.InteractionUnknown
                                        | Ok tracking ->
                                            return Ok(Some tracking, state.Endorsement)
                                    | NexusInteraction.Endorse
                                    | NexusInteraction.Abstain ->
                                        let value =
                                            InteractionJson.endorsement (
                                                NexusJson.text "status" response.RootElement
                                            )

                                        if
                                            value
                                            <> (if action = NexusInteraction.Endorse then
                                                    NexusEndorsement.Endorsed
                                                else
                                                    NexusEndorsement.Abstained)
                                        then
                                            return Error NexusProblem.InteractionUnknown
                                        else
                                            return Ok(state.Tracking, Some value)
                    })

            lock gate (fun () ->
                started
                |> Option.iter (fun value ->
                    match result with
                    | Ok(tracking, endorsement) ->
                        memory.Finish(identity, value, tracking, endorsement, None)
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

                        memory.Finish(identity, value, tracking, endorsement, Some issue)))

            let current = this.State identity

            return
                match started, result with
                | None, Error error -> { current with Problem = Some error }
                | _, Error error when current.Subject.IsNone ->
                    { current with Problem = Some error }
                | _ -> current
        }
