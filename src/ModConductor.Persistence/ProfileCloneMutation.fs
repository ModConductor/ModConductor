namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.Deployment
open ModConductor.ProfileGameData
open ModConductor.Workspaces

module internal ProfileCloneMutation =
    let private clearClone (context: ProfileDataContext) (action: ProfileDataActionRecord) =
        let remove (parent: DataRoot) (root: DataRoot) =
            SaveTrees.clearPrepared root
            use held = HeldDirectory.Open(parent.Path, parent.Identity)
            held.RemoveDirectory(Path.GetFileName(HostPath.value root.Path), root.Identity)

        action.CloneTarget
        |> Option.bind _.Root
        |> Option.iter (remove context.Storage.Value)

        action.WorkspaceStage |> Option.iter (remove context.Storage.Value)

        match context.OriginalsRoot, action.DocumentsStage with
        | Some parent, Some root -> remove parent root
        | _ -> ()

    let private validateActiveContext
        (services: ProfileMutationServices)
        workspace
        source
        (context: ProfileDataContext)
        =
        task {
            if context.Applied |> Option.exists (fun active -> active.ProfileId = source) then
                let! scopeResult = services.Repository.Read(workspace, source)

                match scopeResult with
                | Error error -> return Error error
                | Ok scope ->
                    if
                        (DataLocations.documents scope.Game).Identity <> context.Documents.Identity
                    then
                        return
                            Error(
                                ProfileDataError.Unavailable
                                    "Restore the profile in its previous installation before cloning it."
                            )

                    GameProcesses.validate scope.Game |> ignore
                    return Ok()
            else
                return Ok()
        }

    let private saveCopy
        (services: ProfileMutationServices)
        connection
        transaction
        (context: ProfileDataContext, action: ProfileDataActionRecord, copy: PrivateProfileData)
        =
        match ProfileDataRows.context connection transaction context.Id with
        | None -> Error ProfileDataError.NotFound
        | Some current when
            current.Pending <> Some action.Id || current.Revision <> action.ExpectedRevision
            ->
            Error ProfileDataError.Stale
        | Some _ ->
            ProfileDataRows.saveProfile connection transaction context.Id copy

            ProfileDataRows.saveContext
                connection
                transaction
                { context with
                    Pending = None
                    Revision = context.Revision + 1L }

            ProfileDataRows.saveAction
                connection
                transaction
                services.Database.OwnerId
                false
                { action with
                    Complete = true
                    Problem = None }

            Ok()

    let private commit
        (services: ProfileMutationServices)
        (request: ProfileMutationRequest)
        completed
        =
        let connection = services.Database.Connection

        services.Database.Enqueue(fun () ->
            use transaction = connection.BeginTransaction(deferred = false)

            let result =
                WorkspaceProfiles.editIn
                    connection
                    transaction
                    request.Workspace
                    request.Expected
                    request.Command

            let saved =
                match result with
                | Error _ -> Ok()
                | Ok _ ->
                    completed
                    |> Seq.fold
                        (fun state copy ->
                            state
                            |> Result.bind (fun () ->
                                saveCopy services connection transaction copy))
                        (Ok())

            match result, saved with
            | Ok _, Ok() ->
                request.BeforeCommit()
                transaction.Commit()
                result |> Result.mapError Choice1Of2
            | Error error, _ -> Error(Choice1Of2 error)
            | _, Error error -> Error(Choice2Of2 error))

    let private cancelClaim
        (services: ProfileMutationServices)
        (context: ProfileDataContext)
        (action: ProfileDataActionRecord)
        =
        task {
            let database = services.Database
            let connection = database.Connection

            let! current =
                database.Enqueue(fun () ->
                    ProfileDataRows.context connection null context.Id |> Option.get)

            clearClone current action

            do!
                database.Enqueue(fun () ->
                    use transaction = connection.BeginTransaction(deferred = false)

                    let current =
                        ProfileDataRows.context connection transaction context.Id |> Option.get

                    ProfileDataRows.saveContext
                        connection
                        transaction
                        { current with
                            Pending = None
                            Revision = current.Revision + 1L }

                    ProfileDataRows.saveAction
                        connection
                        transaction
                        database.OwnerId
                        false
                        { action with
                            Complete = true
                            Problem = Some "The profile copy was cancelled." }

                    transaction.Commit())
        }

    let private releaseClaims (services: ProfileMutationServices) claimed =
        task {
            for _, id in claimed do
                do! services.Repository.Release id
        }

    let private handleFailure
        (services: ProfileMutationServices)
        workspace
        (claimed: (ProfileDataContext * Guid) seq)
        (error: exn)
        =
        task {
            for context, id in claimed do
                let! retained = services.Repository.Action(workspace, id)

                match retained with
                | Ok(Some action) when (error :? OperationCanceledException) ->
                    do! cancelClaim services context action
                | _ -> do! services.Repository.Release id
        }

    let private workspaceError =
        function
        | ProfileDataError.Busy -> WorkspaceError.Busy
        | ProfileDataError.Invalid detail
        | ProfileDataError.Unavailable detail
        | ProfileDataError.Conflict detail -> WorkspaceError.ProfileData detail
        | error -> WorkspaceError.ProfileData(DataErrors.problemMessage error)

    let run
        (services: ProfileMutationServices)
        (request: ProfileMutationRequest)
        source
        (target: Profile)
        =
        task {
            let! records = ProfileMutationSupport.contexts services.Database source

            let completed =
                ResizeArray<ProfileDataContext * ProfileDataActionRecord * PrivateProfileData>()

            let claimed = ResizeArray<ProfileDataContext * Guid>()

            let prepareOne (context, profile) =
                task {
                    request.Token.ThrowIfCancellationRequested()
                    let! valid = validateActiveContext services request.Workspace source context

                    match valid with
                    | Error error -> return Error error
                    | Ok() ->
                        let! claim =
                            ProfileMutationSupport.claim
                                services.Repository
                                context
                                source
                                (ProfileMutationSupport.actionId context.Id target.Id 0uy)
                                (ProfileDataActionKind.Clone(
                                    target.Id,
                                    target.Name,
                                    request.Expected
                                ))

                        match claim with
                        | Error error -> return Error error
                        | Ok(context, action) ->
                            claimed.Add(context, action.Id)

                            let notify (value: ProfileDataProgress) =
                                request.Progress
                                    { Files = value.Files
                                      Bytes = value.Bytes }

                            return!
                                ProfileCloning.prepare
                                    services.Repository
                                    context
                                    profile
                                    action
                                    request.Token
                                    notify
                                    request.CaptureCheckpoint
                }

            let rec prepareAll =
                function
                | [] -> System.Threading.Tasks.Task.FromResult(Ok())
                | item :: remaining ->
                    task {
                        let! prepared = prepareOne item

                        match prepared with
                        | Error error -> return Error error
                        | Ok copy ->
                            completed.Add copy
                            return! prepareAll remaining
                    }

            try
                let! prepared = prepareAll records

                match prepared with
                | Error error ->
                    do! releaseClaims services claimed
                    return Error(workspaceError error)
                | Ok() -> ()

                request.Token.ThrowIfCancellationRequested()
                let! committed = commit services request completed

                if Result.isError committed then
                    do! releaseClaims services claimed

                return
                    committed
                    |> Result.mapError (function
                        | Choice1Of2 error -> error
                        | Choice2Of2 error -> workspaceError error)
            with error ->
                do! handleFailure services request.Workspace claimed error
                return raise error
        }
