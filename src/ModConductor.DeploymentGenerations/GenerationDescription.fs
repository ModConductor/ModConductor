namespace ModConductor.DeploymentGenerations

open ModConductor.DeploymentPlanning
open ModConductor.DeploymentRecovery

module internal GenerationDescription =
    let observed (request: BuildRequest) (sources: GenerationSources) visibility =
        (if request.LinkedBase then Map.empty else sources.Files)
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
                      Length = SnapshotFile.length file
                      Modified = SnapshotFile.metadata file |> Option.map _.Modified })
            | _ -> None)

    let references visibility =
        Visibility.files visibility
        |> Map.toList
        |> List.collect (fun (target, _) -> Visibility.sources target visibility)
        |> List.map _.Source
        |> List.distinct
