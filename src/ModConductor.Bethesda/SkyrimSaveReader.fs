namespace ModConductor.Bethesda

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Threading
open K4os.Compression.LZ4

module internal SkyrimSaveReader =
    [<Literal>]
    let maxFileBytes = 512L * 1024L * 1024L

    [<Literal>]
    let maxExpandedBytes = 2L * 1024L * 1024L * 1024L

    [<Literal>]
    let maxScreenshotBytes = 64L * 1024L * 1024L

    [<Literal>]
    let maxPluginInfoBytes = 1024 * 1024

    exception private SaveLimit of string
    exception private SaveUnsupported of string

    let private malformed detail = raise (InvalidDataException detail)
    let private limited detail = raise (SaveLimit detail)
    let private unsupported detail = raise (SaveUnsupported detail)

    let private readExactly (stream: Stream) count (token: CancellationToken) =
        let bytes = Array.zeroCreate<byte> count
        let mutable offset = 0

        while offset < count do
            token.ThrowIfCancellationRequested()
            let read = stream.Read(bytes, offset, count - offset)

            if read = 0 then
                malformed "The save is truncated."

            offset <- offset + read

        bytes

    let private readByte stream token = (readExactly stream 1 token)[0]

    let private readUInt16 stream token =
        let bytes = readExactly stream 2 token
        uint16 bytes[0] ||| (uint16 bytes[1] <<< 8)

    let private readUInt32 stream token =
        let bytes = readExactly stream 4 token

        uint32 bytes[0]
        ||| (uint32 bytes[1] <<< 8)
        ||| (uint32 bytes[2] <<< 16)
        ||| (uint32 bytes[3] <<< 24)

    let private readUInt64 stream token =
        let bytes = readExactly stream 8 token
        let mutable value = 0UL

        for index in 0..7 do
            value <- value ||| (uint64 bytes[index] <<< (8 * index))

        value

    let private strictUtf8 = UTF8Encoding(false, true)

    let private readString stream token =
        let length = int (readUInt16 stream token)
        let bytes = readExactly stream length token

        try
            strictUtf8.GetString bytes
        with :? DecoderFallbackException ->
            malformed "The save contains invalid UTF-8 text."

    let private prefixLength (first: byte array) =
        let size =
            uint32 first[1]
            ||| (uint32 first[2] <<< 8)
            ||| (uint32 first[3] <<< 16)
            ||| (uint32 first[4] <<< 24)

        if size = 0u || size > uint32 maxPluginInfoBytes then
            limited "The save plugin information exceeds 1 MiB."

        5 + int size

    let private readBodyPrefix compression (stream: Stream) token =
        match compression with
        | SkyrimSaveCompression.Uncompressed ->
            let first = readExactly stream 5 token
            Array.append first (readExactly stream (prefixLength first - 5) token)
        | SkyrimSaveCompression.Zlib ->
            let expanded = int64 (readUInt32 stream token)
            let encoded = int64 (readUInt32 stream token)

            if expanded <= 0L || expanded > maxExpandedBytes then
                limited "The save declares an unsupported expanded size."

            if
                encoded <= 0L
                || encoded > maxFileBytes
                || encoded <> stream.Length - stream.Position
            then
                malformed "The save compressed size does not match its data."

            use segment = new MemoryStream(readExactly stream (int encoded) token, false)
            use decoded = new ZLibStream(segment, CompressionMode.Decompress, false)
            let first = readExactly decoded 5 token
            let wanted = prefixLength first

            if int64 wanted > expanded then
                malformed "The save plugin information exceeds its expanded data."

            Array.append first (readExactly decoded (wanted - 5) token)
        | SkyrimSaveCompression.Lz4 ->
            let expanded = int64 (readUInt32 stream token)
            let encoded = int64 (readUInt32 stream token)

            if expanded <= 0L || expanded > maxExpandedBytes then
                limited "The save declares an unsupported expanded size."

            if
                encoded <= 0L
                || encoded > maxFileBytes
                || encoded <> stream.Length - stream.Position
            then
                malformed "The save compressed size does not match its data."

            let source = readExactly stream (int encoded) token
            let first = Array.zeroCreate<byte> 5
            let firstCount = LZ4Codec.PartialDecode(source.AsSpan(), first.AsSpan())

            if firstCount <> first.Length then
                malformed "The save LZ4 data is malformed."

            let wanted = prefixLength first

            if int64 wanted > expanded then
                malformed "The save plugin information exceeds its expanded data."

            let prefix = Array.zeroCreate<byte> wanted
            let decoded = LZ4Codec.PartialDecode(source.AsSpan(), prefix.AsSpan())

            if decoded <> prefix.Length then
                malformed "The save LZ4 data is malformed."

            prefix

    let private plugins (prefix: byte array) token =
        use stream = new MemoryStream(prefix, false)
        let formVersion = readByte stream token

        if formVersion < 77uy then
            unsupported "This Skyrim SE save body version is not supported."

        let declared = int (readUInt32 stream token)

        if declared <> prefix.Length - 5 then
            malformed "The save plugin information size does not match its data."

        let readPlugin () =
            let name = readString stream token

            if
                String.IsNullOrWhiteSpace name
                || name.IndexOfAny([| '\r'; '\n'; '\000'; '/'; '\\' |]) >= 0
            then
                malformed "The save contains an invalid plugin name."

            name

        let full = [ for _ in 1 .. int (readByte stream token) -> readPlugin () ]

        let light =
            if formVersion >= 78uy then
                let count = int (readUInt16 stream token)

                if count > 4095 then
                    limited "The save contains more than 4,095 light plugins."

                [ for _ in 1..count -> readPlugin () ]
            else
                []

        if stream.Position <> stream.Length then
            malformed "The save plugin information has trailing data."

        formVersion, full, light

    let read (stream: Stream) (token: CancellationToken) =
        try
            if not stream.CanRead || not stream.CanSeek then
                unsupported "The save source does not support bounded reading."

            if stream.Length <= 0L || stream.Length > maxFileBytes then
                limited "The save exceeds the 512 MiB metadata read limit."

            stream.Position <- 0L

            if Encoding.ASCII.GetString(readExactly stream 13 token) <> "TESV_SAVEGAME" then
                malformed "The file is not a Skyrim save."

            let headerSize = int64 (readUInt32 stream token)

            if headerSize <= 0L || headerSize > 255L then
                limited "The save header exceeds 255 bytes."

            let headerStart = stream.Position
            let headerVersion = readUInt32 stream token

            if headerVersion <> 12u then
                unsupported "This Skyrim save header version is not supported."

            let saveNumber = readUInt32 stream token
            let character = readString stream token
            let level = readUInt32 stream token
            let location = readString stream token
            let gameTime = readString stream token
            readString stream token |> ignore
            readUInt16 stream token |> ignore
            readUInt32 stream token |> ignore
            readUInt32 stream token |> ignore
            readUInt64 stream token |> ignore
            let width = int64 (readUInt32 stream token)
            let height = int64 (readUInt32 stream token)

            let compression =
                match readUInt16 stream token with
                | 0us -> SkyrimSaveCompression.Uncompressed
                | 1us -> SkyrimSaveCompression.Zlib
                | 2us -> SkyrimSaveCompression.Lz4
                | _ -> unsupported "This Skyrim save compression is not supported."

            if stream.Position - headerStart <> headerSize then
                malformed "The save header size does not match its fields."

            if
                width > maxScreenshotBytes / 4L
                || (width > 0L && height > maxScreenshotBytes / (width * 4L))
            then
                limited "The save screenshot exceeds 64 MiB."

            let screenshot = width * height * 4L

            if screenshot > stream.Length - stream.Position then
                malformed "The save screenshot is truncated."

            stream.Position <- stream.Position + screenshot
            let prefix = readBodyPrefix compression stream token
            let formVersion, full, light = plugins prefix token

            Ok
                { HeaderVersion = headerVersion
                  FormVersion = formVersion
                  Compression = compression
                  SaveNumber = saveNumber
                  Character = character
                  Level = level
                  Location = location
                  GameTime = gameTime
                  FullPlugins = full
                  LightPlugins = light }
        with
        | :? OperationCanceledException -> reraise ()
        | SaveLimit detail -> Error(SkyrimSaveError.Limit detail)
        | SaveUnsupported detail -> Error(SkyrimSaveError.Unsupported detail)
        | :? EndOfStreamException
        | :? InvalidDataException
        | :? ArgumentException ->
            Error(SkyrimSaveError.Malformed "The Skyrim save metadata is malformed.")
