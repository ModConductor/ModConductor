namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ModLibrary
open ModConductor.Platform

type internal StoredMod =
    { Entry: ModEntry
      SourceIdentity: FileIdentity option }

type internal StoredLibrary =
    { Name: string
      Identity: FileIdentity option
      Phase: int
      Owner: string }

type internal StoredPayload =
    { Payload: Payload
      Identity: FileIdentity }

module internal LibraryRows =
    let private optional (reader: SqliteDataReader) column read =
        if reader.IsDBNull column then
            None
        else
            Some(read (reader.GetString column))

    let origin connection transaction version =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT output_action FROM mod_version_origins WHERE version_id=$version"
                [ "$version", box (string version) ]

        match query.ExecuteScalar() with
        | :? string as action -> VersionOrigin.Outputs(Guid.Parse action)
        | _ ->
            use source =
                Sqlite.command
                    connection
                    transaction
                    "SELECT artifact_id FROM archive_version_origins WHERE version_id=$version"
                    [ "$version", box (string version) ]

            match source.ExecuteScalar() with
            | :? string as artifact ->
                use query =
                    Sqlite.command
                        connection
                        transaction
                        "SELECT parent_digest,path_chain,digest_chain FROM bundle_version_origins WHERE version_id=$version"
                        [ "$version", box (string version) ]

                use reader = query.ExecuteReader()

                if reader.Read() then
                    VersionOrigin.Bundle(
                        Guid.Parse artifact,
                        reader.GetString 0,
                        reader.GetString(1).Split('\001')
                        |> Array.map LibraryEncoding.readPath
                        |> Array.toList,
                        reader.GetString(2).Split('\001') |> Array.toList
                    )
                else
                    VersionOrigin.Archive(Guid.Parse artifact)
            | _ -> VersionOrigin.RegisteredSource

    let find connection transaction id =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT id,workspace_id,kind,name,notes,comment,version_text,source_text,revision,source_path,source_identity,current_version,status FROM mods WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = statement.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let metadata =
                { Name = reader.GetString 3
                  Notes = reader.GetString 4
                  Comment = reader.GetString 5
                  Version = reader.GetString 6
                  Source = reader.GetString 7
                  Categories = CategoryRows.references connection transaction id }

            Some
                { Entry =
                    InventoryPolicy.entry
                        (Guid.Parse(reader.GetString 0))
                        (Guid.Parse(reader.GetString 1))
                        (LibraryEncoding.readKind (reader.GetInt32 2))
                        metadata
                        (reader.GetInt64 8)
                        (optional reader 9 LibraryEncoding.readPath)
                        (optional reader 11 Guid.Parse)
                        (LibraryEncoding.readStatus (reader.GetInt32 12))
                    |> fun entry ->
                        { entry with
                            VersionOrigin =
                                entry.CurrentVersion |> Option.map (origin connection transaction) }
                  SourceIdentity = optional reader 10 LibraryEncoding.readIdentity }

    let metadataParameters (metadata: ModMetadata) =
        [ "$name", box metadata.Name
          "$notes", box metadata.Notes
          "$comment", box metadata.Comment
          "$version", box metadata.Version
          "$source", box metadata.Source ]

    let library connection transaction workspace =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT directory,identity,phase,owner FROM mod_libraries WHERE workspace_id=$workspace"
                [ "$workspace", box (string workspace) ]

        use reader = statement.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            Some
                { Name = reader.GetString 0
                  Identity = optional reader 1 LibraryEncoding.readIdentity
                  Phase = reader.GetInt32 2
                  Owner = reader.GetString 3 }

    let ids connection transaction workspace after count =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT id FROM mods WHERE workspace_id=$workspace AND id>$after ORDER BY id LIMIT $count"
                [ "$workspace", box (string workspace)
                  "$after", box after
                  "$count", box count ]

        use reader = statement.ExecuteReader()

        [ while reader.Read() do
              yield Guid.Parse(reader.GetString 0) ]

    let payload connection transaction id =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT identity,length,digest FROM mod_payloads WHERE id=$id AND identity IS NOT NULL"
                [ "$id", box (string id) ]

        use reader = statement.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            Some
                { Payload =
                    { Id = id
                      Length = reader.GetInt64 1
                      Sha256 = reader.GetString 2 }
                  Identity = LibraryEncoding.readIdentity (reader.GetString 0) }

    let version connection transaction id offset count =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT mod_id FROM mod_versions WHERE id=$id AND phase=3"
                [ "$id", box (string id) ]

        let modId = statement.ExecuteScalar()

        if isNull modId then
            None
        else
            use entries =
                Sqlite.command
                    connection
                    transaction
                    "SELECT m.path,p.id,p.length,p.digest FROM mod_manifest m JOIN mod_payloads p ON m.payload_id=p.id WHERE m.version_id=$id ORDER BY m.path LIMIT $count OFFSET $offset"
                    [ "$id", box (string id); "$count", box count; "$offset", box offset ]

            use reader = entries.ExecuteReader()

            Some
                { Id = id
                  ModId = Guid.Parse(string modId)
                  Origin = origin connection transaction id
                  Entries =
                    [ while reader.Read() do
                          yield
                              { Path = LibraryEncoding.readPath (reader.GetString 0)
                                Payload =
                                  { Id = Guid.Parse(reader.GetString 1)
                                    Length = reader.GetInt64 2
                                    Sha256 = reader.GetString 3 } } ]
                  NextOffset = None }

    let profileWorkspace connection transaction profile =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT workspace_id FROM profiles WHERE id=$id"
                [ "$id", box (string profile) ]

        let value = statement.ExecuteScalar()

        if isNull value then
            None
        else
            Some(Guid.Parse(string value))

    let setStatus connection transaction id status =
        Sqlite.execute
            connection
            transaction
            "UPDATE mods SET status=$status WHERE id=$id"
            [ "$id", box (string id); "$status", box (LibraryEncoding.status status) ]
