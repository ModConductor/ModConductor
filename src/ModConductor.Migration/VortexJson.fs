namespace ModConductor.Migration

open System
open System.Text.Json

module internal VortexJson =
    open VortexSource

    let maxBackupBytes = 64L * 1024L * 1024L

    let property (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let mutable result = Unchecked.defaultof<JsonElement>

        if value.TryGetProperty(name, &result) then
            result
        else
            invalid ("The Vortex backup is missing " + name + ".")

    let tryProperty (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            None
        else
            let mutable result = Unchecked.defaultof<JsonElement>

            if value.TryGetProperty(name, &result) then
                Some result
            else
                None

    let text (name: string) (value: JsonElement) =
        let item = property name value

        if item.ValueKind <> JsonValueKind.String then
            invalid ("The Vortex backup has an invalid " + name + ".")

        let result = item.GetString()

        if String.IsNullOrWhiteSpace result then
            invalid ("The Vortex backup has an empty " + name + ".")

        result

    let tryText (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> None
        | Some item when item.ValueKind = JsonValueKind.Null -> None
        | Some item when item.ValueKind = JsonValueKind.String ->
            let result = item.GetString()

            if String.IsNullOrWhiteSpace result then
                None
            else
                Some result
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let boolean (name: string) (value: JsonElement) =
        match (property name value).ValueKind with
        | JsonValueKind.True -> true
        | JsonValueKind.False -> false
        | _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let tryBoolean (name: string) (value: JsonElement) =
        match tryProperty name value with
        | None -> None
        | Some item when item.ValueKind = JsonValueKind.True -> Some true
        | Some item when item.ValueKind = JsonValueKind.False -> Some false
        | Some _ -> invalid ("The Vortex backup has an invalid " + name + ".")

    let int64Value (name: string) (value: JsonElement) =
        let item = property name value
        let mutable result = 0L

        if
            item.ValueKind <> JsonValueKind.Number
            || not (item.TryGetInt64(&result))
            || result < 0L
        then
            invalid ("The Vortex backup has an invalid " + name + ".")

        result

    let objectEntries name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let entries = value.EnumerateObject() |> Seq.toList

        if entries.Length > maxEntries then
            invalid ("The Vortex backup contains too many " + name + " entries.")

        entries

    let arrayItems name (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Array then
            invalid ("The Vortex backup has invalid " + name + " data.")

        let items = value.EnumerateArray() |> Seq.toList

        if items.Length > maxEntries then
            invalid ("The Vortex backup contains too many " + name + " entries.")

        items

    let document stamp =
        if stamp.Length > maxBackupBytes then
            invalid "The Vortex backup is too large."

        let stream, identity = openEntry stamp.Root stamp.Path stamp.Identity
        use stream = stream

        if identity <> stamp.Identity || stream.Length <> stamp.Length then
            refuse Error.SourceChanged

        try
            JsonDocument.Parse(
                stream,
                JsonDocumentOptions(
                    AllowTrailingCommas = false,
                    CommentHandling = JsonCommentHandling.Disallow,
                    MaxDepth = maxDepth
                )
            )
        with :? JsonException ->
            invalid "The Vortex backup is not valid JSON."
