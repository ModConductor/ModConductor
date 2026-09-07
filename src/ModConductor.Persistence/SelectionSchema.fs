namespace ModConductor.Persistence

module internal SelectionSchema =
    let sql =
        """
    ALTER TABLE profiles ADD COLUMN selection_revision INTEGER NOT NULL DEFAULT 0;
    CREATE TABLE profile_mods(profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE, mod_id TEXT NOT NULL REFERENCES mods(id), priority INTEGER NOT NULL, enabled INTEGER, PRIMARY KEY(profile_id,mod_id), UNIQUE(profile_id,priority));
    INSERT INTO profile_mods(profile_id,mod_id,priority,enabled)
      SELECT p.id,m.id,ROW_NUMBER() OVER(PARTITION BY p.id ORDER BY m.id)-1,CASE WHEN m.kind=1 THEN 0 ELSE NULL END
      FROM profiles p JOIN mods m ON m.workspace_id=p.workspace_id WHERE m.kind IN (1,2);
    PRAGMA user_version=5;
    """
