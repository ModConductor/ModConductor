namespace ModConductor.Persistence

open ModConductor.ModLibrary

module internal DeletionAdmission =
    let ownedFnisOutput connection transaction workspace modId =
        DeletionRows.ids
            connection
            transaction
            "SELECT id FROM profiles WHERE workspace_id=$workspace"
            [ "$workspace", box (string workspace) ]
        |> List.exists (fun profile -> FnisRunRows.outputId profile = modId)

    let retainsView connection transaction workspace modId =
        LibraryRows.find connection transaction modId
        |> Option.exists (fun row ->
            row.Entry.Kind = ModKind.GeneratedOutput
            && ownedFnisOutput connection transaction workspace modId)

    let private fnisRunning connection transaction modId =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM fnis_runs WHERE output_mod_id=$mod AND busy=1"
            [ "$mod", box (string modId) ] > 0L

    let row connection transaction workspace modId expected =
        match LibraryRows.find connection transaction modId with
        | None -> Error "The mod is no longer installed."
        | Some value when value.Entry.WorkspaceId <> workspace || value.Entry.Revision <> expected ->
            Error "The mod changed. Delete it again."
        | Some value when
            value.Entry.Kind <> ModKind.Regular
            && not (
                value.Entry.Kind = ModKind.GeneratedOutput
                && ownedFnisOutput connection transaction workspace modId
            )
            ->
            Error "Choose an installed mod or this profile's FNIS output."
        | Some _ when fnisRunning connection transaction modId ->
            Error "Finish the FNIS run before deleting its output."
        | Some value -> Ok value
