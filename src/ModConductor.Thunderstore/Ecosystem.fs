namespace ModConductor.Thunderstore

open System
open System.Net.Http
open System.Text.Json
open System.Threading

type GameStoreIdentity =
    { Platform: string; Identifier: string }

type GameInstallRule =
    { Route: string
      Tracking: string
      Default: bool
      Extensions: string list }

type GameLoaderPackage =
    { Namespace: string
      Name: string
      ArchiveRoot: string }

type EcosystemGame =
    { Id: string
      Name: string
      Community: string
      ArtworkUrl: string
      Stores: GameStoreIdentity list
      Executables: string list
      Content: string
      PackageLoader: string
      PackageIndex: string
      Rules: GameInstallRule list
      Loader: GameLoaderPackage option
      SearchTerms: string list }

module Ecosystem =
    let private strings name value =
        Json.array name value
        |> List.choose (fun item ->
            if item.ValueKind = JsonValueKind.String then
                Some(item.GetString())
            else
                None)

    let private stores value =
        Json.array "distributions" value
        |> List.map (fun row ->
            { Platform = Json.text "platform" row
              Identifier = Json.text "identifier" row })

    let rec private rules prefix value =
        Json.array "installRules" value
        |> List.collect (fun row ->
            let route =
                String.concat "/" ([ prefix; Json.text "route" row ] |> List.filter ((<>) ""))

            { Route = route
              Tracking = Json.text "trackingMethod" row
              Default = Json.flag "isDefaultLocation" row
              Extensions = strings "defaultFileExtensions" row }
            :: (Json.array "subRoutes" row
                |> List.collect (fun child ->
                    let nested = String.concat "/" [ route; Json.text "route" child ]

                    [ { Route = nested
                        Tracking = Json.text "trackingMethod" child
                        Default = Json.flag "isDefaultLocation" child
                        Extensions = strings "defaultFileExtensions" child } ])))

    let private artwork game variant community =
        [ Json.text "icon" (Json.property "meta" community)
          Json.text "iconUrl" (Json.property "meta" variant)
          Json.text "iconUrl" (Json.property "meta" game) ]
        |> List.tryFind ((<>) "")
        |> Option.map (fun path ->
            Uri(Uri "https://ccdn.thunderstore.io/assets/", path).AbsoluteUri)
        |> Option.defaultValue ""

    let read (value: JsonElement) =
        let loaders = Json.array "modloaderPackages" value
        let games = Json.property "games" value

        if games.ValueKind <> JsonValueKind.Object then
            Error Problem.InvalidResponse
        else
            games.EnumerateObject()
            |> Seq.collect (fun property ->
                let game = property.Value
                let community = Json.property "thunderstore" game

                let loader =
                    strings "autolistPackageIds" community
                    |> List.choose (fun id ->
                        loaders
                        |> List.tryFind (fun row ->
                            Json.text "packageId" row = id && Json.text "loader" row = "bepinex")
                        |> Option.bind (fun row ->
                            let parts = id.Split('-', 2)

                            if parts.Length <> 2 then
                                None
                            else
                                Some
                                    { Namespace = parts[0]
                                      Name = parts[1]
                                      ArchiveRoot = Json.text "rootFolder" row }))
                    |> function
                        | [ one ] -> Some one
                        | _ -> None

                let variants = Json.array "r2modman" game

                let variants =
                    if variants.IsEmpty then
                        [ Unchecked.defaultof<JsonElement> ]
                    else
                        variants

                variants
                |> List.mapi (fun index variant ->
                    let distribution = stores variant
                    let name = Json.text "displayName" (Json.property "meta" variant)

                    { Id = property.Name + ":" + string index
                      Name =
                        if name = "" then
                            Json.text "displayName" (Json.property "meta" game)
                        else
                            name
                      Community = property.Name
                      ArtworkUrl = artwork game variant community
                      Stores = if distribution.IsEmpty then stores game else distribution
                      Executables = strings "exeNames" variant
                      Content = Json.text "dataFolderName" variant
                      PackageLoader = Json.text "packageLoader" variant
                      PackageIndex = Json.text "packageIndex" variant
                      Rules = rules "" variant
                      Loader = loader
                      SearchTerms = strings "additionalSearchStrings" variant }))
            |> Seq.toList
            |> Ok

    let matchesSteam id game =
        id <> 0u
        && game.Stores
           |> List.exists (fun store ->
               (store.Platform = "steam" || store.Platform = "steam-direct")
               && store.Identifier = string id)

    let supportsBepInEx game =
        game.PackageLoader = "bepinex"
        && game.Rules
           |> List.exists (fun rule ->
               rule.Default
               && rule.Route.Equals("BepInEx/plugins", StringComparison.OrdinalIgnoreCase))

    let search (query: string) games =
        games
        |> List.filter (fun game ->
            game.Name.Contains(query, StringComparison.OrdinalIgnoreCase)
            || game.Community.Contains(query, StringComparison.OrdinalIgnoreCase)
            || game.SearchTerms
               |> List.exists (fun term ->
                   term.Contains(query, StringComparison.OrdinalIgnoreCase)))

[<Sealed>]
type EcosystemReader(?http: HttpClient, ?address: Uri) =
    let client = defaultArg http (new HttpClient())
    let transport = Transport client

    let address =
        defaultArg address (Uri "https://thunderstore.io/api/experimental/schema/dev/latest/")

    member _.Read(token: CancellationToken) =
        task {
            let! result = transport.Get(address, "Thunderstore games", token)

            match result with
            | Error problem -> return Error problem
            | Ok document -> use document = document in return Ecosystem.read document.RootElement
        }

    interface IDisposable with
        member _.Dispose() =
            if http.IsNone then
                client.Dispose()
