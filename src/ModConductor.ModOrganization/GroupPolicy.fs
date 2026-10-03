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
