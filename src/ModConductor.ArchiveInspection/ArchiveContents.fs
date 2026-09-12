namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open SharpCompress.Archives
open SharpCompress.Archives.SevenZip
open SharpCompress.Common
open SharpCompress.Common.Rar
open SharpCompress.Common.SevenZip
open ModConductor.Platform

type ArchiveContents
    internal
    (
        archive: IArchive,
        digest: string,
        compressedLength: int64,
        limits: ArchiveLimits,
        token: CancellationToken
    ) =
    let refuse = ArchiveNames.refuse

    let format =
        match archive.Type with
        | ArchiveType.Zip -> "ZIP"
        | ArchiveType.SevenZip -> "7z"
        | ArchiveType.Rar -> "RAR"
        | _ -> refuse "This archive format is not supported."

    let mutable total = 0L
    let mutable names = 0
    let raw = ResizeArray<IArchiveEntry>()

    let entries =
        [ for entry in archive.Entries do
              token.ThrowIfCancellationRequested()

              if raw.Count >= limits.Entries then
                  refuse "The archive contains too many entries."

              if entry.CompressionType = CompressionType.Unknown then
                  refuse "This archive compression method is not supported."

              if entry.IsEncrypted then
                  refuse "This archive needs a password. Obtain an unencrypted copy."

              if
                  not entry.IsComplete
                  || entry.IsSplitAfter
                  || entry.VolumeIndexFirst <> entry.VolumeIndexLast
              then
                  refuse "Split archive volumes are not supported. Obtain a single archive."

              let redirection =
                  match entry with
                  | :? RarEntry as rar -> rar.IsRedir
                  | :? SevenZipArchiveEntry as seven -> seven.IsAnti
                  | _ -> false

              let attr = if entry.Attrib.HasValue then entry.Attrib.Value else 0

              let mode =
                  match entry with
                  | :? RarEntry -> attr &&& 0xF000
                  | :? SevenZipEntry as seven when seven.ExtendedAttrib.HasValue ->
                      seven.ExtendedAttrib.Value &&& 0xF000
                  | _ -> (attr >>> 16) &&& 0xF000

              if
                  redirection
                  || not (isNull entry.LinkTarget)
                  || (attr &&& 0x400 <> 0 && archive.Type <> ArchiveType.Rar)
                  || (mode <> 0 && mode <> 0x8000 && mode <> 0x4000)
              then
                  refuse "The archive contains a link, device or unsupported file type."

              let path = ArchiveNames.parse limits entry.IsDirectory entry.Key
              names <- names + entry.Key.Length

              if names > limits.NameCharacters then
                  refuse "The archive contains too much filename data."

              let size = entry.Size

              if size < 0L || size > limits.FileBytes then
                  refuse "An archive entry exceeds the file size limit."

              if size > limits.TotalBytes - total then
                  refuse "The archive exceeds the expanded size limit."

              total <- total + size
              let packed = entry.CompressedSize

              if
                  not entry.IsSolid
                  && packed > 0L
                  && decimal size > decimal limits.Ratio * decimal packed
              then
                  refuse "The archive exceeds the expansion ratio limit."

              let index = raw.Count
              raw.Add entry

              yield
                  { Index = index
                    Path = path
                    Directory = entry.IsDirectory
                    Size = size
                    CompressedSize = if packed > 0L then Some packed else None } ]

    do
        if decimal total > decimal limits.Ratio * decimal (max 1L compressedLength) then
            refuse "The archive exceeds the expansion ratio limit."

        ArchiveNames.validate limits entries

    let manifest =
        { Sha256 = digest
          Format = format
          Entries = entries
          TotalSize = total }

    member _.Manifest = manifest

    member _.ReadEntry(index: int, consume: Stream -> unit) =
        if index < 0 || index >= raw.Count || raw[index].IsDirectory then
            invalidArg (nameof index) "Choose a file entry from this manifest."

        let mutable decoded = 0L

        let count n =
            decoded <- decoded + n

            if
                decoded > limits.TotalBytes
                || decimal decoded > decimal limits.Ratio * decimal (max 1L compressedLength)
            then
                refuse "The archive entry read exceeds the expanded data limit."

        let read (source: Stream) expected action =
            use source = source
            use bounded = new EntryRead(source, expected, count, token)
            action (bounded :> Stream)
            bounded.CopyTo Stream.Null

        if archive.IsSolid then
            use reader = archive.ExtractAllEntries()
            let mutable found = false

            while not found && reader.MoveToNextEntry() do
                token.ThrowIfCancellationRequested()

                if not reader.Entry.IsDirectory then
                    found <- reader.Entry.Key = raw[index].Key

                    read
                        (reader.OpenEntryStream())
                        reader.Entry.Size
                        (if found then consume else ignore)

            if not found then
                raise (InvalidDataException "The archive entry is missing.")
        else
            read (raw[index].OpenEntryStream()) raw[index].Size consume
