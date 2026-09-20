namespace ModConductor.Persistence

module internal SkyrimSetupSchema =
    let sql =
        """
    CREATE TABLE skyrim_setup_intents(
      profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      include_fnis INTEGER NOT NULL CHECK(include_fnis IN (0,1)),
      plan_token TEXT NOT NULL,
      requested_at TEXT NOT NULL
    );
    PRAGMA user_version=31;
    """

    let correction =
        """
    ALTER TABLE skyrim_setup_intents ADD COLUMN cancelled INTEGER NOT NULL DEFAULT 0 CHECK(cancelled IN (0,1));
    ALTER TABLE skyrim_setup_intents ADD COLUMN completed INTEGER NOT NULL DEFAULT 0 CHECK(completed IN (0,1));
    ALTER TABLE skyrim_setup_intents ADD COLUMN stage TEXT NOT NULL DEFAULT 'setup';
    ALTER TABLE skyrim_setup_intents ADD COLUMN context_revision INTEGER NOT NULL DEFAULT 0;
    PRAGMA user_version=32;
    """
