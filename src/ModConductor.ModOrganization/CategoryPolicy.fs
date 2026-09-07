namespace ModConductor.ModOrganization

open System
open ModConductor.ModLibrary

module CategoryPolicy =
    let label (value: string) =
        not (String.IsNullOrWhiteSpace value)
        && value.Length <= 256
        && not (value.Contains '\000')

    let parent workspace id parentId (find: Guid -> Category option) =
        let rec walk visited depth next =
            match next with
            | None -> Ok()
            | Some parent when parent = id || Set.contains parent visited ->
                Error LibraryError.InvalidMetadata
            | Some _ when depth >= 16 -> Error LibraryError.LimitExceeded
            | Some parent ->
                match find parent with
                | Some value when value.WorkspaceId = workspace && not value.Missing ->
                    walk (Set.add parent visited) (depth + 1) value.ParentId
                | Some _
                | None -> Error LibraryError.NotFound

        walk Set.empty 1 parentId

    let references
        workspace
        (existing: CategoryReference list)
        (find: Guid -> Category option)
        (values: CategoryReference list)
        =
        let rec collect (result: CategoryReference list) (remaining: CategoryReference list) =
            match remaining with
            | [] -> Ok(List.rev result)
            | reference :: tail ->
                match find reference.Id with
                | Some category when category.WorkspaceId <> workspace ->
                    Error LibraryError.IdentityConflict
                | Some category ->
                    collect
                        ({ Id = category.Id
                           Label = category.Label
                           Missing = category.Missing }
                         :: result)
                        tail
                | None ->
                    let known = existing |> List.tryFind (fun value -> value.Id = reference.Id)
                    let value = known |> Option.defaultValue reference
                    collect ({ value with Missing = true } :: result) tail

        collect [] values
