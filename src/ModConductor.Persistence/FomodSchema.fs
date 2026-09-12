namespace ModConductor.Persistence

module internal FomodSchema =
    let sql =
        """
        CREATE TABLE installation_destinations(
          installation_id TEXT NOT NULL,entry_index INTEGER NOT NULL,path TEXT NOT NULL,
          PRIMARY KEY(installation_id,path),
          FOREIGN KEY(installation_id,entry_index) REFERENCES installation_files(installation_id,entry_index) ON DELETE CASCADE);
        INSERT INTO installation_destinations SELECT installation_id,entry_index,destination FROM installation_files;
        PRAGMA user_version=18;
        """
