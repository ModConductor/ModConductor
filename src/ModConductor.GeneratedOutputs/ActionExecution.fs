namespace ModConductor.GeneratedOutputs

open System
open System.Threading
open System.Threading.Tasks

type internal OutputActionExecution(repository: IOutputRepository) =
    let execute (record: OutputActionRecord) (token: CancellationToken) afterPublication =
        task {
            try
                if not record.Result.Complete then
                    do! repository.CheckAction record
                    let mutable result = record.Result

                    match record.Action with
                    | OutputAction.MoveToMod _
                    | OutputAction.SaveCopyToMod _ ->
                        let! _ = repository.Publish(record, token)
                        afterPublication ()
                    | OutputAction.Keep
                    | OutputAction.Discard -> ()

                    for observation in record.Files do
                        token.ThrowIfCancellationRequested()

                        let selected =
                            { LocationId = observation.File.LocationId
                              Path = observation.File.Path }

                        let state = result.Entries |> List.find (fun value -> value.File = selected)

                        if state.Disposition = OutputDisposition.Pending then
                            let! disposition =
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

                            let! saved = repository.SaveEntry(record.Id, selected, disposition)
                            result <- saved

                    return Ok result
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
                do! repository.CheckAction record
                let! record = repository.Claim record
                return! execute record token afterPublication
        }

    member _.ResumeClaimed(id, token, afterPublication) =
        task {
            let! record = repository.Resume id
            return! execute record token afterPublication
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
                |> Option.map (fun value -> Ok value.Result)
                |> Option.defaultValue (Error OutputError.NotFound)
        }

    member this.Resume(id, token, run) =
        task {
            let! value = repository.FindAction id

            match value with
            | None -> return Error OutputError.NotFound
            | Some value ->
                return!
                    run value.Scope.WorkspaceId (fun () -> this.ResumeClaimed(id, token, ignore))
        }
