namespace ModConductor.Persistence

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform

module internal ArtifactFiles =
    let stage (id: Guid) =
        "artifact-" + id.ToString("N") + ".partial"

    let final (id: Guid) =
        "artifact-" + id.ToString("N") + ".archive"

    let openExternal (path: string) expected =
        let parent =
            Path.GetDirectoryName path
            |> HostPath.create
            |> Result.bind (fun path ->
                RootSelection.select path
                |> Result.mapError (fun _ -> "The archive folder is unavailable."))
            |> Result.defaultWith (fun message -> raise (IOException message))

        let identity =
            match (RootSelection.facts parent).File with
            | Known value -> value
            | Unknown message -> raise (IOException message)

        use directory = HeldDirectory.Open(RootSelection.path parent, identity)
        directory.Read(Path.GetFileName path, expected)

    let transfer
        (token: CancellationToken)
        (source: FileStream)
        (destination: FileStream option)
        checkpoint
        =
        let length = source.Length
        let buffer = Array.zeroCreate<byte> 65536
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let mutable read = 0L

        while read < length do
            token.ThrowIfCancellationRequested()
            let count = source.Read(buffer, 0, int (min (int64 buffer.Length) (length - read)))

            if count = 0 then
                raise (IOException "The archive changed while reading.")

            hash.AppendData(buffer, 0, count)
            destination |> Option.iter (fun output -> output.Write(buffer, 0, count))
            read <- read + int64 count
            checkpoint "bytes"

        if source.ReadByte() <> -1 || source.Length <> length then
            raise (IOException "The archive changed while reading.")

        destination |> Option.iter (fun output -> output.Flush(true))
        length, Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant()

    let verify (token: CancellationToken) length digest (file: FileStream) =
        if Some file.Length <> length then
            raise (IOException "The archive does not match the saved file.")

        let actualLength, actualDigest = transfer token file None ignore

        if Some actualLength <> length || Some actualDigest <> digest then
            raise (IOException "The archive does not match the saved file.")

    let remove (directory: HeldDirectory) name expected =
        match directory.InspectEntry name with
        | None -> ()
        | Some entry when Some entry.Identity = expected && entry.Kind = EntryKind.RegularFile ->
            directory.RemoveFile(name, entry.Identity)
        | Some _ -> raise (IOException "The library file changed. It was not deleted.")

    let promote (directory: HeldDirectory) id expected =
        match directory.InspectEntry(stage id) with
        | Some entry when Some entry.Identity = expected && entry.Kind = EntryKind.RegularFile ->
            directory.MoveOriginal(stage id, entry, directory, final id)
        | _ -> raise (IOException "The staged archive changed.")
