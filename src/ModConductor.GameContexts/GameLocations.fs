namespace ModConductor.GameContexts

open System.IO

module GameLocations =
    let private bethesda game root (locations: UserLocations) =
        let rules = GameCatalog.rules game

        let selected (relative: string option) previous =
            match relative with
            | None -> previous
            | Some path ->
                let parts = path.Replace('\\', '/').Split('/') |> Array.filter ((<>) "")
                let folder = Array.fold (fun parent name -> Path.Combine(parent, name)) root parts
                Location.Located(folder, Directory.Exists folder)

        { Documents = selected rules.GameSettings locations.Documents
          LocalAppData = selected rules.GamePlugins locations.LocalAppData
          Saves =
            if rules.SaveExtension.IsNone then
                Location.Unavailable "This title has no local saves."
            else
                selected rules.GameSaves locations.Saves }

    let apply game root locations =
        if GameCatalog.isBethesda game then
            bethesda game root locations
        else
            locations
