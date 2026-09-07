namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary
open ModConductor.ModOrganization

module internal CategoryRows =
    let revision connection transaction workspace =
        Sqlite.number
            connection
            transaction
            "SELECT catalogue_revision FROM workspaces WHERE id=$workspace"
            [ "$workspace", box (string workspace) ]

    let advance connection transaction workspace =
        Sqlite.execute
            connection
            transaction
            "UPDATE workspaces SET catalogue_revision=catalogue_revision+1 WHERE id=$workspace"
            [ "$workspace", box (string workspace) ]

    let find connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,parent_id,label,missing,(SELECT count(*) FROM mod_categories WHERE category_id=c.id),EXISTS(SELECT 1 FROM categories child WHERE child.parent_id=c.id AND child.missing=0) FROM categories c WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = command.ExecuteReader()

        if reader.Read() then
            Some
                { Id = id
                  WorkspaceId = Guid.Parse(reader.GetString 0)
                  ParentId =
                    if reader.IsDBNull 1 then
                        None
                    else
                        Some(Guid.Parse(reader.GetString 1))
                  Label = reader.GetString 2
                  Missing = reader.GetBoolean 3
                  AssignedCount = reader.GetInt32 4
                  HasChildren = reader.GetBoolean 5 }
        else
            None

    let references connection transaction modId =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT r.category_id,COALESCE(c.label,r.label),COALESCE(c.missing,1) FROM mod_categories r LEFT JOIN categories c ON c.id=r.category_id WHERE r.mod_id=$id ORDER BY r.category_id"
                [ "$id", box (string modId) ]

        use reader = command.ExecuteReader()

        [ while reader.Read() do
              yield
                  { Id = Guid.Parse(reader.GetString 0)
                    Label = reader.GetString 1
                    Missing = reader.GetBoolean 2 } ]

    let saveReferences connection transaction modId (values: CategoryReference list) =
        Sqlite.execute
            connection
            transaction
            "DELETE FROM mod_categories WHERE mod_id=$id"
            [ "$id", box (string modId) ]

        for value in values do
            Sqlite.execute
                connection
                transaction
                "INSERT INTO mod_categories VALUES($mod,$category,$label)"
                [ "$mod", box (string modId)
                  "$category", box (string value.Id)
                  "$label", box value.Label ]

    let canonicalMetadata connection transaction workspace modId (metadata: ModMetadata) =
        CategoryPolicy.references
            workspace
            (references connection transaction modId)
            (find connection transaction)
            metadata.Categories
        |> Result.map (fun values ->
            { metadata with
                Categories = values |> List.sortBy _.Id })

    let path connection transaction parent =
        let rec ancestors result next =
            match next with
            | None -> result
            | Some id ->
                match find connection transaction id with
                | None -> result
                | Some category -> ancestors (category :: result) category.ParentId

        ancestors [] parent

    let page connection transaction workspace parent (after: Guid option) (expected: int64 option) =
        let revision = revision connection transaction workspace

        if expected |> Option.exists ((<>) revision) || (after.IsSome && expected.IsNone) then
            Error LibraryError.StaleRevision
        elif
            parent
            |> Option.exists (fun id ->
                find connection transaction id
                |> Option.forall (fun value -> value.WorkspaceId <> workspace || value.Missing))
        then
            Error LibraryError.NotFound
        else
            use command =
                Sqlite.command
                    connection
                    transaction
                    "SELECT id FROM categories WHERE workspace_id=$workspace AND parent_id IS $parent AND missing=0 AND id>$after ORDER BY id LIMIT 33"
                    [ "$workspace", box (string workspace)
                      "$parent",
                      parent |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)
                      "$after", box (after |> Option.map string |> Option.defaultValue "") ]

            use reader = command.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()
            let values = ids |> List.truncate 32 |> List.choose (find connection transaction)

            Ok
                { Revision = revision
                  Entries = values
                  Ancestors = path connection transaction parent
                  NextId =
                    if ids.Length > values.Length then
                        values |> List.tryLast |> Option.map _.Id
                    else
                        None }
