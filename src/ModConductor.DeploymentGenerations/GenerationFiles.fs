namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Diagnostics
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationFiles =
    let logical parts =
        LogicalPath.create parts
        |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.InvalidPlan))

    let checkProcesses (processes: ProcessIdentity list) =
        for expected in processes do
            let running =
                try
                    use runningProcess = Process.GetProcessById expected.Id

                    not runningProcess.HasExited
                    && runningProcess.StartTime.ToUniversalTime() = expected.StartedAt
                    && runningProcess.MainModule.FileName = expected.Executable
                with :? ArgumentException ->
                    false

            if running then
                raise (
                    RecoveryException(
                        RecoveryError.Unavailable "The declared game process is running."
                    )
                )

    let length =
        function
        | SourcePin.Mod(_, _, entry) -> entry.Payload.Length
        | SourcePin.Snapshot(_, _, entry) -> SnapshotFile.length entry

    let sha256 =
        function
        | SourcePin.Mod(_, _, entry) -> Some entry.Payload.Sha256
        | SourcePin.Snapshot(_, _, entry) -> SnapshotFile.sha256 entry

    let read (source: FileBacking) action =
        RecoveryFiles.withParent source.Directory source.Path (fun parent name ->
            let stream, _ = parent.Read(name, Some source.Identity)
            use stream = stream
            action stream)

    let verify pin (source: FileBacking) =
        let expectedLength = length pin

        RecoveryFiles.withParent source.Directory source.Path (fun parent name ->
            let metadata = parent.InspectFile(name, Some source.Identity)

            if metadata.Length <> expectedLength then
                RecoveryFiles.fail "A pinned source changed length.")

    let inspect (root: Location) path =
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        let rec walk (parent: HeldDirectory) =
            function
            | [ name ] -> parent.InspectEntry name
            | name :: rest ->
                match parent.InspectEntry name with
                | None -> None
                | Some entry when entry.Kind = EntryKind.Directory ->
                    use child = parent.Directory(name, Some entry.Identity)
                    walk child rest
                | Some _ -> RecoveryFiles.fail "A working path has an unexpected parent."
            | [] -> invalidOp "Empty working path."

        walk directory (LogicalPath.components path)

    let withCreatedParent (root: Location) path action =
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        let rec walk (parent: HeldDirectory) =
            function
            | [ name ] -> action parent name
            | name :: rest ->
                use child =
                    match parent.InspectEntry name with
                    | None -> parent.CreateDirectory name
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        parent.Directory(name, Some entry.Identity)
                    | Some _ -> RecoveryFiles.fail "Prepared storage contains an unexpected entry."

                walk child rest
            | [] -> invalidOp "Empty file path."

        walk directory (LogicalPath.components path)

    let private copyAtCheckpoint token pin source destination path readOnly afterChunk =
        let expectedLength = length pin

        read source (fun input ->
            withCreatedParent destination path (fun parent name ->
                let output, identity = parent.Create name
                use output = output
                let buffer = Array.zeroCreate<byte> 65536
                let mutable count = 0
                let mutable total = 0L
                let mutable more = true

                while more do
                    (token: CancellationToken).ThrowIfCancellationRequested()
                    count <- input.Read(buffer, 0, buffer.Length)

                    if count = 0 then
                        more <- false
                    else
                        total <- total + int64 count

                        if total > expectedLength then
                            RecoveryFiles.fail "A copied source changed length."

                        output.Write(buffer, 0, count)
                        afterChunk total

                output.Flush true

                if total <> expectedLength then
                    RecoveryFiles.fail "A copied source changed length."

                if readOnly then
                    if OperatingSystem.IsWindows() then
                        File.SetAttributes(output.SafeFileHandle, FileAttributes.ReadOnly)
                    else
                        File.SetUnixFileMode(output.SafeFileHandle, UnixFileMode.UserRead)

                identity))

    let copy token pin source destination path readOnly =
        copyAtCheckpoint token pin source destination path readOnly ignore

    let seedAtCheckpoint (token: CancellationToken) pin source destination path afterChunk =
        let parts = LogicalPath.components path

        let temporary =
            logical (
                List.take (parts.Length - 1) parts
                @ [ ".mc-seed-" + Guid.NewGuid().ToString("N") + ".tmp" ]
            )

        let identity =
            copyAtCheckpoint token pin source destination temporary false afterChunk

        token.ThrowIfCancellationRequested()

        RecoveryFiles.withParent destination temporary (fun parent name ->
            match parent.InspectEntry name with
            | Some entry when entry.Identity = identity && entry.Kind = EntryKind.RegularFile ->
                parent.MoveOriginal(name, entry, parent, List.last parts)
            | _ -> RecoveryFiles.fail "The prepared working seed changed before publication.")

        identity

    let seed token pin source destination path =
        seedAtCheckpoint token pin source destination path ignore

    let protect (root: Location) =
        let rec walk (location: Location) =
            use held = HeldDirectory.Open(location.Path, location.Identity)

            for name in held.Names do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    walk
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value location.Path, name))
                            |> Result.defaultWith (fun _ -> invalidOp "Invalid child.")
                          Identity = entry.Identity }
                | Some entry when entry.Kind = EntryKind.Link ->
                    GenerationStorage.protectLink held name entry
                | _ -> ()

            GenerationStorage.protectDirectory location.Path location.Identity

        walk root

    /// Removes a retired generation's derived link tree, never following payload links.
    let removeOwned (generation: Generation) =
        let path = HostPath.value generation.Directory.Path
        let name = generation.Id.ToString("N")
        let outer, nested =
            if Path.GetFileName path = name then Path.GetDirectoryName path, true
            else path, false
        let workspace = Path.GetDirectoryName outer

        if
            Path.GetFileName outer <> ".mc-generation-" + name
            || String.IsNullOrWhiteSpace workspace
        then
            raise (IOException "The derived generation folder has an invalid location.")

        let openCanonical path =
            let host = HostPath.create path |> Result.defaultWith invalidOp
            let selected =
                RootSelection.select host
                |> Result.defaultWith (fun _ -> raise (IOException "The derived generation parent is unavailable."))
            let identity =
                match (RootSelection.facts selected).File with
                | Known value -> value
                | Unknown detail -> raise (IOException detail)
            HeldDirectory.Open(host, identity)

        let rec remove (location: Location) =
            GenerationStorage.allowDirectoryChanges location.Path location.Identity
            use held = HeldDirectory.Open(location.Path, location.Identity)

            for name in held.Names |> Seq.toList do
                match held.InspectEntry name with
                | Some entry when entry.Kind = EntryKind.Directory ->
                    let child =
                        { Path =
                            HostPath.create (Path.Combine(HostPath.value location.Path, name))
                            |> Result.defaultWith invalidOp
                          Identity = entry.Identity }

                    remove child
                    held.RemoveDirectory(name, entry.Identity)
                | Some entry when entry.Kind = EntryKind.Link ->
                    GenerationStorage.allowLinkDeletion held name entry
                    held.RemoveLink(name, entry)
                | Some entry when entry.Kind = EntryKind.RegularFile ->
                    held.RemoveFile(name, entry.Identity)
                | Some _ -> raise (IOException "The derived generation has an unsupported entry.")
                | None -> raise (IOException "The derived generation changed.")

        if Directory.Exists outer && nested then
            let identity, empty =
                use parent = openCanonical outer

                match parent.InspectEntry name with
                | None -> ()
                | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = generation.Directory.Identity ->
                    remove generation.Directory
                    parent.RemoveDirectory(name, entry.Identity)
                | Some _ -> raise (IOException "The derived generation changed.")

                parent.Identity, (parent.Names |> Seq.isEmpty)

            if empty then
                let outerName = Path.GetFileName outer
                use workspaceRoot = openCanonical workspace
                workspaceRoot.RemoveDirectory(outerName, identity)
        elif Directory.Exists outer then
            use workspaceRoot = openCanonical workspace

            match workspaceRoot.InspectEntry(Path.GetFileName outer) with
            | Some entry when entry.Kind = EntryKind.Directory && entry.Identity = generation.Directory.Identity ->
                remove generation.Directory
                workspaceRoot.RemoveDirectory(Path.GetFileName outer, entry.Identity)
            | _ -> raise (IOException "The derived generation changed.")
