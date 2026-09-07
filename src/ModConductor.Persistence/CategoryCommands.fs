namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary
open ModConductor.ModOrganization

module internal CategoryCommands =
    let edit connection transaction workspace expected edit =
        let find = CategoryRows.find connection transaction
        let revision = CategoryRows.revision connection transaction workspace

        let id, parent, label, deleting, creating =
            match edit with
            | CategoryEdit.Create(id, parent, label) -> id, parent, label, false, true
            | CategoryEdit.Update(id, parent, label) -> id, parent, label, false, false
            | CategoryEdit.Delete id -> id, None, "", true, false

        let current = find id

        let count sql parameters =
            Sqlite.number connection transaction sql parameters

        let parameters = [ "$id", box (string id); "$workspace", box (string workspace) ]

        let validate () =
            if expected <> revision then
                Error LibraryError.StaleRevision
            elif id = Guid.Empty then
                Error LibraryError.InvalidMetadata
            elif
                creating
                && (current.IsSome
                    || count
                        "SELECT count(*) FROM mod_categories r JOIN mods m ON m.id=r.mod_id WHERE r.category_id=$id AND m.workspace_id<>$workspace"
                        parameters > 0L)
            then
                Error LibraryError.IdentityConflict
            elif
                not creating
                && (current
                    |> Option.forall (fun value -> value.WorkspaceId <> workspace || value.Missing))
            then
                Error LibraryError.NotFound
            elif deleting then
                if
                    count
                        "SELECT count(*) FROM categories WHERE parent_id=$id AND missing=0"
                        [ "$id", box (string id) ] > 0L
                then
                    Error LibraryError.UnsupportedAction
                else
                    Ok()
            elif
                not (CategoryPolicy.label label)
                && (creating || current |> Option.forall (fun value -> value.Label <> label))
            then
                Error LibraryError.InvalidMetadata
            else
                match CategoryPolicy.parent workspace id parent find with
                | Error error -> Error error
                | Ok() ->
                    let parentDepth = CategoryRows.path connection transaction parent |> List.length

                    let subtreeDepth =
                        count
                            "WITH RECURSIVE tree(id,depth) AS (SELECT $id,1 UNION ALL SELECT c.id,t.depth+1 FROM categories c JOIN tree t ON c.parent_id=t.id WHERE c.missing=0) SELECT max(depth) FROM tree"
                            [ "$id", box (string id) ]
                        |> int

                    if parentDepth + subtreeDepth > 16 then
                        Error LibraryError.LimitExceeded
                    elif
                        count
                            "SELECT count(*) FROM categories WHERE workspace_id=$workspace AND parent_id IS $parent AND label=$label AND id<>$id AND missing=0"
                            (parameters
                             @ [ "$parent",
                                 parent
                                 |> Option.map (string >> box)
                                 |> Option.defaultValue (box DBNull.Value)
                                 "$label", box label ]) > 0L
                    then
                        Error LibraryError.IdentityConflict
                    else
                        Ok()

        match validate () with
        | Error error -> Error error
        | Ok() ->
            if deleting then
                Sqlite.execute
                    connection
                    transaction
                    "UPDATE categories SET missing=1 WHERE id=$id"
                    [ "$id", box (string id) ]
            else
                Sqlite.execute
                    connection
                    transaction
                    (if creating then
                         "INSERT INTO categories(id,workspace_id,parent_id,label) VALUES($id,$workspace,$parent,$label)"
                     else
                         "UPDATE categories SET parent_id=$parent,label=$label WHERE id=$id")
                    (parameters
                     @ [ "$parent",
                         parent
                         |> Option.map (string >> box)
                         |> Option.defaultValue (box DBNull.Value)
                         "$label", box label ])

                Sqlite.execute
                    connection
                    transaction
                    "UPDATE mod_categories SET label=$label WHERE category_id=$id"
                    [ "$id", box (string id); "$label", box label ]
            // Existing drafts must not overwrite a definition rename, deletion or resolved reference.
            Sqlite.execute
                connection
                transaction
                "UPDATE mods SET revision=revision+1 WHERE id IN (SELECT mod_id FROM mod_categories WHERE category_id=$id)"
                [ "$id", box (string id) ]

            CategoryRows.advance connection transaction workspace
            Ok(CategoryRows.revision connection transaction workspace)
