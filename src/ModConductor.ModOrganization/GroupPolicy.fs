namespace ModConductor.ModOrganization

open System
open ModConductor.ModLibrary

module GroupPolicy =
    let private move selected up (items: OrganizationItem list) =
        let rows = List.toArray items

        let swap left right =
            let row = rows[left]
            rows[left] <- rows[right]
            rows[right] <- row

        let indices =
            if up then
                [ 1 .. rows.Length - 1 ]
            else
                [ rows.Length - 2 .. -1 .. 0 ]

        for index in indices do
            let neighbor = if up then index - 1 else index + 1

            if
                Set.contains rows[index].Id selected
                && not (Set.contains rows[neighbor].Id selected)
            then
                swap index neighbor

        List.ofArray rows

    let private movesWithSelection
        (selected: Set<Guid>)
        (headers: Set<Guid>)
        (row: OrganizationItem)
        =
        selected.Contains row.Id || row.GroupId |> Option.exists headers.Contains

    let private dropDestination (headers: Set<Guid>) target (current: OrganizationItem list) =
        match current |> List.tryFind (fun row -> row.Id = target) with
        | Some row when not headers.IsEmpty && row.GroupId.IsSome ->
            current |> List.tryFind (fun parent -> Some parent.Id = row.GroupId)
        | destination -> destination

    let private joinCollection
        (destination: OrganizationItem)
        (moved: OrganizationItem list)
        (retained: OrganizationItem list)
        =
        let members =
            moved
            |> List.map (fun row ->
                { row with
                    GroupId = Some destination.Id })

        let before, after =
            retained
            |> List.partition (fun row ->
                row.Position <= destination.Position || row.GroupId = Some destination.Id)

        before @ members @ after

    let private insertionBoundary
        before
        (destination: OrganizationItem)
        (retained: OrganizationItem list)
        =
        if before then
            destination.Position - 1
        else
            retained
            |> List.filter (fun row -> row.Id = destination.Id || row.GroupId = Some destination.Id)
            |> List.map _.Position
            |> List.max

    let private reorderSiblings
        (targets: OrganizationItem list)
        (headers: Set<Guid>)
        (destination: OrganizationItem)
        before
        moved
        retained
        =
        let roots =
            targets
            |> List.filter (fun row -> not (row.GroupId |> Option.exists headers.Contains))

        if roots |> List.exists (fun row -> row.GroupId <> destination.GroupId) then
            Error LibraryError.UnsupportedAction
        else
            let boundary = insertionBoundary before destination retained

            let preceding, following =
                retained |> List.partition (fun row -> row.Position <= boundary)

            Ok(preceding @ moved @ following)

    let private place selected (targets: OrganizationItem list) target placement current =
        let headers = targets |> List.filter _.IsSeparator |> List.map _.Id |> Set.ofList

        match dropDestination headers target current with
        | None -> Error LibraryError.NotFound
        | Some destination when movesWithSelection selected headers destination ->
            Error LibraryError.UnsupportedAction
        | Some destination ->
            let moved, retained =
                current |> List.partition (movesWithSelection selected headers)

            match placement with
            | OrganizationPlacement.Inside when not destination.IsSeparator || not headers.IsEmpty ->
                Error LibraryError.UnsupportedAction
            | OrganizationPlacement.Inside -> Ok(joinCollection destination moved retained)
            | OrganizationPlacement.Before ->
                reorderSiblings targets headers destination true moved retained
            | OrganizationPlacement.After ->
                reorderSiblings targets headers destination false moved retained

    let change ids edit (current: OrganizationItem list) =
        let selected = Set.ofList ids
        let targets = current |> List.filter (fun row -> selected.Contains row.Id)

        if ids.IsEmpty || ids.Length > 512 then
            Error LibraryError.LimitExceeded
        elif selected.Count <> ids.Length || selected.Contains Guid.Empty then
            Error LibraryError.IdentityConflict
        elif targets.Length <> ids.Length then
            Error LibraryError.UnsupportedAction
        else
            let groups = current |> List.groupBy _.GroupId |> Map.ofList
            let roots = groups |> Map.tryFind None |> Option.defaultValue []

            let children id =
                groups |> Map.tryFind (Some id) |> Option.defaultValue []

            let result =
                match edit with
                | OrganizationEdit.Place(target, placement) ->
                    place selected targets target placement current
                | OrganizationEdit.Group group ->
                    if targets |> List.exists _.IsSeparator then
                        Error LibraryError.UnsupportedAction
                    elif
                        roots |> List.exists (fun row -> row.Id = group && row.IsSeparator) |> not
                    then
                        Error LibraryError.NotFound
                    else
                        let first = targets |> List.map _.Position |> List.min
                        let header = roots |> List.find (fun row -> row.Id = group)

                        let others =
                            roots
                            |> List.filter (fun row ->
                                row.Id <> group && not (selected.Contains row.Id))

                        let before, after =
                            others |> List.partition (fun row -> row.Position < first)

                        let grouped =
                            targets |> List.map (fun row -> { row with GroupId = Some group })

                        [ for root in before @ [ header ] @ after do
                              yield root

                              yield!
                                  (children root.Id
                                   |> List.filter (fun row -> not (selected.Contains row.Id)))

                              if root.Id = group then
                                  yield! grouped ]
                        |> Ok
                | OrganizationEdit.MoveUp
                | OrganizationEdit.MoveDown ->
                    let up = edit = OrganizationEdit.MoveUp

                    [ for root in move selected up roots do
                          yield root

                          yield!
                              (if selected.Contains root.Id then
                                   children root.Id
                               else
                                   move selected up (children root.Id)) ]
                    |> Ok

            result
            |> Result.map (List.mapi (fun position row -> { row with Position = position }))
