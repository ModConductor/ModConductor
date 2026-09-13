namespace ModConductor.BundleInstallation

open System
open System.IO
open ModConductor.ArchiveInspection
open ModConductor.Platform

module Discovery =
    let candidates (manifest: ArchiveManifest) =
        let files = manifest.Entries |> List.filter (fun e -> not e.Directory)

        let rec at (prefix: string list) =
            let underneath =
                files
                |> List.choose (fun e ->
                    let p = LogicalPath.components e.Path

                    if p.Length > prefix.Length && List.take prefix.Length p = prefix then
                        Some(e, List.skip prefix.Length p)
                    else
                        None)

            let direct =
                underneath
                |> List.choose (fun (e, p) ->
                    if
                        p.Length = 1
                        && List.contains
                            (Path.GetExtension(p.Head).ToLowerInvariant())
                            [ ".zip"; ".7z"; ".rar" ]
                    then
                        Some
                            { Index = e.Index
                              Path = e.Path
                              Length = e.Size }
                    else
                        None)

            if not direct.IsEmpty then
                direct
            else
                let folders =
                    underneath
                    |> List.choose (fun (_, p) -> if p.Length > 1 then Some p.Head else None)
                    |> List.distinct

                match folders with
                | [ folder ] when prefix.IsEmpty -> at [ folder ]
                | _ -> []

        at []
        |> List.sortBy (fun e -> (LogicalPath.display e.Path).Normalize().ToUpperInvariant())
