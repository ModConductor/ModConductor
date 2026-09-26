namespace ModConductor.Nexus

open System
open System.Collections.Generic
open System.Globalization
open System.Threading
open System.Threading.Tasks

type internal DownloadLeases
    (
        gate: obj,
        transport: NexusTransport,
        requireCurrent: int64 -> CancellationToken -> unit,
        grant: string * int64 * int64 * string -> NxmGrant option,
        accountSubject: unit -> string option
    ) =
    let leases = Dictionary<string * int64 * int64 * string, DownloadLease>()

    let path (game: string, modId: int64, fileId: int64) (grant: NxmGrant option) =
        let query =
            grant
            |> Option.map (fun value ->
                "?key="
                + Uri.EscapeDataString value.Key
                + "&expires="
                + value.Expires.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture))
            |> Option.defaultValue ""

        "games/"
        + game
        + "/mods/"
        + modId.ToString(CultureInfo.InvariantCulture)
        + "/files/"
        + fileId.ToString(CultureInfo.InvariantCulture)
        + "/download_link.json"
        + query

    member _.Resolve(epoch, token, bearer, game, modId, fileId, subject, requiresLink) =
        task {
            if game <> "skyrimspecialedition" || modId <= 0L || fileId <= 0L then
                return Error NexusProblem.NotFound
            elif lock gate (fun () -> accountSubject () <> Some subject) then
                return Error NexusProblem.DownloadAccount
            else
                let key = game, modId, fileId, subject
                let permission = lock gate (fun () -> grant key)

                if requiresLink && permission.IsNone then
                    return Error NexusProblem.DownloadLinkNeeded
                else
                    let cached =
                        lock gate (fun () ->
                            leases
                            |> Seq.filter (fun entry ->
                                entry.Value.Expires <= DateTimeOffset.UtcNow)
                            |> Seq.map (fun entry -> entry.Key)
                            |> Seq.toArray
                            |> Array.iter (fun expired -> leases.Remove expired |> ignore)

                            match leases.TryGetValue key with
                            | true, value -> Some value
                            | _ -> None)

                    match cached with
                    | Some value -> return Ok value
                    | None ->
                        let! response =
                            transport.Api(
                                path (game, modId, fileId) permission,
                                bearer,
                                true,
                                token
                            )

                        match response with
                        | Error error -> return Error error
                        | Ok reply ->
                            use reply = reply

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
                                requireCurrent epoch token
                                leases[key] <- lease)

                            return Ok lease
        }

    member _.Invalidate(key) = leases.Remove key |> ignore

    member _.Reject(key, url) =
        match leases.TryGetValue key with
        | true, lease when lease.Url = url -> leases.Remove key |> ignore
        | _ -> ()

    member _.Clear() = leases.Clear()
