namespace ModConductor.Persistence

module internal InstallationSchema =
    let sql =
        """
        CREATE TABLE archive_installations(
          id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),artifact_id TEXT NOT NULL,
          owner TEXT NOT NULL,state INTEGER NOT NULL,busy INTEGER NOT NULL,cancelled INTEGER NOT NULL DEFAULT 0,
          fingerprint TEXT NOT NULL,archive_name TEXT NOT NULL,name TEXT NOT NULL,version_label TEXT NOT NULL,
          source_digest TEXT NOT NULL,source_revision INTEGER NOT NULL,root TEXT NOT NULL,
          mod_id TEXT NOT NULL,version_id TEXT NOT NULL,total_bytes INTEGER NOT NULL,total_files INTEGER NOT NULL,problem TEXT);
        CREATE INDEX archive_installations_workspace ON archive_installations(workspace_id,state);
        CREATE TABLE installation_files(
          installation_id TEXT NOT NULL REFERENCES archive_installations(id),entry_index INTEGER NOT NULL,
          destination TEXT NOT NULL,payload_id TEXT NOT NULL UNIQUE,identity TEXT,length INTEGER,digest TEXT,
          PRIMARY KEY(installation_id,entry_index));
        CREATE TABLE archive_version_origins(
          version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),artifact_id TEXT NOT NULL REFERENCES artifacts(id));
        ALTER TABLE artifact_links ADD COLUMN installed INTEGER NOT NULL DEFAULT 0;
        PRAGMA user_version=16;
        """
