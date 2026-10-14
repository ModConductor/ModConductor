namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Threading
open ModConductor.Platform

module internal BethesdaArchiveCommon =
    type Codec =
        | Raw
        | Zlib
        | Lz4Frame

    type DataPart =
        { Offset: int64
          Stored: int64
          Expanded: int64
          Codec: Codec }

    type StoredEntry =
        { Path: LogicalPath
          Expanded: int64
          Compressed: int64 option
          Prefix: byte[] option
          Parts: DataPart list }

    let private utf8 = UTF8Encoding(false, true)

    let malformed () =
        raise (InvalidDataException "The Bethesda archive is malformed.")

    let unsupported () =
        raise (NotSupportedException "This Bethesda archive variant is not supported.")

    let seek (source: Stream) offset =
        if offset < 0L || offset > source.Length then
            malformed ()

        source.Position <- offset

    let readBytes (source: Stream) count =
        if count < 0 then
            malformed ()

        let bytes = Array.zeroCreate<byte> count
        let mutable offset = 0

        while offset < count do
            let received = source.Read(bytes, offset, count - offset)

            if received = 0 then
                raise (EndOfStreamException "The Bethesda archive is truncated.")

            offset <- offset + received

        bytes

    let readByte (source: Stream) =
        let value = source.ReadByte()

        if value < 0 then
            raise (EndOfStreamException "The Bethesda archive is truncated.")

        value

    let u16 source =
        let b = readBytes source 2
        uint16 b[0] ||| (uint16 b[1] <<< 8)

    let u32 source =
        let b = readBytes source 4

        uint32 b[0]
        ||| (uint32 b[1] <<< 8)
        ||| (uint32 b[2] <<< 16)
        ||| (uint32 b[3] <<< 24)

    let u64 source =
        let b = readBytes source 8
        let mutable value = 0UL

        for i in 0..7 do
            value <- value ||| (uint64 b[i] <<< (8 * i))

        value

    let range (source: Stream) offset length =
        if offset < 0L || length < 0L || offset > source.Length - length then
            malformed ()

    let decodeName (bytes: byte[]) =
        try
            utf8.GetString bytes
        with :? DecoderFallbackException ->
            malformed ()

    let terminatedName source =
        use bytes = new MemoryStream()
        let mutable done' = false

        while not done' do
            let value = readByte source

            if value = 0 then
                done' <- true
            else
                bytes.WriteByte(byte value)

        decodeName (bytes.ToArray())

    let manifest digest format (stored: StoredEntry list) =
        { Sha256 = digest
          Format = format
          Entries =
            stored
            |> List.mapi (fun index entry ->
                { Index = index
                  Path = entry.Path
                  Directory = false
                  Size = entry.Expanded
                  CompressedSize = entry.Compressed })
          TotalSize = stored |> List.sumBy _.Expanded }

    let private partStream (source: Stream) token part =
        seek source part.Offset
        let segment = new SegmentStream(source, part.Stored)

        let decoded: Stream =
            match part.Codec with
            | Raw -> segment
            | Zlib -> new ZLibStream(segment, CompressionMode.Decompress, false)
            | Lz4Frame -> new Lz4FrameStream(segment, part.Expanded, token)

        new ExactStream(decoded, part.Expanded) :> Stream

    type Contents
        (
            source: Stream,
            stored: StoredEntry list,
            manifest: ArchiveManifest,
            token: CancellationToken
        ) =
        interface IArchiveContents with
            member _.Manifest = manifest

            member _.ReadEntries(indices, consume) =
                let selected = Collections.Generic.HashSet<int>(indices)

                if
                    selected.Count <> indices.Length
                    || indices |> List.exists (fun i -> i < 0 || i >= stored.Length)
                then
                    invalidArg (nameof indices) "Choose file entries from this manifest."

                for index in indices |> List.sort do
                    token.ThrowIfCancellationRequested()
                    let entry = stored[index]

                    let prefixes =
                        match entry.Prefix with
                        | Some prefix -> [ fun () -> new MemoryStream(prefix, false) :> Stream ]
                        | None -> []

                    let factories =
                        prefixes
                        @ (entry.Parts
                           |> List.map (fun part -> fun () -> partStream source token part))

                    use stream = new SequenceStream(factories, entry.Expanded)
                    use bounded = new EntryRead(stream, entry.Expanded, token)
                    consume (index, bounded)
                    bounded.CopyTo Stream.Null

    let fourcc (bytes: byte[]) = Encoding.ASCII.GetString(bytes)
