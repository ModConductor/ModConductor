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
        | 8L -> ()
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

        beforeCommit ()
        transaction.Commit()

    let migrate connection = migrateAtCommit connection ignore
