namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.ModOrganization

module internal OrganizationQuery =
    let read
        connection
        transaction
        workspace
        profile
        selectionRevision
        query
        (cursor: QueryCursor option)
        inspected
        =
        let catalogue = CategoryRows.revision connection transaction workspace
        let identity = OrganizationPolicy.identity profile query

        let stale =
            cursor
            |> Option.exists (fun value ->
                value.CatalogueRevision <> catalogue
                || value.SelectionRevision <> selectionRevision
                || value.QueryIdentity <> identity
                || value.Offset < 0)

        if stale then
            Error LibraryError.StaleRevision
        else
            let sql, parameters, order = OrganizationQuerySql.build profile workspace query

            let joined id =
                LibraryRows.find connection transaction id
                |> Option.filter (fun row -> row.Entry.WorkspaceId = workspace)
                |> Option.map (fun row ->
                    let selected = SelectionRows.find connection transaction profile id

                    let group =
                        if
                            query.View <> OrganizationView.Groups
                            || row.Entry.Kind = ModKind.Separator
                        then
                            None
                        else
                            use command =
                                Sqlite.command
                                    connection
                                    transaction
                                    (sql + "SELECT group_id FROM base WHERE id=$id")
                                    (parameters @ [ "$id", box (string id) ])

                            let value = command.ExecuteScalar()

                            if isNull value || value = box DBNull.Value then
                                None
                            else
                                Some(Guid.Parse(string value))

                    { Entry =
                        { Mod = row.Entry
                          Selection = SelectionPolicy.state row.Entry.Kind selected }
                      GroupId = group
                      GroupSize =
                        if
                            query.View = OrganizationView.Groups
                            && row.Entry.Kind = ModKind.Separator
                        then
                            let count source =
                                Sqlite.number
                                    connection
                                    transaction
                                    (sql
                                     + "SELECT count(*) FROM "
                                     + source
                                     + " WHERE kind<>2 AND group_id=$id")
                                    (parameters @ [ "$id", box (string id) ])
                                |> int

                            Some
                                { Matching = count "matches"
                                  Total = count "base" }
                        else
                            None })

            let count condition =
                Sqlite.number
                    connection
                    transaction
                    (sql + "SELECT count(*) FROM matches WHERE " + condition)
                    parameters
                |> int

            let matchingMods = count "kind<>2"
            let matchingSeparators = count "kind=2"
            let offset = cursor |> Option.map _.Offset |> Option.defaultValue 0

            use command =
                Sqlite.command
                    connection
                    transaction
                    (sql + "SELECT id FROM matches ORDER BY " + order + " LIMIT 33 OFFSET $offset")
                    (parameters @ [ "$offset", box offset ])

            use reader = command.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()
            let detail = inspected |> Option.bind joined

            let mutable budget =
                512 * 1024
                - (detail
                   |> Option.map (fun value -> InventoryPolicy.inventorySize value.Entry.Mod)
                   |> Option.defaultValue 0)

            let mutable context: Map<Guid, OrganizedMod> = Map.empty

            let rows =
                ids
                |> List.truncate 32
                |> List.choose joined
                |> List.takeWhile (fun value ->
                    let newContext =
                        value.GroupId
                        |> Option.filter (fun id -> not (Map.containsKey id context))
                        |> Option.bind joined

                    let size =
                        InventoryPolicy.inventorySize value.Entry.Mod
                        + (newContext
                           |> Option.map (fun value ->
                               InventoryPolicy.inventorySize value.Entry.Mod)
                           |> Option.defaultValue 0)

                    if size > budget then
                        false
                    else
                        budget <- budget - size

                        newContext
                        |> Option.iter (fun value ->
                            context <- Map.add value.Entry.Mod.Id value context)

                        true)

            if (not ids.IsEmpty && rows.IsEmpty) || budget < 0 then
                Error LibraryError.LimitExceeded
            else
                let rowIds = rows |> List.map (fun value -> value.Entry.Mod.Id) |> Set.ofList

                Ok
                    { CatalogueRevision = catalogue
                      SelectionRevision = selectionRevision
                      QueryIdentity = identity
                      Entries = rows
                      Context =
                        context
                        |> Map.toList
                        |> List.map snd
                        |> List.filter (fun value -> not (Set.contains value.Entry.Mod.Id rowIds))
                      Inspected = detail
                      Next =
                        if ids.Length > rows.Length then
                            Some
                                { CatalogueRevision = catalogue
                                  SelectionRevision = selectionRevision
                                  QueryIdentity = identity
                                  Offset = offset + rows.Length }
                        else
                            None
                      MatchingMods = matchingMods
                      MatchingSeparators = matchingSeparators
                      MatchingGroups =
                        Sqlite.number
                            connection
                            transaction
                            (sql
                             + "SELECT count(*) FROM (SELECT CASE WHEN kind=2 THEN id ELSE group_id END AS owner FROM matches WHERE kind=2 OR group_id IS NOT NULL GROUP BY owner)")
                            parameters
                        |> int
                      TotalMods =
                        Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM mods WHERE workspace_id=$workspace AND kind<>2"
                            [ "$workspace", box (string workspace) ]
                        |> int
                      EnabledCount = SelectionRows.enabledCount connection transaction profile }
