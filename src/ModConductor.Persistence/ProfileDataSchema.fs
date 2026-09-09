namespace ModConductor.Persistence

module internal ProfileDataSchema =
    let sql =
        """
CREATE TABLE profile_data_contexts(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),documents_identity TEXT NOT NULL,revision INTEGER NOT NULL,pending TEXT,body BLOB NOT NULL);
CREATE INDEX profile_data_contexts_workspace ON profile_data_contexts(workspace_id,id);
CREATE INDEX profile_data_contexts_documents ON profile_data_contexts(documents_identity);
CREATE TABLE profile_data_profiles(context_id TEXT NOT NULL REFERENCES profile_data_contexts(id),profile_id TEXT NOT NULL REFERENCES profiles(id),body BLOB NOT NULL,PRIMARY KEY(context_id,profile_id));
CREATE TABLE profile_data_actions(id TEXT PRIMARY KEY,context_id TEXT NOT NULL REFERENCES profile_data_contexts(id),owner TEXT NOT NULL,busy INTEGER NOT NULL,complete INTEGER NOT NULL,body BLOB NOT NULL);
CREATE INDEX profile_data_actions_context ON profile_data_actions(context_id,complete,id);
PRAGMA user_version=13;
"""
