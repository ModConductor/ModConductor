namespace ModConductor.Persistence

module internal SkseSchema =
    let sql =
        """
    CREATE TABLE skse_loader_selections(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      generation_id TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      source_checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id)
    );
    CREATE TABLE skse_artifact_selections(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      game_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      checked_at TEXT NOT NULL
    );
    CREATE INDEX skse_artifact_compatibility ON skse_artifact_selections(workspace_id,account_id,game_sha256,checked_at DESC);
    CREATE TABLE skse_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      game_version TEXT NOT NULL,
      component_version TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      nexus_file INTEGER,
      checked_at TEXT NOT NULL
    );
    CREATE TABLE skse_pending_handoffs(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      account_id TEXT NOT NULL,
      game_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_category TEXT NOT NULL,
      file_description TEXT NOT NULL,
      file_bytes INTEGER,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),
      checked_at TEXT NOT NULL
    );
    CREATE TABLE skse_replacement_intents(
      receipt_id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      expected_selection_revision INTEGER NOT NULL,
      previous_mod_id TEXT,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      generation_id TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      source_checked_at TEXT NOT NULL
    );
    PRAGMA user_version=24;
    """

    let correction =
        """
    ALTER TABLE skse_loader_selections RENAME TO skse_loader_selections_v23;
    CREATE TABLE skse_loader_selections(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      generation_id TEXT NOT NULL,
      executable TEXT NOT NULL,
      component_version TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      source_checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id)
    );
    INSERT INTO skse_loader_selections SELECT profile_id,workspace_id,mod_id,version_id,generation_id,executable,component_version,runtime_version,game_sha256,archive_sha256,nexus_mod,nexus_file,'1970-01-01T00:00:00.0000000+00:00' FROM skse_loader_selections_v23;
    DROP TABLE skse_loader_selections_v23;
    CREATE TABLE skse_artifact_selections(
      artifact_id TEXT PRIMARY KEY REFERENCES artifacts(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id), account_id TEXT NOT NULL,
      game_version TEXT NOT NULL, game_sha256 TEXT NOT NULL, nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL, file_name TEXT NOT NULL, file_version TEXT NOT NULL,
      file_category TEXT NOT NULL, file_description TEXT NOT NULL, file_bytes INTEGER,
      component_version TEXT NOT NULL, runtime_version TEXT NOT NULL,
      acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)), checked_at TEXT NOT NULL
    );
    CREATE INDEX skse_artifact_compatibility ON skse_artifact_selections(workspace_id,account_id,game_sha256,checked_at DESC);
    CREATE TABLE skse_profile_status(profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,workspace_id TEXT NOT NULL REFERENCES workspaces(id),phase TEXT NOT NULL,game_version TEXT NOT NULL,component_version TEXT NOT NULL,status TEXT NOT NULL,detail TEXT NOT NULL,nexus_file INTEGER,checked_at TEXT NOT NULL);
    CREATE TABLE skse_pending_handoffs(profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,workspace_id TEXT NOT NULL REFERENCES workspaces(id),account_id TEXT NOT NULL,game_version TEXT NOT NULL,game_sha256 TEXT NOT NULL,nexus_mod INTEGER NOT NULL,nexus_file INTEGER NOT NULL,file_name TEXT NOT NULL,file_version TEXT NOT NULL,file_category TEXT NOT NULL,file_description TEXT NOT NULL,file_bytes INTEGER,component_version TEXT NOT NULL,runtime_version TEXT NOT NULL,acquisition INTEGER NOT NULL CHECK(acquisition IN (0,1)),checked_at TEXT NOT NULL);
    CREATE TABLE skse_replacement_intents(receipt_id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,expected_selection_revision INTEGER NOT NULL,previous_mod_id TEXT,mod_id TEXT NOT NULL,version_id TEXT NOT NULL,generation_id TEXT NOT NULL,executable TEXT NOT NULL,component_version TEXT NOT NULL,runtime_version TEXT NOT NULL,game_sha256 TEXT NOT NULL,archive_sha256 TEXT NOT NULL,nexus_mod INTEGER NOT NULL,nexus_file INTEGER NOT NULL,source_checked_at TEXT NOT NULL);
    PRAGMA user_version=24;
    """
