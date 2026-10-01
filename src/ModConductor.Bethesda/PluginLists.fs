namespace ModConductor.Bethesda

open System
open System.Text
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module PluginLists =
    let reconcile ordering activation (facts: PluginOrderFacts) headers document loadOrder saved =
        let current = OrderRules.reconcileFor activation facts headers document saved

        if
            saved.IsSome
            || (ordering <> PluginOrdering.FileTime && activation <> PluginActivation.Plain)
        then
            current
        else
            let names =
                if ordering = PluginOrdering.FileTime then
                    headers |> List.map _.Name
                else
                    OrderDocument.namesFor PluginActivation.Plain loadOrder |> List.map fst

            let ranks =
                Collections.Generic.Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)

            names |> List.iteri (fun index name -> ranks.TryAdd(name, index) |> ignore)

            let rank name =
                match ranks.TryGetValue name with
                | true, index -> index
                | _ -> Int32.MaxValue

            let early, rest =
                current.Entries
                |> List.partition (fun row ->
                    List.exists
                        (fun name ->
                            String.Equals(name, row.Name, StringComparison.OrdinalIgnoreCase))
                        facts.Early)

            { current with
                Entries = early @ (rest |> List.sortBy (fun row -> rank row.Name)) }

    let loadOrder (order: PluginOrder) =
        order.Entries
        |> List.map _.Name
        |> fun names -> Encoding.UTF8.GetBytes(String.concat "\r\n" names + "\r\n")

    let timestamps root (order: PluginOrder) =
        order.Entries
        |> List.filter (fun row -> row.Enabled = Some true)
        |> List.mapi (fun index row ->
            let path =
                LogicalPath.create [ row.Name ] |> Result.defaultWith (string >> invalidOp)

            ({ Root = root; Path = path }: TargetFile),
            DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddDays(float index))
        |> Map.ofList
