namespace ModConductor.ProtonContexts

open ModConductor.GameContexts
open ModConductor.SteamDiscovery

module GameDiscovery =
    let scan (definition: GameDefinition) roots token =
        let reports =
            definition.SteamAppIds |> List.map (fun app -> Discovery.scan app roots token)

        { AppId = definition.SteamAppId
          Roots = reports |> List.collect _.Roots |> List.distinct
          Candidates =
            reports
            |> List.collect _.Candidates
            |> List.groupBy _.Id
            |> List.map (fun (_, entries) ->
                { entries.Head with
                    Origins = entries |> List.collect _.Origins |> List.distinct })
          Diagnostics = reports |> List.collect _.Diagnostics |> List.distinct
          Complete = reports |> List.forall _.Complete }
