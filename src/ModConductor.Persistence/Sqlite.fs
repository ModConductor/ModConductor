namespace ModConductor.Persistence

open System
open System.Buffers.Binary
open System.IO
open System.Text
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

    let requireCompatible path =
        if File.Exists path then
            let header = Array.zeroCreate<byte> 72

            use stream =
                new FileStream(
                    path,
                    FileMode.Open,
                    FileAccess.Read,
                    FileShare.ReadWrite ||| FileShare.Delete
                )

            try
                stream.ReadExactly header
            with :? EndOfStreamException ->
                incompatible ()

            let sqliteHeader = Encoding.ASCII.GetBytes("SQLite format 3\000")

            if
                not (header.AsSpan(0, sqliteHeader.Length).SequenceEqual sqliteHeader)
                || int64 (BinaryPrimitives.ReadInt32BigEndian(header.AsSpan(60, 4)))
                   <> Schema.CurrentVersion
                || int64 (BinaryPrimitives.ReadInt32BigEndian(header.AsSpan(68, 4)))
                   <> Schema.ApplicationId
            then
                incompatible ()

    let initializeAtCommit (connection: SqliteConnection) beforeCommit =
        execute connection null "PRAGMA foreign_keys=ON;" []

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

        execute connection null "PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL;" []

    let initialize connection = initializeAtCommit connection ignore
