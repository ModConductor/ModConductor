namespace ModConductor.ArchiveInstallation

open System
open System.Collections.Generic
open ModConductor.ArchiveInspection
open ModConductor.Platform

module Destinations =
    let private refuse message = raise (InstallationException message)

    let policy =
        { TargetPolicy.windows with
            Unicode = CanonicalComposition }

    let key path =
        (TargetPolicy.key policy path).ToUpperInvariant()

    let validate (paths: LogicalPath list) =
        let seen = Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        let mutable characters = 0

        for path in paths do
            characters <- characters + (LogicalPath.display path).Length
            let parts = LogicalPath.components path

            if characters > ArchiveLimits.Default.NameCharacters then
                refuse "The installation contains too much destination path data."

            if
                parts.Length > ArchiveLimits.Default.Depth
                || (LogicalPath.display path).Length > ArchiveLimits.Default.PathCharacters
                || not (TargetPolicy.problems policy path).IsEmpty
            then
                refuse
                    "A destination cannot be used in this mod. Choose a relative Windows-compatible path."

            for count in 1 .. parts.Length do
                let target =
                    LogicalPath.create (List.take count parts)
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid parent path.")

                let name, spelling = key target, LogicalPath.display target

                match seen.TryGetValue name with
                | true, original when original <> spelling ->
                    refuse
                        "Two destinations use conflicting names. Change a destination or exclude a file."
                | _ -> seen[name] <- spelling

                if seen.Count > ArchiveLimits.Default.Entries then
                    refuse "The installation contains too many file and folder entries."

        let targets = paths |> List.map key |> Set.ofList

        if targets.Count <> paths.Length then
            refuse "Two files have the same destination. Change a destination or exclude a file."

        for path in paths do
            let parts = LogicalPath.components path

            for count in 1 .. parts.Length - 1 do
                let parent =
                    LogicalPath.create (List.take count parts)
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid parent path.")

                if targets.Contains(key parent) then
                    refuse "A destination is both a file and a folder."
