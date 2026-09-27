namespace ModConductor.Persistence

open System
open System.Threading
open System.Threading.Tasks
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentGenerations
open ModConductor.Deployment

module internal DeploymentPreparation =
    let refusalMessage error = (RecoveryException error).Message

    let profileError =
        function
        | ModConductor.ProfileGameData.ProfileDataError.NotFound -> RecoveryError.NotFound
        | ModConductor.ProfileGameData.ProfileDataError.Busy -> RecoveryError.Busy
        | ModConductor.ProfileGameData.ProfileDataError.Stale -> RecoveryError.Stale
        | ModConductor.ProfileGameData.ProfileDataError.Cancelled -> RecoveryError.Cancelled
        | ModConductor.ProfileGameData.ProfileDataError.Invalid detail
        | ModConductor.ProfileGameData.ProfileDataError.Unavailable detail
        | ModConductor.ProfileGameData.ProfileDataError.Conflict detail ->
            RecoveryError.Unavailable detail

    let ownedLinkCovers policy owned target =
        DeploymentTargetProjection.ownedLinkCovers policy owned target

    let retireProfile database recovery workspace workspaceId profileId evidence token =
        DeploymentRetirement.retireProfile
            database
            recovery
            workspace
            workspaceId
            profileId
            evidence
            token

    let private prepareWith
        componentMode
        recordProfile
        candidate
        (components: ReviewedComponent list)

        (database: StateDatabase)
        (access: LibraryAccess)
        (plans: FilePlanSession)
        (generations: DeploymentGenerationStore)
        (recovery: Recovery)
        (id: Guid)
        (sources: PlanSources)
        existing
        gameFolderOnly
        retainedProfile
        retainedGeneration
        progress
        token
        =
        task {
            let! components =
                ComponentRoutes.read
                    database
                    sources
                    existing
                    components
                    retainedProfile
                    retainedGeneration

            let duplicateComponent =
                components
                |> List.groupBy _.Mod.ModId
                |> List.exists (fun (_, values) -> values.Length <> 1)

            let duplicateWritable =
                components
                |> List.collect _.Writable
                |> List.groupBy _.Id
                |> List.exists (fun (_, values) -> values.Length <> 1)

            if duplicateComponent || duplicateWritable then
                raise (RecoveryException RecoveryError.InvalidPlan)

            let evidence = GameProcesses.validateContext sources.Context

            let acquireError =
                function
                | FilePlanError.Cancelled -> raise (OperationCanceledException())
                | FilePlanError.Busy -> RecoveryError.Busy
                | FilePlanError.Blocked
                | FilePlanError.InvalidCopy
                | FilePlanError.Unsupported _
                | FilePlanError.InvalidEdit _ -> RecoveryError.InvalidPlan
                | FilePlanError.NotFound -> RecoveryError.NotFound
                | FilePlanError.LimitExceeded _ -> RecoveryError.Limit
                | FilePlanError.ContextUnavailable text
                | FilePlanError.FileUnavailable text -> RecoveryError.Unavailable text
                | FilePlanError.Expired
                | FilePlanError.Stale -> RecoveryError.Stale

            let withWorkspace (workspace: WorkspaceRoot) =
                task {
                    let workspaceLocation: Location =
                        { Path = workspace.Path
                          Identity = workspace.Identity }

                    GameProcesses.checkWithRoot
                        evidence
                        (Some(GameViews.rootPath workspace.Path sources.Stamp.ProfileId))

                    do!
                        DeploymentRetirement.clearOwnedLinks
                            recovery
                            workspaceLocation
                            sources.Stamp.WorkspaceId
                            sources.Stamp.ProfileId
                            (DeploymentContextId.legacyFingerprint evidence)
                            token

                    let ownership = DeploymentContextId.fingerprint evidence

                    let contextId =
                        DeploymentContextId.create
                            sources.Stamp.WorkspaceId
                            sources.Stamp.ProfileId
                            ownership

                    do!
                        DeploymentRetirement.clearPreviousViews
                            database
                            recovery
                            workspaceLocation
                            sources.Stamp.WorkspaceId
                            sources.Stamp.ProfileId
                            contextId
                            token

                    let report (value: AcquisitionProgress) =
                        progress
                            { Phase = DeploymentPhase.Preparing
                              Completed = value.Files
                              Total = value.TotalFiles
                              Bytes = value.Bytes }

                    let! acquired =
                        match candidate with
                        | Some run ->
                            (plans :> IFilePlans)
                                .AcquireFnisCandidate(sources.Stamp.ProfileId, run, report, token)
                        | None ->
                            (plans :> IFilePlans)
                                .Acquire(sources.Stamp.ProfileId, false, report, token)

                    let withObservation (observation: GameObservation) =
                        task {
                            let sourceData: Location =
                                { Path = observation.Root
                                  Identity = observation.Identity }

                            let sourceGame: Location =
                                { Path =
                                    HostPath.create evidence.RootPath
                                    |> Result.defaultWith invalidOp
                                  Identity = evidence.RootIdentity.Value }

                            let gameRoot =
                                ModConductor.GameContexts.ComponentRoots.gameRootId
                                    sources.Stamp.WorkspaceId
                                    evidence
                                |> Result.defaultWith (fun text ->
                                    raise (System.IO.IOException text))

                            if
                                components
                                |> List.exists (fun reviewed -> reviewed.GameRoot <> gameRoot)
                            then
                                raise (RecoveryException RecoveryError.InvalidPlan)

                            let game, target, originals =
                                GameViews.ensure workspaceLocation sources.Stamp.ProfileId

                            let rootSource = GameViews.rootSource sourceGame gameRoot token

                            let withAvailableScope
                                (privateScope: ModConductor.ProfileGameData.ProfileDataScope)
                                =
                                task {
                                    let excluded, ownedFiles =
                                        GameViews.selection
                                            sourceGame
                                            observation.Snapshot.Files
                                            (privateScope.Profile |> Option.bind _.PluginOrder)
                                            sources.Stamp.WorkspaceId
                                            gameRoot
                                            token

                                    let expectedLocations =
                                        [ sources.Stamp.WorkspaceId, target; gameRoot, game ]

                                    let mutable originalStorage: PreparedOriginalStorage option =
                                        None

                                    let mutable retainOriginalStorage = false

                                    use originalStorageGuard =
                                        { new IDisposable with
                                            member _.Dispose() =
                                                if not retainOriginalStorage then
                                                    originalStorage
                                                    |> Option.iter
                                                        Preparation.abandonOriginalStorage }

                                    let staleRoots =
                                        existing
                                        |> Option.exists (fun (context: Context) ->
                                            context.Fingerprint <> ownership
                                            || context.Roots.Length <> expectedLocations.Length
                                            || expectedLocations
                                               |> List.exists (fun (id, location) ->
                                                   context.Roots
                                                   |> List.tryFind (fun root -> root.Root.Id = id)
                                                   |> Option.forall (fun root ->
                                                       root.Directory <> location)))

                                    let withCurrentRoots () =
                                        task {
                                            let roots =
                                                match existing with
                                                | Some(context: Context) -> context.Roots
                                                | None ->
                                                    expectedLocations
                                                    |> List.map (fun (root, directory) ->
                                                        { Root =
                                                            { Id = root
                                                              Policy =
                                                                ModConductor.GameContexts.Skyrim.definition.TargetPolicy }
                                                          Directory = directory
                                                          Originals = originals })

                                            token.ThrowIfCancellationRequested()

                                            let storage =
                                                DeploymentWorkspaceStorage.child
                                                    workspaceLocation
                                                    (".mc-generation-" + id.ToString("N"))

                                            let secondary =
                                                DeploymentWorkspaceStorage.child
                                                    workspaceLocation
                                                    (".mc-secondary-" + id.ToString("N"))

                                            let! previous =
                                                task {
                                                    match existing |> Option.bind _.Active with
                                                    | Some previous ->
                                                        return!
                                                            recovery.Generation(contextId, previous)
                                                    | None -> return None
                                                }

                                            let writable =
                                                if gameFolderOnly then [] else sources.Writable

                                            let enabledComponents =
                                                let enabled =
                                                    retainedProfile
                                                    |> Option.map (fun saved ->
                                                        saved.Mods
                                                        |> List.filter _.Enabled
                                                        |> List.map _.ModId
                                                        |> Set.ofList)
                                                    |> Option.defaultWith (fun () ->
                                                        sources.Profile.Mods
                                                        |> List.filter _.Enabled
                                                        |> List.map _.ModId
                                                        |> Set.ofList)

                                                components
                                                |> List.filter (fun reviewed ->
                                                    enabled.Contains reviewed.Mod.ModId)

                                            let withOutputWorking
                                                (outputWorking: WorkingLocation list)
                                                =
                                                task {
                                                    let working =
                                                        outputWorking
                                                        @ DeploymentWorkspaceStorage.componentWorking
                                                            workspaceLocation
                                                            sources.Stamp.ProfileId
                                                            enabledComponents

                                                    let request: BuildRequest =
                                                        { Id = id
                                                          Storage = storage
                                                          SecondaryStorage = secondary
                                                          Roots = roots
                                                          LinkedBase = true
                                                          Excluded = excluded
                                                          OwnedFiles = ownedFiles
                                                          Working = working
                                                          Previous = previous
                                                          Processes = [] }

                                                    let snapshot: SnapshotSource =
                                                        { Snapshot = observation.Snapshot
                                                          Directory = sourceData
                                                          Files =
                                                            observation.Entries
                                                            |> List.filter (fun entry ->
                                                                not entry.Directory)
                                                            |> List.map (fun entry ->
                                                                entry.Path, entry.Identity)
                                                            |> Map.ofList
                                                          Originals =
                                                            observation.Projection.Originals }

                                                    let! built =
                                                        generations.Build(
                                                            request,
                                                            sources.Stamp.ProfileId,
                                                            [ snapshot; rootSource ],
                                                            writable,
                                                            token,
                                                            (fun location ->
                                                                GenerationStorage.available
                                                                    location.Path
                                                                    location.Identity),
                                                            gameFolderOnly = gameFolderOnly,
                                                            ?retainedProfile = retainedProfile,
                                                            recordProfile = recordProfile,
                                                            ?fnisCandidate = candidate,
                                                            components = components
                                                        )

                                                    match built with
                                                    | Error error -> return Error error
                                                    | Ok built when
                                                        candidate.IsNone
                                                        && built.Sources <> sources.Stamp
                                                        ->
                                                        return Error RecoveryError.Stale
                                                    | Ok built ->
                                                        let! initialized =
                                                            DeploymentOutputs.initialized
                                                                database
                                                                sources.Stamp
                                                                outputWorking

                                                        match initialized with
                                                        | Error error -> return Error error
                                                        | Ok() ->
                                                            let projected =
                                                                DeploymentTargetProjection.project
                                                                    id
                                                                    sources.Stamp
                                                                    existing
                                                                    ownership
                                                                    contextId
                                                                    roots
                                                                    observation
                                                                    built
                                                                    token

                                                            match projected with
                                                            | Error error -> return Error error
                                                            | Ok(switch, changedPaths) ->
                                                                let generation = switch.Generation

                                                                let view =
                                                                    { Id = id
                                                                      WorkspaceId =
                                                                        sources.Stamp.WorkspaceId
                                                                      Fingerprint =
                                                                        built.Generation.PlanFingerprint
                                                                      Sources = sources.Stamp
                                                                      Profile =
                                                                        generation.Provenance
                                                                        |> Option.bind _.Profile
                                                                        |> Option.map
                                                                            SavedDeployments.profile
                                                                      WritableFiles =
                                                                        generation.Working.Length
                                                                      ChangedPaths = changedPaths
                                                                      PreservedOriginals =
                                                                        switch.PreserveOriginals.Length
                                                                      ManagedLinks =
                                                                        built.Measurements.GenerationLinks
                                                                      CopiedBytes =
                                                                        built.Measurements.CopiedBytes
                                                                      RequiredBytes =
                                                                        built.Measurements.RequiredBytes }

                                                                retainOriginalStorage <- true

                                                                return
                                                                    Ok
                                                                        { View = view
                                                                          Context = sources.Context
                                                                          PluginSelectionRevision =
                                                                            privateScope.Profile
                                                                            |> Option.map _.Revision
                                                                            |> Option.defaultValue
                                                                                0L
                                                                          Switch = switch
                                                                          OriginalStorage =
                                                                            originalStorage }
                                                }

                                            let! outputWorking =
                                                if gameFolderOnly then
                                                    Task.FromResult(Ok [])
                                                else
                                                    DeploymentOutputs.read
                                                        database
                                                        workspace
                                                        sources

                                            match outputWorking with
                                            | Error error -> return Error error
                                            | Ok working -> return! withOutputWorking working
                                        }

                                    if staleRoots then
                                        return Error RecoveryError.Stale
                                    else
                                        return! withCurrentRoots ()
                                }

                            let! scope =
                                (ProfileDataRepository(database, access)
                                :> ModConductor.ProfileGameData.IProfileDataRepository)
                                    .Read(sources.Stamp.WorkspaceId, sources.Stamp.ProfileId)

                            match scope with
                            | Error error -> return Error(profileError error)
                            | Ok privateScope ->
                                match privateScope.Availability with
                                | Some detail -> return Error(RecoveryError.Unavailable detail)
                                | None -> return! withAvailableScope privateScope
                        }

                    let withSummary (summary: FilePlanSummary) =
                        match plans.Observation summary.Id with
                        | None -> Task.FromResult(Error RecoveryError.Stale)
                        | Some observation -> withObservation observation

                    match acquired with
                    | Error error -> return Error(acquireError error)
                    | Ok summary -> return! withSummary summary
                }

            let! root = access.Root sources.Stamp.WorkspaceId

            match root with
            | Error _ -> return Error RecoveryError.Stale
            | Ok workspace -> return! withWorkspace workspace
        }

    let prepare
        database
        access
        plans
        generations
        recovery
        id
        sources
        existing
        gameFolderOnly
        retainedProfile
        retainedGeneration
        progress
        token
        =
        prepareWith
            false
            true
            None
            []
            database
            access
            plans
            generations
            recovery
            id
            sources
            existing
            gameFolderOnly
            retainedProfile
            retainedGeneration
            progress
            token

    let transient
        database
        access
        plans
        generations
        recovery
        id
        sources
        existing
        candidate
        progress
        token
        =
        prepareWith
            false
            false
            (Some candidate)
            []
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

    let components
        database
        access
        plans
        generations
        recovery
        id
        sources
        existing
        reviewed
        retainedProfile
        progress
        token
        =
        prepareWith
            true
            true
            None
            reviewed
            database
            access
            plans
            generations
            recovery
            id
            sources
            existing
            false
            retainedProfile
            None
            progress
            token
