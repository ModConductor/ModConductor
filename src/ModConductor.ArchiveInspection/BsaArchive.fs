namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open ModConductor.Platform
open BethesdaArchiveCommon

module internal BsaArchive =
    let openContents (source: Stream) digest (limits: ArchiveLimits) token =
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
