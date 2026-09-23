namespace ModConductor.Persistence

open System
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery
open ModConductor.Deployment

type internal DeploymentBackendRepository
    (
        database: StateDatabase,
        access: LibraryAccess,
        plans: FilePlanSession,
        recovery: Recovery,
        generations: DeploymentGenerationStore
    ) =
    interface IDeploymentRepository with
        member _.RunnableRoot(workspace, profile) =
            task {
                let! root = access.Root workspace

                return
                    root
                    |> Result.map (fun value -> GameViews.rootPath value.Path profile)
                    |> Result.defaultWith (fun _ ->
                        raise (RecoveryException RecoveryError.NotFound))
            }

        member _.Read profile =
            database.Enqueue(fun () ->
                use transaction = database.Connection.BeginTransaction(deferred = true)

                let sources =
                    FilePlanRows.read database.Connection transaction database.OwnerId profile
                    |> Result.defaultWith (fun _ ->
                        raise (RecoveryException RecoveryError.NotFound))

                let context =
                    sources.Context.Binding
                    |> Option.bind (fun binding ->
                        let id =
                            DeploymentContextId.create
                                sources.Stamp.WorkspaceId
                                sources.Stamp.ProfileId
                                (ModConductor.Deployment.DeploymentContextId.fingerprint
                                    binding.Evidence)

                        DeploymentRows.context database.Connection transaction id)

                transaction.Commit()
                sources, context)

        member _.Prepare(id, sources, existing, progress, token) =
            DeploymentPreparation.prepare
                database
                access
                plans
                generations
                recovery
                id
                sources
                existing
                false
                None
                None
                progress
                token

        member _.Retained(id, sources, context, generation, progress, token) =
            task {
                match generation with
                | None ->
                    return!
                        DeploymentPreparation.prepare
                            database
                            access
                            plans
                            generations
                            recovery
                            id
                            sources
                            (Some context)
                            true
                            None
                            None
                            progress
                            token
                | Some generationId ->
                    let! unavailable =
                        database.Enqueue(fun () ->
                            MaintenanceClaims.unavailable
                                database.Connection
                                null
                                context.Id
                                generationId)

                    unavailable
                    |> Option.iter (fun reason ->
                        raise (RecoveryException(RecoveryError.Unavailable reason)))

                    let! recorded = recovery.Generation(context.Id, generationId)

                    let recorded =
                        recorded
                        |> Option.defaultWith (fun () ->
                            raise (RecoveryException RecoveryError.NotFound))

                    let provenance =
                        recorded.Provenance
                        |> Option.defaultWith (fun () ->
                            raise (
                                RecoveryException(
                                    RecoveryError.Unavailable
                                        "This saved deployment has no recorded profile order and file visibility. Its files remain retained, but it cannot be prepared for restoration."
                                )
                            ))

                    return!
                        DeploymentPreparation.prepare
                            database
                            access
                            plans
                            generations
                            recovery
                            id
                            sources
                            (Some context)
                            provenance.Profile.IsNone
                            provenance.Profile
                            (Some generationId)
                            progress
                            token
            }

        member _.Saved(context, active, before) =
            database.Enqueue(fun () ->
                SavedDeployments.page database.Connection context active before)

        member _.SavedOne(context, id) =
            database.Enqueue(fun () ->
                DeploymentRows.generation database.Connection null context id
                |> Option.map (
                    SavedDeployments.describe
                        (Some id)
                        (MaintenanceClaims.unavailable database.Connection null context id)
                ))

        member _.Current stamp =
            database.Enqueue(fun () ->
                FilePlanRows.stamp database.Connection null stamp.ProfileId = Some stamp)

        member _.Context(workspace, profile) =
            database.Enqueue(fun () ->
                GameContextRows.read database.Connection null database.OwnerId workspace profile
                |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.NotFound)))

        member _.ContextForDeployment(workspace, context) =
            database.Enqueue(fun () ->
                use query =
                    Sqlite.command
                        database.Connection
                        null
                        "SELECT id FROM profiles WHERE workspace_id=$workspace ORDER BY id"
                        [ "$workspace", box (string workspace) ]

                use reader = query.ExecuteReader()

                let profiles =
                    [ while reader.Read() do
                          yield Guid.Parse(reader.GetString 0) ]

                reader.Close()

                profiles
                |> List.choose (fun profile ->
                    GameContextRows.read
                        database.Connection
                        null
                        database.OwnerId
                        workspace
                        profile
                    |> Result.toOption
                    |> Option.filter (fun state ->
                        state.Binding
                        |> Option.exists (fun binding ->
                            DeploymentContextId.create
                                workspace
                                profile
                                (DeploymentContextId.fingerprint binding.Evidence) = context)))
                |> function
                    | [ state ] -> state
                    | _ -> raise (RecoveryException RecoveryError.NotFound))

        member _.Start(prepared, token) =
            task {
                let! scope =
                    (ProfileDataRepository(database, access) :> ModConductor.ProfileGameData.IProfileDataRepository)
                        .Read(prepared.View.WorkspaceId, prepared.View.Sources.ProfileId)

                if
                    (scope.Profile |> Option.map _.Revision |> Option.defaultValue 0L)
                    <> prepared.PluginSelectionRevision
                then
                    return Error RecoveryError.Stale
                else
                    return! generations.Start(prepared, [], cancellation = token)
            }

        member _.Run(id, revision, restore, token, checkpoint) =
            generations.Run(id, revision, restore, token, checkpoint, [])

        member _.Receipt id = recovery.Read id
