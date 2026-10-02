namespace ModConductor.Persistence

open System
open System.Text
open System.Threading
open ModConductor.GameContexts
open ModConductor.Bethesda
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.ProfileGameData

module internal GameViewPlugins =
    let private path parts =
        LogicalPath.create parts |> Result.defaultWith (string >> invalidOp)

    let private bethesdaSelection
        (evidence: InstallationEvidence)
        (source: Location)
        (dataFiles: SnapshotFile list)
        (scope: ProfileDataScope)
        dataRootId
        gameRootId
        (token: CancellationToken)
        =
        let rules = GameCatalog.rules evidence.DefinitionId
        let bytes = PluginInputs.creationFile scope.Game token

        let available =
            dataFiles |> List.map (fun file -> LogicalPath.display file.Path) |> Set.ofList

        let installed name =
            available
            |> Seq.exists (fun value -> value.Equals(name, StringComparison.OrdinalIgnoreCase))

        let creation =
            (UTF8Encoding(false, true).GetString bytes)
                .Split([| '\r'; '\n' |], StringSplitOptions.RemoveEmptyEntries)
            |> Array.map _.Trim()
            |> Array.filter (fun name -> not (name.StartsWith "#"))
            |> Array.filter (fun name -> installed name && OrderDocument.canWriteName name)
            |> Array.distinctBy _.ToUpperInvariant()
            |> Array.toList

        let saved = scope.Profile |> Option.bind _.PluginOrder

        let selected name =
            saved
            |> Option.bind (fun order ->
                order.Entries
                |> List.tryFind (fun row ->
                    row.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
            |> Option.bind _.Enabled
            |> Option.defaultValue true

        let optional =
            (rules.Official
             |> List.filter (fun name -> not (List.contains name rules.Primary)))
            @ creation

        let disabled = optional |> List.filter (selected >> not) |> List.filter installed

        let excluded =
            dataFiles
            |> List.choose (fun file ->
                let name = LogicalPath.display file.Path

                if
                    disabled
                    |> List.exists (fun value ->
                        value.Equals(name, StringComparison.OrdinalIgnoreCase))
                then
                    Some { Root = dataRootId; Path = file.Path }
                else
                    None)
            |> Set.ofList

        let ccc =
            creation
            |> List.filter selected
            |> fun lines ->
                if lines.IsEmpty then
                    [||]
                else
                    Encoding.UTF8.GetBytes(String.concat "\r\n" lines + "\r\n")

        let owned =
            match rules.CreationFile with
            | Some name ->
                [ { Root = gameRootId
                    Path = path [ name ] },
                  ccc ]
            | None -> []

        let invalidation =
            match rules.Invalidation with
            | None -> []
            | Some(name, version) ->
                let root =
                    match scope.Profile with
                    | Some profile when profile.Options.Settings && profile.SettingsInitialized ->
                        scope.Context
                        |> Option.filter (fun context ->
                            context.Applied
                            |> Option.exists (fun active ->
                                active.ProfileId = scope.ProfileId && active.Options.Settings))
                        |> Option.map _.Documents
                        |> Option.orElse profile.Settings
                    | _ -> scope.Context |> Option.map _.Documents

                let bytes =
                    root
                    |> Option.map (fun root ->
                        let _, _, bytes = PluginInputs.readFile root rules.Ini token in bytes)
                    |> Option.defaultValue [||]

                match IniArchives.tryArchiveEntriesFor rules.ArchiveKeys bytes with
                | Ok entries when
                    entries
                    |> List.exists (fun row ->
                        row.Name.Equals(name, StringComparison.OrdinalIgnoreCase))
                    ->
                    [ { Root = dataRootId
                        Path = path [ name ] },
                      InvalidationArchive.bytes version ]
                | _ -> []

        let excluded = invalidation |> List.map fst |> Set.ofList |> Set.union excluded
        excluded, owned @ invalidation

    let private bethesdaOrdered
        (evidence: InstallationEvidence)
        (files: SnapshotFile list)
        saved
        root
        token
        =
        let rules =
            GameCatalog.runtimeRules evidence.DefinitionId evidence.Executable.Value.FileVersion

        if rules.Ordering <> PluginOrdering.FileTime then
            Map.empty
        else
            let order =
                saved
                |> Option.defaultWith (fun () ->
                    let read name =
                        match evidence.Locations.LocalAppData with
                        | Location.Located(folder, true) ->
                            let selected =
                                DataLocations.root folder
                                |> Result.defaultWith (fun error ->
                                    raise (ProfileDataException error))

                            let _, _, bytes = PluginInputs.readFile selected name token
                            bytes
                        | _ -> [||]

                    let active =
                        OrderDocument.namesFor
                            rules.Activation
                            (read (
                                if rules.Activation = PluginActivation.MorrowindIni then
                                    rules.Ini
                                else
                                    "plugins.txt"
                            ))
                        |> List.map fst

                    let baseNames =
                        files
                        |> List.filter (fun file -> SkyrimPlugins.isCandidate file.Path)
                        |> List.sortBy (fun file ->
                            SnapshotFile.metadata file |> Option.map _.Modified)
                        |> List.map (fun file -> LogicalPath.display file.Path)

                    let names = rules.Official @ baseNames |> List.distinctBy _.ToUpperInvariant()

                    { Document = [||]
                      Entries =
                        names
                        |> List.map (fun name ->
                            { Name = name
                              Enabled =
                                Some(
                                    rules.Official
                                    |> List.exists (fun value ->
                                        value.Equals(name, StringComparison.OrdinalIgnoreCase))
                                    || active
                                       |> List.exists (fun value ->
                                           value.Equals(name, StringComparison.OrdinalIgnoreCase))
                                )
                              LockedIndex = None }) })

            PluginLists.timestamps root order

    let selection evidence source files scope dataRoot gameRoot token =
        if GameCatalog.isBethesda evidence.DefinitionId then
            bethesdaSelection evidence source files scope dataRoot gameRoot token
        else
            Set.empty, []

    let ordered evidence files saved root token =
        if GameCatalog.isBethesda evidence.DefinitionId then
            bethesdaOrdered evidence files saved root token
        else
            Map.empty
