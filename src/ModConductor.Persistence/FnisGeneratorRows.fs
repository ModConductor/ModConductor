namespace ModConductor.Persistence

open System

module internal FnisGeneratorRows =
    let readStored
        (database: StateDatabase)
        (workspace: Guid)
        (profile: Guid)
        (activeGeneration: Guid option)
        =
        database.Enqueue(fun () ->
            match activeGeneration with
            | None -> None
            | Some generation ->
                let readStored (query: Microsoft.Data.Sqlite.SqliteCommand) =
                    use reader = query.ExecuteReader()

                    if reader.Read() then
                        Some
                            { GenerationId = generation
                              ModId = Guid.Parse(reader.GetString 0)
                              VersionId = Guid.Parse(reader.GetString 1)
                              ArtifactId = Guid.Parse(reader.GetString 2)
                              FileName = reader.GetString 3
                              FileVersion = reader.GetString 4
                              Executable = reader.GetString 5
                              ComponentVersion = reader.GetString 6
                              ArchiveSha256 = reader.GetString 7
                              Provider = reader.GetString 8
                              Source = reader.GetString 9
                              Terms = reader.GetString 10
                              NexusModId = reader.GetInt64 11
                              NexusFileId = reader.GetInt64 12
                              AcquiredAt = DateTimeOffset.Parse(reader.GetString 13) }
                    else
                        None

                use exact =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT mod_id,version_id,artifact_id,file_name,file_version,executable,component_version,archive_sha256,provider,source,terms,nexus_mod,nexus_file,acquired_at FROM fnis_generators WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                        [ "$profile", box (string profile)
                          "$workspace", box (string workspace)
                          "$generation", box (string generation) ]

                match readStored exact with
                | Some stored -> Some stored
                | None ->
                    use selected =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT g.mod_id,g.version_id,g.artifact_id,g.file_name,g.file_version,g.executable,g.component_version,g.archive_sha256,g.provider,g.source,g.terms,g.nexus_mod,g.nexus_file,g.acquired_at FROM fnis_generators g JOIN profile_mods p ON p.profile_id=g.profile_id AND p.mod_id=g.mod_id AND p.enabled=1 JOIN mods m ON m.id=g.mod_id AND m.current_version=g.version_id WHERE g.profile_id=$profile AND g.workspace_id=$workspace ORDER BY g.acquired_at DESC LIMIT 1"
                            [ "$profile", box (string profile)
                              "$workspace", box (string workspace) ]

                    readStored selected)
