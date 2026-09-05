namespace ModConductor.Platform

open System
open System.IO
open System.Collections.Generic

module internal Containment =
    let inside (root: string) (path: string) =
        String.Equals(root, path, StringComparison.Ordinal)
        || path.StartsWith(
            (if Path.EndsInDirectorySeparator root then
                 root
             else
                 root + string Path.DirectorySeparatorChar),
            StringComparison.Ordinal
        )

    let resolve (root: SelectedRoot) path =
        let anchor = HostPath.value root.Resolved
        let selected = HostPath.value root.Selected |> Path.TrimEndingDirectorySeparator
        let seen = HashSet<string>(StringComparer.Ordinal)
        let maxLinks = if OperatingSystem.IsWindows() then 63 else 40

        let parts (value: string) =
            value.Split(
                [| Path.DirectorySeparatorChar; Path.AltDirectorySeparatorChar |],
                StringSplitOptions.RemoveEmptyEntries
            )
            |> Array.toList

        let relativeTarget target =
            [ anchor; selected ]
            |> List.tryPick (fun prefix ->
                if inside prefix target then
                    Some(parts (target.Substring(prefix.Length)))
                else
                    None)

        let rec walk current remaining hops =
            match remaining with
            | [] ->
                match Native.canonical current with
                | Ok canonical when inside anchor canonical ->
                    Native.facts canonical |> Result.map (fun facts -> canonical, facts)
                | Ok _ -> Error OutsideRoot
                | Error problem -> Error problem
            | "." :: rest -> walk current rest hops
            | ".." :: rest ->
                if current = anchor then
                    Error OutsideRoot
                else
                    walk (Path.GetDirectoryName current) rest hops
            | name :: rest ->
                let candidate = Path.Combine(current, name)

                match Native.facts candidate with
                | Error problem -> Error problem
                | Ok facts ->
                    match facts.Kind with
                    | EntryKind.Other -> Error UnsupportedEntry
                    | EntryKind.RegularFile when not (List.isEmpty rest) ->
                        Error FileDirectoryConflict
                    | EntryKind.RegularFile
                    | EntryKind.Directory -> walk candidate rest hops
                    | EntryKind.Link ->
                        if
                            hops >= maxLinks
                            || not (seen.Add(candidate + "\000" + String.Join("\000", rest)))
                        then
                            Error LinkCycle
                        else
                            let attributes = File.GetAttributes candidate

                            let info: FileSystemInfo =
                                if attributes.HasFlag FileAttributes.Directory then
                                    DirectoryInfo(candidate)
                                else
                                    FileInfo(candidate)

                            let target = info.LinkTarget

                            if isNull target then
                                Error UnsupportedEntry
                            elif Path.IsPathFullyQualified target then
                                match relativeTarget target with
                                | Some components -> walk anchor (components @ rest) (hops + 1)
                                | None -> Error OutsideRoot
                            elif Path.IsPathRooted target then
                                Error OutsideRoot
                            else
                                walk current (parts target @ rest) (hops + 1)

        if not (inside anchor path) then
            Error OutsideRoot
        else
            walk anchor (parts (path.Substring(anchor.Length))) 0

module RootSelection =
    let select path =
        try
            match Native.canonical (HostPath.value path) with
            | Error problem -> Error problem
            | Ok canonical ->
                match Native.facts canonical, HostPath.create canonical with
                | Ok facts, Ok resolved when facts.Kind = EntryKind.Directory ->
                    Ok
                        { Selected = path
                          Resolved = resolved
                          Facts = facts }
                | Ok _, _ -> Error FileDirectoryConflict
                | Error problem, _ -> Error problem
        with
        | :? IOException as error -> Error(AccessFailure error.Message)
        | :? UnauthorizedAccessException as error -> Error(AccessFailure error.Message)

    let path (root: SelectedRoot) = root.Resolved
    let facts (root: SelectedRoot) = root.Facts

