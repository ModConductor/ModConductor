namespace ModConductor.Persistence

open System
open System.IO
open System.Threading
open ModConductor.ProfileGameData
open ModConductor.Platform
open ModConductor.Deployment
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations
open ModConductor.Workspaces

module internal ProfileDeleteMutation =
    let private generations (database: StateDatabase) owned =
        let connection = database.Connection

        database.Enqueue(fun () ->
            owned
            |> List.collect (fun (context: Context) ->
                let id = context.Id

                use query =
                    Sqlite.command
                        connection
                        null
                        "SELECT id FROM deployment_generations WHERE context_id=$context"
                        [ "$context", box (string id) ]

                use reader = query.ExecuteReader()

                let ids =
                    [ while reader.Read() do
                          yield Guid.Parse(reader.GetString 0) ]

                reader.Close()
                ids |> List.choose (DeploymentRows.generation connection null id)))

    let private retireGameView (services: ProfileMutationServices) workspace profile token =
        let database = services.Database

        task {
            let! root = services.Access.Root workspace

            let! game =
                database.Enqueue(fun () ->
                    GameContextRows.read
                        database.Connection
                        null
                        database.OwnerId
                        workspace
                        profile)

            let! owned = DeploymentRemoval.ownedContexts database workspace profile
            let! ready = DeploymentRemoval.idle database workspace owned

            match ready, root with
            | Error RecoveryError.Busy, _ -> return Error WorkspaceError.Busy
            | Error error, _ -> return Error(WorkspaceError.ProfileData(string error))
            | _, Error _ ->
                return Error(WorkspaceError.ProfileData "The workspace folder is unavailable.")
            | Ok(), Ok root ->
                let workspaceLocation: Location =
                    { Path = root.Path
                      Identity = root.Identity }

                let! stopped =
                    match game with
                    | Error _ when owned.IsEmpty -> System.Threading.Tasks.Task.FromResult(Ok())
                    | Error _ ->
                        System.Threading.Tasks.Task.FromResult(
                            Error "The deployed game's installation is unavailable."
                        )
                    | Ok game ->
                        System.Threading.Tasks.Task.Run(fun () ->
                            DeploymentRemoval.stopped
                                game
                                (GameViews.rootPath root.Path profile)
                                owned)

                match stopped with
                | Error detail -> return Error(WorkspaceError.ProfileData detail)
                | Ok() ->
                    do! DeploymentRemoval.removeContexts database owned token
                    GameViews.removeOwned workspaceLocation profile
                    let! saved = generations database owned
                    return Ok(owned |> List.map _.Id, saved)
        }

    let private prepareDeletion
        (repository: IProfileDataRepository)
        (context: ProfileDataContext)
        (profile: PrivateProfileData)
        (action: ProfileDataActionRecord)
        token
        notify
        =
        task {
            match action.Deletion with
            | Some _ -> return Ok action
            | None ->
                let deletion =
                    match profile.Root with
                    | None -> Ok(ProfileDeletion.prepare [] [])
                    | Some root ->
                        SaveTrees.observe root token notify
                        |> Result.map (fun tree ->
                            ProfileDeletion.prepare
                                [ tree ]
                                [ { Parent = context.Storage.Value
                                    Name = Path.GetFileName(HostPath.value root.Path)
                                    Identity = root.Identity } ])

                match deletion with
                | Error error -> return Error error
                | Ok deletion ->
                    let prepared = { action with Deletion = Some deletion }
                    let! saved = repository.SaveAction prepared
                    return saved |> Result.map (fun () -> prepared)
        }

    let private removePrivateProfile
        (services: ProfileMutationServices)
        (request: ProfileMutationRequest)
        target
        (context: ProfileDataContext, profile: PrivateProfileData)
        =
        task {
            let database = services.Database
            let repository = services.Repository
            let connection = database.Connection

            let! claim =
                ProfileMutationSupport.claim
                    repository
                    context
                    target
                    (ProfileMutationSupport.actionId context.Id target 1uy)
                    (ProfileDataActionKind.Delete request.Expected)

            match claim with
            | Error error -> return Error error
            | Ok(context, action) ->
                try
                    let notify (value: ProfileDataProgress) =
                        request.Progress
                            { Files = value.Files
                              Bytes = value.Bytes }

                    let! prepared =
                        prepareDeletion repository context profile action request.Token notify

                    match prepared with
                    | Error error ->
                        do! repository.Release action.Id
                        return Error error
                    | Ok prepared ->
                        let! completedResult =
                            ProfileDeletion.run prepared repository.SaveAction request.Token notify

                        match completedResult with
                        | Error error ->
                            do! repository.Release action.Id
                            return Error error
                        | Ok completed ->
                            do!
                                database.Enqueue(fun () ->
                                    use transaction = connection.BeginTransaction(deferred = false)

                                    Sqlite.execute
                                        connection
                                        transaction
                                        "DELETE FROM profile_data_profiles WHERE context_id=$context AND profile_id=$profile"
                                        [ "$context", box (string context.Id)
                                          "$profile", box (string target) ]

                                    ProfileDataRows.saveContext
                                        connection
                                        transaction
                                        { context with
                                            Pending = None
                                            Revision = context.Revision + 1L }

                                    ProfileDataRows.saveAction
                                        connection
                                        transaction
                                        database.OwnerId
                                        false
                                        { completed with Complete = true }

                                    transaction.Commit())

                            return Ok()
                with error ->
                    do! repository.Release action.Id
                    return raise error
        }

    let private commitDeletion
        (services: ProfileMutationServices)
        (request: ProfileMutationRequest)
        ownedContexts
        fnisOutput
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

            if Result.isOk result then
                for contextId in ownedContexts do
                    let args = [ "$context", box (string contextId) ]

                    Sqlite.execute
                        connection
                        transaction
                        "DELETE FROM deployment_receipts WHERE context_id=$context"
                        args

                    Sqlite.execute
                        connection
                        transaction
                        "DELETE FROM deployment_generations WHERE context_id=$context"
                        args

                    Sqlite.execute
                        connection
                        transaction
                        "DELETE FROM deployment_contexts WHERE id=$context"
                        args

                fnisOutput
                |> Option.iter (FnisOutputCleanup.removeProfileRows connection transaction)

                request.BeforeCommit()
                transaction.Commit()

            result)

    let run (services: ProfileMutationServices) (request: ProfileMutationRequest) target =
        task {
            let! records = ProfileMutationSupport.contexts services.Database target

            let active =
                records
                |> List.exists (fun (context, _) ->
                    context.Applied |> Option.exists (fun applied -> applied.ProfileId = target))

            if active then
                return
                    Error(
                        WorkspaceError.ProfileData
                            "Restore global settings and saves before deleting this profile."
                    )
            else
                let! retirement = retireGameView services request.Workspace target request.Token

                match retirement with
                | Error error -> return Error error
                | Ok(ownedContexts, saved) ->
                    let mutable removed: Result<unit, ProfileDataError> = Ok()

                    for record in records do
                        if Result.isOk removed then
                            let! next = removePrivateProfile services request target record
                            removed <- next

                    match removed with
                    | Error error ->
                        return Error(WorkspaceError.ProfileData(DataErrors.problemMessage error))
                    | Ok() ->
                        for generation in saved do
                            GenerationFiles.removeOwned generation

                        let! fnisOutput =
                            FnisOutputCleanup.removeProfileFiles
                                services.Database
                                services.Access
                                request.Workspace
                                target

                        return! commitDeletion services request ownedContexts fnisOutput
        }
