namespace ModConductor.Persistence

module internal NexusMetadataSchema =
    let sql =
        """
    ALTER TABLE artifact_downloads ADD COLUMN nexus_version TEXT;
    CREATE TABLE mod_nexus_links(mod_id TEXT PRIMARY KEY REFERENCES mods(id) ON DELETE CASCADE,revision INTEGER NOT NULL DEFAULT 0,game TEXT,nexus_mod INTEGER,name TEXT,summary TEXT,version TEXT,author TEXT,uploader TEXT,category_id INTEGER,category_label TEXT,modified INTEGER,available INTEGER,allows_rating INTEGER,checked INTEGER,checked_owner TEXT,problem TEXT,mapped_provider INTEGER,mapped_category TEXT);
    CREATE TABLE mod_nexus_files(mod_id TEXT NOT NULL REFERENCES mod_nexus_links(mod_id) ON DELETE CASCADE,file_id INTEGER NOT NULL,name TEXT NOT NULL,version TEXT NOT NULL,category TEXT NOT NULL,description TEXT NOT NULL,bytes INTEGER,category_id INTEGER NOT NULL,uploaded INTEGER,PRIMARY KEY(mod_id,file_id));
    CREATE TABLE mod_nexus_updates(mod_id TEXT NOT NULL REFERENCES mod_nexus_links(mod_id) ON DELETE CASCADE,previous INTEGER NOT NULL,next INTEGER NOT NULL,PRIMARY KEY(mod_id,previous,next));
    CREATE TABLE version_nexus_origins(version_id TEXT NOT NULL REFERENCES mod_versions(id) ON DELETE CASCADE,manual INTEGER NOT NULL,game TEXT NOT NULL,nexus_mod INTEGER NOT NULL,file_id INTEGER NOT NULL,version TEXT NOT NULL,PRIMARY KEY(version_id,manual));
    PRAGMA user_version=20;
    """
