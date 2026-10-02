namespace ModConductor.Unreal

open System
open System.IO
open ModConductor.GameContexts

module Launch =
    let wineOverrides (existing: string) (proxy: string) =
        let selected = Path.GetFileNameWithoutExtension proxy

        let retained =
            (if isNull existing then "" else existing)
                .Split(';', StringSplitOptions.RemoveEmptyEntries)
            |> Array.choose (fun entry ->
                let pair = entry.Split('=', 2)

                let names =
                    pair[0].Split(',')
                    |> Array.filter (fun name ->
                        not (name.Trim().Equals(selected, StringComparison.OrdinalIgnoreCase)))

                if names.Length = 0 then
                    None
                else
                    Some(String.concat "," names + (if pair.Length = 2 then "=" + pair[1] else "")))

        String.concat ";" (Array.toList retained @ [ selected + "=n,b" ])

    let arguments (definition: GameDefinition) (client: UnrealClient) root windows =
        let file = Path.Combine(root, client.LogDirectory, "game.log")

        client.Arguments
        @ [ "-ABSLOG=" + (if windows then file else "Z:" + file.Replace('/', '\\')) ]

    let environment client enabled platform existing =
        match client.Loader.Mechanism, enabled, platform with
        | UnrealModMechanism.UE4SS layout, true, ContextPlatform.Proton
        | UnrealModMechanism.UE4SS layout, true, ContextPlatform.Wine ->
            [ "WINEDLLOVERRIDES", Some(wineOverrides existing layout.Proxy) ]
        | _ -> []
