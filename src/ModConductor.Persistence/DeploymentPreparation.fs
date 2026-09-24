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
    let private required =
        function
        | Ok value -> value
        | Error _ -> raise (RecoveryException RecoveryError.Stale)

    let private child (root: Location) name =
        use parent = HeldDirectory.Open(root.Path, root.Identity)
        use created = parent.CreateDirectory name

        { Path =
            HostPath.create (System.IO.Path.Combine(HostPath.value root.Path, name))
            |> Result.defaultWith invalidOp
          Identity = created.Identity }

    let private durableChild (root: Location) name =
        use parent = HeldDirectory.Open(root.Path, root.Identity)

        use directory =
            match parent.InspectEntry name with
            | None -> parent.CreateDirectory name
            | Some entry when entry.Kind = EntryKind.Directory ->
                parent.Directory(name, Some entry.Identity)
            | Some _ -> RecoveryFiles.fail "Owned working storage is not a directory."

        { Path =
            HostPath.create (System.IO.Path.Combine(HostPath.value root.Path, name))
            |> Result.defaultWith invalidOp
          Identity = directory.Identity }

    let private componentWorking
        (workspace: Location)
        (profile: Guid)
        (components: ReviewedComponent list)
        =
        if components.IsEmpty then
            []
        else
            let root = durableChild workspace ".mc-component-working"
            let profileRoot = durableChild root (profile.ToString "N")

            components
            |> List.collect _.Writable
            |> List.map (fun declaration ->
                let relative =
                    LogicalPath.create [ declaration.Id.ToString("N") + ".working" ]
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid working file name.")

                { Declaration = declaration.Id
                  Initialized =
                    let location =
                        System.IO.Path.Combine(
                            HostPath.value profileRoot.Path,
                            LogicalPath.display relative
                        )

                    match declaration.Target with
                    | WritableTarget.File _ -> System.IO.File.Exists location
                    | WritableTarget.Subtree _ -> System.IO.Directory.Exists location
                  Root = profileRoot
                  Path = relative })

    let private knownAtRoot
        (binding: RootBinding)
        (targets: TargetFile list)
        (token: CancellationToken)
        =
        let known = ResizeArray<LogicalPath>()
        let policy = binding.Root.Policy

        let logical parts =
            LogicalPath.create parts
            |> Result.defaultWith (fun _ ->
                raise (System.IO.IOException "The game root contains an invalid file name."))

        let rec observe (directory: HeldDirectory) prefix =
            function
            | [] -> ()
            | wanted :: rest ->
                token.ThrowIfCancellationRequested()
                let names = directory.Names |> Seq.toList

                for name in names do
                    known.Add(logical (prefix @ [ name ]))

                match
                    names
                    |> List.filter (fun name ->
                        (TargetPolicy.comparer policy)
                            .Equals(
                                TargetPolicy.key policy (logical (prefix @ [ name ])),
                                TargetPolicy.key policy (logical (prefix @ [ wanted ]))
                            ))
                with
                | [] -> ()
                | [ actual ] when not rest.IsEmpty ->
                    match directory.InspectEntry actual with
                    | Some entry when entry.Kind = EntryKind.Directory ->
                        use child = directory.Directory(actual, Some entry.Identity)
                        observe child (prefix @ [ actual ]) rest
                    | _ -> ()
                | [ _ ] -> ()
                | _ -> RecoveryFiles.fail "The game root contains ambiguous target names."

        use root = HeldDirectory.Open(binding.Directory.Path, binding.Directory.Identity)

        for target in targets |> List.distinct do
            observe root [] (LogicalPath.components target.Path)

        List.ofSeq known

    let private clearOwnedLinks
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        fingerprint
        token
        =
        task {
            let contextId =
                DeploymentContextId.create
                    workspaceId
                    profileId
                    fingerprint

            let! legacy = recovery.Context contextId

            match legacy with
            | None -> ()
            | Some context when context.Pending.IsSome ->
                raise (RecoveryException RecoveryError.Busy)
            | Some context when context.Links.IsEmpty -> ()
            | Some context ->
                // Switch the old owned in-place generation to an empty one through the
                // existing recovery journal, restoring only its recorded originals.
                let id = Guid.NewGuid()
                let directory = child workspace (".mc-generation-" + id.ToString("N"))

                let empty: Generation =
                    { Id = id
                      PlanFingerprint = "mc-legacy-game-view-cutover"
                      Directory = directory
                      Files = []
                      References = []
                      Writable = []
                      Roots = context.Roots |> List.map _.Root
                      Observed = []
                      Working = []
                      NativeTargets = Map.empty
                      Provenance = None }

                let request: SwitchRequest =
                    { Id = id
                      ContextId = contextId
                      ContextFingerprint = fingerprint
                      ExpectedRevision = context.Revision
                      Roots = context.Roots
                      Generation = empty
                      DirectoryBoundaries = []
                      PreserveOriginals = []
                      ExpectedSources = None }

                let! started = recovery.Start(request, cancellation = token)
                let receipt = started |> Result.defaultWith (fun error -> raise (RecoveryException error))
                let! completed = recovery.Run(id, receipt.Revision, false, token, (fun _ _ -> ()))
                completed |> Result.defaultWith (fun error -> raise (RecoveryException error)) |> ignore
        }

    let private clearPreviousViews
        (database: StateDatabase)
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        currentId
        token
        =
        task {
            let gamePath = GameViews.rootPath workspace.Path profileId

            let! previous =
                database.Enqueue(fun () ->
                    use query =
                        Sqlite.command
                            database.Connection
                            null
                            "SELECT id FROM deployment_contexts WHERE id<>$current"
                            [ "$current", box (string currentId) ]

                    use reader = query.ExecuteReader()
                    let ids = [ while reader.Read() do yield Guid.Parse(reader.GetString 0) ]
                    reader.Close()

                    ids
                    |> List.choose (fun id ->
                        DeploymentRows.context database.Connection null id
                        |> Option.filter (fun context ->
                            context.Roots
                            |> List.exists (fun root ->
                                String.Equals(
                                    HostPath.value root.Directory.Path,
                                    gamePath,
                                    StringComparison.OrdinalIgnoreCase
                                )))
                        |> Option.map _.Fingerprint))

            for fingerprint in previous do
                do!
                    clearOwnedLinks
                        recovery
                        workspace
                        workspaceId
                        profileId
                        fingerprint
                        token
        }

    let retireProfile
        (database: StateDatabase)
        (recovery: Recovery)
        (workspace: Location)
        workspaceId
        profileId
        (evidence: ModConductor.GameContexts.InstallationEvidence)
        token
        =
        task {
            GameProcesses.checkWithRoot
                evidence
                (Some(GameViews.rootPath workspace.Path profileId))

            let! owned =
                database.Enqueue(fun () ->
                    use query = Sqlite.command database.Connection null "SELECT id FROM deployment_contexts" []
                    use reader = query.ExecuteReader()
                    let ids = [ while reader.Read() do yield Guid.Parse(reader.GetString 0) ]
                    reader.Close()

                    ids
                    |> List.choose (fun id ->
                        DeploymentRows.context database.Connection null id
                        |> Option.filter (fun context ->
                            DeploymentContextId.create workspaceId profileId context.Fingerprint = id)))

            for context in owned do
                for root in context.Roots do
                    let path = HostPath.value root.Directory.Path
                    let gameRoot =
                        if String.Equals(System.IO.Path.GetFileName path, "Data", StringComparison.OrdinalIgnoreCase) then
                            System.IO.Path.GetDirectoryName path
                        else path
                    GameProcesses.checkWithRoot evidence (Some gameRoot)

                do!
                    clearOwnedLinks
                        recovery
                        workspace
                        workspaceId
                        profileId
                        context.Fingerprint
                        token

            GameViews.removeOwned workspace profileId
        }

    let private prepareWith
        componentMode
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
                ComponentRoutes.read database sources existing components retainedProfile retainedGeneration

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

            let! root = access.Root sources.Stamp.WorkspaceId
            let workspace = required root

            let workspaceLocation: Location =
                { Path = workspace.Path
                  Identity = workspace.Identity }

            GameProcesses.checkWithRoot
                evidence
                (Some(GameViews.rootPath workspace.Path sources.Stamp.ProfileId))

            do!
                clearOwnedLinks
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
                clearPreviousViews
                    database
                    recovery
                    workspaceLocation
                    sources.Stamp.WorkspaceId
                    sources.Stamp.ProfileId
                    contextId
                    token

            let! acquired =
                (plans :> IFilePlans)
                    .Acquire(
                        sources.Stamp.ProfileId,
                        false,
                        (fun value ->
                            progress
                                { Phase = DeploymentPhase.Preparing
                                  Completed = value.Files
                                  Total = value.TotalFiles
                                  Bytes = value.Bytes }),
                        token
                    )

            let summary =
                acquired
                |> Result.defaultWith (function
                    | FilePlanError.Cancelled -> raise (OperationCanceledException())
                    | FilePlanError.Busy -> raise (RecoveryException RecoveryError.Busy)
                    | FilePlanError.Blocked
                    | FilePlanError.InvalidCopy
                    | FilePlanError.Unsupported _
                    | FilePlanError.InvalidEdit _ ->
                        raise (RecoveryException RecoveryError.InvalidPlan)
                    | FilePlanError.NotFound -> raise (RecoveryException RecoveryError.NotFound)
                    | FilePlanError.LimitExceeded _ -> raise (RecoveryException RecoveryError.Limit)
                    | FilePlanError.ContextUnavailable text
                    | FilePlanError.FileUnavailable text -> raise (System.IO.IOException text)
                    | FilePlanError.Expired
                    | FilePlanError.Stale -> raise (RecoveryException RecoveryError.Stale))

            let observation =
                plans.Observation summary.Id
                |> Option.defaultWith (fun () -> raise (RecoveryException RecoveryError.Stale))

            let sourceData: Location =
                { Path = observation.Root
                  Identity = observation.Identity }

            let sourceGame: Location =
                { Path = HostPath.create evidence.RootPath |> Result.defaultWith invalidOp
                  Identity = evidence.RootIdentity.Value }

            let gameRoot =
                ModConductor.GameContexts.ComponentRoots.gameRootId
                    sources.Stamp.WorkspaceId
                    evidence
                |> Result.defaultWith (fun text -> raise (System.IO.IOException text))

            if components |> List.exists (fun reviewed -> reviewed.GameRoot <> gameRoot) then
                raise (RecoveryException RecoveryError.InvalidPlan)

            let game, target, originals =
                GameViews.ensure workspaceLocation sources.Stamp.ProfileId

            let rootSource = GameViews.rootSource sourceGame gameRoot token

            let! privateScope =
                (ProfileDataRepository(database, access) :> ModConductor.ProfileGameData.IProfileDataRepository)
                    .Read(sources.Stamp.WorkspaceId, sources.Stamp.ProfileId)

            privateScope.Availability
            |> Option.iter (fun detail ->
                raise (RecoveryException(RecoveryError.Unavailable detail)))

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

            let mutable originalStorage: PreparedOriginalStorage option = None
            let mutable retainOriginalStorage = false

            use originalStorageGuard =
                { new IDisposable with
                    member _.Dispose() =
                        if not retainOriginalStorage then
                            originalStorage |> Option.iter Preparation.abandonOriginalStorage }

            let roots =
                match existing with
                | Some(context: Context) ->
                    if
                        context.Fingerprint <> ownership
                        || context.Roots.Length <> expectedLocations.Length
                        || expectedLocations
                           |> List.exists (fun (id, location) ->
                               context.Roots
                               |> List.tryFind (fun root -> root.Root.Id = id)
                               |> Option.forall (fun root -> root.Directory <> location))
                    then
                        raise (RecoveryException RecoveryError.Stale)

                    context.Roots
                | None ->
                    expectedLocations
                    |> List.map (fun (root, directory) ->
                        { Root =
                            { Id = root
                              Policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy }
                          Directory = directory
                          Originals = originals })

            token.ThrowIfCancellationRequested()
            let storage = child workspaceLocation (".mc-generation-" + id.ToString("N"))
            let secondary = child workspaceLocation (".mc-secondary-" + id.ToString("N"))

            let! previous =
                task {
                    match existing |> Option.bind _.Active with
                    | Some previous -> return! recovery.Generation(contextId, previous)
                    | None -> return None
                }

            let writable = if gameFolderOnly then [] else sources.Writable

            let enabledComponents =
                let enabled =
                    retainedProfile
                    |> Option.map (fun saved ->
                        saved.Mods |> List.filter _.Enabled |> List.map _.ModId |> Set.ofList)
                    |> Option.defaultWith (fun () ->
                        sources.Profile.Mods
                        |> List.filter _.Enabled
                        |> List.map _.ModId
                        |> Set.ofList)

                components |> List.filter (fun reviewed -> enabled.Contains reviewed.Mod.ModId)

            let! outputWorking =
                if gameFolderOnly then
                    System.Threading.Tasks.Task.FromResult []
                else
                    DeploymentOutputs.read database workspace sources

            let working =
                outputWorking
                @ componentWorking workspaceLocation sources.Stamp.ProfileId enabledComponents

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
                    |> List.filter (fun entry -> not entry.Directory)
                    |> List.map (fun entry -> entry.Path, entry.Identity)
                    |> Map.ofList
                  Originals = observation.Projection.Originals }

            let! built =
                generations.Build(
                    request,
                    sources.Stamp.ProfileId,
                    [ snapshot; rootSource ],
                    writable,
                    token,
                    (fun location -> GenerationStorage.available location.Path location.Identity),
                    gameFolderOnly = gameFolderOnly,
                    ?retainedProfile = retainedProfile,
                    recordProfile = true,
                    components = components
                )

            let built =
                built |> Result.defaultWith (fun error -> raise (RecoveryException error))

            if built.Sources <> sources.Stamp then
                raise (RecoveryException RecoveryError.Stale)

            do! DeploymentOutputs.initialized database sources.Stamp outputWorking

            let allTargets: TargetFile list =
                (built.Generation.Files |> List.map _.Target)
                @ (built.Generation.Observed |> List.map _.Target)
                @ (built.Generation.Working |> List.map _.Target)

            let knownFor (binding: RootBinding) =
                if binding.Root.Id = sources.Stamp.WorkspaceId then
                    (observation.Entries |> List.map _.Path)
                    @ (observation.Projection.Links |> List.map _.Path)
                    @ (existing
                       |> Option.map (fun context ->
                           context.Directories
                           |> List.filter (fun value -> value.Target.Root = binding.Root.Id)
                           |> List.map (fun value -> value.Target.Path))
                       |> Option.defaultValue [])
                else
                    knownAtRoot
                        binding
                        (allTargets |> List.filter (fun target -> target.Root = binding.Root.Id))
                        token

            let known =
                roots |> List.map (fun root -> root.Root.Id, knownFor root) |> Map.ofList

            let boundaries =
                roots
                |> List.collect (fun root ->
                    PhysicalTargets.boundaries
                        root.Root.Policy
                        known[root.Root.Id]
                        (existing
                         |> Option.map (fun context ->
                             context.Links
                             |> List.filter (fun link -> link.Target.Root = root.Root.Id))
                         |> Option.defaultValue [])
                        { built.Generation with
                            Files =
                                built.Generation.Files
                                |> List.filter (fun file -> file.Target.Root = root.Root.Id)
                            Observed =
                                built.Generation.Observed
                                |> List.filter (fun file -> file.Target.Root = root.Root.Id)
                            Working =
                                built.Generation.Working
                                |> List.filter (fun file -> file.Target.Root = root.Root.Id) }
                        token)

            let mapped =
                roots
                |> List.collect (fun root ->
                    PhysicalTargets.map
                        root.Root.Policy
                        known[root.Root.Id]
                        ((allTargets |> List.filter (fun target -> target.Root = root.Root.Id))
                         @ (boundaries |> List.filter (fun target -> target.Root = root.Root.Id)))
                        token
                    |> Map.toList)
                |> Map.ofList

            let generation =
                { built.Generation with
                    NativeTargets = mapped }

            let observedContext: Context =
                { Id = contextId
                  Fingerprint = ownership
                  Roots = roots
                  Revision = 0L
                  Active = None
                  Links = []
                  Directories = []
                  Originals = []
                  Pending = None }

            let existingLinks: TargetFile list =
                existing
                |> Option.map (fun context -> context.Links |> List.map _.Target)
                |> Option.defaultValue []

            let insideExisting (target: TargetFile) =
                existingLinks
                |> List.exists (fun (owned: TargetFile) ->
                    let parent = LogicalPath.components owned.Path

                    owned.Root = target.Root
                    && List.truncate parent.Length (LogicalPath.components target.Path) = parent)

            let collisions =
                (generation.Files |> List.map _.Target)
                @ (generation.Working |> List.map _.Target)
                |> List.map (RecoveryFiles.nativeTarget generation)
                |> List.distinct
                |> List.choose (fun target ->
                    if insideExisting target then
                        None
                    else
                        RecoveryFiles.observe observedContext target
                        |> Option.map (fun _ -> target))

            let switch =
                { Id = id
                  ContextId = contextId
                  ContextFingerprint = ownership
                  ExpectedRevision = existing |> Option.map _.Revision |> Option.defaultValue 0L
                  Roots = roots
                  Generation = generation
                  DirectoryBoundaries = boundaries
                  PreserveOriginals = collisions
                  ExpectedSources = Some built.Sources }

            let paths =
                (ModConductor.DeploymentRecovery.Preparation.projection switch |> List.map fst)
                @ (existing
                   |> Option.map (fun context -> context.Links |> List.map _.Target)
                   |> Option.defaultValue [])
                |> Set.ofList

            let view =
                { Id = id
                  WorkspaceId = sources.Stamp.WorkspaceId
                  Fingerprint = built.Generation.PlanFingerprint
                  Sources = built.Sources
                  Profile =
                    generation.Provenance
                    |> Option.bind _.Profile
                    |> Option.map SavedDeployments.profile
                  WritableFiles = generation.Working.Length
                  ChangedPaths = paths.Count
                  PreservedOriginals = collisions.Length
                  ManagedLinks = built.Measurements.GenerationLinks
                  CopiedBytes = built.Measurements.CopiedBytes
                  RequiredBytes = built.Measurements.RequiredBytes }

            retainOriginalStorage <- true

            return
                { View = view
                  Context = sources.Context
                  PluginSelectionRevision =
                    privateScope.Profile |> Option.map _.Revision |> Option.defaultValue 0L
                  Switch = switch
                  OriginalStorage = originalStorage }
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
