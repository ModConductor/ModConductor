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

                    let! prior = repository.Action(expected.WorkspaceId, id)

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
                            task {
                                let! scope =
                                    repository.Read(expected.WorkspaceId, expected.ProfileId)

                                return Ok(scope, Some previous.Kind)
                            }
                        | Some _ -> Task.FromResult(Error ProfileDataError.Stale)
                        | None ->
                            task {
                                let! prepared =
                                    ArchivePolicies.prepareApply
                                        repository
                                        archives
                                        expected
                                        snapshot
                                        token

                                return
                                    prepared
                                    |> Result.map (fun (scope, request) ->
                                        scope,
                                        request |> Option.map ProfileDataActionKind.ApplyArchives)
                            }

                    let! scope, kind = prepared

                    match kind with
                    | None ->
                        let! state = read expected.WorkspaceId expected.ProfileId

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
                            let! context = DataInitialization.context repository scope

                            let! action =
                                repository.Claim(context, initial id context scope.ProfileId kind)

                            let! result =
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
                        let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                        do! check scope expected

                        if scope.Profile |> Option.bind _.ArchiveList |> Option.isNone then
                            return!
                                Error(
                                    ProfileDataError.Invalid
                                        "There are no archive changes to restore."
                                )

                        let! context = DataInitialization.context repository scope

                        let! action =
                            repository.Claim(context, initial id context scope.ProfileId kind)

                        let! result =
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

                        if result.Complete then
                            archives.ForgetObserved expected.ProfileId

                        return result
                })
