namespace ModConductor.Persistence

open System
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
                        context.Roots.Length <> 1
                        || context.Roots.Head.Root.Id <> sources.Stamp.WorkspaceId)
                then
                    raise (RecoveryException RecoveryError.Stale)

                transaction.Commit()
                sources, context)

        member _.Prepare(id, sources, existing, progress, token) =
            DeploymentPreparation.prepare
                access
                plans
                generations
                recovery
                id
                sources
                existing
                false
                progress
                token

        member _.Retained(id, sources, context, generation, progress, token) =
            task {
                match generation with
                | None ->
                    return!
                        DeploymentPreparation.prepare
                            access
                            plans
                            generations
                            recovery
                            id
                            sources
                            (Some context)
                            true
                            progress
                            token
                | Some generationId ->
                    let! recorded = recovery.Generation(context.Id, generationId)

                    let recorded =
                        recorded
                        |> Option.defaultWith (fun () ->
                            raise (RecoveryException RecoveryError.NotFound))

                    RecoveryFiles.verifyGenerationWith token recorded
                    RecoveryFiles.verifyObservedWith token context recorded

                    return
                        { Context = sources.Context
                          View =
                            { Id = id
                              WorkspaceId = sources.Stamp.WorkspaceId
                              Sources = sources.Stamp
                              Fingerprint = recorded.PlanFingerprint
                              ManagedLinks = recorded.Files.Length
                              CopiedBytes = 0L
                              RequiredBytes = 0L }
                          Switch =
                            { Id = id
                              ContextId = context.Id
                              ContextFingerprint = context.Fingerprint
                              ExpectedRevision = context.Revision
                              Roots = context.Roots
                              Generation = recorded
                              DirectoryBoundaries =
                                context.Links
                                |> List.filter (fun link -> link.Spec.Directory)
                                |> List.choose (fun link ->
                                    recorded.Files
                                    |> List.tryPick (fun file ->
                                        let parts =
                                            ModConductor.Platform.LogicalPath.components
                                                file.Target.Path

                                        let depth =
                                            ModConductor.Platform.LogicalPath.components
                                                link.Target.Path
                                            |> List.length

                                        if parts.Length > depth then
                                            let logical =
                                                ModConductor.Platform.LogicalPath.create (
                                                    List.take depth parts
                                                )
                                                |> Result.defaultWith (fun _ ->
                                                    invalidOp "Invalid boundary.")

                                            let target = { file.Target with Path = logical }

                                            if
                                                (RecoveryFiles.nativeTarget recorded target) = link.Target
                                            then
                                                Some target
                                            else
                                                None
                                        else
                                            None))
                                |> List.distinct
                              PreserveOriginals = context.Originals |> List.map _.Target
                              ExpectedSources = Some sources.Stamp } }
            }

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
