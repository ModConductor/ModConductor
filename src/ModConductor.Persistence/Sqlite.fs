namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite

module internal Sqlite =
    let command (connection: SqliteConnection) transaction sql (parameters: (string * obj) list) =
        let command = connection.CreateCommand()
        command.Transaction <- transaction
        command.CommandText <- sql

        for name, value in parameters do
            command.Parameters.AddWithValue(name, value) |> ignore

        command

    let execute connection transaction sql parameters =
        use statement = command connection transaction sql parameters
        statement.ExecuteNonQuery() |> ignore

    let number connection transaction sql parameters =
        use statement = command connection transaction sql parameters
        statement.ExecuteScalar() :?> int64

    let internal operationSchema =
        """
    CREATE TABLE operation_state (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL, cursor INTEGER NOT NULL);
    INSERT INTO operation_state VALUES(1,0,0);
    CREATE TABLE operations ( id TEXT PRIMARY KEY, owner TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 1 AND 5), progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL, last_cursor INTEGER NOT NULL);
    CREATE TABLE operation_events ( cursor INTEGER PRIMARY KEY, id TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL, progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL);
    PRAGMA user_version=1;
    """

    let private workspaceSchema =
        """
    CREATE TABLE workspace_roots (id TEXT PRIMARY KEY, path TEXT NOT NULL, device_kind INTEGER NOT NULL, device TEXT NOT NULL, file_low TEXT NOT NULL, file_high TEXT NOT NULL, revision INTEGER NOT NULL);
    CREATE UNIQUE INDEX workspace_root_identity ON workspace_roots(device_kind,device,file_low,file_high);
    CREATE TABLE root_creation_receipts (id TEXT PRIMARY KEY REFERENCES workspace_roots(id), owner TEXT NOT NULL, marker TEXT NOT NULL, revision INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 1 AND 4), busy INTEGER NOT NULL, abandoned INTEGER NOT NULL, marker_device_kind INTEGER, marker_device TEXT, marker_low TEXT, marker_high TEXT, detail TEXT NOT NULL);
    PRAGMA user_version=2;
    """

    let private profileSchema =
        """
    CREATE TABLE workspaces (id TEXT PRIMARY KEY REFERENCES workspace_roots(id), name TEXT NOT NULL, revision INTEGER NOT NULL, selected_profile TEXT);
    CREATE TABLE profiles (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL REFERENCES workspaces(id), name TEXT NOT NULL);
    CREATE INDEX profiles_by_workspace ON profiles(workspace_id,id);
    PRAGMA user_version=3;
    """

    let migrateAtCommit (connection: SqliteConnection) beforeCommit =
        execute
            connection
            null
            "PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA foreign_keys=ON;"
            []

        use transaction = connection.BeginTransaction(deferred = false)

        match number connection transaction "PRAGMA user_version" [] with
        | 0L ->
            execute connection transaction operationSchema []
            execute connection transaction workspaceSchema []
            execute connection transaction profileSchema []
        | 1L ->
            execute connection transaction workspaceSchema []
            execute connection transaction profileSchema []
        | 2L -> execute connection transaction profileSchema []
        | 3L
        | 4L
        | 5L
        | 6L
        | 7L
        | 8L
        | 9L
        | 10L
        | 11L
        | 12L
        | 13L
        | 14L
        | 15L
        | 16L
        | 17L
        | 18L
        | 19L
        | 20L
        | 21L
        | 22L
        | 23L
        | 24L
        | 25L
        | 26L
        | 27L
        | 28L
        | 29L
        | 30L
        | 31L
        | 32L
        | 33L
        | 34L -> ()
        | _ -> raise (InvalidOperationException("The state database uses an unsupported version."))

        if number connection transaction "PRAGMA user_version" [] = 3L then
            execute connection transaction LibrarySchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 4L then
            execute connection transaction SelectionSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 5L then
            execute connection transaction OrganizationSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 6L then
            execute
                connection
                transaction
                "CREATE TABLE game_contexts(workspace_id TEXT PRIMARY KEY REFERENCES workspaces(id),id TEXT NOT NULL,path TEXT NOT NULL,revision INTEGER NOT NULL,evidence TEXT NOT NULL,checked_owner TEXT NOT NULL,failure TEXT); PRAGMA user_version=7;"
                []


        if number connection transaction "PRAGMA user_version" [] = 7L then
            execute
                connection
                transaction
                "ALTER TABLE game_contexts ADD COLUMN proton_selection TEXT; PRAGMA user_version=8;"
                []

        if number connection transaction "PRAGMA user_version" [] = 8L then
            execute
                connection
                transaction
                """
                CREATE TABLE file_visibility_state(workspace_id TEXT PRIMARY KEY REFERENCES workspaces(id),revision INTEGER NOT NULL);
                CREATE TABLE hidden_mod_files(workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL REFERENCES mods(id),version_id TEXT NOT NULL REFERENCES mod_versions(id),path TEXT NOT NULL,hidden INTEGER NOT NULL CHECK(hidden IN (0,1)),PRIMARY KEY(workspace_id,mod_id,version_id,path));
                CREATE TABLE file_visibility_changes(id INTEGER PRIMARY KEY,workspace_id TEXT NOT NULL REFERENCES workspaces(id),mod_id TEXT NOT NULL,version_id TEXT NOT NULL,path TEXT NOT NULL,hidden INTEGER NOT NULL,before_hidden INTEGER NOT NULL,profile_id TEXT NOT NULL,before_fingerprint TEXT NOT NULL,after_fingerprint TEXT NOT NULL,recorded_at TEXT NOT NULL);
                CREATE INDEX file_visibility_history ON file_visibility_changes(workspace_id,mod_id,version_id,path,id);
                PRAGMA user_version=9;
                """
                []

        if number connection transaction "PRAGMA user_version" [] = 9L then
            execute connection transaction DeploymentSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 10L then
            execute connection transaction OutputSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 11L then
            execute connection transaction ExecutableSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 12L then
            execute connection transaction ProfileDataSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 13L then
            execute connection transaction ArtifactSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 14L then
            execute connection transaction DownloadSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 15L then
            execute connection transaction InstallationSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 16L then
            execute connection transaction MaintenanceSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 17L then
            execute connection transaction FomodSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 18L then
            execute connection transaction BundleSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 19L then
            execute connection transaction NexusMetadataSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 20L then
            execute connection transaction EditSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 21L then
            execute
                connection
                transaction
                "ALTER TABLE operations ADD COLUMN migration_staged_path TEXT; ALTER TABLE operations ADD COLUMN migration_final_path TEXT; PRAGMA user_version=22;"
                []

        if number connection transaction "PRAGMA user_version" [] = 22L then
            execute connection transaction SkseSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 23L then
            execute connection transaction SkseSchema.correction []

        if number connection transaction "PRAGMA user_version" [] = 24L then
            execute connection transaction EnbSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 25L then
            execute connection transaction EnbSchema.correction []

        if number connection transaction "PRAGMA user_version" [] = 26L then
            execute connection transaction EnbSchema.durableConfiguration []

        if number connection transaction "PRAGMA user_version" [] = 27L then
            execute connection transaction FnisSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 28L then
            execute connection transaction FnisSchema.execution []

        if number connection transaction "PRAGMA user_version" [] = 29L then
            execute connection transaction FnisSchema.executionLogs []

        if number connection transaction "PRAGMA user_version" [] = 30L then
            execute connection transaction SkyrimSetupSchema.sql []

        if number connection transaction "PRAGMA user_version" [] = 31L then
            execute connection transaction SkyrimSetupSchema.correction []

        if number connection transaction "PRAGMA user_version" [] = 32L then
            execute connection transaction SkyrimSetupSchema.cancellationAndActions []

        if number connection transaction "PRAGMA user_version" [] = 33L then
            execute
                connection
                transaction
                """
                DELETE FROM skse_replacement_intents;
                DELETE FROM fnis_publication_intents;
                DELETE FROM enb_selection_intents;
                DELETE FROM enb_configuration_operations;

                DELETE FROM mod_version_origins;
                DELETE FROM output_observations;
                DELETE FROM output_actions;
                DELETE FROM output_locations;
                DELETE FROM output_contexts;

                DELETE FROM deployment_receipts;
                DELETE FROM deployment_generations;
                DELETE FROM deployment_contexts;

                DROP TABLE game_contexts;
                CREATE TABLE game_contexts(
                    profile_id TEXT PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
                    workspace_id TEXT NOT NULL REFERENCES workspaces(id),
                    game_id TEXT NOT NULL,
                    id TEXT NOT NULL,
                    path TEXT NOT NULL,
                    revision INTEGER NOT NULL,
                    evidence TEXT NOT NULL,
                    checked_owner TEXT NOT NULL,
                    failure TEXT,
                    proton_selection TEXT
                );
                CREATE INDEX game_contexts_by_workspace ON game_contexts(workspace_id,profile_id);
                PRAGMA user_version=34;
                """
                []

        beforeCommit ()
        transaction.Commit()

    let migrate connection = migrateAtCommit connection ignore
