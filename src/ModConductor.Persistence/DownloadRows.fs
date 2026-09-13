namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads

module internal DownloadRows =
    let optional (reader: SqliteDataReader) column read =
        if reader.IsDBNull column then None else Some(read column)

    let work connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT a.workspace_id,a.original_name,d.sources,d.expected_length,d.expected_sha,d.bytes,d.total,d.etag,d.effective_url,d.source_index,d.attempt,d.nexus_version FROM artifact_downloads d JOIN artifacts a ON a.id=d.artifact_id WHERE a.id=$id"
                [ "$id", box (string id) ]

        use r = query.ExecuteReader()

        if not (r.Read()) then
            None
        else
            Some
                { Request =
                    { Id = id
                      WorkspaceId = Guid.Parse(r.GetString 0)
                      Name = r.GetString 1
                      Sources =
                        (r.GetString 2).Split('\n')
                        |> Array.map (fun source ->
                            match DownloadSource.decode source with
                            | DownloadSource.Nexus reference ->
                                DownloadSource.Nexus
                                    { reference with
                                        Version = optional r 11 r.GetString }
                            | value -> value)
                        |> Array.toList
                      ExpectedLength = optional r 3 r.GetInt64
                      ExpectedSha256 = optional r 4 r.GetString }
                  Bytes = r.GetInt64 5
                  Total = optional r 6 r.GetInt64
                  EntityTag = optional r 7 r.GetString
                  EffectiveUrl = optional r 8 r.GetString
                  SourceIndex = r.GetInt32 9
                  Attempt = r.GetInt32 10 }

    let info connection transaction id phase =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT state,bytes,total,sources,source_index,expected_sha,checksum_matched,restart_required,retry_at,etag FROM artifact_downloads WHERE artifact_id=$id"
                [ "$id", box (string id) ]

        use r = query.ExecuteReader()

        if not (r.Read()) then
            None
        else
            Some
                { State =
                    if phase = 2 || phase = 3 then
                        DownloadState.Complete
                    else
                        match r.GetInt32 0 with
                        | 0 -> DownloadState.Queued
                        | 1 -> DownloadState.Running
                        | 2 -> DownloadState.Waiting
                        | 3 -> DownloadState.Paused
                        | 4 -> DownloadState.Failed
                        | 5 -> DownloadState.Complete
                        | _ -> invalidOp "The saved download state is invalid."
                  Bytes = r.GetInt64 1
                  Total = optional r 2 r.GetInt64
                  Source =
                    DownloadSource.display (
                        DownloadSource.decode ((r.GetString 3).Split('\n')[r.GetInt32 4])
                    )
                  ExpectedSha256 = optional r 5 r.GetString
                  ChecksumMatched = phase = 2 && r.GetBoolean 6
                  RestartRequired =
                    r.GetBoolean 7 || (phase = 0 && r.GetInt64 1 > 0L && r.IsDBNull 9)
                  RetryAt = optional r 8 (r.GetInt64 >> DateTimeOffset.FromUnixTimeMilliseconds) }

    let running (value: DownloadInfo option) =
        match value with
        | Some info ->
            match info.State with
            | DownloadState.Queued
            | DownloadState.Running
            | DownloadState.Waiting -> true
            | DownloadState.Paused
            | DownloadState.Failed
            | DownloadState.Complete -> false
        | None -> false
