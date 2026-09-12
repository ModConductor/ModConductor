namespace ModConductor.Persistence

module internal MaintenanceSchema =
    let sql =
        """
        ALTER TABLE archive_installations ADD COLUMN target_revision INTEGER;
        ALTER TABLE archive_installations ADD COLUMN previous_version TEXT;
        ALTER TABLE installation_files ADD COLUMN reused_payload TEXT;
        CREATE TABLE installation_reuse(installation_id TEXT NOT NULL REFERENCES archive_installations(id),path TEXT NOT NULL,payload_id TEXT NOT NULL REFERENCES mod_payloads(id),PRIMARY KEY(installation_id,path));
        CREATE TABLE mod_deletions(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL UNIQUE,name TEXT NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,problem TEXT);
        CREATE TABLE mod_deletion_targets(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),mod_id TEXT NOT NULL UNIQUE,PRIMARY KEY(deletion_id,mod_id));
        CREATE TABLE mod_deletion_effects(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),sequence INTEGER NOT NULL,kind INTEGER NOT NULL,root TEXT NOT NULL,root_identity TEXT NOT NULL,path TEXT NOT NULL,identity TEXT,label TEXT NOT NULL,bytes INTEGER,PRIMARY KEY(deletion_id,sequence));
        CREATE TABLE mod_deletion_artifacts(deletion_id TEXT NOT NULL REFERENCES mod_deletions(id),artifact_id TEXT NOT NULL UNIQUE,PRIMARY KEY(deletion_id,artifact_id));
        ALTER TABLE deployment_generations ADD COLUMN unavailable TEXT;
        PRAGMA user_version=17;
        """
