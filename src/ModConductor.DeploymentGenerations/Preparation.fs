namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

type internal PreparedBuild =
    { Visibility: FileVisibility
      View: PlanView
      Managed: ResolvedFile list
      Bindings: (WorkingLocation * TargetFile * bool * ResolvedFile list) list
      SeedCopies: (Guid * Location * LogicalPath * SourcePin) list
      CopiedBytes: int64
      SeedBytes: int64
      Capacity: (Location * int64 * int64) list }

module internal GenerationCapacity =
    let private add left right = Checked.(+) left right

    let private entries count =
        add 65536L (Checked.(*) (int64 count) 4096L)

    let required
        (request: BuildRequest)
        (managed: ResolvedFile list)
        (secondary: ResolvedFile list)
        (bindings: (WorkingLocation * TargetFile * bool * ResolvedFile list) list)
        (seeds: (Guid * Location * LogicalPath * SourcePin) list)
        =
        try
            [ yield request.Storage, entries managed.Length
              if not secondary.IsEmpty then
                  yield
                      request.SecondaryStorage,
                      secondary
                      |> List.fold
                          (fun total file -> add total (GenerationFiles.length file.Winner.Source))
                          (entries secondary.Length)
              for binding, _, _, _ in bindings do
                  yield binding.Root, entries 0
              for root in request.Roots do
                  let immutableCount =
                      managed
                      |> List.filter (fun file -> file.Target.Root = root.Root.Id)
                      |> List.length

                  let workingCount =
                      bindings
                      |> List.filter (fun (_, target, _, _) -> target.Root = root.Root.Id)
                      |> List.length

                  yield root.Directory, entries (Checked.(+) immutableCount workingCount)
              for _, root, _, pin in seeds do
                  yield root, add (GenerationFiles.length pin) 4096L ]
            |> List.groupBy (fun (location, _) -> location.Identity.Device)
            |> List.map (fun (_, charges) ->
                fst charges.Head, charges |> List.fold (fun total (_, bytes) -> add total bytes) 0L)
        with :? OverflowException ->
            raise (RecoveryException RecoveryError.Limit)

    let sum values =
        try
            values |> Seq.fold add 0L
        with :? OverflowException ->
            raise (RecoveryException RecoveryError.Limit)

    let check available requirements =
        let capacity =
            requirements |> List.map (fun (root, needed) -> root, needed, available root)

        if capacity |> List.exists (fun (_, needed, free) -> free < needed) then
            Error(
                RecoveryError.Unavailable
                    "There is not enough storage for the required copies and links."
            )
        else
            Ok capacity

