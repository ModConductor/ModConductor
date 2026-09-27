namespace ModConductor.ArchiveInstallation

open System
open System.Collections.Generic
open ModConductor.ArchiveInspection
open ModConductor.Platform

module Destinations =
    let policy =
        { TargetPolicy.windows with
            Unicode = CanonicalComposition }

    let key path =
        (TargetPolicy.key policy path).ToUpperInvariant()

    let private parent parts count =
        LogicalPath.create (List.take count parts)
        |> Result.mapError (fun _ ->
            "A destination cannot be used in this mod. Choose a relative Windows-compatible path.")

    let private checkPrefixes (seen: Dictionary<string, string>) path =
        let parts = LogicalPath.components path

        [ 1 .. parts.Length ]
        |> List.fold
            (fun outcome count ->
                outcome
                |> Result.bind (fun () ->
                    parent parts count
                    |> Result.bind (fun target ->
                        let name, spelling = key target, LogicalPath.display target

                        match seen.TryGetValue name with
                        | true, original when original <> spelling ->
                            Error
                                "Two destinations use conflicting names. Change a destination or exclude a file."
                        | _ ->
                            seen[name] <- spelling

                            if seen.Count > ArchiveLimits.Default.Entries then
                                Error
                                    "The installation contains too many file and folder entries."
                            else
                                Ok())))
            (Ok())

    let private checkPath seen characters path =
        let characters = characters + (LogicalPath.display path).Length
        let parts = LogicalPath.components path

        if characters > ArchiveLimits.Default.NameCharacters then
            Error "The installation contains too much destination path data."
        elif
            parts.Length > ArchiveLimits.Default.Depth
            || (LogicalPath.display path).Length > ArchiveLimits.Default.PathCharacters
            || not (TargetPolicy.problems policy path).IsEmpty
        then
            Error
                "A destination cannot be used in this mod. Choose a relative Windows-compatible path."
        else
            checkPrefixes seen path |> Result.map (fun () -> characters)

    let private checkParents targets path =
        let parts = LogicalPath.components path

        [ 1 .. parts.Length - 1 ]
        |> List.fold
            (fun outcome count ->
                outcome
                |> Result.bind (fun () ->
                    parent parts count
                    |> Result.bind (fun parent ->
                        if targets |> Set.contains (key parent) then
                            Error "A destination is both a file and a folder."
                        else
                            Ok())))
            (Ok())

    let validate (paths: LogicalPath list) =
        let seen = Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)

        paths
        |> List.fold
            (fun outcome path -> outcome |> Result.bind (fun count -> checkPath seen count path))
            (Ok 0)
        |> Result.bind (fun _ ->
            let targets = paths |> List.map key |> Set.ofList

            if targets.Count <> paths.Length then
                Error
                    "Two files have the same destination. Change a destination or exclude a file."
            else
                paths
                |> List.fold
                    (fun outcome path ->
                        outcome |> Result.bind (fun () -> checkParents targets path))
                    (Ok()))
