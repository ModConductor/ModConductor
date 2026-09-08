namespace ModConductor.Persistence

module internal OutputSchema =
    let sql =
        """
    CREATE TABLE output_contexts(workspace_id TEXT NOT NULL REFERENCES workspaces(id),id TEXT NOT NULL,game_path TEXT NOT NULL,revision INTEGER NOT NULL,PRIMARY KEY(workspace_id,id));
    CREATE TABLE output_locations(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL,context_id TEXT NOT NULL,name TEXT NOT NULL,purpose INTEGER NOT NULL CHECK(purpose IN(0,1)),target TEXT,revision INTEGER NOT NULL,enabled INTEGER NOT NULL CHECK(enabled IN(0,1)),initialized INTEGER NOT NULL CHECK(initialized IN(0,1)),root_name TEXT NOT NULL,root_identity TEXT,FOREIGN KEY(workspace_id,context_id) REFERENCES output_contexts(workspace_id,id));
    CREATE INDEX output_locations_context ON output_locations(workspace_id,context_id,id);
    CREATE TABLE output_observations(location_id TEXT NOT NULL REFERENCES output_locations(id),path TEXT NOT NULL,sha256 TEXT NOT NULL,kept INTEGER NOT NULL CHECK(kept IN(0,1)),PRIMARY KEY(location_id,path));
    CREATE TABLE output_actions(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL,context_id TEXT NOT NULL,owner TEXT NOT NULL,busy INTEGER NOT NULL,complete INTEGER NOT NULL,version_id TEXT,body BLOB NOT NULL,FOREIGN KEY(workspace_id,context_id) REFERENCES output_contexts(workspace_id,id));
    CREATE INDEX output_actions_pending ON output_actions(workspace_id,context_id,complete,id);
    CREATE TABLE mod_version_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),output_action TEXT NOT NULL,source_version TEXT,version_label TEXT NOT NULL);
    PRAGMA user_version=11;
    """
