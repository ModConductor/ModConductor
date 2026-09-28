namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.IO
open System.Text.Json
open ModConductor.Platform

module internal ProfileTransportJson =
    [<Literal>]
    let Encoding = "xdelta3-vcdiff-3.2.0-no-app-header"

    let private field (value: JsonElement) (name: string) = value.GetProperty name
    let private text (value: JsonElement) (name: string) = (field value name).GetString()
    let private number (value: JsonElement) (name: string) = (field value name).GetInt64()

    let private items (value: JsonElement) (name: string) =
        (field value name).EnumerateArray() |> Seq.toList

    let private path (value: JsonElement) =
        let parts = value.EnumerateArray() |> Seq.map _.GetString() |> Seq.toList

        LogicalPath.create parts
        |> Result.map LogicalPath.components
        |> Result.defaultWith (fun _ ->
            raise (InvalidDataException "The profile has an invalid file path."))

    let private rootPath (value: JsonElement) =
        if value.GetArrayLength() = 0 then [] else path value

    let private writePath (writer: Utf8JsonWriter) (parts: string list) =
        writer.WriteStartArray()
        parts |> List.iter writer.WriteStringValue
        writer.WriteEndArray()

    let private writeFile (writer: Utf8JsonWriter) (file: PortableFile) =
        writer.WriteStartObject()
        writer.WritePropertyName "path"
        writePath writer file.Path

        match file.Content with
        | PortableContent.Payload(memberName, sha, length) ->
            writer.WriteString("kind", "payload")
            writer.WriteString("member", memberName)
            writer.WriteString("sha256", sha)
            writer.WriteNumber("length", length)
        | PortableContent.Patch(memberName, baseSha, sha, length) ->
            writer.WriteString("kind", "patch")
            writer.WriteString("member", memberName)
            writer.WriteString("baseSha256", baseSha)
            writer.WriteString("sha256", sha)
            writer.WriteNumber("length", length)

        writer.WriteEndObject()

    let private writeFiles (writer: Utf8JsonWriter) (name: string) (files: PortableFile list) =
        writer.WritePropertyName name
        writer.WriteStartArray()
        files |> List.iter (writeFile writer)
        writer.WriteEndArray()

    let private writePaths (writer: Utf8JsonWriter) (name: string) (paths: string list list) =
        writer.WritePropertyName name
        writer.WriteStartArray()
        paths |> List.iter (writePath writer)
        writer.WriteEndArray()

    let private writeStrings (writer: Utf8JsonWriter) (name: string) (values: string list) =
        writer.WritePropertyName name
        writer.WriteStartArray()
        values |> List.iter (fun (value: string) -> writer.WriteStringValue value)
        writer.WriteEndArray()

    let write (profile: PortableProfile) =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream, JsonWriterOptions(Indented = true))
        writer.WriteStartObject()
        writer.WriteNumber("format", 1)
        writer.WriteString("patchEncoding", Encoding)
        writer.WriteString("name", profile.Name)
        writer.WriteString("game", profile.Game)
        writer.WritePropertyName "mods"
        writer.WriteStartArray()

        for value in profile.Mods do
            writer.WriteStartObject()
            writer.WriteString("kind", value.Kind)
            writer.WriteString("name", value.Name)
            writer.WriteString("version", value.Version)
            writer.WriteString("notes", value.Notes)
            writer.WriteString("comment", value.Comment)
            writeStrings writer "categories" value.Categories
            writer.WriteNumber("priority", value.Priority)

            match value.Enabled with
            | Some enabled -> writer.WriteBoolean("enabled", enabled)
            | None -> writer.WriteNull "enabled"

            writer.WritePropertyName "source"

            match value.Source with
            | None -> writer.WriteNullValue()
            | Some source ->
                writer.WriteStartObject()
                writer.WriteString("provider", "nexus")
                writer.WriteString("game", source.Game)
                writer.WriteNumber("mod", source.ModId)
                writer.WriteNumber("file", source.FileId)
                writer.WriteString("fileVersion", source.FileVersion)
                writer.WriteEndObject()

            writer.WritePropertyName "base"

            match value.Base with
            | None -> writer.WriteNullValue()
            | Some source ->
                writer.WriteStartObject()
                writer.WriteString("archiveName", source.ArchiveName)
                writer.WriteString("archiveSha256", source.ArchiveSha256)
                writer.WriteNumber("archiveLength", source.ArchiveLength)
                writer.WritePropertyName "root"
                writePath writer source.Root
                writer.WritePropertyName "selected"
                writer.WriteStartArray()

                for entry in source.Selected do
                    writer.WriteStartObject()
                    writer.WriteNumber("archiveIndex", entry.ArchiveIndex)
                    writer.WritePropertyName "destination"
                    writePath writer entry.Destination
                    writer.WriteEndObject()

                writer.WriteEndArray()
                writer.WriteEndObject()

            writeFiles writer "files" value.Files
            writePaths writer "deleted" value.Deleted
            writePaths writer "hidden" value.Hidden
            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WritePropertyName "pluginOrder"
        writer.WriteStartArray()

        for value in profile.PluginOrder do
            writer.WriteStartObject()
            writer.WriteString("name", value.Name)

            match value.Enabled with
            | Some enabled -> writer.WriteBoolean("enabled", enabled)
            | None -> writer.WriteNull "enabled"

            match value.LockedIndex with
            | Some index -> writer.WriteNumber("lockedIndex", index)
            | None -> writer.WriteNull "lockedIndex"

            writer.WriteEndObject()

        writer.WriteEndArray()
        writer.WriteBoolean("settingsEnabled", profile.SettingsEnabled)
        writer.WriteBoolean("savesEnabled", profile.SavesEnabled)
        writeFiles writer "settings" profile.Settings
        writeFiles writer "saves" profile.Saves
        writer.WritePropertyName "artwork"

        match profile.Artwork with
        | Some value -> writeFile writer value
        | None -> writer.WriteNullValue()

        writer.WriteEndObject()
        writer.Flush()
        stream.ToArray()

    let private readFile (value: JsonElement) =
        let path = field value "path" |> path
        let memberName: string = text value "member"
        let sha: string = text value "sha256"
        let length = number value "length"

        if
            not (memberName.StartsWith("content/", StringComparison.Ordinal))
            || memberName.Length <> 16
            || not (memberName.Substring(8) |> Seq.forall Char.IsAsciiDigit)
            || sha.Length <> 64
            || length < 0L
        then
            raise (InvalidDataException "The profile has an invalid payload reference.")

        let content =
            match text value "kind" with
            | "payload" -> PortableContent.Payload(memberName, sha, length)
            | "patch" ->
                let baseSha = text value "baseSha256"

                if baseSha.Length <> 64 then
                    raise (InvalidDataException "The profile has an invalid patch base.")

                PortableContent.Patch(memberName, baseSha, sha, length)
            | _ -> raise (InvalidDataException "The profile has an unknown file encoding.")

        { Path = path; Content = content }

    let private readFiles (value: JsonElement) (name: string) =
        items value name |> List.map readFile

    let private readPaths (value: JsonElement) (name: string) = items value name |> List.map path

    let private readSource (value: JsonElement) =
        if value.ValueKind = JsonValueKind.Null then
            None
        elif text value "provider" <> "nexus" then
            raise (InvalidDataException "The profile has an unsupported source provider.")
        else
            Some
                { Game = text value "game"
                  ModId = number value "mod"
                  FileId = number value "file"
                  FileVersion = text value "fileVersion" }

    let private readBase (value: JsonElement) =
        if value.ValueKind = JsonValueKind.Null then
            None
        else
            Some
                { ArchiveName = text value "archiveName"
                  ArchiveSha256 = text value "archiveSha256"
                  ArchiveLength = number value "archiveLength"
                  Root = field value "root" |> rootPath
                  Selected =
                    items value "selected"
                    |> List.map (fun entry ->
                        { ArchiveIndex = number entry "archiveIndex" |> int
                          Destination = field entry "destination" |> path }) }

    let private readMod (value: JsonElement) =
        let kind = text value "kind"

        if kind <> "regular" && kind <> "fnis-output" && kind <> "generated-output" then
            raise (InvalidDataException "The profile has an unsupported mod kind.")

        let enabled = field value "enabled"

        { Kind = kind
          Name = text value "name"
          Version = text value "version"
          Notes = text value "notes"
          Comment = text value "comment"
          Categories = items value "categories" |> List.map _.GetString()
          Source = field value "source" |> readSource
          Base = field value "base" |> readBase
          Priority = number value "priority" |> int
          Enabled =
            if enabled.ValueKind = JsonValueKind.Null then
                None
            else
                Some(enabled.GetBoolean())
          Files = readFiles value "files"
          Deleted = readPaths value "deleted"
          Hidden = readPaths value "hidden" }

    let read (bytes: byte array) =
        try
            use document =
                JsonDocument.Parse(ReadOnlyMemory bytes, JsonDocumentOptions(MaxDepth = 64))

            let value = document.RootElement

            if number value "format" <> 1L || text value "patchEncoding" <> Encoding then
                raise (InvalidDataException "This profile format is not supported.")

            if
                value.EnumerateObject()
                |> Seq.exists (fun property -> property.Name = "outputs")
            then
                raise (InvalidDataException "This profile has an unsupported output section.")

            let artwork = field value "artwork"

            { Name = text value "name"
              Game = text value "game"
              Mods = items value "mods" |> List.map readMod
              PluginOrder =
                items value "pluginOrder"
                |> List.map (fun entry ->
                    let enabled = field entry "enabled"
                    let locked = field entry "lockedIndex"

                    { Name = text entry "name"
                      Enabled =
                        if enabled.ValueKind = JsonValueKind.Null then
                            None
                        else
                            Some(enabled.GetBoolean())
                      LockedIndex =
                        if locked.ValueKind = JsonValueKind.Null then
                            None
                        else
                            Some(locked.GetInt32()) })
              SettingsEnabled = (field value "settingsEnabled").GetBoolean()
              SavesEnabled = (field value "savesEnabled").GetBoolean()
              Settings = readFiles value "settings"
              Saves = readFiles value "saves"
              Artwork =
                if artwork.ValueKind = JsonValueKind.Null then
                    None
                else
                    Some(readFile artwork) }
        with
        | :? KeyNotFoundException
        | :? InvalidOperationException
        | :? FormatException
        | :? OverflowException
        | :? JsonException as error ->
            raise (InvalidDataException("The profile metadata is invalid.", error))
