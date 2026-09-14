namespace ModConductor.Persistence

module internal EditSchema =
    let sql =
        """
    CREATE TABLE mod_edit_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),edit_id TEXT NOT NULL UNIQUE,source_version TEXT NOT NULL REFERENCES mod_versions(id),path TEXT NOT NULL,previous_payload TEXT NOT NULL REFERENCES mod_payloads(id),content BLOB NOT NULL,digest TEXT NOT NULL);
    PRAGMA user_version=21;
    """
