namespace ModConductor.Bethesda

open System
open System.IO
open System.Text
open System.Threading

exception private HeaderReadException of HeaderError

module HeaderReader =
    let maxHeaderBytes = 8L * 1024L * 1024L
    let private maxStringBytes = 64L * 1024L

    let private fail detail =
        raise (HeaderReadException(HeaderError.Malformed detail))

    let private unsupported detail =
        raise (HeaderReadException(HeaderError.Unsupported detail))

    let private limit detail =
        raise (HeaderReadException(HeaderError.Limit detail))

    let private text (reader: BinaryReader) length =
        if length > maxStringBytes then
            limit "A header string exceeds the 64 KiB read limit."

        let bytes = reader.ReadBytes(int length)
        let count = Array.IndexOf(bytes, 0uy)

        if count < 0 then
            fail "A header string has no terminating zero."

        PluginText.decode bytes[.. count - 1]

    let read (name: string) (stream: Stream) (token: CancellationToken) =
        try
            use reader = new BinaryReader(stream, Encoding.UTF8, true)

            let tag () =
                Encoding.ASCII.GetString(reader.ReadBytes 4)

            if stream.Length < 4L then
                fail "The plugin header is incomplete."

            if tag () <> "TES4" then
                unsupported "This file has no supported TES4 header."

            let length = int64 (reader.ReadUInt32())
            let flags = reader.ReadUInt32()
            reader.ReadUInt32() |> ignore
            reader.ReadUInt32() |> ignore
            let form = reader.ReadUInt16()
            let tail = reader.ReadUInt16()

            if form = 0x4548us && tail = 0x5244us then
                unsupported "Oblivion-style headers are not supported for Skyrim Special Edition."

            if flags &&& 0x40000u <> 0u then
                unsupported "Compressed TES4 headers are not supported."

            if length > maxHeaderBytes then
                limit "The TES4 header exceeds the 8 MiB read limit."

            let endPosition = 24L + length

            if endPosition > stream.Length then
                fail "The TES4 header ends before its declared size."

            let mutable version = None
            let mutable records = 0u
            let mutable author = None
            let mutable description = None
            let masters = ResizeArray<string>()

            while stream.Position < endPosition do
                token.ThrowIfCancellationRequested()

                if endPosition - stream.Position < 6L then
                    fail "A header subrecord is incomplete."

                let mutable signature = tag ()
                let mutable size = int64 (reader.ReadUInt16())

                if signature = "XXXX" then
                    if size <> 4L || endPosition - stream.Position < 10L then
                        fail "An extended header subrecord is incomplete."

                    size <- int64 (reader.ReadUInt32())
                    signature <- tag ()
                    reader.ReadUInt16() |> ignore

                    if signature = "XXXX" then
                        fail "An extended header subrecord has no data type."

                let next = stream.Position + size

                if next > endPosition then
                    fail "A header subrecord extends past the TES4 header."

                match signature with
                | "HEDR" ->
                    if version.IsSome || size <> 12L then
                        fail "The HEDR subrecord is invalid."

                    version <- Some(reader.ReadSingle())
                    records <- reader.ReadUInt32()
                    reader.ReadUInt32() |> ignore
                | "MAST" ->
                    let master = text reader size

                    if
                        String.IsNullOrWhiteSpace master || master.IndexOfAny([| '/'; '\\' |]) >= 0
                    then
                        fail "A master name is not a file name."

                    masters.Add master
                | "CNAM" -> author <- Some(text reader size)
                | "SNAM" -> description <- Some(text reader size)
                | _ -> ()

                stream.Seek(next, SeekOrigin.Begin) |> ignore

            let version =
                version
                |> Option.defaultWith (fun () -> fail "The TES4 header has no HEDR subrecord.")

            if version <> 1.7f && version <> 1.71f then
                unsupported (
                    "Header version "
                    + version.ToString(Globalization.CultureInfo.InvariantCulture)
                    + " is not supported for Skyrim Special Edition."
                )

            let extension = Path.GetExtension(name).ToLowerInvariant()

            Ok
                { Extension = extension
                  Flags = flags
                  FormVersion = form
                  HeaderVersion = version
                  DeclaredRecords = records
                  Kind = SkyrimPlugins.kind extension flags
                  Localized = flags &&& 0x80u <> 0u
                  Author = author
                  Description = description
                  Masters = List.ofSeq masters }
        with
        | HeaderReadException error -> Error error
        | :? EndOfStreamException -> Error(HeaderError.Malformed "The plugin header is incomplete.")
        | :? IOException as error -> Error(HeaderError.Unavailable error.Message)
        | :? UnauthorizedAccessException ->
            Error(HeaderError.Unavailable "The plugin file cannot be read.")
