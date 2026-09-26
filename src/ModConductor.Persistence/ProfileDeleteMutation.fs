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
    let private ownedContexts (database: StateDatabase) workspace profile =
        let connection = database.Connection

        database.Enqueue(fun () ->
            use query = Sqlite.command connection null "SELECT id FROM deployment_contexts" []
            use reader = query.ExecuteReader()

            let ids =
                [ while reader.Read() do
                      yield Guid.Parse(reader.GetString 0) ]

            reader.Close()

            ids
            |> List.choose (fun id ->
                DeploymentRows.context connection null id
                |> Option.filter (fun value ->
                    DeploymentContextId.create workspace profile value.Fingerprint = id)
                |> Option.map (fun value -> id, value)))

    let private generations (database: StateDatabase) owned =
        let connection = database.Connection

        database.Enqueue(fun () ->
            owned
            |> List.collect (fun (id, _) ->
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
        let access = services.Access
        let recovery = services.Recovery
        let connection = database.Connection

        task {
            let! root = access.Root workspace

            let workspaceLocation: Location =
                root
                |> Result.map (fun value ->
                    { Path = value.Path
                      Identity = value.Identity })
                |> Result.defaultWith (fun _ ->
                    raise (IOException "The workspace folder is unavailable."))

            let! context =
                database.Enqueue(fun () ->
                    GameContextRows.read connection null database.OwnerId workspace profile)

            let! owned = ownedContexts database workspace profile

            if owned |> List.exists (fun (_, value) -> value.Pending.IsSome) then
                raise (IOException "Complete the pending profile deployment before deletion.")

            match context |> Result.toOption |> Option.bind _.Binding with
            | Some binding ->
                try
                    do!
                        DeploymentPreparation.retireProfile
                            database
                            recovery
                            workspaceLocation
                            workspace
                            profile
                            binding.Evidence
                            token
                with RecoveryException error ->
                    raise (
                        IOException("The profile game folder could not be retired: " + string error)
                    )
            | None -> GameViews.removeOwned workspaceLocation profile

            let! saved = generations database owned
            return owned |> List.map fst, saved
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
                    do! repository.SaveAction prepared
                    return Ok prepared
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

            let! context, action =
                ProfileMutationSupport.claim
                    repository
                    context
                    target
                    (ProfileMutationSupport.actionId context.Id target 1uy)
                    (ProfileDataActionKind.Delete request.Expected)

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
                    let! completed =
                        ProfileDeletion.run prepared repository.SaveAction request.Token notify

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
                raise error
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
                let! ownedContexts, saved =
                    retireGameView services request.Workspace target request.Token

                let rec removeRecords =
                    function
                    | [] -> System.Threading.Tasks.Task.FromResult(Ok())
                    | record :: remaining ->
                        task {
                            let! removed = removePrivateProfile services request target record

                            match removed with
                            | Error error -> return Error error
                            | Ok() -> return! removeRecords remaining
                        }

                let! removed = removeRecords records

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
