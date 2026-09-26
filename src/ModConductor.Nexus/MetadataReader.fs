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
            use! game = transport.Api("games/" + identity.Game + ".json", bearer, false, token)

            let path =
                "games/"
                + identity.Game
                + "/mods/"
                + identity.Mod.ToString(CultureInfo.InvariantCulture)

            use! modReply = transport.Api(path + ".json", bearer, false, token)

            use! files =
                if MetadataJson.boolean "available" modReply.RootElement then
                    transport.Api(path + "/files.json", bearer, false, token)
                else
                    Task.FromResult(JsonDocument.Parse("{\"files\":[],\"file_updates\":[]}"))

            return
                MetadataJson.metadata
                    identity
                    game.RootElement
                    modReply.RootElement
                    files.RootElement
        }

    member _.ReadFile(game: string, modId: int64, fileId: int64, bearer, token) =
        task {
            use! reply =
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

            let file = NexusJson.file reply.RootElement

            if file.Id <> fileId then
                NexusJson.fail ()

            return file
        }
