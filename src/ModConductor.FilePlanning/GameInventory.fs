namespace ModConductor.FilePlanning

open System
open System.IO
open System.Text
open System.Threading
open ModConductor.Platform

type internal ScanLimitException(message: string) =
    inherit IOException(message)

type internal ScanChangedException() =
    inherit IOException("Game files changed. Refresh to check them again.")

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

    let read (root: HeldDirectory) (projection: GameProjection) (entry: ObservedEntry) =
        match projection.Originals.TryFind entry.Path with
        | Some source -> readSource source
        | None ->
            withParent root (LogicalPath.components entry.Path) (fun parent name ->
                parent.Read(name, Some entry.Identity))

    let projectionBytes (projection: GameProjection) (token: CancellationToken) =
        let mutable metadata = 0L

        let account (text: string) fixedBytes =
            metadata <- metadata + int64 (Encoding.UTF8.GetByteCount text) + fixedBytes

            if metadata > Limits.snapshotBytes then
                raise (ScanLimitException("The game file inventory exceeds the metadata limit."))

        for link in projection.Links do
            token.ThrowIfCancellationRequested()
            account (LogicalPath.display link.Path) 128L
            link.Entry.LinkTarget |> Option.iter (fun target -> account target 0L)

        for KeyValue(path, _) in projection.Directories do
            token.ThrowIfCancellationRequested()
            account (LogicalPath.display path) 96L

        for KeyValue(path, source) in projection.Originals do
            token.ThrowIfCancellationRequested()
            account (LogicalPath.display path) 160L
            account (HostPath.value source.Root) 0L
            account (LogicalPath.display source.Path) 0L

        metadata

    let inventory (root: HeldDirectory) (projection: GameProjection) (token: CancellationToken) =
        let result = ResizeArray<ObservedEntry>()
        let mutable bytes = 0L
        let mutable metadata = projectionBytes projection token

        let links =
            projection.Links |> List.map (fun link -> link.Path, link.Entry) |> Map.ofList

        for link in projection.Links do
            token.ThrowIfCancellationRequested()

            let actual =
                withParent root (LogicalPath.components link.Path) (fun parent name ->
                    parent.InspectEntry name)

            if actual <> Some link.Entry || link.Entry.Kind <> EntryKind.Link then
                raise (ScanChangedException())

        for KeyValue(path, expected) in projection.Directories do
            token.ThrowIfCancellationRequested()

            let actual =
                withParent root (LogicalPath.components path) (fun parent name ->
                    parent.InspectEntry name)

            match actual with
            | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = expected -> ()
            | _ -> raise (ScanChangedException())

        let add (entry: ObservedEntry) =
            if result.Count >= Limits.entries then
                raise (ScanLimitException("The game folder exceeds the entry limit."))

            metadata <-
                metadata
                + int64 (Encoding.UTF8.GetByteCount(LogicalPath.display entry.Path))
                + 128L

            if metadata > Limits.snapshotBytes then
                raise (ScanLimitException("The game file inventory exceeds the metadata limit."))

            bytes <- bytes + entry.Length

            if bytes > Limits.contentBytes then
                raise (ScanLimitException("The game files exceed the 64 GiB content limit."))

            result.Add entry

        let rec walk (directory: HeldDirectory) components depth =
            if depth > Limits.depth then
                raise (ScanLimitException("The game folder exceeds the depth limit."))

            for name in directory.Names do
                token.ThrowIfCancellationRequested()
                let parts = components @ [ name ]
                let logical = path parts

                if not (links.ContainsKey logical) then
                    match directory.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        use child = directory.Directory(name, Some entry.Identity)

                        match projection.Directories.TryFind logical with
                        | Some expected when expected = child.Identity -> ()
                        | Some _ -> raise (ScanChangedException())
                        | None ->
                            add
                                { Path = logical
                                  Identity = child.Identity
                                  Directory = true
                                  Length = 0L
                                  Modified = DateTime.MinValue }

                        walk child parts (depth + 1)
                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                        let stream, identity = directory.Read(name, Some entry.Identity)
                        use stream = stream

                        add
                            { Path = logical
                              Identity = identity
                              Directory = false
                              Length = stream.Length
                              Modified = File.GetLastWriteTimeUtc stream.SafeFileHandle }
                    | _ ->
                        raise (
                            IOException(
                                "The game folder contains an unowned link or unavailable entry."
                            )
                        )

        walk root [] 0

        let existingPaths = result |> Seq.map _.Path |> Set.ofSeq

        for KeyValue(logical, source) in projection.Originals do
            token.ThrowIfCancellationRequested()
            let stream, identity = readSource source
            use stream = stream

            if existingPaths.Contains logical then
                raise (ScanChangedException())

            add
                { Path = logical
                  Identity = identity
                  Directory = false
                  Length = stream.Length
                  Modified = File.GetLastWriteTimeUtc stream.SafeFileHandle }

        result |> Seq.sortBy _.Path |> Seq.toList, bytes, metadata
