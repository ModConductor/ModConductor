namespace ModConductor.DeploymentPlanning

open System
open System.Collections.Generic
open ModConductor.Platform

module internal WritableResolution =
    let project
        (roots: Dictionary<Guid, TargetPolicy>)
        (files: ResolvedFile list)
        (directories: TargetFile list)
        (issues: ResizeArray<PlanningIssue>)
        declarations
        =
        let valid = ResizeArray<WritableDeclaration * TargetPolicy * string>()
        let identities = HashSet<Guid>()

        let prefix policy (parent: string) (child: string) =
            parent = ""
            || (child.Length >= parent.Length
                && (TargetPolicy.comparer policy).Equals(parent, child.Substring(0, parent.Length))
                && (child.Length = parent.Length || child[parent.Length] = '/'))

        for declaration in declarations |> List.sort do
            if not (identities.Add declaration.Id) then
                issues.Add(PlanningIssue.DuplicateWritableId declaration.Id)

            let root, path =
                PlanningPaths.rootOf declaration.Target, PlanningPaths.pathOf declaration.Target

            match roots.TryGetValue root with
            | false, _ -> issues.Add(PlanningIssue.MissingTargetRoot root)
            | true, policy ->
                let problems =
                    match path with
                    | PlanPath.Root -> []
                    | PlanPath.At value -> TargetPolicy.problems policy value

                match problems, path with
                | _ :: _, PlanPath.At value ->
                    issues.Add(
                        PlanningIssue.InvalidTargetName({ Root = root; Path = value }, problems)
                    )
                | _ ->
                    let key = PlanningPaths.locationKey policy path

                    for other, _, otherKey in valid do
                        if
                            PlanningPaths.rootOf other.Target = root
                            && (prefix policy key otherKey || prefix policy otherKey key)
                        then
                            issues.Add(
                                PlanningIssue.OverlappingWritableTargets(other.Id, declaration.Id)
                            )

                    for file in files |> List.filter (fun file -> file.Target.Root = root) do
                        let fileKey = PlanningPaths.key policy file.Target.Path
                        let same = (TargetPolicy.comparer policy).Equals(key, fileKey)

                        let conflict =
                            match declaration.Target with
                            | WritableTarget.File _ ->
                                (prefix policy key fileKey || prefix policy fileKey key) && not same
                            | WritableTarget.Subtree _ -> prefix policy fileKey key

                        if conflict then
                            issues.Add(
                                PlanningIssue.WritableStructureConflict(declaration.Id, file.Target)
                            )

                    valid.Add(declaration, policy, key)

        let seeds = Dictionary<Guid, ResizeArray<ResolvedFile>>()

        for declaration, _, _ in valid do
            if not (seeds.ContainsKey declaration.Id) then
                seeds.Add(declaration.Id, ResizeArray())

        let readOnly = ResizeArray<ResolvedFile>()

        for file in files do
            let owner =
                valid
                |> Seq.tryFind (fun (declaration, policy, key) ->
                    file.Target.Root = PlanningPaths.rootOf declaration.Target
                    && (match declaration.Target with
                        | WritableTarget.File _ ->
                            (TargetPolicy.comparer policy)
                                .Equals(key, PlanningPaths.key policy file.Target.Path)
                        | WritableTarget.Subtree _ ->
                            prefix policy key (PlanningPaths.key policy file.Target.Path)))

            match owner with
            | None -> readOnly.Add file
            | Some(declaration, _, _) -> seeds[declaration.Id].Add file

        let canonical root policy value =
            let parts = PlanningPaths.components value

            parts
            |> List.mapi (fun index name ->
                let prefix = PlanningPaths.logical (List.take (index + 1) parts)

                directories
                |> List.tryFind (fun directory ->
                    directory.Root = root
                    && (TargetPolicy.comparer policy)
                        .Equals(
                            PlanningPaths.key policy prefix,
                            PlanningPaths.key policy directory.Path
                        ))
                |> Option.map (fun directory -> LogicalPath.components directory.Path |> List.last)
                |> Option.defaultValue name)
            |> PlanningPaths.location

        let writable =
            valid
            |> Seq.map (fun (declaration, policy, _) ->
                let initial = List.ofSeq seeds[declaration.Id]

                match declaration.Target with
                | WritableTarget.File(root, path) ->
                    let seed = List.tryHead initial

                    let target =
                        seed
                        |> Option.map _.Target
                        |> Option.defaultValue
                            { Root = root
                              Path =
                                canonical root policy (PlanPath.At path)
                                |> PlanningPaths.components
                                |> PlanningPaths.logical }

                    WritableProjection.File(declaration.Id, target, seed)
                | WritableTarget.Subtree(root, path) ->
                    WritableProjection.Subtree(
                        declaration.Id,
                        root,
                        canonical root policy path,
                        initial
                    ))
            |> Seq.toList

        List.ofSeq readOnly, writable
