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

module GameFiles =
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

    let acquireProjected
        (projection: GameProjection)
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
            let entries, total, metadata = GameInventory.inventory root projection token

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
                    let stream, _ = GameInventory.read root projection entry
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

            let after, _, _ = GameInventory.inventory root projection token

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
              Projection = projection
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
            let entries, _, _ = GameInventory.inventory root observation.Projection token
            entries = observation.Entries)

    let internal reuse projection (observation: GameObservation) token =
        protect (fun () ->
            use root = HeldDirectory.Open(observation.Root, observation.Identity)
            let entries, _, metadata = GameInventory.inventory root projection token

            if entries <> observation.Entries then
                raise (ScanChangedException())

            { observation with
                Projection = projection
                EncodedBytes = metadata })

    let acquire evidence rootId progress token =
        acquireProjected GameProjection.empty evidence rootId progress token
