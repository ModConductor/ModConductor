namespace ModConductor.Persistence

module internal EnbSchema =
    let sql =
        """
    CREATE TABLE enb_profile_status(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      phase TEXT NOT NULL,
      status TEXT NOT NULL,
      detail TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      preset_version TEXT NOT NULL,
      artifact_id TEXT,
      archive_sha256 TEXT,
      checked_at TEXT NOT NULL
    );
    CREATE TABLE enb_launch_plans(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      game_sha256 TEXT NOT NULL,
      runtime_version TEXT NOT NULL,
      preset_version TEXT NOT NULL,
      runtime_sha256 TEXT NOT NULL,
      preset_sha256 TEXT NOT NULL,
      companion_provenance TEXT NOT NULL,
      dll_overrides TEXT NOT NULL,
      selected_runtime TEXT NOT NULL,
      previous_values TEXT NOT NULL,
      configuration_action TEXT,
      PRIMARY KEY(profile_id,generation_id)
    );
    CREATE TABLE enb_generation_components(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      generation_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      mod_id TEXT NOT NULL,
      version_id TEXT NOT NULL,
      component_version TEXT NOT NULL,
      archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER,
      nexus_file INTEGER,
      source_url TEXT NOT NULL,
      terms_url TEXT NOT NULL,
      checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id,kind)
    );
    CREATE TABLE enb_pending_sources(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      runtime_artifact_id TEXT NOT NULL REFERENCES artifacts(id),
      runtime_sha256 TEXT NOT NULL,
      kind TEXT NOT NULL,
      nexus_mod INTEGER NOT NULL,
      nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_version TEXT NOT NULL,
      file_bytes INTEGER,
      account_id TEXT NOT NULL,
      checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,kind)
    );
    CREATE TABLE enb_selection_intents(
      receipt_id TEXT NOT NULL,
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      expected_revision INTEGER NOT NULL,
      mod_id TEXT NOT NULL,
      enabled INTEGER NOT NULL,
      PRIMARY KEY(receipt_id,mod_id)
    );
    PRAGMA user_version=26;
    """

    let correction =
        """
    ALTER TABLE enb_launch_plans ADD COLUMN configuration_action TEXT;
    CREATE TABLE enb_generation_components(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id), generation_id TEXT NOT NULL,
      kind TEXT NOT NULL, mod_id TEXT NOT NULL, version_id TEXT NOT NULL,
      component_version TEXT NOT NULL, archive_sha256 TEXT NOT NULL,
      nexus_mod INTEGER, nexus_file INTEGER, source_url TEXT NOT NULL,
      terms_url TEXT NOT NULL, checked_at TEXT NOT NULL,
      PRIMARY KEY(profile_id,generation_id,kind));
    CREATE TABLE enb_pending_sources(
      profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      runtime_artifact_id TEXT NOT NULL REFERENCES artifacts(id), runtime_sha256 TEXT NOT NULL,
      kind TEXT NOT NULL, nexus_mod INTEGER NOT NULL, nexus_file INTEGER NOT NULL,
      file_name TEXT NOT NULL, file_version TEXT NOT NULL, file_bytes INTEGER,
      account_id TEXT NOT NULL, checked_at TEXT NOT NULL, PRIMARY KEY(profile_id,kind));
    CREATE TABLE enb_selection_intents(
      receipt_id TEXT NOT NULL, profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id), expected_revision INTEGER NOT NULL,
      mod_id TEXT NOT NULL, enabled INTEGER NOT NULL, PRIMARY KEY(receipt_id,mod_id));
    PRAGMA user_version=26;
    """
