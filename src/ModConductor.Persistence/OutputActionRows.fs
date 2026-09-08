namespace ModConductor.Persistence

open System
open ModConductor.GeneratedOutputs
open ModConductor.ModLibrary

module internal OutputActionRows =
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
                OutputRows.fail OutputError.LimitExceeded

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
        Sqlite.execute
            connection
            transaction
            "UPDATE output_actions SET complete=$complete,version_id=$version,body=$body WHERE id=$id"
            [ "$complete", box record.Result.Complete
              "$version",
              record.Result.VersionId
              |> Option.map (string >> box)
              |> Option.defaultValue (box DBNull.Value)
              "$body", box (OutputEncoding.encode record)
              "$id", box (string record.Id) ]

    let destination (record: OutputActionRecord) =
        match record.Action with
        | OutputAction.MoveToMod value
        | OutputAction.SaveCopyToMod value -> Some value
        | OutputAction.Keep
        | OutputAction.Discard -> None

    let composition connection transaction (record: OutputActionRecord) =
        destination record
        |> Option.map (fun destination ->
            let id, expected, label =
                match destination with
                | OutputDestination.ExistingMod(id, expected, label) -> id, expected, label
                | OutputDestination.NewMod(id, _, label) -> id, 0L, label

            let row =
                LibraryRows.find connection transaction id
                |> Option.defaultWith (fun () -> OutputRows.fail OutputError.NotFound)

            if
                row.Entry.WorkspaceId <> record.Scope.WorkspaceId
                || row.Entry.Kind <> ModKind.Regular
            then
                OutputRows.fail (OutputError.Invalid "Select a regular mod from this workspace.")

            if row.Entry.Revision <> expected then
                OutputRows.fail OutputError.Stale

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
                              Sha256 = value.File.Sha256 } }) }

            let previous =
                input.SourceVersion
                |> Option.bind (fun version ->
                    LibraryRows.version connection transaction version 0 100001)
                |> Option.map _.Entries
                |> Option.defaultValue []

            if previous.Length > 100000 then
                OutputRows.fail OutputError.LimitExceeded

            LibraryComposition.targets input.Policy previous input.Files |> ignore
            id, expected, input)

    let preview connection transaction (record: OutputActionRecord) =
        let source, previous, selected =
            match destination record with
            | None -> OutputRows.fail (OutputError.Invalid "Choose a publication action.")
            | Some(OutputDestination.NewMod(id, name, label)) ->
                if
                    id = Guid.Empty || LibraryRows.find connection transaction id |> Option.isSome
                then
                    OutputRows.fail (OutputError.Invalid "Use a new mod identity.")

                OutputPolicy.name name |> Result.defaultWith OutputRows.fail |> ignore

                if not (OutputPolicy.text 256 label) then
                    OutputRows.fail (OutputError.Invalid "The version label is too long.")

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

                false,
                None,
                LibraryComposition.targets
                    ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                    []
                    files
                |> snd
            | Some(OutputDestination.ExistingMod _) ->
                let id, _, input = composition connection transaction record |> Option.get
                let row = LibraryRows.find connection transaction id |> Option.get

                let previous =
                    input.SourceVersion
                    |> Option.bind (fun version ->
                        LibraryRows.version connection transaction version 0 100001)
                    |> Option.map _.Entries
                    |> Option.defaultValue []

                row.Entry.SourcePath.IsSome,
                input.SourceVersion,
                LibraryComposition.targets input.Policy previous input.Files |> snd

        { Selected = record.Files.Length
          Replaced =
            selected
            |> List.choose (fun (target, _, previous) -> previous |> Option.map (fun _ -> target))
          PreviousVersion = previous
          RegisteredSource = source }

    let claim (database: StateDatabase) (record: OutputActionRecord) =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        if record.Id = Guid.Empty then
            OutputRows.fail (OutputError.Invalid "Use a new output action identity.")

        if find database.Connection transaction record.Id |> Option.isSome then
            OutputRows.fail (OutputError.Invalid "The output action already exists.")

        if not (OutputRows.current database.Connection transaction record.Scope) then
            OutputRows.fail OutputError.Stale

        OutputRows.idle database.Connection transaction record.Scope.WorkspaceId

        if
            (OutputRows.pending
                database.Connection
                transaction
                record.Scope.WorkspaceId
                record.Scope.ContextId)
                .Length
            >= 16
        then
            OutputRows.fail OutputError.LimitExceeded

        destination record
        |> Option.iter (fun value ->
            let label =
                match value with
                | OutputDestination.ExistingMod(_, _, label)
                | OutputDestination.NewMod(_, _, label) -> label

            if not (OutputPolicy.text 256 label) then
                OutputRows.fail (OutputError.Invalid "The version label is too long.")

            match value with
            | OutputDestination.NewMod(id, name, label) ->
                let name = OutputPolicy.name name |> Result.defaultWith OutputRows.fail

                let metadata =
                    { Name = name
                      Version = label
                      Source = ""
                      Notes = ""
                      Comment = ""
                      Categories = [] }

                InventoryCommands.createFromOutputs
                    database.Connection
                    transaction
                    record.Scope.WorkspaceId
                    id
                    metadata
                |> ignore
            | OutputDestination.ExistingMod _ -> ())

        for observation in record.Files do
            if observation.File.Identity.IsSome then
                Sqlite.execute
                    database.Connection
                    transaction
                    "UPDATE output_locations SET initialized=1 WHERE id=$id AND purpose=1"
                    [ "$id", box (string observation.File.LocationId) ]

        composition database.Connection transaction record |> ignore
        let version = destination record |> Option.map (fun _ -> Guid.NewGuid())

        let record =
            { record with
                Result =
                    { record.Result with
                        VersionId = version } }

        Sqlite.execute
            database.Connection
            transaction
            "INSERT INTO output_actions(id,workspace_id,context_id,owner,busy,complete,version_id,body) VALUES($id,$workspace,$context,$owner,1,0,$version,$body)"
            [ "$id", box (string record.Id)
              "$workspace", box (string record.Scope.WorkspaceId)
              "$context", box (string record.Scope.ContextId)
              "$owner", box database.OwnerId
              "$version",
              version |> Option.map (string >> box) |> Option.defaultValue (box DBNull.Value)
              "$body", box (OutputEncoding.encode record) ]

        transaction.Commit()
        record

    let resume (database: StateDatabase) id =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let record =
            find database.Connection transaction id
            |> Option.defaultWith (fun () -> OutputRows.fail OutputError.NotFound)

        if not record.Result.Complete then
            if
                OutputRows.revision
                    database.Connection
                    transaction
                    record.Scope.WorkspaceId
                    record.Scope.ContextId
                <> record.Scope.Revision
            then
                OutputRows.fail OutputError.Stale

            OutputRows.idle database.Connection transaction record.Scope.WorkspaceId

            Sqlite.execute
                database.Connection
                transaction
                "UPDATE output_actions SET busy=1,owner=$owner WHERE id=$id"
                [ "$owner", box database.OwnerId; "$id", box (string id) ]

        transaction.Commit()
        record

    let saveEntry (database: StateDatabase) id file disposition =
        use transaction = database.Connection.BeginTransaction(deferred = false)

        let record =
            find database.Connection transaction id
            |> Option.defaultWith (fun () -> OutputRows.fail OutputError.NotFound)

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

        let record = { record with Result = result }
        save database.Connection transaction record

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

        transaction.Commit()
        result
