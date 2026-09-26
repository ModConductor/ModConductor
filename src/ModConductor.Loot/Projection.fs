namespace ModConductor.Loot

open System
open System.Collections.Generic
open System.IO
open System.Text
open System.Threading
open ModConductor.Bethesda
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.ProfileGameData

module internal Projection =
    let private validPluginName (name: string) =
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

    let private copySource
        (repository: IFileCandidateRepository)
        workspace
        (source: CandidateSource)
        destination
        token
        =
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

    let private headersByName (value: ProfilePluginOrder) =
        let headers = Dictionary<string, PluginEntry>(StringComparer.OrdinalIgnoreCase)

        if
            value.Headers.Entries
            |> List.exists (fun entry -> not (headers.TryAdd(entry.Name, entry)))
        then
            Error(LootError.Unsupported "Plugin names differ only by case.")
        else
            Ok headers

    let private checkedSource (headers: Dictionary<string, PluginEntry>) name =
        if not (validPluginName name) then
            Error(LootError.Unsupported "A plugin name is not a single file name.")
        else
            match headers.TryGetValue name with
            | false, _ ->
                Error(LootError.Unsupported(name + " does not have a checked projected source."))
            | true, entry ->
                match entry.Ambiguity, entry.Winner with
                | Some _, _
                | _, None ->
                    Error(
                        LootError.Unsupported(name + " does not have one checked projected source.")
                    )
                | None, Some winner -> Ok winner.Source

    let private stagePlugins
        repository
        (value: ProfilePluginOrder)
        data
        (token: CancellationToken)
        =
        async {
            match headersByName value with
            | Error error -> return Error error
            | Ok headers ->
                let enabled =
                    value.View.Order.Entries |> List.filter (fun row -> row.Enabled = Some true)

                let rec stage total (rows: PluginSetting list) =
                    async {
                        match rows with
                        | [] -> return Ok()
                        | setting :: remaining ->
                            token.ThrowIfCancellationRequested()

                            match checkedSource headers setting.Name with
                            | Error error -> return Error error
                            | Ok source ->
                                let! copied =
                                    copySource
                                        repository
                                        value.Reference.WorkspaceId
                                        source
                                        (Path.Combine(data, setting.Name))
                                        token

                                match copied with
                                | Error FilePlanError.Cancelled -> return Error LootError.Cancelled
                                | Error _ ->
                                    return
                                        Error(
                                            LootError.Unsupported(
                                                setting.Name
                                                + " could not be copied into the LOOT projection."
                                            )
                                        )
                                | Ok length when total + length > 32L * 1024L * 1024L * 1024L ->
                                    return
                                        Error(
                                            LootError.Unsupported
                                                "The LOOT projection exceeds its 32 GiB byte limit."
                                        )
                                | Ok length -> return! stage (total + length) remaining
                    }

                return! stage 0L enabled
        }

    let private writeGameFiles
        (value: ProfilePluginOrder)
        (evidence: InstallationEvidence)
        game
        local
        =
        let bytes = OrderDocument.write value.Facts.Implicit value.View.Order
        File.WriteAllBytes(Path.Combine(local, "Plugins.txt"), bytes)

        let enabled =
            value.View.Order.Entries
            |> List.filter (fun row -> row.Enabled = Some true)
            |> List.map _.Name

        let creation =
            value.Facts.Early
            |> List.filter (fun name ->
                not (
                    OrderRules.baseFiles
                    |> List.exists (fun baseName ->
                        baseName.Equals(name, StringComparison.OrdinalIgnoreCase))
                )
                && (enabled
                    |> List.exists (fun active ->
                        active.Equals(name, StringComparison.OrdinalIgnoreCase))))

        File.WriteAllText(
            Path.Combine(game, "Skyrim.ccc"),
            (if creation.IsEmpty then
                 ""
             else
                 String.concat "\r\n" creation + "\r\n"),
            UTF8Encoding(false)
        )

        match evidence.Executable with
        | Some executable when executable.Length <= 1024L * 1024L * 1024L ->
            File.Copy(executable.Path, Path.Combine(game, Skyrim.definition.Executable))
            Ok()
        | Some _ -> Error(LootError.Unsupported "The checked game executable exceeds 1 GiB.")
        | None -> Error(LootError.Unsupported "The checked game executable is missing.")

    let private deleteStaging root =
        try
            Directory.Delete(root, true)
        with _ ->
            ()

    let build
        (repository: IFileCandidateRepository)
        stateDirectory
        (validateContext: GameContextState -> InstallationEvidence)
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
                    let! staged = stagePlugins repository value data token

                    let result =
                        staged |> Result.bind (fun () -> writeGameFiles value evidence game local)

                    match result with
                    | Ok() -> return Ok(root, game, local)
                    | Error error ->
                        deleteStaging root
                        return Error error
                with
                | :? OperationCanceledException as error ->
                    deleteStaging root
                    return raise error
                | error ->
                    deleteStaging root
                    return Error(LootError.Unsupported error.Message)
        }
