namespace ModConductor.Fomod

open System.Collections.Generic
open ModConductor.ArchiveInspection
open ModConductor.ArchiveInstallation
open ModConductor.Platform

module Planning =
    let private key parts =
        parts |> List.map (fun (part: string) -> part.Normalize().ToUpperInvariant())

    let private conditionalFiles (definition: Definition) (facts: Facts) flags =
        definition.Conditional
        |> List.fold
            (fun outcome (condition, mappings) ->
                outcome
                |> Result.bind (fun chosen ->
                    match Conditions.evaluate facts flags condition with
                    | Fact.Known true ->
                        Ok(
                            chosen
                            @ (mappings |> List.map (fun file -> file, "Conditional files"))
                        )
                    | Fact.Known false -> Ok chosen
                    | Fact.Unknown why -> Error why))
            (Ok [])

    let private selectedFiles (definition: Definition) (wizard: Wizard) =
        [ for file in definition.Required do
              yield file, "Core files"
          for step in definition.Steps do
              let page = wizard.Past |> List.tryFind (fun page -> page.Step.Index = step.Index)

              for group in step.Groups do
                  for option in group.Options do
                      let state =
                          page
                          |> Option.bind (fun p ->
                              p.Groups
                              |> List.collect _.Options
                              |> List.tryFind (fun o -> o.Option.Id = option.Id))

                      let selected = page |> Option.exists (fun p -> p.Selected.Contains option.Id)

                      for file in option.Files do
                          let usable =
                              state
                              |> Option.exists (fun value ->
                                  match value.Type with
                                  | Fact.Known OptionType.NotUsable
                                  | Fact.Unknown _ -> false
                                  | _ -> true)

                          if file.Always || selected || (file.IfUsable && usable) then
                              yield file, option.Name ]

    let private indexes (definition: Definition) =
        let entries = definition.Manifest.Entries |> List.filter (fun e -> not e.Directory)
        let files = Dictionary<string, ModConductor.ArchiveInspection.ArchiveEntry>()

        let folders =
            Dictionary<string, ResizeArray<ModConductor.ArchiveInspection.ArchiveEntry>>()

        for entry in entries do
            let parts = LogicalPath.components entry.Path |> key
            files[String.concat "/" parts] <- entry

            for count in 0 .. parts.Length - 1 do
                let prefix = parts |> List.take count |> String.concat "/"

                match folders.TryGetValue prefix with
                | true, values -> values.Add entry
                | _ -> folders[prefix] <- ResizeArray([ entry ])

        files, folders

    let private matching
        (definition: Definition)
        (files: Dictionary<string, ArchiveEntry>)
        (folders: Dictionary<string, ResizeArray<ArchiveEntry>>)
        (mapping: FileMapping)
        =
        let source = definition.Root @ mapping.Source
        let sourceKey = key source
        let name = String.concat "/" sourceKey

        let matches =
            if mapping.Folder then
                match folders.TryGetValue name with
                | true, values -> List.ofSeq values
                | _ -> []
            else
                match files.TryGetValue name with
                | true, value -> [ value ]
                | _ -> []

        let emptyFolder =
            mapping.Folder
            && (definition.Manifest.Entries
                |> List.exists (fun e ->
                    e.Directory && (LogicalPath.components e.Path |> key) = sourceKey))

        if matches.IsEmpty && not emptyFolder then
            Error(
                "An installer source is missing: "
                + String.concat "/" source
                + ". Download a fresh copy or use the manual layout."
            )
        else
            Ok(source, matches)

    let private addEntry
        (winners: Dictionary<string, ReviewedFile>)
        count
        (source: string list)
        (mapping: FileMapping)
        label
        (entry: ArchiveEntry)
        =
        if count >= 20000 then
            Error "The installer expands to too many file mappings."
        else
            let suffix =
                if mapping.Folder then
                    LogicalPath.components entry.Path |> List.skip source.Length
                elif mapping.AppendName then
                    [ LogicalPath.components entry.Path |> List.last ]
                else
                    []

            LogicalPath.create (mapping.Destination @ suffix)
            |> Result.mapError (fun _ ->
                "An installer destination is unsafe. Use the manual layout.")
            |> Result.map (fun destination ->
                let id = Destinations.key destination

                let replaced =
                    match winners.TryGetValue id with
                    | true, previous when previous.Source <> entry.Path ->
                        previous.Replaces @ [ previous.Source ]
                    | true, previous -> previous.Replaces
                    | _ -> []

                winners[id] <-
                    { File =
                        { Index = entry.Index
                          Destination = destination }
                      Source = entry.Path
                      Choice = label
                      Replaces = replaced }

                count + 1)

    let private mapped (definition: Definition) (chosen: (FileMapping * string) list) =
        let files, folders = indexes definition
        let winners = Dictionary<string, ReviewedFile>()

        chosen
        |> List.sortBy (fun (mapping, _) -> mapping.Priority, mapping.Order)
        |> List.fold
            (fun outcome (mapping, label) ->
                outcome
                |> Result.bind (fun count ->
                    matching definition files folders mapping
                    |> Result.bind (fun (source, matches) ->
                        matches
                        |> List.fold
                            (fun outcome entry ->
                                outcome
                                |> Result.bind (fun count ->
                                    addEntry winners count source mapping label entry))
                            (Ok count))))
            (Ok 0)
        |> Result.bind (fun _ ->
            let values =
                winners.Values
                |> Seq.sortBy (fun file -> Destinations.key file.File.Destination)
                |> Seq.toList

            if values.IsEmpty then
                Error "No files are selected. Change your choices or use the manual layout."
            else
                Destinations.validate (values |> List.map _.File.Destination)
                |> Result.map (fun () ->
                    { Files = values
                      Name = definition.Name
                      Version = definition.Version }))

    let build (definition: Definition) (facts: Facts) (wizard: Wizard) =
        if wizard.Current.IsSome || wizard.Problem.IsSome then
            Error "Finish the installer choices before reviewing the files."
        else
            let finalFlags =
                wizard.Past
                |> List.tryLast
                |> Option.map Choices.flags
                |> Option.defaultValue Map.empty

            conditionalFiles definition facts finalFlags
            |> Result.bind (fun conditional ->
                mapped definition (selectedFiles definition wizard @ conditional))
