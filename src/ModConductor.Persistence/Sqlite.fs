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

    let private schema =
        """
    CREATE TABLE operation_state (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL, cursor INTEGER NOT NULL);
    INSERT INTO operation_state VALUES(1,0,0);
    CREATE TABLE operations ( id TEXT PRIMARY KEY, owner TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL CHECK(phase BETWEEN 1 AND 5), progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL, last_cursor INTEGER NOT NULL);
    CREATE TABLE operation_events ( cursor INTEGER PRIMARY KEY, id TEXT NOT NULL, expected_revision INTEGER NOT NULL, count INTEGER NOT NULL, phase INTEGER NOT NULL, progress INTEGER NOT NULL, architecture TEXT, native_aot INTEGER, sqlite_version TEXT, result_revision INTEGER NOT NULL);
    PRAGMA user_version=1;
    """

    let migrate (connection: SqliteConnection) =
        execute connection null "PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL;" []
        use transaction = connection.BeginTransaction(deferred = false)

        match number connection transaction "PRAGMA user_version" [] with
        | 0L -> execute connection transaction schema []
        | 1L -> ()
        | _ -> raise (InvalidOperationException("The state database uses an unsupported version."))

        transaction.Commit()
