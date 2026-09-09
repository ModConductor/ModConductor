namespace ModConductor.Persistence

open System
open ModConductor.Operations

type OperationStore(directory: string) =
    let database = new StateDatabase(directory)
    let workspaceRoots = OwnedWorkspaceRootStore(database)
    let workspaces = WorkspaceStateStore(database, workspaceRoots)
    let modLibrary = ModLibraryStore(database, workspaceRoots)
    let organization = ModOrganizationStore(database, modLibrary.Access)
    let selection = ModSelectionStore(database, modLibrary.Access)
    let gameContexts = GameContextStore(database, workspaceRoots)

    let filePlans =
        ModConductor.FilePlanning.FilePlanSession(FilePlanRepository(database, modLibrary.Access))

    let deployment =
        ModConductor.DeploymentRecovery.Recovery(DeploymentRepository(database))

    let generations = DeploymentGenerationStore(database, modLibrary.Access, deployment)

    let outputs =
        ModConductor.GeneratedOutputs.GeneratedOutputSession(
            OutputRepository(database, modLibrary.Access, modLibrary.PublicationOwner)
        )

    let deploymentBackend =
        ModConductor.Deployment.DeploymentBackend(
            DeploymentBackendRepository(
                database,
                modLibrary.Access,
                filePlans,
                deployment,
                generations
            )
        )

    let executables =
        ModConductor.Executables.ExecutableSession(ExecutableRepository(database))

    let connection = database.Connection

    let state transaction =
        OperationJournal.state connection transaction

    let find transaction id =
        OperationJournal.find connection transaction id

    let save transaction snapshot =
        OperationJournal.save connection transaction snapshot

    let enqueue action = database.Enqueue action
    let enqueueInternal action = database.EnqueueInternal action

    let feed initial requested =
        use transaction = connection.BeginTransaction(deferred = true)
        let revision, cursor = state transaction

        let gap =
            requested
            |> Option.exists (fun after -> after < max 0L (cursor - 128L) || after > cursor)

        let result =
            if initial || gap then
                { Cursor = cursor
                  Revision = revision
                  ResyncRequired = gap
                  Snapshot =
                    Some(
                        OperationRows.list
                            connection
                            transaction
                            ("SELECT "
                             + OperationRows.columns
                             + " FROM operations ORDER BY last_cursor DESC LIMIT 16")
                            []
                    )
                  Changes = [] }
            else
                let after = requested |> Option.defaultValue cursor

                use statement =
                    Sqlite.command
                        connection
                        transaction
                        ("SELECT "
                         + OperationRows.columns
                         + ",cursor FROM operation_events WHERE cursor>$after ORDER BY cursor LIMIT 16")
                        [ "$after", box after ]

                use reader = statement.ExecuteReader()

                let changes =
                    [ while reader.Read() do
                          yield
                              { Cursor = reader.GetInt64 9
                                Operation = OperationRows.read reader } ]

                { Cursor =
                    changes
                    |> List.tryLast
                    |> Option.map (fun change -> change.Cursor)
                    |> Option.defaultValue after
                  Revision = revision
                  ResyncRequired = false
                  Snapshot = None
                  Changes = changes }

        transaction.Commit()
        result

    member _.WorkspaceRoots = workspaceRoots

    member _.Workspaces = workspaces

    member _.ModLibrary = modLibrary

    member _.ModSelection = selection
    member _.ModOrganization = organization

    member _.GameContexts = gameContexts
    member _.FilePlans = filePlans
    member _.GeneratedOutputs = outputs :> ModConductor.GeneratedOutputs.IGeneratedOutputs
    member _.Deployments = deploymentBackend :> ModConductor.Deployment.IDeploymentBackend

    member _.ExecutablesFailed = executables.Failed

    member _.Executables = executables :> ModConductor.Executables.IExecutables

    member _.SqliteVersion = connection.ServerVersion

    interface IOperationStore with
        member _.Begin(request) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction request.Id with
                    | Some snapshot when snapshot.Request = request -> Ok(snapshot, false)
                    | Some _ -> Error IdentityConflict
                    | None ->
                        let revision, _ = state transaction

                        if revision <> request.ExpectedRevision then
                            Error StaleRevision
                        elif
                            Sqlite.number
                                connection
                                transaction
                                "SELECT count(*) FROM operations WHERE phase=1"
                                []
                            >= 16L
                        then
                            Error Capacity
                        else
                            let snapshot =
                                { Request = request
                                  Phase = Running
                                  Progress = 0
                                  Result = None
                                  ResultRevision = 0L }

                            Sqlite.execute
                                connection
                                transaction
                                "INSERT INTO operations(id,owner,expected_revision,count,phase,progress,result_revision,last_cursor) VALUES($id,$owner,$expected,$count,1,0,0,0)"
                                [ "$id", box request.Id
                                  "$owner", box database.OwnerId
                                  "$expected", box request.ExpectedRevision
                                  "$count", box request.Count ]

                            save transaction snapshot
                            Ok(snapshot, true)

                transaction.Commit()
                result)

        member _.Advance(id, progress, runtime) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)
                let current = find transaction id |> Option.get

                let snapshot =
                    if current.Phase <> Running then
                        current
                    elif progress = current.Request.Count then
                        let revision, _ = state transaction

                        if revision <> current.Request.ExpectedRevision then
                            { current with
                                Phase = Stale
                                Progress = progress }
                        else
                            Sqlite.execute
                                connection
                                transaction
                                "UPDATE operation_state SET revision=revision+1 WHERE id=1"
                                []

                            { current with
                                Phase = Completed
                                Progress = progress
                                Result = Some runtime
                                ResultRevision = revision + 1L }
                    else
                        { current with Progress = progress }

                if snapshot <> current then
                    save transaction snapshot

                transaction.Commit()
                snapshot)

        member _.Cancel(id) =
            enqueue (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                let result =
                    match find transaction id with
                    | None -> Error NotFound
                    | Some snapshot when snapshot.Phase = Running ->
                        let cancelled = { snapshot with Phase = Cancelled }
                        save transaction cancelled
                        Ok cancelled
                    | Some snapshot -> Ok snapshot

                transaction.Commit()
                result)

        member _.Get(id) =
            enqueue (fun () ->
                find null id |> Option.map Ok |> Option.defaultValue (Error NotFound))

        member _.InitialFeed(cursor) = enqueue (fun () -> feed true cursor)

        member _.Changes(cursor) =
            enqueue (fun () -> feed false (Some cursor))

        member _.Interrupt(id) =
            enqueueInternal (fun () ->
                use transaction = connection.BeginTransaction(deferred = false)

                match find transaction id with
                | Some snapshot when snapshot.Phase = Running ->
                    save transaction { snapshot with Phase = Interrupted }
                | Some _
                | None -> ()

                transaction.Commit())

    member internal _.ApplyOutputAtCheckpoint
        (id, snapshot, selected, action, token, afterPublication)
        =
        outputs.ApplyAtCheckpoint(id, snapshot, selected, action, token, afterPublication)

    member _.DrainOutputs() = outputs.Drain()
    member _.DrainDeployments() = deploymentBackend.Drain()

    member internal _.Deployment = deployment
    member internal _.Generations = generations

    interface IDisposable with
        member _.Dispose() =
            if
                not (
                    outputs.TryClose(fun () ->
                        deploymentBackend.TryClose(fun () ->
                            generations.TryClose(fun () ->
                                deployment.TryClose()
                                && filePlans.TryClose()
                                && gameContexts.TryClose()
                                && modLibrary.TryClose(fun () ->
                                    workspaces.TryClose(workspaceRoots.TryClose)))))
                )
            then
                invalidOp
                    "A workspace change or root file check is still active. Wait for it before closing the store."


            executables.Close().GetAwaiter().GetResult()
            (database :> IDisposable).Dispose()
