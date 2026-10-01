namespace ModConductor.Bethesda

open System
open System.IO
open System.Text
open System.Threading

module internal NewVegasSaveReader =
    let private marker (reader: BinaryReader) = reader.ReadByte() |> ignore

    let private number (reader: BinaryReader) =
        let value = reader.ReadUInt32()
        marker reader
        value

    let private text (reader: BinaryReader) =
        let length = int (reader.ReadByte())
        marker reader
        marker reader
        let bytes = Array.zeroCreate<byte> length
        reader.BaseStream.ReadExactly(bytes.AsSpan())
        marker reader
        UTF8Encoding(false, true).GetString bytes

    let private body (reader: BinaryReader) (token: CancellationToken) =
        reader.ReadUInt32() |> ignore
        let version = reader.ReadUInt32()
        marker reader

        while reader.ReadByte() <> 0x7Cuy do
            token.ThrowIfCancellationRequested()

        let width, height = number reader, number reader
        let save = number reader
        let character = text reader
        text reader |> ignore
        let level = number reader
        let location, time = text reader, text reader
        let screenshot = uint64 width * uint64 height * 3UL

        if screenshot > uint64 SkyrimSaveReader.maxScreenshotBytes then
            Error(SkyrimSaveError.Limit "The save screenshot exceeds the read limit.")
        elif screenshot > uint64 (reader.BaseStream.Length - reader.BaseStream.Position) then
            Error(SkyrimSaveError.Malformed "The save screenshot is incomplete.")
        else
            reader.BaseStream.Seek(int64 screenshot + 5L, SeekOrigin.Current) |> ignore
            let count = int (reader.ReadByte())
            marker reader

            let plugins =
                [ for _ in 1..count do
                      token.ThrowIfCancellationRequested()
                      yield text reader ]

            Ok
                { HeaderVersion = version
                  FormVersion = 0uy
                  Compression = SkyrimSaveCompression.Uncompressed
                  SaveNumber = save
                  Character = character
                  Level = level
                  Location = location
                  GameTime = time
                  FullPlugins = plugins
                  LightPlugins = [] }

    let read (stream: Stream) token =
        try
            use reader = new BinaryReader(stream, Encoding.UTF8, true)

            if stream.Length > SkyrimSaveReader.maxFileBytes then
                Error(SkyrimSaveError.Limit "The save exceeds the read limit.")
            elif Encoding.ASCII.GetString(reader.ReadBytes 11) <> "FO3SAVEGAME" then
                Error(SkyrimSaveError.Unsupported "This file is not a New Vegas save.")
            else
                body reader token
        with
        | :? EndOfStreamException -> Error(SkyrimSaveError.Malformed "The save is incomplete.")
        | :? DecoderFallbackException ->
            Error(SkyrimSaveError.Malformed "The save contains invalid text.")
