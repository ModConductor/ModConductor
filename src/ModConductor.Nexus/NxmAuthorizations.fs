namespace ModConductor.Nexus

open System
open System.Collections.Generic

type internal NxmAuthorizations() =
    let pending = Dictionary<Guid, Result<NxmLink, NxmProblem>>()
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
            pending[key] <- Error Nxm.expired

    member _.Accept(id, input) =
        prune ()

        if id = Guid.Empty then
            false
        elif pending.ContainsKey id then
            true
        elif pending.Count >= 16 then
            false
        else
            pending.Add(id, Nxm.parse input)
            true

    member _.Read id =
        prune ()

        match pending.TryGetValue id with
        | true, value -> value
        | _ -> Error Nxm.missing

    member this.Validate(id, subject) =
        this.Read id
        |> Result.bind (fun link ->
            match link.Grant with
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
    member _.Dismiss id = pending.Remove id |> ignore

    member _.Clear() =
        pending.Clear()
        transfers.Clear()

type NxmAdmission internal (file: NxmFile, cancel: unit -> unit) =
    let mutable complete = false
    member _.File = file
    member _.Complete() = complete <- true

    interface IDisposable with
        member _.Dispose() =
            if not complete then
                cancel ()
