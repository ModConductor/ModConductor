namespace ModConductor.Persistence

open System
open System.IO
open System.Collections.Generic
open System.Security.Cryptography
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.ModLibrary

type internal CompositionFile =
    { Target: LogicalPath
      Root: HostPath
      RootIdentity: FileIdentity
      File: SourceFile }

type internal CompositionBytes =
    { Target: LogicalPath
      Content: byte array
      Sha256: string }

type internal LibraryCompositionInput =
    { ActionId: Guid
      SourceVersion: Guid option
      VersionLabel: string
      Policy: TargetPolicy
      Files: CompositionFile list
      Bytes: CompositionBytes list }

exception internal ReplacedPayloadChangedException

module internal LibraryComposition =
    let targets policy (previous: ManifestEntry list) (files: CompositionFile list) =
        let prior = Dictionary<string, ManifestEntry>(TargetPolicy.comparer policy)

        for entry in previous do
            if not (prior.TryAdd(TargetPolicy.key policy entry.Path, entry)) then
                raise (SourceOverlapException())

        let selected = HashSet<string>(TargetPolicy.comparer policy)

        let replacements =
            files
            |> List.map (fun file ->
                if not (TargetPolicy.problems policy file.Target).IsEmpty then
                    raise (SourceOverlapException())

                let key = TargetPolicy.key policy file.Target

                if not (selected.Add key) then
                    raise (SourceOverlapException())

                let old =
                    match prior.TryGetValue key with
                    | true, entry -> Some entry
                    | _ -> None

                old |> Option.map _.Path |> Option.defaultValue file.Target, file, old)

        previous
        |> List.filter (fun file -> not (selected.Contains(TargetPolicy.key policy file.Path))),
        replacements

    let private checkedFile (root: HeldDirectory) (file: SourceFile) check =
        let stream, _ = SourceFiles.read root file.Path (Some file.Identity)
        use stream = stream

        if
            stream.Length <> file.Length
            || SourceFiles.digestChecked check stream <> file.Sha256
        then
            raise (SourceChangedException())

        { file with
            Modified = File.GetLastWriteTimeUtc stream.SafeFileHandle }

    let capture
        (database: StateDatabase)
        workspace
        library
        version
        input
        check
        afterEffect
        afterObservation
        beforeInlineEffect
        =
        task {
            let connection = database.Connection
            let db action = database.EnqueueInternal action

            let! previous =
                db (fun () ->
                    input.SourceVersion
                    |> Option.bind (fun id -> LibraryRows.version connection null id 0 100001)
                    |> Option.map _.Entries
                    |> Option.defaultValue [])

            if previous.Length > 100000 then
                raise (SourceLimitException())

            let retainedFiles, selected = targets input.Policy previous input.Files
            let inlineKeys = HashSet<string>(TargetPolicy.comparer input.Policy)
            let fileKeys = HashSet<string>(TargetPolicy.comparer input.Policy)

            for file in input.Files do
                fileKeys.Add(TargetPolicy.key input.Policy file.Target) |> ignore

            let inlineFiles =
                input.Bytes
                |> List.map (fun item ->
                    if
                        not (TargetPolicy.problems input.Policy item.Target).IsEmpty
                        || fileKeys.Contains(TargetPolicy.key input.Policy item.Target)
                        || not (inlineKeys.Add(TargetPolicy.key input.Policy item.Target))
                    then
                        raise (SourceOverlapException())

                    let prior =
                        previous
                        |> List.tryFind (fun entry ->
                            (TargetPolicy.comparer input.Policy)
                                .Equals(
                                    TargetPolicy.key input.Policy entry.Path,
                                    TargetPolicy.key input.Policy item.Target
                                ))

                    prior |> Option.map _.Path |> Option.defaultValue item.Target, item, prior)

            let retained =
                retainedFiles
                |> List.filter (fun entry ->
                    not (inlineKeys.Contains(TargetPolicy.key input.Policy entry.Path)))

            if retained.Length + selected.Length + inlineFiles.Length > 100000 then
                raise (SourceLimitException())

            do!
                Task.Run(fun () ->
                    use destination = LibraryFiles.openLibrary workspace library

                    for entry in retained do
                        check ()

                        let stored =
                            (db (fun () ->
                                LibraryRows.payload connection null entry.Payload.Id
                                |> Option.defaultWith (fun () -> raise (SourceChangedException()))))
                                .GetAwaiter()
                                .GetResult()

                        LibraryFiles.verify destination stored |> ignore

                        (db (fun () ->
                            Sqlite.execute
                                connection
                                null
                                "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                                [ "$version", box (string version)
                                  "$path", box (LibraryEncoding.path entry.Path)
                                  "$payload", box (string entry.Payload.Id) ]))
                            .GetAwaiter()
                            .GetResult()

                    for target, item, prior in selected do
                        check ()
                        use source = HeldDirectory.Open(item.Root, item.RootIdentity)
                        let file = checkedFile source item.File check

                        let reused =
                            prior
                            |> Option.filter (fun entry ->
                                entry.Payload.Length = file.Length
                                && entry.Payload.Sha256 = file.Sha256)

                        let payload =
                            match reused with
                            | Some entry ->
                                let stored =
                                    (db (fun () ->
                                        LibraryRows.payload connection null entry.Payload.Id
                                        |> Option.get))
                                        .GetAwaiter()
                                        .GetResult()

                                LibraryFiles.verify destination stored
                                entry.Payload
                            | None ->
                                let payload =
                                    { Id = Guid.NewGuid()
                                      Length = file.Length
                                      Sha256 = file.Sha256 }

                                (db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "INSERT INTO mod_payloads(id,workspace_id,publication_id) VALUES($id,$workspace,$version)"
                                        [ "$id", box (string payload.Id)
                                          "$workspace", box (string workspace.Id)
                                          "$version", box (string version) ]))
                                    .GetAwaiter()
                                    .GetResult()

                                let stream, identity =
                                    destination.Create(LibraryFiles.payloadName payload.Id)

                                use stream = stream
                                SourceFiles.copy source file stream check
                                afterEffect ()

                                (db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "UPDATE mod_payloads SET identity=$identity,length=$length,digest=$digest WHERE id=$id"
                                        [ "$identity", box (LibraryEncoding.identity identity)
                                          "$length", box payload.Length
                                          "$digest", box payload.Sha256
                                          "$id", box (string payload.Id) ]))
                                    .GetAwaiter()
                                    .GetResult()

                                payload

                        (db (fun () ->
                            Sqlite.execute
                                connection
                                null
                                "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                                [ "$version", box (string version)
                                  "$path", box (LibraryEncoding.path target)
                                  "$payload", box (string payload.Id) ]))
                            .GetAwaiter()
                            .GetResult()

                    for target, item, prior in inlineFiles do
                        check ()
                        let digest = Convert.ToHexStringLower(SHA256.HashData item.Content)

                        if digest <> item.Sha256 then
                            raise (SourceChangedException())

                        beforeInlineEffect ()
                        check ()

                        prior
                        |> Option.iter (fun entry ->
                            let stored =
                                (db (fun () ->
                                    LibraryRows.payload connection null entry.Payload.Id
                                    |> Option.defaultWith (fun () ->
                                        raise (SourceChangedException()))))
                                    .GetAwaiter()
                                    .GetResult()

                            if stored.Payload <> entry.Payload then
                                raise ReplacedPayloadChangedException

                            try
                                LibraryFiles.verify destination stored
                            with :? IOException ->
                                raise ReplacedPayloadChangedException)

                        let reused =
                            prior
                            |> Option.filter (fun entry ->
                                entry.Payload.Length = int64 item.Content.Length
                                && entry.Payload.Sha256 = item.Sha256)

                        let payload =
                            match reused with
                            | Some entry -> entry.Payload
                            | None ->
                                let payload =
                                    { Id = Guid.NewGuid()
                                      Length = int64 item.Content.Length
                                      Sha256 = item.Sha256 }

                                (db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "INSERT INTO mod_payloads(id,workspace_id,publication_id) VALUES($id,$workspace,$version)"
                                        [ "$id", box (string payload.Id)
                                          "$workspace", box (string workspace.Id)
                                          "$version", box (string version) ]))
                                    .GetAwaiter()
                                    .GetResult()

                                let stream, identity =
                                    destination.Create(LibraryFiles.payloadName payload.Id)

                                use stream = stream
                                stream.Write item.Content
                                stream.Flush true
                                afterEffect ()

                                (db (fun () ->
                                    Sqlite.execute
                                        connection
                                        null
                                        "UPDATE mod_payloads SET identity=$identity,length=$length,digest=$digest WHERE id=$id"
                                        [ "$identity", box (LibraryEncoding.identity identity)
                                          "$length", box payload.Length
                                          "$digest", box payload.Sha256
                                          "$id", box (string payload.Id) ]))
                                    .GetAwaiter()
                                    .GetResult()

                                payload

                        (db (fun () ->
                            Sqlite.execute
                                connection
                                null
                                "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                                [ "$version", box (string version)
                                  "$path", box (LibraryEncoding.path target)
                                  "$payload", box (string payload.Id) ]))
                            .GetAwaiter()
                            .GetResult()

                    for item in input.Files do
                        use source = HeldDirectory.Open(item.Root, item.RootIdentity)
                        checkedFile source item.File check |> ignore)

            do!
                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "UPDATE mod_versions SET phase=2 WHERE id=$id AND owner=$owner AND phase=1"
                        [ "$id", box (string version); "$owner", box database.OwnerId ])

            afterObservation ()
        }
