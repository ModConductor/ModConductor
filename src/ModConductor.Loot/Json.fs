namespace ModConductor.Loot

open System
open System.IO
open System.Text
open System.Text.Json

module internal LootJson =
    let request
        (operation: string)
        (correlation: string)
        (staging: string)
        (game: string)
        (local: string)
        (metadata: LootMetadata)
        (plugins: string list)
        (fingerprint: string)
        =
        use bytes = new MemoryStream()
        use writer = new Utf8JsonWriter(bytes)
        writer.WriteStartObject()
        writer.WriteNumber("protocol", 1)
        writer.WriteString("operation", operation)
        writer.WriteString("correlationId", correlation)
        writer.WriteString("capabilityId", "skyrim-se-steam")
        writer.WriteString("stagingRoot", staging)
        writer.WriteString("gameRoot", game)
        writer.WriteString("localPath", local)
        writer.WriteString("metadataRoot", Path.GetDirectoryName metadata.MasterlistPath)
        writer.WriteString("masterlistPath", metadata.MasterlistPath)
        writer.WriteString("preludePath", metadata.PreludePath)
        writer.WriteNull("userlistPath")
        writer.WriteStartArray("plugins")
        plugins |> List.iter (fun value -> writer.WriteStringValue(value: string))
        writer.WriteEndArray()
        writer.WriteString("sourceFingerprint", fingerprint)
        writer.WriteString("metadataRevision", metadata.Revision)
        writer.WriteEndObject()
        writer.Flush()
        bytes.ToArray()

    let private requiredString (root: JsonElement) (name: string) =
        match root.TryGetProperty name with
        | true, value when value.ValueKind = JsonValueKind.String -> value.GetString()
        | _ -> raise (InvalidDataException("The helper response is missing " + name + "."))

    let private requiredInt (root: JsonElement) (name: string) =
        match root.TryGetProperty name with
        | true, value when value.TryGetInt32() |> fst -> value.GetInt32()
        | _ -> raise (InvalidDataException("The helper response is missing " + name + "."))

    let private strings (root: JsonElement) (name: string) =
        match root.TryGetProperty name with
        | true, value when value.ValueKind = JsonValueKind.Array ->
            [ for item in value.EnumerateArray() do
                  if item.ValueKind <> JsonValueKind.String then
                      raise (InvalidDataException("The helper response contains an invalid name."))

                  yield item.GetString() ]
        | _ -> raise (InvalidDataException("The helper response is missing " + name + "."))

    type Response =
        { Correlation: string
          Capability: string
          Fingerprint: string
          MetadataRevision: string
          HelperRevision: string
          LiblootVersion: string
          LiblootRevision: string
          Current: string list
          Sorted: string list
          Moves: LootMove list
          Messages: LootMessage list }

    let response (bytes: byte array) =
        use document = JsonDocument.Parse bytes
        let root = document.RootElement

        if requiredInt root "protocol" <> 1 then
            raise (InvalidDataException "The helper protocol version is not supported.")

        let moves: LootMove list =
            match root.TryGetProperty "moves" with
            | true, value when value.ValueKind = JsonValueKind.Array ->
                [ for item in value.EnumerateArray() do
                      yield
                          { Plugin = requiredString item "plugin"
                            Current = requiredInt item "current"
                            Proposed = requiredInt item "proposed"
                            Reason = requiredString item "reason" } ]
            | _ -> raise (InvalidDataException "The helper response is missing moves.")

        let messages: LootMessage list =
            match root.TryGetProperty "messages" with
            | true, value when value.ValueKind = JsonValueKind.Array ->
                [ for item in value.EnumerateArray() do
                      let plugin = requiredString item "plugin"

                      yield
                          { Plugin = if plugin = "" then None else Some plugin
                            Level = requiredString item "level"
                            Text = requiredString item "text" } ]
            | _ -> raise (InvalidDataException "The helper response is missing messages.")

        { Correlation = requiredString root "correlationId"
          Capability = requiredString root "capabilityId"
          Fingerprint = requiredString root "sourceFingerprint"
          MetadataRevision = requiredString root "metadataRevision"
          HelperRevision = requiredString root "helperRevision"
          LiblootVersion = requiredString root "liblootVersion"
          LiblootRevision = requiredString root "liblootRevision"
          Current = strings root "current"
          Sorted = strings root "sorted"
          Moves = moves
          Messages = messages }

    let metadataManifest (value: LootMetadata) =
        use bytes = new MemoryStream()
        use writer = new Utf8JsonWriter(bytes)
        writer.WriteStartObject()
        writer.WriteNumber("version", 1)
        writer.WriteString("revision", value.Revision)
        writer.WriteString("masterlistCommit", value.MasterlistCommit)
        writer.WriteString("preludeCommit", value.PreludeCommit)
        writer.WriteString("masterlistSha256", value.MasterlistSha256)
        writer.WriteString("preludeSha256", value.PreludeSha256)
        writer.WriteString("masterlistPath", value.MasterlistPath)
        writer.WriteString("preludePath", value.PreludePath)
        writer.WriteString("fetchedAt", value.FetchedAt)
        writer.WriteEndObject()
        writer.Flush()
        bytes.ToArray()

    let readMetadataManifest (path: string) =
        let bytes = File.ReadAllBytes path

        if bytes.Length > 64 * 1024 then
            raise (InvalidDataException "The LOOT metadata manifest exceeds its read limit.")

        use document = JsonDocument.Parse bytes
        let root = document.RootElement

        if requiredInt root "version" <> 1 then
            raise (InvalidDataException "The LOOT metadata manifest version is unsupported.")

        { Revision = requiredString root "revision"
          MasterlistCommit = requiredString root "masterlistCommit"
          PreludeCommit = requiredString root "preludeCommit"
          MasterlistSha256 = requiredString root "masterlistSha256"
          PreludeSha256 = requiredString root "preludeSha256"
          MasterlistPath = requiredString root "masterlistPath"
          PreludePath = requiredString root "preludePath"
          FetchedAt = root.GetProperty("fetchedAt").GetDateTimeOffset() }

    let commit (bytes: byte array) =
        use document = JsonDocument.Parse bytes
        requiredString document.RootElement "sha"
