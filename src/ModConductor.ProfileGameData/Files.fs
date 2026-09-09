namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform

type internal DataRoot =
    { Path: HostPath
      Identity: FileIdentity }

type internal DataFile =
    { Identity: FileIdentity
      Length: int64
      Sha256: string }

type internal StoredDataFile =
    { Root: DataRoot
      Name: string
      File: DataFile }

type internal PreparedFileChange =
    { Name: string
      Before: DataFile option
      Replacement: StoredDataFile option
      BackupName: string }

exception internal ProfileDataException of ProfileDataError

module internal DataFiles =
    let fail detail =
        raise (ProfileDataException(ProfileDataError.Conflict detail))

    let private digest (token: CancellationToken) (stream: Stream) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let bytes = Array.zeroCreate<byte> 65536
        let mutable reading = true

        while reading do
            token.ThrowIfCancellationRequested()
            let count = stream.Read(bytes, 0, bytes.Length)

            if count = 0 then
                reading <- false
            else
                hash.AppendData(bytes, 0, count)

        Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant()

    let observe (directory: HeldDirectory) name token =
        match directory.InspectEntry name with
        | None -> None
        | Some entry when entry.Kind = EntryKind.RegularFile ->
            let stream, identity = directory.Read(name, Some entry.Identity)
            use stream = stream
            let length = stream.Length
            let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle
            let sha = digest token stream

            if
                stream.Length <> length
                || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
            then
                fail (name + " changed.")

            Some
                { Identity = identity
                  Length = length
                  Sha256 = sha }
        | Some _ -> fail (name + " is not a regular file.")

    let check directory name expected token =
        if observe directory name token <> expected then
            fail (name + " changed.")

    let readIni (directory: HeldDirectory) name expected token =
        match expected with
        | None ->
            check directory name None token
            None
        | Some expected ->
            let stream, _ = directory.Read(name, Some expected.Identity)
            use stream = stream

            if stream.Length > 16L * 1024L * 1024L then
                raise (
                    ProfileDataException(
                        ProfileDataError.Unavailable "The settings file exceeds 16 MiB."
                    )
                )

            let bytes = Array.zeroCreate<byte> (int stream.Length)
            stream.ReadExactly(bytes.AsSpan())
            token.ThrowIfCancellationRequested()
            let sha = Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant()

            if bytes.LongLength <> expected.Length || sha <> expected.Sha256 then
                fail (name + " changed.")

            Some bytes

    let stage (directory: HeldDirectory) name (bytes: byte array) (token: CancellationToken) =
        token.ThrowIfCancellationRequested()
        let stream, identity = directory.Create name
        use stream = stream
        stream.Write(bytes, 0, bytes.Length)
        stream.Flush true

        { Identity = identity
          Length = bytes.LongLength
          Sha256 = Convert.ToHexString(SHA256.HashData bytes).ToLowerInvariant() }

    let copy
        (source: HeldDirectory)
        name
        (expected: DataFile)
        (destination: HeldDirectory)
        stagedName
        (token: CancellationToken)
        progress
        =
        let input, _ = source.Read(name, Some expected.Identity)
        use input = input
        let output, identity = destination.Create stagedName
        use output = output

        try
            use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
            let buffer = Array.zeroCreate<byte> 65536
            let mutable total = 0L
            let mutable reading = true

            while reading do
                token.ThrowIfCancellationRequested()
                let count = input.Read(buffer, 0, buffer.Length)

                if count = 0 then
                    reading <- false
                else
                    output.Write(buffer, 0, count)
                    hash.AppendData(buffer, 0, count)
                    total <- total + int64 count
                    progress total

            output.Flush true
            let sha = Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant()

            if total <> expected.Length || sha <> expected.Sha256 then
                fail (name + " changed.")

            { Identity = identity
              Length = total
              Sha256 = sha }
        with _ ->
            output.Dispose()
            destination.RemoveFile(stagedName, identity)
            reraise ()

    let private entry (file: DataFile) =
        { Identity = file.Identity
          Kind = EntryKind.RegularFile
          LinkTarget = None
          DirectoryLink = None }

    let apply
        (target: HeldDirectory)
        (prepared: HeldDirectory)
        (change: PreparedFileChange)
        token
        checkpoint
        =
        let current = observe target change.Name token
        let backup = observe prepared change.BackupName token

        match change.Before, backup with
        | Some expected, None ->
            if current <> Some expected then
                fail (change.Name + " changed.")

            target.MoveOriginal(change.Name, entry expected, prepared, change.BackupName)
            checkpoint "preserved"
        | Some expected, Some actual when expected = actual -> ()
        | None, None -> ()
        | _ -> fail (change.Name + " has a different preserved original.")

        match change.Replacement with
        | Some replacement ->
            use source = HeldDirectory.Open(replacement.Root.Path, replacement.Root.Identity)

            match observe source replacement.Name token with
            | Some actual when actual = replacement.File ->
                check target change.Name None token
                source.MoveOriginal(replacement.Name, entry actual, target, change.Name)
                checkpoint "installed"
            | None -> check target change.Name (Some replacement.File) token
            | Some _ -> fail (change.Name + " has a different prepared copy.")
        | None -> check target change.Name None token
