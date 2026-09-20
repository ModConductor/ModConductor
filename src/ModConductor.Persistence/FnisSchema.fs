namespace ModConductor.Persistence

module internal FnisSchema =
    let sql =
        """
    CREATE TABLE fnis_generators(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      artifact_id TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      provider TEXT NOT NULL,
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      acquired_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id)
    );
    CREATE TABLE fnis_artifact_selections(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      checked_at TEXT NOT NULL
    );
    CREATE INDEX fnis_artifact_cache ON fnis_artifact_selections(workspace_id,account_id,checked_at DESC);
    CREATE TABLE fnis_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      component_version TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      nexus_file INTEGER,
      artifact_id TEXT,
      checked_at TEXT NOT NULL
    );
    CREATE TABLE fnis_pending_handoffs(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      source TEXT NOT NULL,
      terms TEXT NOT NULL,
      checked_at TEXT NOT NULL
    );
    CREATE TABLE fnis_publication_intents(
      receipt_id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      kind INTEGER NOT NULL CHECK(kind IN (0,1)),
      expected_selection_revision INTEGER NOT NULL,
      previous_mod_id TEXT,
      mod_id TEXT,
      version_id TEXT,
      artifact_id TEXT,
      file_name TEXT,
      file_version TEXT,
      generation_id TEXT NOT NULL,
      executable TEXT,
      component_version TEXT,
      archive_sha256 TEXT,
      provider TEXT,
      source TEXT,
      terms TEXT,
      nexus_mod INTEGER,
      nexus_file INTEGER,
      acquired_at TEXT
    );
    PRAGMA user_version=28;
    """
