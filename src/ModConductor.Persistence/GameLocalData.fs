namespace ModConductor.Persistence

open System
open System.IO
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.ProfileGameData

/// Game-local configuration is writable in the existing owned profile view only.
module internal GameLocalData =
    let private folder (parent: ModConductor.DeploymentRecovery.Location) (relative: string) =
        relative.Split([| '/'; '\\' |], StringSplitOptions.RemoveEmptyEntries)
        |> Array.fold GameViews.child parent

    let private seed (source: string) (target: ModConductor.DeploymentRecovery.Location) names =
        if Directory.Exists source then
            let selected =
                DataLocations.root source |> Result.defaultWith (ProfileDataException >> raise)

            use original = HeldDirectory.Open(selected.Path, selected.Identity)
            use owned = HeldDirectory.Open(target.Path, target.Identity)

            for declared in names do
                let actual =
                    original.Names
                    |> Seq.filter (fun name ->
                        name.Equals(declared, StringComparison.OrdinalIgnoreCase))
                    |> Seq.toList

                match actual with
                | [ name ] when owned.InspectEntry declared |> Option.isNone ->
                    let stream, _ = original.Read(name, None)
                    use stream = stream
                    let output, _ = owned.Create declared
                    use output = output
                    stream.CopyTo output
                    output.Flush true
                | []
                | [ _ ] -> ()
                | _ -> raise (IOException(declared + " has ambiguous filenames."))

    let private projectView workspace profile (state: GameContextState) =
        match state.Binding with
        | None -> state
        | Some binding when
            binding.NeedsCheck
            || not binding.Evidence.Valid
            || not (GameCatalog.isBethesda binding.GameId)
            ->
            state
        | Some binding ->
            let rules = GameCatalog.rules binding.GameId

            if rules.GameSettings.IsNone && rules.GamePlugins.IsNone then
                state
            else
                let definition = GameCatalog.forGame binding.GameId
                let root, _, _ = GameViews.ensure workspace profile definition

                let locate relative names fallback =
                    match relative with
                    | None -> fallback
                    | Some relative ->
                        let target = folder root relative
                        seed (Path.Combine(binding.Evidence.RootPath, relative)) target names
                        Location.Located(HostPath.value target.Path, true)

                let locations = binding.Evidence.Locations

                let projected =
                    { locations with
                        Documents =
                            locate rules.GameSettings definition.IniFiles locations.Documents
                        LocalAppData =
                            let names =
                                if rules.Activation = PluginActivation.MorrowindIni then
                                    []
                                else
                                    [ "plugins.txt"; "loadorder.txt" ]

                            locate rules.GamePlugins names locations.LocalAppData }

                { state with
                    Binding =
                        Some
                            { binding with
                                Evidence =
                                    { binding.Evidence with
                                        Locations = projected } } }

    let project workspace profile state =
        try
            Ok(projectView workspace profile state)
        with
        | ProfileDataException error -> Error error
        | :? IOException as error -> Error(ProfileDataError.Unavailable error.Message)
        | :? UnauthorizedAccessException ->
            Error(ProfileDataError.Unavailable "The profile game files cannot be accessed.")
