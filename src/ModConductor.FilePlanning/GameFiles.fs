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
            action ()
        with
        | :? OperationCanceledException -> Error FilePlanError.Cancelled
        | :? IOException as e -> Error(FilePlanError.FileUnavailable e.Message)
        | :? UnauthorizedAccessException ->
            Error(FilePlanError.FileUnavailable "The game files cannot be read.")

    let acquireProjected
        (projection: GameProjection)
        (evidence: InstallationEvidence)
        rootId
        (progress: AcquisitionProgress -> unit)
        (token: CancellationToken)
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

            let produce ((entries, total, metadata): ObservedEntry list * int64 * int64) =
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

                for entry in entries do
                    token.ThrowIfCancellationRequested()

                    if not entry.Directory then
                        files.Add
                            { Path = entry.Path
                              Identity =
                                SnapshotFileIdentity.Metadata
                                    { Identity = entry.Identity
                                      Length = entry.Length
                                      Modified = entry.Modified } }

                        doneBytes <- doneBytes + entry.Length
                        notify false

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
                      Archives = [] } }

            GameInventory.inventory root projection token |> Result.map produce)

    let current (observation: GameObservation) token =
        protect (fun () ->
            use root = HeldDirectory.Open(observation.Root, observation.Identity)

            GameInventory.inventory root observation.Projection token
            |> Result.map (fun (entries, _, _) -> entries = observation.Entries))

    let internal reuse projection (observation: GameObservation) token =
        protect (fun () ->
            use root = HeldDirectory.Open(observation.Root, observation.Identity)

            GameInventory.inventory root projection token
            |> Result.bind (fun (entries, _, metadata) ->
                if entries <> observation.Entries then
                    Error FilePlanError.Stale
                else
                    Ok
                        { observation with
                            Projection = projection
                            EncodedBytes = metadata }))

    let acquire evidence rootId progress token =
        acquireProjected GameProjection.empty evidence rootId progress token

    let private checkedEntry (observation: GameObservation) (source: CheckedGamePreviewSource) =
        if
            observation.Snapshot.Id <> source.SnapshotId
            || observation.Snapshot.Generation <> source.Generation
            || observation.Snapshot.Kind <> source.Kind
        then
            Error FilePlanError.Stale
        else
            match
                observation.Entries
                |> List.tryFind (fun entry -> not entry.Directory && entry.Path = source.SourcePath)
            with
            | Some entry when entry.Length = source.Length -> Ok entry
            | _ -> Error FilePlanError.Stale

    let readChecked
        (observation: GameObservation)
        (source: CheckedGamePreviewSource)
        token
        consume
        =
        protect (fun () ->
            checkedEntry observation source
            |> Result.bind (fun entry ->
                use root = HeldDirectory.Open(observation.Root, observation.Identity)
                let stream, _ = GameInventory.read root observation.Projection entry
                use stream = stream

                let unchanged () =
                    stream.Length = entry.Length
                    && File.GetLastWriteTimeUtc stream.SafeFileHandle = entry.Modified

                if not (unchanged ()) then
                    Error FilePlanError.Stale
                else
                    let result = consume stream

                    if unchanged () then
                        Ok result
                    else
                        Error FilePlanError.Stale))
