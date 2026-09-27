namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Threading
open System.Threading.Tasks
open ModConductor.GameContexts
open ModConductor.Platform

type internal ProfileDataActionDependencies =
    { Repository: IProfileDataRepository
      Archives: ModConductor.Bethesda.ArchivePolicySession
      Stopped: GameContextState -> Result<unit, ProfileDataError>
      Read: Guid -> Guid -> Task<Result<ProfileDataState, ProfileDataError>> }

module internal ProfileDataActions =
    let private actionStages (context: ProfileDataContext) (action: ProfileDataActionRecord) =
        let stages =
            [ match action.WorkspaceStage with
              | Some root -> yield context.Storage.Value, "action-" + action.Id.ToString("N"), root
              | None -> ()
              match action.DocumentsStage with
              | Some root -> yield context.OriginalsRoot.Value, action.Id.ToString("N"), root
              | None -> ()
              match action.PluginStage with
              | Some root -> yield context.PluginOriginals.Value, action.Id.ToString("N"), root
              | None -> () ]

        for parent, name, root in stages do
            let path = HostPath.value root.Path

            if
                Path.GetDirectoryName path <> HostPath.value parent.Path
                || Path.GetFileName path <> name
            then
                DataFiles.fail "The prepared action folder changed."

            DataLocations.existing parent root |> ignore

        stages

    let private clearStages stages =
        for _, _, root in stages do
            SaveTrees.clearPrepared root

    let private removeStages stages =
        for parent, name, root in stages do
            use held = HeldDirectory.Open(parent.Path, parent.Identity)
            held.RemoveDirectory(name, root.Identity)

    let initial id (context: ProfileDataContext) profile kind =
        { Id = id
          ContextId = context.Id
          ProfileId = profile
          ExpectedRevision = context.Revision
          Kind = kind
          Deletion = None
          CloneTarget = None
          Prepared = false
          WorkspaceStage = None
          DocumentsStage = None
          PluginStage = None
          ChangedProfile = None
          Files = []
          CompletedFiles = 0
          Link = SaveLinkEffect.Unchanged
          LinkRemoved = false
          LinkCreated = None
          Proposed = context.Applied
          Complete = false
          Problem = None }
        : ProfileDataActionRecord

    let execute
        (dependencies: ProfileDataActionDependencies)
        (
            checkpoint,
            desiredPlugins,
            (scope: ProfileDataScope),
            (context: ProfileDataContext),
            (initial: ProfileDataActionRecord),
            (token: CancellationToken),
            progress,
            (report: ProfileDataActionRecord -> Task<unit>)
        ) =
        ProfileDataResultTask.resultTask {
            let repository = dependencies.Repository
            let archives = dependencies.Archives
            let stopped = dependencies.Stopped
            let read = dependencies.Read

            let mutable context =
                { context with
                    Pending = Some initial.Id }

            let mutable action = { initial with Problem = None }
            let mutable changed = initial.ChangedProfile

            let runAction () =
                ProfileDataResultTask.resultTask {
                    let! incomingResult =
                        ProfileDataActionPreparation.prepareIncoming
                            repository
                            scope
                            context
                            action
                            token
                            progress

                    let! incoming, initialized = incomingResult

                    match initialized with
                    | Some profile -> changed <- Some profile
                    | None -> ()

                    let affectsGame = ProfileDataActionPreparation.affectsGame context action

                    let appliesFiles =
                        affectsGame
                        || match action.Kind with
                           | ProfileDataActionKind.EditConfiguration _ -> true
                           | _ -> false

                    if appliesFiles && action.Deletion.IsNone then
                        if affectsGame then
                            do! stopped scope.Game

                        let! preparation =
                            ProfileDataActionPreparation.prepareEffects
                                repository
                                archives
                                desiredPlugins
                                scope
                                context
                                action
                                incoming
                                token
                                progress

                        let! updatedContext, prepared = preparation
                        context <- updatedContext
                        action <- prepared

                        match action.ChangedProfile with
                        | Some profile -> changed <- Some profile
                        | None -> ()

                        do! report action

                        let save
                            (current: ProfileDataActionRecord)
                            : Task<Result<unit, ProfileDataError>> =
                            ProfileDataResultTask.resultTask {
                                let! saved = repository.SaveAction current
                                do! saved
                                action <- current
                                do! report current
                            }

                        let! appliedResult = DataEffects.run context action save token checkpoint
                        let! applied = appliedResult

                        action <-
                            { applied with
                                Proposed =
                                    applied.Proposed
                                    |> Option.map (fun current ->
                                        { current with
                                            SaveLink = applied.LinkCreated }) }
                    else
                        action <- { action with Prepared = true }

                    let! completion =
                        ProfileDataActionPreparation.finishDeletion
                            repository
                            action
                            changed
                            token
                            progress

                    let! completedAction, completedProfile = completion

                    action <- completedAction
                    changed <- completedProfile

                    let! completed = repository.Complete(context, changed, action)
                    do! completed
                    action <- { action with Complete = true }
                    do! report action
                    let! stateResult = read scope.WorkspaceId scope.ProfileId
                    let! state = stateResult

                    return
                        { Id = action.Id
                          State = state
                          Complete = true
                          NoChange = false
                          CompletedFiles =
                            action.CompletedFiles
                            + (action.Deletion
                               |> Option.map _.CompletedFiles
                               |> Option.defaultValue 0)
                          Problem = None }
                }

            let! outcome =
                task {
                    try
                        let! result = runAction ()
                        return result |> Result.mapError Choice1Of2
                    with error ->
                        return Error(Choice2Of2 error)
                }

            match outcome with
            | Ok result -> return result
            | Error failure ->
                let! retainedResult = repository.Action(scope.WorkspaceId, action.Id)

                match retainedResult with
                | Error error ->
                    do! repository.Release action.Id
                    return! Error error
                | Ok retained -> action <- retained |> Option.defaultValue action

                if action.Complete then
                    match failure with
                    | Choice2Of2 error -> raise error
                    | Choice1Of2 error -> return! Error error

                let detail =
                    match failure with
                    | Choice1Of2 error -> DataErrors.problemMessage error
                    | Choice2Of2 error -> DataErrors.message error

                action <- { action with Problem = Some detail }

                if action.Kind = ProfileDataActionKind.Apply && not action.Prepared then
                    let! discarded =
                        task {
                            try
                                let! contextResult = repository.Context action.ContextId

                                match contextResult with
                                | Error error -> return Error(Choice1Of2 error)
                                | Ok current ->
                                    let stages = actionStages current action
                                    clearStages stages
                                    let! result = repository.Discard action

                                    match result with
                                    | Error error -> return Error(Choice1Of2 error)
                                    | Ok() ->
                                        removeStages stages
                                        return Ok()
                            with error ->
                                return Error(Choice2Of2 error)
                        }

                    match discarded with
                    | Ok() -> ()
                    | Error(Choice1Of2 error) ->
                        do! repository.Release action.Id
                        return! Error error
                    | Error(Choice2Of2 error) ->
                        do! repository.Release action.Id
                        return raise error
                else
                    let! saved = repository.SaveAction action

                    match saved with
                    | Error error ->
                        do! repository.Release action.Id
                        return! Error error
                    | Ok() -> ()

                    do! repository.Release action.Id

                do! report action

                let! stateResult = read scope.WorkspaceId scope.ProfileId
                let! state = stateResult

                return
                    { Id = action.Id
                      State = state
                      Complete = false
                      NoChange = false
                      CompletedFiles =
                        action.CompletedFiles
                        + (action.Deletion |> Option.map _.CompletedFiles |> Option.defaultValue 0)
                      Problem = Some detail }
        }

    let completedFiles (action: ProfileDataActionRecord) =
        action.CompletedFiles
        + (action.Deletion |> Option.map _.CompletedFiles |> Option.defaultValue 0)

    let replay
        (repository: IProfileDataRepository)
        (read: Guid -> Guid -> Task<Result<ProfileDataState, ProfileDataError>>)
        workspace
        profile
        id
        (kind: ProfileDataActionKind)
        expected
        =
        ProfileDataResultTask.resultTask {
            let! priorResult = repository.Action(workspace, id)
            let! prior = priorResult

            match prior with
            | Some value when
                value.ProfileId <> profile
                || value.Kind <> kind
                || value.ExpectedRevision <> expected
                ->
                return! Error ProfileDataError.Stale
            | Some value when value.Complete ->
                let! stateResult = read workspace profile
                let! state = stateResult

                return
                    Some
                        { Id = id
                          State = state
                          Complete = true
                          NoChange = false
                          CompletedFiles = completedFiles value
                          Problem = value.Problem }
            | _ -> return None
        }
