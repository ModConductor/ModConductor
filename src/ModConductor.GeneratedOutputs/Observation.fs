namespace ModConductor.GeneratedOutputs

open System
open System.Threading.Tasks
open ModConductor.Platform

type internal OutputObservationSession(repository: IOutputRepository, cache: OutputSnapshotCache) =
    let save scope current files bytes =
        task {
            let! saved = repository.Observed(scope, files)

            if not saved then
                return Error OutputError.Stale
            else
                let snapshot =
                    { Id = Guid.NewGuid()
                      Scope = current
                      ObservedAt = DateTimeOffset.UtcNow
                      Files =
                        files
                        |> List.filter (fun value -> value.File.Identity.IsSome)
                        |> List.length
                      Entries = files.Length
                      Unreviewed =
                        files
                        |> List.filter (fun value ->
                            value.File.State = OutputFileState.New
                            || value.File.State = OutputFileState.Changed)
                        |> List.length }

                cache.Remember
                    { Snapshot = snapshot
                      Files = files
                      Index =
                        files
                        |> List.map (fun value -> (value.File.LocationId, value.File.Path), value)
                        |> Map.ofList
                      Bytes = bytes
                      Query = None }

                return Ok snapshot
        }

    member _.Observe(scope, progress, token) =
        task {
            let! current, backings =
                repository.Read(scope.WorkspaceId, scope.ProfileId, Some scope.ContextId)

            if
                current.Revision <> scope.Revision
                || current.ContextRevision <> scope.ContextRevision
            then
                return Error OutputError.Stale
            elif backings.Length <> current.Locations.Length then
                return Error(OutputError.Unavailable "An output folder has no confirmed identity.")
            else
                let! previous = repository.Previous scope
                let! deployment = repository.ActiveDeployment scope

                let! observed =
                    Task.Run(fun () ->
                        OutputFiles.observe backings previous deployment progress token)

                match observed with
                | Error error -> return Error error
                | Ok(files, bytes) -> return! save scope current files bytes

        }
