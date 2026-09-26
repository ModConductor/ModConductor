namespace ModConductor.ModLibrary

open System
open System.IO
open System.Security.Cryptography
open ModConductor.Platform

type internal SourceFile =
    { Path: LogicalPath
      Identity: FileIdentity
      Length: int64
      Modified: DateTime
      Sha256: string }

type internal SourceScanFailure =
    { Error: LibraryError; Message: string }

module internal SourceFiles =
    let relative (root: HostPath) (candidate: HostPath) =
        let relative = Path.GetRelativePath(HostPath.value root, HostPath.value candidate)
        let separators = [| Path.DirectorySeparatorChar; Path.AltDirectorySeparatorChar |]

        if Path.IsPathRooted relative then
            Error LibraryError.InvalidSource
        else
            relative.Split(separators)
            |> List.ofArray
            |> LogicalPath.create
            |> Result.mapError (fun _ -> LibraryError.InvalidSource)

    let child (root: HeldDirectory) path expected forbidden =
        if (LogicalPath.components path).Length > 128 then
            Error LibraryError.FileUnavailable
        else
            let checkedChild (parent: HeldDirectory) name expected =
                let directory = parent.Directory(name, expected)

                if Set.contains directory.Identity forbidden then
                    (directory :> IDisposable).Dispose()
                    Error LibraryError.InvalidSource
                else
                    Ok directory

            let rec descend (parent: HeldDirectory) components =
                match components with
                | [] -> invalidArg "path" "Select a child folder."
                | [ name ] -> checkedChild parent name expected
                | name :: remaining ->
                    match checkedChild parent name None with
                    | Error error -> Error error
                    | Ok directory ->
                        use directory = directory
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

    let digestCheckedResult check (file: FileStream) =
        file.Position <- 0L
        let length = file.Length
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let buffer = Array.zeroCreate<byte> 65536
        let mutable remaining = length

        let mutable changed = false

        while remaining > 0L && not changed do
            check ()
            let count = file.Read(buffer, 0, int (min remaining (int64 buffer.Length)))

            if count = 0 then
                changed <- true
            else
                hash.AppendData(buffer, 0, count)
                remaining <- remaining - int64 count

        if changed || file.ReadByte() <> -1 then
            Error LibraryError.FileUnavailable
        else
            Ok(Convert.ToHexStringLower(hash.GetHashAndReset()))

    let digestChecked check file =
        digestCheckedResult check file
        |> Result.defaultWith (fun _ -> raise (IOException("The file changed while reading.")))

    let digest file = digestChecked ignore file

    let scan (root: HeldDirectory) forbidden limit check =
        let files = ResizeArray<SourceFile>()
        let mutable candidates = 0

        let rec walk (directory: HeldDirectory) components depth =
            if depth > 128 then
                Error
                    { Error = LibraryError.FileUnavailable
                      Message = "The source contains an unsupported folder or the library itself." }
            elif Set.contains directory.Identity forbidden then
                Error
                    { Error = LibraryError.FileUnavailable
                      Message = "The source contains an unsupported folder or the library itself." }
            else
                use names = directory.Names.GetEnumerator()
                let mutable failure = None

                while failure.IsNone && names.MoveNext() do
                    check ()
                    candidates <- candidates + 1

                    if candidates > limit then
                        failure <-
                            Some
                                { Error = LibraryError.LimitExceeded
                                  Message = "The source exceeds the inspection limit." }
                    else
                        let name = names.Current
                        let path = components @ [ name ]

                        let child =
                            try
                                Some(directory.Directory(name, None))
                            with :? IOException ->
                                None

                        match child with
                        | Some folder ->
                            use folder = folder

                            match walk folder path (depth + 1) with
                            | Ok() -> ()
                            | Error error -> failure <- Some error
                        | None ->
                            let stream, identity = directory.Read(name, None)
                            use stream = stream
                            let length = stream.Length
                            let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle

                            match digestCheckedResult check stream with
                            | Error error ->
                                failure <-
                                    Some
                                        { Error = error
                                          Message = "The file changed while reading." }
                            | Ok _ when
                                stream.Length <> length
                                || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
                                ->
                                failure <-
                                    Some
                                        { Error = LibraryError.SourceChanged
                                          Message = "The source files changed." }
                            | Ok sha ->
                                files.Add
                                    { Path =
                                        LogicalPath.create path
                                        |> Result.defaultWith (fun _ ->
                                            invalidOp "Invalid source name.")
                                      Identity = identity
                                      Length = length
                                      Modified = modified
                                      Sha256 = sha }

                match failure with
                | Some error -> Error error
                | None -> Ok()

        walk root [] 0
        |> Result.map (fun () ->
            (files |> Seq.sortBy (fun file -> LogicalPath.components file.Path) |> Seq.toList),
            candidates)

    let copy (source: HeldDirectory) (file: SourceFile) (destination: FileStream) check =
        let input, _ = read source file.Path (Some file.Identity)
        use input = input

        let buffer = Array.zeroCreate<byte> 65536
        let mutable remaining = file.Length

        let mutable changed =
            input.Length <> file.Length
            || File.GetLastWriteTimeUtc input.SafeFileHandle <> file.Modified

        while remaining > 0L && not changed do
            check ()
            let count = input.Read(buffer, 0, int (min remaining (int64 buffer.Length)))

            if count = 0 then
                changed <- true
            else
                destination.Write(buffer, 0, count)
                remaining <- remaining - int64 count

        if changed || input.ReadByte() <> -1 then
            Error LibraryError.SourceChanged
        else
            destination.Flush true

            if
                input.Length <> file.Length
                || File.GetLastWriteTimeUtc input.SafeFileHandle <> file.Modified
                || destination.Length <> file.Length
            then
                Error LibraryError.SourceChanged
            else
                match digestCheckedResult check destination with
                | Error error -> Error error
                | Ok digest when digest <> file.Sha256 -> Error LibraryError.SourceChanged
                | Ok _ ->
                    if OperatingSystem.IsLinux() then
                        File.SetUnixFileMode(destination.SafeFileHandle, UnixFileMode.UserRead)
                    elif OperatingSystem.IsWindows() then
                        File.SetAttributes(destination.SafeFileHandle, FileAttributes.ReadOnly)
                    else
                        raise (PlatformNotSupportedException())

                    Ok()
