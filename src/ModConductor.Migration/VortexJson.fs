namespace ModConductor.Migration

open System
open System.Text.Json

module internal VortexJson =
    open VortexSource
    open MigrationResult

    let maxBackupBytes = 64L * 1024L * 1024L

    let property (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")
        else
            let mutable item = Unchecked.defaultof<JsonElement>

            if value.TryGetProperty(name, &item) then
                Ok item
            else
                invalid ("The Vortex backup is missing " + name + ".")

    let tryProperty (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            None
        else
            let mutable item = Unchecked.defaultof<JsonElement>

            if value.TryGetProperty(name, &item) then
                Some item
            else
                None

    let text (name: string) (value: JsonElement) =
        result {
            let! item = property name value

            if item.ValueKind <> JsonValueKind.String then
                return! invalid ("The Vortex backup has an invalid " + name + ".")

            let text = item.GetString()

            if String.IsNullOrWhiteSpace text then
                return! invalid ("The Vortex backup has an empty " + name + ".")

            return text
        }

    let tryText (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> Ok None
        | Some item when item.ValueKind = JsonValueKind.Null -> Ok None
        | Some item when item.ValueKind = JsonValueKind.String ->
            let text = item.GetString()

            if String.IsNullOrWhiteSpace text then
                Ok None
            else
                Ok(Some text)
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let boolean (name: string) (value: JsonElement) =
        result {
            let! item = property name value

            match item.ValueKind with
            | JsonValueKind.True -> return true
            | JsonValueKind.False -> return false
            | _ -> return! invalid ("The Vortex backup has an invalid " + name + ".")
        }

    let tryBoolean (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> Ok None
        | Some item when item.ValueKind = JsonValueKind.True -> Ok(Some true)
        | Some item when item.ValueKind = JsonValueKind.False -> Ok(Some false)
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let int64Value (name: string) (value: JsonElement) =
        result {
            let! item = property name value
            let mutable parsed = 0L

            if
                item.ValueKind <> JsonValueKind.Number
                || not (item.TryGetInt64(&parsed))
                || parsed < 0L
            then
                return! invalid ("The Vortex backup has an invalid " + name + ".")

            return parsed
        }

    let objectEntries name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")
        else
            let entries = value.EnumerateObject() |> Seq.toList

            if entries.Length > maxEntries then
                invalid ("The Vortex backup contains too many " + name + " entries.")
            else
                Ok entries

    let arrayItems name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Array then
            invalid ("The Vortex backup has invalid " + name + " data.")
        else
            let items = value.EnumerateArray() |> Seq.toList

            if items.Length > maxEntries then
                invalid ("The Vortex backup contains too many " + name + " entries.")
            else
                Ok items

    let document stamp =
        result {
            if stamp.Length > maxBackupBytes then
                return! invalid "The Vortex backup is too large."

            let! stream, identity = openEntry stamp.Root stamp.Path stamp.Identity
            use stream = stream

            if identity <> stamp.Identity || stream.Length <> stamp.Length then
                return! Error Error.SourceChanged

            try
                return
                    JsonDocument.Parse(
                        stream,
                        JsonDocumentOptions(
                            AllowTrailingCommas = false,
                            CommentHandling = JsonCommentHandling.Disallow,
                            MaxDepth = maxDepth
                        )
                    )
            with :? JsonException ->
                return! invalid "The Vortex backup is not valid JSON."
        }
