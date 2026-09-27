namespace ModConductor.ProfileGameData

open System
open System.Threading.Tasks

[<Sealed>]
type internal ProfileDataLifecycleOperations
    (context: ProfileDataSessionContext, runtime: ProfileDataSessionRuntime) =
    let repository = context.Repository
    let plugins = context.Plugins
    let protect action = runtime.Protect action
    let run workspace action = runtime.Run(workspace, action)
    let resultTask = ProfileDataResultTask.resultTask
    let requireIds = ProfileDataSessionContext.requireIds
    let read = ProfileDataSessionContext.read context
    let check = ProfileDataProjection.check
    let initial = ProfileDataActions.initial
    let execute = ProfileDataSessionContext.execute context
    let completedFiles = ProfileDataActions.completedFiles
    let replay = ProfileDataSessionContext.replay context

    let restore id (expected: ProfileDataRef) token checkpoint =
        run expected.WorkspaceId (fun () ->
            resultTask {
                do! requireIds [ id; expected.WorkspaceId; expected.ProfileId; expected.ContextId ]

                let! previousResult =
                    replay
                        expected.WorkspaceId
                        expected.ProfileId
                        id
                        ProfileDataActionKind.Restore
                        expected.Revision

                let! previous = previousResult

                match previous with
                | Some result -> return result
                | None ->
                    let! scopeResult = repository.Read(expected.WorkspaceId, expected.ProfileId)
                    let! scope = scopeResult
                    do! check scope expected

                    match
                        scope.Context |> Option.bind _.PluginRoot,
                        scope.Context |> Option.bind _.PluginObserved
                    with
                    | Some root, Some expectedFile ->
                        let _, file, _ = PluginInputs.readFile root PluginInputs.fileName token

                        if file <> expectedFile then
                            return!
                                Error(
                                    ProfileDataError.Conflict
                                        "The game plugin list changed. Use game order before restoring it."
                                )
                    | _ -> ()

                    let! contextResult = DataInitialization.context repository scope
                    let! context = contextResult

                    let! actionResult =
                        repository.Claim(
                            context,
                            initial id context scope.ProfileId ProfileDataActionKind.Restore
                        )

                    let! action = actionResult

                    let! resultResult =
                        execute (
                            checkpoint,
                            None,
                            scope,
                            context,
                            action,
                            token,
                            ignore,
                            (fun _ -> Task.FromResult())
                        )

                    let! result = resultResult
                    return result
            })

    member _.Revision(workspace, profile) =
        protect (fun () ->
            resultTask {
                do! requireIds [ workspace; profile ]
                let! exists = repository.HasData workspace

                if not exists then
                    return 0L
                else
                    let! scopeResult = repository.Read(workspace, profile)
                    let! scope = scopeResult
                    return scope.Context |> Option.map _.Revision |> Option.defaultValue 0L
            })

    member _.ApplyForLaunchAtCheckpoint
        (
            id,
            workspace,
            profile,
            expected,
            token,
            report: ProfileDataApplication -> Task<unit>,
            checkpoint
        ) =
        protect (fun () ->
            resultTask {
                do! requireIds [ id; workspace; profile ]
                let! scopeResult = repository.Read(workspace, profile)
                let! scope = scopeResult
                let revision = scope.Context |> Option.map _.Revision |> Option.defaultValue 0L

                if revision <> expected then
                    return! Error ProfileDataError.Stale
                else
                    let! desiredPluginsResult = PluginOrders.forLaunch plugins scope token
                    let! desiredPlugins = desiredPluginsResult

                    let needed =
                        (scope.Context |> Option.bind _.Applied).IsSome
                        || (scope.Profile
                            |> Option.exists (fun value ->
                                value.Options.Settings
                                || value.Options.Saves
                                || value.PluginOrder.IsSome))

                    if not needed then
                        return None
                    else
                        let! contextResult = DataInitialization.context repository scope
                        let! context = contextResult

                        let! actionResult =
                            repository.Claim(
                                context,
                                initial id context profile ProfileDataActionKind.Apply
                            )

                        let! action = actionResult

                        let reportAction (value: ProfileDataActionRecord) =
                            report
                                { ReceiptId = value.Id
                                  Revision = expected
                                  CompletedFiles = value.CompletedFiles
                                  Complete = value.Complete
                                  Problem = value.Problem }

                        let! resultResult =
                            execute (
                                checkpoint,
                                desiredPlugins,
                                scope,
                                context,
                                action,
                                token,
                                ignore,
                                reportAction
                            )

                        let! result = resultResult

                        return
                            Some
                                { ReceiptId = result.Id
                                  Revision = expected
                                  CompletedFiles = result.CompletedFiles
                                  Complete = result.Complete
                                  Problem = result.Problem }
            })

    member _.Edit(request: ProfileDataEdit, progress, token) =
        run request.Expected.WorkspaceId (fun () ->
            resultTask {
                do!
                    requireIds
                        [ request.Id
                          request.Expected.WorkspaceId
                          request.Expected.ProfileId
                          request.Expected.ContextId ]

                let kind =
                    ProfileDataActionKind.Edit(
                        request.Options,
                        request.InitialSaves,
                        request.DisabledFiles
                    )

                let! previousResult =
                    replay
                        request.Expected.WorkspaceId
                        request.Expected.ProfileId
                        request.Id
                        kind
                        request.Expected.Revision

                let! previous = previousResult

                match previous with
                | Some result -> return result
                | None ->
                    let! scopeResult =
                        repository.Read(request.Expected.WorkspaceId, request.Expected.ProfileId)

                    let! scope = scopeResult

                    do! check scope request.Expected
                    let! contextResult = DataInitialization.context repository scope
                    let! context = contextResult

                    let! actionResult =
                        repository.Claim(context, initial request.Id context scope.ProfileId kind)

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
                    return result
            })

    member _.RestoreAtCheckpoint(id, expected, token, checkpoint) =
        restore id expected token checkpoint

    member _.Restore(id, expected, token) = restore id expected token ignore

    member _.Resume(workspace, id, token) =
        run workspace (fun () ->
            resultTask {
                do! requireIds [ workspace; id ]
                let! previousResult = repository.Action(workspace, id)
                let! previous = previousResult

                let! previous =
                    match previous with
                    | Some value -> Ok value
                    | None -> Error ProfileDataError.NotFound

                match previous.Kind with
                | ProfileDataActionKind.Clone _
                | ProfileDataActionKind.Delete _ ->
                    return!
                        Error(
                            ProfileDataError.Invalid
                                "Continue this action from the profile controls."
                        )
                | _ -> ()

                if previous.Complete then
                    let! stateResult = read workspace previous.ProfileId
                    let! state = stateResult

                    return
                        { Id = id
                          State = state
                          Complete = true
                          NoChange = false
                          CompletedFiles = completedFiles previous
                          Problem = previous.Problem }
                else
                    let! scopeResult = repository.Read(workspace, previous.ProfileId)
                    let! scope = scopeResult

                    ConfigurationRecovery.checkResume previous token

                    let! context =
                        match scope.Context with
                        | Some value -> Ok value
                        | None -> Error ProfileDataError.NotFound

                    let! desiredPluginsResult =
                        if
                            previous.Kind = ProfileDataActionKind.Apply && not previous.Prepared
                        then
                            PluginOrders.forLaunch plugins scope token
                        else
                            Task.FromResult(Ok None)

                    let! desiredPlugins = desiredPluginsResult

                    let! actionResult = repository.Claim(context, previous)
                    let! action = actionResult

                    let! resultResult =
                        execute (
                            ignore,
                            desiredPlugins,
                            scope,
                            context,
                            action,
                            token,
                            ignore,
                            (fun _ -> Task.FromResult())
                        )

                    let! result = resultResult
                    return result
            })