module PathPreflight =
    let inspect limits policy (root: SelectedRoot) =
        if
            limits.Candidates < 1
            || limits.Diagnostics < 1
            || limits.Depth < 1
            || limits.Depth > 256
        then
            invalidArg "limits" "Use positive inspection limits and a depth of at most 256."

        let entries = ResizeArray<PathEntry>()
        let diagnostics = ResizeArray<PathDiagnostic>()
        let identities = Dictionary<string, PathEntry>(TargetPolicy.comparer policy)
        let canonical = HostPath.value root.Resolved

        let mutable visited = 0
        let mutable limited = false

        let diagnose path problem =
            if diagnostics.Count < limits.Diagnostics then
                diagnostics.Add { Path = path; Problem = problem }
            else
                limited <- true

        let rec visit components physical ancestorPaths ancestorIds depth =
            let display = String.Join("/", (components: string list))

            if depth > limits.Depth || visited >= limits.Candidates then
                limited <- true
            else
                try
                    use children = (Directory.EnumerateFileSystemEntries physical).GetEnumerator()

                    while visited < limits.Candidates && children.MoveNext() do
                        let child = children.Current
                        visited <- visited + 1
                        let names = components @ [ Path.GetFileName child ]
                        let shown = String.Join("/", names)

                        match
                            LogicalPath.create names, Native.facts child, HostPath.create child
                        with
                        | Ok logical, Ok sourceFacts, Ok host ->
                            match Containment.resolve root child with
                            | Error problem -> diagnose shown problem
                            | Ok(resolved, facts) ->
                                let resolvedHost =
                                    HostPath.create resolved
                                    |> Result.defaultWith (fun error -> invalidOp error)

                                let entry =
                                    { Logical = logical
                                      Host = host
                                      Resolved = resolvedHost
                                      Kind = sourceFacts.Kind
                                      TargetKind = facts.Kind
                                      Facts = facts }

                                entries.Add entry
                                let problems = TargetPolicy.problems policy logical

                                if not (List.isEmpty problems) then
                                    diagnose shown (InvalidTargetName problems)

                                if not (List.contains InvalidUnicode problems) then
                                    let key = TargetPolicy.key policy logical

                                    match identities.TryGetValue key with
                                    | true, existing ->
                                        diagnose
                                            shown
                                            (if existing.TargetKind <> entry.TargetKind then
                                                 FileDirectoryConflict
                                             else
                                                 TargetCollision)
                                    | false, _ -> identities.Add(key, entry)

                                if facts.Kind = EntryKind.Directory then
                                    let duplicateId =
                                        match facts.File with
                                        | Known id -> Set.contains id ancestorIds
                                        | Unknown _ -> false

                                    if Set.contains resolved ancestorPaths || duplicateId then
                                        diagnose shown LinkCycle
                                    else
                                        let ids =
                                            match facts.File with
                                            | Known id -> Set.add id ancestorIds
                                            | Unknown _ -> ancestorIds

                                        visit
                                            names
                                            resolved
                                            (Set.add resolved ancestorPaths)
                                            ids
                                            (depth + 1)
                        | Error problem, _, _ -> diagnose shown (InvalidTargetName [ problem ])
                        | _, Error problem, _ -> diagnose shown problem
                        | _, _, Error message -> diagnose shown (AccessFailure message)
                with
                | :? IOException as error -> diagnose display (AccessFailure error.Message)
                | :? UnauthorizedAccessException as error ->
                    diagnose display (AccessFailure error.Message)

        let initialIds =
            match root.Facts.File with
            | Known id -> Set.singleton id
            | Unknown _ -> Set.empty

        visit [] canonical (Set.singleton canonical) initialIds 0

        if limited || visited >= limits.Candidates then
            if diagnostics.Count >= limits.Diagnostics then
                diagnostics.RemoveAt(diagnostics.Count - 1)

            diagnostics.Add { Path = ""; Problem = LimitExceeded }

        { Root = root
          Entries = List.ofSeq entries
          Diagnostics = List.ofSeq diagnostics }
