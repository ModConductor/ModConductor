namespace ModConductor.Persistence

open ModConductor.Platform
open ModConductor.ProfileGameData

module internal ProfileDataSnapshots =
    let private stored (value: StoredDataFile) =
        let root = DataLocations.current value.Root
        use directory = HeldDirectory.Open(root.Path, root.Identity)

        let file =
            match directory.InspectEntry value.Name with
            | Some entry when entry.Kind = EntryKind.RegularFile ->
                { value.File with
                    Identity = entry.Identity }
            | _ -> value.File

        { value with Root = root; File = file }

    let context
        connection
        transaction
        (game: ModConductor.GameContexts.GameContextState)
        (value: ProfileDataContext)
        =
        if value.Pending.IsSome then
            value
        else
            let documents = DataLocations.current value.Documents

            let applied =
                value.Applied
                |> Option.map (fun applied ->
                    let link =
                        applied.SaveLink
                        |> Option.map (fun _ ->
                            let profile =
                                ProfileDataRows.profile
                                    connection
                                    transaction
                                    value.Id
                                    applied.ProfileId

                            let target =
                                if applied.Options.Saves then
                                    profile
                                    |> Option.bind _.Saves
                                    |> Option.map (fun root -> HostPath.value root.Path)
                                else
                                    match game.Binding.Value.Evidence.Locations.Saves with
                                    | ModConductor.GameContexts.Location.Located(path, _) ->
                                        Some path
                                    | ModConductor.GameContexts.Location.Unavailable _ -> None

                            use directory = HeldDirectory.Open(documents.Path, documents.Identity)

                            match
                                target, directory.InspectEntry(DataEffects.linkName game value)
                            with
                            | Some target, Some entry when
                                entry.Kind = EntryKind.Link && entry.LinkTarget = Some target
                                ->
                                entry.Identity
                            | _ ->
                                DataFiles.fail
                                    "The profile save link changed. It was left untouched.")

                    { applied with
                        Originals =
                            applied.Originals
                            |> List.map (fun original ->
                                { original with
                                    Original = original.Original |> Option.map stored })
                        Plugins =
                            applied.Plugins
                            |> Option.map (fun plugins ->
                                { plugins with
                                    Original = plugins.Original |> Option.map stored })
                        SaveLink = link })

            { value with
                Workspace = DataLocations.current value.Workspace
                Documents = documents
                Storage = value.Storage |> Option.map DataLocations.current
                OriginalsRoot = value.OriginalsRoot |> Option.map DataLocations.current
                PluginRoot = value.PluginRoot |> Option.map DataLocations.current
                PluginOriginals = value.PluginOriginals |> Option.map DataLocations.current
                PluginObserved = value.PluginObserved |> Option.map (Option.map stored)
                Applied = applied }
