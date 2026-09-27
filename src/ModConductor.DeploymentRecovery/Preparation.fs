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

    let nested parent child = RecoveryLocations.nested parent child

    let overlappingRoots left right =
        RecoveryLocations.overlappingRoots left right

    let abandonOriginalStorage (prepared: PreparedOriginalStorage) =
        let directoryPath = HostPath.value prepared.Directory.Path
        let name = Path.GetFileName directoryPath

        if
            String.IsNullOrWhiteSpace name
            || Path.GetDirectoryName directoryPath <> HostPath.value prepared.Parent.Path
        then
            RecoveryFiles.fail "Prepared original storage has an invalid location."

        use parent = HeldDirectory.Open(prepared.Parent.Path, prepared.Parent.Identity)

        match parent.InspectEntry name with
        | None -> ()
        | Some entry when
            entry.Kind = EntryKind.Directory && entry.Identity = prepared.Directory.Identity
            ->
            let empty =
                use directory = parent.Directory(name, Some prepared.Directory.Identity)
                directory.Names |> Seq.isEmpty

            if empty then
                parent.RemoveDirectory(name, prepared.Directory.Identity)
            else
                RecoveryFiles.fail "Prepared original storage is not empty."
        | Some _ -> RecoveryFiles.fail "Prepared original storage changed."

    let projection (request: SwitchRequest) =
        let generation = request.Generation
        let boundaries = request.DirectoryBoundaries

        let invalidBoundary boundary =
            if
                not (generation.Files |> List.exists (fun file -> contains boundary file.Target))
            then
                true
            elif generation.Observed |> List.exists (fun file -> overlap boundary file.Target) then
                true
            else
                generation.Writable
                |> List.exists (fun output ->
                    match output with
                    | WritableTarget.File(root, path) ->
                        overlap boundary { Root = root; Path = path }
                    | WritableTarget.Subtree(root, PlanPath.Root) -> root = boundary.Root
                    | WritableTarget.Subtree(root, PlanPath.At path) ->
                        overlap boundary { Root = root; Path = path })

        if
            (boundaries
             |> List.sort
             |> List.pairwise
             |> List.exists (fun (left, right) -> overlap left right))
            || (boundaries |> List.exists invalidBoundary)
        then
            Error RecoveryError.InvalidPlan
        else
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
            |> Ok

    let private validateRequest (existing: Context option) (request: SwitchRequest) =
        if
            request.Id = Guid.Empty
            || request.ContextId = Guid.Empty
            || request.Generation.Id = Guid.Empty
            || String.IsNullOrWhiteSpace request.ContextFingerprint
        then
            Error RecoveryError.InvalidPlan
        elif request.Roots.IsEmpty || request.Roots.Length > 8 then
            Error RecoveryError.Limit
        elif
            request.Roots
            |> List.map (fun value -> value.Root.Id)
            |> List.distinct
            |> List.length
            <> request.Roots.Length
        then
            Error RecoveryError.InvalidPlan
        elif
            (request.Roots |> List.map (fun value -> value.Root) |> List.sort)
            <> List.sort request.Generation.Roots
        then
            Error RecoveryError.InvalidPlan
        else
            let context =
                match existing with
                | None when request.ExpectedRevision = 0L ->
                    Ok
                        { Id = request.ContextId
                          Fingerprint = request.ContextFingerprint
                          Roots = request.Roots
                          Revision = 0L
                          Active = None
                          Links = []
                          Directories = []
                          Originals = []
                          Pending = None }
                | None -> Error RecoveryError.Stale
                | Some value when value.Revision <> request.ExpectedRevision ->
                    Error RecoveryError.Stale
                | Some value when value.Pending.IsSome -> Error RecoveryError.Busy
                | Some value when
                    value.Fingerprint <> request.ContextFingerprint || value.Roots <> request.Roots
                    ->
                    Error(RecoveryError.Mismatch "The activation context changed.")
                | Some value -> Ok value

            context
            |> Result.bind (fun context ->
                let nativeTargetsMatch =
                    request.Generation.NativeTargets
                    |> Seq.forall (fun (KeyValue(target, nativePath)) ->
                        context.Roots
                        |> List.tryFind (fun root -> root.Root.Id = target.Root)
                        |> Option.exists (fun root ->
                            (TargetPolicy.comparer root.Root.Policy)
                                .Equals(
                                    TargetPolicy.key root.Root.Policy target.Path,
                                    TargetPolicy.key root.Root.Policy nativePath
                                )))

                if nativeTargetsMatch then
                    Ok context
                else
                    Error RecoveryError.InvalidPlan)

    let private prepareValidated token (context: Context) (request: SwitchRequest) =

        RecoveryLocations.checkLocations
            context.Roots
            request.DirectoryBoundaries
            request.Generation

        RecoveryLocations.checkExternalLocations context.Roots request.Generation
        RecoveryFiles.verifyGenerationWith token request.Generation
        RecoveryFiles.verifyObservedWith token context request.Generation

        projection request
        |> Result.bind (fun proposed ->
            let targets =
                (proposed |> List.map fst)
                @ (context.Links |> List.map (fun link -> link.Target))
                |> List.distinct
                |> List.sort

            if
                targets
                |> List.pairwise
                |> List.exists (fun (left, right) -> overlap left right)
            then
                Error RecoveryError.InvalidPlan
            else
                let linksByTarget: Map<TargetFile, ActiveLink> =
                    List.foldBack
                        (fun (link: ActiveLink) index -> Map.add link.Target link index)
                        context.Links
                        Map.empty

                let proposedByTarget: Map<TargetFile, LinkSpec> =
                    List.foldBack
                        (fun (target, spec) index -> Map.add target spec index)
                        proposed
                        Map.empty

                let preservedTargets = request.PreserveOriginals |> Set.ofList

                let mutable originalsByTarget: Map<TargetFile, Original> =
                    List.foldBack
                        (fun (original: Original) index -> Map.add original.Target original index)
                        context.Originals
                        Map.empty

                let mutable capturedOriginals: Original list = []

                let changes =
                    targets
                    |> List.mapi (fun index target ->
                        let current = RecoveryFiles.observe context target

                        let before =
                            match linksByTarget.TryFind target, current with
                            | Some link, Some actual when
                                link.Entry = actual && RecoveryFiles.linkMatches link.Spec actual
                                ->
                                EntryState.Link(link.Spec, Some actual)
                            | Some _, _ ->
                                RecoveryFiles.fail "An active link changed before activation."
                            | None, None -> EntryState.Missing
                            | None, Some entry when preservedTargets.Contains target ->
                                let original =
                                    RecoveryFiles.captureOriginal
                                        token
                                        request.Id
                                        index
                                        context
                                        target
                                        entry

                                capturedOriginals <- original :: capturedOriginals
                                originalsByTarget <- originalsByTarget.Add(target, original)

                                EntryState.Original original
                            | None, Some _ ->
                                RecoveryFiles.fail
                                    "An unowned destination is occupied; it was left untouched."

                        let after =
                            match proposedByTarget.TryFind target with
                            | Some spec -> EntryState.Link(spec, None)
                            | None ->
                                match originalsByTarget.TryFind target with
                                | Some original ->
                                    if
                                        not (
                                            RecoveryFiles.originalMatches
                                                token
                                                context
                                                original
                                                true
                                        )
                                    then
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

                let capturedTargets = capturedOriginals |> List.map _.Target |> Set.ofList

                let originals =
                    capturedOriginals
                    @ (context.Originals
                       |> List.filter (fun original ->
                           not (capturedTargets.Contains original.Target)))

                let parents = RecoveryParents.prepare context (proposed |> List.map fst)

                Ok
                    { Id = request.Id
                      Model = DeploymentModel.SymbolicLinkGeneration
                      Context = context
                      Proposed = request.Generation.Id
                      Previous = context.Active
                      PlanFingerprint = request.Generation.PlanFingerprint
                      Revision = 0L
                      Phase = ReceiptPhase.Applying
                      Changes = changes
                      Parents = parents
                      Originals = originals
                      Detail = "" })

    let prepare token existing request =
        validateRequest existing request
        |> Result.bind (fun context -> prepareValidated token context request)
