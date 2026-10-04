namespace ModConductor.Thunderstore

open System.Collections.Generic
open System.Threading
open System.Threading.Tasks

module Dependencies =
    let resolve (reader: IPackageReader) (root: VersionReference) (token: CancellationToken) =
        let versions = Dictionary<PackageReference, string>()
        let visiting = HashSet<PackageReference>()
        let complete = HashSet<PackageReference>()
        let ordered = ResizeArray<PackageDetails>()

        let rec visit (reference: VersionReference) =
            task {
                if token.IsCancellationRequested then
                    return Error Problem.Cancelled
                elif visiting.Contains reference.Package then
                    return
                        Error(
                            Problem.Requirements(
                                "Dependency cycle: " + VersionReference.label reference
                            )
                        )
                elif
                    versions.ContainsKey reference.Package
                    && versions[reference.Package] <> reference.Version
                then
                    return
                        Error(
                            Problem.Requirements(
                                PackageReference.label reference.Package
                                + " requires both "
                                + versions[reference.Package]
                                + " and "
                                + reference.Version
                                + "."
                            )
                        )
                elif complete.Contains reference.Package then
                    return Ok()
                else
                    versions[reference.Package] <- reference.Version
                    visiting.Add reference.Package |> ignore
                    let! result = reader.Details(reference.Package, Some reference.Version, token)

                    match result with
                    | Error error -> return Error error
                    | Ok value -> return! visitDetails value
            }

        and visitDetails (value: PackageDetails) =
            task {
                let mutable problem = None

                for dependency in value.Dependencies do
                    if problem.IsNone then
                        if not dependency.Available then
                            problem <-
                                Some(
                                    Problem.Requirements(
                                        VersionReference.label dependency.Reference
                                        + " is not available."
                                    )
                                )
                        else
                            let! found = visit dependency.Reference

                            match found with
                            | Error error -> problem <- Some error
                            | Ok() -> ()

                match problem with
                | Some error -> return Error error
                | None ->
                    visiting.Remove value.Reference.Package |> ignore
                    complete.Add value.Reference.Package |> ignore
                    ordered.Add value
                    return Ok()
            }

        task {
            let! result = visit root
            return result |> Result.map (fun () -> Seq.toList ordered)
        }
