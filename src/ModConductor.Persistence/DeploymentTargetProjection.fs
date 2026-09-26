namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations
open ModConductor.Deployment

module internal DeploymentTargetProjection =
    let ownedLinkCovers policy (owned: TargetFile) (target: TargetFile) =
        let parent = TargetPolicy.key policy owned.Path
        let child = TargetPolicy.key policy target.Path

        owned.Root = target.Root
        && child.Length >= parent.Length
        && (TargetPolicy.comparer policy).Equals(parent, child.Substring(0, parent.Length))
        && (child.Length = parent.Length || child[parent.Length] = '/')

    let private knownAtRoot
        (binding: RootBinding)
        (targets: TargetFile list)
        (token: CancellationToken)
        =
        let known = ResizeArray<LogicalPath>()
        let policy = binding.Root.Policy

        let logical parts =
            LogicalPath.create parts
            |> Result.defaultWith (fun _ ->
                raise (System.IO.IOException "The game root contains an invalid file name."))

        let rec observe (directory: HeldDirectory) prefix =
            function
            | [] -> ()
            | wanted :: rest ->
                token.ThrowIfCancellationRequested()
                let names = directory.Names |> Seq.toList

                for name in names do
                    known.Add(logical (prefix @ [ name ]))

                match
                    names
                    |> List.filter (fun name ->
                        (TargetPolicy.comparer policy)
                            .Equals(
                                TargetPolicy.key policy (logical (prefix @ [ name ])),
                                TargetPolicy.key policy (logical (prefix @ [ wanted ]))
                            ))
                with
                | [] -> ()
                | [ actual ] when not rest.IsEmpty ->
                    match directory.InspectEntry actual with
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        use child = directory.Directory(actual, Some entry.Identity)
                        observe child (prefix @ [ actual ]) rest
                    | _ -> ()
                | [ _ ] -> ()
                | _ -> RecoveryFiles.fail "The game root contains ambiguous target names."

        use root = HeldDirectory.Open(binding.Directory.Path, binding.Directory.Identity)

        for target in targets |> List.distinct do
            observe root [] (LogicalPath.components target.Path)

        List.ofSeq known

    let project
        (id: Guid)
        (stamp: SourceStamp)
        (existing: Context option)
        ownership
        contextId
        (roots: RootBinding list)
        (observation: GameObservation)
        (built: PreparedGeneration)
        (token: CancellationToken)
        =
        let allTargets: TargetFile list =
            (built.Generation.Files |> List.map _.Target)
            @ (built.Generation.Observed |> List.map _.Target)
            @ (built.Generation.Working |> List.map _.Target)

        let knownFor (binding: RootBinding) =
            if binding.Root.Id = stamp.WorkspaceId then
                (observation.Entries |> List.map _.Path)
                @ (observation.Projection.Links |> List.map _.Path)
                @ (existing
                   |> Option.map (fun context ->
                       (context.Links |> List.map _.Target)
                       @ (context.Directories |> List.map _.Target)
                       |> List.filter (fun target -> target.Root = binding.Root.Id)
                       |> List.map _.Path)
                   |> Option.defaultValue [])
            else
                knownAtRoot
                    binding
                    (allTargets |> List.filter (fun target -> target.Root = binding.Root.Id))
                    token

        let known =
            roots |> List.map (fun root -> root.Root.Id, knownFor root) |> Map.ofList

        let boundaries =
            roots
            |> List.collect (fun root ->
                PhysicalTargets.boundaries
                    root.Root.Policy
                    known[root.Root.Id]
                    (existing
                     |> Option.map (fun context ->
                         context.Links
                         |> List.filter (fun link -> link.Target.Root = root.Root.Id))
                     |> Option.defaultValue [])
                    { built.Generation with
                        Files =
                            built.Generation.Files
                            |> List.filter (fun file -> file.Target.Root = root.Root.Id)
                        Observed =
                            built.Generation.Observed
                            |> List.filter (fun file -> file.Target.Root = root.Root.Id)
                        Working =
                            built.Generation.Working
                            |> List.filter (fun file -> file.Target.Root = root.Root.Id) }
                    token)

        let mapped =
            roots
            |> List.collect (fun root ->
                PhysicalTargets.map
                    root.Root.Policy
                    known[root.Root.Id]
                    ((allTargets |> List.filter (fun target -> target.Root = root.Root.Id))
                     @ (boundaries |> List.filter (fun target -> target.Root = root.Root.Id)))
                    token
                |> Map.toList)
            |> Map.ofList

        let generation =
            { built.Generation with
                NativeTargets = mapped }

        let observedContext: Context =
            { Id = contextId
              Fingerprint = ownership
              Roots = roots
              Revision = 0L
              Active = None
              Links = []
              Directories = []
              Originals = []
              Pending = None }

        let existingLinks: TargetFile list =
            existing
            |> Option.map (fun context -> context.Links |> List.map _.Target)
            |> Option.defaultValue []

        let policies =
            roots |> List.map (fun root -> root.Root.Id, root.Root.Policy) |> Map.ofList

        let insideExisting (target: TargetFile) =
            existingLinks
            |> List.exists (fun owned -> ownedLinkCovers policies[target.Root] owned target)

        let collisions =
            (generation.Files |> List.map _.Target)
            @ (generation.Working |> List.map _.Target)
            |> List.map (RecoveryFiles.nativeTarget generation)
            |> List.distinct
            |> List.choose (fun target ->
                if insideExisting target then
                    None
                else
                    RecoveryFiles.observe observedContext target |> Option.map (fun _ -> target))

        let switch =
            { Id = id
              ContextId = contextId
              ContextFingerprint = ownership
              ExpectedRevision = existing |> Option.map _.Revision |> Option.defaultValue 0L
              Roots = roots
              Generation = generation
              DirectoryBoundaries = boundaries
              PreserveOriginals = collisions
              ExpectedSources = Some stamp }

        let paths =
            (ModConductor.DeploymentRecovery.Preparation.projection switch |> List.map fst)
            @ (existing
               |> Option.map (fun context -> context.Links |> List.map _.Target)
               |> Option.defaultValue [])
            |> Set.ofList

        switch, paths.Count
