namespace ModConductor.Migration

open System
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading
open ModConductor.ModLibrary
open ModConductor.ModSelection
open ModConductor.Platform

module internal ModOrganizerInput =
    let maxEntries = 100000
    let private maxDepth = 64
    let private maxTextBytes = 4 * 1024 * 1024

    type Stamp =
        { Root: SelectedRoot
          Path: LogicalPath
          Identity: FileIdentity
          Length: int64
          Sha256: string }

    type Manifest =
        { Path: string
          RootIdentity: FileIdentity
          Entries: (string * EntryKind * EntryKind * Observation<FileIdentity>) list
          Diagnostics: PathDiagnostic list }

    type SourceFile = { Stamp: Stamp; Path: LogicalPath }

    type SourceMod =
        { Id: Guid
          VersionId: Guid
          Name: string
          Kind: ModKind
          Metadata: ModMetadata
          CategorySourceIds: int list
          InstalledFiles: (int * int) list
          Files: SourceFile list }

    type SourceProfile =
        { Id: Guid
          Name: string
          Mods: OrderedMod list }

    type SourceArtifact =
        { Id: Guid
          OriginalName: string
          OriginalPath: string
          File: SourceFile
          Partial: bool
          Sources: string list
          InstalledMod: Guid option }

    type Source =
        { Categories: Category list
          Mods: SourceMod list
          Profiles: SourceProfile list
          SelectedProfile: Guid
          Artifacts: SourceArtifact list
          Stamps: Stamp list
          Manifests: Manifest list
          AbsentPaths: string list }

    open MigrationResult

    let private rootIdentity root =
        match (RootSelection.facts root).File with
        | Known identity -> Ok identity
        | Unknown detail -> Error(Error.UnsafeSource detail)

    let private digest (stream: Stream) =
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let buffer = Array.zeroCreate<byte> 65536
        let mutable length = 0L
        let mutable reading = true

        while reading do
            let count = stream.Read(buffer, 0, buffer.Length)

            if count = 0 then
                reading <- false
            else
                length <- length + int64 count
                hash.AppendData(buffer, 0, count)

        length, Convert.ToHexStringLower(hash.GetHashAndReset())

    let private openEntry root path expected =
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

    let private observe root path identity =
        result {
            let! stream, actual = openEntry root path identity
            use stream = stream
            let length, sha = digest stream

            return
                { Root = root
                  Path = path
                  Identity = actual
                  Length = length
                  Sha256 = sha }
        }

    let private selectedRoot (path: string) =
        match HostPath.create path with
        | Error _ -> Error(Error.InvalidSource "The selected source folder is unavailable.")
        | Ok value ->
            RootSelection.select value
            |> Result.mapError (fun _ ->
                Error.InvalidSource "The selected source folder is unavailable.")

    let directFile (path: string) =
        result {
            let parent = Path.GetDirectoryName path
            let! root = selectedRoot parent
            let! rootId = rootIdentity root

            let! logical =
                LogicalPath.create [ Path.GetFileName path ]
                |> Result.mapError (fun _ -> Error.InvalidSource "A source file name is invalid.")

            let! entry =
                use directory = HeldDirectory.Open(RootSelection.path root, rootId)

                match directory.InspectEntry(Path.GetFileName path) with
                | Some value when value.Kind = EntryKind.RegularFile -> Ok value
                | Some _ ->
                    Error(Error.UnsafeSource "A source file is a link or unsupported file type.")
                | None -> Error(Error.InvalidSource "A required source file is missing.")

            return! observe root logical entry.Identity
        }

    let private bytes stamp =
        result {
            if stamp.Length > int64 maxTextBytes then
                return! Error(Error.InvalidSource "A Mod Organizer settings file is too large.")

            let! stream, _ = openEntry stamp.Root stamp.Path stamp.Identity
            use stream = stream
            let content = Array.zeroCreate<byte> (int stamp.Length)
            stream.ReadExactly content
            return content
        }

    let text stamp =
        result {
            let! value = bytes stamp

            try
                let offset =
                    if value.Length >= 3 && value[0..2] = [| 0xEFuy; 0xBBuy; 0xBFuy |] then
                        3
                    else
                        0

                return UTF8Encoding(false, true).GetString(value, offset, value.Length - offset)
            with :? DecoderFallbackException ->
                return! Error(Error.InvalidSource "A Mod Organizer text file is not valid UTF-8.")
        }

    let private inspectRoot path =
        result {
            let! root = selectedRoot path
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
                    |> List.sortBy (fun (path, _, _, _) -> path)
                  Diagnostics = scan.Diagnostics |> List.sortBy (fun item -> item.Path) }

            return root, scan, manifest
        }

    let scanRoot path =
        result {
            let! root, scan, manifest = inspectRoot path

            match
                scan.Diagnostics
                |> List.tryFind (fun item ->
                    item.Problem = TargetCollision || item.Problem = FileDirectoryConflict)
            with
            | Some item -> return! Error(Error.CaseCollision item.Path)
            | None -> ()

            match scan.Diagnostics |> List.tryHead with
            | Some item ->
                return! Error(Error.UnsafeSource("The source entry is unsafe: " + item.Path))
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
                            "The source entry is a link or unsupported file: "
                            + LogicalPath.display item.Logical
                        )
                    )
            | None -> ()

            return root, scan.Entries, manifest
        }

    let verifyManifest (expected: Manifest) =
        let current =
            try
                inspectRoot expected.Path |> Result.map (fun (_, _, value) -> value)
            with
            | :? IOException
            | :? UnauthorizedAccessException -> Error Error.SourceChanged

        match current with
        | Ok value when value = expected -> Ok()
        | _ -> Error Error.SourceChanged

    let pathExists (path: string) =
        try
            File.GetAttributes path |> ignore
            true
        with
        | :? FileNotFoundException
        | :? DirectoryNotFoundException -> false

    let stamp root (entry: PathEntry) =
        match entry.Facts.File with
        | Known identity -> observe root entry.Logical identity
        | Unknown detail -> Error(Error.UnsafeSource detail)

    let components (entry: PathEntry) = LogicalPath.components entry.Logical

    let rootDirectories entries =
        entries
        |> List.choose (fun entry ->
            match components entry with
            | [ name ] when entry.TargetKind = EntryKind.Directory -> Some name
            | _ -> None)
        |> List.sortWith (fun left right -> StringComparer.OrdinalIgnoreCase.Compare(left, right))

    let exactChild parent (entries: PathEntry list) name =
        entries
        |> List.tryFind (fun entry ->
            match components entry with
            | [ first; second ] ->
                String.Equals(first, parent, StringComparison.Ordinal)
                && String.Equals(second, name, StringComparison.OrdinalIgnoreCase)
            | _ -> false)

    let private copy (stamp: Stamp) (destination: FileStream) (token: CancellationToken) =
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

    let verify stamp =
        let observed =
            try
                observe stamp.Root stamp.Path stamp.Identity
            with
            | :? IOException
            | :? UnauthorizedAccessException -> Error Error.SourceChanged

        match observed with
        | Ok value when value.Length = stamp.Length && value.Sha256 = stamp.Sha256 -> Ok()
        | _ -> Error Error.SourceChanged

    let transferFile (file: SourceFile) : Direct.File =
        { Path = file.Path
          Read = fun destination token -> copy file.Stamp destination token }
