namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Security.Cryptography
open System.Text
open System.Text.Json
open System.Threading
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.DeploymentPlanning
open ModConductor.FilePlanning
open ModConductor.Platform

module FilePreviewFixtures =
    let private path name =
        LogicalPath.create [ name ]
        |> Result.defaultWith (fun _ -> invalidOp "fixture path")

    let private hash (bytes: byte array) =
        SHA256.HashData bytes |> Convert.ToHexStringLower

    let private source name (bytes: byte array) =
        FilePreviewSource.CheckedGameFile
            { SnapshotId = Guid.NewGuid()
              Generation = "fixture"
              Kind = ReadOnlyLayerKind.Base
              SourcePath = path name
              Target = path name
              Length = int64 bytes.Length
              Sha256 = hash bytes }

    let private render name representation (bytes: byte array) token =
        use stream = new MemoryStream(bytes, false)

        FilePreviewRendering.render
            (source name bytes)
            FileSourceStanding.Winner
            representation
            stream
            token

    let private readyText expected =
        function
        | { Outcome = FilePreviewOutcome.Ready(FilePreviewContent.Text value) } ->
            value.Content = expected
        | _ -> false

    let observe (writer: Utf8JsonWriter) =
        let markup =
            "<script>alert('inert')</script>\n<a href='https://example.invalid'>link</a>"

        let markupBytes = Encoding.UTF8.GetBytes markup

        writer.WriteBoolean(
            "markupRemainsInertText",
            render "page.html" FilePreviewRepresentation.Text markupBytes CancellationToken.None
            |> readyText markup
        )

        let utf16 =
            Array.append [| 0xFFuy; 0xFEuy |] (Encoding.Unicode.GetBytes "wide text")

        writer.WriteBoolean(
            "utf16BomIsStrictlyDecoded",
            render "wide.txt" FilePreviewRepresentation.Text utf16 CancellationToken.None
            |> readyText "wide text"
        )

        writer.WriteBoolean(
            "invalidUtf8IsUnsupported",
            match
                render
                    "bad.txt"
                    FilePreviewRepresentation.Text
                    [| 0xC3uy; 0x28uy |]
                    CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.Unsupported _ } -> true
            | _ -> false
        )

        let oversizedText = Array.create (int FilePreviewLimits.TextBytes + 1) (byte 'x')

        writer.WriteBoolean(
            "textLimitRefuses",
            match
                render
                    "large.txt"
                    FilePreviewRepresentation.Text
                    oversizedText
                    CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.TooLarge _ } -> true
            | _ -> false
        )

        let png =
            Convert.FromBase64String
                "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="

        writer.WriteBoolean(
            "pngMagicAndDimensions",
            match render "pixel.png" FilePreviewRepresentation.Image png CancellationToken.None with
            | { Outcome = FilePreviewOutcome.Ready(FilePreviewContent.Image image) } ->
                image.Format = "PNG" && image.Width = 1 && image.Height = 1
            | _ -> false
        )

        writer.WriteBoolean(
            "imageExtensionMismatchRefuses",
            match render "pixel.jpg" FilePreviewRepresentation.Image png CancellationToken.None with
            | { Outcome = FilePreviewOutcome.Unsupported _ } -> true
            | _ -> false
        )

        writer.WriteBoolean(
            "malformedImageIsUnsupported",
            match
                render
                    "broken.png"
                    FilePreviewRepresentation.Image
                    (Encoding.ASCII.GetBytes "not an image")
                    CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.Unsupported _ } -> true
            | _ -> false
        )

        let hugePng = Array.copy png
        hugePng[16] <- 0uy
        hugePng[17] <- 0uy
        hugePng[18] <- 0x20uy
        hugePng[19] <- 0x01uy

        writer.WriteBoolean(
            "imageDimensionLimitRefuses",
            match
                render "huge.png" FilePreviewRepresentation.Image hugePng CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.TooLarge _ } -> true
            | _ -> false
        )

        let hexBytes = Array.init (FilePreviewLimits.HexBytes + 17) byte

        writer.WriteBoolean(
            "hexIsBoundedPrefix",
            match
                render "opaque.bin" FilePreviewRepresentation.Hex hexBytes CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.Ready(FilePreviewContent.Hex value) } ->
                value.Truncated
                && value.Content.Length = FilePreviewLimits.HexBytes
                && value.TotalLength = int64 hexBytes.Length
            | _ -> false
        )

        let changed = source "changed.txt" markupBytes
        use changedStream = new MemoryStream(Encoding.UTF8.GetBytes "different", false)

        writer.WriteBoolean(
            "changedBytesRefuse",
            match
                FilePreviewRendering.render
                    changed
                    FileSourceStanding.Alternative
                    FilePreviewRepresentation.Text
                    changedStream
                    CancellationToken.None
            with
            | { Outcome = FilePreviewOutcome.Changed _ } -> true
            | _ -> false
        )

        use archive = new MemoryStream()

        do
            use zip = new ZipArchive(archive, ZipArchiveMode.Create, true)
            let item = zip.CreateEntry("docs/readme.txt")
            use output = item.Open()
            output.Write markupBytes

        let archiveBytes = archive.ToArray()
        let archiveHash = hash archiveBytes
        archive.Position <- 0L
        let inspection = Inspection(Unchecked.defaultof<IArtifactSource>)

        let archivePreview =
            inspection.WithOwnedStream(
                archiveHash,
                archive,
                CancellationToken.None,
                fun contents ->
                    let entry =
                        contents.Manifest.Entries |> List.find (fun value -> not value.Directory)

                    let archiveSource =
                        FilePreviewSource.QualifiedArchiveEntry
                            { WorkspaceId = Guid.NewGuid()
                              ArtifactId = Guid.NewGuid()
                              ArtifactRevision = 1L
                              ArchiveSha256 = archiveHash
                              Format = contents.Manifest.Format
                              Index = entry.Index
                              Path = entry.Path
                              Length = entry.Size }

                    let mutable preview = Unchecked.defaultof<FilePreview>

                    contents.ReadEntry(
                        entry.Index,
                        fun stream ->
                            preview <-
                                FilePreviewRendering.render
                                    archiveSource
                                    FileSourceStanding.Selected
                                    FilePreviewRepresentation.Text
                                    stream
                                    CancellationToken.None
                    )

                    preview
            )

        writer.WriteBoolean("qualifiedArchiveEntryPreview", readyText markup archivePreview)

        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()

        writer.WriteBoolean(
            "cancellationStopsRead",
            try
                render "cancel.txt" FilePreviewRepresentation.Text markupBytes cancelled.Token
                |> ignore

                false
            with :? OperationCanceledException ->
                true
        )
