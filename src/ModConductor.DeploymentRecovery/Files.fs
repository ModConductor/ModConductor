namespace ModConductor.DeploymentRecovery

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal RecoveryFiles =
    let fail text =
        raise (RecoveryException(RecoveryError.Mismatch text))

    let digestWith (token: CancellationToken) (stream: Stream) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let buffer = Array.zeroCreate<byte> 65536
        let mutable reading = true

        while reading do
            token.ThrowIfCancellationRequested()
            let count = stream.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                hash.AppendData(buffer, 0, count)

        Convert.ToHexStringLower(hash.GetHashAndReset())

    let digest stream =
        digestWith CancellationToken.None stream

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
        let root = (binding context target).Directory
        use held = HeldDirectory.Open(root.Path, root.Identity)

        let rec walk (parent: HeldDirectory) =
            function
            | [ name ] -> parent.InspectEntry name
            | name :: rest ->
                match parent.InspectEntry name with
                | None -> None
                | Some entry when entry.Kind = EntryKind.Directory ->
                    use child = parent.Directory(name, Some entry.Identity)
                    walk child rest
                | Some _ -> fail "A target parent is not a real directory."
            | [] -> invalidOp "A target path is empty."

        walk held (LogicalPath.components target.Path)

    let originalMatches token context (original: Original) stored =
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
                    digestWith token stream = hash

        if stored then
            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)
            check backup original.Backup
        else
            withParent root.Directory original.Target.Path check

    let captureOriginal token (receiptId: Guid) index context target (entry: HeldEntry) =
        let hash =
            if entry.Kind = EntryKind.RegularFile then
                withParent (binding context target).Directory target.Path (fun parent name ->
                    let stream, _ = parent.Read(name, Some entry.Identity)
                    use stream = stream
                    Some(digestWith token stream))
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

    let stateMatches token context target expected state =
        match expected, state with
        | EntryState.Missing, None -> true
        | EntryState.Link(spec, identity), Some actual ->
            linkMatches spec actual && identity = Some actual
        | EntryState.Original original, Some _ -> originalMatches token context original false
        | _ -> false

    let preserve token context (original: Original) =
        let root = binding context original.Target

        if observe context original.Target |> Option.isNone then
            if not (originalMatches token context original true) then
                fail "The preserved original is missing or changed."
        else
            if not (originalMatches token context original false) then
                fail "The original changed before preservation."

            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

            withParent root.Directory original.Target.Path (fun parent name ->
                parent.MoveOriginal(name, original.Entry, backup, original.Backup))

    let restoreOriginal token context (original: Original) =
        let root = binding context original.Target

        if originalMatches token context original false then
            ()
        else
            if observe context original.Target |> Option.isSome then
                fail "The original destination is occupied."

            if not (originalMatches token context original true) then
                fail "The recorded original changed."

            use backup = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)

            withParent root.Directory original.Target.Path (fun parent name ->
                backup.MoveOriginal(original.Backup, original.Entry, parent, name))

    let remove context target expected =
        withParent (binding context target).Directory target.Path (fun parent name ->
            parent.RemoveLink(name, expected))

    let install token context target state =
        let current = observe context target

        if stateMatches token context target state current then
            current
        else
            if current.IsSome then
                fail
                    "The existing entry has no matching recorded identity; review it before recovery."

            match state with
            | EntryState.Missing -> None
            | EntryState.Original original ->
                restoreOriginal token context original
                observe context target
            | EntryState.Link(spec, _) ->
                Some(
                    withParent (binding context target).Directory target.Path (fun parent name ->
                        parent.CreateLink(name, spec.Target, spec.Directory))
                )

    let verifyGenerationWith (token: CancellationToken) (generation: Generation) =
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
                token.ThrowIfCancellationRequested()
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
            let read (parent: HeldDirectory) name identity =
                let stream, _ = parent.Read(name, Some identity)
                use stream = stream

                if stream.Length <> file.Length || digestWith token stream <> file.Sha256 then
                    fail "A retained generation file changed."

            match file.Backing with
            | None ->
                withParent generation.Directory file.Path (fun parent name ->
                    read parent name file.Identity)
            | Some backing ->
                withParent generation.Directory file.Path (fun parent name ->
                    let expected =
                        { Generation = generation.Id
                          Target = path backing.Directory backing.Path
                          Directory = false }

                    match parent.InspectEntry name with
                    | Some entry when entry.Identity = file.Identity && linkMatches expected entry ->
                        ()
                    | _ -> fail "A retained generation link changed.")

                withParent backing.Directory backing.Path (fun parent name ->
                    read parent name backing.Identity)

        for working in generation.Working do
            withParent working.Root working.Path (fun parent name ->
                match parent.InspectEntry name with
                | Some entry when
                    entry.Identity = working.Identity
                    && entry.Kind = (if working.Directory then
                                         EntryKind.Directory
                                     else
                                         EntryKind.RegularFile)
                    ->
                    ()
                | _ -> fail "A declared working location changed.")

    let verifyGeneration generation =
        verifyGenerationWith CancellationToken.None generation

    let nativeTarget (generation: Generation) (target: TargetFile) =
        { target with
            Path = generation.NativeTargets.TryFind target |> Option.defaultValue target.Path }

    let verifyObservedWith token (context: Context) (generation: Generation) =
        for logicalFile in generation.Observed do
            let file =
                { logicalFile with
                    Target = nativeTarget generation logicalFile.Target }

            let check (parent: HeldDirectory) name =
                let stream, _ = parent.Read(name, Some file.Identity)
                use stream = stream

                if stream.Length <> file.Length || digestWith token stream <> file.Sha256 then
                    fail "An observed game-folder file changed."

            match observe context file.Target with
            | Some entry when entry.Kind = EntryKind.RegularFile && entry.Identity = file.Identity ->
                withParent (binding context file.Target).Directory file.Target.Path check
            | _ ->
                match
                    context.Originals
                    |> List.tryFind (fun original -> original.Target = file.Target)
                with
                | Some original when original.Entry.Identity = file.Identity ->
                    let root = binding context file.Target
                    use stored = HeldDirectory.Open(root.Originals.Path, root.Originals.Identity)
                    check stored original.Backup
                | _ -> fail "An observed game-folder file has no matching preserved original."

    let verifyObserved context generation =
        verifyObservedWith CancellationToken.None context generation
