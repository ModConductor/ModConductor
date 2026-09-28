namespace ModConductor.Persistence

open System
open ModConductor.ModOrganization

module internal OrganizationQuerySql =
    let build profile workspace (query: ModQuery) =
        let parameters =
            ResizeArray<string * obj>(
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$fnisOutput", box (string (FnisRunRows.outputId profile))
                  "$text", box query.Text ]
            )

        let parameter value =
            let name = "$filter" + string parameters.Count
            parameters.Add(name, value)
            name

        let predicate =
            function
            | ModFilter.Category(reference, descendants) ->
                let id = parameter (box (string reference.Id))

                if descendants then
                    "EXISTS(SELECT 1 FROM mod_categories r WHERE r.mod_id=b.id AND r.category_id IN (WITH RECURSIVE descendants(id) AS (SELECT "
                    + id
                    + " UNION ALL SELECT c.id FROM categories c JOIN descendants d ON c.parent_id=d.id WHERE c.workspace_id=$workspace AND c.missing=0) SELECT id FROM descendants))"
                else
                    "EXISTS(SELECT 1 FROM mod_categories r WHERE r.mod_id=b.id AND r.category_id="
                    + id
                    + ")"
            | ModFilter.Kind kind -> "b.kind=" + parameter (box (LibraryEncoding.kind kind))
            | ModFilter.Status status ->
                "b.status=" + parameter (box (LibraryEncoding.status status))
            | ModFilter.Enabled None -> "b.enabled IS NULL"
            | ModFilter.Enabled(Some enabled) ->
                "b.enabled=" + parameter (box (if enabled then 1 else 0))
            | ModFilter.Uncategorized ->
                "NOT EXISTS(SELECT 1 FROM mod_categories r WHERE r.mod_id=b.id)"
            | ModFilter.MissingCategory ->
                "EXISTS(SELECT 1 FROM mod_categories r LEFT JOIN categories c ON c.id=r.category_id WHERE r.mod_id=b.id AND COALESCE(c.missing,1)=1)"

        let filters = query.Filters |> List.map predicate

        let typed =
            if filters.IsEmpty then
                "1"
            else
                filters
                |> String.concat (if query.Mode = FilterMode.All then " AND " else " OR ")

        let sql =
            """
WITH base AS (
 SELECT m.*,p.priority,p.enabled,
   (SELECT s.mod_id FROM profile_mods s JOIN mods sm ON sm.id=s.mod_id WHERE s.profile_id=$profile AND sm.kind=2 AND s.priority<p.priority ORDER BY s.priority DESC LIMIT 1) AS group_id
 FROM mods m LEFT JOIN profile_mods p ON p.mod_id=m.id AND p.profile_id=$profile
 WHERE m.workspace_id=$workspace AND (m.kind<>5 OR m.source_path IS NOT NULL OR EXISTS(SELECT 1 FROM fnis_outputs f WHERE f.profile_id=$profile AND f.mod_id=m.id) OR p.mod_id IS NOT NULL OR (m.id=$fnisOutput AND m.current_version IS NOT NULL))
), matches AS (
 SELECT b.* FROM base b WHERE
 (mc_contains(b.name,$text) OR mc_contains(b.version_text,$text) OR mc_contains(b.source_text,$text) OR mc_contains(b.notes,$text) OR mc_contains(b.comment,$text)
 OR EXISTS(SELECT 1 FROM mod_categories r LEFT JOIN categories c ON c.id=r.category_id WHERE r.mod_id=b.id AND mc_contains(COALESCE(c.label,r.label),$text)))
 AND (
            """
            + typed
            + ") ) "

        let order =
            let rowSort =
                if query.Sort = OrganizationSort.Name then
                    "name COLLATE MC_NAME,id"
                elif query.View = OrganizationView.Flat then
                    "priority IS NULL,priority,id"
                else
                    "COALESCE(priority,-1),id"

            match query.View with
            | OrganizationView.Flat -> rowSort
            | OrganizationView.Groups ->
                "CASE WHEN kind=2 THEN priority ELSE COALESCE((SELECT priority FROM base g WHERE g.id=matches.group_id),-1) END,CASE WHEN kind=2 THEN 0 ELSE 1 END,"
                + rowSort

        sql, List.ofSeq parameters, order
