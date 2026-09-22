namespace ModConductor.Persistence

open System

module internal BundleDeletion =
    let works connection transaction targets =
        targets
        |> List.collect (fun target ->
            DeletionRows.ids
                connection
                transaction
                "SELECT bundle_id FROM bundle_mods WHERE mod_id=$mod"
                [ "$mod", box (string target) ])
        |> List.distinct

    let files connection transaction workspace targets =
        let targets = Set.ofList targets

        works connection transaction (Set.toList targets)
        |> List.collect (fun id ->
            let all = BundleRows.sources connection transaction id
            let mods = (BundleRows.snapshot connection transaction workspace id).Mods

            let chains items =
                items
                |> List.collect (fun (item: ModConductor.BundleInstallation.BundleMod) ->
                    BundleRows.chain all (all |> List.find (fun s -> s.Id = item.SourceId))
                    |> List.map _.Id)
                |> Set.ofList

            let removed = mods |> List.filter (fun m -> targets.Contains m.ModId) |> chains

            let remaining =
                mods |> List.filter (fun m -> not (targets.Contains m.ModId)) |> chains

            all
            |> List.filter (fun s -> removed.Contains s.Id)
            |> List.map (fun s -> s, remaining.Contains s.Id))

    let parentShared connection transaction artifact targets =
        DeletionRows.ids
            connection
            transaction
            "SELECT m.mod_id FROM bundle_mods m JOIN bundle_work w ON w.id=m.bundle_id WHERE w.artifact_id=$artifact"
            [ "$artifact", box (string artifact) ]
        |> List.exists (fun id -> not (Set.contains id targets))

    let busy connection transaction workspace targets =
        works connection transaction targets
        |> List.exists (fun id -> (BundleRows.work connection transaction workspace id).Busy <> 0)

    let complete connection transaction workspace targets =
        let workIds = works connection transaction targets

        let privateSources =
            files connection transaction workspace targets
            |> List.choose (fun (s, shared) -> if shared then None else Some s)

        let ordered =
            privateSources
            |> List.sortByDescending (fun s ->
                BundleRows.sources connection transaction s.BundleId
                |> fun all -> (BundleRows.chain all s).Length)

        for target in targets do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM bundle_mods WHERE mod_id=$mod"
                [ "$mod", box (string target) ]

        for source in ordered do
            Sqlite.execute
                connection
                transaction
                "DELETE FROM bundle_sources WHERE id=$id"
                [ "$id", box (string source.Id) ]

        for id in workIds do
            if
                Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM bundle_mods WHERE bundle_id=$id"
                    [ "$id", box (string id) ] = 0L
            then
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM bundle_work WHERE id=$id"
                    [ "$id", box (string id) ]
            else
                BundleRows.touch connection transaction id
