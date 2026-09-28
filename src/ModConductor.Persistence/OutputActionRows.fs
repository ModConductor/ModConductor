namespace ModConductor.Persistence

open System
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary

module internal OutputActionRows =
    let private validTargets policy previous files =
        LibraryComposition.targets policy previous files
        |> Result.mapError (fun _ ->
            OutputError.Invalid "The selected output paths conflict under the game filename rules.")

    let find connection transaction id =
        use query =
            Sqlite.command
                connection
                transaction
                "SELECT body,length(body) FROM output_actions WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = query.ExecuteReader()

        if not (reader.Read()) then
            None
        else
            if reader.GetInt64 1 > 16L * 1024L * 1024L then
                raise (
                    System.IO.InvalidDataException "The saved output action exceeds its size limit."
                )

            let value = OutputEncoding.decode (reader.GetFieldValue<byte array> 0)

            if value.Id <> id then
                raise (System.IO.InvalidDataException "The output action identity is invalid.")

            reader.Close()

            let published =
                value.Result.VersionId
                |> Option.bind (fun version -> PublicationRows.find connection transaction version)
                |> Option.exists (fun receipt -> receipt.Phase = PublicationPhase.Complete)

            Some
                { value with
                    Result =
                        { value.Result with
                            Published = published } }

    let save connection transaction (record: OutputActionRecord) =
        OutputEncoding.encode record
        |> Result.map (fun body ->
            Sqlite.execute
                connection
                transaction
                "UPDATE output_actions SET complete=$complete,version_id=$version,body=$body WHERE id=$id"
                [ "$complete", box record.Result.Complete
                  "$version",
                  record.Result.VersionId
                  |> Option.map (string >> box)
                  |> Option.defaultValue (box DBNull.Value)
                  "$body", box body
                  "$id", box (string record.Id) ])

    let destination (record: OutputActionRecord) =
        match record.Action with
        | OutputAction.MoveToMod value
        | OutputAction.SaveCopyToMod value -> Some value
        | OutputAction.Keep
        | OutputAction.Discard -> None

    let composition connection transaction (record: OutputActionRecord) =
        let compose destination =
            let id, expected, label =
                match destination with
                | OutputDestination.ExistingMod(id, expected, label) -> id, expected, label
                | OutputDestination.NewMod(id, _, label) -> id, 0L, label

            match LibraryRows.find connection transaction id with
            | None -> Error OutputError.NotFound
            | Some row when
                row.Entry.WorkspaceId <> record.Scope.WorkspaceId
                || row.Entry.Kind <> ModKind.Regular
                ->
                Error(OutputError.Invalid "Select a regular mod from this workspace.")
            | Some row when row.Entry.Revision <> expected -> Error OutputError.Stale
            | Some row ->
                let input =
                    { ActionId = record.Id
                      SourceVersion = row.Entry.CurrentVersion
                      VersionLabel = label
                      Policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                      Files =
                        record.Files
                        |> List.map (fun value ->
                            { Target = value.File.Path
                              Root = value.Backing.Root
                              RootIdentity = value.Backing.RootIdentity
                              File =
                                { Path = OutputFiles.path value.Backing value.File.Path
                                  Identity = value.File.Identity.Value
                                  Length = value.File.Length
                                  Modified = value.Modified
                                  Sha256 = value.File.Sha256 } })
                      Bytes = []
                      Deleted = [] }

                let previous =
                    input.SourceVersion
                    |> Option.bind (fun version ->
                        LibraryRows.version connection transaction version 0 100001)
                    |> Option.map _.Entries
                    |> Option.defaultValue []

                if previous.Length > 100000 then
                    Error OutputError.LimitExceeded
                else
                    validTargets input.Policy previous input.Files
                    |> Result.map (fun _ -> id, expected, input)

        match destination record with
        | None -> Ok None
        | Some value -> compose value |> Result.map Some

    let private previewNew connection transaction (record: OutputActionRecord) id name label =
        if id = Guid.Empty || LibraryRows.find connection transaction id |> Option.isSome then
            Error(OutputError.Invalid "Use a new mod identity.")
        else
            OutputPolicy.name name
            |> Result.bind (fun _ ->
                if not (OutputPolicy.text 256 label) then
                    Error(OutputError.Invalid "The version label is too long.")
                else
                    let files =
                        record.Files
                        |> List.map (fun value ->
                            { Target = value.File.Path
                              Root = value.Backing.Root
                              RootIdentity = value.Backing.RootIdentity
                              File =
                                { Path = OutputFiles.path value.Backing value.File.Path
                                  Identity = value.File.Identity.Value
                                  Length = value.File.Length
                                  Modified = value.Modified
                                  Sha256 = value.File.Sha256 } })

                    validTargets ModConductor.GameContexts.Skyrim.definition.TargetPolicy [] files
                    |> Result.map (fun (_, selected) -> false, None, selected))

    let private previewExisting connection transaction (record: OutputActionRecord) =
        composition connection transaction record
        |> Result.map (fun value ->
            let id, _, input = value |> Option.get
            let row = LibraryRows.find connection transaction id |> Option.get

            let previous =
                input.SourceVersion
                |> Option.bind (fun version ->
                    LibraryRows.version connection transaction version 0 100001)
                |> Option.map _.Entries
                |> Option.defaultValue []

            row.Entry.SourcePath.IsSome,
            input.SourceVersion,
            validTargets input.Policy previous input.Files)
        |> Result.bind (fun (source, previous, selected) ->
            selected |> Result.map (fun (_, files) -> source, previous, files))

    let preview connection transaction (record: OutputActionRecord) =
        let details =
            match destination record with
            | None -> Error(OutputError.Invalid "Choose a publication action.")
            | Some(OutputDestination.NewMod(id, name, label)) ->
                previewNew connection transaction record id name label
            | Some(OutputDestination.ExistingMod _) -> previewExisting connection transaction record

        details
        |> Result.map (fun (source, previous, selected) ->
            { Selected = record.Files.Length
              Replaced =
                selected
                |> List.choose (fun (target, _, previous) ->
                    previous |> Option.map (fun _ -> target))
              PreviousVersion = previous
              RegisteredSource = source })

    let private checkDestination connection transaction =
        function
        | None -> Ok()
        | Some value ->
            let label =
                match value with
                | OutputDestination.ExistingMod(_, _, label)
                | OutputDestination.NewMod(_, _, label) -> label

            if not (OutputPolicy.text 256 label) then
                Error(OutputError.Invalid "The version label is too long.")
            else
                match value with
                | OutputDestination.ExistingMod _ -> Ok()
                | OutputDestination.NewMod(id, name, _) ->
                    OutputPolicy.name name
                    |> Result.bind (fun _ ->
                        if
                            id = Guid.Empty
                            || LibraryRows.find connection transaction id |> Option.isSome
                        then
                            Error(OutputError.Invalid "Use a new mod identity.")
                        else
                            Ok())

    let private claimChecks (database: StateDatabase) transaction (record: OutputActionRecord) =
        if record.Id = Guid.Empty then
            Error(OutputError.Invalid "Use a new output action identity.")
        elif find database.Connection transaction record.Id |> Option.isSome then
            Error(OutputError.Invalid "The output action already exists.")
        elif not (OutputRows.current database.Connection transaction record.Scope) then
            Error OutputError.Stale
        else
            OutputRows.idle database.Connection transaction record.Scope.WorkspaceId
            |> Result.bind (fun () ->
                if
                    (OutputRows.pending
                        database.Connection
                        transaction
                        record.Scope.WorkspaceId
                        record.Scope.ContextId)
                        .Length
                    >= 16
                then
                    Error OutputError.LimitExceeded
                else
                    checkDestination database.Connection transaction (destination record))

    let private createDestination
        (database: StateDatabase)
        transaction
        (record: OutputActionRecord)
        =
        match destination record with
        | Some(OutputDestination.NewMod(id, name, label)) ->
            let metadata =
                { Name = name
                  Version = label
                  Source = ""
                  Notes = ""
                  Comment = ""
                  Categories = [] }

            InventoryOutput.createFromOutputs
                database.Connection
                transaction
                record.Scope.WorkspaceId
                id
                metadata
            |> ignore
        | _ -> ()

    let private markInitialized (database: StateDatabase) transaction (record: OutputActionRecord) =
        for observation in record.Files do
            if observation.File.Identity.IsSome then
                Sqlite.execute
                    database.Connection
                    transaction
                    "UPDATE output_locations SET initialized=1 WHERE id=$id AND purpose=1"
                    [ "$id", box (string observation.File.LocationId) ]

    let private insertClaim
        (database: StateDatabase)
        transaction
        (record: OutputActionRecord)
        body
        =
        Sqlite.execute
            database.Connection
            transaction
            "INSERT INTO output_actions(id,workspace_id,context_id,owner,busy,complete,version_id,body) VALUES($id,$workspace,$context,$owner,1,0,$version,$body)"
            [ "$id", box (string record.Id)
              "$workspace", box (string record.Scope.WorkspaceId)
              "$context", box (string record.Scope.ContextId)
              "$owner", box database.OwnerId
              "$version",
              record.Result.VersionId
              |> Option.map (string >> box)
              |> Option.defaultValue (box DBNull.Value)
              "$body", box body ]

    let claim (database: StateDatabase) (record: OutputActionRecord) =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let result =
            claimChecks database transaction record
            |> Result.bind (fun () ->
                createDestination database transaction record
                markInitialized database transaction record
                composition database.Connection transaction record)
            |> Result.bind (fun _ ->
                let version = destination record |> Option.map (fun _ -> Guid.NewGuid())

                let claimed =
                    { record with
                        Result =
                            { record.Result with
                                VersionId = version } }

                OutputEncoding.encode claimed
                |> Result.map (fun body ->
                    insertClaim database transaction claimed body
                    claimed))

        if Result.isOk result then
            transaction.Commit()

        result

    let resume (database: StateDatabase) id =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let resumeRecord record =
            if record.Result.Complete then
                Ok record
            elif
                OutputRows.revision
                    database.Connection
                    transaction
                    record.Scope.WorkspaceId
                    record.Scope.ContextId
                <> record.Scope.Revision
            then
                Error OutputError.Stale
            else
                OutputRows.idle database.Connection transaction record.Scope.WorkspaceId
                |> Result.map (fun () ->
                    Sqlite.execute
                        database.Connection
                        transaction
                        "UPDATE output_actions SET busy=1,owner=$owner WHERE id=$id"
                        [ "$owner", box database.OwnerId; "$id", box (string id) ]

                    record)

        let result =
            find database.Connection transaction id
            |> Option.map resumeRecord
            |> Option.defaultValue (Error OutputError.NotFound)

        if Result.isOk result then
            transaction.Commit()

        result

    let saveEntry (database: StateDatabase) id file disposition =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let update record =
            let entries =
                record.Result.Entries
                |> List.map (fun entry ->
                    if entry.File = file then
                        { entry with Disposition = disposition }
                    else
                        entry)

            let result =
                { record.Result with
                    Entries = entries
                    Complete =
                        entries
                        |> List.forall (fun entry -> entry.Disposition <> OutputDisposition.Pending) }

            let updated = { record with Result = result }

            save database.Connection transaction updated
            |> Result.map (fun () ->
                if disposition = OutputDisposition.Kept then
                    let observed =
                        record.Files
                        |> List.find (fun entry ->
                            entry.File.LocationId = file.LocationId && entry.File.Path = file.Path)

                    Sqlite.execute
                        database.Connection
                        transaction
                        "INSERT INTO output_observations(location_id,path,sha256,kept) VALUES($location,$path,$hash,1) ON CONFLICT(location_id,path) DO UPDATE SET sha256=$hash,kept=1"
                        [ "$location", box (string file.LocationId)
                          "$path", box (LibraryEncoding.path file.Path)
                          "$hash", box observed.File.Sha256 ]

                result)

        let result =
            find database.Connection transaction id
            |> Option.map update
            |> Option.defaultValue (Error OutputError.NotFound)

        if Result.isOk result then
            transaction.Commit()

        result
