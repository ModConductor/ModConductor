namespace ModConductor.Persistence

module internal OrganizationSchema =
    let sql =
        """
    ALTER TABLE workspaces ADD COLUMN catalogue_revision INTEGER NOT NULL DEFAULT 0;
    CREATE TABLE categories(id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), parent_id TEXT REFERENCES categories(id), label TEXT NOT NULL, missing INTEGER NOT NULL DEFAULT 0);
    CREATE UNIQUE INDEX category_sibling_name ON categories(workspace_id,COALESCE(parent_id,''),label) WHERE missing=0;
    CREATE INDEX category_children ON categories(workspace_id,parent_id,id);
    CREATE TABLE mod_categories(mod_id TEXT NOT NULL REFERENCES mods(id), category_id TEXT NOT NULL, label TEXT NOT NULL, PRIMARY KEY(mod_id,category_id));
    CREATE INDEX mods_by_category ON mod_categories(category_id,mod_id);
    INSERT INTO categories(id,workspace_id,label)
      SELECT lower(hex(randomblob(4)))||'-'||lower(hex(randomblob(2)))||'-'||lower(hex(randomblob(2)))||'-'||lower(hex(randomblob(2)))||'-'||lower(hex(randomblob(6))),workspace_id,category FROM mods WHERE category<>'' GROUP BY workspace_id,category;
    INSERT INTO mod_categories(mod_id,category_id,label)
      SELECT m.id,c.id,c.label FROM mods m JOIN categories c ON c.workspace_id=m.workspace_id AND c.label=m.category WHERE m.category<>'';
    ALTER TABLE mods DROP COLUMN category;
    CREATE TRIGGER mod_catalogue_insert AFTER INSERT ON mods BEGIN UPDATE workspaces SET catalogue_revision=catalogue_revision+1 WHERE id=NEW.workspace_id; END;
    CREATE TRIGGER mod_catalogue_update AFTER UPDATE ON mods BEGIN UPDATE workspaces SET catalogue_revision=catalogue_revision+1 WHERE id=NEW.workspace_id; END;
    PRAGMA user_version=6;
    """
