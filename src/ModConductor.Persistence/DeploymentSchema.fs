namespace ModConductor.Persistence

module internal DeploymentSchema =
    let sql =
        """
    CREATE TABLE deployment_contexts(id TEXT PRIMARY KEY, revision INTEGER NOT NULL, pending TEXT, body BLOB NOT NULL, digest TEXT NOT NULL);
    CREATE TABLE deployment_generations(context_id TEXT NOT NULL REFERENCES deployment_contexts(id), id TEXT NOT NULL, body BLOB NOT NULL, digest TEXT NOT NULL, PRIMARY KEY(context_id,id));
    CREATE TABLE deployment_receipts(sequence INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE, context_id TEXT NOT NULL REFERENCES deployment_contexts(id), previous_id TEXT, proposed_id TEXT NOT NULL, revision INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 0 AND 4), owner TEXT NOT NULL, busy INTEGER NOT NULL, abandoned INTEGER NOT NULL, body BLOB NOT NULL, digest TEXT NOT NULL, FOREIGN KEY(context_id,previous_id) REFERENCES deployment_generations(context_id,id), FOREIGN KEY(context_id,proposed_id) REFERENCES deployment_generations(context_id,id));
    CREATE INDEX deployment_pending ON deployment_receipts(phase,sequence);
    PRAGMA user_version=10;
    """
