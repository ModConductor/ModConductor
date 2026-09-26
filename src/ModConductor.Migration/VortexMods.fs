namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.IO
open System.Text.Json
open ModConductor.ModLibrary
open ModConductor.Platform

module internal VortexMods =
    open VortexSource
    open VortexJson
    open VortexProfiles
    open MigrationResult

    type ParsedMod =
        { SourceId: string
          Id: Guid
          VersionId: Guid
          ArchiveId: string option
          Metadata: ModMetadata
          CategorySourceIds: int list
          Rules: JsonElement option
          Files: Direct.File list }

    let private attributeText (names: string list) (value: JsonElement) =
        result {
            let mutable found = None

            for name in names do
                if found.IsNone then
                    let! candidate = tryText name value
                    found <- candidate

            return found
        }

    let private safeSource (value: string) =
        match Uri.TryCreate(value, UriKind.Absolute) with
        | true, uri when
            (uri.Scheme = Uri.UriSchemeHttp || uri.Scheme = Uri.UriSchemeHttps)
            && String.IsNullOrEmpty uri.UserInfo
            ->
            let builder = UriBuilder uri
            builder.Query <- ""
            builder.Fragment <- ""
            builder.Uri.AbsoluteUri
        | true, _ -> ""
        | false, _ -> value

    let private categoryReferences (attributes: JsonElement) =
        match tryProperty "category" attributes with
        | None -> Ok []
        | Some item when item.ValueKind = JsonValueKind.Null -> Ok []
        | Some item when item.ValueKind = JsonValueKind.Number ->
            let mutable value = 0

            if item.TryGetInt32(&value) && value > 0 then
                Ok [ value ]
            else
                invalid "A mod has an invalid category."
        | Some item when item.ValueKind = JsonValueKind.String ->
            let value = item.GetString()

            if String.IsNullOrWhiteSpace value then
                Ok []
            else
                categoryId value |> Result.map List.singleton
        | Some _ -> invalid "A mod has an invalid category."

    let private exactDirectory (entries: PathEntry list) (name: string) =
        entries
        |> List.tryFind (fun entry ->
            match components entry with
            | [ first ] ->
                entry.TargetKind = EntryKind.Directory
                && String.Equals(first, name, StringComparison.Ordinal)
            | _ -> false)

    let private modFiles (root: SelectedRoot) (entries: PathEntry list) (installationPath: string) =
        result {
            if
                installationPath.IndexOfAny(
                    [| Path.DirectorySeparatorChar; Path.AltDirectorySeparatorChar; '\\'; '/' |]
                )
                >= 0
            then
                return! unsupported "A Vortex mod uses a nested staging path."

            if exactDirectory entries installationPath |> Option.isNone then
                return! invalid ("The staging folder is missing the mod " + installationPath + ".")

            let files = ResizeArray<Direct.File * Stamp>()

            for entry in entries do
                match components entry with
                | first :: rest when
                    first = installationPath
                    && entry.TargetKind = EntryKind.RegularFile
                    && not rest.IsEmpty
                    ->
                    let! identity =
                        match entry.Facts.File with
                        | Known value -> Ok value
                        | Unknown detail -> Error(Error.UnsafeSource detail)

                    let! logical =
                        LogicalPath.create rest
                        |> Result.mapError (fun _ ->
                            Error.InvalidSource "A staged mod file path is invalid.")

                    let! stamp = observe root entry.Logical identity
                    files.Add(transferFile logical stamp, stamp)
                | _ -> ()

            return List.ofSeq files
        }

    let private nonEmptyArray name value =
        match tryProperty name value with
        | None -> Ok false
        | Some item -> arrayItems name item |> Result.map (not << List.isEmpty)

    let private validateMod sourceId value =
        result {
            let! id = text "id" value

            if id <> sourceId then
                return! invalid "A Vortex mod ID does not match its backup key."

            let! state = text "state" value

            if state <> "installed" then
                return! unsupported ("The mod " + sourceId + " is not fully installed.")

            let! kind = tryText "type" value

            if kind |> Option.defaultValue "" |> (<>) "" then
                return!
                    unsupported ("The mod " + sourceId + " uses an unsupported Vortex mod type.")

            let! iniTweaks = nonEmptyArray "enabledINITweaks" value

            if iniTweaks then
                return!
                    unsupported (
                        "The mod " + sourceId + " uses profile settings that cannot be moved."
                    )

            let! overrides = nonEmptyArray "fileOverrides" value

            if overrides then
                return!
                    unsupported (
                        "The mod " + sourceId + " uses file overrides that cannot be moved."
                    )
        }

    let private modAttributes sourceId value =
        match tryProperty "attributes" value with
        | None ->
            use empty = JsonDocument.Parse("{}")
            Ok(empty.RootElement.Clone())
        | Some item when item.ValueKind = JsonValueKind.Object -> Ok item
        | Some _ -> invalid ("The mod " + sourceId + " has invalid attributes.")

    let private modMetadata sourceId attributes =
        result {
            let! named = attributeText [ "name"; "modName" ] attributes
            let name = named |> Option.defaultValue sourceId
            let! notes = attributeText [ "description"; "shortDescription" ] attributes
            let! comment = attributeText [ "author" ] attributes
            let! version = attributeText [ "version"; "modVersion" ] attributes
            let! source = attributeText [ "source"; "fileName" ] attributes

            let metadata =
                { Name = name
                  Notes = notes |> Option.defaultValue ""
                  Comment = comment |> Option.defaultValue ""
                  Version = version |> Option.defaultValue ""
                  Source = source |> Option.map safeSource |> Option.defaultValue ""
                  Categories = [] }

            do!
                InventoryPolicy.metadata metadata
                |> Result.mapError (fun _ ->
                    Error.InvalidSource("The metadata is invalid for mod " + name + "."))
                |> Result.map ignore

            return metadata
        }

    let private parseMod
        (states: IDictionary<string, JsonElement>)
        stagingRoot
        stagingEntries
        (entry: JsonProperty)
        =
        result {
            let sourceId = entry.Name
            let value = entry.Value

            let! enabled =
                match states.TryGetValue sourceId with
                | true, state -> boolean "enabled" state
                | _ -> Ok false

            do! validateMod sourceId value
            let! installationPath = text "installationPath" value
            let! attributes = modAttributes sourceId value
            let! metadata = modMetadata sourceId attributes
            let! fileEntries = modFiles stagingRoot stagingEntries installationPath
            let files, observed = List.unzip fileEntries
            let! archiveId = tryText "archiveId" value
            let! categoryIds = categoryReferences attributes

            return
                { SourceId = sourceId
                  Id = Guid.NewGuid()
                  VersionId = Guid.NewGuid()
                  ArchiveId = archiveId
                  Metadata = metadata
                  CategorySourceIds = categoryIds
                  Rules = tryProperty "rules" value |> Option.map _.Clone()
                  Files = files },
                enabled,
                observed
        }

    let parseMods persistent profile stagingRoot stagingEntries =
        result {
            let! gameId = text "gameId" profile
            let! stateObject = property "modState" profile
            let! stateEntries = objectEntries "profile mods" stateObject
            let! allGames = property "mods" persistent
            let! gameMods = property gameId allGames
            let! modEntries = objectEntries "mods" gameMods
            let modsById = modEntries |> Seq.map (fun item -> item.Name, item.Value) |> dict
            let states = stateEntries |> Seq.map (fun item -> item.Name, item.Value) |> dict

            for state in stateEntries do
                if not (modsById.ContainsKey state.Name) then
                    return!
                        invalid (
                            "The selected profile refers to a missing mod: " + state.Name + "."
                        )

                let! _ = boolean "enabled" state.Value
                ()

            let stamps = ResizeArray<Stamp>()

            let! mods =
                modEntries
                |> traverse (fun entry ->
                    result {
                        let! parsed, enabled, observed =
                            parseMod states stagingRoot stagingEntries entry

                        stamps.AddRange observed
                        return parsed, enabled
                    })

            return mods, List.ofSeq stamps, gameId
        }
