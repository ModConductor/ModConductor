namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.Platform
open ModConductor.ProfileGameData
open ModConductor.GeneratedOutputs

type ProfileTransportWriter
    internal
    (
        database: StateDatabase,
        access: LibraryAccess,
        artifacts: IArtifactLibrary,
        inspection: Inspection,
        images: ModConductor.Workspaces.IProfileImages,
        directory: string
    ) =
    let codec = Path.Combine(AppContext.BaseDirectory, if OperatingSystem.IsWindows() then "xdelta3.exe" else "xdelta3")

    let copiedPayload root workspace (payload: Payload) destination =
        task {
            let! stored =
                database.Enqueue(fun () ->
                    match
                        LibraryRows.library database.Connection null workspace,
                        LibraryRows.payload database.Connection null payload.Id
                    with
                    | Some library, Some item when item.Payload = payload -> Ok(library, item)
                    | _ -> Error "A selected mod file is unavailable.")

            match stored with
            | Error problem -> return Error problem
            | Ok(library, item) ->
                use folder = LibraryFiles.openLibrary root library
                LibraryFiles.verify folder item
                let source, _ = folder.Read(LibraryFiles.payloadName payload.Id, Some item.Identity)
                use source = source
                use target = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None)
                do! source.CopyToAsync(target)
                do! target.FlushAsync()
                return Ok()
        }

    member _.Write(workspace, profile, destination: string, includeSaves: bool, token: CancellationToken) =
        task {
            let! root = access.Root workspace

            match root with
            | Error _ -> return Error "The workspace is unavailable."
            | Ok root ->
                let! observed =
                    database.Enqueue(fun () ->
                        use transaction = database.Connection.BeginTransaction(deferred = true)
                        let result = ProfileTransportSnapshot.read database.Connection transaction workspace profile
                        transaction.Commit()
                        result)

                match observed with
                | Error problem -> return Error problem
                | Ok observed ->
                    let temporary = Path.Combine(directory, "profile-transport", Guid.NewGuid().ToString("N"))
                    Directory.CreateDirectory temporary |> ignore

                    try
                        let members = Collections.Generic.Dictionary<string, string>()
                        let mutable next = 0

                        let memberFile () =
                            let name = "content/" + next.ToString("D8")
                            next <- next + 1
                            let path = Path.Combine(temporary, (next - 1).ToString("D8"))
                            members.Add(name, path)
                            name, path

                        let copyPrivateRoot (root: DataRoot option) =
                            let files = ResizeArray<PortableFile>()

                            let rec walk (folder: HeldDirectory) prefix depth =
                                if depth > 128 || files.Count > 100000 then
                                    raise (InvalidDataException "The private profile folder exceeds the file limit.")

                                let names = folder.Names |> Seq.toList |> List.sort

                                for item in names do
                                    token.ThrowIfCancellationRequested()

                                    match folder.InspectEntry item with
                                    | Some entry when entry.Kind = EntryKind.Directory ->
                                        use child = folder.Directory(item, Some entry.Identity)
                                        walk child (prefix @ [ item ]) (depth + 1)
                                    | Some entry when entry.Kind = EntryKind.RegularFile ->
                                        let source, _ = folder.Read(item, Some entry.Identity)
                                        use source = source
                                        let name, destination = memberFile ()
                                        use output = new FileStream(destination, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None)
                                        source.CopyTo output
                                        output.Flush(true)
                                        output.Position <- 0L
                                        let sha = Security.Cryptography.SHA256.HashData output |> Convert.ToHexStringLower
                                        files.Add
                                            { Path = prefix @ [ item ]
                                              Content = PortableContent.Payload(name, sha, output.Length) }
                                    | _ ->
                                        raise (InvalidDataException "The private profile folder contains an unsupported entry.")

                            match root with
                            | Some root ->
                                use folder = HeldDirectory.Open(root.Path, root.Identity)
                                walk folder [] 0
                            | None -> ()

                            files |> Seq.toList

                        let portableMods = ResizeArray<PortableMod>()

                        for modEntry in
                            observed.Mods
                            |> List.filter (fun value ->
                                value.Entry.Kind <> ModKind.Separator
                                && value.Selection.Enabled = Some true)
                            |> List.sortBy _.Selection.Priority do
                            let! portableMod =
                                task {
                                    token.ThrowIfCancellationRequested()

                                    let! baseMap =
                                        match modEntry.Base with
                                        | Some candidate ->
                                            ProfileTransportBases.reconstruct inspection artifacts workspace candidate token
                                        | None -> Task.FromResult None

                                    let baseFiles =
                                        if baseMap.IsSome then
                                            modEntry.Base.Value.Files
                                            |> List.map (fun value -> LogicalPath.components value.Path, value)
                                            |> Map.ofList
                                        else
                                            Map.empty

                                    let current =
                                        modEntry.Version
                                        |> Option.map _.Entries
                                        |> Option.defaultValue []
                                        |> List.sortBy (fun value -> LogicalPath.components value.Path)

                                    let files = ResizeArray<PortableFile>()

                                    for file in current do
                                        token.ThrowIfCancellationRequested()
                                        let path = LogicalPath.components file.Path

                                        match baseFiles |> Map.tryFind path with
                                        | Some original when original.Payload.Sha256 = file.Payload.Sha256 && original.Payload.Length = file.Payload.Length -> ()
                                        | previous ->
                                            let name, output = memberFile ()
                                            let! copied = copiedPayload root workspace file.Payload output

                                            match copied with
                                            | Error problem -> raise (InvalidDataException problem)
                                            | Ok() -> ()

                                            match previous with
                                            | Some original ->
                                                let source = Path.Combine(temporary, Guid.NewGuid().ToString("N") + ".base")
                                                let! copied = copiedPayload root workspace original.Payload source

                                                match copied with
                                                | Error problem -> raise (InvalidDataException problem)
                                                | Ok() -> ()

                                                let patch = output + ".patch"
                                                do!
                                                    ProfileDelta.encode codec source original.Payload.Sha256 output file.Payload.Sha256 file.Payload.Length patch token

                                                File.Delete source
                                                File.Delete output
                                                members[name] <- patch
                                                files.Add
                                                    { Path = path
                                                      Content = PortableContent.Patch(name, original.Payload.Sha256, file.Payload.Sha256, file.Payload.Length) }
                                            | None ->
                                                files.Add
                                                    { Path = path
                                                      Content = PortableContent.Payload(name, file.Payload.Sha256, file.Payload.Length) }

                                    let currentPaths = current |> List.map (fun value -> LogicalPath.components value.Path) |> Set.ofList

                                    let deleted =
                                        baseFiles
                                        |> Map.keys
                                        |> Seq.filter (fun path -> not (Set.contains path currentPaths))
                                        |> Seq.toList

                                    let metadata = modEntry.Entry.Metadata

                                    return
                                        { Kind =
                                            match modEntry.Entry.Kind with
                                            | ModKind.Regular -> "regular"
                                            | ModKind.GeneratedOutput when modEntry.Entry.Id = FnisRunRows.outputId profile -> "fnis-output"
                                            | ModKind.GeneratedOutput -> "generated-output"
                                            | _ -> raise (InvalidDataException "The profile contains an unsupported selected mod.")
                                          Name = metadata.Name
                                          Version = metadata.Version
                                          Notes = metadata.Notes
                                          Comment = metadata.Comment
                                          Categories = metadata.Categories |> List.map _.Label |> List.sort
                                          Source = modEntry.Nexus
                                          Base = baseMap
                                          Priority = portableMods.Count
                                          Enabled = modEntry.Selection.Enabled
                                          Files = files |> Seq.toList
                                          Deleted = deleted
                                          Hidden = modEntry.Hidden |> List.sort }
                                }

                            portableMods.Add portableMod

                        let! outputBackings =
                            database.Enqueue(fun () ->
                                use transaction = database.Connection.BeginTransaction(deferred = true)
                                let result =
                                    OutputRows.scope
                                        database.Connection
                                        transaction
                                        database.OwnerId
                                        root
                                        profile
                                        None

                                transaction.Commit()
                                result)

                        let backings =
                            match outputBackings with
                            | Ok(_, backings) ->
                                backings
                                |> List.filter (fun backing -> backing.Location.State = OutputLocationState.Ready)
                                |> List.sortBy (fun backing -> backing.Location.Name, backing.Location.Id)
                            | Error _ -> raise (InvalidDataException "The generated output locations are unavailable.")

                        let observedOutputs =
                            OutputFiles.observe backings Map.empty None ignore token
                            |> Result.map fst
                            |> Result.defaultWith (fun _ ->
                                raise (InvalidDataException "A generated output cannot be exported."))

                        for backing in backings do
                            let files =
                                observedOutputs
                                |> List.filter (fun output ->
                                    output.File.LocationId = backing.Location.Id
                                    && output.File.Identity.IsSome)

                            if not files.IsEmpty then
                                let portableFiles = ResizeArray<PortableFile>()
                                use sourceRoot = HeldDirectory.Open(backing.Root, backing.RootIdentity)

                                for output in files do
                                    let input, _ =
                                        SourceFiles.read
                                            sourceRoot
                                            (OutputFiles.path backing output.File.Path)
                                            output.File.Identity

                                    use input = input
                                    let name, target = memberFile ()
                                    use destination = new FileStream(target, FileMode.CreateNew, FileAccess.ReadWrite, FileShare.None)
                                    input.CopyTo destination
                                    destination.Flush(true)
                                    destination.Position <- 0L
                                    let sha = Security.Cryptography.SHA256.HashData destination |> Convert.ToHexStringLower

                                    if sha <> output.File.Sha256 || destination.Length <> output.File.Length then
                                        raise (InvalidDataException "A generated output changed during export.")

                                    portableFiles.Add
                                        { Path = LogicalPath.components output.File.Path
                                          Content = PortableContent.Payload(name, sha, destination.Length) }

                                portableMods.Add
                                    { Kind = "generated-output"
                                      Name = backing.Location.Name
                                      Version = ""
                                      Notes = ""
                                      Comment = ""
                                      Categories = []
                                      Source = None
                                      Base = None
                                      Priority = portableMods.Count
                                      Enabled = Some true
                                      Files = portableFiles |> Seq.toList
                                      Deleted = []
                                      Hidden = [] }

                        let! image = images.Read(workspace, profile)

                        let settings = copyPrivateRoot observed.Settings
                        let saves = if includeSaves then copyPrivateRoot observed.Saves else []

                        let artwork =
                            match image with
                            | Ok(Some source) when File.Exists source ->
                                let name, target = memberFile ()
                                File.Copy(source, target)
                                use stream = File.OpenRead target
                                let sha = Security.Cryptography.SHA256.HashData stream |> Convert.ToHexStringLower
                                Some { Path = [ "image" ]; Content = PortableContent.Payload(name, sha, stream.Length) }
                            | _ -> None

                        let portable =
                            { Name = observed.Name
                              Game = observed.Game
                              Mods = portableMods |> Seq.toList
                              PluginOrder = observed.PluginOrder
                              SettingsEnabled = observed.SettingsEnabled
                              SavesEnabled = observed.SavesEnabled
                              Settings = settings
                              Saves = saves
                              Artwork = artwork }

                        let! unchanged =
                            database.Enqueue(fun () ->
                                use transaction = database.Connection.BeginTransaction(deferred = true)
                                let latest = ProfileTransportSnapshot.read database.Connection transaction workspace profile
                                transaction.Commit()
                                latest = Ok observed)

                        if not unchanged then
                            return Error "The profile changed during export. Try again."
                        else
                            ProfileTransportZip.write destination portable (members |> Seq.map (fun pair -> pair.Key, pair.Value) |> Map.ofSeq)
                            return Ok()
                    finally
                        Directory.Delete(temporary, true)
        }
