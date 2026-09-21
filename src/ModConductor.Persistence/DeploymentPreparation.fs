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
                    System.IO.File.Exists(
                        System.IO.Path.Combine(
                            HostPath.value profileRoot.Path,
                            LogicalPath.display relative
                        )
                    )
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
        progress
        token
        =
        task {
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

            let evidence = GameProcesses.validate sources.Context

            let ownership = DeploymentContextId.fingerprint evidence
            let contextId =
                DeploymentContextId.create
                    sources.Stamp.WorkspaceId
                    sources.Stamp.ProfileId
                    ownership

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

            let! root = access.Root sources.Stamp.WorkspaceId
            let workspace = required root

            let workspaceLocation: Location =
                { Path = workspace.Path
                  Identity = workspace.Identity }

            let target: Location =
                { Path = observation.Root
                  Identity = observation.Identity }

            let game: Location =
                { Path = HostPath.create evidence.RootPath |> Result.defaultWith invalidOp
                  Identity = evidence.RootIdentity.Value }

            let gameRoot =
                if not componentMode then
                    None
                else
                    let expected =
                        ModConductor.GameContexts.ComponentRoots.gameRootId
                            sources.Stamp.WorkspaceId
                            evidence
                        |> Result.defaultWith (fun text -> raise (System.IO.IOException text))

                    if
                        components |> List.exists (fun reviewed -> reviewed.GameRoot <> expected)
                    then
                        raise (RecoveryException RecoveryError.InvalidPlan)

                    Some expected

            let expectedLocations =
                [ yield sources.Stamp.WorkspaceId, target
                  match gameRoot with
                  | Some id -> yield id, game
                  | None -> () ]

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
                    let originals =
                        child game (".modconductor-originals-" + Guid.NewGuid().ToString("N"))

                    originalStorage <- Some { Parent = game; Directory = originals }

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
                  Working = working
                  Previous = previous
                  Processes = [] }

            let snapshot: SnapshotSource =
                { Snapshot = observation.Snapshot
                  Directory = target
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
                    [ snapshot ],
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
            progress
            token
