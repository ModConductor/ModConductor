namespace ModConductor.Persistence

open System
open ModConductor.HttpDownloads
open ModConductor.Nexus

module internal NexusOriginRows =
    let derived connection tx version =
        use query =
            Sqlite.command
                connection
                tx
                "SELECT d.sources,d.nexus_version FROM archive_version_origins a JOIN artifact_downloads d ON d.artifact_id=a.artifact_id WHERE a.version_id=$version AND NOT EXISTS(SELECT 1 FROM bundle_version_origins b WHERE b.version_id=a.version_id)"
                [ "$version", box (string version) ]

        use reader = query.ExecuteReader()

        if reader.Read() then
            match DownloadSource.decode (reader.GetString 0) with
            | DownloadSource.Nexus value ->
                Some(
                    { Game = value.Game; Mod = value.ModId },
                    { Id = value.FileId
                      Version = (if reader.IsDBNull 1 then "" else reader.GetString 1)
                      Manual = false }
                )
            | DownloadSource.Url _ -> None
        else
            None

    let origins connection tx version =
        use query =
            Sqlite.command
                connection
                tx
                "SELECT game,nexus_mod,file_id,version,manual FROM version_nexus_origins WHERE version_id=$version ORDER BY manual DESC"
                [ "$version", box (string version) ]

        use reader = query.ExecuteReader()

        let rows =
            [ while reader.Read() do
                  yield
                      ({ Game = reader.GetString 0
                         Mod = reader.GetInt64 1 },
                       { Id = reader.GetInt64 2
                         Version = reader.GetString 3
                         Manual = reader.GetBoolean 4 }) ]

        reader.Close()

        if rows |> List.exists (fun (_, file) -> not file.Manual) then
            rows
        else
            rows @ (derived connection tx version |> Option.toList)

    let save connection tx version (identity: NexusIdentity) (file: InstalledNexusFile) =
        Sqlite.execute
            connection
            tx
            "INSERT INTO version_nexus_origins VALUES($version,$manual,$game,$mod,$file,$label) ON CONFLICT(version_id,manual) DO UPDATE SET game=excluded.game,nexus_mod=excluded.nexus_mod,file_id=excluded.file_id,version=excluded.version"
            [ "$version", box (string version)
              "$manual", box file.Manual
              "$game", box identity.Game
              "$mod", box identity.Mod
              "$file", box file.Id
              "$label", box file.Version ]

    let published connection tx modId version =
        match derived connection tx version with
        | None -> ()
        | Some(identity, file) ->
            save connection tx version identity file

            Sqlite.execute
                connection
                tx
                "INSERT OR IGNORE INTO mod_nexus_links(mod_id,game,nexus_mod) VALUES($id,$game,$mod)"
                [ "$id", box (string modId)
                  "$game", box identity.Game
                  "$mod", box identity.Mod ]
