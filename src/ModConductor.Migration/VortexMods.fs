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
        names |> List.tryPick (fun name -> tryText name value)

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
        | None -> []
        | Some item when item.ValueKind = JsonValueKind.Null -> []
        | Some item when item.ValueKind = JsonValueKind.Number ->
            let mutable value = 0

            if item.TryGetInt32(&value) && value > 0 then
                [ value ]
            else
                invalid "A mod has an invalid category."
        | Some item when item.ValueKind = JsonValueKind.String ->
            let value = item.GetString()

            if String.IsNullOrWhiteSpace value then
                []
            else
                [ categoryId value ]
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
        if
            installationPath.IndexOfAny(
                [| Path.DirectorySeparatorChar; Path.AltDirectorySeparatorChar; '\\'; '/' |]
            )
            >= 0
        then
            unsupported "A Vortex mod uses a nested staging path."

        exactDirectory entries installationPath
        |> Option.defaultWith (fun () ->
            invalid ("The staging folder is missing the mod " + installationPath + "."))
        |> ignore

        entries
        |> List.choose (fun entry ->
            match components entry with
            | first :: rest when
                first = installationPath
                && entry.TargetKind = EntryKind.RegularFile
                && not rest.IsEmpty
                ->
                let identity =
                    match entry.Facts.File with
                    | Known value -> value
                    | Unknown detail -> refuse (Error.UnsafeSource detail)

                let logical =
                    LogicalPath.create rest
                    |> Result.defaultWith (fun _ -> invalid "A staged mod file path is invalid.")

                let stamp = observe root entry.Logical identity
                Some(transferFile logical stamp, stamp)
            | _ -> None)

    let private nonEmptyArray name value =
        match tryProperty name value with
        | None -> false
        | Some item -> not (arrayItems name item).IsEmpty

    let private validateMod sourceId value =
        if text "id" value <> sourceId then
            invalid "A Vortex mod ID does not match its backup key."

        if text "state" value <> "installed" then
            unsupported ("The mod " + sourceId + " is not fully installed.")

        let kind = tryText "type" value |> Option.defaultValue ""

        if kind <> "" then
            unsupported ("The mod " + sourceId + " uses an unsupported Vortex mod type.")

        if nonEmptyArray "enabledINITweaks" value then
            unsupported ("The mod " + sourceId + " uses profile settings that cannot be moved.")

        if nonEmptyArray "fileOverrides" value then
            unsupported ("The mod " + sourceId + " uses file overrides that cannot be moved.")

    let private modAttributes sourceId value =
        match tryProperty "attributes" value with
        | None ->
            use empty = JsonDocument.Parse("{}")
            empty.RootElement.Clone()
        | Some item when item.ValueKind = JsonValueKind.Object -> item
        | Some _ -> invalid ("The mod " + sourceId + " has invalid attributes.")

    let private modMetadata sourceId attributes =
        let name =
            attributeText [ "name"; "modName" ] attributes |> Option.defaultValue sourceId

        let metadata =
            { Name = name
              Notes =
                attributeText [ "description"; "shortDescription" ] attributes
                |> Option.defaultValue ""
              Comment = attributeText [ "author" ] attributes |> Option.defaultValue ""
              Version =
                attributeText [ "version"; "modVersion" ] attributes |> Option.defaultValue ""
              Source =
                attributeText [ "source"; "fileName" ] attributes
                |> Option.map safeSource
                |> Option.defaultValue ""
              Categories = [] }

        InventoryPolicy.metadata metadata
        |> Result.defaultWith (fun _ -> invalid ("The metadata is invalid for mod " + name + "."))
        |> ignore

        metadata

    let private parseMod
        (states: IDictionary<string, JsonElement>)
        stagingRoot
        stagingEntries
        (entry: JsonProperty)
        =
        let sourceId = entry.Name
        let value = entry.Value

        let enabled =
            match states.TryGetValue sourceId with
            | true, state -> boolean "enabled" state
            | _ -> false

        validateMod sourceId value
        let installationPath = text "installationPath" value
        let attributes = modAttributes sourceId value
        let metadata = modMetadata sourceId attributes

        let files, observed =
            modFiles stagingRoot stagingEntries installationPath |> List.unzip

        { SourceId = sourceId
          Id = Guid.NewGuid()
          VersionId = Guid.NewGuid()
          ArchiveId = tryText "archiveId" value
          Metadata = metadata
          CategorySourceIds = categoryReferences attributes
          Rules = tryProperty "rules" value |> Option.map _.Clone()
          Files = files },
        enabled,
        observed

    let parseMods persistent profile stagingRoot stagingEntries =
        let gameId = text "gameId" profile
        let stateEntries = property "modState" profile |> objectEntries "profile mods"
        let allGames = property "mods" persistent
        let gameMods = property gameId allGames

        let modEntries = objectEntries "mods" gameMods

        let modsById = modEntries |> Seq.map (fun item -> item.Name, item.Value) |> dict

        let states = stateEntries |> Seq.map (fun item -> item.Name, item.Value) |> dict

        for state in stateEntries do
            if not (modsById.ContainsKey state.Name) then
                invalid ("The selected profile refers to a missing mod: " + state.Name + ".")

            boolean "enabled" state.Value |> ignore

        let stamps = ResizeArray<Stamp>()

        let mods =
            modEntries
            |> List.map (fun entry ->
                let parsed, enabled, observed = parseMod states stagingRoot stagingEntries entry
                stamps.AddRange observed
                parsed, enabled)

        mods, List.ofSeq stamps, gameId
