namespace ModConductor.ProfileGameData

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.GameContexts

type internal ProfileDataActionDependencies =
    { Repository: IProfileDataRepository
      Archives: ModConductor.Bethesda.ArchivePolicySession
      Stopped: GameContextState -> unit
      Read: Guid -> Guid -> Task<ProfileDataState> }

module internal ProfileDataActions =
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
        task {
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
                            stopped scope.Game

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

                        let save current =
                            task {
                                do! repository.SaveAction current
                                action <- current
                                do! report current
                            }

                        let! applied = DataEffects.run context action save token checkpoint

                        action <-
                            { applied with
                                Proposed =
                                    applied.Proposed
                                    |> Option.map (fun current ->
                                        { current with
                                            SaveLink = applied.LinkCreated }) }
                    else
                        action <- { action with Prepared = true }

                    let! completedAction, completedProfile =
                        ProfileDataActionPreparation.finishDeletion
                            repository
                            action
                            changed
                            token
                            progress

                    action <- completedAction
                    changed <- completedProfile

                    do! repository.Complete(context, changed, action)
                    action <- { action with Complete = true }
                    do! report action
                    let! state = read scope.WorkspaceId scope.ProfileId

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
                        return result |> Result.mapError (DataErrors.problemMessage >> Choice1Of2)
                    with error ->
                        return Error(Choice2Of2 error)
                }

            match outcome with
            | Ok result -> return result
            | Error failure ->
                let! retained = repository.Action(scope.WorkspaceId, action.Id)
                action <- retained |> Option.defaultValue action

                if action.Complete then
                    match failure with
                    | Choice2Of2 error -> raise error
                    | Choice1Of2 _ ->
                        invalidOp "A completed profile action cannot fail preparation."

                let detail =
                    match failure with
                    | Choice1Of2 detail -> detail
                    | Choice2Of2 error -> DataErrors.message error

                action <- { action with Problem = Some detail }

                do! repository.SaveAction action
                do! report action
                do! repository.Release action.Id
                let! state = read scope.WorkspaceId scope.ProfileId

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
        (read: Guid -> Guid -> Task<ProfileDataState>)
        workspace
        profile
        id
        (kind: ProfileDataActionKind)
        expected
        =
        task {
            let! prior = repository.Action(workspace, id)

            match prior with
            | Some value when
                value.ProfileId <> profile
                || value.Kind <> kind
                || value.ExpectedRevision <> expected
                ->
                return Error ProfileDataError.Stale
            | Some value when value.Complete ->
                let! state = read workspace profile

                return
                    Ok(
                        Some
                            { Id = id
                              State = state
                              Complete = true
                              NoChange = false
                              CompletedFiles = completedFiles value
                              Problem = value.Problem }
                    )
            | _ -> return Ok None
        }
