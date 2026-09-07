namespace ModConductor.Persistence

open System
open System.IO
open System.Text.Json
open ModConductor.GameContexts
open ModConductor.Platform

module internal GameContextEncoding =
    let encode (e: InstallationEvidence) =
        use output = new MemoryStream()
        use w = new Utf8JsonWriter(output)
        let text (name: string) (value: string) = w.WriteString(name, value)

        let identity name (id: FileIdentity) =
            w.WriteStartObject(name: string)

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

        let location name value =
            w.WriteStartObject(name: string)

            match value with
            | Location.Located(path, exists) ->
                text "path" path
                w.WriteBoolean("exists", exists)
            | Location.Unavailable reason -> text "reason" reason

            w.WriteEndObject()

        w.WriteStartObject()
        text "definition" e.DefinitionId
        w.WriteNumber("definitionRevision", e.DefinitionRevision)

        w.WriteNumber(
            "platform",
            match e.Platform with
            | ContextPlatform.Windows -> 1
            | ContextPlatform.Proton -> 2
        )

        text "root" e.RootPath
        e.RootIdentity |> Option.iter (identity "rootIdentity")
        e.DataPath |> Option.iter (text "data")
        e.DataIdentity |> Option.iter (identity "dataIdentity")
        e.LauncherPath |> Option.iter (text "launcher")

        match e.Executable with
        | None -> ()
        | Some executable ->
            w.WriteStartObject("executable")
            text "path" executable.Path
            identity "identity" executable.Identity
            w.WriteNumber("length", executable.Length)
            text "sha256" executable.Sha256
            text "fileVersion" executable.FileVersion
            text "productVersion" executable.ProductVersion
            w.WriteEndObject()

        e.Proton
        |> Option.iter (fun p ->
            w.WritePropertyName("proton")
            ProtonEncoding.write w p)

        location "documents" e.Locations.Documents
        location "saves" e.Locations.Saves
        location "localAppData" e.Locations.LocalAppData
        w.WriteStartArray("problems")

        for issue in e.Problems do
            w.WriteStartObject()
            text "path" issue.Path
            text "detail" issue.Detail
            w.WriteEndObject()

        w.WriteEndArray()
        w.WriteNumber("checkedAt", e.CheckedAt.ToUnixTimeMilliseconds())
        text "fingerprint" e.Fingerprint
        w.WriteEndObject()
        w.Flush()
        System.Text.Encoding.UTF8.GetString(output.ToArray())

    let decode (value: string) : InstallationEvidence =
        use document = JsonDocument.Parse value
        let root = document.RootElement
        let get (e: JsonElement) (name: string) = e.GetProperty name
        let text e name = (get e name).GetString()

        let optional (e: JsonElement) (name: string) project =
            let mutable value = Unchecked.defaultof<JsonElement>

            if e.TryGetProperty(name, &value) then
                Some(project value)
            else
                None

        let identity e =
            { Device =
                match (get e "kind").GetInt32() with
                | 1 -> LinuxDevice((get e "major").GetUInt32(), (get e "minor").GetUInt32())
                | 2 -> WindowsVolume((get e "serial").GetUInt64())
                | _ -> invalidOp "Invalid stored context identity."
              Low = (get e "low").GetUInt64()
              High = (get e "high").GetUInt64() }

        let location name =
            let e = get root name

            match optional e "path" (fun x -> x.GetString()) with
            | Some path -> Location.Located(path, (get e "exists").GetBoolean())
            | None -> Location.Unavailable(text e "reason")

        { DefinitionId = text root "definition"
          DefinitionRevision = (get root "definitionRevision").GetInt32()
          Platform =
            match (get root "platform").GetInt32() with
            | 1 -> ContextPlatform.Windows
            | 2 -> ContextPlatform.Proton
            | _ -> invalidOp "Invalid stored context platform."
          RootPath = text root "root"
          RootIdentity = optional root "rootIdentity" identity
          DataPath = optional root "data" (fun x -> x.GetString())
          DataIdentity = optional root "dataIdentity" identity
          LauncherPath = optional root "launcher" (fun x -> x.GetString())
          Executable =
            optional root "executable" (fun e ->
                { Path = text e "path"
                  Identity = identity (get e "identity")
                  Length = (get e "length").GetInt64()
                  Sha256 = text e "sha256"
                  FileVersion = text e "fileVersion"
                  ProductVersion = text e "productVersion" })
          Proton = optional root "proton" ProtonEncoding.read
          Locations =
            { Documents = location "documents"
              Saves = location "saves"
              LocalAppData = location "localAppData" }
          Problems =
            [ for p in (get root "problems").EnumerateArray() ->
                  { Path = text p "path"
                    Detail = text p "detail" } ]
          CheckedAt = DateTimeOffset.FromUnixTimeMilliseconds((get root "checkedAt").GetInt64())
          Fingerprint = text root "fingerprint" }
