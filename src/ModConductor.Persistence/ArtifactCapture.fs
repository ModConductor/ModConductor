namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.Platform

type internal ArtifactCapture(operations: ArtifactAccess) =
    let database = operations.Database
    let access = operations.LibraryAccess
    let connection = database.Connection
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait
    let refuse error = raise (ArtifactException error)
    let run action = operations.Run action
    let read workspace id = operations.Read(workspace, id)
    let save row = operations.Save row
    let finish row phase problem = operations.Finish(row, phase, problem)
    let root workspace = operations.Root workspace
    let library workspace = operations.Library workspace
    let withClaim reference action = operations.Claim(reference, action)

    let reconcile (token: CancellationToken) row =
        try
            token.ThrowIfCancellationRequested()

            if row.Artifact.Storage = ArtifactStorage.Reference then
                let file, _ = ArtifactFiles.openExternal row.Artifact.Path row.SourceIdentity
                use file = file

                if row.Artifact.Sha256.IsNone then
                    row
                else
                    if row.Phase = 2 then
                        if Some file.Length <> row.Artifact.Length then
                            raise (IOException "The archive does not match the saved file.")

                        row
                    else
                        ArtifactFiles.verify token row.Artifact.Length row.Artifact.Sha256 file
                        finish row 2 None
            elif row.Phase = 0 && row.Artifact.Download.IsSome && row.StoredIdentity.IsSome then
                use directory = library row.Artifact.WorkspaceId

                use file =
                    directory.Write(ArtifactFiles.stage row.Artifact.Id, row.StoredIdentity.Value)

                let bytes = row.Artifact.Download.Value.Bytes

                if file.Length < bytes then
                    raise (IOException "The partial copy is shorter than its saved size.")

                if file.Length > bytes then
                    file.SetLength bytes
                    file.Flush true

                row
            elif row.Phase = 0 || (row.Phase = 3 && row.StoredIdentity.IsNone) then
                row
            else
                use directory = library row.Artifact.WorkspaceId

                let stage, final =
                    ArtifactFiles.stage row.Artifact.Id, ArtifactFiles.final row.Artifact.Id

                if row.Phase = 4 then
                    ArtifactFiles.remove directory stage row.StoredIdentity
                    ArtifactFiles.remove directory final row.StoredIdentity
                    finish { row with StoredIdentity = None } 3 None
                else
                    match directory.InspectEntry final with
                    | Some _ ->
                        let file, identity = directory.Read(final, row.StoredIdentity)
                        use file = file

                        if row.StoredIdentity.IsNone then
                            raise (IOException "The library file has no saved identity.")

                        if row.Phase = 2 then
                            if Some file.Length <> row.Artifact.Length then
                                raise (IOException "The archive does not match the saved file.")

                            row
                        else
                            ArtifactFiles.verify token row.Artifact.Length row.Artifact.Sha256 file
                            finish
                                { row with
                                    StoredIdentity = Some identity }
                                2
                                None
                    | None when row.Phase = 1 ->
                        let file, _ = directory.Read(stage, row.StoredIdentity)
                        use file = file
                        ArtifactFiles.verify token row.Artifact.Length row.Artifact.Sha256 file
                        file.Dispose()
                        ArtifactFiles.promote directory row.Artifact.Id row.StoredIdentity
                        finish row 2 None
                    | None -> finish row 3 (Some "The archive is not at its saved location.")
        with
        | :? IOException as error ->
            finish
                row
                (if row.Phase = 0 || row.Phase = 1 || row.Phase = 4 then
                     0
                 else
                     3)
                (Some error.Message)
        | :? UnauthorizedAccessException ->
            finish
                row
                (if row.Phase = 0 || row.Phase = 1 || row.Phase = 4 then
                     0
                 else
                     3)
                (Some "The archive cannot be read.")

    let capture token checkpoint row =
        let file, identity = ArtifactFiles.openExternal row.Artifact.OriginalPath None
        use file = file

        if row.Artifact.Sha256.IsSome then
            ArtifactFiles.verify token row.Artifact.Length row.Artifact.Sha256 file
            file.Position <- 0L

        if row.Artifact.Storage = ArtifactStorage.Reference then
            let length, digest = ArtifactFiles.transfer token file None checkpoint

            finish
                { row with
                    SourceIdentity = Some identity
                    Artifact =
                        { row.Artifact with
                            Length = Some length
                            Sha256 = Some digest
                            Path = row.Artifact.OriginalPath } }
                2
                None
            |> ignore
        else
            let root = root row.Artifact.WorkspaceId

            let prepared =
                access.PrepareLibrary(root, ignore)
                |> wait
                |> Result.defaultWith (fun _ -> refuse ArtifactError.Unavailable)

            use directory = LibraryFiles.openLibrary root prepared

            let stage, final =
                ArtifactFiles.stage row.Artifact.Id, ArtifactFiles.final row.Artifact.Id

            if directory.InspectEntry final |> Option.isSome then
                refuse ArtifactError.Conflict

            ArtifactFiles.remove directory stage row.StoredIdentity
            let output, stored = directory.Create stage
            use output = output

            let row =
                { row with
                    StoredIdentity = Some stored
                    SourceIdentity = Some identity
                    Artifact =
                        { row.Artifact with
                            Path = Path.Combine(HostPath.value root.Path, prepared.Name, final) } }

            save row
            checkpoint "stage"
            let length, digest = ArtifactFiles.transfer token file (Some output) checkpoint
            output.Dispose()

            let row =
                finish
                    { row with
                        Artifact =
                            { row.Artifact with
                                Length = Some length
                                Sha256 = Some digest } }
                    1
                    None

            checkpoint "observed"
            token.ThrowIfCancellationRequested()
            ArtifactFiles.promote directory row.Artifact.Id (Some stored)
            checkpoint "final"
            finish row 2 None |> ignore
            checkpoint "committed"

    let add (request: ArtifactRegistration) token checkpoint =
        run (fun () ->
            if
                request.Id = Guid.Empty
                || request.WorkspaceId = Guid.Empty
                || HostPath.create request.Path |> Result.isError
            then
                refuse ArtifactError.Conflict

            let fresh =
                db (fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    if
                        Sqlite.number
                            connection
                            transaction
                            "SELECT count(*) FROM workspaces WHERE id=$workspace"
                            [ "$workspace", box (string request.WorkspaceId) ]
                        <> 1L
                    then
                        refuse ArtifactError.NotFound

                    let fresh =
                        match
                            ArtifactRows.find
                                connection
                                transaction
                                request.WorkspaceId
                                request.Id
                        with
                        | Some row ->
                            if
                                row.Artifact.OriginalPath <> request.Path
                                || row.Artifact.Storage <> request.Storage
                            then
                                refuse ArtifactError.Conflict

                            false
                        | None ->
                            if
                                Sqlite.number
                                    connection
                                    transaction
                                    "SELECT count(*) FROM artifacts WHERE id=$id"
                                    [ "$id", box (string request.Id) ]
                                <> 0L
                            then
                                refuse ArtifactError.Conflict

                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO artifacts(id,workspace_id,revision,original_name,original_path,path,storage,phase,owner,busy) VALUES($id,$workspace,0,$name,$path,$path,$storage,0,$owner,0)"
                                [ "$id", box (string request.Id)
                                  "$workspace", box (string request.WorkspaceId)
                                  "$name", box (Path.GetFileName request.Path)
                                  "$path", box request.Path
                                  "$storage",
                                  box (
                                      if request.Storage = ArtifactStorage.Reference then 0 else 1
                                  )
                                  "$owner", box database.OwnerId ]

                            true

                    transaction.Commit()
                    fresh)

            if fresh then
                withClaim
                    { WorkspaceId = request.WorkspaceId
                      Id = request.Id
                      Revision = 0L }
                    (capture token checkpoint)

            (read request.WorkspaceId request.Id).Artifact)

    member _.Reconcile(token, row) = reconcile token row
    member _.Capture(token, row) = capture token ignore row
    member _.Add(request, token, checkpoint) = add request token checkpoint
