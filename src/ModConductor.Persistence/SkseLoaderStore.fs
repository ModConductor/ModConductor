namespace ModConductor.Persistence

open System
open ModConductor.GameLaunching

type internal SkseLoaderStore(database: StateDatabase) =
    member _.CurrentMod(profile: Guid) =
        database.Enqueue(fun () ->
            use query =
                Sqlite.command
                    database.Connection
                    null
                    "SELECT mod_id FROM skse_loader_selections WHERE profile_id=$profile"
                    [ "$profile", box (string profile) ]

            match query.ExecuteScalar() with
            | :? string as value -> Some(Guid.Parse value)
            | _ -> None)

    interface IComponentLoaderSelection with
        member _.Read(workspace, profile, activeGeneration) =
            database.Enqueue(fun () ->
                match activeGeneration with
                | None -> None
                | Some generation ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT executable,component_version,runtime_version,game_sha256 FROM skse_loader_selections WHERE profile_id=$profile AND workspace_id=$workspace AND generation_id=$generation"
                            [ "$profile", box (string profile)
                              "$workspace", box (string workspace)
                              "$generation", box (string generation) ]

                    use reader = query.ExecuteReader()

                    if reader.Read() then
                        Some
                            { GenerationId = generation
                              Executable = reader.GetString 0
                              ComponentVersion = reader.GetString 1
                              RuntimeVersion = reader.GetString 2
                              GameSha256 = reader.GetString 3 }
                    else
                        None)

    member _.Save
        (
            workspace: Guid,
            profile: Guid,
            modId: Guid,
            versionId: Guid,
            generation: Guid,
            executable: string,
            componentVersion: string,
            runtimeVersion: string,
            gameSha256: string,
            archiveSha256: string,
            nexusMod: int64,
            nexusFile: int64
        ) =
        database.EnqueueInternal(fun () ->
            Sqlite.execute
                database.Connection
                null
                "INSERT INTO skse_loader_selections VALUES($profile,$workspace,$installedMod,$version,$generation,$executable,$component,$runtime,$game,$archive,$mod,$file) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,mod_id=excluded.mod_id,version_id=excluded.version_id,generation_id=excluded.generation_id,executable=excluded.executable,component_version=excluded.component_version,runtime_version=excluded.runtime_version,game_sha256=excluded.game_sha256,archive_sha256=excluded.archive_sha256,nexus_mod=excluded.nexus_mod,nexus_file=excluded.nexus_file"
                [ "$profile", box (string profile)
                  "$workspace", box (string workspace)
                  "$installedMod", box (string modId)
                  "$version", box (string versionId)
                  "$generation", box (string generation)
                  "$executable", box executable
                  "$component", box componentVersion
                  "$runtime", box runtimeVersion
                  "$game", box gameSha256
                  "$archive", box archiveSha256
                  "$mod", box nexusMod
                  "$file", box nexusFile ])
