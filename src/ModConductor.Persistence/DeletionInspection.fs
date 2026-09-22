namespace ModConductor.Persistence

open System
open System.IO
open System.Threading.Tasks
open ModConductor.ModLibrary
open ModConductor.ModMaintenance
open ModConductor.ArchiveInstallation
open ModConductor.ArtifactLibrary
open ModConductor.Platform
open ModConductor.GeneratedOutputs

module internal DeletionInspection =
    let private refuse message = raise (InstallationException message)

    let read (database: StateDatabase) (access: LibraryAccess) workspace modId expected =
        task {
            let! snapshot = DeletionSnapshot.read database workspace modId expected

            let (row,
                 targets,
                 versions,
                 payloads,
                 temporary,
                 bundleSources,
                 artifacts,
                 generations,
                 profiles,
                 backups,
                 storedLibrary,
                 initialBlocked) =
                snapshot

            let! root = access.Root workspace

            let root =
                root |> Result.defaultWith (fun _ -> refuse "The workspace is unavailable.")

            let! effects, files, external, blocked =
                Task.Run(fun () ->
                    let effects = ResizeArray<DeletionEffect>()
                    let files = ResizeArray<DeletionFile>()
                    let external = ResizeArray<string>()
                    let mutable blocked = initialBlocked

                    let add kind host identity path expected label =
                        try
                            use directory = HeldDirectory.Open(host, identity)
                            let parts = LogicalPath.components path

                            let rec child (parent: HeldDirectory) parts =
                                match parts with
                                | [] -> invalidOp "A deletion file needs a name."
                                | [ name ] ->
                                    match parent.InspectEntry name with
                                    | None -> ()
                                    | Some entry when
                                        Some entry.Identity = expected
                                        && entry.Kind = (if
                                                             kind = DeletionFileKind.GenerationLink
                                                         then
                                                             EntryKind.Link
                                                         else
                                                             EntryKind.RegularFile)
                                        ->
                                        let bytes =
                                            if entry.Kind = EntryKind.Link then
                                                None
                                            else
                                                let stream, _ = parent.Read(name, expected) in
                                                use stream = stream in
                                                Some stream.Length

                                        effects.Add
                                            { Sequence = effects.Count
                                              Kind = kind
                                              Root = host
                                              RootIdentity = identity
                                              Path = path
                                              Identity = expected
                                              Label = label
                                              Bytes = bytes }

                                        if kind <> DeletionFileKind.GenerationLink then
                                            files.Add
                                                { Label = label
                                                  Kind = kind
                                                  Bytes = bytes
                                                  Shared = false }
                                    | Some _ ->
                                        blocked <- Some("A stored file was replaced: " + label)
                                | name :: tail ->
                                    use folder = parent.Directory(name, None) in child folder tail

                            child directory parts
                        with :? IOException as error ->
                            blocked <- Some error.Message

                    match storedLibrary with
                    | Some library when library.Identity.IsSome ->
                        let host =
                            HostPath.create (Path.Combine(HostPath.value root.Path, library.Name))
                            |> Result.defaultWith (string >> invalidOp)

                        for id, identity, bytes, label, shared in payloads do
                            if shared then
                                files.Add
                                    { Label = label
                                      Kind = DeletionFileKind.Payload
                                      Bytes = bytes
                                      Shared = true }
                            else
                                add
                                    DeletionFileKind.Payload
                                    host
                                    library.Identity.Value
                                    (LogicalPath.create [ LibraryFiles.payloadName id ]
                                     |> Result.defaultWith (string >> invalidOp))
                                    identity
                                    label

                        for file in temporary do
                            add
                                DeletionFileKind.Temporary
                                host
                                library.Identity.Value
                                (LogicalPath.create [ LibraryFiles.payloadName file.PayloadId ]
                                 |> Result.defaultWith (string >> invalidOp))
                                file.Identity
                                ("Temporary file: " + LogicalPath.display file.Destination)

                        for source, shared in bundleSources do
                            let label = "Temporary archive: " + LogicalPath.display source.Path

                            if shared then
                                files.Add
                                    { Label = label
                                      Kind = DeletionFileKind.Temporary
                                      Bytes = source.Length
                                      Shared = true }
                            else
                                add
                                    DeletionFileKind.Temporary
                                    host
                                    library.Identity.Value
                                    (LogicalPath.create [ BundleFiles.name source.Id ]
                                     |> Result.defaultWith (string >> invalidOp))
                                    source.Identity
                                    label

                        for artifact, shared in artifacts do
                            let value = artifact.Artifact

                            if shared then
                                files.Add
                                    { Label = value.OriginalName
                                      Kind = DeletionFileKind.Archive
                                      Bytes = value.Length
                                      Shared = true }
                            elif value.Storage = ArtifactStorage.Copy then
                                for name in
                                    [ ArtifactFiles.final value.Id; ArtifactFiles.stage value.Id ] do
                                    add
                                        DeletionFileKind.Archive
                                        host
                                        library.Identity.Value
                                        (LogicalPath.create [ name ]
                                         |> Result.defaultWith (string >> invalidOp))
                                        artifact.StoredIdentity
                                        value.OriginalName

                            if value.OriginalPath <> "" then
                                external.Add value.OriginalPath
                    | _ when
                        not payloads.IsEmpty || not temporary.IsEmpty || not bundleSources.IsEmpty
                        ->
                        blocked <- Some "The owned mod library is unavailable."
                    | _ -> ()

                    row.Entry.SourcePath
                    |> Option.iter (fun path ->
                        external.Add(
                            Path.Combine(HostPath.value root.Path, LogicalPath.display path)
                        ))

                    let privateNames =
                        payloads
                        |> List.choose (fun (id, _, _, _, shared) ->
                            if shared then None else Some(LibraryFiles.payloadName id))
                        |> Set.ofList

                    for _, generation in generations do
                        for file in generation.Files do
                            if
                                file.Backing
                                |> Option.exists (fun backing ->
                                    (storedLibrary
                                     |> Option.exists (fun library ->
                                         library.Identity = Some backing.Directory.Identity))
                                    && (match LogicalPath.components backing.Path with
                                        | [ name ] -> privateNames.Contains name
                                        | _ -> false))
                            then
                                add
                                    DeletionFileKind.GenerationLink
                                    generation.Directory.Path
                                    generation.Directory.Identity
                                    file.Path
                                    (Some file.Identity)
                                    (LogicalPath.display file.Target.Path)

                    if effects.Count > 100000 then
                        refuse "The deletion contains too many owned file effects."

                    effects |> Seq.toList,
                    files |> Seq.toList,
                    external |> Seq.distinct |> Seq.toList,
                    blocked)

            let deployments =
                generations
                |> List.map (fun (context, generation) ->
                    { DeletionDeployment.ContextId = context.Id
                      Id = generation.Id
                      Name =
                        generation.Provenance
                        |> Option.bind _.Profile
                        |> Option.map _.Name
                        |> Option.defaultValue "Saved deployment"
                      PreparedAt = generation.Provenance |> Option.map _.PreparedAt
                      Active = context.Active = Some generation.Id })

            return
                { View =
                    { WorkspaceId = workspace
                      ModId = modId
                      Revision = expected
                      Name = row.Entry.Metadata.Name
                      Versions = versions.Length
                      Backups = backups
                      Profiles = profiles
                      Deployments = deployments
                      Files = files
                      External = external
                      Blocked = blocked }
                  Targets = targets
                  Versions = versions
                  Payloads = payloads |> List.map (fun (id, _, _, _, _) -> id)
                  PrivatePayloads =
                    payloads
                    |> List.choose (fun (id, _, _, _, shared) -> if shared then None else Some id)
                  Artifacts =
                    artifacts
                    |> List.choose (fun (artifact, shared) ->
                        if shared then None else Some artifact.Artifact.Id)
                  Effects = effects
                  Generations =
                    generations |> List.map (fun (context, generation) -> context.Id, generation) }
        }
