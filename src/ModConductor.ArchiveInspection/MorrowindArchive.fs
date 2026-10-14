namespace ModConductor.ArchiveInspection

open System.IO
open System.Threading
open ModConductor.Platform
open BethesdaArchiveCommon

module internal MorrowindArchive =
    let private entries (source: Stream) count hashes (token: CancellationToken) =
        let records = [ for _ in 1..count -> int64 (u32 source), int64 (u32 source) ]
        let offsets = [ for _ in 1..count -> int64 (u32 source) ]
        let names = source.Position
        let data = hashes + int64 count * 8L

        [ for index in 0 .. count - 1 do
              token.ThrowIfCancellationRequested()
              let size, offset = records[index]
              let position = names + offsets[index]

              if position < names || position >= hashes then
                  malformed ()

              seek source position
              let name = terminatedName source

              if source.Position > hashes then
                  malformed ()

              range source (data + offset) size

              yield
                  { Path = ArchiveNames.parse name
                    Expanded = size
                    Compressed = None
                    Prefix = None
                    Parts =
                      [ { Offset = data + offset
                          Stored = size
                          Expanded = size
                          Codec = Raw } ] } ]

    let openContents (source: Stream) digest token =
        let hashes = 12L + int64 (u32 source)
        let count = int (u32 source)

        if count < 0 then
            malformed ()

        let metadata = 12L + int64 count * 12L

        if hashes < metadata then
            malformed ()

        range source 12L (hashes - 12L + int64 count * 8L)
        let stored = entries source count hashes token
        let manifest = manifest digest "BSA v256" stored
        Contents(source, stored, manifest, token) :> IArchiveContents
