namespace ModConductor.Bethesda

open System
open System.IO
open System.Text
open System.Threading
open ModConductor.GameContexts

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

    let private readTes4
        (rules: GameRules)
        (name: string)
        (stream: Stream)
        (token: CancellationToken)
        =
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

            let form, tail =
                if rules.HeaderBytes = 20 then
                    0us, 0us
                else
                    reader.ReadUInt16(), reader.ReadUInt16()

            if form = 0x4548us && tail = 0x5244us then
                unsupported "Oblivion-style headers are not supported for Skyrim Special Edition."

            if flags &&& 0x40000u <> 0u then
                unsupported "Compressed TES4 headers are not supported."

            if length > maxHeaderBytes then
                limit "The TES4 header exceeds the 8 MiB read limit."

            let endPosition = int64 rules.HeaderBytes + length

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

            if rules.NexusGame = "skyrimspecialedition" && version <> 1.7f && version <> 1.71f then
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
                  Kind =
                    if rules.SupportsMedium && flags &&& 0x400u <> 0u then
                        if flags &&& 1u <> 0u || extension = ".esm" then
                            PluginKind.MediumMaster
                        else
                            PluginKind.MediumPlugin
                    elif rules.SupportsMedium && rules.SupportsLight then
                        let adjusted =
                            (flags &&& ~~~0x200u)
                            ||| (if flags &&& 0x100u <> 0u then 0x200u else 0u)

                        SkyrimPlugins.kind extension adjusted
                    elif rules.SupportsLight then
                        SkyrimPlugins.kind extension flags
                    elif flags &&& 1u <> 0u || extension = ".esm" then
                        PluginKind.Master
                    else
                        PluginKind.Plugin
                  Localized = rules.SupportsLight && flags &&& 0x80u <> 0u
                  Author = author
                  Description = description
                  Masters = List.ofSeq masters }
        with
        | HeaderReadException error -> Error error
        | :? EndOfStreamException -> Error(HeaderError.Malformed "The plugin header is incomplete.")
        | :? IOException as error -> Error(HeaderError.Unavailable error.Message)
        | :? UnauthorizedAccessException ->
            Error(HeaderError.Unavailable "The plugin file cannot be read.")

    let readFor (rules: GameRules) name stream token =
        if rules.HeaderBytes = 16 then
            MorrowindHeaderReader.read name stream token
        else
            readTes4 rules name stream token

    let read name stream token =
        readFor (GameCatalog.rules Skyrim.definition.Id) name stream token
