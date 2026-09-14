namespace ModConductor.FilePlanning

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform

[<RequireQualifiedAccess>]
module FilePreviewLimits =
    let SourceBytes = 8L * 1024L * 1024L
    let TextBytes = 1L * 1024L * 1024L
    let TextLines = 20000
    let HexBytes = 256 * 1024
    let ImageDimension = 8192
    let ImagePixels = 16L * 1024L * 1024L
    let BufferBytes = 64 * 1024

module private ImageHeader =
    let private be16 (bytes: byte array) offset =
        int bytes[offset] <<< 8 ||| int bytes[offset + 1]

    let private be32 (bytes: byte array) offset =
        int bytes[offset] <<< 24 ||| int bytes[offset + 1] <<< 16
        ||| int bytes[offset + 2]
        <<< 8
        ||| int bytes[offset + 3]

    let private png (bytes: byte array) =
        let signature = [| 137uy; 80uy; 78uy; 71uy; 13uy; 10uy; 26uy; 10uy |]

        if
            bytes.Length >= 24
            && bytes[0..7] = signature
            && bytes[12..15] = [| 73uy; 72uy; 68uy; 82uy |]
        then
            Some("PNG", be32 bytes 16, be32 bytes 20)
        else
            None

    let private jpeg (bytes: byte array) =
        if bytes.Length < 4 || bytes[0] <> 0xFFuy || bytes[1] <> 0xD8uy then
            None
        else
            let mutable offset = 2
            let mutable result = None

            while offset + 3 < bytes.Length && result.IsNone do
                if bytes[offset] <> 0xFFuy then
                    offset <- bytes.Length
                else
                    while offset < bytes.Length && bytes[offset] = 0xFFuy do
                        offset <- offset + 1

                    if offset < bytes.Length then
                        let marker = int bytes[offset]
                        offset <- offset + 1

                        if marker = 0xD9 || marker = 0xDA then
                            offset <- bytes.Length
                        elif marker = 0x01 || (marker >= 0xD0 && marker <= 0xD7) then
                            ()
                        elif offset + 1 >= bytes.Length then
                            offset <- bytes.Length
                        else
                            let size = be16 bytes offset

                            if size < 2 || offset + size > bytes.Length then
                                offset <- bytes.Length
                            elif
                                (marker >= 0xC0 && marker <= 0xC3)
                                || (marker >= 0xC5 && marker <= 0xC7)
                                || (marker >= 0xC9 && marker <= 0xCB)
                                || (marker >= 0xCD && marker <= 0xCF)
                            then
                                if size >= 7 then
                                    result <-
                                        Some(
                                            "JPEG",
                                            be16 bytes (offset + 5),
                                            be16 bytes (offset + 3)
                                        )
                                else
                                    offset <- bytes.Length
                            else
                                offset <- offset + size

            result

    let tryRead bytes =
        match png bytes |> Option.orElseWith (fun () -> jpeg bytes) with
        | Some value -> Ok value
        | None -> Error "Only PNG and JPEG images can be previewed."

