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
      PRIMARY KEY(profile_id,generation_id)
    );
    PRAGMA user_version=25;
    """
