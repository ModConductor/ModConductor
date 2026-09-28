namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationMaterialization =
    open GenerationFiles

    let private source (sources: GenerationSources) pin =
        sources.Files.TryFind pin
        |> Option.defaultWith (fun () ->
            RecoveryFiles.fail "A pinned source has no checked backing.")

    let files
        (request: BuildRequest)
        (sources: GenerationSources)
        (token: CancellationToken)
        (directory: Location)
        (managed: ResolvedFile list)
        =
        let name = request.Id.ToString("N")
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

        let resolvedFiles =
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
                    | LayerTier.Base when request.LinkedBase ->
                        let value = source sources pin in
                        verify pin value
                        value
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

                let length = length pin
                let hash = sha256 pin

                { Target = file.Target
                  Path = path
                  Identity = entry.Identity
                  Length = length
                  Sha256 = hash
                  Backing = Some backing })

        let ownedFiles =
            request.OwnedFiles
            |> List.map (fun (target, bytes) ->
                token.ThrowIfCancellationRequested()

                let path =
                    logical (target.Root.ToString("N") :: LogicalPath.components target.Path)

                let identity =
                    withCreatedParent directory path (fun parent name ->
                        let stream, identity = parent.Create name
                        use stream = stream
                        stream.Write(bytes, 0, bytes.Length)
                        stream.Flush true
                        identity)

                { Target = target
                  Path = path
                  Identity = identity
                  Length = int64 bytes.Length
                  Sha256 = None
                  Backing = None })

        resolvedFiles @ ownedFiles, secondaryRoot

    let working
        (sources: GenerationSources)
        (token: CancellationToken)
        (bindings: (WorkingLocation * TargetFile * bool * ResolvedFile list) list)
        (seedCopies: (Guid * Location * LogicalPath * SourcePin) list)
        =
        bindings
        |> List.map (fun (binding, target, isDirectory, _) ->
            if isDirectory then
                withCreatedParent binding.Root binding.Path (fun parent name ->
                    match parent.InspectEntry name with
                    | None -> use child = parent.CreateDirectory name in ()
                    | Some entry when entry.Kind = EntryKind.Directory -> ()
                    | _ ->
                        RecoveryFiles.fail "A declared output directory is not a real directory.")

            for _, root, path, pin in
                seedCopies
                |> List.filter (fun (declaration, _, _, _) -> declaration = binding.Declaration) do
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
                        Some entry.Identity
                    | None when not isDirectory && binding.Initialized -> None
                    | None when not isDirectory ->
                        let stream, identity = parent.Create name in
                        stream.Dispose()
                        Some identity
                    | _ -> RecoveryFiles.fail "A declared working entry changed.")

            { Target = target
              Directory = isDirectory
              Root = binding.Root
              Path = binding.Path
              Identity = identity })
