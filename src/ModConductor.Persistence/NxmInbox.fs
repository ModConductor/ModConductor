namespace ModConductor.Persistence

open System
open ModConductor.Nexus

type internal NxmInbox(database: StateDatabase) =
    let connection = database.Connection

    let read transaction predicate parameters =
        use command =
            Sqlite.command
                connection
                transaction
                ("SELECT r.id,r.game,r.mod_id,r.file_id,r.keyed FROM nexus_requests r WHERE r.pending=1 AND "
                 + predicate)
                parameters

        use reader = command.ExecuteReader()

        [ while reader.Read() do
              yield
                  { Id = Guid.Parse(reader.GetString 0)
                    File =
                      { Game = reader.GetString 1
                        ModId = reader.GetInt64 2
                        FileId = reader.GetInt64 3
                        Keyed = reader.GetBoolean 4 }
                    Deliveries = [] } ]

    let run action =
        database.EnqueueInternal(action).GetAwaiter().GetResult()

    interface INxmInbox with
        member _.Accept(id, file) =
            try
                run (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)
                    let delivery = [ "$id", box (string id) ]

                    let known =
                        Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM nexus_request_deliveries WHERE id=$id"
                            delivery > 0L

                    let existing =
                        if known then
                            read
                                transaction
                                "r.id=(SELECT request_id FROM nexus_request_deliveries WHERE id=$id)"
                                delivery
                        else
                            read
                                transaction
                                "r.game=$game AND r.mod_id=$mod AND r.file_id=$file"
                                [ "$game", box file.Game
                                  "$mod", box file.ModId
                                  "$file", box file.FileId ]

                    let result =
                        match existing with
                        | request :: _ -> Ok(Some request)
                        | [] when known -> Ok None
                        | [] when
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM nexus_requests WHERE pending=1"
                                []
                            >= 16L
                            ->
                            Error()
                        | [] ->
                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO nexus_requests(id,game,mod_id,file_id,keyed,pending) VALUES($id,$game,$mod,$file,$keyed,1)"
                                [ "$id", box (string id)
                                  "$game", box file.Game
                                  "$mod", box file.ModId
                                  "$file", box file.FileId
                                  "$keyed", box file.Keyed ]

                            Ok(
                                Some
                                    { Id = id
                                      File = file
                                      Deliveries = [] }
                            )

                    match result with
                    | Ok(Some request) when not known ->
                        Sqlite.execute
                            connection
                            transaction
                            "INSERT INTO nexus_request_deliveries(id,request_id) VALUES($id,$request)"
                            [ "$id", box (string id); "$request", box (string request.Id) ]

                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE nexus_requests SET keyed=$keyed WHERE id=$request"
                            [ "$keyed", box file.Keyed; "$request", box (string request.Id) ]
                    | _ -> ()

                    transaction.Commit()

                    result
                    |> Result.map (
                        Option.map (fun request ->
                            { request with
                                File = if known then request.File else file })
                    ))
            with :? Microsoft.Data.Sqlite.SqliteException ->
                Error()

        member _.Read id =
            run (fun () ->
                read
                    null
                    "r.id=(SELECT request_id FROM nexus_request_deliveries WHERE id=$id)"
                    [ "$id", box (string id) ]
                |> List.tryHead)

        member _.Handled id =
            run (fun () ->
                Sqlite.number
                    connection
                    null
                    "SELECT count(*) FROM nexus_request_deliveries d JOIN nexus_requests r ON r.id=d.request_id WHERE d.id=$id AND r.pending=0"
                    [ "$id", box (string id) ] > 0L)

        member _.Pending() =
            run (fun () ->
                read null "1=1 ORDER BY r.rowid" []
                |> List.map (fun request ->
                    use query =
                        Sqlite.command
                            connection
                            null
                            "SELECT id FROM nexus_request_deliveries WHERE request_id=$id"
                            [ "$id", box (string request.Id) ]

                    use reader = query.ExecuteReader()

                    { request with
                        Deliveries =
                            [ while reader.Read() do
                                  yield Guid.Parse(reader.GetString 0) ] }))

        member _.Dismiss id =
            run (fun () ->
                Sqlite.execute
                    connection
                    null
                    "UPDATE nexus_requests SET pending=0 WHERE id=(SELECT request_id FROM nexus_request_deliveries WHERE id=$id)"
                    [ "$id", box (string id) ])
