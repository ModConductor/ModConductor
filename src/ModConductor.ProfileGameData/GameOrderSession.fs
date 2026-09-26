namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfilePluginOrderOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let requireIds = ProfileDataSessionContext.requireIds

    interface IProfilePluginOrders with
        member _.PreflightForLaunch(workspace, profile, token) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile ]
                    let! scope = repository.Read(workspace, profile)
                    let! _ = PluginOrders.forLaunch plugins scope token
                    return Ok()
                })

        member _.Read(workspace, profile, headers) =
            protect (fun () ->
                task {
                    let! value = PluginOrders.read repository plugins workspace profile headers
                    return Ok value
                })

        member _.Change(expected, headers, change) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save repository plugins expected headers (Some change)

                    return Ok value
                })

        member _.UseGameOrder(expected, headers) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value = PluginOrders.save repository plugins expected headers None
                    return Ok value
                })

        member _.ApplyExactOrder(expected, headers, names) =
            run expected.WorkspaceId (fun () ->
                task {
                    let! value =
                        PluginOrders.save
                            repository
                            plugins
                            expected
                            headers
                            (Some(ModConductor.Bethesda.PluginOrderChange.Replace names))

                    return Ok value
                })

[<Sealed>]
type internal ProfileArchivePolicyOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let archives = context.Archives
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let requireIds = ProfileDataSessionContext.requireIds
    let read = ProfileDataSessionContext.read context
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let replay = ProfileDataSessionContext.replay context

    interface IProfileArchivePolicies with
        member _.Scan(workspace, profile, headers, token) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile; headers ]

                    let! value =
                        ArchivePolicies.scan
                            repository
                            plugins
                            archives
                            workspace
                            profile
                            headers
                            token

                    return Ok value
                })

        member _.Read(workspace, profile, snapshot, token) =
            protect (fun () ->
                task {
                    requireIds [ workspace; profile; snapshot ]

                    let! value =
                        ArchivePolicies.read repository archives workspace profile snapshot token

                    return Ok value
                })

        member _.Apply(id, expected, snapshot, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    requireIds
                        [ id
                          expected.WorkspaceId
                          expected.ProfileId
                          expected.ContextId
                          snapshot ]

                    let! prior = repository.Action(expected.WorkspaceId, id)

                    let! scope, kind =
                        match prior with
                        | Some previous ->
                            match previous.Kind with
                            | ProfileDataActionKind.ApplyArchives request when
                                previous.ProfileId = expected.ProfileId
                                && previous.ExpectedRevision = expected.Revision
                                && request.SnapshotId = snapshot
                                ->
                                task {
                                    let! scope =
                                        repository.Read(expected.WorkspaceId, expected.ProfileId)

                                    return scope, Some previous.Kind
                                }
                            | _ -> raise (ProfileDataException ProfileDataError.Stale)
                        | None ->
                            task {
                                let! scope, request =
                                    ArchivePolicies.prepareApply
                                        repository
                                        archives
                                        expected
                                        snapshot
                                        token

                                return
                                    scope,
                                    request |> Option.map ProfileDataActionKind.ApplyArchives
                            }

                    match kind with
                    | None ->
                        let! state = read expected.WorkspaceId expected.ProfileId

                        return
                            Ok
                                { Id = id
                                  State = state
                                  Complete = true
                                  NoChange = true
                                  CompletedFiles = 0
                                  Problem = None }
                    | Some kind ->
                        let! replayed =
                            replay
                                expected.WorkspaceId
                                expected.ProfileId
                                id
                                kind
                                expected.Revision

                        match replayed with
                        | Some result -> return Ok result
                        | None ->
                            check scope expected
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

                            return Ok result
                })

        member _.Restore(id, expected, progress, token) =
            run expected.WorkspaceId (fun () ->
                task {
                    requireIds [ id; expected.WorkspaceId; expected.ProfileId; expected.ContextId ]
                    let kind = ProfileDataActionKind.RestoreArchives

                    let! replayed =
                        replay expected.WorkspaceId expected.ProfileId id kind expected.Revision

                    match replayed with
                    | Some result -> return Ok result
                    | None ->
                        let! scope = repository.Read(expected.WorkspaceId, expected.ProfileId)
                        check scope expected

                        if scope.Profile |> Option.bind _.ArchiveList |> Option.isNone then
                            raise (
                                ProfileDataException(
                                    ProfileDataError.Invalid
                                        "There are no archive changes to restore."
                                )
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

                        return Ok result
                })
