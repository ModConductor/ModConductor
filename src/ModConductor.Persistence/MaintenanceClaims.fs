namespace ModConductor.Persistence

module internal MaintenanceClaims =
    let deleting connection transaction modId =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM mod_deletion_targets WHERE mod_id=$mod"
            [ "$mod", box (string modId) ]
        <> 0L

    let busy connection transaction modId =
        deleting connection transaction modId
        || Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM archive_installations WHERE mod_id=$mod AND target_revision IS NOT NULL AND (state=0 OR busy=1)"
            [ "$mod", box (string modId) ]
           <> 0L

    let workspace connection transaction workspace =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM mod_deletions WHERE workspace_id=$workspace"
            [ "$workspace", box (string workspace) ]
        <> 0L

    let unavailable connection transaction context generation =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT unavailable FROM deployment_generations WHERE context_id=$context AND id=$id"
                [ "$context", box (string context); "$id", box (string generation) ]

        match query.ExecuteScalar() with
        | :? string as reason -> Some reason
        | _ -> None

    let generationExists
        connection
        transaction
        (generation: ModConductor.DeploymentRecovery.Generation)
        =
        let available modId version =
            not (deleting connection transaction modId)
            && Sqlite.number
                connection
                transaction
                "SELECT count(*) FROM mods m JOIN mod_versions v ON v.mod_id=m.id WHERE m.id=$mod AND v.id=$version AND v.phase=3"
                [ "$mod", box (string modId); "$version", box (string version) ] = 1L

        let references =
            generation.References
            |> List.forall (function
                | ModConductor.DeploymentPlanning.SourcePin.Mod(modId, version, _) ->
                    available modId version
                | _ -> true)

        let profile =
            generation.Provenance
            |> Option.bind _.Profile
            |> Option.forall (fun value ->
                value.Mods
                |> List.forall (fun entry ->
                    not (deleting connection transaction entry.ModId)
                    && Sqlite.number
                        connection
                        transaction
                        "SELECT count(*) FROM mods WHERE id=$id"
                        [ "$id", box (string entry.ModId) ] = 1L))

        references && profile
