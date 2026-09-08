namespace ModConductor.FilePlanning

open System.Threading
open System.Threading.Tasks

type internal SnapshotAcquisition(repository: IFilePlanRepository, cache: SnapshotCache) =
    let describe snapshot =
        PlanSnapshot.summary (cache.Stale snapshot) snapshot

    let keep fresh snapshot =
        cache.Put(snapshot, fresh)
        describe snapshot

    let create sources observation =
        Task.Run(fun () -> PlanSnapshot.create sources observation)

    member _.Open(profile, token: CancellationToken) =
        task {
            let! sources = repository.Read profile

            match sources with
            | Error error -> return Error error
            | Ok sources ->
                match cache.Matching sources.Stamp with
                | Some snapshot ->
                    return
                        PlanSnapshot.withLabels sources.Mods snapshot
                        |> Result.map (fun updated ->
                            if updated.Id <> snapshot.Id then
                                cache.Put(updated, false)

                            describe updated)
                | None ->
                    let! snapshot = create sources None
                    token.ThrowIfCancellationRequested()
                    let! current = repository.Current sources.Stamp

                    return
                        match current with
                        | Error error -> Error error
                        | Ok false -> Error FilePlanError.Stale
                        | Ok true -> snapshot |> Result.map (keep false)
        }

    member _.Acquire(profile, refresh, progress, token: CancellationToken) =
        task {
            let! sources = repository.Read profile

            match sources with
            | Error error -> return Error error
            | Ok sources ->
                match PlanSnapshot.context sources with
                | Error error -> return Error error
                | Ok evidence ->
                    let! projected = repository.GameProjection(sources.Stamp, token)

                    match projected with
                    | Error error -> return Error error
                    | Ok projection ->
                        let cached =
                            if refresh then
                                None
                            else
                                cache.Game
                                    sources.Stamp.WorkspaceId
                                    evidence.DataIdentity
                                    evidence.Fingerprint

                        let! observation =
                            Task.Run(
                                (fun () ->
                                    match cached with
                                    | None ->
                                        GameFiles.acquireProjected
                                            projection
                                            evidence
                                            sources.Stamp.WorkspaceId
                                            progress
                                            token
                                    | Some previous ->
                                        if cache.GameStale previous then
                                            Error FilePlanError.Stale
                                        else
                                            match GameFiles.reuse projection previous token with
                                            | Ok observation -> Ok observation
                                            | Error FilePlanError.Cancelled ->
                                                Error FilePlanError.Cancelled
                                            | Error error ->
                                                cache.MarkGameStale previous
                                                Error error),
                                token
                            )

                        match observation with
                        | Error error -> return Error error
                        | Ok observation ->
                            let! verified =
                                repository.VerifyPayloads(
                                    sources,
                                    Limits.contentBytes
                                    - (observation.Snapshot.Files |> List.sumBy _.Length),
                                    token
                                )

                            match verified with
                            | Error error -> return Error error
                            | Ok() ->
                                let! snapshot = create sources (Some observation)
                                token.ThrowIfCancellationRequested()
                                let! current = repository.Current sources.Stamp

                                return
                                    match current with
                                    | Error error -> Error error
                                    | Ok false -> Error FilePlanError.Stale
                                    | Ok true ->
                                        snapshot |> Result.map (keep (refresh || cached.IsNone))
        }
