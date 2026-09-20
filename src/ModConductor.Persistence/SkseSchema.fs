namespace ModConductor.Persistence

module internal SkseSchema =
    let sql =
        """
    CREATE TABLE skse_loader_selections(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
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
      nexus_file INTEGER NOT NULL
    );
    PRAGMA user_version=23;
    """
