namespace ModConductor.Deployment

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery

type DeploymentBackend internal (repository: IDeploymentRepository) =
    let state = DeploymentBackendState()

    let protect action =
        task {
            try
                return! action ()
            with
            | RecoveryException error -> return Error(DeploymentReports.error error)
            | :? OperationCanceledException -> return Error DeploymentError.Cancelled
            | :? IOException as error -> return Error(DeploymentError.Unavailable error.Message)
            | :? UnauthorizedAccessException ->
                return Error(DeploymentError.Unavailable "Deployment storage cannot be accessed.")
        }

    let run workspace action =
        task {
            if not (state.Enter workspace) then
                return Error DeploymentError.Busy
            else
                try
                    return! protect action
                finally
                    state.Leave workspace
        }

    let execute (receipt: Receipt) restoring progress token =
        task {
            let mutable completed = 0
            let mutable last = DateTime.MinValue

            let phase =
                if restoring then
                    DeploymentPhase.Restoring
                else
                    DeploymentPhase.Applying

            let notify name _ =
                if name = "installed" || name = "restored" then
                    completed <- completed + 1

                if (DateTime.UtcNow - last).TotalMilliseconds >= 100. then
                    progress
                        { Phase = phase
                          Completed = completed
                          Total = receipt.Changes.Length
                          Bytes = 0L }

                    last <- DateTime.UtcNow

            let! result = repository.Run(receipt.Id, receipt.Revision, restoring, token, notify)

            return
                result
                |> Result.map DeploymentReports.receipt
                |> Result.mapError DeploymentReports.error
        }

    let checkedContext context =
        GameProcesses.validate context |> Result.mapError DeploymentError.Unavailable

    member _.Drain() = state.Drain()

    member internal _.TryClose(next: unit -> bool) = state.TryClose next

    member internal _.TryAcquireWorkspace(workspace) = state.TryAcquireWorkspace workspace

    member _.PrepareForLaunch(id, expected: SourceStamp, progress, token) =
        task {
            if not (state.Enter expected.WorkspaceId) then
                return Error DeploymentError.Busy
            else
                let mutable retained = false

                try
                    let! result =
                        protect (fun () ->
                            LaunchDeployment.prepare
                                repository
                                execute
                                id
                                expected
                                None
                                progress
                                token)

                    match result with
                    | Error error -> return Error error
                    | Ok(prepared, receipt) ->
                        let lease = state.Lease expected.WorkspaceId

                        retained <- true
                        return Ok(prepared, receipt, lease)
                finally
                    if not retained then
                        state.Leave expected.WorkspaceId
        }

    interface IDeploymentBackend with
        member _.Read profile =
            protect (fun () ->
                task {
                    let! read = repository.Read profile

                    match read with
                    | Error error -> return Error(DeploymentReports.error error)
                    | Ok(sources, context) ->
                        let! root =
                            repository.RunnableRoot(
                                sources.Stamp.WorkspaceId,
                                sources.Stamp.ProfileId
                            )

                        match root with
                        | Error error -> return Error(DeploymentReports.error error)
                        | Ok runnableRoot ->
                            let! active =
                                match context |> Option.bind _.Active with
                                | Some id -> repository.SavedOne(context.Value.Id, id)
                                | None -> System.Threading.Tasks.Task.FromResult None

                            return
                                Ok
                                    { WorkspaceId = sources.Stamp.WorkspaceId
                                      RunnableRoot = runnableRoot
                                      Revision =
                                        context |> Option.map _.Revision |> Option.defaultValue 0L
                                      ActiveGeneration = context |> Option.bind _.Active
                                      Active = active
                                      PendingReceipt = context |> Option.bind _.Pending
                                      Sources = sources.Stamp }
                })

        member _.Saved(profile, before) =
            protect (fun () ->
                task {
                    let! read = repository.Read profile

                    match read with
                    | Error error -> return Error(DeploymentReports.error error)
                    | Ok(_, context) ->
                        match context with
                        | None -> return Ok { Entries = []; NextBefore = None }
                        | Some context ->
                            let! page = repository.Saved(context.Id, context.Active, before)
                            return Ok page
                })

        member _.Prepare(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! read = repository.Read expected.ProfileId

                    match read with
                    | Error error -> return Error(DeploymentReports.error error)
                    | Ok(sources, context) ->
                        if sources.Stamp <> expected then
                            return Error DeploymentError.Stale
                        elif context |> Option.exists (fun value -> value.Pending.IsSome) then
                            return Error DeploymentError.Busy
                        elif id = Guid.Empty then
                            return
                                Error(DeploymentError.Unavailable "Select an operation identity.")
                        else
                            token.ThrowIfCancellationRequested()

                            match checkedContext sources.Context with
                            | Error error -> return Error error
                            | Ok _ ->
                                let! prepared =
                                    repository.Prepare(id, sources, context, progress, token)

                                match prepared with
                                | Error error -> return Error(DeploymentReports.error error)
                                | Ok value ->
                                    let mutable retained = false

                                    try
                                        let! current = repository.Current expected
                                        token.ThrowIfCancellationRequested()

                                        if not current then
                                            return Error DeploymentError.Stale
                                        else
                                            state.Cache(id, value)
                                            retained <- true
                                            return Ok value.View
                                    finally
                                        if not retained then
                                            state.Abandon value
                })

        member _.PrepareRetained(id, expected, generation, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! read = repository.Read expected.ProfileId

                    match read with
                    | Error error -> return Error(DeploymentReports.error error)
                    | Ok(sources, existing) ->
                        if sources.Stamp <> expected then
                            return Error DeploymentError.Stale
                        else
                            match existing with
                            | None -> return Error DeploymentError.NotFound
                            | Some context when context.Pending.IsSome ->
                                return Error DeploymentError.Busy
                            | Some context ->
                                match checkedContext sources.Context with
                                | Error error -> return Error error
                                | Ok evidence ->
                                    if
                                        context.Fingerprint
                                        <> DeploymentContextId.fingerprint evidence
                                    then
                                        return Error DeploymentError.Stale
                                    else
                                        let! prepared =
                                            repository.Retained(
                                                id,
                                                sources,
                                                context,
                                                generation,
                                                progress,
                                                token
                                            )

                                        match prepared with
                                        | Error error ->
                                            return Error(DeploymentReports.error error)
                                        | Ok value ->
                                            let mutable retained = false

                                            try
                                                let! current = repository.Current expected
                                                token.ThrowIfCancellationRequested()

                                                if not current then
                                                    return Error DeploymentError.Stale
                                                else
                                                    state.Cache(id, value)
                                                    retained <- true
                                                    return Ok value.View
                                            finally
                                                if not retained then
                                                    state.Abandon value
                })

        member _.RefreshFnis(id, expected, candidate, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! refreshed =
                        LaunchDeployment.prepare
                            repository
                            execute
                            id
                            expected
                            (Some candidate)
                            progress
                            token

                    return refreshed |> Result.map (fun (_, receipt) -> receipt)
                })

        member _.Activate(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    let value = state.Take id

                    match value with
                    | None -> return Error DeploymentError.NotFound
                    | Some value ->
                        let mutable durable = false

                        try
                            if value.View.Sources <> expected then
                                return Error DeploymentError.Stale
                            else
                                let! contextResult =
                                    repository.Context(expected.WorkspaceId, expected.ProfileId)

                                let contextCheck =
                                    contextResult
                                    |> Result.mapError DeploymentReports.error
                                    |> Result.bind (fun context ->
                                        if context <> value.Context then
                                            Error DeploymentError.Stale
                                        else
                                            checkedContext context)

                                match contextCheck with
                                | Error error -> return Error error
                                | Ok _ ->
                                    token.ThrowIfCancellationRequested()
                                    let! started = repository.Start(value, token)

                                    match started with
                                    | Error error -> return Error(DeploymentReports.error error)
                                    | Ok receipt ->
                                        durable <- true
                                        return! execute receipt false progress token
                        finally
                            if not durable then
                                state.Abandon value
                })

        member _.Recover(id, revision, restore, progress, token) =
            protect (fun () ->
                task {
                    let! saved = repository.Receipt id

                    match saved with
                    | None -> return Error DeploymentError.NotFound
                    | Some saved ->
                        return!
                            run saved.Context.Roots.Head.Root.Id (fun () ->
                                task {
                                    if saved.Revision <> revision then
                                        return Error DeploymentError.Stale
                                    else
                                        let! contextResult =
                                            repository.ContextForDeployment(
                                                saved.Context.Roots.Head.Root.Id,
                                                saved.Context.Id
                                            )

                                        let contextCheck =
                                            contextResult
                                            |> Result.mapError DeploymentReports.error
                                            |> Result.bind checkedContext

                                        match contextCheck with
                                        | Error error -> return Error error
                                        | Ok evidence when
                                            DeploymentContextId.fingerprint evidence
                                            <> saved.Context.Fingerprint
                                            ->
                                            return Error DeploymentError.Stale
                                        | Ok _ -> return! execute saved restore progress token
                                })
                })

        member _.Receipt id =
            protect (fun () ->
                task {
                    let! value = repository.Receipt id

                    return
                        value
                        |> Option.map (DeploymentReports.receipt >> Ok)
                        |> Option.defaultValue (Error DeploymentError.NotFound)
                })

        member _.PreviewRecovery(id, revision) =
            protect (fun () ->
                task {
                    let! value = repository.Receipt id

                    match value with
                    | None -> return Error DeploymentError.NotFound
                    | Some value when value.Revision <> revision ->
                        return Error DeploymentError.Stale
                    | Some value ->
                        let paths =
                            [ yield!
                                  value.Changes
                                  |> List.filter (fun change ->
                                      change.Phase <> EntryPhase.Restored)
                                  |> List.map (fun change ->
                                      ModConductor.Platform.LogicalPath.display change.Target.Path)
                              yield!
                                  value.Parents
                                  |> List.filter (fun change ->
                                      change.Phase <> EntryPhase.Restored)
                                  |> List.map (fun change ->
                                      ModConductor.Platform.LogicalPath.display change.Target.Path) ]
                            |> List.distinct

                        return
                            Ok
                                { ReceiptId = value.Id
                                  WorkspaceId = value.Context.Roots.Head.Root.Id
                                  Revision = value.Revision
                                  Paths = paths }
                })
