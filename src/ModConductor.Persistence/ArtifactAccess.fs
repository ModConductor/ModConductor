namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.ArtifactLibrary
open ModConductor.ModLibrary
open ModConductor.Platform

type internal ArtifactAccess(database: StateDatabase, access: LibraryAccess) =
    let connection = database.Connection
    let wait (task: Task<'a>) = task.GetAwaiter().GetResult()
    let db action = database.EnqueueInternal action |> wait

    let find transaction workspace id =
        match ArtifactRows.find connection transaction workspace id with
        | Some row -> Ok row
        | None -> Error ArtifactError.NotFound

    let save row =
        db (fun () -> ArtifactRows.save connection row)

    let finish row phase problem =
        let updated =
            { row with
                Phase = phase
                Artifact =
                    { row.Artifact with
                        Revision = row.Artifact.Revision + 1L
                        Problem = problem } }

        save updated
        updated

    let read workspace id = db (fun () -> find null workspace id)

    let run action =
        task {
            let! result =
                access.Run(fun () ->
                    task {
                        let! result =
                            Task.Run(fun () ->
                                try
                                    action ()
                                with :? OperationCanceledException ->
                                    Error ArtifactError.Cancelled)

                        return Ok result
                    })

            return
                match result with
                | Ok value -> value
                | Error LibraryError.Busy -> Error ArtifactError.Busy
                | Error _ -> Error ArtifactError.Unavailable
        }

    let root workspace =
        access.Root workspace
        |> wait
        |> Result.mapError (fun _ -> ArtifactError.Unavailable)

    let library workspace =
        root workspace
        |> Result.bind (fun root ->
            match db (fun () -> LibraryRows.library connection null workspace) with
            | Some row -> Ok(LibraryFiles.openLibrary root row)
            | None -> Error ArtifactError.Unavailable)

    let withClaim (reference: ArtifactRef) action =
        let acquired =
            db (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                match find transaction reference.WorkspaceId reference.Id with
                | Error error -> Error error
                | Ok row when row.Busy -> Error ArtifactError.Busy
                | Ok row when row.Artifact.Revision <> reference.Revision ->
                    Error ArtifactError.Stale
                | Ok row ->
                    Sqlite.execute
                        connection
                        transaction
                        "UPDATE artifacts SET busy=1,owner=$owner WHERE id=$id"
                        [ "$owner", box database.OwnerId; "$id", box (string reference.Id) ]

                    transaction.Commit()

                    Ok
                        { row with
                            Busy = true
                            Owner = database.OwnerId })

        match acquired with
        | Error error -> Error error
        | Ok row ->
            try
                action row
            finally
                db (fun () ->
                    Sqlite.execute
                        connection
                        null
                        "UPDATE artifacts SET busy=0 WHERE id=$id AND owner=$owner"
                        [ "$id", box (string reference.Id); "$owner", box database.OwnerId ])

    member _.Database = database
    member _.LibraryAccess = access
    member _.Read(workspace, id) = read workspace id
    member _.Save(row) = save row
    member _.Finish(row, phase, problem) = finish row phase problem
    member _.Run(action) = run action
    member _.Root(workspace) = root workspace
    member _.Library(workspace) = library workspace
    member _.Claim(reference, action) = withClaim reference action
