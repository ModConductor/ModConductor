namespace ModConductor.DeploymentGenerations

open System
open System.IO
open System.Threading
open ModConductor.Platform
open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationBuilder =
    open GenerationFiles

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

        let files, secondaryRoot =
            GenerationMaterialization.files request sources token directory managed

        let workingBindings =
            GenerationMaterialization.working sources token bindings seedCopies

        let observed = GenerationDescription.observed request sources visibility
        let references = GenerationDescription.references visibility

        let generation =
            { Id = request.Id
              PlanFingerprint = view.Fingerprint
              Directory = directory
              Files = files
              References = references
              Writable = sources.Input.Planning.Writable |> List.map _.Target
              Roots = sources.Input.Planning.Roots
              Provenance = None
              NativeTargets = Map.empty
              Working = workingBindings
              Observed = observed }

        GenerationRetirement.protect directory
        secondaryRoot |> Option.iter GenerationRetirement.protect
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
