namespace ModConductor.GeneratedOutputs

open System
open System.Threading
open System.Threading.Tasks

type internal OutputActionExecution(repository: IOutputRepository) =
    let disposition
        (record: OutputActionRecord)
        (observation: OutputObservation)
        (token: CancellationToken)
        =
        Task.Run(fun () ->
            match record.Action with
            | OutputAction.Keep
            | OutputAction.SaveCopyToMod _ ->
                if OutputFiles.current observation token then
                    match record.Action with
                    | OutputAction.Keep -> OutputDisposition.Kept
                    | _ -> OutputDisposition.Copied
                else
                    OutputDisposition.Changed
            | OutputAction.Discard
            | OutputAction.MoveToMod _ ->
                if OutputFiles.remove observation token then
                    match record.Action with
                    | OutputAction.Discard -> OutputDisposition.Discarded
                    | _ -> OutputDisposition.Moved
                else
                    OutputDisposition.Changed)

    let saveFile
        (record: OutputActionRecord)
        (token: CancellationToken)
        (result: OutputActionResult)
        (observation: OutputObservation)
        =
        task {
            token.ThrowIfCancellationRequested()

            let selected =
                { LocationId = observation.File.LocationId
                  Path = observation.File.Path }

            let state = result.Entries |> List.find (fun value -> value.File = selected)

            if state.Disposition <> OutputDisposition.Pending then
                return Ok result
            else
                let! selectedDisposition = disposition record observation token
                return! repository.SaveEntry(record.Id, selected, selectedDisposition)
        }

    let rec saveFiles
        (record: OutputActionRecord)
        token
        (result: OutputActionResult)
        (observations: OutputObservation list)
        =
        match observations with
        | [] -> Task.FromResult(Ok result)
        | observation :: rest ->
            task {
                let! saved = saveFile record token result observation

                match saved with
                | Error error -> return Error error
                | Ok result -> return! saveFiles record token result rest
            }

    let execute (record: OutputActionRecord) (token: CancellationToken) afterPublication =
        task {
            try
                if not record.Result.Complete then
                    let! validated = repository.CheckAction record

                    match validated with
                    | Error error -> return Error error
                    | Ok() ->
                        let! published =
                            match record.Action with
                            | OutputAction.MoveToMod _
                            | OutputAction.SaveCopyToMod _ -> repository.Publish(record, token)
                            | OutputAction.Keep
                            | OutputAction.Discard -> Task.FromResult(Ok Guid.Empty)

                        match published with
                        | Error error -> return Error error
                        | Ok _ ->
                            match record.Action with
                            | OutputAction.MoveToMod _
                            | OutputAction.SaveCopyToMod _ -> afterPublication ()
                            | _ -> ()

                            return! saveFiles record token record.Result record.Files
                else
                    return Ok record.Result
            finally
                repository.Release(record.Id).GetAwaiter().GetResult()
        }

    let replayMatches snapshot action selected (record: OutputActionRecord) =
        record.SnapshotId = snapshot
        && record.Action = action
        && (record.Files
            |> List.map (fun value ->
                { LocationId = value.File.LocationId
                  Path = value.File.Path })) = selected

    let newRecord id snapshot (value: CachedOutput) action selected files =
        { Id = id
          SnapshotId = snapshot
          Scope = value.Snapshot.Scope
          Action = action
          Files = files
          Result =
            { Published = false
              Id = id
              VersionId = None
              Entries =
                selected
                |> List.map (fun file ->
                    { File = file
                      Disposition = OutputDisposition.Pending })
              Complete = false } }

    member _.ApplyNew(id, snapshot, selected, action, token, afterPublication, value, files) =
        task {
            let! valid =
                Task.Run(fun () ->
                    files |> List.forall (fun file -> OutputFiles.current file token))

            if not valid then
                return Error OutputError.Stale
            else
                let record = newRecord id snapshot value action selected files
                let! validated = repository.CheckAction record

                match validated with
                | Error error -> return Error error
                | Ok() ->
                    let! claimed = repository.Claim record

                    match claimed with
                    | Error error -> return Error error
                    | Ok record -> return! execute record token afterPublication
        }

    member _.ResumeClaimed(id, token, afterPublication) =
        task {
            let! resumed = repository.Resume id

            match resumed with
            | Error error -> return Error error
            | Ok record -> return! execute record token afterPublication
        }

    member this.Apply
        (id, snapshot, selected, action, token, afterPublication, cache: OutputSnapshotCache, run)
        =
        task {
            match OutputPolicy.selection selected with
            | Error error -> return Error error
            | Ok selected ->
                let! existing = repository.FindAction id

                match existing with
                | Error error -> return Error error
                | Ok existing ->
                    match existing with
                    | Some record when replayMatches snapshot action selected record ->
                        return!
                            run record.Scope.WorkspaceId (fun () ->
                                this.ResumeClaimed(id, token, afterPublication))
                    | Some _ ->
                        return
                            Error(
                                OutputError.Invalid
                                    "This action identity already belongs to another request."
                            )
                    | None ->
                        match cache.Find snapshot with
                        | Error error -> return Error error
                        | Ok value ->
                            return!
                                run value.Snapshot.Scope.WorkspaceId (fun () ->
                                    task {
                                        match cache.SelectFiles(value, selected, action) with
                                        | Error error -> return Error error
                                        | Ok files ->
                                            return!
                                                this.ApplyNew(
                                                    id,
                                                    snapshot,
                                                    selected,
                                                    action,
                                                    token,
                                                    afterPublication,
                                                    value,
                                                    files
                                                )
                                    })
        }

    member this.Action(id) =
        task {
            let! value = repository.FindAction id

            return
                value
                |> Result.bind (function
                    | Some value -> Ok value.Result
                    | None -> Error OutputError.NotFound)
        }

    member this.Resume(id, token, run) =
        task {
            let! value = repository.FindAction id

            match value with
            | Error error -> return Error error
            | Ok None -> return Error OutputError.NotFound
            | Ok(Some value) ->
                return!
                    run value.Scope.WorkspaceId (fun () -> this.ResumeClaimed(id, token, ignore))
        }
