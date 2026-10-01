namespace ModConductor.ProfileGameData

open System
open ModConductor.Platform
open ModConductor.GameContexts

module internal SettingsSource =
    let readStored (file: StoredDataFile) token =
        use root = HeldDirectory.Open(file.Root.Path, file.Root.Identity)
        DataFiles.readIni root file.Name (Some file.File) token

    let globalSettings game (context: ProfileDataContext) token =
        use documents =
            HeldDirectory.Open(context.Documents.Path, context.Documents.Identity)

        let originals = context.Applied |> Option.map _.Originals |> Option.defaultValue []
        let rules = GameCatalog.rules game.Binding.Value.GameId
        let saveIni = defaultArg rules.SaveOverrideIni rules.Ini

        DataLocations.iniNames game documents
        |> ProfileDataResultFlow.traverse (fun (declared, actual) ->
            let bytes =
                match
                    originals
                    |> List.tryFind (fun value ->
                        value.Name.Equals(actual, StringComparison.OrdinalIgnoreCase))
                with
                | Some original when context.Applied.Value.Options.Settings ->
                    Ok(original.Original |> Option.bind (fun file -> readStored file token))
                | _ ->
                    let observed = DataFiles.observe documents actual token
                    let current = DataFiles.readIni documents actual observed token

                    match context.Applied |> Option.bind _.SaveOverride, current with
                    | Some patch, Some bytes when declared = saveIni -> Ini.remove patch bytes
                    | _ -> Ok current

            bytes |> Result.map (fun value -> declared, value))
