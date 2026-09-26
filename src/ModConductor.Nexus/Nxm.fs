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
