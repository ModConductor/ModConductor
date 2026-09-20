namespace ModConductor.DeploymentRecovery

open System
open System.IO
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal Preparation =
    let private components (target: TargetFile) = LogicalPath.components target.Path

    let private contains (parent: TargetFile) (child: TargetFile) =
        parent.Root = child.Root
        && List.truncate (components parent).Length (components child) = components parent

    let private overlap left right =
        contains left right || contains right left

    let nested parent child =
        let relative = Path.GetRelativePath(parent, child)

        relative = "."
        || (not (Path.IsPathRooted relative)
            && relative <> ".."
            && not (
                relative.StartsWith(
                    ".." + string Path.DirectorySeparatorChar,
                    StringComparison.Ordinal
                )
            ))


    let overlappingRoots (left: RootBinding list) (right: RootBinding list) =
        left
        |> List.exists (fun first ->
            right
            |> List.exists (fun second ->
                first.Directory.Identity = second.Directory.Identity
                || nested
                    (HostPath.value first.Directory.Path)
                    (HostPath.value second.Directory.Path)
                || nested
                    (HostPath.value second.Directory.Path)
                    (HostPath.value first.Directory.Path)))

    let private checkLocations
        (roots: RootBinding list)
        (boundaries: TargetFile list)
        (generation: Generation)
        =
        let canonical (location: Location) =
            use held = HeldDirectory.Open(location.Path, location.Identity)

            let selected =
                RootSelection.select location.Path
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "A selected fixture root is unavailable.")

            if RootSelection.path selected <> location.Path then
                RecoveryFiles.fail "Use the canonical selected root for deployment."

            HostPath.value location.Path

        let targets = roots |> List.map (fun root -> root, canonical root.Directory)
        let generationPath = canonical generation.Directory

        for root, _ in targets do
            let originals = canonical root.Originals

            if
                targets
                |> List.exists (fun (targetRoot, path) ->
                    targetRoot.Directory.Identity = root.Originals.Identity
                    || targetRoot.Directory.Identity = generation.Directory.Identity
                    || nested path generationPath
                    || nested generationPath path)
            then
                RecoveryFiles.fail
                    "Targets, generation storage and original storage must be disjoint."

            if
                generation.Directory.Identity = root.Originals.Identity
                || nested generationPath originals
                || nested originals generationPath
            then
                RecoveryFiles.fail "Generation and original storage must be disjoint."

            if root.Directory.Identity.Device <> root.Originals.Identity.Device then
                RecoveryFiles.fail "Original preservation requires the target volume."

        let nativePath target =
            let root = roots |> List.find (fun value -> value.Root.Id = target.Root)

            (HostPath.value root.Directory.Path, LogicalPath.components target.Path)
            ||> List.fold (fun parent child -> Path.Combine(parent, child))
            |> Path.GetFullPath

        let physicalTargets =
            (generation.Files |> List.map _.Target)
            @ (generation.Observed |> List.map _.Target)
            @ (generation.Working |> List.map _.Target)
            @ boundaries
            |> List.distinct
            |> List.map (fun target -> target, nativePath target)

        for index, (target, path) in List.indexed physicalTargets do
            for other, otherPath in physicalTargets |> List.skip (index + 1) do
                if
                    target.Root <> other.Root && (nested path otherPath || nested otherPath path)
                then
                    RecoveryFiles.fail "Deployment target roots contain overlapping paths."

        for root in roots do
            let originals = HostPath.value root.Originals.Path |> Path.GetFullPath

            if
                physicalTargets
                |> List.exists (fun (_, path) -> nested path originals || nested originals path)
            then
                RecoveryFiles.fail "A deployment target overlaps original storage."

    let private checkExternalLocations (roots: RootBinding list) (generation: Generation) =
        let protectedLocations =
            generation.Directory
            :: (roots |> List.collect (fun root -> [ root.Directory; root.Originals ]))

        let external =
            (generation.Files |> List.choose _.Backing |> List.map _.Directory)
            @ (generation.Working |> List.map _.Root)

        let overlaps (a: Location) (b: Location) =
            a.Identity = b.Identity
            || nested (HostPath.value a.Path) (HostPath.value b.Path)
            || nested (HostPath.value b.Path) (HostPath.value a.Path)

        for location in external do
            let selected =
                RootSelection.select location.Path
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "External generation storage is unavailable.")

            if RootSelection.path selected <> location.Path then
                RecoveryFiles.fail "Use canonical external storage locations."

            if protectedLocations |> List.exists (overlaps location) then
                RecoveryFiles.fail
                    "Payload and working storage must be outside deployment locations."

        for working in generation.Working do
            if
                generation.Files
                |> List.choose _.Backing
                |> List.exists (fun backing -> overlaps working.Root backing.Directory)
            then
                RecoveryFiles.fail
                    "Working storage must be separate from immutable payload storage."

    let projection (request: SwitchRequest) =
        let generation = request.Generation
        let boundaries = request.DirectoryBoundaries

        if boundaries |> List.distinct |> List.length <> boundaries.Length then
            raise (RecoveryException RecoveryError.InvalidPlan)

        for index, boundary in List.indexed boundaries do
            if boundaries |> List.skip (index + 1) |> List.exists (overlap boundary) then
                raise (RecoveryException RecoveryError.InvalidPlan)

            if
                not (generation.Files |> List.exists (fun file -> contains boundary file.Target))
            then
                raise (RecoveryException RecoveryError.InvalidPlan)

            if generation.Observed |> List.exists (fun file -> overlap boundary file.Target) then
                raise (RecoveryException RecoveryError.InvalidPlan)

            for output in generation.Writable do
                let collides =
                    match output with
                    | WritableTarget.File(root, path) ->
                        overlap boundary { Root = root; Path = path }
                    | WritableTarget.Subtree(root, PlanPath.Root) -> root = boundary.Root
                    | WritableTarget.Subtree(root, PlanPath.At path) ->
                        overlap boundary { Root = root; Path = path }

                if collides then
                    raise (RecoveryException RecoveryError.InvalidPlan)

        let targets =
            boundaries
            |> List.map (fun target -> target, true)
            |> fun values ->
                values
                @ (generation.Files
                   |> List.filter (fun file ->
                       not (
                           boundaries
                           |> List.exists (fun boundary -> contains boundary file.Target)
                       ))
                   |> List.map (fun file -> file.Target, false))

        targets
        |> List.map (fun (target, directory) ->
            let path =
                LogicalPath.create (target.Root.ToString("N") :: components target)
                |> Result.defaultWith (fun _ -> invalidOp "Invalid target.")

            target,
            { Generation = generation.Id
              Target = RecoveryFiles.path generation.Directory path
              Directory = directory })
        |> fun immutable ->
            immutable
            @ (generation.Working
               |> List.map (fun working ->
                   working.Target,
                   { Generation = generation.Id
                     Target = RecoveryFiles.path working.Root working.Path
                     Directory = working.Directory }))
        |> List.map (fun (target, spec) -> RecoveryFiles.nativeTarget generation target, spec)

    let prepare token (existing: Context option) (request: SwitchRequest) =
        if
            request.Id = Guid.Empty
            || request.ContextId = Guid.Empty
            || request.Generation.Id = Guid.Empty
            || String.IsNullOrWhiteSpace request.ContextFingerprint
        then
            raise (RecoveryException RecoveryError.InvalidPlan)

        if
            request.Roots.IsEmpty
            || request.Roots.Length > 8
            || request.DirectoryBoundaries.Length > 4096
            || request.PreserveOriginals.Length > 4096
        then
            raise (RecoveryException RecoveryError.Limit)

        if
            request.Roots
            |> List.map (fun value -> value.Root.Id)
            |> List.distinct
            |> List.length
            <> request.Roots.Length
        then
            raise (RecoveryException RecoveryError.InvalidPlan)

        if
            (request.Roots |> List.map (fun value -> value.Root) |> List.sort)
            <> List.sort request.Generation.Roots
        then
            raise (RecoveryException RecoveryError.InvalidPlan)

        let context =
            match existing with
            | None when request.ExpectedRevision = 0L ->
                { Id = request.ContextId
                  Fingerprint = request.ContextFingerprint
                  Roots = request.Roots
                  Revision = 0L
                  Active = None
                  Links = []
                  Directories = []
                  Originals = []
                  Pending = None }
            | None -> raise (RecoveryException RecoveryError.Stale)
            | Some value when value.Revision <> request.ExpectedRevision ->
                raise (RecoveryException RecoveryError.Stale)
            | Some value when value.Pending.IsSome -> raise (RecoveryException RecoveryError.Busy)
            | Some value when
                value.Fingerprint <> request.ContextFingerprint || value.Roots <> request.Roots
                ->
                RecoveryFiles.fail "The activation context changed."
            | Some value -> value

        for KeyValue(target, nativePath) in request.Generation.NativeTargets do
            let root = context.Roots |> List.tryFind (fun root -> root.Root.Id = target.Root)

            match root with
            | Some root when
                (ModConductor.Platform.TargetPolicy.comparer root.Root.Policy)
                    .Equals(
                        ModConductor.Platform.TargetPolicy.key root.Root.Policy target.Path,
                        ModConductor.Platform.TargetPolicy.key root.Root.Policy nativePath
                    )
                ->
                ()
            | _ -> raise (RecoveryException RecoveryError.InvalidPlan)

        checkLocations context.Roots request.DirectoryBoundaries request.Generation
        checkExternalLocations context.Roots request.Generation
        RecoveryFiles.verifyGenerationWith token request.Generation
        RecoveryFiles.verifyObservedWith token context request.Generation
        let proposed = projection request

        let targets =
            (proposed |> List.map fst)
            @ (context.Links |> List.map (fun link -> link.Target))
            |> List.distinct
            |> List.sort

        if targets.Length > 4096 then
            raise (RecoveryException RecoveryError.Limit)
        // A boundary cannot coexist with an individual descendant during this operation.
        for index, target in List.indexed targets do
            if targets |> List.skip (index + 1) |> List.exists (overlap target) then
                raise (RecoveryException RecoveryError.InvalidPlan)

        let mutable originals = context.Originals

        let changes =
            targets
            |> List.mapi (fun index target ->
                let current = RecoveryFiles.observe context target

                let before =
                    match
                        context.Links |> List.tryFind (fun link -> link.Target = target), current
                    with
                    | Some link, Some actual when
                        link.Entry = actual && RecoveryFiles.linkMatches link.Spec actual
                        ->
                        EntryState.Link(link.Spec, Some actual)
                    | Some _, _ -> RecoveryFiles.fail "An active link changed before activation."
                    | None, None -> EntryState.Missing
                    | None, Some entry when request.PreserveOriginals |> List.contains target ->
                        let original =
                            RecoveryFiles.captureOriginal
                                token
                                request.Id
                                index
                                context
                                target
                                entry

                        originals <-
                            original
                            :: (originals |> List.filter (fun value -> value.Target <> target))

                        EntryState.Original original
                    | None, Some _ ->
                        RecoveryFiles.fail
                            "An unowned destination is occupied; it was left untouched."

                let after =
                    match proposed |> List.tryFind (fun (path, _) -> path = target) with
                    | Some(_, spec) -> EntryState.Link(spec, None)
                    | None ->
                        match originals |> List.tryFind (fun value -> value.Target = target) with
                        | Some original ->
                            if not (RecoveryFiles.originalMatches token context original true) then
                                RecoveryFiles.fail
                                    "The original required by the removed path changed."

                            EntryState.Original original
                        | None -> EntryState.Missing

                { Target = target
                  Before = before
                  After = after
                  Phase = EntryPhase.Pending
                  Observed = None
                  RestoredEntry = None })

        { Id = request.Id
          Model = DeploymentModel.SymbolicLinkGeneration
          Context = context
          Proposed = request.Generation.Id
          Previous = context.Active
          PlanFingerprint = request.Generation.PlanFingerprint
          Revision = 0L
          Phase = ReceiptPhase.Applying
          Changes = changes
          Parents = RecoveryParents.prepare context (proposed |> List.map fst)
          Originals = originals
          Detail = "" }
