namespace ModConductor.ProfileGameData

open System
open ModConductor.Bethesda

module internal SaveDiagnostics =
    let private unavailable = [], Some "Refresh plugins to check this save."

    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private source (value: PluginSource) =
        if value.Version = "" then
            value.Name
        else
            value.Name + " " + value.Version

    let private issue (order: ProfilePluginOrder) name : Result<SavePluginIssue option, unit> =
        let entries =
            order.Headers.Entries |> List.filter (fun entry -> same entry.Name name)

        let settings =
            order.View.Order.Entries |> List.filter (fun setting -> same setting.Name name)

        if
            entries
            |> List.exists (fun entry -> entry.Winner.IsNone || entry.Ambiguity.IsSome)
            || entries.Length > 1
            || settings.Length > 1
            || settings |> List.exists (fun setting -> setting.Enabled.IsNone)
        then
            Error()
        else
            match entries, settings with
            | [], _ ->
                Ok(
                    Some(
                        { Name = name
                          State = SavePluginState.Missing
                          Source = None }
                        : SavePluginIssue
                    )
                )
            | [ entry ], [ setting ] ->
                match setting.Enabled with
                | Some false ->
                    Ok(
                        Some(
                            { Name = name
                              State = SavePluginState.Inactive
                              Source = entry.Winner |> Option.map source }
                            : SavePluginIssue
                        )
                    )
                | Some true -> Ok None
                | None -> Error()
            | _ -> Error()

    let check (order: ProfilePluginOrder) (metadata: SkyrimSaveMetadata) =
        if
            order.Headers.Stale
            || not order.Headers.Problems.IsEmpty
            || order.Pending
            || order.ExternalChanged
            || order.Problem.IsSome
        then
            unavailable
        else
            let resolved =
                metadata.FullPlugins @ metadata.LightPlugins
                |> List.distinctBy _.ToUpperInvariant()
                |> List.map (issue order)

            if resolved |> List.exists Result.isError then
                unavailable
            else
                resolved |> List.choose (Result.toOption >> Option.flatten), None
