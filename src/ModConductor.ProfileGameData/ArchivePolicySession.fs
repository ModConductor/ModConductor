namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfileArchivePolicyOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let archives = context.Archives
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let resultTask = ProfileDataResultTask.resultTask
    let requireIds = ProfileDataSessionContext.requireIds
    let read = ProfileDataSessionContext.read context
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let replay = ProfileDataSessionContext.replay context

    interface IProfileArchivePolicies with
        member _.Scan(workspace, profile, headers, token) =
            protect (fun () ->
                resultTask {
                    do! requireIds [ workspace; profile; headers ]

                    return!
                        ArchivePolicies.scan
                            repository
                            plugins
                            archives
                            workspace
                            profile
                            headers
                            token
                })

        member _.Read(workspace, profile, snapshot, token) =
            protect (fun () ->
                resultTask {
                    do! requireIds [ workspace; profile; snapshot ]

                    return!
                        ArchivePolicies.read repository archives workspace profile snapshot token
                })

        member _.Apply(id, expected, snapshot, progress, token) =
            run expected.WorkspaceId (fun () ->
                resultTask {
                    do!
                        requireIds
                            [ id
                              expected.WorkspaceId
                              expected.ProfileId
                              expected.ContextId
                              snapshot ]

                    let! priorResult = repository.Action(expected.WorkspaceId, id)
                    let! prior = priorResult

                    let! prepared =
                        match prior with
                        | Some previous when
                            match previous.Kind with
                            | ProfileDataActionKind.ApplyArchives request ->
                                previous.ProfileId = expected.ProfileId
                                && previous.ExpectedRevision = expected.Revision
                                && request.SnapshotId = snapshot
                            | _ -> false
                            ->
                            resultTask {
                                let! scopeResult =
                                    repository.Read(expected.WorkspaceId, expected.ProfileId)

                                let! scope = scopeResult

                                return scope, Some previous.Kind
                            }
                        | Some _ -> Task.FromResult(Error ProfileDataError.Stale)
                        | None ->
                            resultTask {
                                let! prepared =
                                    ArchivePolicies.prepareApply
                                        repository
                                        archives
                                        expected
                                        snapshot
                                        token

                                let! scope, request = prepared

                                return
                                    scope,
                                    request |> Option.map ProfileDataActionKind.ApplyArchives
                            }

                    let! scope, kind = prepared

                    match kind with
                    | None ->
                        let! stateResult = read expected.WorkspaceId expected.ProfileId
                        let! state = stateResult

                        return
                            { Id = id
                              State = state
                              Complete = true
                              NoChange = true
                              CompletedFiles = 0
                              Problem = None }
                    | Some kind ->
                        let! replayResult =
                            replay
                                expected.WorkspaceId
                                expected.ProfileId
                                id
                                kind
                                expected.Revision

                        let! replayed = replayResult

                        match replayed with
                        | Some result -> return result
                        | None ->
                            do! check scope expected
                            let! contextResult = DataInitialization.context repository scope
                            let! context = contextResult

                            let! actionResult =
                                repository.Claim(context, initial id context scope.ProfileId kind)

                            let! action = actionResult

                            let! resultResult =
                                execute (
                                    ignore,
                                    None,
                                    scope,
                                    context,
                                    action,
                                    token,
                                    progress,
                                    (fun _ -> Task.FromResult())
                                )

                            let! result = resultResult

                            if result.Complete then
                                archives.Accept snapshot

                            return result
                })

        member _.Restore(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                resultTask {
                    do!
                        requireIds
                            [ id; expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                    let kind = ProfileDataActionKind.RestoreArchives

                    let! replayResult =
                        replay expected.WorkspaceId expected.ProfileId id kind expected.Revision

                    let! replayed = replayResult

                    match replayed with
                    | Some result -> return result
                    | None ->
                        let! scopeResult =
                            repository.Read(expected.WorkspaceId, expected.ProfileId)

                        let! scope = scopeResult
                        do! check scope expected

                        if scope.Profile |> Option.bind _.ArchiveList |> Option.isNone then
                            return!
                                Error(
                                    ProfileDataError.Invalid
                                        "There are no archive changes to restore."
                                )

                        let! contextResult = DataInitialization.context repository scope
                        let! context = contextResult

                        let! actionResult =
                            repository.Claim(context, initial id context scope.ProfileId kind)

                        let! action = actionResult

                        let! resultResult =
                            execute (
                                ignore,
                                None,
                                scope,
                                context,
                                action,
                                token,
                                progress,
                                (fun _ -> Task.FromResult())
                            )

                        let! result = resultResult

                        if result.Complete then
                            archives.ForgetObserved expected.ProfileId

                        return result
                })
