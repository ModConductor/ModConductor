namespace ModConductor.Persistence

open System
open Microsoft.Data.Sqlite
open ModConductor.DeploymentRecovery

module internal DeploymentRows =
    let private identifier (value: Guid) = box (string value)

    let private optional value =
        value |> Option.map identifier |> Option.defaultValue (box DBNull.Value)

    let private bytes (reader: SqliteDataReader) offset =
        if reader.GetInt64(offset + 2) > int64 DeploymentEncoding.limit then
            DeploymentEncoding.corrupt ()

        let body = reader.GetFieldValue<byte[]>(offset)

        if DeploymentEncoding.hash body <> reader.GetString(offset + 1) then
            DeploymentEncoding.corrupt ()

        body

    let context connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT body,digest,length(body),revision,pending FROM deployment_contexts WHERE id=$id"
                [ "$id", identifier id ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let value = DeploymentEncoding.contextFrom (bytes reader 0)

            let pending =
                if reader.IsDBNull 4 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 4))

            if
                value.Id <> id
                || value.Revision <> reader.GetInt64 3
                || value.Pending <> pending
            then
                DeploymentEncoding.corrupt ()

            Some value

    let generation connection transaction contextId id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT body,digest,length(body) FROM deployment_generations WHERE context_id=$context AND id=$id"
                [ "$context", identifier contextId; "$id", identifier id ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let value = DeploymentEncoding.generationFrom (bytes reader 0)

            if value.Id <> id then
                DeploymentEncoding.corrupt ()

            Some value

    let receipt connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT body,digest,length(body),revision,phase,owner,busy,abandoned,context_id,previous_id,proposed_id FROM deployment_receipts WHERE id=$id"
                [ "$id", identifier id ]

        use reader = command.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            let value = DeploymentEncoding.receiptFrom (bytes reader 0)

            let previous =
                if reader.IsDBNull 9 then
                    None
                else
                    Some(Guid.Parse(reader.GetString 9))

            if
                value.Id <> id
                || value.Revision <> reader.GetInt64 3
                || DeploymentEncoding.phase value.Phase <> reader.GetInt32 4
                || value.Context.Id <> Guid.Parse(reader.GetString 8)
                || value.Previous <> previous
                || value.Proposed <> Guid.Parse(reader.GetString 10)
            then
                DeploymentEncoding.corrupt ()

            Some(value, reader.GetString 5, reader.GetBoolean 6, reader.GetBoolean 7)

    let checkOwnership connection transaction (value: Context) workspace =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT body,digest,length(body) FROM deployment_contexts WHERE id<>$id"
                [ "$id", identifier value.Id ]

        use reader = command.ExecuteReader()

        while reader.Read() do
            let existing = DeploymentEncoding.contextFrom (bytes reader 0)

            let sameWorkspace =
                workspace
                |> Option.exists (fun id ->
                    existing.Roots.Length = 1
                    && value.Roots.Length = 1
                    && existing.Roots.Head.Root.Id = id
                    && value.Roots.Head.Root.Id = id)

            let inactive =
                existing.Pending.IsNone
                && existing.Links.IsEmpty
                && existing.Directories.IsEmpty

            if sameWorkspace && not inactive then
                raise (RecoveryException RecoveryError.Busy)

            if
                Preparation.overlappingRoots existing.Roots value.Roots
                && not (sameWorkspace && inactive)
            then
                raise (
                    RecoveryException(
                        RecoveryError.Mismatch "Another deployment context owns this target."
                    )
                )

    let writeContext connection transaction (value: Context) =
        let body = DeploymentEncoding.contextBytes value

        Sqlite.execute
            connection
            transaction
            "INSERT INTO deployment_contexts VALUES($id,$revision,$pending,$body,$digest) ON CONFLICT(id) DO UPDATE SET revision=$revision,pending=$pending,body=$body,digest=$digest"
            [ "$id", identifier value.Id
              "$revision", box value.Revision
              "$pending", optional value.Pending
              "$body", box body
              "$digest", box (DeploymentEncoding.hash body) ]

    let writeGeneration connection transaction contextId (value: Generation) =
        let body = DeploymentEncoding.generationBytes value

        match generation connection transaction contextId value.Id with
        | Some existing when existing <> value ->
            raise (
                RecoveryException(
                    RecoveryError.Mismatch
                        "A generation ID already names different immutable inputs."
                )
            )
        | Some _ -> ()
        | None ->
            Sqlite.execute
                connection
                transaction
                "INSERT INTO deployment_generations VALUES($context,$id,$body,$digest)"
                [ "$context", identifier contextId
                  "$id", identifier value.Id
                  "$body", box body
                  "$digest", box (DeploymentEncoding.hash body) ]

    let insert connection transaction owner (value: Receipt) =
        let body = DeploymentEncoding.receiptBytes value

        Sqlite.execute
            connection
            transaction
            "INSERT INTO deployment_receipts(id,context_id,previous_id,proposed_id,revision,phase,owner,busy,abandoned,body,digest) VALUES($id,$context,$previous,$proposed,$revision,$phase,$owner,0,0,$body,$digest)"
            [ "$id", identifier value.Id
              "$context", identifier value.Context.Id
              "$previous", optional value.Previous
              "$proposed", identifier value.Proposed
              "$revision", box value.Revision
              "$phase", box (DeploymentEncoding.phase value.Phase)
              "$owner", box owner
              "$body", box body
              "$digest", box (DeploymentEncoding.hash body) ]

    let update connection transaction (value: Receipt) =
        let next =
            { value with
                Revision = value.Revision + 1L }

        let body = DeploymentEncoding.receiptBytes next

        Sqlite.execute
            connection
            transaction
            "UPDATE deployment_receipts SET revision=$revision,phase=$phase,body=$body,digest=$digest WHERE id=$id"
            [ "$id", identifier value.Id
              "$revision", box next.Revision
              "$phase", box (DeploymentEncoding.phase next.Phase)
              "$body", box body
              "$digest", box (DeploymentEncoding.hash body) ]

        next

    let pending connection after =
        use command =
            Sqlite.command
                connection
                null
                "SELECT sequence,body,digest,length(body) FROM deployment_receipts WHERE phase NOT IN (2,3) AND sequence>$after ORDER BY sequence LIMIT 32"
                [ "$after", box after ]

        use reader = command.ExecuteReader()
        let mutable size = 0
        let mutable reading = true

        [ while reading && reader.Read() do
              let length = reader.GetInt64 3

              if length > int64 DeploymentEncoding.limit then
                  DeploymentEncoding.corrupt ()

              if int64 size + length > int64 DeploymentEncoding.limit then
                  reading <- false
              else
                  let body = bytes reader 1
                  size <- size + body.Length
                  yield reader.GetInt64 0, DeploymentEncoding.receiptFrom body ]
