namespace ModConductor.Migration

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform

module internal VortexSource =
    let maxEntries = 100000
    let maxDepth = 64

    type Stamp =
        { Root: SelectedRoot
          Path: LogicalPath
          Identity: FileIdentity
          Length: int64
          Sha256: string
          Md5: string }

    type Manifest =
        { Path: string
          RootIdentity: FileIdentity
          Entries: (string * EntryKind * EntryKind * Observation<FileIdentity>) list
          Diagnostics: PathDiagnostic list }

    open MigrationResult

    let invalid detail = Error(Error.InvalidSource detail)

    let unsupported detail = Error(Error.UnsupportedData detail)

    let private rootIdentity root =
        match (RootSelection.facts root).File with
        | Known identity -> Ok identity
        | Unknown detail -> Error(Error.UnsafeSource detail)

    let private selectedRoot (path: string) label =
        result {
            if String.IsNullOrWhiteSpace path then
                return! invalid ("Choose the " + label + ".")

            let full = Path.GetFullPath path

            let! host =
                HostPath.create full
                |> Result.mapError (fun _ ->
                    Error.InvalidSource("The " + label + " is unavailable."))

            return!
                RootSelection.select host
                |> Result.mapError (fun _ ->
                    Error.InvalidSource("The " + label + " is unavailable."))
        }

    let openEntry root path expected =
        result {
            let! rootId = rootIdentity root
            let components = LogicalPath.components path
            let mutable current = HeldDirectory.Open(RootSelection.path root, rootId)
            let parents = ResizeArray<HeldDirectory>()

            try
                for name in components |> List.take (components.Length - 1) do
                    let next = current.Directory(name, None)
                    parents.Add current
                    current <- next

                return current.Read(List.last components, Some expected)
            finally
                (current :> IDisposable).Dispose()

                for parent in parents do
                    (parent :> IDisposable).Dispose()
        }

    let private digest (stream: Stream) =
        use sha = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        use md5 = IncrementalHash.CreateHash HashAlgorithmName.MD5
        let buffer = Array.zeroCreate<byte> 65536
        let mutable length = 0L
        let mutable reading = true

        while reading do
            let count = stream.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                length <- length + int64 count
                sha.AppendData(buffer, 0, count)
                md5.AppendData(buffer, 0, count)

        length,
        Convert.ToHexStringLower(sha.GetHashAndReset()),
        Convert.ToHexStringLower(md5.GetHashAndReset())

    let observe root path identity =
        result {
            let! stream, actual = openEntry root path identity
            use stream = stream
            let length, sha, md5 = digest stream

            return
                { Root = root
                  Path = path
                  Identity = actual
                  Length = length
                  Sha256 = sha
                  Md5 = md5 }
        }

    let directFile path label =
        result {
            let full = Path.GetFullPath path
            let parent = Path.GetDirectoryName full
            let! root = selectedRoot parent label
            let! rootId = rootIdentity root
            let name = Path.GetFileName full

            let! logical =
                LogicalPath.create [ name ]
                |> Result.mapError (fun _ ->
                    Error.InvalidSource("The " + label + " name is invalid."))

            let! entry =
                use directory = HeldDirectory.Open(RootSelection.path root, rootId)

                match directory.InspectEntry name with
                | Some value when value.Kind = EntryKind.RegularFile -> Ok value
                | Some _ ->
                    Error(Error.UnsafeSource("The " + label + " is a link or unsupported file."))
                | None -> invalid ("The " + label + " is missing.")

            return! observe root logical entry.Identity
        }

    let private inspectRoot path label =
        result {
            let! root = selectedRoot path label
            let! rootId = rootIdentity root

            let scan =
                PathPreflight.inspect
                    { Candidates = maxEntries
                      Depth = maxDepth
                      Diagnostics = 64 }
                    TargetPolicy.windows
                    root

            let manifest =
                { Path = Path.GetFullPath path
                  RootIdentity = rootId
                  Entries =
                    scan.Entries
                    |> List.map (fun entry ->
                        LogicalPath.display entry.Logical,
                        entry.Kind,
                        entry.TargetKind,
                        entry.Facts.File)
                    |> List.sortBy (fun (name, _, _, _) -> name)
                  Diagnostics = scan.Diagnostics |> List.sortBy _.Path }

            return root, scan, manifest
        }

    let scanRoot path label =
        result {
            let! root, scan, manifest = inspectRoot path label

            match
                scan.Diagnostics
                |> List.tryFind (fun item ->
                    item.Problem = TargetCollision || item.Problem = FileDirectoryConflict)
            with
            | Some item -> return! Error(Error.CaseCollision item.Path)
            | None -> ()

            match scan.Diagnostics |> List.tryHead with
            | Some item ->
                return!
                    Error(
                        Error.UnsafeSource(
                            "The " + label + " contains an unsafe entry: " + item.Path
                        )
                    )
            | None -> ()

            match
                scan.Entries
                |> List.tryFind (fun item ->
                    item.Kind = EntryKind.Link || item.Kind = EntryKind.Other)
            with
            | Some item ->
                return!
                    Error(
                        Error.UnsafeSource(
                            "The "
                            + label
                            + " contains a link or unsupported file: "
                            + LogicalPath.display item.Logical
                        )
                    )
            | None -> ()

            return root, scan.Entries, manifest
        }

    let verifyManifest expected label =
        let current =
            try
                inspectRoot expected.Path label |> Result.map (fun (_, _, value) -> value)
            with
            | :? IOException
            | :? UnauthorizedAccessException -> Error Error.SourceChanged

        match current with
        | Ok value when value = expected -> Ok()
        | _ -> Error Error.SourceChanged

    let verify stamp =
        let current =
            try
                observe stamp.Root stamp.Path stamp.Identity
            with
            | :? IOException
            | :? UnauthorizedAccessException -> Error Error.SourceChanged

        match current with
        | Ok value when
            value.Identity = stamp.Identity
            && value.Length = stamp.Length
            && value.Sha256 = stamp.Sha256
            ->
            Ok()
        | _ -> Error Error.SourceChanged

    let private copy stamp (destination: FileStream) (token: CancellationToken) =
        result {
            let! source, identity = openEntry stamp.Root stamp.Path stamp.Identity
            use source = source

            if identity <> stamp.Identity || source.Length <> stamp.Length then
                return! Error Error.SourceChanged

            let buffer = Array.zeroCreate<byte> 65536
            use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
            let mutable read = 0L

            while read < stamp.Length do
                token.ThrowIfCancellationRequested()

                let count =
                    source.Read(buffer, 0, int (min (int64 buffer.Length) (stamp.Length - read)))

                if count = 0 then
                    return! Error Error.SourceChanged

                destination.Write(buffer, 0, count)
                hash.AppendData(buffer, 0, count)
                read <- read + int64 count

            if source.ReadByte() <> -1 || source.Length <> stamp.Length then
                return! Error Error.SourceChanged

            let sha = Convert.ToHexStringLower(hash.GetHashAndReset())

            if sha <> stamp.Sha256 then
                return! Error Error.SourceChanged

            destination.Flush true
            return read, sha
        }

    let transferFile path stamp : Direct.File =
        { Path = path
          Read = fun destination token -> copy stamp destination token }

    let components (entry: PathEntry) = LogicalPath.components entry.Logical
