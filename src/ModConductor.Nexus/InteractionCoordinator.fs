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
        access: int64 -> CancellationToken -> bool -> Task<NexusAuthorization>,
        transport: NexusTransport
    ) =
    member _.Forget(identity: NexusIdentity) =
        lock gate (fun () -> memory.Forget identity)

    member _.State(identity: NexusIdentity) =
        lock gate (fun () ->
            { memory.Get(currentAccount () |> Option.map (fun value -> value.Subject), identity) with
                AccountName = currentAccount () |> Option.map _.Name })

    member this.Refresh(identity: NexusIdentity, run) =
        task {
            let mutable started = None

            let! result =
                run (fun epoch token ->
                    task {
                        let! bearer = access epoch token false

                        let state =
                            lock gate (fun () ->
                                requireCurrent epoch token

                                let subject =
                                    currentAccount ()
                                    |> Option.map (fun value -> value.Subject)
                                    |> Option.defaultWith (fun () ->
                                        raise (NexusException NexusProblem.SignInRequired))

                                memory.Begin(subject, identity, None)
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

                        let state, already =
                            lock gate (fun () ->
                                requireCurrent epoch token

                                let subject =
                                    currentAccount ()
                                    |> Option.map (fun value -> value.Subject)
                                    |> Option.defaultWith (fun () ->
                                        raise (NexusException NexusProblem.SignInRequired))

                                let value = memory.Get(Some subject, identity)

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
                                    memory.Begin(subject, identity, Some expected)
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
