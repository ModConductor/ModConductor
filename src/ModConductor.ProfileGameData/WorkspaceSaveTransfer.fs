namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Collections.Generic
open System.Threading
open ModConductor.Platform

module internal WorkspaceSaveTransfer =
    let private directoryExists (path: string) =
        try
            (File.GetAttributes path).HasFlag FileAttributes.Directory
        with
        | :? FileNotFoundException
        | :? DirectoryNotFoundException -> false

    let rec hasFiles (root: DataRoot) =
        if not (directoryExists (HostPath.value root.Path)) then
            false
        else
            use held = HeldDirectory.Open(root.Path, root.Identity)

            held.Names
            |> Seq.exists (fun name ->
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    hasFiles
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value root.Path, name))
                            |> Result.defaultWith invalidOp
                          Identity = entry.Identity }
                | Some _ -> true
                | None -> false)

    let private groups (source: HeldDirectory) =
        let files =
            source.Names
            |> Seq.choose (fun name ->
                match source.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.RegularFile -> Some(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Directory -> None
                | None -> None
                | Some _ -> raise (IOException "A private save is not a regular file."))
            |> Seq.toList

        let companions =
            files
            |> List.filter (fun (name, _) ->
                Path.GetExtension(name).Equals(".skse", StringComparison.OrdinalIgnoreCase))

        let paired = HashSet<string>(StringComparer.OrdinalIgnoreCase)

        let saves =
            files
            |> List.filter (fun (name, _) ->
                Path.GetExtension(name).Equals(".ess", StringComparison.OrdinalIgnoreCase))
            |> List.map (fun ((name, _) as save) ->
                let matching =
                    companions
                    |> List.filter (fun (other, _) ->
                        Path
                            .GetFileNameWithoutExtension(other)
                            .Equals(
                                Path.GetFileNameWithoutExtension(name),
                                StringComparison.OrdinalIgnoreCase
                            ))

                if matching.Length > 1 then
                    raise (IOException "A save has more than one matching co-save.")

                for other, _ in matching do
                    paired.Add other |> ignore

                save :: matching)

        saves
        @ (files
           |> List.filter (fun (name, _) ->
               not (Path.GetExtension(name).Equals(".ess", StringComparison.OrdinalIgnoreCase))
               && not (paired.Contains name))
           |> List.map List.singleton)

    let private targetNames (occupied: HashSet<string>) (files: (string * FileIdentity) list) =
        let first = fst files.Head
        let basename = Path.GetFileNameWithoutExtension first

        let rec choose index =
            let stem =
                if index = 0 then
                    basename
                else
                    basename + " (" + string index + ")"

            let names = files |> List.map (fun (name, _) -> stem + Path.GetExtension name)

            let saveGroup =
                files
                |> List.exists (fun (name, _) ->
                    let extension = Path.GetExtension name

                    extension.Equals(".ess", StringComparison.OrdinalIgnoreCase)
                    || extension.Equals(".skse", StringComparison.OrdinalIgnoreCase))

            let reserved =
                if saveGroup then
                    [ stem + ".ess"; stem + ".skse" ]
                else
                    names

            if reserved |> List.exists occupied.Contains then
                choose (index + 1)
            else
                reserved |> List.iter (occupied.Add >> ignore)
                names

        choose 0

    let private copyGroup
        (source: HeldDirectory)
        (destination: HeldDirectory)
        files
        names
        (token: CancellationToken)
        =
        for (name, identity), target in List.zip files names do
            token.ThrowIfCancellationRequested()
            use input = fst (source.Read(name, Some identity))
            use output = fst (destination.Create target)
            input.CopyTo output
            output.Flush true

        for name, identity in files do
            source.RemoveFile(name, identity)

    let rec private moveDirectory (sourceRoot: DataRoot) (destinationRoot: DataRoot) token =
        use source = HeldDirectory.Open(sourceRoot.Path, sourceRoot.Identity)
        use destination = HeldDirectory.Open(destinationRoot.Path, destinationRoot.Identity)
        let occupied = HashSet<string>(destination.Names, StringComparer.OrdinalIgnoreCase)

        for files in groups source do
            copyGroup source destination files (targetNames occupied files) token

        for name in source.Names |> Seq.toList do
            match source.InspectEntry name with
            | Some entry when entry.Kind = EntryKind.Directory ->
                let existing =
                    destination.Names
                    |> Seq.tryFind (fun actual ->
                        actual.Equals(name, StringComparison.OrdinalIgnoreCase))

                let actual = existing |> Option.defaultValue name

                use child =
                    match destination.InspectEntry actual with
                    | None -> destination.CreateDirectory actual
                    | Some item when item.Kind = EntryKind.Directory ->
                        destination.Directory(actual, Some item.Identity)
                    | Some _ ->
                        raise (
                            IOException
                                "A folder in the game save destination conflicts with a private save folder."
                        )

                let childRoot: DataRoot =
                    { Path =
                        HostPath.create (Path.Combine(HostPath.value destinationRoot.Path, actual))
                        |> Result.defaultWith invalidOp
                      Identity = child.Identity }

                moveDirectory
                    { Path =
                        HostPath.create (Path.Combine(HostPath.value sourceRoot.Path, name))
                        |> Result.defaultWith invalidOp
                      Identity = entry.Identity }
                    childRoot
                    token
            | _ -> ()

    let move (root: DataRoot) destination token =
        if hasFiles root then
            Directory.CreateDirectory destination |> ignore

            let target =
                DataLocations.root destination
                |> Result.defaultWith (fun _ ->
                    raise (IOException "The game save folder could not be opened."))

            moveDirectory root target token
