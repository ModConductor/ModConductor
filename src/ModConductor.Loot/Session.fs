namespace ModConductor.Loot

open System
open System.Collections.Generic
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.Bethesda
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.ProfileGameData

type LootSession
    (
        repository: IFileCandidateRepository,
        stateDirectory: string,
        helperPath: string,
        validateContext: GameContextState -> InstallationEvidence
    ) =
    let gate = obj ()
    let cache = MetadataCache stateDirectory
    let mutable busy = false
    let mutable proposal: LootProposal option = None

    let validPluginName (name: string) =
        not (String.IsNullOrWhiteSpace name)
        && name <> "."
        && name <> ".."
        && name = Path.GetFileName name
        && not (name.Contains Path.DirectorySeparatorChar)
        && not (name.Contains Path.AltDirectorySeparatorChar)
        && not (name.Contains '/')
        && not (name.Contains '\\')

    let sourceFingerprint (value: ProfilePluginOrder) =
        let stamp = value.Headers.Stamp

        String.Join(
            ":",
            [ value.Reference.WorkspaceId.ToString("N")
              value.Reference.ProfileId.ToString("N")
              string value.Reference.Revision
              value.Headers.Id.ToString("N")
              string stamp.SelectionRevision
              string stamp.ContextRevision
              string stamp.ExclusionRevision
              string stamp.OutputRevision
              Option.defaultValue "" stamp.Deployment ]
        )

    let state () =
        let metadata = cache.Current()
        let helper = File.Exists helperPath

        { CapabilityId = "skyrim-se-steam"
          Available = helper && metadata.IsSome
          Reason =
            if not helper then
                Some "The local LOOT helper has not been built."
            elif metadata.IsNone then
                Some "Refresh LOOT metadata before previewing a sort."
            else
                None
          Metadata = metadata
          Proposal = lock gate (fun () -> proposal) }

    let copySource workspace (source: CandidateSource) destination token =
        async {
            let! opened =
                match source with
                | CandidateSource.Observed source ->
                    async {
                        try
                            return Ok(CandidateFiles.openObserved source)
                        with error ->
                            return Error(FilePlanError.FileUnavailable error.Message)
                    }
                | CandidateSource.Pinned pin ->
                    repository.OpenManaged(workspace, pin, token) |> Async.AwaitTask

            match opened with
            | Error error -> return Error error
            | Ok stream ->
                use stream = stream

                use output =
                    new FileStream(
                        destination,
                        FileMode.CreateNew,
                        FileAccess.Write,
                        FileShare.None
                    )

                do! stream.CopyToAsync(output, 1024 * 1024, token) |> Async.AwaitTask
                return Ok stream.Length
        }

    let buildProjection
        (value: ProfilePluginOrder)
        (sources: PlanSources)
        (token: CancellationToken)
        =
        async {
            let evidence = validateContext sources.Context

            if evidence.DefinitionId <> GameId.SkyrimSpecialEditionSteam then
                return Error(LootError.Unsupported "LOOT sorting is not available for this game.")
            else
                let root =
                    Path.Combine(stateDirectory, "loot-staging", Guid.NewGuid().ToString("N"))

                let game = Directory.CreateDirectory(Path.Combine(root, "game")).FullName
                let data = Directory.CreateDirectory(Path.Combine(game, "Data")).FullName
                let local = Directory.CreateDirectory(Path.Combine(root, "local")).FullName

                try
                    let headers = Dictionary<string, PluginEntry>(StringComparer.OrdinalIgnoreCase)

                    for entry in value.Headers.Entries do
                        if not (headers.TryAdd(entry.Name, entry)) then
                            raise (InvalidDataException "Plugin names differ only by case.")

                    let mutable total = 0L

                    for setting in value.View.Order.Entries |> List.filter (fun row -> row.Enabled = Some true) do
                        token.ThrowIfCancellationRequested()

                        if not (validPluginName setting.Name) then
                            raise (InvalidDataException "A plugin name is not a single file name.")

                        match headers.TryGetValue setting.Name with
                        | false, _ ->
                            raise (
                                InvalidDataException(
                                    setting.Name + " does not have a checked projected source."
                                )
                            )
                        | true, entry ->
                            match entry.Ambiguity, entry.Winner with
                            | Some _, _
                            | _, None ->
                                raise (
                                    InvalidDataException(
                                        setting.Name
                                        + " does not have one checked projected source."
                                    )
                                )
                            | None, Some winner ->
                                let! copied =
                                    copySource
                                        value.Reference.WorkspaceId
                                        winner.Source
                                        (Path.Combine(data, setting.Name))
                                        token

                                match copied with
                                | Error FilePlanError.Cancelled ->
                                    raise (OperationCanceledException token)
                                | Error _ ->
                                    raise (
                                        IOException(
                                            setting.Name
                                            + " could not be copied into the LOOT projection."
                                        )
                                    )
                                | Ok length ->
                                    total <- total + length

                                    if total > 32L * 1024L * 1024L * 1024L then
                                        raise (
                                            InvalidDataException
                                                "The LOOT projection exceeds its 32 GiB byte limit."
                                        )

                    let bytes = OrderDocument.write value.Facts.Implicit value.View.Order
                    File.WriteAllBytes(Path.Combine(local, "Plugins.txt"), bytes)

                    let enabled =
                        value.View.Order.Entries
                        |> List.filter (fun row -> row.Enabled = Some true)
                        |> List.map _.Name

                    let creation =
                        value.Facts.Early
                        |> List.filter (fun name ->
                            not (OrderRules.baseFiles |> List.exists (fun baseName ->
                                baseName.Equals(name, StringComparison.OrdinalIgnoreCase)))
                            && (enabled |> List.exists (fun active ->
                                active.Equals(name, StringComparison.OrdinalIgnoreCase))))

                    File.WriteAllText(
                        Path.Combine(game, "Skyrim.ccc"),
                        (if creation.IsEmpty then "" else String.concat "\r\n" creation + "\r\n"),
                        UTF8Encoding(false)
                    )

                    match evidence.Executable with
                    | Some executable when executable.Length <= 1024L * 1024L * 1024L ->
                        File.Copy(executable.Path, Path.Combine(game, Skyrim.definition.Executable))
                    | Some _ ->
                        raise (InvalidDataException "The checked game executable exceeds 1 GiB.")
                    | None -> raise (InvalidDataException "The checked game executable is missing.")

                    return Ok(root, game, local)
                with
                | :? OperationCanceledException as error ->
                    try
                        Directory.Delete(root, true)
                    with _ ->
                        ()

                    return raise error
                | error ->
                    try
                        Directory.Delete(root, true)
                    with _ ->
                        ()

                    return Error(LootError.Unsupported error.Message)
        }

    let runHelper
        (operation: string)
        (root: string)
        (game: string)
        (local: string)
        (metadata: LootMetadata)
        (plugins: string list)
        (fingerprint: string)
        (correlation: string)
        (token: CancellationToken)
        =
        async {
            let request =
                LootJson.request operation correlation root game local metadata plugins fingerprint

            let limits =
                { InputBytes = 4 * 1024 * 1024
                  OutputBytes = 4 * 1024 * 1024
                  ErrorBytes = 256 * 1024
                  Timeout = TimeSpan.FromSeconds 120.0 }

            let! result =
                NativeToolLaunch.run
                    { Executable = helperPath
                      Arguments = []
                      WorkingDirectory = root
                      Environment = [ "http_proxy", None; "https_proxy", None; "all_proxy", None ] }
                    request
                    limits
                    token
                |> Async.AwaitTask

            match result with
            | Error NativeToolError.Cancelled -> return Error LootError.Cancelled
            | Error NativeToolError.TimedOut ->
                return Error(LootError.HelperUnavailable "The LOOT helper timed out.")
            | Error NativeToolError.OutputLimit ->
                return Error(LootError.InvalidResponse "The LOOT helper output exceeded 4 MiB.")
            | Error NativeToolError.ErrorLimit ->
                return
                    Error(
                        LootError.HelperUnavailable "The LOOT helper diagnostic exceeded 256 KiB."
                    )
            | Error(NativeToolError.LaunchFailed detail) ->
                return Error(LootError.HelperUnavailable detail)
            | Ok result when result.ExitCode <> 0 ->
                let detail = Encoding.UTF8.GetString result.Error

                return
                    Error(
                        LootError.HelperUnavailable(
                            if String.IsNullOrWhiteSpace detail then
                                "The LOOT helper exited with code " + string result.ExitCode + "."
                            else
                                detail.Trim()
                        )
                    )
            | Ok result ->
                try
                    return Ok(LootJson.response result.Output)
                with error ->
                    return Error(LootError.InvalidResponse error.Message)
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
                        if not (File.Exists helperPath) then
                            return
                                Error(
                                    LootError.HelperUnavailable
                                        "The local LOOT helper has not been built."
                                )
                        else
                            match cache.Current() with
                            | None ->
                                return
                                    Error(
                                        LootError.MetadataUnavailable
                                            "Refresh LOOT metadata before previewing a sort."
                                    )
                            | Some metadata ->
                                let! loaded =
                                    repository.Read value.Reference.ProfileId |> Async.AwaitTask

                                match loaded with
                                | Error _ -> return Error LootError.Stale
                                | Ok sources when sources.Stamp <> value.Headers.Stamp ->
                                    return Error LootError.Stale
                                | Ok sources ->
                                    let! projected = buildProjection value sources token

                                    match projected with
                                    | Error error -> return Error error
                                    | Ok(root, game, local) ->
                                        try
                                            let all = value.View.Order.Entries
                                            let current =
                                                all
                                                |> List.filter (fun row -> row.Enabled = Some true)
                                                |> List.map _.Name

                                            let fingerprint = sourceFingerprint value
                                            let correlation = Guid.NewGuid().ToString("N")

                                            let! result =
                                                runHelper
                                                    "sort"
                                                    root
                                                    game
                                                    local
                                                    metadata
                                                    current
                                                    fingerprint
                                                    correlation
                                                    token

                                            match result with
                                            | Error error -> return Error error
                                            | Ok response ->
                                                match
                                                    ResponseValidation.validate
                                                        correlation
                                                        fingerprint
                                                        metadata
                                                        current
                                                        response
                                                with
                                                | Error error -> return Error error
                                                | Ok response ->
                                                    let sorted = ResizeArray(response.Sorted)
                                                    let mutable position = 0
                                                    let fullSorted =
                                                        all
                                                        |> List.map (fun row ->
                                                            if row.Enabled = Some true then
                                                                let name = sorted[position]
                                                                position <- position + 1
                                                                name
                                                            else row.Name)

                                                    let fullCurrent = all |> List.map _.Name
                                                    let positions =
                                                        Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)

                                                    fullSorted
                                                    |> List.iteri (fun index name ->
                                                        positions.Add(name, index + 1))

                                                    let moves =
                                                        fullCurrent
                                                        |> List.mapi (fun index name ->
                                                            let next = positions[name]
                                                            if next = index + 1 then None
                                                            else
                                                                Some
                                                                    { Plugin = name
                                                                      Current = index + 1
                                                                      Proposed = next
                                                                      Reason = "LOOT order" })
                                                        |> List.choose id

                                                    let next =
                                                        { Id = Guid.NewGuid()
                                                          Expected = value.Reference
                                                          HeadersId = value.Headers.Id
                                                          SourceFingerprint = fingerprint
                                                          CreatedAt = DateTimeOffset.UtcNow
                                                          Current = fullCurrent
                                                          Sorted = fullSorted
                                                          Moves = moves
                                                          Messages = response.Messages
                                                          Metadata = metadata
                                                          HelperVersion = response.HelperRevision
                                                          LiblootVersion = response.LiblootVersion
                                                          LiblootRevision = response.LiblootRevision }

                                                    lock gate (fun () -> proposal <- Some next)
                                                    return Ok next
                                        finally
                                            try
                                                Directory.Delete(root, true)
                                            with _ ->
                                                ()
                    with
                    | :? OperationCanceledException -> return Error LootError.Cancelled
                    | error -> return Error(LootError.Unsupported error.Message)
                finally
                    lock gate (fun () -> busy <- false)
        }

    let refresh token =
        let validateMetadata metadata =
            async {
                if not (File.Exists helperPath) then
                    return
                        Error(
                            LootError.HelperUnavailable
                                "Build the local LOOT helper before refreshing metadata."
                        )
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
                            runHelper
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
            | Ok sources -> return! buildProjection value sources token
        }

    interface ILootSorting with
        member _.Read() = state ()
        member _.Preview(value, token) = preview value token

        member _.ValidateApply(id, expected, headers) =
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
