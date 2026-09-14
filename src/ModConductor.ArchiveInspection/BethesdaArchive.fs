namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.IO.Compression
open System.Text
open System.Threading
open ModConductor.Platform

module internal BethesdaArchive =
    type private Codec =
        | Raw
        | Zlib
        | Lz4Frame

    type private DataPart =
        { Offset: int64
          Stored: int64
          Expanded: int64
          Codec: Codec }

    type private StoredEntry =
        { Path: LogicalPath
          Expanded: int64
          Compressed: int64 option
          Prefix: byte[] option
          Parts: DataPart list }

    let private utf8 = UTF8Encoding(false, true)
    let private refuse message = ArchiveNames.refuse message

    let private malformed () =
        raise (InvalidDataException "The Bethesda archive is malformed.")

    let private unsupported () =
        raise (NotSupportedException "This Bethesda archive variant is not supported.")

    let private seek (source: Stream) offset =
        if offset < 0L || offset > source.Length then
            malformed ()

        source.Position <- offset

    let private readBytes (source: Stream) count =
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

    let private readByte (source: Stream) =
        let value = source.ReadByte()

        if value < 0 then
            raise (EndOfStreamException "The Bethesda archive is truncated.")

        value

    let private u16 source =
        let b = readBytes source 2
        uint16 b[0] ||| (uint16 b[1] <<< 8)

    let private u32 source =
        let b = readBytes source 4

        uint32 b[0]
        ||| (uint32 b[1] <<< 8)
        ||| (uint32 b[2] <<< 16)
        ||| (uint32 b[3] <<< 24)

    let private u64 source =
        let b = readBytes source 8
        let mutable value = 0UL

        for i in 0..7 do
            value <- value ||| (uint64 b[i] <<< (8 * i))

        value

    let private range (source: Stream) offset length =
        if offset < 0L || length < 0L || offset > source.Length - length then
            malformed ()

    let private decodeName (bytes: byte[]) =
        try
            utf8.GetString bytes
        with :? DecoderFallbackException ->
            malformed ()

    let private terminatedName (limits: ArchiveLimits) source =
        use bytes = new MemoryStream()
        let mutable done' = false

        while not done' do
            let value = readByte source

            if value = 0 then
                done' <- true
            else
                if bytes.Length >= int64 limits.PathCharacters then
                    refuse "An archive path is empty or too long."

                bytes.WriteByte(byte value)

        decodeName (bytes.ToArray())

    let private validateEntries
        digest
        format
        compressedLength
        (limits: ArchiveLimits)
        (stored: StoredEntry list)
        =
        if stored.Length > limits.Entries then
            refuse "The archive contains too many entries."

        let mutable total = 0L
        let mutable names = 0

        let entries =
            stored
            |> List.mapi (fun index entry ->
                let components = LogicalPath.components entry.Path
                names <- names + (components |> List.sumBy (fun value -> value.Length))

                if names > limits.NameCharacters then
                    refuse "The archive contains too much filename data."

                if entry.Expanded < 0L || entry.Expanded > limits.FileBytes then
                    refuse "An archive entry exceeds the file size limit."

                if entry.Expanded > limits.TotalBytes - total then
                    refuse "The archive exceeds the expanded size limit."

                total <- total + entry.Expanded

                match entry.Compressed with
                | Some packed when
                    packed > 0L && decimal entry.Expanded > decimal limits.Ratio * decimal packed
                    ->
                    refuse "The archive exceeds the expansion ratio limit."
                | _ -> ()

                { Index = index
                  Path = entry.Path
                  Directory = false
                  Size = entry.Expanded
                  CompressedSize = entry.Compressed })

        if decimal total > decimal limits.Ratio * decimal (max 1L compressedLength) then
            refuse "The archive exceeds the expansion ratio limit."

        ArchiveNames.validate limits entries

        { Sha256 = digest
          Format = format
          Entries = entries
          TotalSize = total }

    let private partStream (source: Stream) token part =
        seek source part.Offset
        let segment = new SegmentStream(source, part.Stored)

        let decoded: Stream =
            match part.Codec with
            | Raw -> segment
            | Zlib -> new ZLibStream(segment, CompressionMode.Decompress, false)
            | Lz4Frame -> new Lz4FrameStream(segment, part.Expanded, token)

        new ExactStream(decoded, part.Expanded) :> Stream

    type private Contents
        (
            source: Stream,
            stored: StoredEntry list,
            manifest: ArchiveManifest,
            compressedLength: int64,
            limits: ArchiveLimits,
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

                let mutable decoded = 0L

                let count amount =
                    decoded <- decoded + amount

                    if
                        decoded > limits.TotalBytes
                        || decimal decoded > decimal limits.Ratio
                                             * decimal (max 1L compressedLength)
                    then
                        refuse "The archive entry read exceeds the expanded data limit."

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
                    use bounded = new EntryRead(stream, entry.Expanded, count, token)
                    consume (index, bounded)
                    bounded.CopyTo Stream.Null

    let private fourcc (bytes: byte[]) = Encoding.ASCII.GetString(bytes)

    let private bsa (source: Stream) digest (limits: ArchiveLimits) token =
        let version = u32 source

        if version <> 105u then
            unsupported ()

        let folderOffset = int64 (u32 source)
        let flags = u32 source
        let folderCount = int (u32 source)
        let fileCount = int (u32 source)
        let declaredFolderNames = int64 (u32 source)
        let declaredFileNames = int64 (u32 source)
        u32 source |> ignore

        if folderOffset <> 36L then
            malformed ()

        if flags &&& 0x03u <> 0x03u || flags &&& 0x260u <> 0u then
            unsupported ()

        if
            folderCount < 0
            || fileCount < 0
            || fileCount > limits.Entries
            || folderCount > limits.Entries
        then
            refuse "The archive contains too many entries."

        range source folderOffset (int64 folderCount * 24L)
        seek source folderOffset

        let folders =
            [ for _ in 1..folderCount do
                  u64 source |> ignore
                  let count = int (u32 source)
                  u32 source |> ignore
                  let dataOffset = u64 source

                  if dataOffset > uint64 source.Length then
                      malformed ()

                  yield count ]

        if folders |> List.sum <> fileCount then
            malformed ()

        let records = ResizeArray<string * uint32 * int64>()
        let mutable actualFolderNames = 0L

        for count in folders do
            let length = readByte source

            if length = 0 then
                malformed ()

            let raw = readBytes source length

            if raw[length - 1] <> 0uy then
                malformed ()

            actualFolderNames <- actualFolderNames + int64 length
            let folder = decodeName raw[.. length - 2]

            for _ in 1..count do
                u64 source |> ignore
                let size = u32 source
                let offset = u32 source

                if offset &&& 0x80000000u <> 0u then
                    unsupported ()

                records.Add(folder, size, int64 offset)

        if actualFolderNames <> declaredFolderNames then
            malformed ()

        let namesStart = source.Position
        let names = [ for _ in 1..fileCount -> terminatedName limits source ]

        if source.Position - namesStart <> declaredFileNames then
            malformed ()

        let metadataEnd = source.Position
        let embedded = flags &&& 0x100u <> 0u
        let archiveCompressed = flags &&& 0x04u <> 0u

        let stored =
            [ for index in 0 .. fileCount - 1 do
                  let folder, encodedSize, dataOffset = records[index]
                  let storedSize = int64 (encodedSize &&& 0x3FFFFFFFu)
                  range source dataOffset storedSize

                  if dataOffset < metadataEnd then
                      malformed ()

                  let logicalName =
                      if String.IsNullOrEmpty folder then
                          names[index]
                      else
                          folder + "\\" + names[index]

                  let path = ArchiveNames.parse limits false logicalName
                  let saved = source.Position
                  seek source dataOffset
                  let mutable prefix = 0L

                  if embedded then
                      let length = readByte source
                      let name = readBytes source length |> decodeName

                      if name.Replace('/', '\\') <> logicalName.Replace('/', '\\') then
                          malformed ()

                      prefix <- int64 (length + 1)

                  let compressed = archiveCompressed <> (encodedSize &&& 0x40000000u <> 0u)

                  let expanded, codecPrefix =
                      if compressed then
                          int64 (u32 source), 4L
                      else
                          storedSize - prefix, 0L

                  let payload = storedSize - prefix - codecPrefix

                  if payload < 0L then
                      malformed ()

                  let part =
                      { Offset = dataOffset + prefix + codecPrefix
                        Stored = payload
                        Expanded = expanded
                        Codec = if compressed then Lz4Frame else Raw }

                  source.Position <- saved

                  yield
                      { Path = path
                        Expanded = expanded
                        Compressed = if compressed then Some payload else None
                        Prefix = None
                        Parts = [ part ] } ]

        let manifest = validateEntries digest "BSA v105" source.Length limits stored
        Contents(source, stored, manifest, source.Length, limits, token) :> IArchiveContents

    let private writeU32 (bytes: byte[]) offset (value: uint32) =
        bytes[offset] <- byte value
        bytes[offset + 1] <- byte (value >>> 8)
        bytes[offset + 2] <- byte (value >>> 16)
        bytes[offset + 3] <- byte (value >>> 24)

    let private ddsHeader width height mips format cube =
        let mutable dimension = max width height
        let mutable maximumMips = 1

        while dimension > 1 do
            dimension <- dimension / 2
            maximumMips <- maximumMips + 1

        if mips > maximumMips then
            unsupported ()

        let legacy =
            if cube then
                None
            else
                match format with
                | 71 -> Some(0x31545844u, true)
                | 74 -> Some(0x33545844u, false)
                | 77 -> Some(0x35545844u, false)
                | 80 -> Some(0x55344342u, true)
                | 81 -> Some(0x53344342u, true)
                | 83 -> Some(0x55354342u, false)
                | 84 -> Some(0x53354342u, false)
                | _ -> None

        let qualified = (format >= 70 && format <= 84) || (format >= 94 && format <= 99)

        if not qualified then
            unsupported ()

        let hasDx10 = legacy.IsNone
        let bytes = Array.zeroCreate<byte> (if hasDx10 then 148 else 128)
        writeU32 bytes 0 0x20534444u
        writeU32 bytes 4 124u
        writeU32 bytes 8 0xA1007u
        writeU32 bytes 12 (uint32 height)
        writeU32 bytes 16 (uint32 width)
        let halfBlock = (format >= 70 && format <= 72) || (format >= 79 && format <= 81)
        let blocksWide = int64 (max 1 ((width + 3) / 4))
        let blocksHigh = int64 (max 1 ((height + 3) / 4))
        let linearSize = blocksWide * blocksHigh * (if halfBlock then 8L else 16L)

        if linearSize > int64 UInt32.MaxValue then
            unsupported ()

        writeU32 bytes 20 (uint32 linearSize)
        writeU32 bytes 24 1u
        writeU32 bytes 28 (uint32 mips)
        writeU32 bytes 76 32u
        writeU32 bytes 80 4u
        writeU32 bytes 84 (legacy |> Option.map fst |> Option.defaultValue 0x30315844u)
        let mutable caps = 0x1000u

        if mips > 1 then
            caps <- caps ||| 0x400008u

        if cube then
            caps <- caps ||| 0x08u

        writeU32 bytes 108 caps

        if cube then
            writeU32 bytes 112 0xFE00u

        if hasDx10 then
            writeU32 bytes 128 (uint32 format)
            writeU32 bytes 132 3u
            writeU32 bytes 136 (if cube then 4u else 0u)
            writeU32 bytes 140 1u

        bytes

    let private overlaps start length otherStart otherEnd =
        length > 0L && start < otherEnd && otherStart < start + length

    let private ba2 (source: Stream) digest (limits: ArchiveLimits) token =
        let version = u32 source

        if version <> 1u then
            unsupported ()

        let kind = readBytes source 4 |> fourcc

        if kind <> "GNRL" && kind <> "DX10" then
            unsupported ()

        let count = int (u32 source)
        let namesOffsetRaw = u64 source

        if namesOffsetRaw = 0UL || namesOffsetRaw > uint64 Int64.MaxValue then
            unsupported ()

        let namesOffset = int64 namesOffsetRaw

        if count < 0 || count > limits.Entries then
            refuse "The archive contains too many entries."

        let recordsEnd =
            if kind = "GNRL" then
                24L + int64 count * 36L
            else
                let start = source.Position
                let mutable length = 24L
                let mutable totalChunks = 0

                for _ in 1..count do
                    readBytes source 13 |> ignore
                    let chunks = readByte source
                    totalChunks <- totalChunks + chunks

                    if totalChunks > limits.Entries then
                        refuse "The archive contains too much entry metadata."

                    length <- length + 24L + int64 chunks * 24L
                    seek source (source.Position + 10L + int64 chunks * 24L)

                seek source start
                length

        range source 0L recordsEnd

        if namesOffset < recordsEnd then
            malformed ()

        let general = ResizeArray<DataPart * int64 option>()
        let textures = ResizeArray<int * int * int * int * bool * DataPart list>()
        seek source 24L

        if kind = "GNRL" then
            for _ in 1..count do
                readBytes source 16 |> ignore
                let offsetRaw = u64 source

                if offsetRaw > uint64 Int64.MaxValue then
                    malformed ()

                let packed = int64 (u32 source)
                let expanded = int64 (u32 source)

                if u32 source <> 0xBAADF00Du then
                    malformed ()

                let storedLength = if packed = 0L then expanded else packed
                let offset = int64 offsetRaw
                range source offset storedLength

                general.Add(
                    { Offset = offset
                      Stored = storedLength
                      Expanded = expanded
                      Codec = if packed = 0L then Raw else Zlib },
                    if packed = 0L then None else Some packed
                )
        else
            for _ in 1..count do
                readBytes source 13 |> ignore
                let chunks = readByte source
                let chunkHeader = u16 source
                let height = int (u16 source)
                let width = int (u16 source)
                let mips = readByte source
                let format = readByte source
                let cubeCode = u16 source

                if chunks = 0 || chunkHeader <> 24us || width = 0 || height = 0 || mips = 0 then
                    malformed ()

                let cube =
                    if cubeCode = 2048us then false
                    elif cubeCode = 2049us then true
                    else unsupported ()

                let mutable expectedMip = 0

                let parts =
                    [ for _ in 1..chunks do
                          let offsetRaw = u64 source

                          if offsetRaw > uint64 Int64.MaxValue then
                              malformed ()

                          let packed = int64 (u32 source)
                          let expanded = int64 (u32 source)
                          let firstMip = int (u16 source)
                          let lastMip = int (u16 source)

                          if u32 source <> 0xBAADF00Du then
                              malformed ()

                          if firstMip <> expectedMip || lastMip < firstMip || lastMip >= mips then
                              malformed ()

                          expectedMip <- lastMip + 1
                          let storedLength = if packed = 0L then expanded else packed
                          let offset = int64 offsetRaw
                          range source offset storedLength

                          yield
                              { Offset = offset
                                Stored = storedLength
                                Expanded = expanded
                                Codec = if packed = 0L then Raw else Zlib } ]

                if expectedMip <> mips then
                    malformed ()

                textures.Add(width, height, mips, format, cube, parts)

        range source namesOffset 0L
        seek source namesOffset

        let names =
            [ for _ in 1..count do
                  let length = int (u16 source)

                  if length = 0 then
                      malformed ()

                  if length > limits.PathCharacters then
                      refuse "An archive path is empty or too long."

                  yield readBytes source length |> decodeName ]

        let namesEnd = source.Position

        let dataRanges =
            if kind = "GNRL" then
                general |> Seq.map (fun (p, _) -> p)
            else
                textures |> Seq.collect (fun (_, _, _, _, _, p) -> p)

        for part in dataRanges do
            if
                overlaps part.Offset part.Stored 0L recordsEnd
                || overlaps part.Offset part.Stored namesOffset namesEnd
            then
                malformed ()

        let stored =
            [ for index in 0 .. count - 1 do
                  let path = ArchiveNames.parse limits false names[index]

                  if kind = "GNRL" then
                      let part, packed = general[index]

                      yield
                          { Path = path
                            Expanded = part.Expanded
                            Compressed = packed
                            Prefix = None
                            Parts = [ part ] }
                  else
                      let width, height, mips, format, cube, parts = textures[index]
                      let header = ddsHeader width height mips format cube
                      let chunkBytes = parts |> List.sumBy _.Expanded

                      let compressed =
                          if parts |> List.exists (fun p -> p.Codec = Zlib) then
                              Some(parts |> List.sumBy _.Stored)
                          else
                              None

                      yield
                          { Path = path
                            Expanded = int64 header.Length + chunkBytes
                            Compressed = compressed
                            Prefix = Some header
                            Parts = parts } ]

        let manifest = validateEntries digest ("BA2 v1 " + kind) source.Length limits stored
        Contents(source, stored, manifest, source.Length, limits, token) :> IArchiveContents

    let tryOpen (source: Stream) digest (limits: ArchiveLimits) token =
        if not source.CanSeek then
            unsupported ()

        seek source 0L

        if source.Length < 4L then
            None
        else
            let magic = readBytes source 4 |> fourcc

            match magic with
            | "BSA\000" -> Some(bsa source digest limits token)
            | "BTDX" -> Some(ba2 source digest limits token)
            | _ ->
                seek source 0L
                None
