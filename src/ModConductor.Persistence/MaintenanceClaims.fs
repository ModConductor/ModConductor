namespace ModConductor.Persistence

open System
open ModConductor.ModLibrary

module internal MaintenanceClaims =
    let private operation (id: string) (workspace: string) kind actions =
        { Id = Guid.Parse id
          WorkspaceId = Guid.Parse workspace
          Kind = kind
          Actions = actions }

    let activeOperation connection transaction modId =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT d.id,d.workspace_id,d.busy,1 FROM mod_deletions d JOIN mod_deletion_targets t ON t.deletion_id=d.id WHERE t.mod_id=$mod UNION ALL SELECT i.id,i.workspace_id,CASE WHEN i.state=0 THEN 1 ELSE 0 END,2 FROM archive_installations i WHERE i.mod_id=$mod AND i.target_revision IS NOT NULL AND (i.state=0 OR i.busy=1) UNION ALL SELECT v.id,m.workspace_id,v.busy,3 FROM mod_versions v JOIN mods m ON m.id=v.mod_id WHERE v.mod_id=$mod AND v.busy=1 LIMIT 1"
                [ "$mod", box (string modId) ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let id, workspace, live =
                reader.GetString 0, reader.GetString 1, reader.GetBoolean 2

            let kind, actions =
                match reader.GetInt32 3 with
                | 1 ->
                    LibraryOperationKind.Deletion,
                    (if live then
                         [ LibraryOperationAction.Wait ]
                     else
                         [ LibraryOperationAction.Resume ])
                | 2 ->
                    LibraryOperationKind.Upgrade,
                    [ LibraryOperationAction.Wait; LibraryOperationAction.Cancel ]
                | _ ->
                    LibraryOperationKind.Publication,
                    [ LibraryOperationAction.Wait; LibraryOperationAction.Cancel ]

            Some(operation id workspace kind actions)

    let busyError connection transaction modId =
        activeOperation connection transaction modId
        |> Option.map LibraryError.Busy
        |> Option.defaultValue LibraryError.FileUnavailable

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
