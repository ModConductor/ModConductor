namespace ModConductor.GameDiscovery

open System.Threading
open ModConductor.GameContexts
open ModConductor.GameCatalogue.Serialization
open ModConductor.Thunderstore

type Detection =
    { Draft: GameDocument
      DetectedEngine: string
      Executables: string list
      Problem: string option }

type Discovery(reader: EcosystemReader, packages: IPackageReader) =
    member _.Search(query, token) =
        task {
            let! result = reader.Read token
            return result |> Result.map (Ecosystem.search query)
        }

    member _.Inspect(root, name, app, metadataId: string, token: CancellationToken) =
        task {
            let known =
                GameCatalog.definitions
                |> List.tryFind (fun row ->
                    app <> 0u
                    && metadataId = ""
                    && List.contains app row.SteamAppIds
                    && not (GameCatalog.isBethesda row.Id))

            let! metadata =
                if known.IsSome then
                    System.Threading.Tasks.Task.FromResult(Ok [])
                else
                    reader.Read token

            let selected =
                metadata
                |> Result.toOption
                |> Option.bind (fun rows ->
                    if metadataId <> "" then
                        rows |> List.tryFind (fun row -> row.Id = metadataId)
                    else
                        rows
                        |> List.filter (Ecosystem.matchesSteam app)
                        |> function
                            | [ one ] -> Some one
                            | _ -> None)

            let d =
                known
                |> Option.map KnownDefinition.draft
                |> Option.defaultValue (GameDocument(Name = name, SteamAppId = app))

            selected
            |> Option.iter (fun game ->
                if known.IsNone then
                    d.Content <- game.Content

                    d.Executable <-
                        game.Executables
                        |> List.tryFind (fun path ->
                            path.EndsWith(".exe", System.StringComparison.OrdinalIgnoreCase))
                        |> Option.defaultValue ""

                d.Community <- game.Community)

            match InstallationDetection.inspect root d with
            | Error problem ->
                return
                    { Draft = d
                      DetectedEngine = ""
                      Executables = []
                      Problem = Some problem }
            | Ok(d, choices, engine) ->
                match selected with
                | Some game when
                    known.IsNone
                    && Ecosystem.supportsBepInEx game
                    && d.Mechanism.StartsWith("unity-", System.StringComparison.Ordinal)
                    ->
                    match game.Loader with
                    | None -> ()
                    | Some loader ->
                        let reference =
                            { Community = game.Community
                              Namespace = loader.Namespace
                              Name = loader.Name }

                        let! details = packages.Details(reference, None, token)

                        match details with
                        | Error _ -> ()
                        | Ok details ->
                            d.LoaderNamespace <- loader.Namespace
                            d.LoaderPackage <- loader.Name
                            d.LoaderVersion <- details.Reference.Version
                            d.ArchiveRoot <- loader.ArchiveRoot
                | _ -> ()

                let detected = engine

                if known.IsNone && not (selected |> Option.exists Ecosystem.supportsBepInEx) then
                    d.Mechanism <- ""

                let problem =
                    match selected with
                    | Some game when
                        game.PackageLoader <> "" && game.PackageLoader <> "bepinex" && known.IsNone
                        ->
                        Some(
                            "This Thunderstore loader is not implemented: "
                            + game.PackageLoader
                            + "."
                        )
                    | Some game when game.Executables.IsEmpty ->
                        Some "This community does not supply mod setup."
                    | None when Result.isError metadata ->
                        Some "Thunderstore is not available. Enter the missing mod setup fields."
                    | _ -> None

                return
                    { Draft = d
                      DetectedEngine = detected
                      Executables = choices
                      Problem = problem }
        }
