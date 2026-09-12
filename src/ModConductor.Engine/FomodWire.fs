namespace ModConductor.Engine

open ModConductor.Fomod
open ModConductor.Platform
open ModConductor.Protocol.V1

module internal FomodWire =
    let private kind value =
        match value with
        | Fact.Unknown _ -> FomodOptionKind.Unknown
        | Fact.Known OptionType.Required -> FomodOptionKind.Required
        | Fact.Known OptionType.Recommended -> FomodOptionKind.Recommended
        | Fact.Known OptionType.Optional -> FomodOptionKind.Optional
        | Fact.Known OptionType.NotUsable -> FomodOptionKind.NotUsable
        | Fact.Known OptionType.CouldBeUsable -> FomodOptionKind.CouldBeUsable

    let private group (page: Page) (value: GroupState) =
        let groupKind =
            match value.Group.Kind with
            | GroupType.Any -> FomodGroupKind.Any
            | GroupType.All -> FomodGroupKind.All
            | GroupType.AtLeastOne -> FomodGroupKind.AtLeastOne
            | GroupType.AtMostOne -> FomodGroupKind.AtMostOne
            | GroupType.ExactlyOne -> FomodGroupKind.ExactlyOne

        let result = FomodGroup(Name = value.Group.Name, Kind = groupKind)

        let lockedSingle =
            (value.Group.Kind = GroupType.ExactlyOne
             || value.Group.Kind = GroupType.AtMostOne)
            && (value.Options
                |> List.exists (fun option -> option.Type = Fact.Known OptionType.Required))

        for value in value.Options do
            let changeable =
                match value.Type with
                | Fact.Unknown _
                | Fact.Known OptionType.NotUsable
                | Fact.Known OptionType.Required -> false
                | _ -> result.Kind <> FomodGroupKind.All && not lockedSingle

            let option =
                FomodOption(
                    Id = uint32 value.Option.Id,
                    Name = value.Option.Name,
                    Description = value.Option.Description,
                    Kind = kind value.Type,
                    Selected = page.Selected.Contains value.Option.Id,
                    CanChange = changeable
                )

            option.Image.AddRange(value.Option.Image |> Option.defaultValue [])

            match value.Type with
            | Fact.Unknown why -> option.Problem <- why
            | _ -> ()

            result.Options.Add option

        result

    let choices (value: InstallerChoices) =
        let wizard = value.Wizard
        let page = wizard |> Option.bind _.Current

        let name =
            value.Definition
            |> Option.map _.Name
            |> Option.filter (System.String.IsNullOrWhiteSpace >> not)
            |> Option.defaultValue value.Draft.Name

        let result =
            FomodChoices(
                Reference =
                    InstallationDraftReference(
                        WorkspaceId = value.Draft.Artifact.WorkspaceId.ToString("N"),
                        Id = value.Draft.Id.ToString("N"),
                        Revision = uint64 value.Draft.Revision
                    ),
                ProfileId = value.ProfileId.ToString("N"),
                Name = name,
                HasStep = page.IsSome,
                CanBack = (wizard |> Option.exists (fun wizard -> not wizard.Past.IsEmpty)),
                ReviewReady = (value.Planned.IsSome && value.Draft.Plan.IsSome),
                VisibleSteps = uint32 value.VisibleSteps
            )

        if result.ReviewReady then
            result.ReviewedDraft <- InstallationWire.draft value.Draft

        match page with
        | None -> ()
        | Some page ->
            result.StepName <- page.Step.Name
            result.StepNumber <- uint32 (wizard.Value.Past.Length + 1)
            result.Groups.AddRange(page.Groups |> List.map (group page))

        match value.Planned with
        | None -> ()
        | Some planned ->
            let entries =
                value.Draft.Manifest.Entries |> List.map (fun e -> e.Index, e) |> Map.ofList

            result.Files.AddRange(planned.Files |> List.map (InstallationReviewWire.file entries))

        value.Problem |> Option.iter (fun why -> result.Problem <- why)
        result
