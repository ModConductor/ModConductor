namespace ModConductor.Nexus

open System
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

    let propertyArray name limit value =
        NexusJson.field name value
        |> Option.map (NexusJson.array limit)
        |> Option.defaultValue []

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
