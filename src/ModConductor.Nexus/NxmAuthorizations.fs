namespace ModConductor.Nexus

open System
open System.Collections.Generic

type internal NxmAuthorizations() =
    let pending = Dictionary<Guid, Result<NxmLink, NxmProblem>>()
    let mutable inbox: INxmInbox option = None
    let transfers = Dictionary<string * int64 * int64 * string, NxmGrant>()

    let prune () =
        let now = DateTimeOffset.UtcNow

        for key in
            transfers
            |> Seq.filter (fun p -> p.Value.Expires <= now)
            |> Seq.map (fun p -> p.Key)
            |> Seq.toArray do
            transfers.Remove key |> ignore

        for key in
            pending
            |> Seq.filter (fun p ->
                match p.Value with
                | Ok link -> link.Grant |> Option.exists (fun g -> g.Expires <= now)
                | Error _ -> false)
            |> Seq.map (fun p -> p.Key)
            |> Seq.toArray do
            match pending[key] with
            | Ok link -> pending[key] <- Ok { link with Grant = None }
            | Error _ -> ()

    member _.Handled id =
        inbox |> Option.exists (fun store -> store.Handled id)

    member _.Attach(value) = inbox <- Some value

    member _.Pending() =
        inbox |> Option.map (fun store -> store.Pending()) |> Option.defaultValue []

    member _.Accept(id, input) =
        prune ()

        if id = Guid.Empty then
            false
        else
            match Nxm.parse input, inbox with
            | Ok link, Some store ->
                let saved = store.Pending()
                let invalid = pending.Values |> Seq.filter Result.isError |> Seq.length

                let duplicate =
                    saved
                    |> List.exists (fun request ->
                        request.File.Game = link.File.Game
                        && request.File.ModId = link.File.ModId
                        && request.File.FileId = link.File.FileId)

                let accepted =
                    if saved.Length + invalid >= 16 && not duplicate && not (store.Handled id) then
                        Error()
                    else
                        store.Accept(id, link.File)

                match accepted with
                | Error() -> false
                | Ok None -> true
                | Ok(Some request) when
                    request.File.Game <> link.File.Game
                    || request.File.ModId <> link.File.ModId
                    || request.File.FileId <> link.File.FileId
                    ->
                    false
                | Ok(Some request) ->
                    pending[request.Id] <- Ok link
                    true
            | parsed, _ ->
                if pending.ContainsKey id then
                    true
                elif
                    (match inbox with
                     | None -> pending.Count
                     | Some store ->
                         store.Pending().Length
                         + (pending.Values |> Seq.filter Result.isError |> Seq.length))
                    >= 16
                then
                    false
                else
                    pending.Add(id, parsed)
                    true

    member _.Read id =
        prune ()
        let saved = inbox |> Option.bind (fun store -> store.Read id)

        let canonical = saved |> Option.map _.Id |> Option.defaultValue id

        match pending.TryGetValue canonical, saved with
        | (true, value), _ -> value
        | _, Some request -> Ok { File = request.File; Grant = None }
        | _ -> Error Nxm.missing

    member this.NeedsGrant id =
        match this.Read id with
        | Ok link -> link.File.Keyed && link.Grant.IsNone
        | Error _ -> false

    member this.Validate(id, subject) =
        this.Read id
        |> Result.bind (fun link ->
            match link.Grant with
            | None when link.File.Keyed -> Error Nxm.missing
            | Some grant ->
                match Nxm.positive subject with
                | None ->
                    Error
                        { Title = "MC cannot check which Nexus account this link belongs to"
                          Detail = "" }
                | Some value when value <> grant.User -> Error Nxm.mismatch
                | Some _ -> Ok link
            | None -> Ok link)

    member this.Admit(id, subject) =
        this.Validate(id, subject)
        |> Result.bind (fun link ->
            match link.Grant with
            | None -> Ok(link.File, fun () -> ())
            | Some grant ->
                let key = link.File.Game, link.File.ModId, link.File.FileId, subject

                let previous =
                    match transfers.TryGetValue key with
                    | true, value -> Some value
                    | _ -> None

                if transfers.Count >= 64 && previous.IsNone then
                    Error
                        { Title = "Too many Nexus downloads are waiting"
                          Detail = "Try again after a download finishes." }
                else
                    transfers[key] <- grant

                    let cancel () =
                        match transfers.TryGetValue key with
                        | true, current when Object.ReferenceEquals(current, grant) ->
                            match previous with
                            | Some old when old.Expires > DateTimeOffset.UtcNow ->
                                transfers[key] <- old
                            | _ -> transfers.Remove key |> ignore
                        | _ -> ()

                    Ok(link.File, cancel))

    member _.Grant key =
        prune ()

        match transfers.TryGetValue key with
        | true, grant -> Some grant
        | _ -> None

    member _.Expire() = prune ()

    member _.Dismiss id =
        let canonical = inbox |> Option.bind (fun store -> store.Read id) |> Option.map _.Id
        inbox |> Option.iter (fun store -> store.Dismiss id)
        pending.Remove(defaultArg canonical id) |> ignore

    member _.Clear() =
        pending.Clear()
        transfers.Clear()

type NxmAdmission internal (file: NxmFile, completeRequest: unit -> unit, cancel: unit -> unit) =
    let mutable complete = false
    member _.File = file

    member _.Complete() =
        // The transfer already has an owner even if inbox retirement fails.
        complete <- true
        completeRequest ()

    interface IDisposable with
        member _.Dispose() =
            if not complete then
                cancel ()
