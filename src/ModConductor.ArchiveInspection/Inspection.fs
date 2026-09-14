namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open SharpCompress.Archives
open SharpCompress.Readers
open SharpCompress.Common
open ModConductor.ArtifactLibrary

type Inspection(source: IArtifactSource, ?limits: ArchiveLimits, ?nested: INestedArchiveSource) =
    let limits = defaultArg limits ArchiveLimits.Default

    let read sha (file: Stream) token consume =
        let mutable format = Nullable<ArchiveType>()

        match BethesdaArchive.tryOpen file sha limits token with
        | Some contents -> consume (ArchiveContents contents)
        | None ->
            file.Position <- 0L

            if not (ArchiveFactory.IsArchive(file, &format)) then
                raise (NotSupportedException "Unknown archive format")

            file.Position <- 0L
            use archive = ArchiveFactory.OpenArchive(file, ReaderOptions.ForExternalStream)

            consume (
                ArchiveContents(
                    SharpArchiveContents(archive, sha, file.Length, limits, token)
                    :> IArchiveContents
                )
            )

    member _.WithOwnedStream(sha, file: Stream, token, consume) = read sha file token consume

    member _.IdentifyBethesdaOwnedStream(file: Stream) =
        BethesdaArchive.tryIdentify file
        |> Option.defaultWith (fun () ->
            raise (NotSupportedException "Unknown Bethesda archive format"))

    member _.WithContents(reference, token: CancellationToken, consume: ArchiveContents -> 'a) =
        source.ReadVerified(
            reference,
            token,
            fun (artifact, file) -> read artifact.Sha256.Value file token consume
        )

    member this.WithInput(reference: ArtifactRef, input: NestedArchiveRef option, token, consume) =
        match input with
        | None -> this.WithContents(reference, token, consume)
        | Some input ->
            match nested with
            | Some owner ->
                owner.ReadVerified(
                    reference.WorkspaceId,
                    input,
                    token,
                    fun file -> read input.Sha256 file token consume
                )
            | None -> invalidOp "Nested archive source is not connected."

    member this.Inspect(reference, token) =
        this.WithContents(reference, token, fun contents -> contents.Manifest)

module ArchiveFailure =
    let message (error: exn) =
        match error with
        | :? ArchiveInspectionException -> Some error.Message
        | :? CryptographicException ->
            Some "This archive needs a password. Obtain an unencrypted copy."
        | :? MultipartStreamRequiredException
        | :? MultiVolumeExtractionException ->
            Some "Split archive volumes are not supported. Obtain a single archive."
        | :? NotSupportedException ->
            Some "This archive format or compression method is not supported."
        | :? InvalidDataException
        | :? EndOfStreamException
        | :? IncompleteArchiveException
        | :? InvalidFormatException -> Some "The archive is corrupt. Download a fresh copy."
        | :? ArchiveOperationException ->
            Some "The archive could not be read. Download a fresh copy."
        | :? SharpCompressException -> Some "The archive could not be read."
        | :? IOException
        | :? UnauthorizedAccessException ->
            Some "The archive file cannot be read. Check its location and access."
        | _ -> None
