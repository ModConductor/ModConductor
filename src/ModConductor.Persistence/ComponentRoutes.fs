namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.Platform

/// Reconstructs installed component routes from the existing generation selections.
module internal ComponentRoutes =
    let private logical parts =
        LogicalPath.create parts |> Result.mapError (fun _ -> RecoveryError.InvalidPlan)

    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private componentFiles role useFile (version: ModConductor.ModLibrary.ModVersion) =
        let route entry =
            let parts = LogicalPath.components entry.Path

            let destination =
                match role, parts with
                | "skse", first :: rest when same first "Root" && not rest.IsEmpty ->
                    Ok(ComponentRoot.GameRoot, rest)
                | "skse", first :: rest when same first "Data" && not rest.IsEmpty ->
                    Ok(ComponentRoot.Data, rest)
                | "fnis", first :: rest when same first "Data" && not rest.IsEmpty ->
                    Ok(ComponentRoot.Data, rest)
                | value, _ when value.StartsWith("companion:", StringComparison.Ordinal) ->
                    Ok(ComponentRoot.Data, parts)
                | "runtime", _
                | "preset", _ -> Ok(ComponentRoot.GameRoot, parts)
                | _ -> Error RecoveryError.InvalidPlan

            destination
            |> Result.bind (fun (root, parts) ->
                logical parts
                |> Result.map (fun path ->
                    { Source = entry.Path
                      Root = root
                      Destination = path
                      Use = useFile path }))

        version.Entries
        |> List.fold
            (fun routes entry ->
                routes
                |> Result.bind (fun routes ->
                    route entry |> Result.map (fun file -> file :: routes)))
            (Ok [])
        |> Result.map List.rev

    let read
        (database: StateDatabase)
        (sources: PlanSources)
        (existing: Context option)
        (explicit: ReviewedComponent list)
        (retained: SavedProfile option)
        retainedGeneration
        =
        task {
            let workspace, profile = sources.Stamp.WorkspaceId, sources.Stamp.ProfileId

            let componentGeneration =
                retainedGeneration |> Option.orElse (existing |> Option.bind _.Active)

            let! skse =
                SkseLoaderStore(database).ReadStored(workspace, profile, componentGeneration)

            let! fnis = FnisStore(database).ReadStored(workspace, profile, componentGeneration)
            let! enb = EnbStore(database).Components(workspace, profile, componentGeneration)

            let selected =
                retained
                |> Option.map (fun saved ->
                    saved.Mods
                    |> List.map (fun row -> row.ModId, (row.Enabled, row.VersionId))
                    |> Map.ofList)
                |> Option.defaultWith (fun () ->
                    sources.Profile.Mods
                    |> List.map (fun row ->
                        row.ModId, (row.Enabled, (row.Version |> Option.map _.Id)))
                    |> Map.ofList)

            let review evidence gameRoot =
                let make id versionId role useFile =
                    match selected.TryFind id with
                    | None
                    | Some(false, _) -> Ok None
                    | Some(true, chosen) when chosen <> Some versionId ->
                        Error(
                            RecoveryError.Unavailable
                                "An installed component changed version. Check its setup."
                        )
                    | Some(true, _) ->
                        match sources.Profile.Mods |> List.tryFind (fun row -> row.ModId = id) with
                        | None -> Error RecoveryError.Stale
                        | Some modLayer ->
                            match modLayer.Version with
                            | None -> Error RecoveryError.Stale
                            | Some version ->
                                componentFiles role useFile version
                                |> Result.bind (fun files ->
                                    ComponentManifests.review
                                        workspace
                                        gameRoot
                                        Skyrim.definition.TargetPolicy
                                        { ModId = id
                                          Version = version
                                          Priority = modLayer.Priority
                                          Files = files }
                                    |> Result.map Some
                                    |> Result.mapError (fun _ -> RecoveryError.InvalidPlan))

                let immutable _ = ComponentFileUse.Immutable

                let add review rows =
                    rows
                    |> Result.bind (fun previous ->
                        review ()
                        |> Result.map (function
                            | Some item -> item :: previous
                            | None -> previous))

                let afterSkse =
                    add
                        (fun () ->
                            match skse with
                            | Some row -> make row.ModId row.VersionId "skse" immutable
                            | None -> Ok None)
                        (Ok [])

                let afterFnis =
                    add
                        (fun () ->
                            match fnis with
                            | None -> Ok None
                            | Some row ->
                                let selected = Path.GetFullPath row.Executable

                                let useFile destination =
                                    let candidate =
                                        Path.GetFullPath(
                                            Path.Combine(
                                                evidence.RootPath,
                                                "Data",
                                                LogicalPath.display destination
                                            )
                                        )

                                    if same candidate selected then
                                        ComponentFileUse.WritableContainingDirectory
                                    else
                                        ComponentFileUse.Immutable

                                make row.ModId row.VersionId "fnis" useFile)
                        afterSkse

                let previous =
                    enb
                    |> List.fold
                        (fun rows row ->
                            add
                                (fun () ->
                                    let useFile destination =
                                        if
                                            row.Kind = "preset"
                                            && same
                                                (LogicalPath.components destination |> List.last)
                                                "enblocal.ini"
                                        then
                                            ComponentFileUse.WritableConfiguration
                                        else
                                            ComponentFileUse.Immutable

                                    make row.ModId row.VersionId row.Kind useFile)
                                rows)
                        afterFnis

                let replacements = explicit |> List.map (fun row -> row.Mod.ModId) |> Set.ofList

                previous
                |> Result.map (fun rows ->
                    (rows
                     |> List.rev
                     |> List.filter (fun row -> not (replacements.Contains row.Mod.ModId)))
                    @ explicit)

            match sources.Context.Binding with
            | None -> return Error RecoveryError.Stale
            | Some binding ->
                match ComponentRoots.gameRootId workspace binding.Evidence with
                | Error _ -> return Error RecoveryError.Stale
                | Ok gameRoot -> return review binding.Evidence gameRoot
        }
