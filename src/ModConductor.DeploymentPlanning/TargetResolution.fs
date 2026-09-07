namespace ModConductor.DeploymentPlanning

open System
open System.Collections.Generic
open ModConductor.Platform

module internal TargetResolution =
    let resolve
        (roots: Dictionary<Guid, TargetPolicy>)
        contributions
        (issues: ResizeArray<PlanningIssue>)
        =
        let resolved = ResizeArray<ResolvedFile>()
        let directories = ResizeArray<TargetFile>()

        for KeyValue(root, policy) in roots do
            let files = PlanningPaths.table<ResizeArray<Contribution>> policy
            let folders = PlanningPaths.table<ResizeArray<LogicalPath * Contribution>> policy

            for contribution in
                contributions |> List.filter (fun value -> value.MappedTarget.Root = root) do
                let target = contribution.MappedTarget
                let key = PlanningPaths.key policy target.Path

                if not (files.ContainsKey key) then
                    files.Add(key, ResizeArray())

                files[key].Add contribution

                for prefix in PlanningPaths.prefixes target.Path do
                    let key = PlanningPaths.key policy prefix

                    if not (folders.ContainsKey key) then
                        folders.Add(key, ResizeArray())

                    folders[key].Add(prefix, contribution)

            let spellings = PlanningPaths.table<LogicalPath> policy

            for KeyValue(key, values) in folders do
                let ordered =
                    values
                    |> Seq.toList
                    |> List.sortBy (fun (path, item) ->
                        let tier, priority = PlanningPaths.rank item.Precedence
                        -tier, -(int64 priority), item.LayerId, LogicalPath.components path)

                let chosenPath, chosen = List.head ordered
                let address = { Root = root; Path = chosenPath }

                for _, entries in ordered |> List.groupBy (fun (_, value) -> value.LayerId) do
                    if entries |> List.map fst |> List.distinct |> List.length > 1 then
                        issues.Add(
                            PlanningIssue.TargetAlias(
                                address,
                                entries |> List.map snd |> PlanningPaths.sortedContributions
                            )
                        )

                let tied =
                    ordered |> List.filter (fun (_, value) -> value.Precedence = chosen.Precedence)

                if tied |> List.map fst |> List.distinct |> List.length > 1 then
                    issues.Add(
                        PlanningIssue.DirectorySpellingTie(
                            address,
                            tied |> List.map snd |> PlanningPaths.sortedContributions
                        )
                    )

                spellings.Add(key, chosenPath)

                if files.ContainsKey key then
                    issues.Add(PlanningIssue.FileDirectoryConflict address)

            let canonical path =
                let parents = PlanningPaths.prefixes path

                let names =
                    parents
                    |> List.map (fun parent ->
                        spellings[PlanningPaths.key policy parent]
                        |> LogicalPath.components
                        |> List.last)

                PlanningPaths.logical (names @ [ LogicalPath.components path |> List.last ])

            for KeyValue(_, path) in spellings do
                directories.Add { Root = root; Path = canonical path }

            for KeyValue(_, values) in files do
                let ordered = values |> Seq.toList |> PlanningPaths.sortedContributions
                let winner = List.head ordered

                let target =
                    { winner.MappedTarget with
                        Path = canonical winner.MappedTarget.Path }

                let mutable ambiguous = false

                for _, entries in ordered |> List.groupBy _.LayerId do
                    if entries.Length > 1 then
                        ambiguous <- true
                        issues.Add(PlanningIssue.TargetAlias(target, entries))

                for _, entries in ordered |> List.groupBy _.Precedence do
                    if entries.Length > 1 then
                        ambiguous <- true
                        issues.Add(PlanningIssue.PrecedenceTie(target, entries))

                if not ambiguous then
                    let alternatives = List.tail ordered

                    let reason =
                        match alternatives with
                        | [] -> WinnerReason.OnlyContribution
                        | next :: _ when next.Precedence.Tier <> winner.Precedence.Tier ->
                            WinnerReason.HigherLayerTier
                        | _ -> WinnerReason.HigherPriority

                    resolved.Add
                        { Target = target
                          Winner = winner
                          Alternatives = alternatives
                          Reason = reason }

        resolved
        |> Seq.sortBy (fun value -> PlanningPaths.targetOrder value.Target)
        |> Seq.toList,
        directories |> Seq.sortBy PlanningPaths.targetOrder |> Seq.toList
