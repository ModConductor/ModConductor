namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.DeploymentRecovery

module internal RuntimeDataTarget =
    let path (evidence: InstallationEvidence) =
        if evidence.DefinitionId <> GameId.StarfieldSteam then
            None
        else
            match evidence.Locations.Documents with
            | ModConductor.GameContexts.Location.Located(documents, _) ->
                Some(Path.Combine(documents, "Data"))
            | ModConductor.GameContexts.Location.Unavailable reason -> raise (IOException reason)

    let select (evidence: InstallationEvidence) (profile: Guid) current originals =
        match path evidence with
        | None -> current, originals
        | Some target ->
            let parent =
                ModConductor.ProfileGameData.DataLocations.root (Path.GetDirectoryName target)
                |> Result.defaultWith (ModConductor.ProfileGameData.ProfileDataException >> raise)

            let documents: Location =
                { Path = parent.Path
                  Identity = parent.Identity }

            let data = GameViews.child documents "Data"

            let saved =
                GameViews.child documents (".mod-conductor-data-originals-" + profile.ToString("N"))

            data, saved
