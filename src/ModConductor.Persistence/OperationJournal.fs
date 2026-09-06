namespace ModConductor.Persistence

open Microsoft.Data.Sqlite
open ModConductor.Operations

module internal OperationJournal =
    let state connection transaction =
        use statement =
            Sqlite.command
                connection
                transaction
                "SELECT revision,cursor FROM operation_state WHERE id=1"
                []

        use reader = statement.ExecuteReader()
        reader.Read() |> ignore
        reader.GetInt64 0, reader.GetInt64 1

    let find connection transaction id =
        OperationRows.list
            connection
            transaction
            ("SELECT " + OperationRows.columns + " FROM operations WHERE id=$id")
            [ "$id", box id ]
        |> List.tryHead

    let save connection transaction snapshot =
        Sqlite.execute
            connection
            transaction
            "UPDATE operation_state SET cursor=cursor+1 WHERE id=1"
            []

        let _, cursor = state connection transaction
        let parameters = OperationRows.parameters snapshot

        Sqlite.execute
            connection
            transaction
            "UPDATE operations SET phase=$phase,progress=$progress,architecture=$architecture,native_aot=$native, sqlite_version=$sqlite,result_revision=$resultRevision,last_cursor=$cursor WHERE id=$id"
            (("$cursor", box cursor) :: parameters)

        Sqlite.execute
            connection
            transaction
            "INSERT INTO operation_events(cursor,id,expected_revision,count,phase,progress,architecture,native_aot,sqlite_version,result_revision) VALUES($cursor,$id,$expected,$count,$phase,$progress,$architecture,$native,$sqlite,$resultRevision)"
            (("$cursor", box cursor) :: parameters)

        Sqlite.execute
            connection
            transaction
            "DELETE FROM operation_events WHERE cursor <= $oldest"
            [ "$oldest", box (cursor - 128L) ]

    let interruptOwner (connection: SqliteConnection) owner =
        use transaction = connection.BeginTransaction(deferred = false)

        let pending =
            OperationRows.list
                connection
                transaction
                ("SELECT "
                 + OperationRows.columns
                 + " FROM operations WHERE owner=$owner AND phase=1")
                [ "$owner", box owner ]

        for snapshot in pending do
            save connection transaction { snapshot with Phase = Interrupted }

        transaction.Commit()
