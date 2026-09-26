namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading
open ModConductor.Platform

type internal SaveTree =
    { Root: DataRoot
      Directories: (string list * DataRoot) list
      Files: (string list * StoredDataFile) list
      Bytes: int64 }

module internal SaveTrees =
    let observe (root: DataRoot) (token: CancellationToken) progress =
        let directories = ResizeArray<string list * DataRoot>()
        let files = ResizeArray<string list * StoredDataFile>()
        let mutable bytes = 0L
        let mutable entries = 0

        let rec walk (current: DataRoot) (parts: string list) =
            if parts.Length > 128 then
                Error(ProfileDataError.Unavailable "The save folder exceeds 128 directory levels.")
            else
                use held = HeldDirectory.Open(current.Path, current.Identity)
                use names = held.Names.GetEnumerator()
                let mutable problem = None

                while problem.IsNone && names.MoveNext() do
                    match observeEntry held current parts names.Current with
                    | Ok() -> ()
                    | Error error -> problem <- Some error

                match problem with
                | Some error -> Error error
                | None -> Ok()

        and observeEntry (held: HeldDirectory) (current: DataRoot) parts name =
            token.ThrowIfCancellationRequested()
            entries <- entries + 1

            if entries > 1000000 then
                Error(ProfileDataError.Unavailable "The save folder exceeds one million entries.")
            else
                match LogicalPath.create [ name ] with
                | Error _ -> Error(ProfileDataError.Conflict "A save filename is invalid.")
                | Ok logical when not (TargetPolicy.problems TargetPolicy.windows logical).IsEmpty ->
                    Error(
                        ProfileDataError.Unavailable "A save filename is not supported by the game."
                    )
                | Ok _ -> observeKind held current (parts @ [ name ]) name

        and observeKind (held: HeldDirectory) (current: DataRoot) path name =
            match held.InspectEntry name with
            | Some entry when entry.Kind = EntryKind.Directory ->
                use child = held.Directory(name, Some entry.Identity)

                let location =
                    { Path =
                        HostPath.create (Path.Combine(HostPath.value current.Path, name))
                        |> Result.defaultWith invalidOp
                      Identity = child.Identity }
                    : DataRoot

                directories.Add(path, location)
                walk location path
            | Some entry when entry.Kind = EntryKind.RegularFile ->
                let file =
                    DataFiles.observe held name token
                    |> Option.defaultWith (fun () -> DataFiles.fail (name + " changed."))

                if file.Length > 64L * 1024L * 1024L * 1024L - bytes then
                    Error(ProfileDataError.Unavailable "The save copy exceeds 64 GiB.")
                else
                    bytes <- bytes + file.Length

                    files.Add(
                        path,
                        { Root = current
                          Name = name
                          File = file }
                    )

                    progress { Files = files.Count; Bytes = bytes }
                    Ok()
            | _ ->
                Error(
                    ProfileDataError.Unavailable
                        "The save folder contains a link or unsupported entry."
                )

        walk root []
        |> Result.map (fun () ->
            { Root = root
              Directories = List.ofSeq directories
              Files = List.ofSeq files
              Bytes = bytes })

    let copy (tree: SaveTree) (destination: DataRoot) (token: CancellationToken) progress =
        use sourceRoot = HeldDirectory.Open(tree.Root.Path, tree.Root.Identity)
        let mutable targets = Map.ofList [ [], destination ]

        for parts, source in tree.Directories do
            token.ThrowIfCancellationRequested()
            use held = HeldDirectory.Open(source.Path, source.Identity)
            let parent = targets[parts |> List.take (parts.Length - 1)]
            targets <- targets.Add(parts, DataLocations.child parent (List.last parts))

        let mutable completed = 0
        let mutable bytes = 0L

        for parts, source in tree.Files do
            token.ThrowIfCancellationRequested()
            use heldSource = HeldDirectory.Open(source.Root.Path, source.Root.Identity)
            let target = targets[parts |> List.take (parts.Length - 1)]
            use heldTarget = HeldDirectory.Open(target.Path, target.Identity)
            let name = List.last parts
            let temporary = ".mc-copy-" + Guid.NewGuid().ToString("N")
            let mutable created = None

            try
                let staged =
                    DataFiles.copy
                        heldSource
                        source.Name
                        source.File
                        heldTarget
                        temporary
                        token
                        (fun copied ->
                            progress
                                { Files = completed
                                  Bytes = bytes + copied })

                created <- Some staged.Identity

                heldTarget.MoveOriginal(
                    temporary,
                    { Identity = staged.Identity
                      Kind = EntryKind.RegularFile
                      LinkTarget = None
                      DirectoryLink = None },
                    heldTarget,
                    name
                )

                created <- None
                bytes <- bytes + staged.Length
                completed <- completed + 1
                progress { Files = completed; Bytes = bytes }
            finally
                created
                |> Option.iter (fun identity -> heldTarget.RemoveFile(temporary, identity))

    let remove (tree: SaveTree) (token: CancellationToken) progress =
        use root = HeldDirectory.Open(tree.Root.Path, tree.Root.Identity)
        let parents = tree.Directories |> Map.ofList |> Map.add [] tree.Root
        let mutable completed = 0
        let mutable bytes = 0L

        for _, source in tree.Files do
            token.ThrowIfCancellationRequested()
            use parent = HeldDirectory.Open(source.Root.Path, source.Root.Identity)
            DataFiles.check parent source.Name (Some source.File) token
            parent.RemoveFile(source.Name, source.File.Identity)
            completed <- completed + 1
            bytes <- bytes + source.File.Length
            progress { Files = completed; Bytes = bytes }

        for parts, directory in List.rev tree.Directories do
            token.ThrowIfCancellationRequested()
            let parentPath = Path.GetDirectoryName(HostPath.value directory.Path)
            let parent = parents[List.take (parts.Length - 1) parts]

            if HostPath.value parent.Path <> parentPath then
                invalidOp "The save parent changed."

            use held = HeldDirectory.Open(parent.Path, parent.Identity)
            held.RemoveDirectory(List.last parts, directory.Identity)

    let clearPrepared (root: DataRoot) =
        let rec clear (root: DataRoot) depth =
            if depth > 128 then
                DataFiles.fail "The prepared copy is too deep."

            use held = HeldDirectory.Open(root.Path, root.Identity)

            for name in held.Names |> Seq.toList do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    held.RemoveFile(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Directory ->
                    let child =
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value root.Path, name))
                            |> Result.defaultWith invalidOp
                          Identity = entry.Identity }
                        : DataRoot

                    clear child (depth + 1)
                    held.RemoveDirectory(name, entry.Identity)
                | _ -> DataFiles.fail "The prepared copy contains an unsupported entry."

        clear root 0
