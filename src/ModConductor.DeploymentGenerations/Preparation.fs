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

module internal GenerationPreparation =
    open GenerationFiles

    let private declaredPath =
        function
        | WritableProjection.File(id, target, seed) -> id, target, false, Option.toList seed
        | WritableProjection.Subtree(id, root, PlanPath.At path, seeds) ->
            id, { Root = root; Path = path }, true, seeds
        | WritableProjection.Subtree(_, _, PlanPath.Root, _) ->
            raise (
                RecoveryException(
                    RecoveryError.Unavailable
                        "A whole-root working link has no separate target parent."
                )
            )

    let reused (request: BuildRequest) pin =
        request.Previous
        |> Option.bind (fun generation ->
            generation.Files
            |> List.tryPick (fun file ->
                if generation.References |> List.contains pin then
                    let length, hash = content pin

                    file.Backing
                    |> Option.filter (fun backing ->
                        backing.OwnerGeneration.IsSome
                        && file.Length = length
                        && file.Sha256 = hash)
                else
                    None))

    let prepare
        (available: Location -> int64)
        (request: BuildRequest)
        (sources: GenerationSources)
        (token: CancellationToken)
        =
        checkProcesses request.Processes
        token.ThrowIfCancellationRequested()
        let visibility = Visibility.prepare sources.Input

        let view =
            Visibility.view visibility
            |> Result.defaultWith (fun _ -> raise (RecoveryException RecoveryError.InvalidPlan))

        if view.ReadOnlyFiles.Length > 1000000 then
            raise (RecoveryException RecoveryError.Limit)

        let managed =
            view.ReadOnlyFiles
            |> List.filter (fun file -> file.Winner.Precedence.Tier <> LayerTier.Base)

        let working = view.Writable |> List.map declaredPath

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
                seeds
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
            secondaryCopies |> List.sumBy (fun file -> content file.Winner.Source |> fst)

        let seedBytes = seedCopies |> List.sumBy (fun (_, _, _, pin) -> content pin |> fst)
        let metadataBytes = 65536L + int64 managed.Length * 4096L

        let requirements =
            [ yield request.Storage, metadataBytes
              yield request.SecondaryStorage, copiedBytes + 65536L
              for binding, _, _, _ in bindings do
                  yield binding.Root, 65536L
              for root in request.Roots do
                  yield root.Directory, metadataBytes
              for _, root, _, pin in seedCopies do
                  yield root, fst (content pin) + 4096L ]
            |> List.groupBy (fun (location, _) -> location.Identity.Device)
            |> List.map (fun (_, entries) -> fst entries.Head, entries |> List.sumBy snd)

        let capacity =
            requirements
            |> List.map (fun (root, needed) -> let free = available root in root, needed, free)

        if capacity |> List.exists (fun (_, needed, free) -> free < needed) then
            raise (
                RecoveryException(
                    RecoveryError.Unavailable
                        "There is not enough storage for the required copies and links."
                )
            )

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

        { Visibility = visibility
          View = view
          Managed = managed
          Bindings = bindings
          SeedCopies = seedCopies
          CopiedBytes = copiedBytes
          SeedBytes = seedBytes
          Capacity = capacity }
