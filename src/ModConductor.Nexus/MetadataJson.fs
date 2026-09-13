namespace ModConductor.Nexus

open System
open System.IO
open System.Text.Json

module internal MetadataJson =
    let text name value =
        NexusJson.optionalText name value |> Option.defaultValue ""

    let boolean name value =
        match NexusJson.field name value with
        | Some field when field.ValueKind = JsonValueKind.True -> true
        | Some field when field.ValueKind = JsonValueKind.False -> false
        | _ -> NexusJson.fail ()

    let timestamp name value =
        NexusJson.optionalNumber name value
        |> Option.map DateTimeOffset.FromUnixTimeSeconds

    let array limit (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Array || value.GetArrayLength() > limit then
            NexusJson.fail ()

        value.EnumerateArray() |> Seq.toList

    let propertyArray name limit value =
        NexusJson.field name value |> Option.map (array limit) |> Option.defaultValue []

    let metadata
        (identity: NexusIdentity)
        (game: JsonElement)
        (value: JsonElement)
        (files: JsonElement)
        =
        if
            NexusJson.text "domain_name" game <> identity.Game
            || NexusJson.number "mod_id" value <> identity.Mod
            || NexusJson.number "game_id" value <> NexusJson.number "id" game
        then
            NexusJson.fail ()

        let categoryId = NexusJson.optionalNumber "category_id" value

        let category =
            propertyArray "categories" 4096 game
            |> List.tryFind (fun c -> Some(NexusJson.number "category_id" c) = categoryId)

        let entries =
            propertyArray "files" 4096 files
            |> List.map (fun item ->
                let file = NexusJson.file item

                if file.Id <= 0L then
                    NexusJson.fail ()

                { File = file
                  CategoryId = int (NexusJson.number "category_id" item)
                  Uploaded = timestamp "uploaded_timestamp" item })

        if
            entries |> List.distinctBy (fun file -> file.File.Id) |> List.length
            <> entries.Length
        then
            NexusJson.fail ()

        let updates =
            propertyArray "file_updates" 8192 files
            |> List.map (fun item ->
                let previous, next =
                    NexusJson.number "old_file_id" item, NexusJson.number "new_file_id" item

                if previous <= 0L || next <= 0L then
                    NexusJson.fail ()

                { Previous = previous; Next = next })

        { Identity = identity
          Name = text "name" value
          Summary = text "summary" value
          Version = text "version" value
          Author = text "author" value
          Uploader = text "uploaded_by" value
          Category =
            category
            |> Option.map (fun c -> NexusJson.number "category_id" c, NexusJson.text "name" c)
          Modified = timestamp "updated_timestamp" value
          Available = boolean "available" value
          AllowsRating = boolean "allow_rating" value
          Files = entries
          Updates = updates }

    let endorsement value =
        match value with
        | "Undecided" -> NexusEndorsement.Undecided
        | "Abstained" -> NexusEndorsement.Abstained
        | "Endorsed" -> NexusEndorsement.Endorsed
        | _ -> NexusJson.fail ()

    let matching (identity: NexusIdentity) value =
        NexusJson.text "domain_name" value = identity.Game
        && NexusJson.number "mod_id" value = identity.Mod

    let tracking identity value =
        array 10000 value |> List.exists (matching identity)

    let endorsements identity value =
        array 10000 value
        |> List.tryFind (matching identity)
        |> Option.map (fun item -> endorsement (NexusJson.text "status" item))
        |> Option.defaultValue NexusEndorsement.Undecided

    let write (fields: (string * Choice<string, int64>) list) =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream)
        writer.WriteStartObject()

        for name, value in fields do
            match value with
            | Choice1Of2(value: string) -> writer.WriteString(name, value)
            | Choice2Of2(value: int64) -> writer.WriteNumber(name, value)

        writer.WriteEndObject()
        writer.Flush()
        stream.ToArray()
