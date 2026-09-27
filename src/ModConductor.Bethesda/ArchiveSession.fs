namespace ModConductor.Bethesda

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Platform

type internal ArchiveBaseline =
    | ParsedNames of string list
    | BeforeSettingsEdit of byte array

type ArchivePolicySession(repository: IFileCandidateRepository, inspection: Inspection) =
    let gate = obj ()
    let stop = new CancellationTokenSource()
    let mutable closing = false
    let mutable active = false

    let mutable idle =
        TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

    let mutable saved: ArchivePolicySnapshot option = None
    let mutable observed: (Guid * ArchiveBaseline) option = None
    do idle.SetResult()

    let label (sources: PlanSources) source =
        match source with
        | CandidateSource.Pinned(SourcePin.Mod(modId, _, _)) ->
            let value = sources.Mods |> List.find (fun row -> row.Id = modId)

            { Source = source
              Name = value.Name
              Version = value.Version }
        | CandidateSource.Pinned(SourcePin.Snapshot _)
        | CandidateSource.Observed _ ->
            { Source = source
              Name = "Game folder"
              Version = "" }

    let format workspace source (token: CancellationToken) =
        task {
            try
                let consume (stream: Stream) =
                    token.ThrowIfCancellationRequested()
                    inspection.IdentifyBethesdaOwnedStream stream

                match source with
                | CandidateSource.Observed observed ->
                    use stream = CandidateFiles.openObserved observed
                    return Some(consume stream), None
                | CandidateSource.Pinned pin ->
                    let! opened = repository.OpenManaged(workspace, pin, token)

                    match opened with
                    | Ok stream ->
                        use stream = stream
                        return Some(consume stream), None
                    | Error FilePlanError.Cancelled ->
                        return raise (OperationCanceledException token)
                    | Error _ ->
                        return
                            None,
                            Some
                                "The selected archive source cannot be read. Refresh and try again."
            with error ->
                return
                    None,
                    Some(
                        ArchiveFailure.message error
                        |> Option.defaultValue "The selected archive source cannot be read."
                    )
        }

    let acquire profile input token =
        task {
            let! acquired =
                CandidateFiles.acquire repository profile SkyrimArchives.isCandidate 100000 token

            match acquired with
            | Error error -> return Error error
            | Ok observation when observation.Sources.Stamp <> input.Headers.Stamp ->
                return Error FilePlanError.Stale
            | Ok observation ->
                let sources = observation.Sources
                let candidates = ResizeArray<ArchiveCandidate>()

                for file in
                    observation.Plan.Files
                    |> List.filter (fun row -> SkyrimArchives.isCandidate row.Target.Path) do
                    token.ThrowIfCancellationRequested()
                    let name = LogicalPath.display file.Target.Path
                    let! archiveFormat, problem =
                        format sources.Stamp.WorkspaceId file.Winner.Source token

                    candidates.Add
                        { Name = name
                          Source = Some(label sources file.Winner.Source)
                          Format = archiveFormat
                          Problem = problem }

                for conflict in
                    observation.Plan.Problems
                    |> List.filter (fun row -> SkyrimArchives.isCandidate row.Target.Path) do
                    candidates.Add
                        { Name = LogicalPath.display conflict.Target.Path
                          Source = None
                          Format = None
                          Problem = Some conflict.Detail }

                let snapshot = SkyrimArchivePolicy.resolve input (List.ofSeq candidates)
                let! current = repository.Current sources.Stamp

                match current with
                | Error error -> return Error error
                | Ok current -> return Ok { snapshot with Stale = not current }
        }

    member private _.ObserveCore(profile, input, token: CancellationToken, retain) =
        task {
            let entered =
                lock gate (fun () ->
                    if closing || active then
                        false
                    else
                        active <- true

                        idle <-
                            TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)

                        true)

            if not entered then
                return Error FilePlanError.Busy
            else
                use linked = CancellationTokenSource.CreateLinkedTokenSource(token, stop.Token)

                try
                    try
                        let! result = acquire profile input linked.Token

                        match result with
                        | Ok value when retain ->
                            lock gate (fun () ->
                                if observed |> Option.exists (fun (profile, _) -> profile <> value.Stamp.ProfileId) then
                                    observed <- None

                                if observed.IsNone then
                                    observed <- Some(value.Stamp.ProfileId, ParsedNames value.ExplicitNames)

                                saved <- Some value)
                        | _ -> ()

                        return result
                    with
                    | :? OperationCanceledException -> return Error FilePlanError.Cancelled
                    | :? IOException as error ->
                        return Error(FilePlanError.FileUnavailable error.Message)
                    | :? UnauthorizedAccessException ->
                        return
                            Error(
                                FilePlanError.FileUnavailable
                                    "The archive sources cannot be read."
                            )
                finally
                    lock gate (fun () ->
                        active <- false
                        idle.TrySetResult() |> ignore)
        }

    member this.Scan(profile, input, token) = this.ObserveCore(profile, input, token, true)

    member this.Observe(profile, input, token) = this.ObserveCore(profile, input, token, false)

    member internal _.ObservedBaseline(profile) =
        lock gate (fun () ->
            observed
            |> Option.filter (fun (value, _) -> value = profile)
            |> Option.map snd)

    member internal _.NoteSettingsEdit(profile, before: byte array) =
        lock gate (fun () ->
            if observed |> Option.exists (fun (value, _) -> value <> profile) then
                observed <- None

            if observed.IsNone then
                observed <- Some(profile, BeforeSettingsEdit before))

    member internal _.UseCurrentNames(profile, names) =
        lock gate (fun () ->
            match observed with
            | Some(value, BeforeSettingsEdit _) when value = profile ->
                observed <- Some(profile, ParsedNames names)
            | _ -> ())

    member _.Accept(id) =
        lock gate (fun () ->
            saved
            |> Option.filter (fun value -> value.Id = id)
            |> Option.iter (fun value -> observed <- Some(value.Stamp.ProfileId, ParsedNames value.ExplicitNames)))

    member _.ForgetObserved(profile) =
        lock gate (fun () ->
            if observed |> Option.exists (fun (value, _) -> value = profile) then
                observed <- None)

    member _.Read id =
        task {
            match lock gate (fun () -> saved |> Option.filter (fun value -> value.Id = id)) with
            | None -> return Error FilePlanError.Expired
            | Some value ->
                let! current = repository.Current value.Stamp
                return current |> Result.map (fun current -> { value with Stale = not current })
        }

    member _.Current stamp = repository.Current stamp

    member _.Verify(snapshot: ArchivePolicySnapshot, token: CancellationToken) =
        task {
            let! current = repository.Current snapshot.Stamp

            match current with
            | Error error -> return Error error
            | Ok false -> return Error FilePlanError.Stale
            | Ok true ->
                let mutable problem = None

                for entry in snapshot.Entries do
                    if problem.IsNone && entry.State = ArchivePolicyState.Active then
                        match entry.Source, entry.Format with
                        | Some source, Some expected ->
                            let! actual, unavailable =
                                format snapshot.Stamp.WorkspaceId source.Source token

                            problem <-
                                match actual, unavailable with
                                | Some value, None when value = expected -> None
                                | None, Some _ -> Some FilePlanError.Stale
                                | _ -> Some FilePlanError.Stale
                        | _ -> problem <- Some FilePlanError.Stale

                return problem |> Option.map Error |> Option.defaultValue (Ok())
        }

    member _.TryClose() =
        lock gate (fun () ->
            if active then
                false
            else
                closing <- true
                saved <- None
                observed <- None
                true)

    member _.Drain() =
        let wait =
            lock gate (fun () ->
                closing <- true
                idle.Task)

        stop.Cancel()
        wait
