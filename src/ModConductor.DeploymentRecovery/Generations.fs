namespace ModConductor.DeploymentRecovery

open System
open System.IO
open ModConductor.Platform
open ModConductor.DeploymentPlanning

module internal Generations =
    let capture id (directory: Location) plan input =
        match Planner.checkCurrent plan input with
        | Error _ -> raise (RecoveryException RecoveryError.InvalidPlan)
        | Ok() -> ()

        let view = Planner.view plan

        let files =
            view.ReadOnlyFiles
            |> List.map (fun file ->
                let components =
                    file.Target.Root.ToString("N") :: LogicalPath.components file.Target.Path

                let path =
                    LogicalPath.create components
                    |> Result.defaultWith (fun _ -> invalidOp "Invalid generation path.")

                let length, hash =
                    match file.Winner.Source with
                    | SourcePin.Mod(_, _, entry) -> entry.Payload.Length, entry.Payload.Sha256
                    | SourcePin.Snapshot(_, _, entry) -> entry.Length, entry.Sha256

                RecoveryFiles.withParent directory path (fun parent name ->
                    let stream, identity = parent.Read(name, None)
                    use stream = stream

                    if stream.Length <> length || RecoveryFiles.digest stream <> hash then
                        RecoveryFiles.fail "The prepared generation differs from its plan."

                    { Target = file.Target
                      Path = path
                      Identity = identity
                      Length = length
                      Sha256 = hash
                      Backing = None }))

        let seeds =
            view.Writable
            |> List.collect (function
                | WritableProjection.File(_, _, seed) -> Option.toList seed
                | WritableProjection.Subtree(_, _, _, seeds) -> seeds)

        let references =
            view.ReadOnlyFiles @ seeds
            |> List.collect (fun file -> file.Winner :: file.Alternatives)
            |> List.map (fun source -> source.Source)
            |> List.distinct

        { Id = id
          PlanFingerprint = view.Fingerprint
          Directory = directory
          Files = files
          References = references
          Writable = input.Writable |> List.map (fun value -> value.Target)
          Roots = input.Roots
          Observed = []
          Working = []
          NativeTargets = Map.empty }
