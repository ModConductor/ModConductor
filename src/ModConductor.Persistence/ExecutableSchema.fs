namespace ModConductor.Persistence

module internal ExecutableSchema =
    let sql =
        """
CREATE TABLE executable_presets(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),revision INTEGER NOT NULL,data TEXT NOT NULL);
CREATE INDEX executable_presets_workspace ON executable_presets(workspace_id,id);
CREATE TABLE executable_runs(sequence INTEGER PRIMARY KEY,id TEXT NOT NULL UNIQUE,workspace_id TEXT NOT NULL REFERENCES workspaces(id),preset_id TEXT NOT NULL,owner TEXT NOT NULL,revision INTEGER NOT NULL,phase INTEGER NOT NULL,data TEXT NOT NULL);
CREATE INDEX executable_runs_preset ON executable_runs(workspace_id,preset_id,sequence);
CREATE INDEX executable_runs_workspace ON executable_runs(workspace_id,sequence);
PRAGMA user_version=12;
"""
