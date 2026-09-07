namespace ModConductor.DeploymentPlanning

open System
open System.Collections.Generic
open ModConductor.Platform
open ModConductor.ModLibrary

module internal InputProjection =
    let project (input: PlanningInput) =
        let issues = ResizeArray<PlanningIssue>()
        let roots = Dictionary<Guid, TargetPolicy>()

        for root in input.Roots |> List.sort do
            if not (roots.TryAdd(root.Id, root.Policy)) then
                issues.Add(PlanningIssue.DuplicateRoot root.Id)

        if not input.Profile.Complete then
            issues.Add PlanningIssue.IncompleteSelection

        let identities = HashSet<Guid>()
        let payloads = Dictionary<Guid, int64 * string>()
        let contributions = ResizeArray<Contribution>()

        let validContent length (digest: string) =
            length >= 0L && digest.Length = 64 && digest |> Seq.forall Uri.IsHexDigit

        let addLayer id precedence mappings archives (sources: SourcePin list) =
            for mapping in mappings do
                if not (roots.ContainsKey mapping.TargetRoot) then
                    issues.Add(PlanningIssue.MissingTargetRoot mapping.TargetRoot)

            let paths = sources |> List.map PlanningPaths.sourcePath |> Set.ofList

            for annotation in archives do
                if
                    not (paths.Contains annotation.Container)
                    || String.IsNullOrWhiteSpace annotation.CapabilityId
                    || String.IsNullOrWhiteSpace annotation.CapabilityRevision
                then
                    issues.Add(PlanningIssue.InvalidArchiveAnnotation(id, annotation.Container))

            for source in sources do
                let path = PlanningPaths.sourcePath source

                let length, digest =
                    match source with
                    | SourcePin.Mod(_, _, entry) ->
                        let payload = entry.Payload
                        let signature = payload.Length, payload.Sha256.ToUpperInvariant()

                        match payloads.TryGetValue payload.Id with
                        | true, existing when existing <> signature ->
                            issues.Add(PlanningIssue.InconsistentPayload payload.Id)
                        | true, _ -> ()
                        | false, _ -> payloads.Add(payload.Id, signature)

                        payload.Length, payload.Sha256
                    | SourcePin.Snapshot(_, _, file) -> file.Length, file.Sha256

                if not (validContent length digest) then
                    issues.Add(PlanningIssue.InvalidContent(id, path))

                let candidates =
                    mappings
                    |> List.filter (fun mapping ->
                        PlanningPaths.exactPrefix mapping.SourcePrefix path)
                    |> List.sortByDescending (fun mapping ->
                        PlanningPaths.components mapping.SourcePrefix |> List.length)

                match candidates with
                | [] -> issues.Add(PlanningIssue.UnmappedFile(id, path))
                | first :: rest when
                    rest
                    |> List.exists (fun candidate ->
                        (PlanningPaths.components candidate.SourcePrefix).Length = (PlanningPaths.components
                            first.SourcePrefix)
                            .Length)
                    ->
                    issues.Add(PlanningIssue.AmbiguousMapping(id, path))
                | mapping :: _ ->
                    let mapped =
                        PlanningPaths.components mapping.TargetPrefix
                        @ (LogicalPath.components path
                           |> List.skip (PlanningPaths.components mapping.SourcePrefix).Length)

                    if List.isEmpty mapped then
                        issues.Add(PlanningIssue.FileMappedToRoot(id, path))
                    else
                        let target =
                            { Root = mapping.TargetRoot
                              Path = PlanningPaths.logical mapped }

                        match roots.TryGetValue target.Root with
                        | false, _ -> ()
                        | true, policy ->
                            match TargetPolicy.problems policy target.Path with
                            | [] ->
                                contributions.Add
                                    { LayerId = id
                                      Precedence = precedence
                                      Source = source
                                      MappedTarget = target
                                      Archives =
                                        archives
                                        |> List.filter (fun value -> value.Container = path)
                                        |> List.sort }
                            | problems ->
                                issues.Add(PlanningIssue.InvalidTargetName(target, problems))

        for layer in input.ReadOnly do
            if not (identities.Add layer.Id) then
                issues.Add(PlanningIssue.DuplicateLayer layer.Id)

            if not layer.Complete then
                issues.Add(PlanningIssue.IncompleteSnapshot layer.Id)

            let tier =
                match layer.Kind with
                | ReadOnlyLayerKind.Base -> LayerTier.Base
                | ReadOnlyLayerKind.Secondary -> LayerTier.Secondary

            addLayer
                layer.Id
                { Tier = tier
                  Priority = layer.Priority }
                layer.Mappings
                layer.Archives
                (layer.Files
                 |> List.map (fun file -> SourcePin.Snapshot(layer.Id, layer.Generation, file)))

        for layer in input.Profile.Mods do
            if not (identities.Add layer.ModId) then
                issues.Add(PlanningIssue.DuplicateLayer layer.ModId)

            if layer.Enabled then
                match layer.Version with
                | None -> issues.Add(PlanningIssue.MissingVersion layer.ModId)
                | Some version ->
                    if version.ModId <> layer.ModId then
                        issues.Add(PlanningIssue.WrongModVersion(layer.ModId, version.ModId))

                    if version.NextOffset.IsSome then
                        issues.Add(PlanningIssue.IncompleteManifest version.Id)

                    addLayer
                        layer.ModId
                        { Tier = LayerTier.Mod
                          Priority = layer.Priority }
                        layer.Mappings
                        layer.Archives
                        (version.Entries
                         |> List.map (fun entry -> SourcePin.Mod(layer.ModId, version.Id, entry)))

        roots, List.ofSeq contributions, issues
