namespace ModConductor.Persistence

module internal BundleSchema =
    let sql =
        """
    CREATE TABLE bundle_work(id TEXT PRIMARY KEY,workspace_id TEXT NOT NULL UNIQUE REFERENCES workspaces(id),artifact_id TEXT NOT NULL REFERENCES artifacts(id),archive_name TEXT NOT NULL,parent_digest TEXT NOT NULL,revision INTEGER NOT NULL DEFAULT 0,owner TEXT NOT NULL,busy INTEGER NOT NULL DEFAULT 0,problem TEXT);
    CREATE TABLE bundle_sources(id TEXT PRIMARY KEY,bundle_id TEXT NOT NULL REFERENCES bundle_work(id),parent_id TEXT REFERENCES bundle_sources(id),entry_index INTEGER NOT NULL,path TEXT NOT NULL,expected_length INTEGER NOT NULL,identity TEXT,length INTEGER,digest TEXT,leaf_entries INTEGER NOT NULL DEFAULT 0,leaf_bytes INTEGER NOT NULL DEFAULT 0,problem TEXT,UNIQUE(bundle_id,parent_id,entry_index));
    CREATE TABLE bundle_mods(id TEXT PRIMARY KEY,bundle_id TEXT NOT NULL REFERENCES bundle_work(id),source_id TEXT NOT NULL UNIQUE REFERENCES bundle_sources(id),mod_id TEXT NOT NULL UNIQUE,name TEXT NOT NULL,position INTEGER NOT NULL,attempt TEXT REFERENCES archive_installations(id));
    CREATE TABLE bundle_version_origins(version_id TEXT PRIMARY KEY REFERENCES mod_versions(id),parent_digest TEXT NOT NULL,path_chain TEXT NOT NULL,digest_chain TEXT NOT NULL);
    PRAGMA user_version=19;
    """
