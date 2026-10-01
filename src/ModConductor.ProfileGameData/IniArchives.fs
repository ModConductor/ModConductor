namespace ModConductor.ProfileGameData

open System
open ModConductor.ProfileGameData.IniDocument

module internal IniArchives =
    let private archiveKeys = [ "SResourceArchiveList"; "SResourceArchiveList2" ]

    let private sectionFor keys =
        if
            keys
            |> List.exists (fun (key: string) ->
                key.StartsWith("Archive ", StringComparison.OrdinalIgnoreCase))
        then
            "Archives"
        else
            "Archive"

    let private morrowindKeys bytes =
        let _, text = decode bytes
        let mutable inside = false

        [ for line in lines text do
              match section line with
              | Some name -> inside <- name.Equals("Archives", StringComparison.OrdinalIgnoreCase)
              | None when inside ->
                  let split = line.IndexOf '='

                  if split >= 0 then
                      let key = line.Substring(0, split).Trim()

                      if key.StartsWith("Archive ", StringComparison.OrdinalIgnoreCase) then
                          match Int32.TryParse(key.Substring 8) with
                          | true, index when index >= 0 -> yield "Archive " + string index
                          | _ -> ()
              | _ -> () ]
        |> List.distinct
        |> List.sortBy (fun key -> Int32.Parse(key.Substring 8))

    let tryArchiveEntriesFor archiveKeys bytes =
        let archiveKeys =
            if List.isEmpty archiveKeys then
                morrowindKeys bytes
            else
                archiveKeys

        let _, text = decode bytes

        tryLocateSettings (sectionFor archiveKeys) archiveKeys (lines text)
        |> Result.map (fun (_, found) ->
            [ for key in archiveKeys do
                  match found |> List.tryFind (fun (name, _, _) -> name = key) with
                  | None -> ()
                  | Some(_, _, value) ->
                      let mutable position = 0

                      for name in value.Split(',') do
                          let name = name.Trim()

                          if name <> "" then
                              yield
                                  ({ Name = name
                                     Key = key
                                     Position = position }
                                  : ModConductor.Bethesda.ExplicitArchive)

                              position <- position + 1 ])

    let archiveValuesFor archiveKeys names =
        let joined = String.concat ", " names

        if List.length archiveKeys <= 1 || joined.Length <= 255 then
            Ok(joined, None)
        else
            let search = min 256 (joined.Length - 1)
            let split = joined.LastIndexOf(',', search)

            if split < 0 then
                Error(
                    ProfileDataError.Invalid
                        "The game archive list cannot be split between its two keys."
                )
            else
                let first = joined.Substring(0, split)
                let second = joined.Substring(split + 1).TrimStart()

                if first.Length > 256 || second.Length > 255 then
                    Error(
                        ProfileDataError.Invalid "The game archive list does not fit its two keys."
                    )
                else
                    Ok(first, Some second)

    let validateNamesFor archiveKeys names =
        if
            List.isEmpty names
            || names
               |> List.exists (fun name ->
                   String.IsNullOrWhiteSpace name
                   || name <> name.Trim()
                   || name.IndexOfAny([| ','; '\r'; '\n'; '\000'; '/'; '\\' |]) >= 0)
        then
            Error(ProfileDataError.Invalid "Choose valid game archive filenames.")
        else if List.isEmpty archiveKeys then
            Ok()
        else
            archiveValuesFor archiveKeys names |> Result.map ignore

    let private applySettings (values: (string * string) list) (original: byte array option) =
        let archiveKeys = List.map fst values
        let bytes = original |> Option.defaultValue [||]
        let kind, text = decode bytes
        let content = lines text

        let newline =
            if text.Contains("\r\n") || not (text.Contains '\n') then
                "\r\n"
            else
                "\n"

        let header, found = locateSettings (sectionFor archiveKeys) archiveKeys content
        let mutable separator = IniSeparatorOverride.None
        let mutable addedSection = false

        let header =
            match header with
            | Some index ->
                if not (content[index].EndsWith '\n') then
                    let previous = content[index]
                    content[index] <- previous + newline
                    separator <- IniSeparatorOverride.SectionHeader previous

                index
            | None ->
                if content.Count > 0 && not (content[content.Count - 1].EndsWith '\n') then
                    let previous = content[content.Count - 1]
                    content[content.Count - 1] <- previous + newline
                    separator <- IniSeparatorOverride.FileTail previous

                content.Add("[" + sectionFor archiveKeys + "]" + newline)
                addedSection <- true
                content.Count - 1

        let patches = ResizeArray<ArchiveLineOverride>()

        let write key value insert =
            let _, current = locateSettings (sectionFor archiveKeys) archiveKeys content

            match current |> List.tryFind (fun (name, _, _) -> name = key) with
            | Some(_, index, _) ->
                let previous = content[index]
                content[index] <- key + "=" + value + ending previous

                patches.Add
                    { Key = key
                      Value = value
                      PreviousLine = Some previous }
            | None when insert ->
                let previousKeys = patches.Count
                content.Insert(header + 1 + previousKeys, key + "=" + value + newline)

                patches.Add
                    { Key = key
                      Value = value
                      PreviousLine = None }
            | None -> ()

        values |> List.iter (fun (key, value) -> write key value true)

        encode kind (String.Concat content),
        { Lines = List.ofSeq patches
          AddedSection = addedSection
          Separator = separator
          AbsentFile = original.IsNone }

    let applyArchivesFor archiveKeys names original =
        validateNamesFor archiveKeys names
        |> Result.bind (fun () -> archiveValuesFor archiveKeys names)
        |> Result.map (fun (first, second) ->
            [ yield List.head archiveKeys, first
              match List.tryItem 1 archiveKeys, second with
              | Some key, Some value -> yield key, value
              | _ -> () ]
            |> fun values -> applySettings values original)

    let looseFilesEnabled bytes =
        let _, text = decode bytes

        tryLocateSettings
            "Archive"
            [ "bInvalidateOlderFiles"; "sResourceDataDirsFinal" ]
            (lines text)
        |> Result.map (fun (_, values) ->
            values
            |> List.exists (fun (key, _, value) -> key = "bInvalidateOlderFiles" && value = "1")
            && values
               |> List.exists (fun (key, _, value) -> key = "sResourceDataDirsFinal" && value = ""))

    let applyFor (rules: ModConductor.GameContexts.GameRules) names original =
        match rules.Activation, rules.Invalidation with
        | ModConductor.GameContexts.PluginActivation.MorrowindIni, _ ->
            validateNamesFor [] names
            |> Result.map (fun () ->
                let existing = original |> Option.map morrowindKeys |> Option.defaultValue []
                let wanted = names |> List.mapi (fun index name -> "Archive " + string index, name)

                let obsolete =
                    existing
                    |> List.filter (fun key ->
                        wanted |> List.exists (fun (name, _) -> name = key) |> not)

                wanted @ (obsolete |> List.map (fun key -> key, ""))
                |> fun values -> applySettings values original)
        | _, None when rules.LooseFilesInvalidation ->
            validateNamesFor rules.ArchiveKeys names
            |> Result.bind (fun () -> archiveValuesFor rules.ArchiveKeys names)
            |> Result.map (fun (first, second) ->
                [ List.head rules.ArchiveKeys, first
                  match List.tryItem 1 rules.ArchiveKeys, second with
                  | Some key, Some value -> key, value
                  | _ -> ()
                  "bInvalidateOlderFiles", "1"
                  "sResourceDataDirsFinal", "" ]
                |> fun values -> applySettings values original)
        | _, None -> applyArchivesFor rules.ArchiveKeys names original
        | _, Some(name, _) ->
            validateNamesFor rules.ArchiveKeys names
            |> Result.map (fun () ->
                let enabled =
                    names
                    |> List.exists (fun value ->
                        value.Equals(name, StringComparison.OrdinalIgnoreCase))

                [ List.head rules.ArchiveKeys, String.concat ", " names
                  "bInvalidateOlderFiles", "1"
                  "SInvalidationFile", if enabled then "" else "ArchiveInvalidation.txt" ]
                |> fun values -> applySettings values original)

    let tryArchiveEntries bytes = tryArchiveEntriesFor archiveKeys bytes

    let applyArchives names original =
        applyArchivesFor archiveKeys names original

    let validateNames names = validateNamesFor archiveKeys names
