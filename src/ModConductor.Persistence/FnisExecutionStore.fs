namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open System.Threading.Tasks
open ModConductor.DeploymentPlanning
open ModConductor.Fnis
open ModConductor.GameContexts
open ModConductor.ModLibrary
open ModConductor.Platform

type internal StoredFnisRun =
    { Id: Guid
      WorkspaceId: Guid
      ProfileId: Guid
      Phase: FnisOutputPhase
      Busy: bool
      GenerationId: Guid
      Generator: string
      Fingerprint: string
      OutputModId: Guid
      OutputVersionId: Guid
      ExitCode: int option
      StandardOutput: string
      StandardError: string
      RunLog: string
      Problem: string option }

type internal FnisExecutionStore
    (
        directory: string,
        database: StateDatabase,
        access: LibraryAccess,
        publication: LibraryPublication,
        setups: FnisStore
    ) =
    let runs = Path.Combine(directory, "fnis-runs")

    do Directory.CreateDirectory runs |> ignore

    let stage (id: Guid) = Path.Combine(runs, id.ToString("N"), "output")

    let outputId (profile: Guid) =
        let bytes =
            SHA256.HashData(
                Encoding.UTF8.GetBytes("modconductor/fnis-output/" + profile.ToString("N"))
            )
            |> Array.take 16

        bytes[7] <- (bytes[7] &&& 0x0Fuy) ||| 0x50uy
        bytes[8] <- (bytes[8] &&& 0x3Fuy) ||| 0x80uy
        Guid bytes

    let decode bytes =
        if isNull bytes then "" else Encoding.UTF8.GetString(bytes: byte array)

    let readRun (reader: Microsoft.Data.Sqlite.SqliteDataReader) =
        let phase =
            match reader.GetInt64 3 with
            | 0L -> FnisOutputPhase.Running
            | 2L -> FnisOutputPhase.Cancelled
            | 3L -> FnisOutputPhase.Current
            | 7L -> FnisOutputPhase.Abandoned
            | _ -> FnisOutputPhase.Failed

        { Id = Guid.Parse(reader.GetString 0)
          WorkspaceId = Guid.Parse(reader.GetString 1)
          ProfileId = Guid.Parse(reader.GetString 2)
          Phase = phase
          Busy = reader.GetInt64 4 <> 0L
          GenerationId = Guid.Parse(reader.GetString 5)
          Generator = reader.GetString 6
          Fingerprint = reader.GetString 7
          OutputModId = Guid.Parse(reader.GetString 8)
          OutputVersionId = Guid.Parse(reader.GetString 9)
          ExitCode = if reader.IsDBNull 10 then None else Some(reader.GetInt32 10)
          StandardOutput = decode (reader.GetFieldValue<byte array> 11)
          StandardError = decode (reader.GetFieldValue<byte array> 12)
          Problem = if reader.IsDBNull 13 then None else Some(reader.GetString 13)
          RunLog = decode (reader.GetFieldValue<byte array> 14) }

    let latest connection transaction profile =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT id,workspace_id,profile_id,phase,busy,generation_id,generator,input_fingerprint,output_mod_id,output_version_id,exit_code,stdout,stderr,problem,run_log FROM fnis_runs WHERE profile_id=$profile ORDER BY requested_at DESC LIMIT 1"
                [ "$profile", box (string profile) ]

        use reader = command.ExecuteReader()
        if reader.Read() then Some(readRun reader) else None

    let input connection transaction workspace profile =
        let sources =
            FilePlanRows.read connection transaction database.OwnerId profile
            |> Result.defaultWith (fun _ -> raise (InvalidDataException "The FNIS inputs are unavailable."))

        if sources.Stamp.WorkspaceId <> workspace then
            raise (InvalidDataException "The selected profile belongs to another workspace.")

        let activeOutput =
            use command =
                Sqlite.command
                    connection
                    transaction
                    "SELECT mod_id,input_fingerprint FROM fnis_outputs WHERE profile_id=$profile AND workspace_id=$workspace"
                    [ "$profile", box (string profile); "$workspace", box (string workspace) ]

            use reader = command.ExecuteReader()

            if reader.Read() then
                Some(Guid.Parse(reader.GetString 0), reader.GetString 1)
            else
                None

        let excluded = activeOutput |> Option.map fst

        let profile =
            { sources.Profile with
                Mods =
                    sources.Profile.Mods
                    |> List.map (fun value ->
                        if excluded = Some value.ModId then
                            { value with Enabled = false }
                        else
                            value) }

        let visibility =
            Visibility.prepare
                { Planning =
                    { Profile = profile
                      Roots = [ { Id = workspace; Policy = Skyrim.definition.TargetPolicy } ]
                      ReadOnly = []
                      Writable = [] }
                  Hidden = sources.Hidden }

        Visibility.view visibility
        |> Result.defaultWith (fun _ -> raise (InvalidDataException "The effective FNIS inputs are unresolved."))
        |> ignore

        let files =
            Visibility.files visibility
            |> Map.toList
            |> List.choose (fun (target, resolved) ->
                match resolved with
                | Some resolved when target.Root = workspace && FnisFreshness.relevant target.Path ->
                    let length, digest =
                        match resolved.Winner.Source with
                        | SourcePin.Mod(_, _, entry) -> entry.Payload.Length, entry.Payload.Sha256
                        | SourcePin.Snapshot(_, _, file) ->
                            SnapshotFile.length file,
                            SnapshotFile.sha256 file
                            |> Option.defaultWith (fun () ->
                                raise (InvalidDataException "FNIS inputs require acquired content."))

                    Some
                        { Path = target.Path
                          Length = length
                          Sha256 = digest }
                | _ -> None)

        FnisFreshness.compute Skyrim.definition.TargetPolicy files,
        activeOutput |> Option.map snd,
        sources.Stamp.SelectionRevision

    let inspection workspace profile (generator: StoredFnisGenerator) =
        database.Enqueue(fun () ->
            let fingerprint, activeFingerprint, _ =
                input database.Connection null workspace profile

            let latest = latest database.Connection null profile

            let phase, status, detail =
                match latest, activeFingerprint with
                | Some run, _ when run.Busy ->
                    FnisOutputPhase.Running,
                    "FNIS is running",
                    "The previous generated output stays active until this run succeeds."
                | Some run, _ when
                    (run.Phase = FnisOutputPhase.Failed
                        || run.Phase = FnisOutputPhase.Cancelled
                        || run.Phase = FnisOutputPhase.Abandoned)
                    ->
                    run.Phase,
                    (match run.Phase with
                     | FnisOutputPhase.Cancelled -> "FNIS run was cancelled"
                     | FnisOutputPhase.Abandoned -> "FNIS run was interrupted"
                     | _ -> "FNIS run failed"),
                    (run.Problem
                     |> Option.defaultValue "The previous generated output remains active.")
                | _, None ->
                    FnisOutputPhase.Missing,
                    "FNIS output is missing",
                    "Run FNIS to create the generated behavior files for this profile."
                | _, Some previous when previous <> fingerprint ->
                    FnisOutputPhase.Stale,
                    "FNIS output is stale",
                    "Animation inputs changed. Run FNIS before playing."
                | Some { Phase = FnisOutputPhase.Current; ExitCode = Some code }, _ when code <> 0 ->
                    FnisOutputPhase.Current,
                    "FNIS output is available, but FNIS exited with code " + string code,
                    "Check the FNIS messages before you use these files."
                | _ ->
                    FnisOutputPhase.Current,
                    "FNIS output is current",
                    "The active generated output matches the effective animation inputs."

            { WorkspaceId = workspace
              ProfileId = profile
              GenerationId = generator.GenerationId
              Generator = generator.Executable
              Fingerprint = fingerprint
              Phase = phase
              Status = status
              Detail = detail
              LatestRunId = latest |> Option.map _.Id
              ExitCode = latest |> Option.bind _.ExitCode
              StandardOutput = latest |> Option.map _.StandardOutput |> Option.defaultValue ""
              StandardError = latest |> Option.map _.StandardError |> Option.defaultValue ""
              RunLog = latest |> Option.map _.RunLog |> Option.defaultValue "" })

    let mapLibrary =
        function
        | LibraryError.Busy -> FnisExecutionError.Busy
        | LibraryError.Cancelled -> FnisExecutionError.Cancelled
        | LibraryError.StaleRevision
        | LibraryError.SourceChanged -> FnisExecutionError.Stale
        | LibraryError.IdentityConflict -> FnisExecutionError.IdentityConflict
        | LibraryError.NotFound -> FnisExecutionError.NotFound
        | LibraryError.LimitExceeded ->
            FnisExecutionError.Invalid "The generated FNIS output exceeds its file limit."
        | LibraryError.InvalidMetadata
        | LibraryError.InvalidSource
        | LibraryError.UnsupportedAction ->
            FnisExecutionError.Invalid "The generated FNIS output is invalid."
        | LibraryError.UnprovedOwnership
        | LibraryError.FileUnavailable ->
            FnisExecutionError.Unavailable "The generated FNIS output could not be saved."

    member _.CleanupStage(id: Guid) =
        let directory = Path.Combine(runs, id.ToString("N"))

        try
            if Directory.Exists directory then
                Directory.Delete(directory, true)
        with
        | :? IOException
        | :? UnauthorizedAccessException -> ()

    member _.Inspect(workspace, profile, generation) =
        task {
            let! installed = setups.ReadStored(workspace, profile, Some generation)

            match installed with
            | None -> return Error FnisExecutionError.NotFound
            | Some generator ->
                try
                    let! value = inspection workspace profile generator
                    return Ok value
                with
                | :? InvalidDataException as error ->
                    return Error(FnisExecutionError.Unavailable error.Message)
            }

    member _.Begin(request: FnisRunRequest, generator: StoredFnisGenerator, fingerprint) =
        task {
            let! result =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)

                    let existing =
                        use command =
                            Sqlite.command
                                database.Connection
                                transaction
                                "SELECT id,workspace_id,profile_id,phase,busy,generation_id,generator,input_fingerprint,output_mod_id,output_version_id,exit_code,stdout,stderr,problem,run_log FROM fnis_runs WHERE id=$id"
                                [ "$id", box (string request.Id) ]

                        use reader = command.ExecuteReader()
                        if reader.Read() then Some(readRun reader) else None

                    let result =
                        match existing with
                        | Some run when
                            run.WorkspaceId = request.WorkspaceId
                            && run.ProfileId = request.ProfileId
                            && run.GenerationId = generator.GenerationId
                            && run.Generator = generator.Executable
                            && run.Fingerprint = fingerprint
                            -> Ok(run, false)
                        | Some _ -> Error FnisExecutionError.IdentityConflict
                        | None when
                            Sqlite.number
                                database.Connection
                                transaction
                                "SELECT count(*) FROM fnis_runs WHERE profile_id=$profile AND busy=1"
                                [ "$profile", box (string request.ProfileId) ] > 0L
                            -> Error FnisExecutionError.Busy
                        | None ->
                            let current, _, _ =
                                input
                                    database.Connection
                                    transaction
                                    request.WorkspaceId
                                    request.ProfileId

                            if current <> fingerprint then
                                Error FnisExecutionError.Stale
                            else
                                let run =
                                    { Id = request.Id
                                      WorkspaceId = request.WorkspaceId
                                      ProfileId = request.ProfileId
                                      Phase = FnisOutputPhase.Running
                                      Busy = true
                                      GenerationId = generator.GenerationId
                                      Generator = generator.Executable
                                      Fingerprint = fingerprint
                                      OutputModId = outputId request.ProfileId
                                      OutputVersionId = Guid.NewGuid()
                                      ExitCode = None
                                      StandardOutput = ""
                                      StandardError = ""
                                      RunLog = ""
                                      Problem = None }

                                Sqlite.execute
                                    database.Connection
                                    transaction
                                    "INSERT INTO fnis_runs(id,workspace_id,profile_id,owner,busy,phase,generation_id,generator,input_fingerprint,output_mod_id,output_version_id,stdout,stderr,requested_at) VALUES($id,$workspace,$profile,$owner,1,0,$generation,$generator,$fingerprint,$mod,$version,$stdout,$stderr,$requested)"
                                    [ "$id", box (string run.Id)
                                      "$workspace", box (string run.WorkspaceId)
                                      "$profile", box (string run.ProfileId)
                                      "$owner", box database.OwnerId
                                      "$generation", box (string run.GenerationId)
                                      "$generator", box run.Generator
                                      "$fingerprint", box run.Fingerprint
                                      "$mod", box (string run.OutputModId)
                                      "$version", box (string run.OutputVersionId)
                                      "$stdout", box Array.empty<byte>
                                      "$stderr", box Array.empty<byte>
                                      "$requested", box (DateTimeOffset.UtcNow.ToString("O")) ]

                                Ok(run, true)

                    transaction.Commit()
                    result)

            match result with
            | Error error -> return Error error
            | Ok(run, created) ->
                let directory = stage run.Id

                let creationError =
                    if not created then
                        None
                    else
                        try
                            Directory.CreateDirectory directory |> ignore
                            None
                        with error ->
                            Some error

                match creationError with
                | Some error ->
                        do!
                            database.EnqueueInternal(fun () ->
                                Sqlite.execute
                                    database.Connection
                                    null
                                    "UPDATE fnis_runs SET phase=1,busy=0,problem=$problem,completed_at=$completed WHERE id=$id AND owner=$owner AND busy=1"
                                    [ "$problem", box error.Message
                                      "$completed", box (DateTimeOffset.UtcNow.ToString("O"))
                                      "$id", box (string run.Id)
                                      "$owner", box database.OwnerId ])

                        return Error(FnisExecutionError.Unavailable error.Message)
                | None ->
                    return
                        Ok(
                            { Request = request
                              GenerationId = run.GenerationId
                              Generator = run.Generator
                              Fingerprint = run.Fingerprint
                              Directory = directory },
                            created,
                            run.Phase
                        )
        }

    member _.Fail(id, phase, exitCode, stdout: byte array, stderr: byte array, runLog: byte array, problem) =
        database.EnqueueInternal(fun () ->
            let phase =
                match phase with
                | FnisOutputPhase.Cancelled -> 2
                | _ -> 1

            Sqlite.execute
                database.Connection
                null
                "UPDATE fnis_runs SET phase=$phase,busy=0,exit_code=$exit,stdout=$stdout,stderr=$stderr,run_log=$log,problem=$problem,completed_at=$completed WHERE id=$id AND owner=$owner AND busy=1"
                [ "$phase", box phase
                  "$exit", exitCode |> Option.map box |> Option.defaultValue (box DBNull.Value)
                  "$stdout", box stdout
                  "$stderr", box stderr
                  "$log", box runLog
                  "$problem", box problem
                  "$completed", box (DateTimeOffset.UtcNow.ToString("O"))
                  "$id", box (string id)
                  "$owner", box database.OwnerId ])

    member _.Publish
        (
            run: FnisRunStage,
            exitCode,
            stdout: byte array,
            stderr: byte array,
            runLog: byte array,
            token: CancellationToken
        ) =
        task {
            let root =
                match HostPath.create run.Directory with
                | Error _ -> raise (IOException "The FNIS output stage is unavailable.")
                | Ok path ->
                    RootSelection.select path
                    |> Result.defaultWith (fun _ -> raise (IOException "The FNIS output stage is unavailable."))

            let identity =
                match RootSelection.facts root with
                | { File = Observation.Known value } -> value
                | _ -> raise (IOException "The FNIS output stage identity is unavailable.")

            let rootPath = RootSelection.path root
            use held = HeldDirectory.Open(rootPath, identity)
            let files, _ = SourceFiles.scan held Set.empty 100000 (fun () -> token.ThrowIfCancellationRequested())

            if files.IsEmpty then
                return Error(FnisExecutionError.Invalid "FNIS produced no generated files.")
            elif files |> List.sumBy _.Length > 2L * 1024L * 1024L * 1024L then
                return Error(FnisExecutionError.Invalid "The generated FNIS output exceeds 2 GiB.")
            else
                let! prepared =
                    database.Enqueue(fun () ->
                        use transaction = database.Connection.BeginTransaction(deferred = false)
                        let output = outputId run.Request.ProfileId
                        let row = LibraryRows.find database.Connection transaction output

                        let entry, created =
                            match row with
                            | Some row when row.Entry.WorkspaceId = run.Request.WorkspaceId ->
                                row.Entry, false
                            | Some _ -> raise (InvalidDataException "The FNIS output identity is already in use.")
                            | None ->
                                (InventoryCommands.createFromOutputs
                                    database.Connection
                                    transaction
                                    run.Request.WorkspaceId
                                    output
                                    { Name = "FNIS generated output"
                                      Notes = "Managed by Run FNIS."
                                      Comment = ""
                                      Version = DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss")
                                      Source = ""
                                      Categories = [] }),
                                true

                        let _, _, selectionRevision =
                            input
                                database.Connection
                                transaction
                                run.Request.WorkspaceId
                                run.Request.ProfileId

                        Sqlite.execute
                            database.Connection
                            transaction
                            "UPDATE fnis_runs SET expected_selection_revision=$revision WHERE id=$id AND owner=$owner AND busy=1"
                            [ "$revision", box selectionRevision
                              "$id", box (string run.Request.Id)
                              "$owner", box database.OwnerId ]

                        transaction.Commit()
                        entry.Revision, selectionRevision, entry.CurrentVersion, created)

                let expectedRevision, expectedSelection, sourceVersion, createdOutput = prepared
                let inputFiles: CompositionFile list =
                    files
                    |> List.map (fun file ->
                        { Target = file.Path
                          Root = rootPath
                          RootIdentity = identity
                          File = file })

                let composition: LibraryCompositionInput =
                    { ActionId = run.Request.Id
                      SourceVersion = sourceVersion
                      VersionLabel = DateTimeOffset.UtcNow.ToString("yyyyMMdd-HHmmss")
                      Policy = Skyrim.definition.TargetPolicy
                      Files = inputFiles
                      Bytes = [] }

                let! version =
                    database.Enqueue(fun () ->
                        use command =
                            Sqlite.command
                                database.Connection
                                null
                                "SELECT output_version_id FROM fnis_runs WHERE id=$id"
                                [ "$id", box (string run.Request.Id) ]

                        Guid.Parse(command.ExecuteScalar() :?> string))

                let! published =
                    access.Run(fun () ->
                        publication.ComposeFinalized(
                            outputId run.Request.ProfileId,
                            expectedRevision,
                            version,
                            composition,
                            token,
                            (fun connection transaction entry ->
                                let current, _, selectionRevision =
                                    input
                                        connection
                                        transaction
                                        run.Request.WorkspaceId
                                        run.Request.ProfileId

                                if
                                    selectionRevision <> expectedSelection
                                    || current <> run.Fingerprint
                                then
                                    Error LibraryError.StaleRevision
                                else
                                    let output = outputId run.Request.ProfileId

                                    let previous =
                                        use command =
                                            Sqlite.command
                                                connection
                                                transaction
                                                "SELECT mod_id FROM fnis_outputs WHERE profile_id=$profile"
                                                [ "$profile", box (string run.Request.ProfileId) ]

                                        match command.ExecuteScalar() with
                                        | :? string as value -> Some(Guid.Parse value)
                                        | _ -> None

                                    let changed =
                                        SelectionRows.all connection transaction run.Request.ProfileId
                                        |> List.map (fun row ->
                                            if row.Id = output then
                                                { row with Enabled = Some true }
                                            elif previous = Some row.Id then
                                                { row with Enabled = Some false }
                                            else
                                                row)

                                    SelectionRows.apply
                                        connection
                                        transaction
                                        run.Request.ProfileId
                                        changed

                                    Sqlite.execute
                                        connection
                                        transaction
                                        "INSERT INTO fnis_outputs(profile_id,workspace_id,mod_id,version_id,run_id,input_fingerprint,updated_at) VALUES($profile,$workspace,$mod,$version,$run,$fingerprint,$updated) ON CONFLICT(profile_id) DO UPDATE SET workspace_id=excluded.workspace_id,mod_id=excluded.mod_id,version_id=excluded.version_id,run_id=excluded.run_id,input_fingerprint=excluded.input_fingerprint,updated_at=excluded.updated_at"
                                        [ "$profile", box (string run.Request.ProfileId)
                                          "$workspace", box (string run.Request.WorkspaceId)
                                          "$mod", box (string output)
                                          "$version", box (string entry.CurrentVersion.Value)
                                          "$run", box (string run.Request.Id)
                                          "$fingerprint", box run.Fingerprint
                                          "$updated", box (DateTimeOffset.UtcNow.ToString("O")) ]

                                    Sqlite.execute
                                        connection
                                        transaction
                                        "UPDATE fnis_runs SET phase=3,busy=0,exit_code=$exit,stdout=$stdout,stderr=$stderr,run_log=$log,problem=NULL,completed_at=$completed WHERE id=$id AND owner=$owner AND busy=1"
                                        [ "$exit", box exitCode
                                          "$stdout", box stdout
                                          "$stderr", box stderr
                                          "$log", box runLog
                                          "$completed", box (DateTimeOffset.UtcNow.ToString("O"))
                                          "$id", box (string run.Request.Id)
                                          "$owner", box database.OwnerId ]

                                    Ok())
                        ))

                match published with
                | Error error ->
                    if createdOutput then
                        do!
                            database.EnqueueInternal(fun () ->
                                use transaction =
                                    database.Connection.BeginTransaction(deferred = false)

                                let output = outputId run.Request.ProfileId
                                let removable =
                                    Sqlite.number
                                        database.Connection
                                        transaction
                                        "SELECT count(*) FROM mods WHERE id=$mod AND current_version IS NULL AND NOT EXISTS(SELECT 1 FROM mod_versions WHERE mod_id=$mod) AND NOT EXISTS(SELECT 1 FROM fnis_outputs WHERE mod_id=$mod)"
                                        [ "$mod", box (string output) ] = 1L

                                if removable then
                                    Sqlite.execute
                                        database.Connection
                                        transaction
                                        "DELETE FROM profile_mods WHERE mod_id=$mod; DELETE FROM mods WHERE id=$mod; UPDATE profiles SET selection_revision=selection_revision+1 WHERE workspace_id=$workspace"
                                        [ "$mod", box (string output)
                                          "$workspace", box (string run.Request.WorkspaceId) ]

                                transaction.Commit())

                    return Error(mapLibrary error)
                | Ok _ -> return Ok()
        }
