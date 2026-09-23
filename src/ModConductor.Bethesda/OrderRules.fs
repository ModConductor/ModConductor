namespace ModConductor.Bethesda

open System
open System.Collections.Generic

module OrderRules =
    let private same a b =
        String.Equals(a, b, StringComparison.OrdinalIgnoreCase)

    let private set (names: string seq) =
        HashSet<string>(names, StringComparer.OrdinalIgnoreCase)

    let baseFiles =
        [ "Skyrim.esm"
          "Update.esm"
          "Dawnguard.esm"
          "HearthFires.esm"
          "Dragonborn.esm" ]

    let mandatoryFiles = [ "Skyrim.esm"; "Update.esm" ]

    let requirement (facts: PluginOrderFacts) name =
        facts.Required
        |> List.tryPick (fun (required, reason) -> if same required name then Some reason else None)

    let private locked (rows: PluginSetting list) =
        let mutable result = rows
        let active = rows |> List.filter (fun row -> row.Enabled = Some true) |> List.length

        for row in
            rows
            |> List.filter (fun row -> row.Enabled = Some true && row.LockedIndex.IsSome)
            |> List.sortBy _.LockedIndex do
            let wanted = min row.LockedIndex.Value (active - 1)
            let rest = result |> List.filter (fun value -> not (same row.Name value.Name))
            let mutable enabled = 0
            let mutable position = 0

            while position < rest.Length && enabled < wanted do
                if rest[position].Enabled = Some true then
                    enabled <- enabled + 1

                position <- position + 1

            result <- List.take position rest @ [ row ] @ List.skip position rest

        result

    let reconcile
        (facts: PluginOrderFacts)
        (headers: PluginEntry list)
        document
        (saved: PluginOrder option)
        =
        let found = headers |> List.map _.Name |> set

        let early =
            facts.Early
            |> List.filter found.Contains
            |> List.distinctBy _.ToUpperInvariant()

        let required = facts.Required |> List.map fst |> set
        let defaultEnabled = set facts.DefaultEnabled

        let initial =
            match saved with
            | Some order -> order
            | None ->
                let listed =
                    OrderDocument.names document
                    |> List.filter (fun (name, _) -> found.Contains name)

                let groups = Dictionary<string, ResizeArray<bool>>(StringComparer.OrdinalIgnoreCase)
                let sequence = ResizeArray<string>()

                for name, enabled in listed do
                    match groups.TryGetValue name with
                    | true, values -> values.Add enabled
                    | _ ->
                        sequence.Add name
                        groups.Add(name, ResizeArray([ enabled ]))

                { Document = document
                  Entries =
                    sequence
                    |> Seq.map (fun name ->
                        { Name = name
                          Enabled =
                            if groups[name].Count = 1 then
                                Some(groups[name][0])
                            else
                                None
                          LockedIndex = None })
                    |> Seq.toList }

        let existing = initial.Entries |> List.map _.Name |> set

        let rows =
            initial.Entries
            @ (headers
               |> List.filter (fun row -> not (existing.Contains row.Name))
               |> List.map (fun row ->
                   { Name = row.Name
                     Enabled = Some(defaultEnabled.Contains row.Name)
                     LockedIndex = None }))
            |> List.map (fun row ->
                if required.Contains row.Name then
                    { row with Enabled = Some true }
                else
                    row)

        let earlySet = set early

        { initial with
            Entries =
                (early
                 |> List.map (fun name -> rows |> List.find (fun row -> same name row.Name)))
                @ (rows |> List.filter (fun row -> not (earlySet.Contains row.Name))) }

    let inspect (facts: PluginOrderFacts) (headers: PluginEntry list) (order: PluginOrder) =
        let issues = ResizeArray<PluginOrderIssue>()

        let problem name detail =
            issues.Add { Name = name; Detail = detail }

        let index = Dictionary<string, PluginEntry>(StringComparer.OrdinalIgnoreCase)

        for header in headers do
            index.Add(header.Name, header)

        let active =
            order.Entries
            |> List.filter (fun row -> row.Enabled = Some true && index.ContainsKey row.Name)

        let positions = Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
        active |> List.iteri (fun position row -> positions.Add(row.Name, position))
        let mutable full = 0
        let mutable light = 0
        let waiting = HashSet<string>(StringComparer.OrdinalIgnoreCase)

        for required in mandatoryFiles do
            if not (index.ContainsKey required) then
                problem (Some required) (required + " is missing.")

        for row in order.Entries do
            if row.Enabled.IsNone then
                problem
                    (Some row.Name)
                    ("Choose whether to enable " + row.Name + "; the game list repeats it.")

            if not (OrderDocument.canWriteName row.Name) then
                problem
                    (Some row.Name)
                    (row.Name + " cannot be written in the game's plugin-list encoding.")

        for row in active do
            let entry = index[row.Name]

            match entry.Header with
            | Error _ ->
                problem (Some row.Name) ("The active header for " + row.Name + " cannot be used.")
            | Ok header ->
                match header.Kind with
                | PluginKind.LightMaster
                | PluginKind.LightPlugin -> light <- light + 1
                | PluginKind.Master
                | PluginKind.Plugin -> full <- full + 1

                let master = header.Kind = PluginKind.Master || header.Kind = PluginKind.LightMaster

                if master then
                    for required in header.Masters do
                        waiting.Remove required |> ignore

                    if waiting.Count > 0 then
                        problem
                            (Some row.Name)
                            (row.Name
                             + " must load before ordinary plugins that it does not require.")
                else
                    waiting.Add row.Name |> ignore

                for required in header.Masters do
                    match positions.TryGetValue required with
                    | false, _ ->
                        problem
                            (Some row.Name)
                            (required + " must be enabled for " + row.Name + ".")
                    | true, before when before >= positions[row.Name] ->
                        problem (Some row.Name) (required + " must load before " + row.Name + ".")
                    | _ -> ()

                if entry.Ambiguity.IsSome then
                    problem (Some row.Name) (row.Name + " has ambiguous file sources.")

        let early =
            facts.Early
            |> List.filter positions.ContainsKey
            |> List.distinctBy _.ToUpperInvariant()

        early
        |> List.iteri (fun position name ->
            if positions[name] <> position then
                problem (Some name) (name + " has a required early load position."))

        for row in active do
            match row.LockedIndex with
            | Some requested when positions[row.Name] <> min requested (active.Length - 1) ->
                problem
                    (Some row.Name)
                    ("The locked load position for " + row.Name + " cannot be kept.")
            | _ -> ()

        let fullLimit = if light > 0 then 254 else 255

        if full > fullLimit then
            problem
                None
                ("Too many full plugins enabled: "
                 + string full
                 + "; limit "
                 + string fullLimit
                 + ".")

        if light > 4096 then
            problem None "Too many light plugins enabled. The limit is 4096."

        { Order = order
          Issues = List.ofSeq issues |> List.distinct
          Full = full
          Light = light
          FullLimit = fullLimit }

    let change (facts: PluginOrderFacts) (headers: PluginEntry list) (order: PluginOrder) change =
        let names =
            match change with
            | PluginOrderChange.Enable(names, _)
            | PluginOrderChange.Move(names, _)
            | PluginOrderChange.Lock(names, _)
            | PluginOrderChange.Replace names -> names

        let selected = set names
        let known = order.Entries |> List.map _.Name |> set
        let early = set facts.Early
        let required = facts.Required |> List.map fst |> set

        let dependant =
            match change with
            | PluginOrderChange.Enable(_, false) ->
                headers
                |> List.tryPick (fun entry ->
                    if
                        not (selected.Contains entry.Name)
                        && order.Entries
                           |> List.exists (fun row ->
                               same row.Name entry.Name && row.Enabled = Some true)
                    then
                        match entry.Header with
                        | Ok header ->
                            header.Masters
                            |> List.tryFind selected.Contains
                            |> Option.map (fun master -> master, entry.Name)
                        | Error _ -> None
                    else
                        None)
            | _ -> None

        if
            selected.Count = 0
            || selected |> Seq.exists (known.Contains >> not)
            || (match change with
                | PluginOrderChange.Replace names ->
                    names.Length <> order.Entries.Length || selected.Count <> known.Count
                | _ -> false)
        then
            Error "Select current plugins first."
        else
            match change with
            | PluginOrderChange.Enable(_, false) when selected |> Seq.exists required.Contains ->
                Error "Required plugins cannot be disabled."
            | PluginOrderChange.Enable(_, false) when dependant.IsSome ->
                let master, plugin = dependant.Value
                Error(plugin + " requires " + master + ". Disable " + plugin + " first.")
            | PluginOrderChange.Move _ when
                order.Entries
                |> List.exists (fun row ->
                    selected.Contains row.Name
                    && (early.Contains row.Name
                        || (row.Enabled = Some true && row.LockedIndex.IsSome)))
                ->
                Error "Required or locked plugins cannot be moved."
            | PluginOrderChange.Lock(_, true) when
                order.Entries
                |> List.exists (fun row ->
                    selected.Contains row.Name
                    && (early.Contains row.Name || row.Enabled <> Some true))
                ->
                Error "Only enabled, non-required plugins can have a locked load position."
            | _ ->
                let rows =
                    match change with
                    | PluginOrderChange.Enable(_, enabled) ->
                        order.Entries
                        |> List.map (fun row ->
                            if selected.Contains row.Name then
                                { row with Enabled = Some enabled }
                            else
                                row)
                        |> locked
                    | PluginOrderChange.Lock(_, enabled) ->
                        let mutable position = -1

                        order.Entries
                        |> List.map (fun row ->
                            if row.Enabled = Some true then
                                position <- position + 1

                            if selected.Contains row.Name then
                                { row with
                                    LockedIndex = if enabled then Some position else None }
                            else
                                row)
                    | PluginOrderChange.Move(_, up) ->
                        let rows = List.toArray order.Entries

                        let indices =
                            if up then
                                [ 1 .. rows.Length - 1 ]
                            else
                                [ rows.Length - 2 .. -1 .. 0 ]

                        for index in indices do
                            let next = if up then index - 1 else index + 1

                            if
                                selected.Contains rows[index].Name
                                && not (selected.Contains rows[next].Name)
                                && not (early.Contains rows[next].Name)
                            then
                                let value = rows[next]
                                rows[next] <- rows[index]
                                rows[index] <- value

                        List.ofArray rows |> locked
                    | PluginOrderChange.Replace names ->
                        let index =
                            Dictionary<string, PluginSetting>(StringComparer.OrdinalIgnoreCase)

                        order.Entries |> List.iter (fun row -> index.Add(row.Name, row))
                        names |> List.map (fun name -> index[name])

                Ok { order with Entries = rows }
