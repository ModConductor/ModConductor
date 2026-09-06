namespace ModConductor.Persistence

module internal LibrarySchema =
    let sql =
        """
    CREATE TABLE mod_libraries(workspace_id TEXT PRIMARY KEY REFERENCES workspaces(id), directory TEXT NOT NULL UNIQUE, owner TEXT NOT NULL, phase INTEGER NOT NULL, identity TEXT);
    CREATE TABLE mods(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), kind INTEGER NOT NULL, name TEXT NOT NULL, notes TEXT NOT NULL, comment TEXT NOT NULL, version_text TEXT NOT NULL, source_text TEXT NOT NULL, category TEXT NOT NULL, revision INTEGER NOT NULL, source_path TEXT, source_identity TEXT, current_version TEXT REFERENCES mod_versions(id), status INTEGER NOT NULL);
    CREATE INDEX mods_by_workspace ON mods(workspace_id,id);
    CREATE TABLE mod_versions(id TEXT PRIMARY KEY, mod_id TEXT NOT NULL REFERENCES mods(id), expected_revision INTEGER NOT NULL, owner TEXT NOT NULL, phase INTEGER NOT NULL, busy INTEGER NOT NULL, cancelled INTEGER NOT NULL DEFAULT 0);
    CREATE TABLE mod_payloads(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), publication_id TEXT NOT NULL REFERENCES mod_versions(id), identity TEXT, length INTEGER, digest TEXT);
    CREATE TABLE mod_manifest(version_id TEXT NOT NULL REFERENCES mod_versions(id), path TEXT NOT NULL, payload_id TEXT NOT NULL REFERENCES mod_payloads(id), PRIMARY KEY(version_id,path));
    PRAGMA user_version=4;
    """
