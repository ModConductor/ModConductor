namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationBuilder =
    open GenerationFiles

    let private source (sources: GenerationSources) pin =
        sources.Files.TryFind pin
        |> Option.defaultWith (fun () ->
            RecoveryFiles.fail "A pinned source has no checked backing.")

    let build
        available
        (request: BuildRequest)
        (sources: GenerationSources)
        (token: CancellationToken)
        =
        let prepared = GenerationPreparation.prepare available request sources token
        let visibility, view, managed = prepared.Visibility, prepared.View, prepared.Managed
        let bindings, seedCopies = prepared.Bindings, prepared.SeedCopies

        let copiedBytes, seedBytes, capacity =
            prepared.CopiedBytes, prepared.SeedBytes, prepared.Capacity

        let name = request.Id.ToString("N")
        use parent = HeldDirectory.Open(request.Storage.Path, request.Storage.Identity)
        use created = parent.CreateDirectory name

        let directory =
            { Path =
                HostPath.create (Path.Combine(HostPath.value request.Storage.Path, name))
                |> Result.defaultWith invalidOp
              Identity = created.Identity }
        // A failed capability probe leaves only this inactive owned generation directory.
        let probe =
            created.CreateLink(".link-probe", HostPath.value request.SecondaryStorage.Path, true)

        created.RemoveLink(".link-probe", probe)

        let mutable secondaryRoot: Location option = None

        let copySecondary pin =
            match GenerationPreparation.reused request pin with
            | Some backing ->
                verify pin backing
                backing
            | None ->
                let root =
                    match secondaryRoot with
                    | Some value -> value
                    | None ->
                        use storage =
                            HeldDirectory.Open(
                                request.SecondaryStorage.Path,
                                request.SecondaryStorage.Identity
                            )

                        use child = storage.CreateDirectory name

                        let value =
                            { Path =
                                HostPath.create (
                                    Path.Combine(HostPath.value request.SecondaryStorage.Path, name)
                                )
                                |> Result.defaultWith invalidOp
                              Identity = child.Identity }

                        secondaryRoot <- Some value
                        value

                let path = logical [ Guid.NewGuid().ToString("N") ]
                let identity = copy token pin (source sources pin) root path true

                { Directory = root
                  Path = path
                  Identity = identity
                  OwnerGeneration = Some request.Id }

        let files =
            managed
            |> List.map (fun file ->
                token.ThrowIfCancellationRequested()
                let pin = file.Winner.Source

                let backing =
                    match file.Winner.Precedence.Tier with
                    | LayerTier.Mod ->
                        let value = source sources pin in
                        verify pin value
                        value
                    | LayerTier.Secondary -> copySecondary pin
                    | LayerTier.Base -> invalidOp "Base files remain at the target."

                let path =
                    logical (
                        file.Target.Root.ToString("N") :: LogicalPath.components file.Target.Path
                    )

                let entry =
                    withCreatedParent directory path (fun parent name ->
                        parent.CreateLink(
                            name,
                            RecoveryFiles.path backing.Directory backing.Path,
                            false
                        ))

                let length, hash = content pin

                { Target = file.Target
                  Path = path
                  Identity = entry.Identity
                  Length = length
                  Sha256 = hash
                  Backing = Some backing })

        let workingBindings =
            bindings
            |> List.map (fun (binding, target, isDirectory, _) ->
                if isDirectory then
                    withCreatedParent binding.Root binding.Path (fun parent name ->
                        match parent.InspectEntry name with
                        | None -> use child = parent.CreateDirectory name in ()
                        | Some entry when entry.Kind = EntryKind.Directory -> ()
                        | _ ->
                            RecoveryFiles.fail
                                "A declared output directory is not a real directory.")

                for _, root, path, pin in
                    seedCopies
                    |> List.filter (fun (declaration, _, _, _) ->
                        declaration = binding.Declaration) do
                    seed token pin (source sources pin) root path |> ignore

                let identity =
                    RecoveryFiles.withParent binding.Root binding.Path (fun parent name ->
                        match parent.InspectEntry name with
                        | Some entry when
                            entry.Kind = (if isDirectory then
                                              EntryKind.Directory
                                          else
                                              EntryKind.RegularFile)
                            ->
                            entry.Identity
                        | None when not isDirectory ->
                            let stream, identity = parent.Create name in
                            stream.Dispose()
                            identity
                        | _ -> RecoveryFiles.fail "A declared working entry changed.")

                { Target = target
                  Directory = isDirectory
                  Root = binding.Root
                  Path = binding.Path
                  Identity = identity })

        let observed =
            sources.Files
            |> Map.toList
            |> List.choose (fun (pin, backing) ->
                match pin with
                | SourcePin.Snapshot(id, _, file) when
                    sources.Input.Planning.ReadOnly
                    |> List.exists (fun snapshot ->
                        snapshot.Id = id && snapshot.Kind = ReadOnlyLayerKind.Base)
                    ->
                    let contributions =
                        Visibility.files visibility
                        |> Map.toList
                        |> List.collect (fun (target, _) ->
                            Visibility.sources target visibility
                            |> List.filter (fun value -> value.Source = pin)
                            |> List.map (fun _ -> target))

                    contributions
                    |> List.tryHead
                    |> Option.map (fun target ->
                        { Target = target
                          Identity = backing.Identity
                          Length = file.Length
                          Sha256 = file.Sha256 })
                | _ -> None)

        let references =
            Visibility.files visibility
            |> Map.toList
            |> List.collect (fun (target, _) -> Visibility.sources target visibility)
            |> List.map _.Source
            |> List.distinct

        let generation =
            { Id = request.Id
              PlanFingerprint = view.Fingerprint
              Directory = directory
              Files = files
              References = references
              Writable = sources.Input.Planning.Writable |> List.map _.Target
              Roots = sources.Input.Planning.Roots
              NativeTargets = Map.empty
              Working = workingBindings
              Observed = observed }

        protect directory
        secondaryRoot |> Option.iter protect
        RecoveryFiles.verifyGeneration generation

        { Generation = generation
          Sources = sources.Stamp
          Measurements =
            { GenerationLinks = files.Length
              CopiedBytes = copiedBytes
              WritableSeedBytes = seedBytes
              BaseCopiedBytes = 0L
              AvailableBytes =
                capacity |> Seq.map (fun (_, _, free) -> free) |> GenerationCapacity.sum
              RequiredBytes =
                capacity |> Seq.map (fun (_, needed, _) -> needed) |> GenerationCapacity.sum } }
