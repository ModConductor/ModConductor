namespace ModConductor.Persistence

open System
open System.IO
open System.Collections.Generic
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads

/// Stores transfer state as an extension of the existing artifact claim and file owner.
type internal DownloadRepository(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let operations = ArtifactAccess(database, access)
    let db action = database.EnqueueInternal action
    let refuse error = raise (ArtifactException error)
    let changesGate = obj ()
    let changes = Dictionary<Guid, TaskCompletionSource>()

    let changed id =
        lock changesGate (fun () ->
            match changes.TryGetValue id with
            | true, signal ->
                changes.Remove id |> ignore
                signal.TrySetResult() |> ignore
            | _ -> ())

    let waitSignal id =
        lock changesGate (fun () ->
            match changes.TryGetValue id with
            | true, signal -> signal.Task
            | _ ->
                let signal = TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously)
                changes.Add(id, signal)
                signal.Task)

    let find tx workspace id =
        ArtifactRows.find connection tx workspace id
        |> Option.defaultWith (fun () -> refuse ArtifactError.NotFound)

    let read workspace id =
        db (fun () -> (find null workspace id).Artifact)

    let protect action =
        task {
            try
                return! action ()
            with
            | :? ArtifactException as error -> return Error error.Error
            | :? ModConductor.Operations.CapacityException -> return Error ArtifactError.Busy
        }

    let admit tx =
        if
            Sqlite.number
                connection
                tx
                "SELECT count(*) FROM artifact_downloads WHERE state IN (0,2)"
                []
            >= 32L
        then
            refuse ArtifactError.Busy

    let findNexus tx workspace reference =
        use query =
            Sqlite.command
                connection
                tx
                "SELECT a.id FROM artifacts a JOIN artifact_downloads d ON d.artifact_id=a.id WHERE a.workspace_id=$workspace AND a.phase IN (0,1,2) AND (d.sources=$ordinary OR d.sources=$keyed) ORDER BY CASE WHEN a.phase=2 THEN 0 ELSE 1 END,a.id LIMIT 1"
                [ "$workspace", box (string workspace)
                  "$ordinary",
                  box (
                      DownloadSource.encode (DownloadSource.Nexus { reference with Keyed = false })
                  )
                  "$keyed",
                  box (DownloadSource.encode (DownloadSource.Nexus { reference with Keyed = true })) ]

        match query.ExecuteScalar() with
        | :? string as value -> Some(Guid.Parse value)
        | _ -> None

    let start (request: DownloadRequest) =
        protect (fun () ->
            task {
                if
                    request.Id = Guid.Empty
                    || request.WorkspaceId = Guid.Empty
                    || String.IsNullOrWhiteSpace request.Name
                    || request.Name.Length > 256
                    || request.Sources.IsEmpty
                    || request.Sources.Length > 8
                    || (request.Sources |> List.exists (DownloadSource.valid >> not))
                    || (request.Sources.Length > 1
                        && request.Sources
                           |> List.exists (function
                               | DownloadSource.Nexus _ -> true
                               | DownloadSource.Url _ -> false))
                    || (request.ExpectedLength |> Option.exists (fun n -> n < 0L))
                    || (request.ExpectedSha256
                        |> Option.exists (fun hash ->
                            hash.Length <> 64
                            || (hash |> Seq.exists (fun c -> not (Uri.IsHexDigit c)))))
                then
                    refuse ArtifactError.Conflict

                let! actualId =
                    db (fun () ->
                        use tx = connection.BeginTransaction(deferred = false)

                        let matching =
                            match request.Sources with
                            | [ DownloadSource.Nexus reference ] ->
                                findNexus tx request.WorkspaceId reference
                            | _ -> None

                        let selected = defaultArg matching request.Id

                        let parameters =
                            [ "$id", box (string selected)
                              "$workspace", box (string request.WorkspaceId) ]

                        match DownloadRows.work connection tx selected with
                        | Some _ when matching.IsSome ->
                            match request.Sources with
                            | [ DownloadSource.Nexus reference ] when reference.Keyed ->
                                Sqlite.execute
                                    connection
                                    tx
                                    "UPDATE artifact_downloads SET sources=$source WHERE artifact_id=$id"
                                    [ "$source", box (DownloadSource.encode request.Sources.Head)
                                      "$id", box (string selected) ]
                            | _ -> ()
                        | Some existing when existing.Request = request -> ()
                        | Some _ -> refuse ArtifactError.Conflict
                        | None ->
                            if
                                Sqlite.number
                                    connection
                                    tx
                                    "SELECT count(*) FROM artifacts WHERE id=$id"
                                    [ "$id", box (string request.Id) ]
                                <> 0L
                            then
                                refuse ArtifactError.Conflict

                            if
                                Sqlite.number
                                    connection
                                    tx
                                    "SELECT count(*) FROM workspaces WHERE id=$workspace"
                                    [ "$workspace", box (string request.WorkspaceId) ]
                                <> 1L
                            then
                                refuse ArtifactError.NotFound

                            admit tx

                            Sqlite.execute
                                connection
                                tx
                                "INSERT INTO artifacts(id,workspace_id,revision,original_name,original_path,path,storage,phase,owner,busy,length) VALUES($id,$workspace,0,$name,$source,'',1,0,$owner,0,$length)"
                                (parameters
                                 @ [ "$name", box request.Name
                                     "$source", box (DownloadSource.display request.Sources.Head)
                                     "$owner", box database.OwnerId
                                     "$length", ArtifactRows.nullable request.ExpectedLength ])

                            Sqlite.execute
                                connection
                                tx
                                "INSERT INTO artifact_downloads(artifact_id,sources,expected_length,expected_sha,state,bytes,total,source_index,attempt,restart_required,checksum_matched) VALUES($id,$sources,$length,$sha,0,0,$length,0,0,0,0)"
                                [ "$id", box (string request.Id)
                                  "$sources",
                                  box (
                                      request.Sources
                                      |> List.map DownloadSource.encode
                                      |> String.concat "\n"
                                  )
                                  "$length", ArtifactRows.nullable request.ExpectedLength
                                  "$sha", ArtifactRows.nullable request.ExpectedSha256 ]

                        match request.Sources with
                        | [ DownloadSource.Nexus reference ] ->
                            Sqlite.execute
                                connection
                                tx
                                "UPDATE artifact_downloads SET nexus_version=COALESCE(nexus_version,$version) WHERE artifact_id=$id"
                                [ "$version", ArtifactRows.nullable reference.Version
                                  "$id", box (string selected) ]
                        | _ -> ()

                        tx.Commit()
                        selected)

                let! artifact = read request.WorkspaceId actualId
                changed actualId
                return Ok artifact
            })

    let control workspace id action =
        protect (fun () ->
            task {
                do!
                    db (fun () ->
                        use tx = connection.BeginTransaction(deferred = false)
                        let row = find tx workspace id

                        let info =
                            row.Artifact.Download
                            |> Option.defaultWith (fun () -> refuse ArtifactError.Conflict)

                        let parameters = [ "$id", box (string id) ]

                        if DownloadRows.running (Some info) && row.Owner <> database.OwnerId then
                            refuse ArtifactError.Busy

                        if row.Phase = 0 then
                            match action with
                            | DownloadAction.Pause ->
                                Sqlite.execute
                                    connection
                                    tx
                                    "UPDATE artifact_downloads SET state=3 WHERE artifact_id=$id"
                                    parameters
                            | DownloadAction.Resume when DownloadRows.running (Some info) -> ()
                            | DownloadAction.Resume
                            | DownloadAction.Restart ->
                                if row.Busy then
                                    refuse ArtifactError.Busy

                                if
                                    info.RetryAt
                                    |> Option.exists (fun at -> at > DateTimeOffset.UtcNow)
                                then
                                    refuse ArtifactError.Busy

                                if action = DownloadAction.Resume && info.RestartRequired then
                                    refuse ArtifactError.Conflict

                                admit tx

                                let statement =
                                    if action = DownloadAction.Restart then
                                        "UPDATE artifact_downloads SET state=0,bytes=0,total=expected_length,etag=NULL,effective_url=NULL,source_index=$source,attempt=0,retry_at=NULL,restart_required=0,checksum_matched=0 WHERE artifact_id=$id"
                                    else
                                        "UPDATE artifact_downloads SET state=0,attempt=0,retry_at=NULL WHERE artifact_id=$id"

                                let work = (DownloadRows.work connection tx id).Value

                                let args =
                                    if action = DownloadAction.Restart then
                                        parameters
                                        @ [ "$source",
                                            box (
                                                (work.SourceIndex + 1) % work.Request.Sources.Length
                                            ) ]
                                    else
                                        parameters

                                Sqlite.execute connection tx statement args

                                Sqlite.execute
                                    connection
                                    tx
                                    "UPDATE artifacts SET owner=$owner,problem=NULL,sha256=NULL WHERE id=$id"
                                    (parameters @ [ "$owner", box database.OwnerId ])

                            Sqlite.execute
                                connection
                                tx
                                "UPDATE artifacts SET revision=revision+1 WHERE id=$id"
                                parameters

                        tx.Commit())

                let! artifact = read workspace id
                changed id
                return Ok artifact
            })

    interface IDownloadRepository with
        member _.FindNexus(workspace, reference) =
            db (fun () ->
                findNexus null workspace reference
                |> Option.map (fun id -> (find null workspace id).Artifact))

        member _.AccountDownloads subject =
            db (fun () ->
                use query =
                    Sqlite.command
                        connection
                        null
                        "SELECT artifact_id FROM artifact_downloads WHERE state IN (0,1,2)"
                        []

                use reader = query.ExecuteReader()
                let ids = ResizeArray<Guid>()

                while reader.Read() do
                    ids.Add(Guid.Parse(reader.GetString 0))

                reader.Close()

                ids
                |> Seq.choose (fun id ->
                    DownloadRows.work connection null id
                    |> Option.bind (fun work ->
                        if
                            work.Request.Sources
                            |> List.exists (function
                                | DownloadSource.Nexus value -> value.Account = subject
                                | DownloadSource.Url _ -> false)
                        then
                            Some(work.Request.WorkspaceId, id)
                        else
                            None))
                |> Seq.toList)

        member _.Read(workspace, id) =
            protect (fun () ->
                task {
                    let! artifact = read workspace id
                    return Ok artifact
                })

        member _.WaitForChange(workspace, revisions, token) =
            task {
                if revisions.IsEmpty then
                    do! Task.Delay(Timeout.InfiniteTimeSpan, token)
                else
                    let! pending =
                        db (fun () ->
                            if
                                revisions
                                |> List.exists (fun (id, revision) ->
                                    ArtifactRows.find connection null workspace id
                                    |> Option.exists (fun row -> row.Artifact.Revision <> revision))
                            then
                                Task.CompletedTask
                            else
                                revisions
                                |> List.map (fst >> waitSignal)
                                |> Task.WhenAny
                                :> Task)

                    do! pending.WaitAsync(token)
            } :> Task

        member _.Start request = start request
        member _.Control(workspace, id, action) = control workspace id action

        member _.Take() =
            db (fun () ->
                use tx = connection.BeginTransaction(deferred = false)

                use q =
                    Sqlite.command
                        connection
                        tx
                        "SELECT a.id FROM artifacts a JOIN artifact_downloads d ON d.artifact_id=a.id WHERE a.phase=0 AND a.busy=0 AND a.owner=$owner AND (d.state=0 OR (d.state=2 AND d.retry_at<=$now)) ORDER BY d.retry_at,a.id LIMIT 1"
                        [ "$owner", box database.OwnerId
                          "$now", box (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()) ]

                let value = q.ExecuteScalar()

                if isNull value then
                    tx.Commit()
                    None
                else
                    let id = Guid.Parse(string value)
                    let parameters = [ "$id", box (string id) ]

                    Sqlite.execute
                        connection
                        tx
                        "UPDATE artifacts SET busy=1,revision=revision+1 WHERE id=$id"
                        parameters

                    Sqlite.execute
                        connection
                        tx
                        "UPDATE artifact_downloads SET state=1,attempt=attempt+1,retry_at=NULL WHERE artifact_id=$id"
                        parameters

                    let work = DownloadRows.work connection tx id
                    tx.Commit()
                    changed id
                    work)

        member _.NextDue() =
            db (fun () ->
                use q =
                    Sqlite.command
                        connection
                        null
                        "SELECT min(d.retry_at) FROM artifact_downloads d JOIN artifacts a ON a.id=d.artifact_id WHERE d.state=2 AND a.owner=$owner AND a.phase=0"
                        [ "$owner", box database.OwnerId ]

                match q.ExecuteScalar() with
                | :? int64 as value -> Some(DateTimeOffset.FromUnixTimeMilliseconds value)
                | _ -> None)

        member _.Open work = DownloadTarget.Open(operations, work, changed)

        member _.Finish(work, outcome) : Task =
            db (fun () ->
                use tx = connection.BeginTransaction(deferred = false)
                let row = find tx work.Request.WorkspaceId work.Request.Id
                let info = row.Artifact.Download.Value

                let outcome =
                    if info.State = DownloadState.Paused then
                        DownloadOutcome.Paused
                    else
                        outcome

                let state, at, source, restart, message =
                    match outcome with
                    | DownloadOutcome.Paused ->
                        3, None, work.SourceIndex, info.RestartRequired, None
                    | DownloadOutcome.Retry(at, source) ->
                        2,
                        Some at,
                        (if info.Bytes = 0L then source else work.SourceIndex),
                        false,
                        None
                    | DownloadOutcome.Failed(message, restart, at) ->
                        4, at, work.SourceIndex, restart, Some message

                let parameters = [ "$id", box (string work.Request.Id) ]

                Sqlite.execute
                    connection
                    tx
                    "UPDATE artifact_downloads SET state=$state,retry_at=$at,source_index=$source,restart_required=$restart WHERE artifact_id=$id"
                    (parameters
                     @ [ "$state", box state
                         "$at",
                         ArtifactRows.nullable (
                             at |> Option.map (fun d -> d.ToUnixTimeMilliseconds())
                         )
                         "$source", box source
                         "$restart", box restart ])

                Sqlite.execute
                    connection
                    tx
                    "UPDATE artifacts SET busy=0,problem=$problem,revision=revision+1 WHERE id=$id"
                    (parameters @ [ "$problem", ArtifactRows.nullable message ])

                tx.Commit()
                changed work.Request.Id)
