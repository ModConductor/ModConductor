namespace ModConductor.ModSelection

open System
open ModConductor.ModLibrary

module SelectionPolicy =
    let ordered =
        function
        | ModKind.Regular
        | ModKind.Separator -> true
        | ModKind.Backup
        | ModKind.Unmanaged
        | ModKind.GeneratedOutput -> false

    let state kind (position: OrderedMod option) =
        match kind, position with
        | ModKind.Regular, Some row -> SelectionState.Managed(row.Priority, row.Enabled.Value)
        | ModKind.Separator, Some row -> SelectionState.Separator row.Priority
        | ModKind.Backup, _ -> SelectionState.Locked SelectionRestriction.Backup
        | ModKind.Unmanaged, _ -> SelectionState.Locked SelectionRestriction.Unmanaged
        | ModKind.GeneratedOutput, Some row -> SelectionState.Managed(row.Priority, row.Enabled.Value)
        | ModKind.GeneratedOutput, None -> SelectionState.Locked SelectionRestriction.Automatic
        | ModKind.Regular, None
        | ModKind.Separator, None -> invalidOp "The profile is missing an ordered mod."

    let change ids edit (current: OrderedMod list) =
        let selected = Set.ofList ids
        let targets = current |> List.filter (fun row -> selected.Contains row.Id)

        if ids.IsEmpty || ids.Length > 512 then
            Error LibraryError.LimitExceeded
        elif selected.Count <> ids.Length || selected.Contains Guid.Empty then
            Error LibraryError.IdentityConflict
        elif targets.Length <> ids.Length then
            Error LibraryError.UnsupportedAction
        else
            match edit with
            | SelectionEdit.Enable enabled ->
                if targets |> List.exists (fun row -> row.Enabled.IsNone) then
                    Error LibraryError.UnsupportedAction
                else
                    targets
                    |> List.choose (fun row ->
                        if row.Enabled = Some enabled then
                            None
                        else
                            Some { row with Enabled = Some enabled })
                    |> Ok
            | SelectionEdit.MoveUp
            | SelectionEdit.MoveDown ->
                let rows = List.toArray current

                let swap left right =
                    let row = rows[left]
                    rows[left] <- rows[right]
                    rows[right] <- row

                match edit with
                | SelectionEdit.MoveUp ->
                    for index in 1 .. rows.Length - 1 do
                        if
                            selected.Contains rows[index].Id
                            && not (selected.Contains rows[index - 1].Id)
                        then
                            swap index (index - 1)
                | SelectionEdit.MoveDown ->
                    for index in rows.Length - 2 .. -1 .. 0 do
                        if
                            selected.Contains rows[index].Id
                            && not (selected.Contains rows[index + 1].Id)
                        then
                            swap index (index + 1)
                | SelectionEdit.Enable _ -> invalidOp "Expected an order edit."

                rows
                |> Array.mapi (fun priority row ->
                    if row.Priority = priority then
                        None
                    else
                        Some { row with Priority = priority })
                |> Array.choose id
                |> List.ofArray
                |> Ok
