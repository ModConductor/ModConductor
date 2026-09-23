namespace ModConductor.Persistence

open System
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning
open ModConductor.GameContexts
open ModConductor.Platform

/// Reconstructs installed component routes from the existing generation selections.
module internal ComponentRoutes =
    let private logical parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.InvalidPlan))

    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private componentFiles role useFile (version: ModConductor.ModLibrary.ModVersion) =
        version.Entries
        |> List.map (fun entry ->
            let parts = LogicalPath.components entry.Path

            let root, destination =
                match role, parts with
                | "skse", first :: rest when same first "Root" && not rest.IsEmpty ->
                    ComponentRoot.GameRoot, rest
                | "skse", first :: rest when same first "Data" && not rest.IsEmpty ->
                    ComponentRoot.Data, rest
                | "fnis", first :: rest when same first "Data" && not rest.IsEmpty ->
                    ComponentRoot.Data, rest
                | value, _ when value.StartsWith("companion:", StringComparison.Ordinal) ->
                    ComponentRoot.Data, parts
                | "runtime", _
                | "preset", _ -> ComponentRoot.GameRoot, parts
                | _ -> raise (RecoveryException RecoveryError.InvalidPlan)

            { Source = entry.Path
              Root = root
              Destination = logical destination
              Use = useFile destination })

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
            let! skse = SkseLoaderStore(database).ReadStored(workspace, profile, componentGeneration)
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

            let gameRoot =
                sources.Context.Binding
                |> Option.map _.Evidence
                |> Option.map (ComponentRoots.gameRootId workspace)
                |> Option.bind Result.toOption
                |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.Stale))

            let make id versionId role useFile =
                match selected.TryFind id with
                | None
                | Some(false, _) -> None
                | Some(true, chosen) when chosen <> Some versionId ->
                    raise (RecoveryException(RecoveryError.Unavailable "An installed component changed version. Check its setup."))
                | Some(true, _) ->
                    let modLayer =
                        sources.Profile.Mods
                        |> List.tryFind (fun row -> row.ModId = id)
                        |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.Stale))

                    let version =
                        modLayer.Version
                        |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.Stale))

                    let files = componentFiles role useFile version

                    ComponentManifests.review
                        workspace
                        gameRoot
                        Skyrim.definition.TargetPolicy
                        { ModId = id
                          Version = version
                          Priority = modLayer.Priority
                          Files = files }
                    |> Result.map Some
                    |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.InvalidPlan))

            let immutable _ = ComponentFileUse.Immutable

            let previous =
                [ yield!
                      skse
                      |> Option.bind (fun row -> make row.ModId row.VersionId "skse" immutable)
                      |> Option.toList
                  yield!
                      fnis
                      |> Option.bind (fun row -> make row.ModId row.VersionId "fnis" immutable)
                      |> Option.toList
                  for row in enb do
                      let useFile destination =
                          if row.Kind = "preset" && same (List.last destination) "enblocal.ini" then
                              ComponentFileUse.WritableConfiguration
                          else
                              ComponentFileUse.Immutable

                      yield! make row.ModId row.VersionId row.Kind useFile |> Option.toList ]

            let replacements = explicit |> List.map (fun row -> row.Mod.ModId) |> Set.ofList
            return (previous |> List.filter (fun row -> not (replacements.Contains row.Mod.ModId))) @ explicit
        }