module internal GenerationPreparation =
    open GenerationFiles

    let private declaredPath =
        function
        | WritableProjection.File(id, target, seed) -> Some(id, target, false, Option.toList seed)
        | WritableProjection.Subtree(id, root, PlanPath.At path, seeds) ->
            Some(id, { Root = root; Path = path }, true, seeds)
        | WritableProjection.Subtree(_, _, PlanPath.Root, _) -> None

    let reused (request: BuildRequest) pin =
        request.Previous
        |> Option.bind (fun generation ->
            generation.Files
            |> List.tryPick (fun file ->
                if generation.References |> List.contains pin then
                    file.Backing
                    |> Option.filter (fun backing ->
                        backing.OwnerGeneration.IsSome
                        && file.Length = length pin
                        && file.Sha256 = sha256 pin)
                else
                    None))

    let private verifyLocations
        (request: BuildRequest)
        (sources: GenerationSources)
        (bindings: (WorkingLocation * TargetFile * bool * ResolvedFile list) list)
        =
        let overlaps (left: Location) (right: Location) =
            left.Identity = right.Identity
            || Preparation.nested (HostPath.value left.Path) (HostPath.value right.Path)
            || Preparation.nested (HostPath.value right.Path) (HostPath.value left.Path)

        if overlaps request.Storage request.SecondaryStorage then
            RecoveryFiles.fail "Generation and secondary backing storage must be separate."

        for _, backing in sources.Files |> Map.toList do
            for destination in [ request.Storage; request.SecondaryStorage ] do
                if overlaps backing.Directory destination then
                    RecoveryFiles.fail "Generation storage overlaps a source directory."

        let locations =
            request.Storage
            :: request.SecondaryStorage
            :: (bindings |> List.map (fun (binding, _, _, _) -> binding.Root))

        for location in locations do
            use held = HeldDirectory.Open(location.Path, location.Identity)

            let selected =
                RootSelection.select location.Path
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "Build storage cannot be selected.")

            if RootSelection.path selected <> location.Path then
                RecoveryFiles.fail "Use canonical selected storage locations."

            for root in request.Roots do
                for reserved in [ root.Directory; root.Originals ] do
                    if
                        location.Identity = reserved.Identity
                        || Preparation.nested
                            (HostPath.value location.Path)
                            (HostPath.value reserved.Path)
                        || Preparation.nested
                            (HostPath.value reserved.Path)
                            (HostPath.value location.Path)
                    then
                        RecoveryFiles.fail
                            "Build storage overlaps a deployment target or original store."

        for binding, _, _, _ in bindings do
            for immutable in
                [ request.Storage; request.SecondaryStorage ]
                @ (sources.Files |> Map.toList |> List.map (fun (_, value) -> value.Directory)) do
                if
                    binding.Root.Identity = immutable.Identity
                    || Preparation.nested
                        (HostPath.value binding.Root.Path)
                        (HostPath.value immutable.Path)
                    || Preparation.nested
                        (HostPath.value immutable.Path)
                        (HostPath.value binding.Root.Path)
                then
                    RecoveryFiles.fail "Working storage overlaps immutable source storage."


    let private prepareWorking
        (available: Location -> int64)
        (request: BuildRequest)
        (sources: GenerationSources)
        (visibility: FileVisibility)
        (view: PlanView)
        (managed: ResolvedFile list)
        (working: (Guid * TargetFile * bool * ResolvedFile list) list)
        =
        let bindings =
            working
            |> List.map (fun (id, target, directory, seeds) ->
                let selected = request.Working |> List.filter (fun value -> value.Declaration = id)

                match selected with
                | [ value ] -> value, target, directory, seeds
                | _ -> raise (RecoveryException RecoveryError.InvalidPlan))

        if request.Working.Length <> bindings.Length then
            raise (RecoveryException RecoveryError.InvalidPlan)

        let secondaryCopies =
            managed
            |> List.filter (fun file ->
                file.Winner.Precedence.Tier = LayerTier.Secondary
                && reused request file.Winner.Source |> Option.isNone)

        let seedCopies =
            bindings
            |> List.collect (fun (binding, target, directory, seeds) ->
                (if binding.Initialized then [] else seeds)
                |> List.choose (fun seed ->
                    let relative =
                        if directory then
                            LogicalPath.components binding.Path
                            @ (LogicalPath.components seed.Target.Path
                               |> List.skip (LogicalPath.components target.Path).Length)
                        else
                            LogicalPath.components binding.Path

                    let path = logical relative

                    match inspect binding.Root path with
                    | Some entry when entry.Kind = EntryKind.RegularFile -> None
                    | Some _ ->
                        RecoveryFiles.fail "A working seed destination is not a regular file."
                    | None -> Some(binding.Declaration, binding.Root, path, seed.Winner.Source)))

        let copiedBytes =
            secondaryCopies
            |> Seq.map (fun file -> length file.Winner.Source)
            |> GenerationCapacity.sum

        let seedBytes =
            seedCopies
            |> Seq.map (fun (_, _, _, pin) -> length pin)
            |> GenerationCapacity.sum

        let requirements =
            GenerationCapacity.required request managed secondaryCopies bindings seedCopies

        GenerationCapacity.check available requirements
        |> Result.map (fun capacity ->
            verifyLocations request sources bindings

            { Visibility = visibility
              View = view
              Managed = managed
              Bindings = bindings
              SeedCopies = seedCopies
              CopiedBytes = copiedBytes
              SeedBytes = seedBytes
              Capacity = capacity })

    let prepare
        (available: Location -> int64)
        (request: BuildRequest)
        (sources: GenerationSources)
        (token: CancellationToken)
        =
        checkProcesses request.Processes
        token.ThrowIfCancellationRequested()
        let visibility = Visibility.prepare sources.Input

        match Visibility.view visibility with
        | Error _ -> Error RecoveryError.InvalidPlan
        | Ok view when view.ReadOnlyFiles.Length > 1000000 -> Error RecoveryError.Limit
        | Ok view ->
            let managed =
                view.ReadOnlyFiles
                |> List.filter (fun file ->
                    not (request.Excluded.Contains file.Target)
                    && (request.LinkedBase || file.Winner.Precedence.Tier <> LayerTier.Base))

            let working = view.Writable |> List.map declaredPath

            if working |> List.exists Option.isNone then
                Error(
                    RecoveryError.Unavailable
                        "A whole-root working link has no separate target parent."
                )
            else
                prepareWorking
                    available
                    request
                    sources
                    visibility
                    view
                    managed
                    (working |> List.choose id)
