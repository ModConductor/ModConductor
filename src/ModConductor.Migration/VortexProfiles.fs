namespace ModConductor.Migration

open System
open System.Text.Json

module internal VortexProfiles =
    open VortexSource
    open VortexJson

    let backupVersion root =
        property "settings" root |> objectEntries "settings" |> ignore
        property "user" root |> objectEntries "user" |> ignore
        let app = property "app" root
        let version = text "appVersion" app

        if version <> "2.6.3" then
            unsupported "Choose a full-state backup made by Vortex 2.6.3."

    let profileEntries root =
        let persistent = property "persistent" root
        property "profiles" persistent |> objectEntries "profiles"

    let profileName value =
        let name = text "name" value

        if name.Length > 256 || name.Contains '\000' then
            invalid "A Vortex profile has an invalid name."

        name.Trim()

    let readProfiles backup =
        let stamp = directFile backup "Vortex backup file"
        use parsed = document stamp
        backupVersion parsed.RootElement

        profileEntries parsed.RootElement
        |> List.map (fun entry ->
            let value = entry.Value
            let id = text "id" value

            if id <> entry.Name then
                invalid "A Vortex profile ID does not match its backup key."

            id, profileName value, text "gameId" value)
        |> List.sortWith (fun (leftId, leftName, _) (rightId, rightName, _) ->
            let name = StringComparer.OrdinalIgnoreCase.Compare(leftName, rightName)

            if name <> 0 then
                name
            else
                StringComparer.Ordinal.Compare(leftId, rightId))

    let categoryId (value: string) =
        let mutable parsed = 0

        if Int32.TryParse(value, &parsed) && parsed > 0 then
            parsed
        else
            invalid "The Vortex backup has an invalid category ID."

    let private category (entry: JsonProperty) =
        let value = entry.Value
        let parent = tryText "parentCategory" value
        let label = text "name" value

        if label.Length > 256 || label.Contains '\000' then
            invalid "A Vortex category has an invalid name."

        { SourceId = categoryId entry.Name
          Label = label.Trim()
          ParentSourceId =
            parent
            |> Option.bind (fun item ->
                if item = "" || item = "0" then
                    None
                else
                    Some(categoryId item)) }

    let private validateCategoryIds (result: Category list) =
        let ids = result |> List.map _.SourceId

        if ids.Length <> (ids |> Set.ofList |> Set.count) then
            invalid "The Vortex categories contain duplicate IDs."

        let known = Set.ofList ids

        result
        |> List.choose _.ParentSourceId
        |> List.tryFind (fun id -> not (known.Contains id))
        |> Option.iter (fun _ -> invalid "A Vortex category has a missing parent.")

    let private validateCategoryCycles (result: Category list) =
        let mutable mapped = Set.empty
        let mutable remaining = result
        let mutable changed = true

        while not remaining.IsEmpty && changed do
            let ready, blocked =
                remaining
                |> List.partition (fun item ->
                    item.ParentSourceId |> Option.forall (fun parent -> mapped.Contains parent))

            mapped <- ready |> List.fold (fun state item -> state.Add item.SourceId) mapped
            remaining <- blocked
            changed <- not ready.IsEmpty

        if not remaining.IsEmpty then
            invalid "The Vortex categories contain a parent cycle."

    let private validateCategoryDepth (result: Category list) =
        let byId = result |> Seq.map (fun item -> item.SourceId, item) |> dict

        for item in result do
            let mutable depth = 1
            let mutable parent = item.ParentSourceId

            while parent.IsSome do
                if depth >= 16 then
                    invalid "The Vortex categories are nested too deeply."

                depth <- depth + 1
                parent <- byId[parent.Value].ParentSourceId

    let categories (persistent: JsonElement) (gameId: string) =
        let result =
            tryProperty "categories" persistent
            |> Option.bind (tryProperty gameId)
            |> Option.map (objectEntries "categories" >> List.map category)
            |> Option.defaultValue []

        validateCategoryIds result
        validateCategoryCycles result
        validateCategoryDepth result
        result
