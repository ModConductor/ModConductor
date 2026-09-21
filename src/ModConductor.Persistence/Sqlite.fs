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

    let private incompatible () =
        raise (
            InvalidOperationException(
                "The state database is incompatible with this pre-release build. Delete the Mod Conductor state directory to reset it."
            )
        )

    let initializeAtCommit (connection: SqliteConnection) beforeCommit =
        execute
            connection
            null
            "PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA foreign_keys=ON;"
            []

        use transaction = connection.BeginTransaction(deferred = false)
        let version = number connection transaction "PRAGMA user_version" []
        let application = number connection transaction "PRAGMA application_id" []

        let objects =
            number
                connection
                transaction
                "SELECT count(*) FROM sqlite_schema WHERE name NOT LIKE 'sqlite_%'"
                []

        match version, application, objects with
        | 0L, 0L, 0L -> execute connection transaction Schema.sql []
        | Schema.CurrentVersion, Schema.ApplicationId, _ -> ()
        | _ -> incompatible ()

        beforeCommit ()
        transaction.Commit()

    let initialize connection = initializeAtCommit connection ignore
