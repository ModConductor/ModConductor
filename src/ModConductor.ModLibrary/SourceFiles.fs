namespace ModConductor.ModLibrary

open System
open System.IO
open System.Security.Cryptography
open ModConductor.Platform

type internal SourceChangedException() =
    inherit IOException("The source files changed.")

type internal SourceOverlapException() =
    inherit IOException("The source overlaps the library.")

type internal SourceLimitException() =
    inherit IOException("The source exceeds the inspection limit.")

type internal SourceFile =
    { Path: LogicalPath
      Identity: FileIdentity
      Length: int64
      Modified: DateTime
      Sha256: string }

module internal SourceFiles =
    let child (root: HeldDirectory) path expected forbidden =
        if (LogicalPath.components path).Length > 128 then
            raise (IOException("The source folder is too deep."))

        let checkedChild (parent: HeldDirectory) name expected =
            let directory = parent.Directory(name, expected)

            if Set.contains directory.Identity forbidden then
                (directory :> IDisposable).Dispose()
                raise (SourceOverlapException())

            directory

        let rec descend (parent: HeldDirectory) components =
            match components with
            | [] -> invalidArg "path" "Select a child folder."
            | [ name ] -> checkedChild parent name expected
            | name :: remaining ->
                use directory = checkedChild parent name None
                descend directory remaining

        descend root (LogicalPath.components path)

    let read (root: HeldDirectory) path expected =
        let rec descend (parent: HeldDirectory) components =
            match components with
            | [] -> invalidArg "path" "Select a file."
            | [ name ] -> parent.Read(name, expected)
            | name :: remaining ->
                use directory = parent.Directory(name, None)
                descend directory remaining

        descend root (LogicalPath.components path)

    let digestChecked check (file: FileStream) =
        file.Position <- 0L
        let length = file.Length
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let buffer = Array.zeroCreate<byte> 65536
        let mutable remaining = length

        while remaining > 0L do
            check ()
            let count = file.Read(buffer, 0, int (min remaining (int64 buffer.Length)))

            if count = 0 then
                raise (IOException("The file changed while reading."))

            hash.AppendData(buffer, 0, count)
            remaining <- remaining - int64 count

        if file.ReadByte() <> -1 then
            raise (IOException("The file changed while reading."))

        Convert.ToHexStringLower(hash.GetHashAndReset())

    let digest file = digestChecked ignore file

    let scan (root: HeldDirectory) forbidden limit check =
        let files = ResizeArray<SourceFile>()
        let mutable candidates = 0

        let rec walk (directory: HeldDirectory) components depth =
            if depth > 128 || Set.contains directory.Identity forbidden then
                raise (
                    IOException("The source contains an unsupported folder or the library itself.")
                )

            for name in directory.Names do
                check ()
                candidates <- candidates + 1

                if candidates > limit then
                    raise (SourceLimitException())

                let path = components @ [ name ]

                let child =
                    try
                        Some(directory.Directory(name, None))
                    with :? IOException ->
                        None

                match child with
                | Some folder ->
                    use folder = folder
                    walk folder path (depth + 1)
                | None ->
                    let stream, identity = directory.Read(name, None)
                    use stream = stream
                    let length = stream.Length
                    let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle
                    let sha = digestChecked check stream

                    if
                        stream.Length <> length
                        || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
                    then
                        raise (SourceChangedException())

                    files.Add
                        { Path =
                            LogicalPath.create path
                            |> Result.defaultWith (fun _ -> invalidOp "Invalid source name.")
                          Identity = identity
                          Length = length
                          Modified = modified
                          Sha256 = sha }

        walk root [] 0

        (files |> Seq.sortBy (fun file -> LogicalPath.components file.Path) |> Seq.toList),
        candidates

    let copy (source: HeldDirectory) (file: SourceFile) (destination: FileStream) check =
        let input, _ = read source file.Path (Some file.Identity)
        use input = input

        if
            input.Length <> file.Length
            || File.GetLastWriteTimeUtc input.SafeFileHandle <> file.Modified
        then
            raise (SourceChangedException())

        let buffer = Array.zeroCreate<byte> 65536
        let mutable remaining = file.Length

        while remaining > 0L do
            check ()
            let count = input.Read(buffer, 0, int (min remaining (int64 buffer.Length)))

            if count = 0 then
                raise (SourceChangedException())

            destination.Write(buffer, 0, count)
            remaining <- remaining - int64 count

        if input.ReadByte() <> -1 then
            raise (SourceChangedException())

        destination.Flush true

        if
            input.Length <> file.Length
            || File.GetLastWriteTimeUtc input.SafeFileHandle <> file.Modified
            || destination.Length <> file.Length
            || digestChecked check destination <> file.Sha256
        then
            raise (SourceChangedException())

        if OperatingSystem.IsLinux() then
            File.SetUnixFileMode(destination.SafeFileHandle, UnixFileMode.UserRead)
        elif OperatingSystem.IsWindows() then
            File.SetAttributes(destination.SafeFileHandle, FileAttributes.ReadOnly)
        else
            raise (PlatformNotSupportedException())
