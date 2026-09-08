namespace ModConductor.Deployment

open System.Collections.Generic
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal PhysicalTargets =
    let private path parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> invalidOp "Invalid physical target.")

    let private ancestors includeSelf value =
        let parts = LogicalPath.components value
        let last = parts.Length - (if includeSelf then 0 else 1)
        [ for count in 1..last -> path (List.take count parts) ]

    let map policy (known: LogicalPath list) (targets: TargetFile list) (token: CancellationToken) =
        let spellings = Dictionary<string, LogicalPath option>(TargetPolicy.comparer policy)

        for knownPath in known do
            token.ThrowIfCancellationRequested()

            for parent in ancestors true knownPath do
                let key = TargetPolicy.key policy parent

                match spellings.TryGetValue key with
                | false, _ -> spellings.Add(key, Some parent)
                | true, Some prior when prior <> parent -> spellings[key] <- None
                | _ -> ()

        targets
        |> List.choose (fun target ->
            token.ThrowIfCancellationRequested()

            let resolved =
                LogicalPath.components target.Path
                |> List.fold
                    (fun prior part ->
                        let wanted = path (prior @ [ part ])

                        match spellings.TryGetValue(TargetPolicy.key policy wanted) with
                        | false, _ -> LogicalPath.components wanted
                        | true, Some value -> LogicalPath.components value
                        | true, None ->
                            RecoveryFiles.fail "The game folder contains ambiguous target names.")
                    []
                |> path

            if resolved = target.Path then
                None
            else
                Some(target, resolved))
        |> Map.ofList

    let boundaries
        policy
        (known: LogicalPath list)
        (existing: ActiveLink list)
        (generation: Generation)
        (token: CancellationToken)
        =
        let key = TargetPolicy.key policy

        let index paths =
            let values = HashSet<string>(TargetPolicy.comparer policy)

            for value in paths do
                token.ThrowIfCancellationRequested()

                for parent in ancestors true value do
                    values.Add(key parent) |> ignore

            values

        let occupied = index known

        let oldLeaves =
            index (
                existing
                |> List.filter (fun link -> not link.Spec.Directory)
                |> List.map _.Target.Path
            )

        let baseFiles = index (generation.Observed |> List.map _.Target.Path)
        let working = index (generation.Working |> List.map _.Target.Path)

        let workingRoots =
            HashSet<string>(
                generation.Working |> Seq.map (fun file -> key file.Target.Path),
                TargetPolicy.comparer policy
            )

        let oldBoundaries =
            HashSet<string>(
                existing
                |> Seq.filter _.Spec.Directory
                |> Seq.map (fun link -> key link.Target.Path),
                TargetPolicy.comparer policy
            )

        let candidates =
            generation.Files
            |> List.collect (fun file ->
                token.ThrowIfCancellationRequested()

                ancestors false file.Target.Path
                |> List.map (fun parent -> { file.Target with Path = parent }))
            |> List.distinct
            |> List.sortBy (fun target -> (LogicalPath.components target.Path).Length, target)

        let chosen = ResizeArray<TargetFile>()
        let chosenKeys = HashSet<string>(TargetPolicy.comparer policy)

        for target in candidates do
            token.ThrowIfCancellationRequested()
            let targetKey = key target.Path
            let parents = ancestors true target.Path
            let insideWorking = parents |> List.exists (key >> workingRoots.Contains)
            let alreadyCovered = parents |> List.exists (key >> chosenKeys.Contains)

            if
                not (oldLeaves.Contains targetKey)
                && not (baseFiles.Contains targetKey)
                && not (working.Contains targetKey)
                && not insideWorking
                && (oldBoundaries.Contains targetKey || not (occupied.Contains targetKey))
                && not alreadyCovered
            then
                chosen.Add target
                chosenKeys.Add targetKey |> ignore

        chosen |> Seq.toList
