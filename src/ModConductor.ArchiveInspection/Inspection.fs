namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open SharpCompress.Archives
open SharpCompress.Readers
open SharpCompress.Common
open ModConductor.ArtifactLibrary

type Inspection(source: IArtifactSource, ?limits: ArchiveLimits) =
    let limits = defaultArg limits ArchiveLimits.Default

    member _.WithContents(reference, token: CancellationToken, consume: ArchiveContents -> 'a) =
        source.ReadVerified(
            reference,
            token,
            fun (artifact, file) ->
                let mutable format = Nullable<ArchiveType>()

                if not (ArchiveFactory.IsArchive(file, &format)) then
                    raise (NotSupportedException "Unknown archive format")

                file.Position <- 0L
                use archive = ArchiveFactory.OpenArchive(file, ReaderOptions.ForExternalStream)

                let contents =
                    ArchiveContents(archive, artifact.Sha256.Value, file.Length, limits, token)

                consume contents
        )

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
