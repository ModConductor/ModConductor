namespace ModConductor.Workspaces

open System

module ProfilePolicy =
    let name (value: string) =
        if String.IsNullOrWhiteSpace value || value.Length > 256 || value.Contains('\000') then
            Error WorkspaceError.InvalidName
        else
            Ok(value.Trim())

    let target =
        function
        | ProfileEdit.Create profile -> profile.Id
        | ProfileEdit.Clone(source, _) -> source
        | ProfileEdit.Rename(id, _)
        | ProfileEdit.Select id
        | ProfileEdit.Delete id -> id

    let validate (selected: Guid option) (current: Profile option) edit =
        let named (profile: Profile) =
            if profile.Id = Guid.Empty then
                Error WorkspaceError.IdentityConflict
            else
                name profile.Name |> Result.map (fun value -> { profile with Name = value })

        match edit, current with
        | ProfileEdit.Create profile, None -> named profile |> Result.map ProfileEdit.Create
        | ProfileEdit.Create _, Some _ -> Error WorkspaceError.IdentityConflict
        | ProfileEdit.Clone(_, profile), Some source when source.Id <> profile.Id ->
            named profile |> Result.map (fun copy -> ProfileEdit.Clone(source.Id, copy))
        | ProfileEdit.Clone _, Some _ -> Error WorkspaceError.IdentityConflict
        | ProfileEdit.Rename(id, value), Some _ ->
            name value |> Result.map (fun value -> ProfileEdit.Rename(id, value))
        | ProfileEdit.Select _, Some _ -> Ok edit
        | ProfileEdit.Delete id, Some _ when selected = Some id ->
            Error WorkspaceError.SelectedProfile
        | ProfileEdit.Delete _, Some _ -> Ok edit
        | _, None -> Error WorkspaceError.NotFound
