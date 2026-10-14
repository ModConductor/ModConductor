namespace ModConductor.ArchiveInspection

open System
open System.IO
open System.Threading
open SharpCompress.Archives
open SharpCompress.Common
open ModConductor.Platform

type internal IArchiveContents =
    abstract Manifest: ArchiveManifest
    abstract ReadEntries: int list * (int * Stream -> unit) -> unit

type ArchiveContents internal (contents: IArchiveContents) =
    member _.Manifest = contents.Manifest

    member _.ReadEntries(indices: int list, consume: int * Stream -> unit) =
        contents.ReadEntries(indices, consume)

    member this.ReadEntry(index: int, consume: Stream -> unit) =
        this.ReadEntries([ index ], fun (_, stream) -> consume stream)

type internal SharpArchiveContents
    internal (archive: IArchive, digest: string, token: CancellationToken) =
    let format =
        match archive.Type with
        | ArchiveType.Zip -> "ZIP"
        | ArchiveType.SevenZip -> "7z"
        | ArchiveType.Rar -> "RAR"
        | _ -> string archive.Type

    let mutable total = 0L
    let raw = ResizeArray<IArchiveEntry>()

    let entries =
        [ for entry in archive.Entries do
              token.ThrowIfCancellationRequested()

              let path = ArchiveNames.parse entry.Key
              let size = entry.Size
              total <- total + size
              let packed = entry.CompressedSize

              let index = raw.Count
              raw.Add entry

              yield
                  { Index = index
                    Path = path
                    Directory = entry.IsDirectory
                    Size = size
                    CompressedSize = if packed > 0L then Some packed else None } ]

    let manifest =
        { Sha256 = digest
          Format = format
          Entries = entries
          TotalSize = total }

    interface IArchiveContents with
        member _.Manifest = manifest

        member _.ReadEntries(indices: int list, consume: int * Stream -> unit) =
            let selected = System.Collections.Generic.HashSet<int>(indices)

            if
                selected.Count <> indices.Length
                || indices
                   |> List.exists (fun index ->
                       index < 0 || index >= raw.Count || raw[index].IsDirectory)
            then
                invalidArg (nameof indices) "Choose file entries from this manifest."

            let read (source: Stream) expected action =
                use source = source
                use stream = new EntryRead(source, expected, token)
                action (stream :> Stream)
                stream.CopyTo Stream.Null

            if archive.IsSolid && selected.Count > 0 then
                let byName =
                    Collections.Generic.Dictionary<string, Collections.Generic.Queue<int>>()

                for entry in entries do
                    if not entry.Directory then
                        let name = raw[entry.Index].Key

                        match byName.TryGetValue name with
                        | true, indices -> indices.Enqueue entry.Index
                        | _ -> byName[name] <- Collections.Generic.Queue<int>([ entry.Index ])

                use reader = archive.ExtractAllEntries()

                while selected.Count > 0 && reader.MoveToNextEntry() do
                    token.ThrowIfCancellationRequested()

                    if not reader.Entry.IsDirectory then
                        let index =
                            match byName.TryGetValue reader.Entry.Key with
                            | true, indices when indices.Count > 0 -> Some(indices.Dequeue())
                            | _ -> None

                        let wanted = index |> Option.filter selected.Remove

                        read (reader.OpenEntryStream()) reader.Entry.Size (fun stream ->
                            wanted |> Option.iter (fun index -> consume (index, stream)))

                if selected.Count <> 0 then
                    raise (InvalidDataException "An archive entry is missing.")
            else
                for index in indices |> List.sort do
                    read (raw[index].OpenEntryStream()) raw[index].Size (fun stream ->
                        consume (index, stream))
