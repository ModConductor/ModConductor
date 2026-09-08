namespace ModConductor.DeploymentRecovery

open System
open System.IO
open System.Security.Cryptography
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal RecoveryFiles =
    let fail text =
        raise (RecoveryException(RecoveryError.Mismatch text))

    let digest (stream: Stream) =
        Convert.ToHexStringLower(SHA256.HashData stream)

    let path (root: Location) logical =
        (HostPath.value root.Path, LogicalPath.components logical)
        ||> List.fold (fun parent child -> Path.Combine(parent, child))

    let withParent (root: Location) logical action =
        use held = HeldDirectory.Open(root.Path, root.Identity)

        let rec walk (parent: HeldDirectory) =
            function
            | [ name ] -> action parent name
            | name :: rest ->
                use next = parent.Directory(name, None)
                walk next rest
            | [] -> invalidOp "A target path is empty."

        walk held (LogicalPath.components logical)

    let binding (context: Context) (target: TargetFile) =
        context.Roots |> List.find (fun root -> root.Root.Id = target.Root)

    let observe context target =
        withParent (binding context target).Directory target.Path (fun parent name ->
            parent.InspectEntry name)

    let originalMatches context (original: Original) stored =
        let root = binding context original.Target

        let check (parent: HeldDirectory) name =
            if parent.InspectEntry name <> Some original.Entry then
                false
            else
                match original.Sha256 with
                | None -> true
                | Some hash ->
                    let stream, _ = parent.Read(name, Some original.Entry.Identity)
                    use stream = stream
                    digest stream = hash

        if stored then
            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)
            check backup original.Backup
        else
            withParent root.Directory original.Target.Path check

    let captureOriginal (receiptId: Guid) index context target (entry: HeldEntry) =
        let hash =
            if entry.Kind = EntryKind.RegularFile then
                withParent (binding context target).Directory target.Path (fun parent name ->
                    let stream, _ = parent.Read(name, Some entry.Identity)
                    use stream = stream
                    Some(digest stream))
            elif entry.Kind = EntryKind.Directory then
                None
            else
                fail "An unowned link or special entry is not an original file or directory."

        { Target = target
          Entry = entry
          Sha256 = hash
          Backup = receiptId.ToString() + "-" + string index }

    let linkMatches (spec: LinkSpec) (entry: HeldEntry) =
        entry.Kind = EntryKind.Link
        && entry.LinkTarget = Some spec.Target
        && (entry.DirectoryLink.IsNone || entry.DirectoryLink = Some spec.Directory)

    let stateMatches context target expected state =
        match expected, state with
        | EntryState.Missing, None -> true
        | EntryState.Link(spec, identity), Some actual ->
            linkMatches spec actual && identity = Some actual
        | EntryState.Original original, Some _ -> originalMatches context original false
        | _ -> false

    let preserve context (original: Original) =
        let root = binding context original.Target

        if observe context original.Target |> Option.isNone then
            if not (originalMatches context original true) then
                fail "The preserved original is missing or changed."
        else
            if not (originalMatches context original false) then
                fail "The original changed before preservation."

            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

            withParent root.Directory original.Target.Path (fun parent name ->
                parent.MoveOriginal(name, original.Entry, backup, original.Backup))

    let restoreOriginal context (original: Original) =
        let root = binding context original.Target

        if originalMatches context original false then
            ()
        else
            if observe context original.Target |> Option.isSome then
                fail "The original destination is occupied."

            if not (originalMatches context original true) then
                fail "The recorded original changed."

            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

            withParent root.Directory original.Target.Path (fun parent name ->
                backup.MoveOriginal(original.Backup, original.Entry, parent, name))

    let remove context target expected =
        withParent (binding context target).Directory target.Path (fun parent name ->
            parent.RemoveLink(name, expected))

    let install context target state =
        let current = observe context target

        if stateMatches context target state current then
            current
        else
            if current.IsSome then
                fail
                    "The existing entry has no matching recorded identity; review it before recovery."

            match state with
            | EntryState.Missing -> None
            | EntryState.Original original ->
                restoreOriginal context original
                observe context target
            | EntryState.Link(spec, _) ->
                Some(
                    withParent (binding context target).Directory target.Path (fun parent name ->
                        parent.CreateLink(name, spec.Target, spec.Directory))
                )

    let verifyGeneration (generation: Generation) =
        use directory =
            HeldDirectory.Open(generation.Directory.Path, generation.Directory.Identity)

        let paths =
            generation.Files |> List.map (fun file -> LogicalPath.components file.Path)

        let expectedFiles = Set.ofList paths

        let expectedDirectories =
            paths
            |> List.collect (fun parts ->
                [ for count in 1 .. parts.Length - 1 -> List.take count parts ])
            |> Set.ofList

        let rec check (parent: HeldDirectory) prefix =
            for name in parent.Names do
                let child = prefix @ [ name ]

                if expectedFiles.Contains child then
                    ()
                elif expectedDirectories.Contains child then
                    use next = parent.Directory(name, None)
                    check next child
                else
                    fail "The prepared generation contains an unplanned entry."

        check directory []

        for file in generation.Files do
            withParent generation.Directory file.Path (fun parent name ->
                let stream, _ = parent.Read(name, Some file.Identity)
                use stream = stream

                if stream.Length <> file.Length || digest stream <> file.Sha256 then
                    fail "A retained generation file changed.")

module internal Generations =
    let capture id (directory: Location) plan input =
        match Planner.checkCurrent plan input with
        | Error _ -> raise (RecoveryException RecoveryError.InvalidPlan)
        | Ok() -> ()

        let view = Planner.view plan

        let files =
            view.ReadOnlyFiles
            |> List.map (fun file ->
                let components =
                    file.Target.Root.ToString("N") :: LogicalPath.components file.Target.Path

                let path =
                    LogicalPath.create components
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid generation path.")

                let length, hash =
                    match file.Winner.Source with
                    | SourcePin.Mod(_, _, entry) -> entry.Payload.Length, entry.Payload.Sha256
                    | SourcePin.Snapshot(_, _, entry) -> entry.Length, entry.Sha256

                RecoveryFiles.withParent directory path (fun parent name ->
                    let stream, identity = parent.Read(name, None)
                    use stream = stream

                    if stream.Length <> length || RecoveryFiles.digest stream <> hash then
                        RecoveryFiles.fail "The prepared generation differs from its plan."

                    { Target = file.Target
                      Path = path
                      Identity = identity
                      Length = length
                      Sha256 = hash }))

        let seeds =
            view.Writable
            |> List.collect (function
                | WritableProjection.File(_, _, seed) -> Option.toList seed
                | WritableProjection.Subtree(_, _, _, seeds) -> seeds)

        let references =
            view.ReadOnlyFiles @ seeds
            |> List.collect (fun file -> file.Winner :: file.Alternatives)
            |> List.map (fun source -> source.Source)
            |> List.distinct

        { Id = id
          PlanFingerprint = view.Fingerprint
          Directory = directory
          Files = files
          References = references
          Writable = input.Writable |> List.map (fun value -> value.Target)
          Roots = input.Roots }
