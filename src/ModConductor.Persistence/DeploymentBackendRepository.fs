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
                                (ModConductor.Deployment.DeploymentContextId.fingerprint
                                    binding.Evidence)

                        DeploymentRows.context database.Connection transaction id)

                if
                    context
                    |> Option.exists (fun context ->
                        let evidence = sources.Context.Binding.Value.Evidence

                        let matches id path identity =
                            context.Roots
                            |> List.tryFind (fun root -> root.Root.Id = id)
                            |> Option.exists (fun root ->
                                HostPath.value root.Directory.Path = path
                                && root.Directory.Identity = identity)

                        let dataMatches =
                            match evidence.DataPath, evidence.DataIdentity with
                            | Some path, Some identity ->
                                matches sources.Stamp.WorkspaceId path identity
                            | _ -> false

                        let gameMatches =
                            if context.Roots.Length = 1 then
                                true
                            else
                                ComponentRoots.gameRootId sources.Stamp.WorkspaceId evidence
                                |> Result.exists (fun id ->
                                    matches id evidence.RootPath evidence.RootIdentity.Value)

                        not dataMatches
                        || not gameMatches
                        || (context.Roots.Length <> 1 && context.Roots.Length <> 2))
                then
                    raise (RecoveryException RecoveryError.Stale)

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

        member _.Context workspace =
            database.Enqueue(fun () ->
                GameContextRows.read database.Connection null database.OwnerId workspace
                |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.NotFound)))

        member _.Start(request, token) =
            generations.Start(request, [], cancellation = token)

        member _.Run(id, revision, restore, token, checkpoint) =
            generations.Run(id, revision, restore, token, checkpoint, [])

        member _.Receipt id = recovery.Read id
