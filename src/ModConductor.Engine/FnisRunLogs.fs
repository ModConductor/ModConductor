namespace ModConductor.Engine

open System
open System.IO
open System.Text

module internal FnisRunLogs =
    type FnisPathMetadata =
        { LastAccessUtc: DateTime
          LastWriteUtc: DateTime
          Attributes: FileAttributes
          UnixMode: UnixFileMode option }

    type FnisLogFileSnapshot =
        { Content: byte array
          Metadata: FnisPathMetadata }

    type FnisLogSnapshot =
        { Directory: string
          DirectoryMetadata: FnisPathMetadata
          TemporaryDirectoryMetadata: FnisPathMetadata option
          Files: Map<string, FnisLogFileSnapshot> }

    let private logLimit = 256 * 1024

    let private metadata (path: string) =
        { LastAccessUtc = File.GetLastAccessTimeUtc path
          LastWriteUtc = File.GetLastWriteTimeUtc path
          Attributes = File.GetAttributes path
          UnixMode =
            if OperatingSystem.IsWindows() then
                None
            else
                Some(File.GetUnixFileMode path) }

    let makeWritable (path: string) (directory: bool) =
        if OperatingSystem.IsWindows() then
            let attributes = File.GetAttributes path

            if attributes.HasFlag FileAttributes.ReadOnly then
                File.SetAttributes(path, attributes &&& (~~~FileAttributes.ReadOnly))
        else
            let required =
                if directory then
                    UnixFileMode.UserRead ||| UnixFileMode.UserWrite ||| UnixFileMode.UserExecute
                else
                    UnixFileMode.UserRead ||| UnixFileMode.UserWrite

            File.SetUnixFileMode(path, File.GetUnixFileMode(path) ||| required)

    let private restoreMetadata (path: string) (value: FnisPathMetadata) =
        if value.Attributes.HasFlag FileAttributes.Directory then
            Directory.SetLastAccessTimeUtc(path, value.LastAccessUtc)
            Directory.SetLastWriteTimeUtc(path, value.LastWriteUtc)
        else
            File.SetLastAccessTimeUtc(path, value.LastAccessUtc)
            File.SetLastWriteTimeUtc(path, value.LastWriteUtc)

        if OperatingSystem.IsWindows() then
            File.SetAttributes(path, value.Attributes)
        else
            value.UnixMode |> Option.iter (fun mode -> File.SetUnixFileMode(path, mode))

    let restoreLogMetadata (before: FnisLogSnapshot) =
        for KeyValue(path, value) in before.Files do
            if File.Exists path then
                restoreMetadata path value.Metadata

        before.TemporaryDirectoryMetadata
        |> Option.iter (fun value ->
            let path = Path.Combine(before.Directory, "temporary_logs")

            if Directory.Exists path then
                restoreMetadata path value)

        if Directory.Exists before.Directory then
            restoreMetadata before.Directory before.DirectoryMetadata

    let private logLike (path: string) =
        Path.GetFileName(path).Contains("log", StringComparison.OrdinalIgnoreCase)

    let private logPriority (path: string) =
        let extension = Path.GetExtension path

        if String.Equals(extension, ".xml", StringComparison.OrdinalIgnoreCase) then
            1
        elif
            logLike path
            || String.Equals(extension, ".txt", StringComparison.OrdinalIgnoreCase)
        then
            0
        else
            1

    let private logPaths (generator: string) =
        let directory = Path.GetDirectoryName generator

        let direct =
            Directory.EnumerateFiles(directory, "*", SearchOption.TopDirectoryOnly)
            |> Seq.filter logLike
            |> Seq.toList

        let temporary = Path.Combine(directory, "temporary_logs")

        let nested =
            if Directory.Exists temporary then
                Directory.EnumerateFiles(temporary, "*", SearchOption.TopDirectoryOnly)
                |> Seq.toList
            else
                []

        direct @ nested
        |> List.distinct
        |> List.sortWith (fun left right ->
            let priority = compare (logPriority left) (logPriority right)
            let pathOrder = StringComparer.OrdinalIgnoreCase.Compare(left, right)

            if priority <> 0 then priority
            elif pathOrder <> 0 then pathOrder
            else StringComparer.Ordinal.Compare(left, right))

    let private readBounded path limit =
        use stream =
            File.Open(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.ReadWrite ||| FileShare.Delete
            )

        if stream.Length > int64 limit then
            raise (InvalidDataException "FNIS temporary logs exceed 256 KiB.")

        let bytes = Array.zeroCreate<byte> (int stream.Length)
        let mutable offset = 0

        while offset < bytes.Length do
            let read = stream.Read(bytes, offset, bytes.Length - offset)

            if read = 0 then
                offset <- bytes.Length
            else
                offset <- offset + read

        bytes

    let private readPrefix path limit =
        use stream =
            File.Open(
                path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.ReadWrite ||| FileShare.Delete
            )

        let bytes =
            Array.zeroCreate<byte> (min limit (int (min (int64 Int32.MaxValue) stream.Length)))

        let mutable offset = 0

        while offset < bytes.Length do
            let read = stream.Read(bytes, offset, bytes.Length - offset)

            if read = 0 then
                offset <- bytes.Length
            else
                offset <- offset + read

        bytes

    let logSnapshot (generator: string) =
        let directory = Path.GetDirectoryName generator
        let temporary = Path.Combine(directory, "temporary_logs")
        let directoryMetadata = metadata directory

        let temporaryMetadata =
            if Directory.Exists temporary then
                Some(metadata temporary)
            else
                None

        try
            let paths = logPaths generator

            if paths.Length > 32 then
                raise (InvalidDataException "FNIS has more than 32 temporary logs.")

            let fileMetadata = paths |> List.map (fun path -> path, metadata path) |> Map.ofList

            try
                let mutable remaining = logLimit

                let files =
                    paths
                    |> List.map (fun path ->
                        let content = readBounded path remaining
                        remaining <- remaining - content.Length

                        path,
                        { Content = content
                          Metadata = fileMetadata[path] })
                    |> Map.ofList

                { Directory = directory
                  DirectoryMetadata = directoryMetadata
                  TemporaryDirectoryMetadata = temporaryMetadata
                  Files = files }
            finally
                for KeyValue(path, value) in fileMetadata do
                    restoreMetadata path value
        finally
            temporaryMetadata |> Option.iter (fun value -> restoreMetadata temporary value)
            restoreMetadata directory directoryMetadata

    let private utf8PrefixLength (bytes: byte array) limit =
        let mutable count = min bytes.Length limit

        while count > 0 && count < bytes.Length && bytes[count] &&& 0xC0uy = 0x80uy do
            count <- count - 1

        count

    let captureAndRestoreLogs (generator: string) (before: FnisLogSnapshot) =
        let temporary = Path.Combine(before.Directory, "temporary_logs")
        use builder = new MemoryStream()
        let mutable truncated = false
        let mutable afterPaths = []
        let mutable cleanupError: exn option = None

        let append (value: string) =
            let bytes = Encoding.UTF8.GetBytes value
            let count = utf8PrefixLength bytes (logLimit - int builder.Length)
            builder.Write(bytes, 0, count)
            truncated <- truncated || count < bytes.Length

        let attempt action =
            try
                action ()
            with error ->
                if cleanupError.IsNone then
                    cleanupError <- Some error

        try
            makeWritable before.Directory true

            if Directory.Exists temporary then
                makeWritable temporary true

            afterPaths <- logPaths generator

            for path in afterPaths do
                makeWritable path false

            let changedPaths =
                afterPaths
                |> List.filter (fun path ->
                    before.Files
                    |> Map.tryFind path
                    |> Option.forall (fun prior ->
                        FileInfo(path).Length <> int64 prior.Content.Length
                        || readBounded path prior.Content.Length <> prior.Content))

            for path in changedPaths |> List.truncate 32 do
                if not truncated then
                    if builder.Length > 0L then
                        append "\n"

                    append ("== " + Path.GetFileName path + " ==\n")

                    if not truncated then
                        let content = readPrefix path logLimit
                        append (Encoding.UTF8.GetString content)
                        truncated <- truncated || int64 content.Length < FileInfo(path).Length

            truncated <- truncated || changedPaths.Length > 32
        finally
            for path in afterPaths do
                match before.Files |> Map.tryFind path with
                | None -> attempt (fun () -> File.Delete path)
                | Some prior -> attempt (fun () -> File.WriteAllBytes(path, prior.Content))

            for KeyValue(path, prior) in before.Files do
                if not (File.Exists path) then
                    let parent = Path.GetDirectoryName path
                    attempt (fun () -> Directory.CreateDirectory parent |> ignore)

                    if Directory.Exists parent then
                        attempt (fun () -> makeWritable parent true)

                    attempt (fun () -> File.WriteAllBytes(path, prior.Content))

                if File.Exists path then
                    attempt (fun () -> restoreMetadata path prior.Metadata)

            match before.TemporaryDirectoryMetadata with
            | Some value ->
                if not (Directory.Exists temporary) then
                    attempt (fun () -> Directory.CreateDirectory temporary |> ignore)

                if Directory.Exists temporary then
                    attempt (fun () -> restoreMetadata temporary value)
            | None when Directory.Exists temporary ->
                attempt (fun () -> makeWritable temporary true)
                attempt (fun () -> Directory.Delete(temporary, true))
            | None -> ()

            attempt (fun () -> restoreMetadata before.Directory before.DirectoryMetadata)

        cleanupError |> Option.iter raise

        let bytes = builder.ToArray()

        if truncated then
            let notice =
                Encoding.UTF8.GetBytes "\n[FNIS run log truncated: byte or file limit reached.]\n"

            let count = utf8PrefixLength bytes (logLimit - notice.Length)
            Array.append bytes[.. count - 1] notice
        else
            bytes
