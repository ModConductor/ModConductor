namespace ModConductor.ArchiveInspection

open System
open System.Collections.Generic
open ModConductor.Platform

module internal ArchiveNames =
    let refuse message =
        raise (ArchiveInspectionException message)

    let policy =
        { TargetPolicy.windows with
            Unicode = CanonicalComposition }

    let parse limits directory (name: string) =
        if String.IsNullOrEmpty name || name.Length > limits.PathCharacters then
            refuse "An archive path is empty or too long."

        let name = name.Replace('\\', '/')

        let name =
            if directory && name.EndsWith('/') then
                name.Substring(0, name.Length - 1)
            else
                name

        if name.StartsWith('/') || name |> Seq.exists Char.IsControl then
            refuse "The archive contains an unsafe path."

        let parts = name.Split('/') |> Array.toList

        if parts.Length > limits.Depth then
            refuse "An archive path has too many folder levels."

        let path =
            LogicalPath.create parts
            |> Result.defaultWith (fun _ -> refuse "The archive contains an unsafe path.")

        if not (TargetPolicy.problems policy path).IsEmpty then
            refuse "The archive contains a filename that cannot be used on Windows."

        path

    let validate (limits: ArchiveLimits) (entries: ArchiveEntry list) =
        let names = Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase)

        for entry in entries do
            let key = TargetPolicy.key policy entry.Path

            if not (names.TryAdd(key, entry.Directory)) then
                refuse "The archive contains duplicate or conflicting paths."

        let spellings = Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)

        for entry in entries do
            let parts = LogicalPath.components entry.Path

            for count in 1 .. parts.Length do
                let componentPath =
                    parts
                    |> List.take count
                    |> LogicalPath.create
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid checked path")

                let key = TargetPolicy.key policy componentPath
                let original = LogicalPath.display componentPath

                match spellings.TryGetValue key with
                | true, value when value <> original ->
                    refuse "The archive contains duplicate or conflicting paths."
                | _ -> spellings[key] <- original

                if spellings.Count > limits.Entries then
                    refuse "The archive contains too many file and folder entries."

            for count in 1 .. parts.Length - 1 do
                let parent =
                    parts
                    |> List.take count
                    |> LogicalPath.create
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid checked path")

                match names.TryGetValue(TargetPolicy.key policy parent) with
                | true, false -> refuse "An archive file also names a folder."
                | _ -> ()
