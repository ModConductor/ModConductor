namespace ModConductor.Persistence

open System.IO
open System.Text.Json
open ModConductor.GameContexts

module internal WineEncoding =
    let writeSelection (writer: Utf8JsonWriter) (selection: WineSelection) =
        writer.WriteStartObject()
        writer.WriteString("executable", selection.Executable)
        writer.WriteString("prefix", selection.Prefix)
        writer.WriteEndObject()

    let readSelection (value: JsonElement) : WineSelection =
        { Executable = value.GetProperty("executable").GetString()
          Prefix = value.GetProperty("prefix").GetString() }

    let encodeSelection selection =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream)
        writeSelection writer selection
        writer.Flush()
        System.Text.Encoding.UTF8.GetString(stream.ToArray())

    let decodeSelection (value: string) =
        use document = JsonDocument.Parse value
        readSelection document.RootElement

    let write (writer: Utf8JsonWriter) (evidence: WineEvidence) =
        writer.WriteStartObject()
        writer.WritePropertyName("selection")
        writeSelection writer evidence.Selection
        writer.WritePropertyName("prefixIdentity")
        ProtonEncoding.writeIdentity writer evidence.PrefixIdentity
        writer.WritePropertyName("executableIdentity")
        ProtonEncoding.writeIdentity writer evidence.ExecutableIdentity
        writer.WriteStartArray("paths")

        for path in evidence.Paths do
            writer.WriteStartObject()
            writer.WriteString("name", path.Name)

            path.WindowsPath
            |> Option.iter (fun value -> writer.WriteString("windows", value))

            match path.HostLocation with
            | Location.Located(value, exists) ->
                writer.WriteString("path", value)
                writer.WriteBoolean("exists", exists)
            | Location.Unavailable reason -> writer.WriteString("reason", reason)

            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteEndObject()

    let read (value: JsonElement) : WineEvidence =
        { Selection = readSelection (value.GetProperty "selection")
          PrefixIdentity = ProtonEncoding.readIdentity (value.GetProperty "prefixIdentity")
          ExecutableIdentity = ProtonEncoding.readIdentity (value.GetProperty "executableIdentity")
          Paths =
            [ for path in value.GetProperty("paths").EnumerateArray() do
                  let mutable windows = Unchecked.defaultof<JsonElement>
                  let mutable located = Unchecked.defaultof<JsonElement>

                  yield
                      { Name = path.GetProperty("name").GetString()
                        WindowsPath =
                          if path.TryGetProperty("windows", &windows) then
                              Some(windows.GetString())
                          else
                              None
                        HostLocation =
                          if path.TryGetProperty("path", &located) then
                              Location.Located(
                                  located.GetString(),
                                  path.GetProperty("exists").GetBoolean()
                              )
                          else
                              Location.Unavailable(path.GetProperty("reason").GetString()) } ] }
