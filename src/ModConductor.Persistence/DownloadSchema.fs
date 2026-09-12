namespace ModConductor.Persistence

module internal DownloadSchema =
    let sql =
        """
    CREATE TABLE artifact_downloads(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      sources TEXT NOT NULL,expected_length INTEGER,expected_sha TEXT,
      state INTEGER NOT NULL,bytes INTEGER NOT NULL,total INTEGER,etag TEXT,effective_url TEXT,
      source_index INTEGER NOT NULL,attempt INTEGER NOT NULL,retry_at INTEGER,
      restart_required INTEGER NOT NULL,checksum_matched INTEGER NOT NULL);
    PRAGMA user_version=15;
    """
