namespace ModConductor.Persistence

open System
open System.Collections.Generic
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Platform

type internal ArtifactStore(database: StateDatabase, access: LibraryAccess) =
    let operations = ArtifactAccess(database, access)
    let files = ArtifactCapture(operations)
    let checkedWorkspaces = HashSet<Guid>()
    let checkedArtifacts = HashSet<Guid>()
    let connection = database.Connection
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let run action = operations.Run action
    let read workspace id = operations.Read(workspace, id)
    let finish row phase problem = operations.Finish(row, phase, problem)
    let library workspace = operations.Library workspace
    let withClaim reference action = operations.Claim(reference, action)

    let find transaction workspace id =
        match ArtifactRows.find connection transaction workspace id with
        | Some row -> Ok row
        | None -> Error ArtifactError.NotFound

    let reconcileRow token row =
        if row.Busy then
            Ok()
        else
            let reference =
                { WorkspaceId = row.Artifact.WorkspaceId
                  Id = row.Artifact.Id
                  Revision = row.Artifact.Revision }

            match
                withClaim reference (fun held -> files.Reconcile(token, held) |> Result.map ignore)
            with
            | Ok() ->
                lock checkedArtifacts (fun () -> checkedArtifacts.Add row.Artifact.Id |> ignore)
                Ok()
            | Error ArtifactError.Busy
            | Error ArtifactError.Stale -> Ok()
            | Error error -> Error error

    let reconcilePage token workspace ids =
        ids
        |> List.fold
            (fun progress id ->
                progress
                |> Result.bind (fun () -> read workspace id |> Result.bind (reconcileRow token)))
            (Ok())

    let artifacts workspace ids =
        ids
        |> List.fold
            (fun progress id ->
                progress
                |> Result.bind (fun entries ->
                    read workspace id |> Result.map (fun row -> row.Artifact :: entries)))
            (Ok [])
        |> Result.map List.rev

    let checkedRow transaction (reference: ArtifactRef) =
        find transaction reference.WorkspaceId reference.Id
        |> Result.bind (fun row ->
            if row.Busy then
                Error ArtifactError.Busy
            elif row.Artifact.Revision <> reference.Revision then
                Error ArtifactError.Stale
            else
                Ok row)

    let changeLink transaction (reference: ArtifactRef) row modId versionId remove =
        let parameters =
            [ "$artifact", box (string reference.Id)
              "$mod", box (string modId)
              "$version", box (string versionId) ]

        if remove then
            let installed =
                row.Artifact.Links
                |> List.exists (fun link ->
                    link.ModId = modId && link.VersionId = versionId && link.Installed)

            if installed then
                Error ArtifactError.InvalidLink
            else
                Sqlite.execute
                    connection
                    transaction
                    "DELETE FROM artifact_links WHERE artifact_id=$artifact AND mod_id=$mod AND version_id=$version"
                    parameters

                Ok()
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
                Error ArtifactError.InvalidLink
            else
                let name, label = reader.GetString 0, reader.GetString 1
                reader.Close()

                Sqlite.execute
                    connection
                    transaction
                    "INSERT OR IGNORE INTO artifact_links(artifact_id,mod_id,version_id,mod_name,version_label) VALUES($artifact,$mod,$version,$name,$label)"
                    (parameters @ [ "$name", box name; "$label", box label ])

                Ok()

    let removeArtifact transaction (reference: ArtifactRef) row =
        let active =
            Sqlite.number
                connection
                transaction
                "SELECT (SELECT count(*) FROM archive_installations WHERE artifact_id=$id AND state IN (0,1)) + (SELECT count(*) FROM bundle_work WHERE artifact_id=$id)"
                [ "$id", box (string reference.Id) ]

        if active <> 0L then
            Error ArtifactError.Conflict
        elif not row.Artifact.Links.IsEmpty then
            Error ArtifactError.Linked
        elif
            row.Artifact.Storage = ArtifactStorage.Copy
            && (row.Phase <> 3 || row.StoredIdentity.IsSome)
        then
            Error ArtifactError.Conflict
        else
            Sqlite.execute
                connection
                transaction
                "DELETE FROM artifacts WHERE id=$id"
                [ "$id", box (string reference.Id) ]

            Ok()

    member _.AddAtCheckpoint(request, token, checkpoint) = files.Add(request, token, checkpoint)

    interface IArtifactSource with
        member _.ReadVerified(reference, token, consume) =
            task {
                let! outcome =
                    run (fun () ->
                        withClaim reference (fun row ->
                            if row.Phase <> 2 then
                                Error ArtifactError.Unavailable
                            else
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

                                    Ok(inspect file)
                                else
                                    library row.Artifact.WorkspaceId
                                    |> Result.map (fun directory ->
                                        use directory = directory

                                        let file, _ =
                                            directory.Read(
                                                ArtifactFiles.final row.Artifact.Id,
                                                row.StoredIdentity
                                            )

                                        inspect file)))

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

                    Ok
                        { ArtifactLinkPage.Entries = entries
                          Next =
                            if links.Length > 64 then
                                entries |> List.tryLast |> Option.map (fun l -> l.ModId)
                            else
                                None }))

        member _.Read(workspace, id) =
            run (fun () ->
                read workspace id
                |> Result.bind (fun row ->
                    let inspection =
                        if lock checkedArtifacts (fun () -> checkedArtifacts.Contains id) then
                            Ok()
                        else
                            reconcileRow CancellationToken.None row

                    inspection
                    |> Result.bind (fun () ->
                        read workspace id |> Result.map (fun current -> current.Artifact))))

        member _.Retry(reference, token) =
            run (fun () ->
                withClaim reference (fun row ->
                    if row.Phase <> 0 || row.Artifact.Download.IsSome then
                        Error ArtifactError.Conflict
                    else
                        files.Capture(token, row))

                |> Result.bind (fun () ->
                    read reference.WorkspaceId reference.Id
                    |> Result.map (fun row -> row.Artifact)))

        member _.Locate(reference, path, token) =
            run (fun () ->
                if HostPath.create path |> Result.isError then
                    Error ArtifactError.Conflict
                else
                    withClaim reference (fun row ->
                        if row.Artifact.Storage <> ArtifactStorage.Reference then
                            Error ArtifactError.Conflict
                        else
                            let file, identity = ArtifactFiles.openExternal path None
                            use file = file

                            ArtifactFiles.verify
                                token
                                row.Artifact.Length
                                row.Artifact.Sha256
                                file

                            finish
                                { row with
                                    SourceIdentity = Some identity
                                    Artifact = { row.Artifact with Path = path } }
                                2
                                None
                            |> ignore

                            Ok())
                    |> Result.bind (fun () ->
                        read reference.WorkspaceId reference.Id
                        |> Result.map (fun row -> row.Artifact)))

        member _.List(workspace, after, refresh, token) =
            run (fun () ->
                let check =
                    lock checkedWorkspaces (fun () ->
                        refresh || not (checkedWorkspaces.Contains workspace))

                let mutable progress = Ok()

                if check then
                    let mutable cursor = None
                    let mutable more = true

                    while more && Result.isOk progress do
                        token.ThrowIfCancellationRequested()

                        let ids =
                            db (fun () -> ArtifactRows.reconcileIds connection workspace cursor)
                            |> List.truncate 64

                        progress <- reconcilePage token workspace ids
                        cursor <- List.tryLast ids
                        more <- ids.Length = 64

                    if Result.isOk progress then
                        lock checkedWorkspaces (fun () ->
                            checkedWorkspaces.Add workspace |> ignore)

                progress
                |> Result.bind (fun () ->
                    let ids = db (fun () -> ArtifactRows.ids connection workspace after)

                    artifacts workspace (List.truncate 64 ids)
                    |> Result.map (fun entries ->
                        { Entries = entries
                          Next =
                            if ids.Length > 64 then
                                entries |> List.tryLast |> Option.map (fun a -> a.Id)
                            else
                                None })))

        member _.Link(reference, modId, versionId, remove) =
            run (fun () ->
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    checkedRow transaction reference
                    |> Result.bind (fun row ->
                        changeLink transaction reference row modId versionId remove)
                    |> Result.map (fun () ->
                        Sqlite.execute
                            connection
                            transaction
                            "UPDATE artifacts SET revision=revision+1 WHERE id=$id"
                            [ "$id", box (string reference.Id) ]

                        transaction.Commit()))
                |> Result.bind (fun () ->
                    read reference.WorkspaceId reference.Id
                    |> Result.map (fun row -> row.Artifact)))

        member _.DeleteCopy(reference) =
            run (fun () ->
                withClaim reference (fun row ->
                    if
                        row.Artifact.Storage <> ArtifactStorage.Copy
                        || DownloadRows.running row.Artifact.Download
                    then
                        Error ArtifactError.Conflict
                    else
                        let row = finish row 4 None

                        let hasLibrary =
                            db (fun () ->
                                LibraryRows.library connection null row.Artifact.WorkspaceId
                                |> Option.isSome)

                        let removed =
                            if hasLibrary || row.StoredIdentity.IsSome then
                                library row.Artifact.WorkspaceId
                                |> Result.map (fun directory ->
                                    use directory = directory

                                    ArtifactFiles.remove
                                        directory
                                        (ArtifactFiles.stage reference.Id)
                                        row.StoredIdentity

                                    ArtifactFiles.remove
                                        directory
                                        (ArtifactFiles.final reference.Id)
                                        row.StoredIdentity)
                            else
                                Ok()

                        removed
                        |> Result.map (fun () ->
                            finish { row with StoredIdentity = None } 3 None |> ignore))
                |> Result.bind (fun () ->
                    read reference.WorkspaceId reference.Id
                    |> Result.map (fun row -> row.Artifact)))

        member _.Remove(reference) =
            run (fun () ->
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    checkedRow transaction reference
                    |> Result.bind (removeArtifact transaction reference)
                    |> Result.map (fun () -> transaction.Commit())))
