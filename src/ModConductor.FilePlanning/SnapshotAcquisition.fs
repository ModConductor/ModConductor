namespace ModConductor.FilePlanning

open System.Threading
open System.Threading.Tasks
open ModConductor.DeploymentPlanning

type internal SnapshotAcquisition(repository: IFilePlanRepository, cache: SnapshotCache) as this =
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

    member private _.AcquireWith(candidate, profile, refresh, progress, token: CancellationToken) =
        task {
            let! baseSources = repository.Read profile

            let! sources =
                match candidate, baseSources with
                | Some run, Ok _ -> repository.ReadFnisCandidate(profile, run)
                | _ -> Task.FromResult baseSources

            match sources with
            | Error error -> return Error error
            | Ok sources ->
                match PlanSnapshot.context sources with
                | Error error -> return Error error
                | Ok evidence ->
                    let! projected =
                        repository.GameProjection(baseSources |> Result.map _.Stamp |> Result.defaultValue sources.Stamp, token)

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
                            let payloadBytes =
                                sources.Profile.Mods
                                |> List.filter _.Enabled
                                |> List.collect (fun row ->
                                    row.Version |> Option.map _.Entries |> Option.defaultValue [])
                                |> List.map _.Payload
                                |> List.distinctBy _.Id
                                |> List.sumBy _.Length

                            let gameBytes =
                                observation.Snapshot.Files |> List.sumBy SnapshotFile.length

                            if payloadBytes > Limits.contentBytes - gameBytes then
                                return
                                    Error(
                                        FilePlanError.LimitExceeded
                                            "The published files exceed the 64 GiB content limit."
                                    )
                            else
                                let! snapshot = create sources (Some observation)
                                token.ThrowIfCancellationRequested()
                                let! current =
                                    match candidate with
                                    | None -> repository.Current sources.Stamp
                                    | Some run ->
                                        task {
                                            let! baseCurrent =
                                                repository.Current(baseSources |> Result.map _.Stamp |> Result.defaultValue sources.Stamp)
                                            let! candidateCurrent = repository.ReadFnisCandidate(profile, run)
                                            return
                                                match baseCurrent, candidateCurrent with
                                                | Ok true, Ok value -> Ok(value.Stamp = sources.Stamp)
                                                | Ok false, _ -> Ok false
                                                | Error error, _ -> Error error
                                                | _, Error error -> Error error
                                        }

                                return
                                    match current with
                                    | Error error -> Error error
                                    | Ok false -> Error FilePlanError.Stale
                                    | Ok true ->
                                        snapshot |> Result.map (keep (refresh || cached.IsNone))
        }

    member _.Acquire(profile, refresh, progress, token) =
        this.AcquireWith(None, profile, refresh, progress, token)

    member _.AcquireFnisCandidate(profile, run, progress, token) =
        this.AcquireWith(Some run, profile, false, progress, token)
