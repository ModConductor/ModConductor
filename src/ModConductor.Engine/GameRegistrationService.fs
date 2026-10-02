namespace ModConductor.Engine

open System.IO
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.GameCatalogue
open ModConductor.GameDiscovery
open ModConductor.Protocol.V1
open ModConductor.SteamDiscovery

type GameRegistrationService(catalogue: Catalogue, discovery: Discovery) =
    inherit GameRegistration.GameRegistrationBase()

    override _.ListInstalledGames(request, context) =
        task {
            let roots =
                DefaultRoots.read ()
                @ (request.AdditionalRoots
                   |> Seq.filter Path.IsPathFullyQualified
                   |> Seq.map (fun path ->
                       { Path = path
                         Origin = "Selected Steam folder" })
                   |> Seq.toList)

            let! result =
                Task.Run(
                    (fun () -> InstalledGames.scan roots context.CancellationToken),
                    context.CancellationToken
                )

            return SteamWire.report result
        }

    override _.SearchThunderstoreGames(request, context) =
        task {
            let! result = discovery.Search(request.Query, context.CancellationToken)
            let reply = ThunderstoreGamesReply()

            match result with
            | Error problem -> reply.Problem <- ModConductor.Thunderstore.Problem.message problem
            | Ok games ->
                reply.Games.AddRange(
                    games
                    |> Seq.map (fun game ->
                        ThunderstoreGameInfo(
                            Id = game.Id,
                            Name = game.Name,
                            Community = game.Community,
                            SuppliesSetup = not game.Executables.IsEmpty
                        ))
                )

            return reply
        }

    override _.DetectGame(request, context) =
        task {
            if not (Path.IsPathFullyQualified request.Path) then
                return DetectGameReply(Problem = "Select an absolute game folder.")
            else
                let! result =
                    discovery.Inspect(
                        request.Path,
                        request.Name,
                        request.SteamAppId,
                        request.ThunderstoreId,
                        context.CancellationToken
                    )

                let reply =
                    DetectGameReply(
                        Draft = GameRegistrationWire.draft result.Draft,
                        DetectedEngine = result.DetectedEngine,
                        Problem = defaultArg result.Problem ""
                    )

                reply.ExecutableChoices.AddRange result.Executables
                return reply
        }

    override _.ReadCustomGame(request, _) =
        task {
            match catalogue.Read request.Id with
            | None -> return CustomGameReply(Problem = "This custom game is not available.")
            | Some d ->
                return
                    CustomGameReply(
                        Draft = GameRegistrationWire.draft d,
                        Game = GameContextWire.definition (Definition.toGame d)
                    )
        }

    override _.SaveCustomGame(request, _) =
        task {
            if isNull request.Draft then
                return CustomGameReply(Problem = "Enter a game definition.")
            else
                let d = GameRegistrationWire.document request.Draft

                match catalogue.Save d with
                | Error problem -> return CustomGameReply(Problem = problem)
                | Ok game ->
                    return
                        CustomGameReply(
                            Draft = GameRegistrationWire.draft d,
                            Game = GameContextWire.definition game
                        )
        }
