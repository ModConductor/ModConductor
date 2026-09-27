namespace ModConductor.Loot

open System
open System.IO
open System.Threading
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.ProfileGameData

type LootSession
    (
        repository: IFileCandidateRepository,
        stateDirectory: string,
        helperPath: string,
        validateContext: GameContextState -> Result<InstallationEvidence, LootError>
    ) =
    let gate = obj ()
    let cache = MetadataCache stateDirectory
    let mutable busy = false
    let mutable proposal: LootProposal option = None

    let state () =
        let metadata = cache.Current()
        let helper = HelperAvailability.check helperPath stateDirectory |> Result.isOk

        if not helper then
            lock gate (fun () -> proposal <- None)

        { CapabilityId = "skyrim-se-steam"
          Available = helper
          Reason =
            if not helper then
                Some "LOOT sorting is unavailable."
            elif metadata.IsNone then
                Some "Refresh LOOT metadata before previewing a sort."
            else
                None
          Metadata = metadata
          Proposal = lock gate (fun () -> proposal) }

    let sortProjection (value: ProfilePluginOrder) metadata root game local token =
        async {
            let current =
                value.View.Order.Entries
                |> List.filter (fun row -> row.Enabled = Some true)
                |> List.map _.Name

            let fingerprint = Projection.sourceFingerprint value
            let correlation = Guid.NewGuid().ToString("N")

            let! result =
                HelperInvocation.run
                    helperPath
                    "sort"
                    root
                    game
                    local
                    metadata
                    current
                    fingerprint
                    correlation
                    token

            return
                result
                |> Result.bind (
                    ResponseValidation.validate correlation fingerprint metadata current
                )
                |> Result.map (Proposal.create value fingerprint metadata)
        }

    let previewWithMetadata (value: ProfilePluginOrder) metadata token =
        async {
            let! loaded = repository.Read value.Reference.ProfileId |> Async.AwaitTask

            match loaded with
            | Error _ -> return Error LootError.Stale
            | Ok sources when sources.Stamp <> value.Headers.Stamp -> return Error LootError.Stale
            | Ok sources ->
                let! projected =
                    Projection.build repository stateDirectory validateContext value sources token

                match projected with
                | Error error -> return Error error
                | Ok(root, game, local) ->
                    try
                        return! sortProjection value metadata root game local token
                    finally
                        try
                            Directory.Delete(root, true)
                        with _ ->
                            ()
        }

    let previewCore (value: ProfilePluginOrder) token =
        async {
            if HelperAvailability.check helperPath stateDirectory |> Result.isError then
                return Error(LootError.HelperUnavailable "LOOT sorting is unavailable.")
            else
                match cache.Current() with
                | None ->
                    return
                        Error(
                            LootError.MetadataUnavailable
                                "Refresh LOOT metadata before previewing a sort."
                        )
                | Some metadata -> return! previewWithMetadata value metadata token
        }

    let preview (value: ProfilePluginOrder) (token: CancellationToken) =
        async {
            let entered =
                lock gate (fun () ->
                    if busy then
                        false
                    else
                        busy <- true
                        true)

            if not entered then
                return Error LootError.Busy
            else
                try
                    lock gate (fun () -> proposal <- None)

                    try
                        let! result = previewCore value token

                        match result with
                        | Ok next -> lock gate (fun () -> proposal <- Some next)
                        | Error _ -> ()

                        return result
                    with
                    | :? OperationCanceledException -> return Error LootError.Cancelled
                    | error -> return Error(LootError.Unsupported error.Message)
                finally
                    lock gate (fun () -> busy <- false)
        }

    let refresh token =
        let validateMetadata metadata =
            async {
                if HelperAvailability.check helperPath stateDirectory |> Result.isError then
                    return Error(LootError.HelperUnavailable "LOOT sorting is unavailable.")
                else
                    let root =
                        Directory.CreateDirectory(
                            Path.Combine(
                                stateDirectory,
                                "loot-staging",
                                Guid.NewGuid().ToString("N")
                            )
                        )
                        |> _.FullName

                    let game = Directory.CreateDirectory(Path.Combine(root, "game")).FullName
                    Directory.CreateDirectory(Path.Combine(game, "Data")) |> ignore
                    let local = Directory.CreateDirectory(Path.Combine(root, "local")).FullName

                    try
                        let correlation = Guid.NewGuid().ToString("N")

                        let! result =
                            HelperInvocation.run
                                helperPath
                                "validateMetadata"
                                root
                                game
                                local
                                metadata
                                []
                                "metadata-refresh"
                                correlation
                                token

                        match result with
                        | Error error -> return Error error
                        | Ok response when
                            response.Correlation = correlation
                            && response.MetadataRevision = metadata.Revision
                            && response.HelperRevision = "0.1.0"
                            && response.LiblootVersion = "0.29.6"
                            && response.LiblootRevision = "136f3983"
                            ->
                            return Ok()
                        | Ok _ ->
                            return
                                Error(
                                    LootError.InvalidResponse
                                        "The LOOT helper returned different metadata evidence."
                                )
                    finally
                        try
                            Directory.Delete(root, true)
                        with _ ->
                            ()
            }

        async {
            let entered =
                lock gate (fun () ->
                    if busy then
                        false
                    else
                        busy <- true
                        true)

            if not entered then
                return Error LootError.Busy
            else
                try
                    if HelperAvailability.check helperPath stateDirectory |> Result.isError then
                        return Error(LootError.HelperUnavailable "LOOT sorting is unavailable.")
                    else
                        let! result = cache.Refresh(token, validateMetadata)

                        match result with
                        | Ok value ->
                            lock gate (fun () -> proposal <- None)
                            return Ok value
                        | Error error -> return Error error
                finally
                    lock gate (fun () -> busy <- false)
        }

    member internal _.ProjectionForFixture(value: ProfilePluginOrder, token) =
        async {
            let! loaded = repository.Read value.Reference.ProfileId |> Async.AwaitTask

            match loaded with
            | Error _ -> return Error LootError.Stale
            | Ok sources ->
                return!
                    Projection.build repository stateDirectory validateContext value sources token
        }

    interface ILootSorting with
        member _.Read() = state ()

        member _.HelperDiagnostic() =
            match HelperAvailability.check helperPath stateDirectory with
            | Ok() -> None
            | Error detail ->
                Some(
                    "Package helper: "
                    + helperPath
                    + ". Expected protocol 1, helper 0.1.0, libloot 0.29.6 at 136f3983. "
                    + detail
                )

        member _.Preview(value, token) = preview value token

        member _.ValidateApply(id, expected, headers) =
            if HelperAvailability.check helperPath stateDirectory |> Result.isError then
                Error(LootError.HelperUnavailable "LOOT sorting is unavailable.")
            else
                lock gate (fun () ->
                    match proposal with
                    | Some value when
                        value.Id = id && value.Expected = expected && value.HeadersId = headers
                        ->
                        Ok value.Sorted
                    | _ -> Error LootError.Stale)

        member _.Applied id =
            lock gate (fun () ->
                if proposal |> Option.exists (fun value -> value.Id = id) then
                    proposal <- None)

        member _.Dismiss id =
            lock gate (fun () ->
                if proposal |> Option.exists (fun value -> value.Id = id) then
                    proposal <- None)

        member _.RefreshMetadata token = refresh token
