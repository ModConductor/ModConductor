namespace ModConductor.Fomod

module Choices =
    let flags (page: Page) =
        page.Groups
        |> List.collect _.Options
        |> List.filter (fun value -> page.Selected.Contains value.Option.Id)
        |> List.collect _.Option.Flags
        |> List.fold (fun flags (name, value) -> Map.add name value flags) page.FlagsBefore

    let private initial group =
        let ofType kind =
            group.Options
            |> List.filter (fun value -> value.Type = Fact.Known kind)
            |> List.map _.Option.Id

        let required = ofType OptionType.Required
        let recommended = ofType OptionType.Recommended

        match group.Group.Kind with
        | GroupType.All -> group.Options |> List.map _.Option.Id
        | GroupType.ExactlyOne
        | GroupType.AtMostOne ->
            if required.IsEmpty then
                recommended |> List.truncate 1
            else
                required
        | GroupType.Any
        | GroupType.AtLeastOne -> required @ recommended

    let private page facts prefix (step: InstallStep) =
        let groups =
            step.Groups
            |> List.map (fun group ->
                { Group = group
                  Options =
                    group.Options
                    |> List.map (fun option ->
                        { Option = option
                          Type = Conditions.optionType facts prefix option.Type }) })

        { Step = step
          Groups = groups
          Selected = groups |> List.collect initial |> Set.ofList
          FlagsBefore = prefix }

    let private following definition facts prefix after =
        let rec find steps =
            match steps with
            | [] -> Ok None
            | step :: tail ->
                match Conditions.evaluate facts prefix step.Visible with
                | Fact.Known true -> Ok(Some(page facts prefix step))
                | Fact.Known false -> find tail
                | Fact.Unknown why -> Error why

        definition.Steps |> List.skip (after + 1) |> find

    let beginChoices definition facts =
        let next =
            match Conditions.evaluate facts Map.empty definition.Dependency with
            | Fact.Known true -> following definition facts Map.empty -1
            | Fact.Known false ->
                Error
                    "The installer requirements are not met. Check the selected game and mods, or use the manual layout."
            | Fact.Unknown why -> Error why

        match next with
        | Ok current ->
            { Past = []
              Current = current
              Future = []
              Problem = None }
        | Error why ->
            { Past = []
              Current = None
              Future = []
              Problem = Some why }

    let validation (page: Page) =
        page.Groups
        |> List.tryPick (fun group ->
            let unknown =
                group.Options
                |> List.tryPick (fun value ->
                    match value.Type with
                    | Fact.Unknown why -> Some why
                    | _ -> None)

            match unknown with
            | Some _ -> unknown
            | None ->
                let selected =
                    group.Options
                    |> List.filter (fun value -> page.Selected.Contains value.Option.Id)

                if
                    selected
                    |> List.exists (fun value -> value.Type = Fact.Known OptionType.NotUsable)
                then
                    Some(
                        "An unavailable option is required by "
                        + group.Group.Name
                        + ". Use the manual layout."
                    )
                else
                    let count = selected.Length

                    let valid =
                        match group.Group.Kind with
                        | GroupType.Any -> true
                        | GroupType.All -> count = group.Options.Length
                        | GroupType.AtLeastOne -> count >= 1
                        | GroupType.AtMostOne -> count <= 1
                        | GroupType.ExactlyOne -> count = 1

                    if valid then
                        None
                    else
                        Some("Check the selection for " + group.Group.Name + "."))

    let private choice id (page: Page) =
        page.Groups
        |> List.tryPick (fun group ->
            group.Options
            |> List.tryFind (fun value -> value.Option.Id = id)
            |> Option.map (fun option -> group, option))

    let private choiceProblem selected (group: GroupState) (option: OptionState) =
        match option.Type with
        | Fact.Unknown why -> Some why
        | Fact.Known OptionType.NotUsable -> Some "This installer option is not usable."
        | Fact.Known OptionType.Required when not selected ->
            Some "This installer option is required."
        | _ when group.Group.Kind = GroupType.All -> Some "All options in this group are required."
        | _ -> None

    let private selectedOptions id selected (page: Page) (group: GroupState) =
        let singles =
            group.Group.Kind = GroupType.ExactlyOne
            || group.Group.Kind = GroupType.AtMostOne

        let previous =
            if selected && singles then
                page.Selected
                - (group.Options
                   |> List.filter (fun o -> o.Type <> Fact.Known OptionType.Required)
                   |> List.map _.Option.Id
                   |> Set.ofList)
            else
                page.Selected

        if selected then previous.Add id else previous.Remove id

    let choose id selected (wizard: Wizard) =
        match wizard.Current with
        | None -> Error "Open a choice step before changing an option."
        | Some page ->
            match choice id page with
            | None -> Error "This installer choice is no longer on the current step."
            | Some(group, option) ->
                match choiceProblem selected group option with
                | Some why -> Error why
                | None ->
                    Ok
                        { wizard with
                            Current =
                                Some
                                    { page with
                                        Selected = selectedOptions id selected page group }
                            Future = []
                            Problem = None }

    let next definition facts wizard =
        match wizard.Current with
        | None -> wizard
        | Some page ->
            match validation page with
            | Some why -> { wizard with Problem = Some why }
            | None ->
                match wizard.Future with
                | head :: tail ->
                    { Past = wizard.Past @ [ page ]
                      Current = Some head
                      Future = tail
                      Problem = None }
                | [] ->
                    match following definition facts (flags page) page.Step.Index with
                    | Ok current ->
                        { Past = wizard.Past @ [ page ]
                          Current = current
                          Future = []
                          Problem = None }
                    | Error why -> { wizard with Problem = Some why }

    let back wizard =
        match List.rev wizard.Past with
        | [] -> wizard
        | last :: rest ->
            { Past = List.rev rest
              Current = Some last
              Future = (wizard.Current |> Option.toList) @ wizard.Future
              Problem = None }
