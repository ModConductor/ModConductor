namespace ModConductor.FilePlanning

open System
open System.IO
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.DeploymentPlanning

/// Starfield's user Data wins over installation Data; mods keep their normal higher tier.
module internal GameDataInputs =
    let primaryEvidence (evidence: InstallationEvidence) =
        match evidence.Locations.Documents with
        | Location.Located(documents, _) ->
            let path = Path.Combine(documents, "Data")

            if not (Directory.Exists path) then
                Ok None
            else
                HostPath.create path
                |> Result.bind (fun host -> RootSelection.select host |> Result.mapError string)
                |> Result.bind (fun selected ->
                    match (RootSelection.facts selected).File with
                    | Known identity ->
                        Ok(
                            Some
                                { evidence with
                                    DataPath = Some path
                                    DataIdentity = Some identity }
                        )
                    | Unknown reason -> Error reason)
                |> Result.mapError FilePlanError.ContextUnavailable
        | Location.Unavailable reason -> Error(FilePlanError.ContextUnavailable reason)

    let private merge (secondary: GameObservation) (primary: GameObservation) =
        let key path =
            (LogicalPath.display path).ToUpperInvariant()

        let rows =
            secondary.Entries @ primary.Entries
            |> List.groupBy (fun entry -> key entry.Path)
            |> List.map (snd >> List.last)

        let originals =
            primary.Entries
            |> List.filter (fun entry -> not entry.Directory)
            |> List.map (fun entry ->
                entry.Path,
                primary.Projection.Originals.TryFind entry.Path
                |> Option.defaultValue
                    { Root = primary.Root
                      RootIdentity = primary.Identity
                      Path = entry.Path
                      Identity = entry.Identity })
            |> Map.ofList

        let files =
            secondary.Snapshot.Files @ primary.Snapshot.Files
            |> List.groupBy (fun file -> key file.Path)
            |> List.map (snd >> List.last)

        { secondary with
            Inputs = [ secondary; primary ]
            Entries = rows
            Projection =
                { GameProjection.empty with
                    Originals = originals }
            EncodedBytes = secondary.EncodedBytes + primary.EncodedBytes
            Snapshot =
                { secondary.Snapshot with
                    Files = files
                    Generation = secondary.Snapshot.Generation + ":" + primary.Snapshot.Generation } }

    let acquire projection (evidence: InstallationEvidence) root progress token =
        if evidence.DefinitionId <> GameId.StarfieldSteam then
            GameFiles.acquireProjected projection evidence root progress token
        else
            primaryEvidence evidence
            |> Result.bind (fun primary ->
                GameFiles.acquireProjected GameProjection.empty evidence root progress token
                |> Result.bind (fun secondary ->
                    match primary with
                    | None -> Ok secondary
                    | Some evidence ->
                        GameFiles.acquireProjected projection evidence root progress token
                        |> Result.map (merge secondary)))
