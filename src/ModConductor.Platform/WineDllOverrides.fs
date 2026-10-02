namespace ModConductor.Platform

open System
open System.IO

module WineDllOverrides =
    let withNative (existing: string) (proxy: string) =
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
