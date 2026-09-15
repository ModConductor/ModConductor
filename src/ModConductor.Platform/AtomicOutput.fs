namespace ModConductor.Platform

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks

[<RequireQualifiedAccess>]
type AtomicOutputError =
    | InvalidPath
    | ParentUnavailable
    | UnsupportedDestination
    | ReplacementRequired
    | DestinationChanged
    | Cancelled
    | WriteFailed

type internal OutputFingerprint =
    { Entry: HeldEntry
      Length: int64
      Sample: string }

type AtomicOutputDestination =
    internal
        { OutputId: Guid
          OutputPath: HostPath
          OutputParent: HostPath
          OutputParentIdentity: FileIdentity
          OutputName: string
          ExistingFingerprint: OutputFingerprint option }

    member this.Id = this.OutputId
    member this.Exists = this.ExistingFingerprint.IsSome
    member this.FileName = this.OutputName

type AtomicOutputResult = { Path: HostPath; Length: int64 }

type AtomicOutputCommitBoundary =
    { BeforeReplace: unit -> unit
      AfterReplace: unit -> unit }

module AtomicOutput =
    let private readSample (stream: FileStream) =
        let buffer = Array.zeroCreate<byte> 65536
        use hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256)
        let length = stream.Length

        let read count =
            let mutable offset = 0

            while offset < count do
                let next = stream.Read(buffer, offset, count - offset)

                if next = 0 then
                    raise (EndOfStreamException())

                offset <- offset + next

            hash.AppendData(buffer, 0, count)

        read (int (min length (int64 buffer.Length)))

        if length > int64 buffer.Length then
            stream.Position <- max (int64 buffer.Length) (length - int64 buffer.Length)
            read (int (length - stream.Position))

        length, Convert.ToHexString(hash.GetHashAndReset())

    let private fingerprint (directory: HeldDirectory) name entry =
        let opened, identity = directory.Read(name, Some entry.Identity)
        use stream = opened

        if identity <> entry.Identity then
            raise (IOException "The destination changed.")

        let length, sample = readSample stream

        { Entry = entry
          Length = length
          Sample = sample }

    let private observe (directory: HeldDirectory) name =
        match directory.InspectEntry name with
        | None -> Ok None
        | Some entry when entry.Kind = EntryKind.RegularFile ->
            try
                Ok(Some(fingerprint directory name entry))
            with :? IOException ->
                Error AtomicOutputError.DestinationChanged
        | Some _ -> Error AtomicOutputError.UnsupportedDestination

    let inspect (path: HostPath) =
        try
            let value = HostPath.value path
            let parent = Path.GetDirectoryName value
            let name = Path.GetFileName value

            if
                String.IsNullOrWhiteSpace parent
                || String.IsNullOrWhiteSpace name
                || name = "."
                || name = ".."
                || name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0
            then
                Error AtomicOutputError.InvalidPath
            else
                match HostPath.create parent, Native.facts parent with
                | Ok parentPath,
                  Ok { File = Known identity
                       Kind = EntryKind.Directory } ->
                    use directory = HeldDirectory.Open(parentPath, identity)

                    observe directory name
                    |> Result.map (fun existing ->
                        { OutputId = Guid.NewGuid()
                          OutputPath = path
                          OutputParent = parentPath
                          OutputParentIdentity = identity
                          OutputName = name
                          ExistingFingerprint = existing })
                | Ok _, Ok _ -> Error AtomicOutputError.ParentUnavailable
                | _ -> Error AtomicOutputError.ParentUnavailable
        with
        | :? ArgumentException -> Error AtomicOutputError.InvalidPath
        | :? IOException
        | :? UnauthorizedAccessException -> Error AtomicOutputError.ParentUnavailable

    let private unchanged directory value =
        match observe directory value.OutputName with
        | Ok actual -> actual = value.ExistingFingerprint
        | Error _ -> false

    let writeWithBoundary
        (boundary: AtomicOutputCommitBoundary)
        (destination: AtomicOutputDestination)
        replace
        (writeContent: FileStream -> CancellationToken -> Task<int64>)
        (token: CancellationToken)
        =
        task {
            if destination.ExistingFingerprint.IsSome && not replace then
                return Error AtomicOutputError.ReplacementRequired
            else
                let mutable temporaryName = ""
                let mutable temporaryIdentity = None
                let mutable committed = false
                let mutable preserveTemporary = false

                try
                    try
                        use directory =
                            HeldDirectory.Open(
                                destination.OutputParent,
                                destination.OutputParentIdentity
                            )

                        if not (unchanged directory destination) then
                            return Error AtomicOutputError.DestinationChanged
                        else
                            token.ThrowIfCancellationRequested()
                            temporaryName <- ".mc-csv-" + Guid.NewGuid().ToString("N") + ".tmp"
                            let stream, identity = directory.Create temporaryName
                            temporaryIdentity <- Some identity

                            let! length =
                                task {
                                    use output = stream
                                    let! written = writeContent output token
                                    do! output.FlushAsync token
                                    output.Flush true
                                    return written
                                }

                            token.ThrowIfCancellationRequested()

                            if not (unchanged directory destination) then
                                preserveTemporary <- true
                                return Error AtomicOutputError.DestinationChanged
                            else
                                boundary.BeforeReplace()
                                token.ThrowIfCancellationRequested()

                                directory.ReplaceFile(
                                    temporaryName,
                                    identity,
                                    destination.OutputName,
                                    destination.ExistingFingerprint |> Option.map _.Entry
                                )

                                committed <- true
                                boundary.AfterReplace()

                                return
                                    Ok
                                        { Path = destination.OutputPath
                                          Length = length }
                    with
                    | :? OperationCanceledException -> return Error AtomicOutputError.Cancelled
                    | :? IOException
                    | :? UnauthorizedAccessException -> return Error AtomicOutputError.WriteFailed
                finally
                    if not committed && not preserveTemporary && temporaryName <> "" then
                        try
                            use directory =
                                HeldDirectory.Open(
                                    destination.OutputParent,
                                    destination.OutputParentIdentity
                                )

                            temporaryIdentity
                            |> Option.iter (fun identity ->
                                directory.RemoveFile(temporaryName, identity))
                        with _ ->
                            ()
        }

    let write destination replace writeContent token =
        writeWithBoundary
            { BeforeReplace = ignore
              AfterReplace = ignore }
            destination
            replace
            writeContent
            token
