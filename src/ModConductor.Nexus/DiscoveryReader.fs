namespace ModConductor.Nexus

open System
open System.Text.Json
open System.Threading

type internal DiscoveryReader(transport: NexusTransport) =
    let card id value =
        { Id = id
          Name = NexusJson.optionalText "name" value |> Option.defaultValue ""
          Summary = NexusJson.optionalText "summary" value |> Option.defaultValue ""
          Author = NexusJson.optionalText "author" value |> Option.defaultValue ""
          Category = NexusJson.optionalText "category_name" value |> Option.defaultValue ""
          Picture = NexusJson.imageUrl "picture_url" value }

    let pageId game value =
        NexusJson.optionalText "mod_page_url" value
        |> Option.bind (fun text ->
            match Uri.TryCreate(text, UriKind.Absolute) with
            | true, uri when
                uri.Scheme = Uri.UriSchemeHttps
                && uri.UserInfo = ""
                && (uri.Host.Equals("www.nexusmods.com", StringComparison.OrdinalIgnoreCase)
                    || uri.Host.Equals("nexusmods.com", StringComparison.OrdinalIgnoreCase))
                ->
                match uri.AbsolutePath.Split('/', StringSplitOptions.RemoveEmptyEntries) with
                | [| domain; "mods"; id |] when domain = game ->
                    match Int64.TryParse id with
                    | true, number when number > 0L -> Some number
                    | _ -> None
                | [| "games"; domain; "mods"; id |] when domain = game ->
                    match Int64.TryParse id with
                    | true, number when number > 0L -> Some number
                    | _ -> None
                | _ -> None
            | _ -> None)

    member _.Trending(game: string, token: CancellationToken) =
        NexusBoundary.protectResult (fun () ->
            task {
                let! result = transport.PublicV3("games/" + game + "/trending-mods", token)

                match result with
                | Error error -> return Error error
                | Ok response ->
                    use response = response

                    let mods =
                        response.RootElement.GetProperty("data").GetProperty("mods")
                        |> NexusJson.array 5

                    return
                        Ok(
                            mods
                            |> List.choose (fun item ->
                                pageId game item |> Option.map (fun id -> card id item))
                            |> List.distinctBy _.Id
                        )
            })

    member _.Legacy(game: string, feed: string, bearer, token: CancellationToken) =
        NexusBoundary.protectResult (fun () ->
            task {
                let path =
                    if feed = "tracked" then
                        "user/tracked_mods.json"
                    else
                        "games/" + game + "/mods/" + feed + ".json"

                let! result = transport.Api(path, bearer, false, token)

                match result with
                | Error error -> return Error error
                | Ok response ->
                    use response = response
                    let limit = if feed = "tracked" then 4096 else 100
                    let items = response.RootElement |> NexusJson.array limit

                    return
                        Ok(
                            items
                            |> List.choose (fun item ->
                                let domain = NexusJson.optionalText "domain_name" item
                                let id = NexusJson.optionalNumber "mod_id" item

                                match id with
                                | Some value when
                                    value > 0L
                                    && (domain.IsNone || domain = Some game)
                                    && (feed <> "tracked" || domain = Some game)
                                    ->
                                    Some(card value item)
                                | _ -> None)
                            |> List.distinctBy _.Id
                        )
            })
