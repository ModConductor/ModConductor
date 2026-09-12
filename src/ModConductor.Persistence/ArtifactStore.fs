namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Platform

open System.Collections.Generic

type internal ArtifactStore(database: StateDatabase, access: LibraryAccess) =
    let operations = ArtifactAccess(database, access)
    let files = ArtifactCapture(operations)
    let checkedWorkspaces = HashSet<Guid>()
    let checkedArtifacts = HashSet<Guid>()
    let connection = database.Connection
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse error = raise (ArtifactException error)
    let run action = operations.Run action
    let read workspace id = operations.Read(workspace, id)
    let finish row phase problem = operations.Finish(row, phase, problem)
    let library workspace = operations.Library workspace
    let withClaim reference action = operations.Claim(reference, action)

    let find transaction workspace id =
        ArtifactRows.find connection transaction workspace id
        |> Option.defaultWith (fun () -> refuse ArtifactError.NotFound)

    member _.AddAtCheckpoint(request, token, checkpoint) = files.Add(request, token, checkpoint)

    interface IArtifactSource with
        member _.ReadVerified(reference, token, consume) =
            task {
                let! outcome =
                    run (fun () ->
                        withClaim reference (fun row ->
                            if row.Phase <> 2 then
                                refuse ArtifactError.Unavailable

                            let inspect (file: FileStream) =
                                use file = file

                                ArtifactFiles.verify
                                    token
                                    row.Artifact.Length
                                    row.Artifact.Sha256
                                    file

                                file.Position <- 0L
                                // Consumer errors belong to its operation, not file admission.
                                try
                                    Choice1Of2(consume (row.Artifact, file :> Stream))
                                with error ->
                                    Choice2Of2 error

                            if row.Artifact.Storage = ArtifactStorage.Reference then
                                let file, _ =
                                    ArtifactFiles.openExternal
                                        row.Artifact.Path
                                        row.SourceIdentity

                                inspect file
                            else
                                use directory = library row.Artifact.WorkspaceId

                                let file, _ =
                                    directory.Read(
                                        ArtifactFiles.final row.Artifact.Id,
                                        row.StoredIdentity
                                    )

                                inspect file))

                match outcome with
                | Ok(Choice1Of2 value) -> return Ok value
                | Ok(Choice2Of2 error) -> return raise error
                | Error error -> return Error error
            }

    interface IArtifactLibrary with
        member _.Add(request, token) = files.Add(request, token, ignore)

        member _.LinkOptions(workspace, after) =
            run (fun () ->
                db (fun () ->
                    use query =
                        Sqlite.command
                            connection
                            null
                            "SELECT m.id,m.current_version,m.name,m.version_text FROM mods m JOIN mod_versions v ON v.id=m.current_version WHERE m.workspace_id=$workspace AND v.phase=3 AND m.id>$after ORDER BY m.id LIMIT 65"
                            [ "$workspace", box (string workspace)
                              "$after", box (after |> Option.map string |> Option.defaultValue "") ]

                    use reader = query.ExecuteReader()

                    let links =
                        [ while reader.Read() do
                              yield
                                  { ModId = Guid.Parse(reader.GetString 0)
                                    VersionId = Guid.Parse(reader.GetString 1)
                                    ModName = reader.GetString 2
                                    VersionLabel = reader.GetString 3
                                    Installed = false } ]

                    let entries = links |> List.truncate 64

                    { ArtifactLinkPage.Entries = entries
                      Next =
                        if links.Length > 64 then
                            entries |> List.tryLast |> Option.map (fun l -> l.ModId)
                        else
                            None }))

        member _.Read(workspace, id) =
            run (fun () ->
                let row = read workspace id

                if
                    not row.Busy
                    && not (lock checkedArtifacts (fun () -> checkedArtifacts.Contains id))
                then
                    try
                        withClaim
                            { WorkspaceId = workspace
                              Id = id
                              Revision = row.Artifact.Revision }
                            (fun row -> files.Reconcile(CancellationToken.None, row) |> ignore)

                        lock checkedArtifacts (fun () -> checkedArtifacts.Add id |> ignore)
                    with :? ArtifactException as error when
                        error.Error = ArtifactError.Busy || error.Error = ArtifactError.Stale ->
                        ()

                (read workspace id).Artifact)

        member _.Retry(reference, token) =
            run (fun () ->
                withClaim reference (fun row ->
                    if row.Phase <> 0 || row.Artifact.Download.IsSome then
                        refuse ArtifactError.Conflict

                    files.Capture(token, row))

                (read reference.WorkspaceId reference.Id).Artifact)

        member _.Locate(reference, path, token) =
            run (fun () ->
                if HostPath.create path |> Result.isError then
                    refuse ArtifactError.Conflict

                withClaim reference (fun row ->
                    if row.Artifact.Storage <> ArtifactStorage.Reference then
                        refuse ArtifactError.Conflict

                    let file, identity = ArtifactFiles.openExternal path None
                    use file = file
                    ArtifactFiles.verify token row.Artifact.Length row.Artifact.Sha256 file

                    finish
                        { row with
                            SourceIdentity = Some identity
                            Artifact = { row.Artifact with Path = path } }
                        2
                        None
                    |> ignore)

                (read reference.WorkspaceId reference.Id).Artifact)

        member _.List(workspace, after, refresh, token) =
            run (fun () ->
                let check =
                    lock checkedWorkspaces (fun () ->
                        refresh || not (checkedWorkspaces.Contains workspace))

                if check then
                    let mutable cursor = None
                    let mutable more = true

                    while more do
                        token.ThrowIfCancellationRequested()

                        let ids =
                            db (fun () -> ArtifactRows.ids connection workspace cursor)
                            |> List.truncate 64

                        for id in ids do
                            let row = read workspace id

                            if not row.Busy then
                                try
                                    withClaim
                                        { WorkspaceId = workspace
                                          Id = id
                                          Revision = row.Artifact.Revision }
                                        (fun row -> files.Reconcile(token, row) |> ignore)

                                    lock checkedArtifacts (fun () ->
                                        checkedArtifacts.Add id |> ignore)
                                with :? ArtifactException as error when
                                    error.Error = ArtifactError.Busy
                                    || error.Error = ArtifactError.Stale ->
                                    ()

                        cursor <- List.tryLast ids
                        more <- ids.Length = 64

                    lock checkedWorkspaces (fun () -> checkedWorkspaces.Add workspace |> ignore)

                let ids = db (fun () -> ArtifactRows.ids connection workspace after)

                let entries =
                    ids |> List.truncate 64 |> List.map (fun id -> (read workspace id).Artifact)

                { Entries = entries
                  Next =
                    if ids.Length > 64 then
                        entries |> List.tryLast |> Option.map (fun a -> a.Id)
                    else
                        None })

        member _.Link(reference, modId, versionId, remove) =
            run (fun () ->
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)
                    let row = find transaction reference.WorkspaceId reference.Id

                    if row.Busy then
                        refuse ArtifactError.Busy

                    if row.Artifact.Revision <> reference.Revision then
                        refuse ArtifactError.Stale

                    if remove then
                        if
                            row.Artifact.Links
                            |> List.exists (fun link ->
                                link.ModId = modId
                                && link.VersionId = versionId
                                && link.Installed)
                        then
                            refuse ArtifactError.InvalidLink

                        Sqlite.execute
                            connection
                            transaction
                            "DELETE FROM artifact_links WHERE artifact_id=$artifact AND mod_id=$mod AND version_id=$version"
                            [ "$artifact", box (string reference.Id)
                              "$mod", box (string modId)
                              "$version", box (string versionId) ]
                    else
                        use query =
                            Sqlite.command
                                connection
                                transaction
                                "SELECT m.name,m.version_text FROM mods m JOIN mod_versions v ON v.mod_id=m.id WHERE m.id=$mod AND m.workspace_id=$workspace AND v.id=$version AND m.current_version=v.id AND v.phase=3"
                                [ "$mod", box (string modId)
                                  "$workspace", box (string reference.WorkspaceId)
                                  "$version", box (string versionId) ]

                        use reader = query.ExecuteReader()

                        if not (reader.Read()) then
                            refuse ArtifactError.InvalidLink

                        let name, label = reader.GetString 0, reader.GetString 1
                        reader.Close()

                        Sqlite.execute
                            connection
                            transaction
                            "INSERT OR IGNORE INTO artifact_links(artifact_id,mod_id,version_id,mod_name,version_label) VALUES($artifact,$mod,$version,$name,$label)"
                            [ "$artifact", box (string reference.Id)
                              "$mod", box (string modId)
                              "$version", box (string versionId)
                              "$name", box name
                              "$label", box label ]

                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE artifacts SET revision=revision+1 WHERE id=$id"
                        [ "$id", box (string reference.Id) ]

                    transaction.Commit())

                (read reference.WorkspaceId reference.Id).Artifact)

        member _.DeleteCopy(reference) =
            run (fun () ->
                withClaim reference (fun row ->
                    if
                        row.Artifact.Storage <> ArtifactStorage.Copy
                        || DownloadRows.running row.Artifact.Download
                    then
                        refuse ArtifactError.Conflict

                    let row = finish row 4 None

                    let hasLibrary =
                        db (fun () ->
                            LibraryRows.library connection null row.Artifact.WorkspaceId
                            |> Option.isSome)

                    if hasLibrary || row.StoredIdentity.IsSome then
                        use directory = library row.Artifact.WorkspaceId

                        ArtifactFiles.remove
                            directory
                            (ArtifactFiles.stage reference.Id)
                            row.StoredIdentity

                        ArtifactFiles.remove
                            directory
                            (ArtifactFiles.final reference.Id)
                            row.StoredIdentity

                    finish { row with StoredIdentity = None } 3 None |> ignore)

                (read reference.WorkspaceId reference.Id).Artifact)

        member _.Remove(reference) =
            run (fun () ->
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)
                    let row = find transaction reference.WorkspaceId reference.Id

                    if row.Busy then
                        refuse ArtifactError.Busy

                    if row.Artifact.Revision <> reference.Revision then
                        refuse ArtifactError.Stale

                    if
                        Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM archive_installations WHERE artifact_id=$id AND state IN (0,1)"
                            [ "$id", box (string reference.Id) ]
                        <> 0L
                    then
                        refuse ArtifactError.Conflict

                    if not row.Artifact.Links.IsEmpty then
                        refuse ArtifactError.Linked

                    if
                        row.Artifact.Storage = ArtifactStorage.Copy
                        && (row.Phase <> 3 || row.StoredIdentity.IsSome)
                    then
                        refuse ArtifactError.Conflict

                    Sqlite.execute
                        connection
                        transaction
                        "DELETE FROM artifacts WHERE id=$id"
                        [ "$id", box (string reference.Id) ]

                    transaction.Commit()))
