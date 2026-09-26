namespace ModConductor.DeploymentRecovery

open System
open System.IO
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal RecoveryLocations =
    let nested parent child =
        let relative = Path.GetRelativePath(parent, child)

        relative = "."
        || (not (Path.IsPathRooted relative)
            && relative <> ".."
            && not (
                relative.StartsWith(
                    ".." + string Path.DirectorySeparatorChar,
                    StringComparison.Ordinal
                )
            ))


    let overlappingRoots (left: RootBinding list) (right: RootBinding list) =
        left
        |> List.exists (fun first ->
            right
            |> List.exists (fun second ->
                first.Directory.Identity = second.Directory.Identity
                || nested
                    (HostPath.value first.Directory.Path)
                    (HostPath.value second.Directory.Path)
                || nested
                    (HostPath.value second.Directory.Path)
                    (HostPath.value first.Directory.Path)))

    let checkLocations
        (roots: RootBinding list)
        (boundaries: TargetFile list)
        (generation: Generation)
        =
        let canonical (location: Location) =
            use held = HeldDirectory.Open(location.Path, location.Identity)

            let selected =
                RootSelection.select location.Path
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "A selected fixture root is unavailable.")

            if RootSelection.path selected <> location.Path then
                RecoveryFiles.fail "Use the canonical selected root for deployment."

            HostPath.value location.Path

        let targets = roots |> List.map (fun root -> root, canonical root.Directory)
        let generationPath = canonical generation.Directory

        for root, _ in targets do
            let originals = canonical root.Originals

            if
                targets
                |> List.exists (fun (targetRoot, path) ->
                    targetRoot.Directory.Identity = root.Originals.Identity
                    || targetRoot.Directory.Identity = generation.Directory.Identity
                    || nested path generationPath
                    || nested generationPath path)
            then
                RecoveryFiles.fail
                    "Targets, generation storage and original storage must be disjoint."

            if
                generation.Directory.Identity = root.Originals.Identity
                || nested generationPath originals
                || nested originals generationPath
            then
                RecoveryFiles.fail "Generation and original storage must be disjoint."

            if root.Directory.Identity.Device <> root.Originals.Identity.Device then
                RecoveryFiles.fail "Original preservation requires the target volume."

        let nativePath target =
            let root = roots |> List.find (fun value -> value.Root.Id = target.Root)

            (HostPath.value root.Directory.Path, LogicalPath.components target.Path)
            ||> List.fold (fun parent child -> Path.Combine(parent, child))
            |> Path.GetFullPath

        let physicalTargets =
            (generation.Files |> List.map _.Target)
            @ (generation.Observed |> List.map _.Target)
            @ (generation.Working |> List.map _.Target)
            @ boundaries
            |> List.distinct
            |> List.map (fun target -> target, nativePath target)

        for index, (target, path) in List.indexed physicalTargets do
            for other, otherPath in physicalTargets |> List.skip (index + 1) do
                if
                    target.Root <> other.Root && (nested path otherPath || nested otherPath path)
                then
                    RecoveryFiles.fail "Deployment target roots contain overlapping paths."

        for root in roots do
            let originals = HostPath.value root.Originals.Path |> Path.GetFullPath

            if
                physicalTargets
                |> List.exists (fun (_, path) -> nested path originals || nested originals path)
            then
                RecoveryFiles.fail "A deployment target overlaps original storage."

    let checkExternalLocations (roots: RootBinding list) (generation: Generation) =
        let protectedLocations =
            generation.Directory
            :: (roots |> List.collect (fun root -> [ root.Directory; root.Originals ]))

        let external =
            (generation.Files |> List.choose _.Backing |> List.map _.Directory)
            @ (generation.Working |> List.map _.Root)

        let overlaps (a: Location) (b: Location) =
            a.Identity = b.Identity
            || nested (HostPath.value a.Path) (HostPath.value b.Path)
            || nested (HostPath.value b.Path) (HostPath.value a.Path)

        for location in external do
            let selected =
                RootSelection.select location.Path
                |> Result.defaultWith (fun _ ->
                    RecoveryFiles.fail "External generation storage is unavailable.")

            if RootSelection.path selected <> location.Path then
                RecoveryFiles.fail "Use canonical external storage locations."

            if protectedLocations |> List.exists (overlaps location) then
                RecoveryFiles.fail
                    "Payload and working storage must be outside deployment locations."

        for working in generation.Working do
            if
                generation.Files
                |> List.choose _.Backing
                |> List.exists (fun backing -> overlaps working.Root backing.Directory)
            then
                RecoveryFiles.fail
                    "Working storage must be separate from immutable payload storage."
