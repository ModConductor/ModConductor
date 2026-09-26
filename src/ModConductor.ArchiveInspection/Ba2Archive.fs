namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open ModConductor.Platform
open BethesdaArchiveCommon

open Ba2Texture

module internal Ba2Archive =
    let private overlaps start length otherStart otherEnd =
        length > 0L && start < otherEnd && otherStart < start + length

    let openContents (source: Stream) digest (limits: ArchiveLimits) token =
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
