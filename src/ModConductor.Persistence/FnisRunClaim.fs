namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.Fnis

type internal FnisRunClaim(directory: string, database: StateDatabase) =
    let runs = Path.Combine(directory, "fnis-runs")

    do Directory.CreateDirectory runs |> ignore

    let stage (id: Guid) =
        Path.Combine(runs, id.ToString("N"), "output")

    let input = FnisInputInspection.read database
    let outputId = FnisRunRows.outputId
    let readRun = FnisRunRows.readRun

    let existing connection transaction id =
        use command =
            Sqlite.command
                connection
                transaction
                "SELECT id,workspace_id,profile_id,phase,busy,generation_id,generator,input_fingerprint,output_mod_id,output_version_id,exit_code,stdout,stderr,problem,run_log FROM fnis_runs WHERE id=$id"
                [ "$id", box (string id) ]

        use reader = command.ExecuteReader()
        if reader.Read() then Some(readRun reader) else None

    let sameRequest
        (
            connection,
            transaction,
            request: FnisRunRequest,
            generator: StoredFnisGenerator,
            fingerprint,
            run: StoredFnisRun
        ) =
        run.WorkspaceId = request.WorkspaceId
        && run.ProfileId = request.ProfileId
        && run.Generator = generator.Executable
        && run.Fingerprint = fingerprint
        && (run.GenerationId = generator.GenerationId
            || (run.Phase = FnisOutputPhase.Current
                && Sqlite.number
                    connection
                    transaction
                    "SELECT count(*) FROM fnis_outputs WHERE profile_id=$profile AND run_id=$run"
                    [ "$profile", box (string request.ProfileId); "$run", box (string request.Id) ] = 1L))

    let busy connection transaction profile =
        Sqlite.number
            connection
            transaction
            "SELECT count(*) FROM fnis_runs WHERE profile_id=$profile AND busy=1"
            [ "$profile", box (string profile) ] > 0L

    let newRun (request: FnisRunRequest) (generator: StoredFnisGenerator) fingerprint =
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

    let insert connection transaction (run: StoredFnisRun) =
        Sqlite.execute
            connection
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

    let admit
        (
            connection,
            transaction,
            request: FnisRunRequest,
            generator: StoredFnisGenerator,
            fingerprint
        ) =
        match existing connection transaction request.Id with
        | Some run when sameRequest (connection, transaction, request, generator, fingerprint, run) ->
            Ok(run, false)
        | Some _ -> Error FnisExecutionError.IdentityConflict
        | None when busy connection transaction request.ProfileId -> Error FnisExecutionError.Busy
        | None ->
            input connection transaction request.WorkspaceId request.ProfileId
            |> Result.mapError FnisExecutionError.Unavailable
            |> Result.bind (fun (current, _, _) ->
                if current <> fingerprint then
                    Error FnisExecutionError.Stale
                else
                    let run = newRun request generator fingerprint
                    insert connection transaction run
                    Ok(run, true))

    member _.CleanupStage(id: Guid) =
        let directory = Path.Combine(runs, id.ToString("N"))

        try
            if Directory.Exists directory then
                Directory.Delete(directory, true)
        with
        | :? IOException
        | :? UnauthorizedAccessException -> ()

    member _.Begin(request: FnisRunRequest, generator: StoredFnisGenerator, fingerprint) =
        task {
            let! result =
                database.Enqueue(fun () ->
                    use transaction = database.Connection.BeginTransaction(deferred = false)

                    let result =
                        admit (database.Connection, transaction, request, generator, fingerprint)

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

    member _.Fail
        (id, phase, exitCode, stdout: byte array, stderr: byte array, runLog: byte array, problem)
        =
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
