namespace ModConductor.Persistence

open System
open System.IO
open System.Text.Json
open ModConductor.GameContexts
open ModConductor.Platform

module internal ProtonEncoding =
    let writeSelection (w: Utf8JsonWriter) (s: ProtonSelection) =
        w.WriteStartObject()
        w.WriteNumber("appId", s.AppId)

        match s.Association with
        | ProtonAssociation.Manual -> w.WriteString("association", "manual")
        | ProtonAssociation.Steam(root, library) ->
            w.WriteString("association", "steam")
            w.WriteString("steamRoot", root)
            w.WriteString("library", library)

        w.WriteString("compatdata", s.CompatData)
        w.WriteString("runtime", s.RuntimeDirectory)
        w.WriteString("toolId", s.ToolId)
        w.WriteEndObject()

    let private get (e: JsonElement) (name: string) = e.GetProperty name
    let private text e name = (get e name).GetString()

    let private optional (e: JsonElement) (name: string) =
        let mutable value = Unchecked.defaultof<JsonElement>

        if e.TryGetProperty(name, &value) then
            Some(value.GetString())
        else
            None

    let readSelection e : ProtonSelection =
        { AppId = (get e "appId").GetUInt32()
          Association =
            match text e "association" with
            | "manual" -> ProtonAssociation.Manual
            | "steam" -> ProtonAssociation.Steam(text e "steamRoot", text e "library")
            | _ -> invalidOp "Invalid stored Proton association."
          CompatData = text e "compatdata"
          RuntimeDirectory = text e "runtime"
          ToolId = text e "toolId" }

    let encodeSelection s =
        use output = new MemoryStream()
        use w = new Utf8JsonWriter(output)
        writeSelection w s
        w.Flush()
        System.Text.Encoding.UTF8.GetString(output.ToArray())

    let decodeSelection (json: string) =
        use d = JsonDocument.Parse json
        readSelection d.RootElement

    let writeIdentity (w: Utf8JsonWriter) (id: FileIdentity) =
        w.WriteStartObject()

        match id.Device with
        | LinuxDevice(major, minor) ->
            w.WriteNumber("kind", 1)
            w.WriteNumber("major", major)
            w.WriteNumber("minor", minor)
        | WindowsVolume serial ->
            w.WriteNumber("kind", 2)
            w.WriteNumber("serial", serial)

        w.WriteNumber("low", id.Low)
        w.WriteNumber("high", id.High)
        w.WriteEndObject()

    let readIdentity e =
        { Device =
            match (get e "kind").GetInt32() with
            | 1 -> LinuxDevice((get e "major").GetUInt32(), (get e "minor").GetUInt32())
            | 2 -> WindowsVolume((get e "serial").GetUInt64())
            | _ -> invalidOp "Invalid stored Proton file identity."
          Low = (get e "low").GetUInt64()
          High = (get e "high").GetUInt64() }

    let write (w: Utf8JsonWriter) (e: ProtonEvidence) =
        let text (name: string) (value: string) = w.WriteString(name, value)

        let identity name value =
            w.WritePropertyName(name: string)
            writeIdentity w value

        let file (f: ContextFileEvidence) =
            w.WriteStartObject()
            text "path" f.Path
            identity "identity" f.Identity
            text "hash" f.Sha256
            w.WriteEndObject()

        w.WriteStartObject()
        w.WritePropertyName("selection")
        writeSelection w e.Selection
        text "prefix" e.PrefixPath
        identity "prefixIdentity" e.PrefixIdentity
        identity "compatdataIdentity" e.CompatDataIdentity
        identity "runtimeIdentity" e.RuntimeIdentity
        text "runtimeName" e.RuntimeName
        text "runtimeVersion" e.RuntimeVersion
        e.PrefixVersion |> Option.iter (text "prefixVersion")
        e.PerGameTool |> Option.iter (text "perGameTool")
        e.GlobalTool |> Option.iter (text "globalTool")
        e.MappingProblem |> Option.iter (text "mappingProblem")
        w.WritePropertyName("launcher")
        file e.Launcher
        w.WriteStartArray("metadata")
        e.Metadata |> List.iter file
        w.WriteEndArray()
        w.WriteStartArray("paths")

        for path in e.Paths do
            w.WriteStartObject()
            text "name" path.Name
            path.WindowsPath |> Option.iter (text "windows")

            match path.HostLocation with
            | Location.Unavailable reason -> text "reason" reason
            | Location.Located(path, exists) ->
                text "path" path
                w.WriteBoolean("exists", exists)

            w.WriteEndObject()

        w.WriteEndArray()
        w.WriteEndObject()

    let read e : ProtonEvidence =
        let file e : ContextFileEvidence =
            { Path = text e "path"
              Identity = readIdentity (get e "identity")
              Sha256 = text e "hash" }

        { Selection = readSelection (get e "selection")
          PrefixPath = text e "prefix"
          PrefixIdentity = readIdentity (get e "prefixIdentity")
          CompatDataIdentity = readIdentity (get e "compatdataIdentity")
          RuntimeIdentity = readIdentity (get e "runtimeIdentity")
          RuntimeName = text e "runtimeName"
          RuntimeVersion = text e "runtimeVersion"
          PrefixVersion = optional e "prefixVersion"
          PerGameTool = optional e "perGameTool"
          GlobalTool = optional e "globalTool"
          MappingProblem = optional e "mappingProblem"
          Launcher = file (get e "launcher")
          Metadata = [ for f in (get e "metadata").EnumerateArray() -> file f ]
          Paths =
            [ for p in (get e "paths").EnumerateArray() ->
                  { Name = text p "name"
                    WindowsPath = optional p "windows"
                    HostLocation =
                      match optional p "path" with
                      | Some path -> Location.Located(path, (get p "exists").GetBoolean())
                      | None -> Location.Unavailable(text p "reason") } ] }
