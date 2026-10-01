namespace ModConductor.Bethesda

open System
open System.IO

module BlueprintPlugins =
    let private prefix = "BlueprintShips-"

    let isNamed (name: string) =
        name.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)

    let isBlueprint (entry: PluginEntry) =
        isNamed entry.Name
        || entry.Header |> Result.exists (fun header -> header.Flags &&& 0x800u <> 0u)

    let synchronize (order: PluginOrder) =
        let ordinary, paired =
            order.Entries |> List.partition (fun row -> not (isNamed row.Name))

        let attach (row: PluginSetting) =
            let stem = Path.GetFileNameWithoutExtension(row.Name.Substring prefix.Length)

            let parent =
                ordinary
                |> List.tryFind (fun item ->
                    Path
                        .GetFileNameWithoutExtension(item.Name)
                        .Equals(stem, StringComparison.OrdinalIgnoreCase))

            { row with
                Enabled = Some(parent |> Option.exists (fun parent -> parent.Enabled = Some true))
                LockedIndex = None }

        { order with
            Entries = ordinary @ (paired |> List.map attach) }
