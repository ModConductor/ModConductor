namespace ModConductor.FilePlanning

open System
open System.IO
open System.Diagnostics
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.DeploymentPlanning

type internal ScanLimitException(message: string) =
    inherit IOException(message)

type internal ScanChangedException() =
    inherit IOException("Game files changed. Refresh to check them again.")

module GameFiles =
    let private path components =
        LogicalPath.create components
        |> Result.defaultWith (fun _ ->
            raise (IOException("The game folder contains an invalid file name.")))

    let private encoded path =
        int64 (Encoding.UTF8.GetByteCount(LogicalPath.display path) + 128)

    let private inventory (root: HeldDirectory) (token: CancellationToken) =
        let result = ResizeArray<ObservedEntry>()
        let mutable bytes = 0L
        let mutable metadata = 0L

        let rec walk (directory: HeldDirectory) components depth =
            if depth > Limits.depth then
                raise (ScanLimitException("The game folder exceeds the depth limit."))

            for name in directory.Names do
                token.ThrowIfCancellationRequested()

                if result.Count >= Limits.entries then
                    raise (ScanLimitException("The game folder exceeds the entry limit."))

                let parts = components @ [ name ]
                let logical = path parts
                metadata <- metadata + encoded logical

                if metadata > Limits.snapshotBytes then
                    raise (
                        ScanLimitException("The game file inventory exceeds the metadata limit.")
                    )

                let child =
                    try
                        Some(directory.Directory(name, None))
                    with :? IOException ->
                        None

                match child with
                | Some child ->
                    use child = child

                    result.Add
                        { Path = logical
                          Identity = child.Identity
                          Directory = true
                          Length = 0L
                          Modified = DateTime.MinValue }

                    walk child parts (depth + 1)
                | None ->
                    let stream, identity = directory.Read(name, None)
                    use stream = stream
                    bytes <- bytes + stream.Length

                    if bytes > Limits.contentBytes then
                        raise (
                            ScanLimitException("The game files exceed the 64 GiB content limit.")
                        )

                    result.Add
                        { Path = logical
                          Identity = identity
                          Directory = false
                          Length = stream.Length
                          Modified = File.GetLastWriteTimeUtc stream.SafeFileHandle }

        walk root [] 0
        result |> Seq.sortBy _.Path |> Seq.toList, bytes, metadata

    let private read (root: HeldDirectory) (entry: ObservedEntry) =
        let rec descend (directory: HeldDirectory) =
            function
            | [] -> invalidOp "A file path cannot be empty."
            | [ name ] -> directory.Read(name, Some entry.Identity)
            | name :: rest ->
                use child = directory.Directory(name, None)
                descend child rest

        descend root (LogicalPath.components entry.Path)

    let private protect action =
        try
            Ok(action ())
        with
        | :? OperationCanceledException -> Error FilePlanError.Cancelled
        | :? ScanLimitException as e -> Error(FilePlanError.LimitExceeded e.Message)
        | :? ScanChangedException -> Error FilePlanError.Stale
        | :? IOException as e -> Error(FilePlanError.FileUnavailable e.Message)
        | :? UnauthorizedAccessException ->
            Error(FilePlanError.FileUnavailable "The game files cannot be read.")

    let acquire
        (evidence: InstallationEvidence)
        rootId
        (progress: AcquisitionProgress -> unit)
        token
        =
        protect (fun () ->
            let directory =
                evidence.DataPath
                |> Option.defaultWith (fun () ->
                    raise (IOException("Select a checked game installation.")))

            let identity =
                evidence.DataIdentity
                |> Option.defaultWith (fun () ->
                    raise (IOException("The game Data folder has no checked identity.")))

            let rootPath =
                HostPath.create directory
                |> Result.defaultWith (fun _ ->
                    raise (IOException("The checked Data path is invalid.")))

            use root = HeldDirectory.Open(rootPath, identity)
            let entries, total, metadata = inventory root token

            let totalFiles =
                entries |> List.filter (fun entry -> not entry.Directory) |> List.length

            let files = ResizeArray<SnapshotFile>()
            let mutable doneBytes = 0L
            let clock = Stopwatch.StartNew()

            let notify force =
                if force || clock.ElapsedMilliseconds >= 100L then
                    progress
                        { Files = files.Count
                          TotalFiles = totalFiles
                          Bytes = doneBytes
                          TotalBytes = total }

                    clock.Restart()

            notify true
            let buffer = Array.zeroCreate<byte> 65536

            for entry in entries do
                token.ThrowIfCancellationRequested()

                if not entry.Directory then
                    let stream, _ = read root entry
                    use stream = stream

                    if
                        stream.Length <> entry.Length
                        || File.GetLastWriteTimeUtc stream.SafeFileHandle <> entry.Modified
                    then
                        raise (ScanChangedException())

                    use digest = IncrementalHash.CreateHash HashAlgorithmName.SHA256
                    let mutable remaining = entry.Length

                    while remaining > 0L do
                        token.ThrowIfCancellationRequested()

                        let count =
                            stream.Read(buffer, 0, int (min remaining (int64 buffer.Length)))

                        if count = 0 then
                            raise (ScanChangedException())

                        digest.AppendData(buffer, 0, count)
                        remaining <- remaining - int64 count
                        doneBytes <- doneBytes + int64 count

                        notify false

                    if
                        stream.ReadByte() <> -1
                        || stream.Length <> entry.Length
                        || File.GetLastWriteTimeUtc stream.SafeFileHandle <> entry.Modified
                    then
                        raise (ScanChangedException())

                    files.Add
                        { Path = entry.Path
                          Length = entry.Length
                          Sha256 = Convert.ToHexStringLower(digest.GetHashAndReset()) }

            let after, _, _ = inventory root token

            if after <> entries then
                raise (ScanChangedException())

            use reopened = HeldDirectory.Open(rootPath, identity)
            notify true

            let generation =
                use data = new MemoryStream()
                use writer = new BinaryWriter(data, Encoding.UTF8, true)
                writer.Write evidence.Fingerprint

                for entry in entries do
                    writer.Write(LogicalPath.display entry.Path)

                    match entry.Identity.Device with
                    | LinuxDevice(major, minor) ->
                        writer.Write 1
                        writer.Write major
                        writer.Write minor
                    | WindowsVolume serial ->
                        writer.Write 2
                        writer.Write serial

                    writer.Write entry.Identity.Low
                    writer.Write entry.Identity.High
                    writer.Write entry.Directory
                    writer.Write entry.Length
                    writer.Write entry.Modified.Ticks

                for file in files do
                    writer.Write file.Sha256

                writer.Flush()

                SHA256.HashData(data.GetBuffer().AsSpan(0, int data.Length))
                |> Convert.ToHexStringLower

            { ContextFingerprint = evidence.Fingerprint
              Root = rootPath
              Identity = identity
              Entries = entries
              EncodedBytes = metadata
              ObservedAt = DateTimeOffset.UtcNow
              Snapshot =
                { Id = rootId
                  Generation = generation
                  Kind = ReadOnlyLayerKind.Base
                  Priority = 0
                  Complete = true
                  Files = List.ofSeq files
                  Mappings =
                    [ { SourcePrefix = PlanPath.Root
                        TargetRoot = rootId
                        TargetPrefix = PlanPath.Root } ]
                  Archives = [] } })

    let current (observation: GameObservation) token =
        protect (fun () ->
            use root = HeldDirectory.Open(observation.Root, observation.Identity)
            let entries, _, _ = inventory root token
            entries = observation.Entries)
