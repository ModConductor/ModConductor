namespace ModConductor.FilePlanning

open System
open System.IO
open System.Text
open System.Threading
open ModConductor.Platform

module internal GameInventory =
    let private path components =
        LogicalPath.create components
        |> Result.defaultWith (fun _ ->
            raise (IOException("The game folder contains an invalid file name.")))

    let rec withParent (directory: HeldDirectory) components action =
        match components with
        | [] -> invalidOp "A file path cannot be empty."
        | [ name ] -> action directory name
        | name :: rest ->
            use child = directory.Directory(name, None)
            withParent child rest action

    let readSource (source: GameFileSource) =
        use root = HeldDirectory.Open(source.Root, source.RootIdentity)

        withParent root (LogicalPath.components source.Path) (fun parent name ->
            parent.Read(name, Some source.Identity))

    let inspectSource (source: GameFileSource) =
        use root = HeldDirectory.Open(source.Root, source.RootIdentity)

        withParent root (LogicalPath.components source.Path) (fun parent name ->
            parent.InspectFile(name, Some source.Identity))

    let read (root: HeldDirectory) (projection: GameProjection) (entry: ObservedEntry) =
        match projection.Originals.TryFind entry.Path with
        | Some source -> readSource source
        | None ->
            withParent root (LogicalPath.components entry.Path) (fun parent name ->
                parent.Read(name, Some entry.Identity))

    let projectionBytes (projection: GameProjection) (token: CancellationToken) =
        let mutable metadata = 0L
        let mutable failure = None

        let account (text: string) fixedBytes =
            if failure.IsNone then
                let next = metadata + int64 (Encoding.UTF8.GetByteCount text) + fixedBytes

                if next > Limits.snapshotBytes then
                    failure <-
                        Some(FilePlanError.LimitExceeded "The game file inventory exceeds the metadata limit.")
                else
                    metadata <- next

        use links = (projection.Links :> seq<_>).GetEnumerator()

        while failure.IsNone && links.MoveNext() do
            token.ThrowIfCancellationRequested()
            let link = links.Current
            account (LogicalPath.display link.Path) 128L
            link.Entry.LinkTarget |> Option.iter (fun target -> account target 0L)

        use directories = (projection.Directories :> seq<_>).GetEnumerator()

        while failure.IsNone && directories.MoveNext() do
            token.ThrowIfCancellationRequested()
            account (LogicalPath.display directories.Current.Key) 96L

        use originals = (projection.Originals :> seq<_>).GetEnumerator()

        while failure.IsNone && originals.MoveNext() do
            token.ThrowIfCancellationRequested()
            let path, source = originals.Current.Key, originals.Current.Value
            account (LogicalPath.display path) 160L
            account (HostPath.value source.Root) 0L
            account (LogicalPath.display source.Path) 0L

        match failure with
        | Some error -> Error error
        | None -> Ok metadata

    let private validateProjection
        (root: HeldDirectory)
        (projection: GameProjection)
        (token: CancellationToken)
        =
        let mutable failure = None
        use links = (projection.Links :> seq<_>).GetEnumerator()

        while failure.IsNone && links.MoveNext() do
            token.ThrowIfCancellationRequested()
            let link = links.Current

            let actual =
                withParent root (LogicalPath.components link.Path) (fun parent name ->
                    parent.InspectEntry name)

            if actual <> Some link.Entry || link.Entry.Kind <> EntryKind.Link then
                failure <- Some FilePlanError.Stale

        use directories = (projection.Directories :> seq<_>).GetEnumerator()

        while failure.IsNone && directories.MoveNext() do
            token.ThrowIfCancellationRequested()
            let path, expected = directories.Current.Key, directories.Current.Value

            let actual =
                withParent root (LogicalPath.components path) (fun parent name ->
                    parent.InspectEntry name)

            match actual with
            | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = expected -> ()
            | _ -> failure <- Some FilePlanError.Stale

        match failure with
        | Some error -> Error error
        | None -> Ok()

    let inventory (root: HeldDirectory) (projection: GameProjection) (token: CancellationToken) =
        projectionBytes projection token
        |> Result.bind (fun initialMetadata ->
            let result = ResizeArray<ObservedEntry>()
            let mutable bytes = 0L
            let mutable metadata = initialMetadata

            let links =
                projection.Links |> List.map (fun link -> link.Path, link.Entry) |> Map.ofList

            let add (entry: ObservedEntry) =
                if result.Count >= Limits.entries then
                    Error(FilePlanError.LimitExceeded "The game folder exceeds the entry limit.")
                else
                    let nextMetadata =
                        metadata
                        + int64 (Encoding.UTF8.GetByteCount(LogicalPath.display entry.Path))
                        + 128L

                    if nextMetadata > Limits.snapshotBytes then
                        Error(FilePlanError.LimitExceeded "The game file inventory exceeds the metadata limit.")
                    elif bytes + entry.Length > Limits.contentBytes then
                        Error(FilePlanError.LimitExceeded "The game files exceed the 64 GiB content limit.")
                    else
                        metadata <- nextMetadata
                        bytes <- bytes + entry.Length
                        result.Add entry
                        Ok()

            let rec walk (directory: HeldDirectory) components depth =
                if depth > Limits.depth then
                    Error(FilePlanError.LimitExceeded "The game folder exceeds the depth limit.")
                else
                    use names = directory.Names.GetEnumerator()
                    let mutable outcome = Ok()

                    while Result.isOk outcome && names.MoveNext() do
                        token.ThrowIfCancellationRequested()
                        let name = names.Current
                        let parts = components @ [ name ]
                        let logical = path parts

                        if not (links.ContainsKey logical) then
                            outcome <-
                                match directory.InspectEntry name with
                                | Some entry when entry.Kind = EntryKind.Directory ->
                                    use child = directory.Directory(name, Some entry.Identity)

                                    match projection.Directories.TryFind logical with
                                    | Some expected when expected <> child.Identity ->
                                        Error FilePlanError.Stale
                                    | Some _ -> walk child parts (depth + 1)
                                    | None ->
                                        add
                                            { Path = logical
                                              Identity = child.Identity
                                              Directory = true
                                              Length = 0L
                                              Modified = DateTime.MinValue }
                                        |> Result.bind (fun () -> walk child parts (depth + 1))
                                | Some entry when entry.Kind = EntryKind.RegularFile ->
                                    let file = directory.InspectFile(name, Some entry.Identity)

                                    add
                                        { Path = logical
                                          Identity = file.Identity
                                          Directory = false
                                          Length = file.Length
                                          Modified = file.Modified }
                                | _ ->
                                    raise (
                                        IOException(
                                            "The game folder contains an unowned link or unavailable entry."
                                        )
                                    )

                    outcome

            validateProjection root projection token
            |> Result.bind (fun () -> walk root [] 0)
            |> Result.bind (fun () ->
                let existingPaths = result |> Seq.map _.Path |> Set.ofSeq
                use originals = (projection.Originals :> seq<_>).GetEnumerator()
                let mutable outcome = Ok()

                while Result.isOk outcome && originals.MoveNext() do
                    token.ThrowIfCancellationRequested()
                    let logical, source = originals.Current.Key, originals.Current.Value
                    let file = inspectSource source

                    outcome <-
                        if existingPaths.Contains logical then
                            Error FilePlanError.Stale
                        else
                            add
                                { Path = logical
                                  Identity = file.Identity
                                  Directory = false
                                  Length = file.Length
                                  Modified = file.Modified }

                outcome)
            |> Result.map (fun () -> result |> Seq.sortBy _.Path |> Seq.toList, bytes, metadata))
