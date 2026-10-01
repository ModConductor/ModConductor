namespace ModConductor.Persistence

open System
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.FilePlanning
open ModConductor.Platform

module internal RemasteredComponents =
    let private location (parts: string list) =
        match parts with
        | first :: rest when not rest.IsEmpty ->
            match first.ToLowerInvariant() with
            | "data" -> ComponentRoot.Data, rest
            | "paks" -> ComponentRoot.GameRoot, [ "OblivionRemastered"; "Content"; "Paks" ] @ rest
            | "movies" ->
                ComponentRoot.GameRoot, [ "OblivionRemastered"; "Content"; "Movies" ] @ rest
            | "obse" ->
                ComponentRoot.GameRoot, [ "OblivionRemastered"; "Binaries"; "Win64"; "OBSE" ] @ rest
            | "ue4ss" ->
                ComponentRoot.GameRoot,
                [ "OblivionRemastered"; "Binaries"; "Win64"; "ue4ss"; "Mods" ] @ rest
            | "gamesettings" ->
                ComponentRoot.GameRoot,
                [ "OblivionRemastered"; "Binaries"; "Win64"; "GameSettings" ] @ rest
            | "root" -> ComponentRoot.GameRoot, rest
            | "oblivionremastered" -> ComponentRoot.GameRoot, parts
            | _ -> ComponentRoot.Data, parts
        | _ -> ComponentRoot.Data, parts

    let private route (entry: ModConductor.ModLibrary.ManifestEntry) =
        let root, parts = location (LogicalPath.components entry.Path)

        LogicalPath.create parts
        |> Result.map (fun destination ->
            { Source = entry.Path
              Root = root
              Destination = destination
              Use = ComponentFileUse.Immutable })
        |> Result.mapError (fun _ -> RecoveryError.InvalidPlan)

    let read workspace gameRoot (sources: PlanSources) selected =
        sources.Profile.Mods
        |> List.filter (fun row -> selected |> Map.tryFind row.ModId |> Option.exists fst)
        |> List.fold
            (fun state row ->
                state
                |> Result.bind (fun result ->
                    match row.Version with
                    | None -> Error RecoveryError.Stale
                    | Some version ->
                        version.Entries
                        |> List.fold
                            (fun state entry ->
                                state
                                |> Result.bind (fun rows ->
                                    route entry |> Result.map (fun file -> file :: rows)))
                            (Ok [])
                        |> Result.bind (fun files ->
                            ComponentManifests.review
                                workspace
                                gameRoot
                                ModConductor.GameContexts.Skyrim.definition.TargetPolicy
                                { ModId = row.ModId
                                  Version = version
                                  Priority = row.Priority
                                  Files = List.rev files }
                            |> Result.mapError (fun _ -> RecoveryError.InvalidPlan))
                        |> Result.map (fun reviewed -> reviewed :: result)))
            (Ok [])
        |> Result.map List.rev
