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

    exception Refused of Error

    let refuse error = raise (Refused error)

    let invalid detail = refuse (Error.InvalidSource detail)

    let unsupported detail = refuse (Error.UnsupportedData detail)

    let private rootIdentity root =
        match (RootSelection.facts root).File with
        | Known identity -> identity
        | Unknown detail -> refuse (Error.UnsafeSource detail)

    let private selectedRoot (path: string) label =
        if String.IsNullOrWhiteSpace path then
            invalid ("Choose the " + label + ".")

        let full = Path.GetFullPath path

        match HostPath.create full with
        | Error _ -> invalid ("The " + label + " is unavailable.")
        | Ok value ->
            RootSelection.select value
            |> Result.defaultWith (fun _ -> invalid ("The " + label + " is unavailable."))

    let openEntry root path expected =
        let components = LogicalPath.components path
        let mutable current = HeldDirectory.Open(RootSelection.path root, rootIdentity root)
        let parents = ResizeArray<HeldDirectory>()

        try
            for name in components |> List.take (components.Length - 1) do
                let next = current.Directory(name, None)
                parents.Add current
                current <- next

            current.Read(List.last components, Some expected)
        finally
            (current :> IDisposable).Dispose()

            for parent in parents do
                (parent :> IDisposable).Dispose()

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
        let stream, actual = openEntry root path identity
        use stream = stream
        let length, sha, md5 = digest stream

        { Root = root
          Path = path
          Identity = actual
          Length = length
          Sha256 = sha
          Md5 = md5 }

    let directFile path label =
        let full = Path.GetFullPath path
        let parent = Path.GetDirectoryName full
        let root = selectedRoot parent label
        let name = Path.GetFileName full

        let logical =
            LogicalPath.create [ name ]
            |> Result.defaultWith (fun _ -> invalid ("The " + label + " name is invalid."))

        let entry =
            use directory = HeldDirectory.Open(RootSelection.path root, rootIdentity root)

            match directory.InspectEntry name with
            | Some value when value.Kind = EntryKind.RegularFile -> value
            | Some _ ->
                refuse (Error.UnsafeSource("The " + label + " is a link or unsupported file."))
            | None -> invalid ("The " + label + " is missing.")

        observe root logical entry.Identity

    let private inspectRoot path label =
        let root = selectedRoot path label

        let result =
            PathPreflight.inspect
                { Candidates = maxEntries
                  Depth = maxDepth
                  Diagnostics = 64 }
                TargetPolicy.windows
                root

        let manifest =
            { Path = Path.GetFullPath path
              RootIdentity = rootIdentity root
              Entries =
                result.Entries
                |> List.map (fun entry ->
                    LogicalPath.display entry.Logical,
                    entry.Kind,
                    entry.TargetKind,
                    entry.Facts.File)
                |> List.sortBy (fun (name, _, _, _) -> name)
              Diagnostics = result.Diagnostics |> List.sortBy _.Path }

        root, result, manifest

    let scanRoot path label =
        let root, result, manifest = inspectRoot path label

        result.Diagnostics
        |> List.tryFind (fun item ->
            item.Problem = TargetCollision || item.Problem = FileDirectoryConflict)
        |> Option.iter (fun item -> refuse (Error.CaseCollision item.Path))

        result.Diagnostics
        |> List.tryHead
        |> Option.iter (fun item ->
            refuse (Error.UnsafeSource("The " + label + " contains an unsafe entry: " + item.Path)))

        result.Entries
        |> List.tryFind (fun item -> item.Kind = EntryKind.Link || item.Kind = EntryKind.Other)
        |> Option.iter (fun item ->
            refuse (
                Error.UnsafeSource(
                    "The "
                    + label
                    + " contains a link or unsupported file: "
                    + LogicalPath.display item.Logical
                )
            ))

        root, result.Entries, manifest

    let verifyManifest expected label =
        let current =
            try
                let _, _, value = inspectRoot expected.Path label
                Some value
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if current <> Some expected then
            refuse Error.SourceChanged

    let verify stamp =
        let current =
            try
                Some(observe stamp.Root stamp.Path stamp.Identity)
            with
            | :? IOException
            | :? UnauthorizedAccessException
            | Refused _ -> None

        if
            current
            |> Option.forall (fun value ->
                value.Identity <> stamp.Identity
                || value.Length <> stamp.Length
                || value.Sha256 <> stamp.Sha256)
        then
            refuse Error.SourceChanged

    let private copy stamp (destination: FileStream) (token: CancellationToken) =
        let source, identity = openEntry stamp.Root stamp.Path stamp.Identity
        use source = source

        if identity <> stamp.Identity || source.Length <> stamp.Length then
            refuse Error.SourceChanged

        let buffer = Array.zeroCreate<byte> 65536
        use hash = IncrementalHash.CreateHash HashAlgorithmName.SHA256
        let mutable read = 0L

        while read < stamp.Length do
            token.ThrowIfCancellationRequested()

            let count =
                source.Read(buffer, 0, int (min (int64 buffer.Length) (stamp.Length - read)))

            if count = 0 then
                refuse Error.SourceChanged

            destination.Write(buffer, 0, count)
            hash.AppendData(buffer, 0, count)
            read <- read + int64 count

        if source.ReadByte() <> -1 || source.Length <> stamp.Length then
            refuse Error.SourceChanged

        let sha = Convert.ToHexStringLower(hash.GetHashAndReset())

        if sha <> stamp.Sha256 then
            refuse Error.SourceChanged

        destination.Flush true
        read, sha

    let transferFile path stamp : Direct.File =
        { Path = path
          Read =
            fun destination token ->
                try
                    Ok(copy stamp destination token)
                with Refused error ->
                    Error error }

    let components (entry: PathEntry) = LogicalPath.components entry.Logical