module FilePreviewRendering =
    let sourceLength =
        function
        | FilePreviewSource.ManagedCopy value -> value.Length
        | FilePreviewSource.CheckedGameFile value -> value.Length
        | FilePreviewSource.QualifiedArchiveEntry value -> value.Length

    let sourceSha256 =
        function
        | FilePreviewSource.ManagedCopy value -> Some value.Sha256
        | FilePreviewSource.CheckedGameFile value -> Some value.Sha256
        | FilePreviewSource.QualifiedArchiveEntry _ -> None

    let target =
        function
        | FilePreviewSource.ManagedCopy value -> value.Target
        | FilePreviewSource.CheckedGameFile value -> value.Target
        | FilePreviewSource.QualifiedArchiveEntry value -> value.Path

    let sourcePath =
        function
        | FilePreviewSource.ManagedCopy value -> value.SourcePath
        | FilePreviewSource.CheckedGameFile value -> value.SourcePath
        | FilePreviewSource.QualifiedArchiveEntry value -> value.Path

    let private changed source detail standing =
        { Source = source
          Standing = standing
          Target = target source
          Outcome = FilePreviewOutcome.Changed detail }

    let private tooLarge source detail standing =
        { Source = source
          Standing = standing
          Target = target source
          Outcome = FilePreviewOutcome.TooLarge detail }

    let private unsupported source detail standing =
        { Source = source
          Standing = standing
          Target = target source
          Outcome = FilePreviewOutcome.Unsupported detail }

    let private ready source content standing =
        { Source = source
          Standing = standing
          Target = target source
          Outcome = FilePreviewOutcome.Ready content }

    let private representationLimit =
        function
        | FilePreviewRepresentation.Text -> FilePreviewLimits.TextBytes
        | FilePreviewRepresentation.Image
        | FilePreviewRepresentation.Hex -> FilePreviewLimits.SourceBytes

    let exceedsLimit source representation =
        sourceLength source > representationLimit representation

    let private readAll
        (source: FilePreviewSource)
        standing
        representation
        (stream: Stream)
        (token: CancellationToken)
        =
        let expectedLength = sourceLength source

        if expectedLength < 0L || stream.CanRead |> not then
            changed source "The selected source is no longer readable." standing
        elif expectedLength > representationLimit representation then
            tooLarge
                source
                (if representation = FilePreviewRepresentation.Text then
                     "This text file is too large to preview."
                 else
                     "This file is too large to preview.")
                standing
        else
            use digest = IncrementalHash.CreateHash HashAlgorithmName.SHA256
            use output = new MemoryStream(int expectedLength)
            let buffer = Array.zeroCreate<byte> FilePreviewLimits.BufferBytes
            let mutable doneReading = false
            let mutable changedInput = false
            let mutable total = 0L

            while not doneReading && not changedInput do
                token.ThrowIfCancellationRequested()
                let count = stream.Read(buffer, 0, buffer.Length)

                if count = 0 then
                    doneReading <- true
                else
                    total <- total + int64 count

                    if total > expectedLength || total > FilePreviewLimits.SourceBytes then
                        changedInput <- true
                    else
                        digest.AppendData(buffer, 0, count)
                        output.Write(buffer, 0, count)

            let actualHash = Convert.ToHexStringLower(digest.GetHashAndReset())

            if
                changedInput
                || total <> expectedLength
                || (sourceSha256 source |> Option.exists ((<>) actualHash))
            then
                changed source "The selected source changed. Reload the file view." standing
            else
                let bytes = output.ToArray()

                match representation with
                | FilePreviewRepresentation.Hex ->
                    let count = min bytes.Length FilePreviewLimits.HexBytes

                    ready
                        source
                        (FilePreviewContent.Hex
                            { Content = bytes |> Array.truncate count
                              TotalLength = total
                              Truncated = count < bytes.Length })
                        standing
                | FilePreviewRepresentation.Text ->
                    match TextDocuments.decode bytes with
                    | Error detail when detail.Contains("too many lines") ->
                        tooLarge source "This text file has too many lines to preview." standing
                    | Error detail -> unsupported source detail standing
                    | Ok decoded ->
                        ready
                            source
                            (FilePreviewContent.Text
                                { Content = decoded.Content
                                  Encoding = decoded.EncodingName
                                  Lines = decoded.Lines })
                            standing
                | FilePreviewRepresentation.Image ->
                    let extension =
                        sourcePath source
                        |> LogicalPath.display
                        |> Path.GetExtension
                        |> _.ToLowerInvariant()

                    match ImageHeader.tryRead bytes with
                    | Error detail -> unsupported source detail standing
                    | Ok(format, _, _) when
                        (format = "PNG" && extension <> ".png")
                        || (format = "JPEG" && extension <> ".jpg" && extension <> ".jpeg")
                        ->
                        unsupported
                            source
                            "The file extension does not match its image data."
                            standing
                    | Ok(format, width, height) ->
                        if
                            width <= 0
                            || height <= 0
                            || width > FilePreviewLimits.ImageDimension
                            || height > FilePreviewLimits.ImageDimension
                            || int64 width * int64 height > FilePreviewLimits.ImagePixels
                        then
                            tooLarge source "This image is too large to preview safely." standing
                        else
                            ready
                                source
                                (FilePreviewContent.Image
                                    { Content = bytes
                                      Format = format
                                      Width = width
                                      Height = height })
                                standing

    let render
        (source: FilePreviewSource)
        standing
        representation
        (stream: Stream)
        (token: CancellationToken)
        =
        readAll source standing representation stream token
