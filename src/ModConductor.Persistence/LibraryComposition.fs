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

module internal LibraryComposition =
    let targets policy (previous: ManifestEntry list) (files: CompositionFile list) =
        let prior = Dictionary<string, ManifestEntry>(TargetPolicy.comparer policy)
        let mutable failure = None

        for entry in previous do
            if failure.IsNone && not (prior.TryAdd(TargetPolicy.key policy entry.Path, entry)) then
                failure <- Some LibraryError.InvalidSource

        let selected = HashSet<string>(TargetPolicy.comparer policy)

        let replacements = ResizeArray<_>()

        for file in files do
            if failure.IsNone then
                let key = TargetPolicy.key policy file.Target

                if
                    not (TargetPolicy.problems policy file.Target).IsEmpty || not (selected.Add key)
                then
                    failure <- Some LibraryError.InvalidSource
                else
                    let old =
                        match prior.TryGetValue key with
                        | true, entry -> Some entry
                        | _ -> None

                    replacements.Add(
                        (old |> Option.map _.Path |> Option.defaultValue file.Target),
                        file,
                        old
                    )

        match failure with
        | Some error -> Error error
        | None ->
            Ok(
                previous
                |> List.filter (fun file ->
                    not (selected.Contains(TargetPolicy.key policy file.Path))),
                List.ofSeq replacements
            )

    let private checkedFile (root: HeldDirectory) (file: SourceFile) check =
        let stream, _ = SourceFiles.read root file.Path (Some file.Identity)
        use stream = stream

        if stream.Length <> file.Length then
            Error LibraryError.SourceChanged
        else
            SourceFiles.digestCheckedResult check stream
            |> Result.bind (fun digest ->
                if digest <> file.Sha256 then
                    Error LibraryError.SourceChanged
                else
                    Ok
                        { file with
                            Modified = File.GetLastWriteTimeUtc stream.SafeFileHandle })

    let private each (entries: 'T list) action =
        use items = entries.GetEnumerator()
        let mutable outcome = Ok()

        while Result.isOk outcome && items.MoveNext() do
            outcome <- action items.Current

        outcome

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
                return Error LibraryError.LimitExceeded
            else
                match targets input.Policy previous input.Files with
                | Error error -> return Error error
                | Ok(retainedFiles, selected) ->
                    let inlineKeys = HashSet<string>(TargetPolicy.comparer input.Policy)
                    let fileKeys = HashSet<string>(TargetPolicy.comparer input.Policy)

                    for file in input.Files do
                        fileKeys.Add(TargetPolicy.key input.Policy file.Target) |> ignore

                    let inlineFiles = ResizeArray<_>()
                    let mutable invalid = false

                    for item in input.Bytes do
                        if not invalid then
                            let key = TargetPolicy.key input.Policy item.Target

                            if
                                not (TargetPolicy.problems input.Policy item.Target).IsEmpty
                                || fileKeys.Contains key
                                || not (inlineKeys.Add key)
                            then
                                invalid <- true
                            else
                                let prior =
                                    previous
                                    |> List.tryFind (fun entry ->
                                        (TargetPolicy.comparer input.Policy)
                                            .Equals(TargetPolicy.key input.Policy entry.Path, key))

                                inlineFiles.Add(
                                    (prior |> Option.map _.Path |> Option.defaultValue item.Target),
                                    item,
                                    prior
                                )

                    if invalid then
                        return Error LibraryError.InvalidSource
                    else
                        let retained =
                            retainedFiles
                            |> List.filter (fun entry ->
                                not (inlineKeys.Contains(TargetPolicy.key input.Policy entry.Path)))

                        if retained.Length + selected.Length + inlineFiles.Count > 100000 then
                            return Error LibraryError.LimitExceeded
                        else
                            let! captured =
                                Task.Run(fun () ->
                                    use destination = LibraryFiles.openLibrary workspace library

                                    let execute action = (db action).GetAwaiter().GetResult()

                                    let manifest path payload =
                                        execute (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "INSERT INTO mod_manifest VALUES($version,$path,$payload)"
                                                [ "$version", box (string version)
                                                  "$path", box (LibraryEncoding.path path)
                                                  "$payload", box (string payload.Id) ])

                                    let insert payload =
                                        execute (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "INSERT INTO mod_payloads(id,workspace_id,publication_id) VALUES($id,$workspace,$version)"
                                                [ "$id", box (string payload.Id)
                                                  "$workspace", box (string workspace.Id)
                                                  "$version", box (string version) ])

                                    let update payload identity =
                                        execute (fun () ->
                                            Sqlite.execute
                                                connection
                                                null
                                                "UPDATE mod_payloads SET identity=$identity,length=$length,digest=$digest WHERE id=$id"
                                                [ "$identity",
                                                  box (LibraryEncoding.identity identity)
                                                  "$length", box payload.Length
                                                  "$digest", box payload.Sha256
                                                  "$id", box (string payload.Id) ])

                                    let retainedEntry entry =
                                        check ()

                                        match
                                            execute (fun () ->
                                                LibraryRows.payload
                                                    connection
                                                    null
                                                    entry.Payload.Id)
                                        with
                                        | None -> Error LibraryError.SourceChanged
                                        | Some stored ->
                                            LibraryFiles.verify destination stored
                                            manifest entry.Path entry.Payload
                                            Ok()

                                    let selectedEntry (target, item, prior) =
                                        check ()

                                        use source =
                                            HeldDirectory.Open(item.Root, item.RootIdentity)

                                        checkedFile source item.File check
                                        |> Result.bind (fun file ->
                                            let reused =
                                                prior
                                                |> Option.filter (fun entry ->
                                                    entry.Payload.Length = file.Length
                                                    && entry.Payload.Sha256 = file.Sha256)

                                            let payload =
                                                match reused with
                                                | Some entry ->
                                                    let stored =
                                                        execute (fun () ->
                                                            LibraryRows.payload
                                                                connection
                                                                null
                                                                entry.Payload.Id
                                                            |> Option.get)

                                                    LibraryFiles.verify destination stored
                                                    Ok entry.Payload
                                                | None ->
                                                    let payload =
                                                        { Id = Guid.NewGuid()
                                                          Length = file.Length
                                                          Sha256 = file.Sha256 }

                                                    insert payload

                                                    let stream, identity =
                                                        destination.Create(
                                                            LibraryFiles.payloadName payload.Id
                                                        )

                                                    use stream = stream

                                                    SourceFiles.copy source file stream check
                                                    |> Result.map (fun () ->
                                                        afterEffect ()
                                                        update payload identity
                                                        payload)

                                            payload
                                            |> Result.map (fun payload -> manifest target payload))

                                    let inlineEntry (target, item, prior) =
                                        check ()

                                        let digest =
                                            Convert.ToHexStringLower(SHA256.HashData item.Content)

                                        if digest <> item.Sha256 then
                                            Error LibraryError.SourceChanged
                                        else
                                            beforeInlineEffect ()
                                            check ()

                                            let priorValid =
                                                match prior with
                                                | None -> Ok()
                                                | Some entry ->
                                                    match
                                                        execute (fun () ->
                                                            LibraryRows.payload
                                                                connection
                                                                null
                                                                entry.Payload.Id)
                                                    with
                                                    | None -> Error LibraryError.SourceChanged
                                                    | Some stored when
                                                        stored.Payload <> entry.Payload
                                                        ->
                                                        Error LibraryError.SourceChanged
                                                    | Some stored ->
                                                        try
                                                            LibraryFiles.verify destination stored
                                                            Ok()
                                                        with :? IOException ->
                                                            Error LibraryError.SourceChanged

                                            priorValid
                                            |> Result.map (fun () ->
                                                let reused =
                                                    prior
                                                    |> Option.filter (fun entry ->
                                                        entry.Payload.Length = int64
                                                            item.Content.Length
                                                        && entry.Payload.Sha256 = item.Sha256)

                                                let payload =
                                                    match reused with
                                                    | Some entry -> entry.Payload
                                                    | None ->
                                                        let payload =
                                                            { Id = Guid.NewGuid()
                                                              Length = int64 item.Content.Length
                                                              Sha256 = item.Sha256 }

                                                        insert payload

                                                        let stream, identity =
                                                            destination.Create(
                                                                LibraryFiles.payloadName
                                                                    payload.Id
                                                            )

                                                        use stream = stream
                                                        stream.Write item.Content
                                                        stream.Flush true
                                                        afterEffect ()
                                                        update payload identity
                                                        payload

                                                manifest target payload)

                                    let verifySource item =
                                        use source =
                                            HeldDirectory.Open(item.Root, item.RootIdentity)

                                        checkedFile source item.File check |> Result.map ignore

                                    each retained retainedEntry
                                    |> Result.bind (fun () -> each selected selectedEntry)
                                    |> Result.bind (fun () ->
                                        each (List.ofSeq inlineFiles) inlineEntry)
                                    |> Result.bind (fun () -> each input.Files verifySource))

                            match captured with
                            | Error error -> return Error error
                            | Ok() ->
                                do!
                                    db (fun () ->
                                        Sqlite.execute
                                            connection
                                            null
                                            "UPDATE mod_versions SET phase=2 WHERE id=$id AND owner=$owner AND phase=1"
                                            [ "$id", box (string version)
                                              "$owner", box database.OwnerId ])

                                afterObservation ()
                                return Ok()
        }
