namespace ModConductor.Persistence

module internal ArtifactSchema =
    let sql =
        """
    CREATE TABLE artifacts(
      id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),revision INTEGER NOT NULL,
      original_name TEXT NOT NULL,original_path TEXT NOT NULL,path TEXT NOT NULL,storage INTEGER NOT NULL,
      phase INTEGER NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,
      length INTEGER,sha256 TEXT,source_identity TEXT,stored_identity TEXT,problem TEXT);
    CREATE INDEX artifacts_workspace ON artifacts(workspace_id,id);
    CREATE TABLE artifact_links(
      artifact_id TEXT NOT NULL REFERENCES artifacts(id),mod_id TEXT NOT NULL REFERENCES mods(id),
      version_id TEXT NOT NULL REFERENCES mod_versions(id),mod_name TEXT NOT NULL,version_label TEXT NOT NULL,
      PRIMARY KEY(artifact_id,mod_id,version_id));
    PRAGMA user_version=14;
    """
