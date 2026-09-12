namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.Platform

type internal StoredArtifact =
    { Artifact: Artifact
      Phase: int
      Owner: string
      Busy: bool
      SourceIdentity: FileIdentity option
      StoredIdentity: FileIdentity option }

module internal ArtifactRows =
    let optional (reader: SqliteDataReader) column read =
        if reader.IsDBNull column then None else Some(read column)

    let links connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT l.mod_id,l.version_id,COALESCE(m.name,l.mod_name),l.version_label FROM artifact_links l LEFT JOIN mods m ON m.id=l.mod_id WHERE l.artifact_id=$id ORDER BY l.mod_id,l.version_id"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield
                  { ModId = Guid.Parse(reader.GetString 0)
                    VersionId = Guid.Parse(reader.GetString 1)
                    ModName = reader.GetString 2
                    VersionLabel = reader.GetString 3 } ]

    let find connection transaction workspace id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT revision,original_name,original_path,path,storage,phase,owner,busy,length,sha256,source_identity,stored_identity,problem FROM artifacts WHERE workspace_id=$workspace AND id=$id"
                [ "$workspace", box (string workspace); "$id", box (string id) ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let phase = reader.GetInt32 5

            let row =
                { Artifact =
                    { Id = id
                      WorkspaceId = workspace
                      Revision = reader.GetInt64 0
                      OriginalName = reader.GetString 1
                      OriginalPath = reader.GetString 2
                      Path = reader.GetString 3
                      Storage =
                        if reader.GetInt32 4 = 0 then
                            ArtifactStorage.Reference
                        else
                            ArtifactStorage.Copy
                      State = ArtifactState.Incomplete
                      Length = optional reader 8 reader.GetInt64
                      Sha256 = optional reader 9 reader.GetString
                      Problem = optional reader 12 reader.GetString
                      Links = []
                      CanRetry = false
                      CanLocate = false
                      CanDeleteCopy = false
                      CanRemove = false
                      Download = None }
                  Phase = phase
                  Owner = reader.GetString 6
                  Busy = reader.GetBoolean 7
                  SourceIdentity =
                    optional reader 10 (reader.GetString >> LibraryEncoding.readIdentity)
                  StoredIdentity =
                    optional reader 11 (reader.GetString >> LibraryEncoding.readIdentity) }

            reader.Close()
            let provenance = links connection transaction id
            let download = DownloadRows.info connection transaction id phase

            let state =
                match phase with
                | 2 when not provenance.IsEmpty -> ArtifactState.Installed
                | 2 -> ArtifactState.Ready
                | 3 -> ArtifactState.Detached
                | _ -> ArtifactState.Incomplete

            Some
                { row with
                    Artifact =
                        { row.Artifact with
                            State = state
                            Download = download
                            Links = provenance
                            CanRetry = not row.Busy && phase = 0 && download.IsNone
                            CanLocate =
                                not row.Busy
                                && row.Artifact.Storage = ArtifactStorage.Reference
                                && row.Artifact.Sha256.IsSome
                            CanDeleteCopy =
                                not row.Busy
                                && row.Artifact.Storage = ArtifactStorage.Copy
                                && not (DownloadRows.running download)
                                && (phase <> 3 || row.StoredIdentity.IsSome)
                            CanRemove =
                                not row.Busy
                                && provenance.IsEmpty
                                && (row.Artifact.Storage = ArtifactStorage.Reference
                                    || (phase = 3 && row.StoredIdentity.IsNone)) } }

    let ids connection workspace after =
        use query =
            Sqlite.command
                connection
                null
                "SELECT id FROM artifacts WHERE workspace_id=$workspace AND id>$after ORDER BY id LIMIT 65"
                [ "$workspace", box (string workspace)
                  "$after", box (after |> Option.map string |> Option.defaultValue "") ]

        use reader = query.ExecuteReader()

        [ while reader.Read() do
              yield Guid.Parse(reader.GetString 0) ]

    let nullable value =
        value |> Option.map box |> Option.defaultValue (box DBNull.Value)

    let identity value =
        value |> Option.map LibraryEncoding.identity |> nullable

    let save connection row =
        let a = row.Artifact

        Sqlite.execute
            connection
            null
            "UPDATE artifacts SET revision=$revision,path=$path,phase=$phase,owner=$owner,busy=$busy,length=$length,sha256=$sha,source_identity=$source,stored_identity=$stored,problem=$problem WHERE id=$id"
            [ "$revision", box a.Revision
              "$path", box a.Path
              "$phase", box row.Phase
              "$owner", box row.Owner
              "$busy", box row.Busy
              "$length", nullable a.Length
              "$sha", nullable a.Sha256
              "$source", identity row.SourceIdentity
              "$stored", identity row.StoredIdentity
              "$problem", nullable a.Problem
              "$id", box (string a.Id) ]
