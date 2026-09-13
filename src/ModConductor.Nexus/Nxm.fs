namespace ModConductor.Nexus

open System
open System.Collections.Generic
open System.Globalization

[<StructuralEquality; NoComparison>]
type NxmFile =
    { Game: string
      ModId: int64
      FileId: int64
      Keyed: bool }

type NxmProblem = { Title: string; Detail: string }

type internal NxmGrant =
    { Key: string
      Expires: DateTimeOffset
      User: int64 }

type internal NxmLink =
    { File: NxmFile
      Grant: NxmGrant option }

module internal Nxm =
    let malformed =
        { Title = "This Nexus link cannot be read"
          Detail = "Get a new Mod Manager Download link from Nexus Mods." }

    let expired =
        { Title = "This download link has expired"
          Detail = "Use Mod Manager Download on Nexus Mods again." }

    let missing =
        { Title = "A new download link is needed"
          Detail = "Use Mod Manager Download on Nexus Mods again." }

    let mismatch =
        { Title = "This link belongs to another Nexus account"
          Detail = "Use Mod Manager Download while signed in to the same account as MC." }

    let positive (value: string) =
        if value.Length = 0 || value |> Seq.exists (fun c -> c < '0' || c > '9') then
            None
        else
            match Int64.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture) with
            | true, number when number > 0L -> Some number
            | _ -> None

    let parse (input: string) =
        let invalid () = Error malformed

        if isNull input || input.Length > 4096 || input |> Seq.exists Char.IsControl then
            invalid ()
        else
            let rawPath = input.Split('?', 2) |> Array.head

            match Uri.TryCreate(input, UriKind.Absolute) with
            | true, uri when
                uri.Scheme = "nxm" && uri.UserInfo = "" && uri.Port = -1 && uri.Fragment = ""
                ->
                let path = uri.AbsolutePath.Split('/')

                if
                    path.Length >= 2
                    && path[1].Equals("collections", StringComparison.OrdinalIgnoreCase)
                then
                    Error
                        { Title = "Nexus Collections are not supported"
                          Detail = "Use a single mod file download instead." }
                elif
                    path.Length <> 5
                    || not (path[1].Equals("mods", StringComparison.OrdinalIgnoreCase))
                    || not (path[3].Equals("files", StringComparison.OrdinalIgnoreCase))
                    || uri.Host = ""
                    || input.Contains('\\')
                    || rawPath.Contains('%')
                    || input.Contains("/../")
                    || input.Contains("/./")
                then
                    invalid ()
                else
                    match positive path[2], positive path[4] with
                    | Some modId, Some fileId ->
                        let file =
                            { Game = uri.Host.ToLowerInvariant()
                              ModId = modId
                              FileId = fileId
                              Keyed = uri.Query <> "" }

                        if uri.Query = "" then
                            Ok { File = file; Grant = None }
                        else
                            let parts = uri.Query.Substring(1).Split('&')
                            let fields = Dictionary<string, string>(StringComparer.Ordinal)
                            let mutable valid = parts.Length = 3

                            for part in parts do
                                let pair = part.Split('=', 2)

                                if pair.Length <> 2 || not (fields.TryAdd(pair[0], pair[1])) then
                                    valid <- false

                            if
                                not valid
                                || not (
                                    fields.ContainsKey "key"
                                    && fields.ContainsKey "expires"
                                    && fields.ContainsKey "user_id"
                                )
                            then
                                invalid ()
                            else
                                let encoded = fields["key"]
                                let mutable escaped = true
                                let mutable at = 0

                                while at < encoded.Length do
                                    if encoded[at] = '%' then
                                        if
                                            at + 2 >= encoded.Length
                                            || not (
                                                Uri.IsHexDigit encoded[at + 1]
                                                && Uri.IsHexDigit encoded[at + 2]
                                            )
                                        then
                                            escaped <- false

                                        at <- at + 3
                                    else
                                        at <- at + 1

                                let key = Uri.UnescapeDataString encoded

                                match positive fields["expires"], positive fields["user_id"] with
                                | Some expiry, Some user when
                                    escaped
                                    && key.Length > 0
                                    && not (key |> Seq.exists Char.IsWhiteSpace)
                                    && not (key |> Seq.exists Char.IsControl)
                                    && expiry <= 253402300799L
                                    ->
                                    Ok
                                        { File = file
                                          Grant =
                                            Some
                                                { Key = key
                                                  Expires =
                                                    DateTimeOffset.FromUnixTimeSeconds expiry
                                                  User = user } }
                                | _ -> invalid ()
                    | _ -> invalid ()
            | _ -> invalid ()

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
