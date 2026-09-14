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

    let prepare
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
            let evidence = GameProcesses.validate sources.Context

            let ownership = DeploymentContextId.fingerprint evidence
            let contextId = DeploymentContextId.create sources.Stamp.WorkspaceId ownership

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

            let roots =
                match existing with
                | Some(context: Context) ->
                    if
                        context.Fingerprint <> ownership
                        || context.Roots |> List.exists (fun root -> root.Directory <> target)
                    then
                        raise (RecoveryException RecoveryError.Stale)

                    context.Roots
                | None ->
                    let originals =
                        child game (".modconductor-originals-" + Guid.NewGuid().ToString("N"))

                    [ { Root =
                          { Id = sources.Stamp.WorkspaceId
                            Policy = ModConductor.GameContexts.Skyrim.definition.TargetPolicy }
                        Directory = target
                        Originals = originals } ]

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

            let! working =
                if gameFolderOnly then
                    System.Threading.Tasks.Task.FromResult []
                else
                    DeploymentOutputs.read database workspace sources

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
                    recordProfile = true
                )

            let built =
                built |> Result.defaultWith (fun error -> raise (RecoveryException error))

            if built.Sources <> sources.Stamp then
                raise (RecoveryException RecoveryError.Stale)

            do! DeploymentOutputs.initialized database sources.Stamp working

            let known =
                (observation.Entries |> List.map _.Path)
                @ (observation.Projection.Links |> List.map _.Path)
                @ (existing
                   |> Option.map (fun context ->
                       context.Directories |> List.map (fun value -> value.Target.Path))
                   |> Option.defaultValue [])

            let boundaries =
                PhysicalTargets.boundaries
                    roots.Head.Root.Policy
                    known
                    (existing |> Option.map _.Links |> Option.defaultValue [])
                    built.Generation
                    token

            let mapped =
                PhysicalTargets.map
                    roots.Head.Root.Policy
                    known
                    ((built.Generation.Files |> List.map _.Target)
                     @ (built.Generation.Observed |> List.map _.Target)
                     @ (built.Generation.Working |> List.map _.Target)
                     @ boundaries)
                    token

            let generation =
                { built.Generation with
                    NativeTargets = mapped }

            let collisions =
                built.Generation.Files
                |> List.choose (fun file ->
                    let native = RecoveryFiles.nativeTarget generation file.Target

                    if
                        observation.Snapshot.Files
                        |> List.exists (fun original -> original.Path = native.Path)
                    then
                        Some native
                    else
                        None)

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

            return
                { View = view
                  Context = sources.Context
                  Switch = switch }
        }
