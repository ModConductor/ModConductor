namespace ModConductor.GeneratedOutputs

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.ModLibrary

type internal OutputBacking =
    { Location: OutputLocation
      Root: HostPath
      RootIdentity: FileIdentity
      Path: LogicalPath option }

type internal OutputObservation =
    { File: OutputFile
      Backing: OutputBacking
      Modified: DateTime }

exception internal OutputException of OutputError

module internal OutputFiles =
    let withParent (root: HeldDirectory) path action =
        let rec walk (directory: HeldDirectory) =
            function
            | [] -> invalidArg "path" "Select a file."
            | [ name ] -> action directory name
            | name :: rest ->
                use child = directory.Directory(name, None)
                walk child rest

        walk root (LogicalPath.components path)

    let path (backing: OutputBacking) file =
        backing.Path |> Option.defaultValue file

    let observe
        (backings: OutputBacking list)
        prior
        deployment
        progress
        (token: CancellationToken)
        =
        let observations = ResizeArray<OutputObservation>()
        let mutable candidates = 0
        let mutable bytes = 0L
        let mutable encoded = 0L
        let mutable last = DateTime.MinValue
        let now = DateTimeOffset.UtcNow

        let notify () =
            if (DateTime.UtcNow - last).TotalMilliseconds >= 100. then
                progress
                    { Files = observations.Count
                      Bytes = bytes }

                last <- DateTime.UtcNow

        let append backing logical identity length modified digest =
            let state =
                match identity, Map.tryFind (backing.Location.Id, logical) prior with
                | None, _ -> OutputFileState.Absent
                | Some _, Some(previousHash, kept) when previousHash = digest ->
                    if kept then OutputFileState.Kept else OutputFileState.New
                | Some _, Some _ -> OutputFileState.Changed
                | Some _, None -> OutputFileState.New

            let file =
                { LocationId = backing.Location.Id
                  Path = logical
                  State = state
                  Length = length
                  Sha256 = digest
                  Identity = identity
                  ObservedAt = now
                  DeploymentId = deployment }

            let nextEncoded = encoded + int64 (OutputPolicy.fileSize file)

            if nextEncoded > OutputLimits.snapshot then
                Error OutputError.LimitExceeded
            else
                encoded <- nextEncoded

                observations.Add
                    { File = file
                      Backing = backing
                      Modified = modified }

                notify ()
                Ok()

        let read backing (directory: HeldDirectory) name logical identity =
            let stream, actual = directory.Read(name, Some identity)
            use stream = stream
            let length = stream.Length

            if length > OutputLimits.content - bytes then
                Error OutputError.LimitExceeded
            else
                let modified = File.GetLastWriteTimeUtc stream.SafeFileHandle
                let completed = bytes

                let hash =
                    SourceFiles.digestChecked
                        (fun () ->
                            token.ThrowIfCancellationRequested()
                            bytes <- completed + stream.Position
                            notify ())
                        stream

                bytes <- completed + length

                if
                    stream.Length <> length
                    || File.GetLastWriteTimeUtc stream.SafeFileHandle <> modified
                then
                    Error OutputError.Stale
                else
                    append backing logical (Some actual) length modified hash

        let rec walk backing (directory: HeldDirectory) components depth =
            if depth > OutputLimits.depth then
                Error OutputError.LimitExceeded
            else
                use names = directory.Names.GetEnumerator()
                let mutable outcome = Ok()

                while Result.isOk outcome && names.MoveNext() do
                    outcome <- visit backing directory components depth names.Current

                outcome

        and visit backing (directory: HeldDirectory) components depth name =
            token.ThrowIfCancellationRequested()
            candidates <- candidates + 1

            if candidates > OutputLimits.entries then
                Error OutputError.LimitExceeded
            else
                let parts = components @ [ name ]

                match LogicalPath.create parts with
                | Error _ -> Error(OutputError.Invalid "An output path is invalid.")
                | Ok logical ->
                    match directory.InspectEntry name with
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        use child = directory.Directory(name, Some entry.Identity)
                        walk backing child parts (depth + 1)
                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                        read backing directory name logical entry.Identity
                    | _ ->
                        Error(
                            OutputError.Unavailable
                                "An output folder contains a link or unsupported file."
                        )

        let observeBacking backing =
            token.ThrowIfCancellationRequested()
            use root = HeldDirectory.Open(backing.Root, backing.RootIdentity)

            match backing.Location.Purpose with
            | OutputPurpose.WritableFile logical ->
                withParent root (path backing logical) (fun parent name ->
                    match parent.InspectEntry name with
                    | None -> append backing logical None 0L DateTime.MinValue ""
                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                        read backing parent name logical entry.Identity
                    | Some _ ->
                        Error(OutputError.Unavailable "A writable file is not a regular file."))
            | OutputPurpose.ToolFolder -> walk backing root [] 0

        let rec collect =
            function
            | [] -> Ok()
            | backing :: rest ->
                match observeBacking backing with
                | Error error -> Error error
                | Ok() -> collect rest

        match collect backings with
        | Error error -> Error error
        | Ok() ->
            progress
                { Files = observations.Count
                  Bytes = bytes }

            Ok(
                observations
                |> Seq.sortBy (fun value ->
                    value.File.LocationId, LogicalPath.components value.File.Path)
                |> Seq.toList,
                encoded
            )

    let current (observation: OutputObservation) (token: CancellationToken) =
        use root =
            HeldDirectory.Open(observation.Backing.Root, observation.Backing.RootIdentity)

        withParent root (path observation.Backing observation.File.Path) (fun parent name ->
            match parent.InspectEntry name, observation.File.Identity with
            | None, None -> true
            | Some entry, Some expected when
                entry.Identity = expected && entry.Kind = EntryKind.RegularFile
                ->
                let stream, _ = parent.Read(name, Some expected)
                use stream = stream

                stream.Length = observation.File.Length
                && SourceFiles.digestChecked token.ThrowIfCancellationRequested stream = observation.File.Sha256
            | _ -> false)

    let remove (observation: OutputObservation) token =
        use root =
            HeldDirectory.Open(observation.Backing.Root, observation.Backing.RootIdentity)

        withParent root (path observation.Backing observation.File.Path) (fun parent name ->
            match parent.InspectEntry name with
            | None -> true
            | Some _ when current observation token ->
                match observation.File.Identity with
                | None -> false
                | Some identity ->
                    parent.RemoveFile(name, identity)
                    true
            | Some _ -> false)
