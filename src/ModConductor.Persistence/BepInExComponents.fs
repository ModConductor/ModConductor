namespace ModConductor.Persistence

open ModConductor.BepInEx
open ModConductor.GameContexts
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentPlanning

module internal BepInExComponents =
    let read
        (database: StateDatabase)
        gameRoot
        (sources: PlanSources)
        selected
        (client: UnityLoader)
        =
        let role row =
            LibraryRows.find database.Connection null row.ModId
            |> Option.map (fun row -> row.Entry.Metadata.Source)
            |> Option.defaultValue ""
            |> fun source ->
                LoaderPackage.role
                    client
                    source
                    (row.Version |> Option.map _.Entries |> Option.defaultValue [] |> Seq.map _.Path)

        let add (rows: ReviewedComponent list, working) row =
            let role = role row

            PackageRoutes.review
                sources.Stamp.WorkspaceId
                gameRoot
                (GameCatalog.forGame sources.Context.Binding.Value.GameId).TargetPolicy
                client.Backend
                role
                row
            |> Result.mapError RecoveryError.Unavailable
            |> Result.map (fun reviewed ->
                let loader =
                    match role with
                    | PackageRole.Loader _ -> true
                    | _ -> false

                let reviewed =
                    if loader && working then
                        { reviewed with Writable = [] }
                    else
                        reviewed

                reviewed :: rows, working || loader)

        sources.Profile.Mods
        |> List.filter (fun row -> selected |> Map.tryFind row.ModId |> Option.exists fst)
        |> List.fold
            (fun state row -> state |> Result.bind (fun previous -> add previous row))
            (Ok([], false))
        |> Result.map (fst >> List.rev)
