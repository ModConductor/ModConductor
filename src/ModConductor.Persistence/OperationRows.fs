namespace ModConductor.Persistence

open System
open System.IO
open Microsoft.Data.Sqlite
open ModConductor.Operations

module internal OperationRows =
    let columns =
        "id,expected_revision,count,phase,progress,architecture,native_aot,sqlite_version,result_revision"

    let phase =
        function
        | Running -> 1
        | Completed -> 2
        | Cancelled -> 3
        | Interrupted -> 4
        | Stale -> 5

    let read (reader: SqliteDataReader) =
        let phase =
            match reader.GetInt32 3 with
            | 1 -> Running
            | 2 -> Completed
            | 3 -> Cancelled
            | 4 -> Interrupted
            | 5 -> Stale
            | _ -> raise (InvalidDataException("Unknown operation state."))

        { Request =
            { Id = reader.GetString 0
              ExpectedRevision = reader.GetInt64 1
              Count = reader.GetInt32 2 }
          Phase = phase
          Progress = reader.GetInt32 4
          Result =
            if reader.IsDBNull 5 then
                None
            else
                Some
                    { Architecture = reader.GetString 5
                      NativeAot = reader.GetBoolean 6
                      SqliteVersion = reader.GetString 7 }
          ResultRevision = reader.GetInt64 8 }

    let parameters (snapshot: Snapshot) =
        let architecture, nativeAot, sqliteVersion =
            match snapshot.Result with
            | Some result -> box result.Architecture, box result.NativeAot, box result.SqliteVersion
            | None -> box DBNull.Value, box DBNull.Value, box DBNull.Value

        [ "$id", box snapshot.Request.Id
          "$expected", box snapshot.Request.ExpectedRevision
          "$count", box snapshot.Request.Count
          "$phase", box (phase snapshot.Phase)
          "$progress", box snapshot.Progress
          "$architecture", architecture
          "$native", nativeAot
          "$sqlite", sqliteVersion
          "$resultRevision", box snapshot.ResultRevision ]

    let list connection transaction sql parameters =
        use statement = Sqlite.command connection transaction sql parameters
        use reader = statement.ExecuteReader()

        [ while reader.Read() do
              yield read reader ]
