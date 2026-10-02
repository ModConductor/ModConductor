namespace ModConductor.Engine

open ModConductor.GameContexts
open ModConductor.Protocol.V1

type GameCatalogueService() =
    inherit GameCatalogue.GameCatalogueBase()

    override _.ReadGameCatalogue(_, _) =
        task {
            let reply = GameCatalogueReply()
            reply.Games.AddRange(GameCatalog.all () |> Seq.map GameContextWire.definition)
            return reply
        }

    override _.OpenScriptExtenderPage(request, context) =
        task {
            let address =
                GameCatalog.tryParse request.GameId
                |> Option.bind (GameCatalog.tryRules >> Option.bind _.ExtenderUrl)

            match address with
            | None ->
                return
                    OpenScriptExtenderPageReply(
                        Problem = "This game has no registered script extender page."
                    )
            | Some url ->
                try
                    do!
                        ModConductor.Desktop.WebLink.openBrowser (
                            System.Uri url,
                            context.CancellationToken
                        )

                    return OpenScriptExtenderPageReply()
                with :? System.ComponentModel.Win32Exception ->
                    return OpenScriptExtenderPageReply(Problem = "The web browser could not open.")
        }
