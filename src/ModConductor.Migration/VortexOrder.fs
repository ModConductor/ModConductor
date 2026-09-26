namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.Text.Json
open ModConductor.ModSelection

module internal VortexOrder =
    open VortexSource
    open VortexJson
    open VortexMods

    let private validateRules (mods: (ParsedMod * bool) list) =
        let known = mods |> List.map (fun (item, _) -> item.SourceId) |> Set.ofList
        let edges = ResizeArray<string * string>()

        for item, _ in mods do
            match item.Rules with
            | None -> ()
            | Some rules ->
                for rule in arrayItems "mod rules" rules do
                    let relation = text "type" rule

                    if relation <> "before" && relation <> "after" then
                        unsupported ("The mod " + item.Metadata.Name + " uses an unsupported rule.")

                    if tryBoolean "ignored" rule = Some true then
                        unsupported (
                            "The mod " + item.Metadata.Name + " has an ignored ordering rule."
                        )

                    let reference = property "reference" rule
                    let target = text "id" reference

                    if not (known.Contains target) then
                        unsupported (
                            "The mod " + item.Metadata.Name + " has a rule for a missing mod."
                        )

                    if target = item.SourceId then
                        unsupported ("The mod " + item.Metadata.Name + " has a rule cycle.")

                    if relation = "before" then
                        edges.Add(item.SourceId, target)
                    else
                        edges.Add(target, item.SourceId)

        List.ofSeq edges

    let private explicitOrder (persistent: JsonElement) (profileId: string) (known: Set<string>) =
        match tryProperty "loadOrder" persistent with
        | None -> None
        | Some all ->
            match tryProperty profileId all with
            | None -> None
            | Some value when value.ValueKind = JsonValueKind.Object ->
                let positions =
                    objectEntries "load order" value
                    |> List.map (fun entry ->
                        if not (known.Contains entry.Name) then
                            unsupported "The Vortex load order contains an unknown mod."

                        if tryBoolean "external" entry.Value = Some true then
                            unsupported "The Vortex load order contains an externally managed mod."

                        let position = int64Value "pos" entry.Value
                        entry.Name, position)

                if positions |> List.map snd |> Set.ofList |> Set.count <> positions.Length then
                    invalid "The Vortex load order contains duplicate positions."

                Some(positions |> List.sortBy (fun (id, position) -> position, id) |> List.map fst)
            | Some value when value.ValueKind = JsonValueKind.Array ->
                let ids =
                    arrayItems "load order" value
                    |> List.map (fun entry ->
                        match tryText "modId" entry with
                        | Some id when known.Contains id -> id
                        | Some _ -> unsupported "The Vortex load order contains an unknown mod."
                        | None -> unsupported "The Vortex load order contains an unmanaged entry.")

                if ids |> Set.ofList |> Set.count <> ids.Length then
                    invalid "The Vortex load order contains a mod more than once."

                Some ids
            | Some _ -> invalid "The Vortex load order is invalid."

    let private ruleOrder (ids: string list) (edges: (string * string) list) =
        let outgoing = Dictionary<string, ResizeArray<string>>(StringComparer.Ordinal)
        let incoming = Dictionary<string, int>(StringComparer.Ordinal)

        for id in ids do
            outgoing.Add(id, ResizeArray())
            incoming.Add(id, 0)

        for before, after in edges |> List.distinct do
            outgoing[before].Add after
            incoming[after] <- incoming[after] + 1

        let ready = SortedSet<string>(StringComparer.Ordinal)

        for id in ids do
            if incoming[id] = 0 then
                ready.Add id |> ignore

        let ordered = ResizeArray<string>()

        while ready.Count > 0 do
            let current = ready.Min
            ready.Remove current |> ignore
            ordered.Add current

            for next in
                outgoing[current]
                |> Seq.sortWith (fun left right -> StringComparer.Ordinal.Compare(left, right)) do
                incoming[next] <- incoming[next] - 1

                if incoming[next] = 0 then
                    ready.Add next |> ignore

        if ordered.Count <> ids.Length then
            unsupported "The Vortex mod rules contain a cycle."

        List.ofSeq ordered

    let orderedMods (persistent: JsonElement) (profileId: string) (mods: (ParsedMod * bool) list) =
        let edges = validateRules mods
        let ids = mods |> List.map (fun (item, _) -> item.SourceId)
        let known = Set.ofList ids
        let rules = ruleOrder ids edges

        let order =
            match explicitOrder persistent profileId known with
            | Some listed ->
                listed
                @ (ids |> List.filter (fun id -> not (List.contains id listed)) |> List.sort)
            | None -> rules

        let byId =
            mods |> Seq.map (fun (item, enabled) -> item.SourceId, (item, enabled)) |> dict

        order
        |> List.mapi (fun priority id ->
            let item, enabled = byId[id]

            { Id = item.Id
              Priority = priority
              Enabled = Some enabled })
