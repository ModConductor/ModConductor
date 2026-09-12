namespace ModConductor.Fomod

open System.Collections.Generic
open ModConductor.ArchiveInstallation
open ModConductor.Platform

module Planning =
    let private refuse message = raise (FomodException message)

    let build (definition: Definition) (facts: Facts) (wizard: Wizard) =
        if wizard.Current.IsSome || wizard.Problem.IsSome then
            refuse "Finish the installer choices before reviewing the files."

        let finalFlags =
            wizard.Past
            |> List.tryLast
            |> Option.map Choices.flags
            |> Option.defaultValue Map.empty

        let chosen =
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

                          let selected =
                              page |> Option.exists (fun p -> p.Selected.Contains option.Id)

                          for file in option.Files do
                              let usable =
                                  state
                                  |> Option.exists (fun value ->
                                      match value.Type with
                                      | Fact.Known OptionType.NotUsable
                                      | Fact.Unknown _ -> false
                                      | _ -> true)

                              if file.Always || selected || (file.IfUsable && usable) then
                                  yield file, option.Name
              for condition, mappings in definition.Conditional do
                  match Conditions.evaluate facts finalFlags condition with
                  | Fact.Known true ->
                      for file in mappings do
                          yield file, "Conditional files"
                  | Fact.Known false -> ()
                  | Fact.Unknown why -> refuse why ]

        let entries = definition.Manifest.Entries |> List.filter (fun e -> not e.Directory)

        let key parts =
            parts |> List.map (fun (part: string) -> part.Normalize().ToUpperInvariant())

        let fileIndex = Dictionary<string, ModConductor.ArchiveInspection.ArchiveEntry>()

        let folders =
            Dictionary<string, ResizeArray<ModConductor.ArchiveInspection.ArchiveEntry>>()

        for entry in entries do
            let parts = LogicalPath.components entry.Path |> key
            fileIndex[String.concat "/" parts] <- entry

            for count in 0 .. parts.Length - 1 do
                let prefix = parts |> List.take count |> String.concat "/"

                match folders.TryGetValue prefix with
                | true, values -> values.Add entry
                | _ -> folders[prefix] <- ResizeArray([ entry ])

        let winners = Dictionary<string, ReviewedFile>()
        let mutable count = 0

        for mapping, label in chosen |> List.sortBy (fun (m, _) -> m.Priority, m.Order) do
            let source = definition.Root @ mapping.Source
            let sourceKey = key source
            let name = String.concat "/" sourceKey

            let matching =
                if mapping.Folder then
                    match folders.TryGetValue name with
                    | true, values -> List.ofSeq values
                    | _ -> []
                else
                    match fileIndex.TryGetValue name with
                    | true, value -> [ value ]
                    | _ -> []

            if
                matching.IsEmpty
                && not (
                    mapping.Folder
                    && definition.Manifest.Entries
                       |> List.exists (fun e ->
                           e.Directory && (LogicalPath.components e.Path |> key) = sourceKey)
                )
            then
                refuse (
                    "An installer source is missing: "
                    + String.concat "/" source
                    + ". Download a fresh copy or use the manual layout."
                )

            for entry in matching do
                count <- count + 1

                if count > 20000 then
                    refuse "The installer expands to too many file mappings."

                let suffix =
                    if mapping.Folder then
                        LogicalPath.components entry.Path |> List.skip source.Length
                    elif mapping.AppendName then
                        [ LogicalPath.components entry.Path |> List.last ]
                    else
                        []

                let destination =
                    LogicalPath.create (mapping.Destination @ suffix)
                    |> Result.defaultWith (fun _ ->
                        refuse "An installer destination is unsafe. Use the manual layout.")

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

        let values =
            winners.Values
            |> Seq.sortBy (fun f -> Destinations.key f.File.Destination)
            |> Seq.toList

        if values.IsEmpty then
            refuse "No files are selected. Change your choices or use the manual layout."

        Destinations.validate (values |> List.map _.File.Destination)

        { Files = values
          Name = definition.Name
          Version = definition.Version }
