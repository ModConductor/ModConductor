namespace ModConductor.Nexus

open System
open System.Globalization
open System.Text.Json
open System.Threading
open System.Threading.Tasks

type internal MetadataReader(transport: NexusTransport) =
    member _.ReadMetadata
        (identity: NexusIdentity, bearer: NexusAuthorization, token: CancellationToken)
        =
        task {
            let! gameResult =
                transport.Api("games/" + identity.Game + ".json", bearer, false, token)

            match gameResult with
            | Error error -> return Error error
            | Ok game ->
                use game = game

                let path =
                    "games/"
                    + identity.Game
                    + "/mods/"
                    + identity.Mod.ToString(CultureInfo.InvariantCulture)

                let! modResult = transport.Api(path + ".json", bearer, false, token)

                match modResult with
                | Error error -> return Error error
                | Ok modReply ->
                    use modReply = modReply

                    let! fileResult =
                        if MetadataJson.boolean "available" modReply.RootElement then
                            transport.Api(path + "/files.json", bearer, false, token)
                        else
                            Task.FromResult(
                                Ok(JsonDocument.Parse("{\"files\":[],\"file_updates\":[]}"))
                            )

                    match fileResult with
                    | Error error -> return Error error
                    | Ok files ->
                        use files = files

                        return
                            Ok(
                                MetadataJson.metadata
                                    identity
                                    game.RootElement
                                    modReply.RootElement
                                    files.RootElement
                            )
        }

    member _.ReadFile(game: string, modId: int64, fileId: int64, bearer, token) =
        task {
            let! result =
                transport.Api(
                    ("games/"
                     + game
                     + "/mods/"
                     + modId.ToString(CultureInfo.InvariantCulture)
                     + "/files/"
                     + fileId.ToString(CultureInfo.InvariantCulture)
                     + ".json"),
                    bearer,
                    false,
                    token
                )

            match result with
            | Error error -> return Error error
            | Ok reply ->
                use reply = reply
                let file = NexusJson.file reply.RootElement

                if file.Id <> fileId then
                    NexusJson.fail ()

                return Ok file
        }
