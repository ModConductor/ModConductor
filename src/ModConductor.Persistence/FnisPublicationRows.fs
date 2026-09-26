namespace ModConductor.Persistence

open System

module internal FnisPublicationRows =
    let completePublication connection transaction receiptId publish =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id,profile_id,kind,expected_selection_revision,previous_mod_id,mod_id,version_id,artifact_id,file_name,file_version,generation_id,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at FROM fnis_publication_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            let workspace = Guid.Parse(reader.GetString 0)
            let profile = Guid.Parse(reader.GetString 1)
            let kind = reader.GetInt64 2
            let expected = reader.GetInt64 3

            let previous =
                if reader.IsDBNull 4 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 4))

            let target =
                if reader.IsDBNull 5 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 5))

            let generator =
                if kind = 0L then
                    Some(
                        Guid.Parse(reader.GetString 6),
                        Guid.Parse(reader.GetString 7),
                        reader.GetString 8,
                        reader.GetString 9,
                        Guid.Parse(reader.GetString 10),
                        reader.GetString 11,
                        reader.GetString 12,
                        reader.GetString 13,
                        reader.GetString 14,
                        reader.GetString 15,
                        reader.GetString 16,
                        reader.GetInt64 17,
                        reader.GetInt64 18,
                        reader.GetString 19
                    )
                else
                    None

            reader.Close()

            if publish then
                match SelectionRows.profile connection transaction profile with
                | Some(owner, revision) when owner = workspace && revision = expected -> ()
                | _ ->
                    raise (
                        ModConductor.DeploymentRecovery.RecoveryException
                            ModConductor.DeploymentRecovery.RecoveryError.Stale
                    )

                let current = SelectionRows.all connection transaction profile

                let changed =
                    current
                    |> List.map (fun row ->
                        if target = Some row.Id then
                            { row with Enabled = Some true }
                        elif previous = Some row.Id then
                            { row with Enabled = Some false }
                        else
                            row)

                if
                    target
                    |> Option.exists (fun id -> current |> List.exists (fun row -> row.Id = id))
                    |> not
                    && target.IsSome
                then
                    raise (
                        ModConductor.DeploymentRecovery.RecoveryException
                            ModConductor.DeploymentRecovery.RecoveryError.Stale
                    )

                SelectionRows.apply connection transaction profile changed

                match target, generator with
                | Some modId,
                  Some(versionId,
                       artifactId,
                       fileName,
                       fileVersion,
                       generation,
                       executable,
                       componentVersion,
                       archive,
                       provider,
                       source,
                       terms,
                       nexusMod,
                       nexusFile,
                       acquiredAt) ->
                    Sqlite.execute
                        connection
                        transaction
                        "INSERT OR IGNORE INTO fnis_generators(profile_id,workspace_id,generation_id,mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at) VALUES($profile,$workspace,$generation,$mod,$version,$artifact,$fileName,$fileVersion,$executable,$component,$archive,$provider,$source,$terms,$nexusMod,$nexusFile,$acquired)"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation)
                          "$mod", box (string modId)
                          "$version", box (string versionId)
                          "$artifact", box (string artifactId)
                          "$fileName", box fileName
                          "$fileVersion", box fileVersion
                          "$executable", box executable
                          "$component", box componentVersion
                          "$archive", box archive
                          "$provider", box provider
                          "$source", box source
                          "$terms", box terms
                          "$nexusMod", box nexusMod
                          "$nexusFile", box nexusFile
                          "$acquired", box acquiredAt ]
                | _ -> ()

            Sqlite.execute
                connection
                transaction
                "DELETE FROM fnis_publication_intents WHERE receipt_id=$receipt"
                [ "$receipt", box (string receiptId) ]
