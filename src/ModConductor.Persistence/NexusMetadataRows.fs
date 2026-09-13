namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.Nexus
open ModConductor.ModLibrary

module internal NexusMetadataRows =
    let nullable value =
        value |> Option.map box |> Option.defaultValue (box DBNull.Value)

    let optional (r: SqliteDataReader) i read =
        if r.IsDBNull i then None else Some(read i)

    let date (r: SqliteDataReader) i =
        optional r i (r.GetInt64 >> DateTimeOffset.FromUnixTimeMilliseconds)

    let parameters modId = [ "$id", box (string modId) ]

    let files connection tx modId =
        use query =
            Sqlite.command
                connection
                tx
                "SELECT file_id,name,version,category,description,bytes,category_id,uploaded FROM mod_nexus_files WHERE mod_id=$id ORDER BY file_id"
                (parameters modId)

        use r = query.ExecuteReader()

        [ while r.Read() do
              yield
                  { File =
                      { Id = r.GetInt64 0
                        Name = r.GetString 1
                        Version = r.GetString 2
                        Category = r.GetString 3
                        Description = r.GetString 4
                        Bytes = optional r 5 r.GetInt64 }
                    CategoryId = r.GetInt32 6
                    Uploaded = date r 7 } ]

    let updates connection tx modId =
        use query =
            Sqlite.command
                connection
                tx
                "SELECT previous,next FROM mod_nexus_updates WHERE mod_id=$id ORDER BY previous,next"
                (parameters modId)

        use r = query.ExecuteReader()

        [ while r.Read() do
              yield
                  { Previous = r.GetInt64 0
                    Next = r.GetInt64 1 } ]

    let read connection tx owner workspace modId =
        match LibraryRows.find connection tx modId with
        | Some row when
            row.Entry.WorkspaceId = workspace
            && row.Entry.Kind = ModKind.Regular
            && not (MaintenanceClaims.deleting connection tx modId)
            ->
            let entry = row.Entry

            let origins =
                entry.CurrentVersion
                |> Option.map (NexusOriginRows.origins connection tx)
                |> Option.defaultValue []

            use query =
                Sqlite.command
                    connection
                    tx
                    "SELECT revision,game,nexus_mod,name,summary,version,author,uploader,category_id,category_label,modified,available,allows_rating,checked,checked_owner,problem,mapped_provider,mapped_category FROM mod_nexus_links WHERE mod_id=$id"
                    (parameters modId)

            use r = query.ExecuteReader()
            let exists = r.Read()

            let identity =
                if exists then
                    optional r 1 (fun _ ->
                        { Game = r.GetString 1
                          Mod = r.GetInt64 2 })
                else
                    origins |> List.tryHead |> Option.map fst

            let installed =
                origins
                |> List.tryPick (fun (origin, file) ->
                    if Some origin = identity then Some file else None)

            let snapshot =
                if not exists || r.IsDBNull 3 then
                    None
                else
                    identity
                    |> Option.map (fun identity ->
                        { Identity = identity
                          Name = r.GetString 3
                          Summary = r.GetString 4
                          Version = r.GetString 5
                          Author = r.GetString 6
                          Uploader = r.GetString 7
                          Category = optional r 8 (fun _ -> r.GetInt64 8, r.GetString 9)
                          Modified = date r 10
                          Available = r.GetBoolean 11
                          AllowsRating = r.GetBoolean 12
                          Files = files connection tx modId
                          Updates = updates connection tx modId })

            let problem = if exists then optional r 15 r.GetString else None

            let mapping =
                if not exists || r.IsDBNull 16 || r.IsDBNull 17 then
                    None
                else
                    let provider = r.GetInt64 16

                    CategoryRows.find connection tx (Guid.Parse(r.GetString 17))
                    |> Option.filter (fun category ->
                        not category.Missing
                        && category.WorkspaceId = workspace
                        && (snapshot |> Option.bind _.Category |> Option.map fst) = Some provider)
                    |> Option.map (fun category ->
                        { ProviderId = provider
                          CategoryId = category.Id
                          Label = category.Label })

            Ok
                { Workspace = workspace
                  Mod = modId
                  Name = entry.Metadata.Name
                  ModRevision = entry.Revision
                  Version = entry.CurrentVersion
                  LinkRevision = if exists then r.GetInt64 0 else 0L
                  Identity = identity
                  Installed = installed
                  Snapshot = snapshot
                  Freshness =
                    match snapshot with
                    | None -> NexusFreshness.Unavailable
                    | Some value when not value.Available -> NexusFreshness.Unavailable
                    | Some _ when problem.IsSome || r.IsDBNull 14 || r.GetString 14 <> owner ->
                        NexusFreshness.Stale
                    | Some _ -> NexusFreshness.Current
                  Checked = if exists then date r 13 else None
                  Problem = problem
                  CategoryMapping = mapping }
        | _ -> Error NexusProblem.ModChanged

    let save connection tx owner modId (value: NexusMetadata) =
        let p = parameters modId

        Sqlite.execute
            connection
            tx
            "UPDATE mod_nexus_links SET name=$name,summary=$summary,version=$version,author=$author,uploader=$uploader,category_id=$category,category_label=$label,modified=$modified,available=$available,allows_rating=$rating,checked=$checked,checked_owner=$owner,problem=NULL WHERE mod_id=$id"
            (p
             @ [ "$name", box value.Name
                 "$summary", box value.Summary
                 "$version", box value.Version
                 "$author", box value.Author
                 "$uploader", box value.Uploader
                 "$category", nullable (value.Category |> Option.map fst)
                 "$label", nullable (value.Category |> Option.map snd)
                 "$modified", nullable (value.Modified |> Option.map _.ToUnixTimeMilliseconds())
                 "$available", box value.Available
                 "$rating", box value.AllowsRating
                 "$checked", box (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds())
                 "$owner", box owner ])

        Sqlite.execute
            connection
            tx
            "DELETE FROM mod_nexus_files WHERE mod_id=$id; DELETE FROM mod_nexus_updates WHERE mod_id=$id"
            p

        for file in value.Files do
            Sqlite.execute
                connection
                tx
                "INSERT INTO mod_nexus_files VALUES($id,$file,$name,$version,$category,$description,$bytes,$categoryId,$uploaded)"
                (p
                 @ [ "$file", box file.File.Id
                     "$name", box file.File.Name
                     "$version", box file.File.Version
                     "$category", box file.File.Category
                     "$description", box file.File.Description
                     "$bytes", nullable file.File.Bytes
                     "$categoryId", box file.CategoryId
                     "$uploaded", nullable (file.Uploaded |> Option.map _.ToUnixTimeMilliseconds()) ])

        for edge in value.Updates |> List.distinct do
            Sqlite.execute
                connection
                tx
                "INSERT INTO mod_nexus_updates VALUES($id,$previous,$next)"
                (p @ [ "$previous", box edge.Previous; "$next", box edge.Next ])
