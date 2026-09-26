namespace ModConductor.Migration

open System
open System.Text.Json

module internal VortexProfiles =
    open VortexSource
    open VortexJson
    open MigrationResult

    let backupVersion root =
        result {
            let! settings = property "settings" root
            let! _ = objectEntries "settings" settings
            let! user = property "user" root
            let! _ = objectEntries "user" user
            let! app = property "app" root
            let! version = text "appVersion" app

            if version <> "2.6.3" then
                return! unsupported "Choose a full-state backup made by Vortex 2.6.3."
        }

    let profileEntries root =
        result {
            let! persistent = property "persistent" root
            let! profiles = property "profiles" persistent
            return! objectEntries "profiles" profiles
        }

    let profileName value =
        result {
            let! name = text "name" value

            if name.Length > 256 || name.Contains '\000' then
                return! invalid "A Vortex profile has an invalid name."

            return name.Trim()
        }

    let readProfiles backup =
        result {
            let! stamp = directFile backup "Vortex backup file"
            use! parsed = document stamp
            do! backupVersion parsed.RootElement
            let! entries = profileEntries parsed.RootElement

            let! profiles =
                entries
                |> traverse (fun entry ->
                    result {
                        let value = entry.Value
                        let! id = text "id" value

                        if id <> entry.Name then
                            return! invalid "A Vortex profile ID does not match its backup key."

                        let! name = profileName value
                        let! gameId = text "gameId" value
                        return id, name, gameId
                    })

            return
                profiles
                |> List.sortWith (fun (leftId, leftName, _) (rightId, rightName, _) ->
                    let name = StringComparer.OrdinalIgnoreCase.Compare(leftName, rightName)

                    if name <> 0 then
                        name
                    else
                        StringComparer.Ordinal.Compare(leftId, rightId))
        }

    let categoryId (value: string) =
        let mutable parsed = 0

        if Int32.TryParse(value, &parsed) && parsed > 0 then
            Ok parsed
        else
            invalid "The Vortex backup has an invalid category ID."

    let private category (entry: JsonProperty) =
        result {
            let value = entry.Value
            let! parent = tryText "parentCategory" value
            let! label = text "name" value

            if label.Length > 256 || label.Contains '\000' then
                return! invalid "A Vortex category has an invalid name."

            let! id = categoryId entry.Name

            let! parentId =
                match parent with
                | None -> Ok None
                | Some item when item = "" || item = "0" -> Ok None
                | Some item -> categoryId item |> Result.map Some

            return
                { SourceId = id
                  Label = label.Trim()
                  ParentSourceId = parentId }
        }

    let private validateCategoryIds (categories: Category list) =
        let ids = categories |> List.map _.SourceId

        if ids.Length <> (ids |> Set.ofList |> Set.count) then
            invalid "The Vortex categories contain duplicate IDs."
        else
            let known = Set.ofList ids

            match
                categories
                |> List.choose _.ParentSourceId
                |> List.tryFind (fun id -> not (known.Contains id))
            with
            | Some _ -> invalid "A Vortex category has a missing parent."
            | None -> Ok()

    let private validateCategoryCycles (categories: Category list) =
        let mutable mapped = Set.empty
        let mutable remaining = categories
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
        else
            Ok()

    let private validateCategoryDepth (categories: Category list) =
        result {
            let byId = categories |> Seq.map (fun item -> item.SourceId, item) |> dict

            for item in categories do
                let mutable depth = 1
                let mutable parent = item.ParentSourceId

                while parent.IsSome do
                    if depth >= 16 then
                        return! invalid "The Vortex categories are nested too deeply."

                    depth <- depth + 1
                    parent <- byId[parent.Value].ParentSourceId
        }

    let categories (persistent: JsonElement) (gameId: string) =
        result {
            let! categories =
                match tryProperty "categories" persistent |> Option.bind (tryProperty gameId) with
                | None -> Ok []
                | Some value ->
                    result {
                        let! entries = objectEntries "categories" value
                        return! traverse category entries
                    }

            do! validateCategoryIds categories
            do! validateCategoryCycles categories
            do! validateCategoryDepth categories
            return categories
        }
