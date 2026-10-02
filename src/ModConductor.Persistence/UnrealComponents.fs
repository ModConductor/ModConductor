namespace ModConductor.Persistence

open System.IO
open ModConductor.GameContexts
open ModConductor.Unreal
open ModConductor.FilePlanning
open ModConductor.DeploymentRecovery
open ModConductor.DeploymentPlanning
open ModConductor.Platform

module internal UnrealComponents =
    let private descriptors
        (database: StateDatabase)
        workspace
        field
        (version: ModConductor.ModLibrary.ModVersion)
        =
        let root =
            (WorkspaceRows.find database.Connection null workspace).Value.Receipt.Workspace

        let library = (LibraryRows.library database.Connection null workspace).Value
        use parent = HeldDirectory.Open(root.Path, root.Identity)
        use held = parent.Directory(library.Name, library.Identity)

        version.Entries
        |> List.filter (fun entry ->
            System.String.Equals(
                Path.GetExtension(LogicalPath.display entry.Path),
                ".uplugin",
                System.StringComparison.OrdinalIgnoreCase
            ))
        |> List.fold
            (fun state entry ->
                state
                |> Result.bind (fun rows ->
                    let payload =
                        (LibraryRows.payload database.Connection null entry.Payload.Id).Value

                    LibraryFiles.verify held payload

                    let stream, _ =
                        held.Read(
                            LibraryFiles.payloadName entry.Payload.Id,
                            Some payload.Identity
                        )

                    use stream = stream
                    use bytes = new MemoryStream()
                    stream.CopyTo bytes

                    PluginDescriptor.gameFeature field (bytes.ToArray())
                    |> Result.map (fun feature ->
                        let parts = LogicalPath.components entry.Path

                        (List.take (parts.Length - 1) parts,
                         Path.GetFileNameWithoutExtension(LogicalPath.display entry.Path),
                         feature)
                        :: rows)))
            (Ok [])

    let read (database: StateDatabase) gameRoot (sources: PlanSources) selected definition client =
        sources.Profile.Mods
        |> List.filter (fun row -> selected |> Map.tryFind row.ModId |> Option.exists fst)
        |> List.fold
            (fun state row ->
                state
                |> Result.bind (fun (rows, working) ->
                    let metadata =
                        (LibraryRows.find database.Connection null row.ModId).Value.Entry.Metadata

                    let loader = LoaderSource.matches client.Loader metadata.Source

                    let descriptors =
                        match client.Loader.Mechanism, row.Version with
                        | UnrealModMechanism.CookedPlugins layout, Some version ->
                            descriptors
                                database
                                sources.Stamp.WorkspaceId
                                layout.GameFeatureField
                                version
                        | _ -> Ok []

                    descriptors
                    |> Result.bind (fun descriptors ->
                        PackageRoutes.review
                            definition
                            client
                            sources.Stamp.WorkspaceId
                            gameRoot
                            loader
                            descriptors
                            row)
                    |> Result.map (fun reviewed ->
                        let reviewed =
                            if working && loader then
                                { reviewed with Writable = [] }
                            else
                                reviewed

                        reviewed :: rows, working || loader)))
            (Ok([], false))
        |> Result.map (fst >> List.rev)
        |> Result.mapError RecoveryError.Unavailable

    let private loaderControls
        (database: StateDatabase)
        workspace
        policy
        target
        (loader: ReviewedComponent)
        =
        loader.Mod.Mappings
        |> List.tryPick (fun route ->
            match route.SourcePrefix, route.TargetPrefix with
            | PlanPath.At source, PlanPath.At destination when
                TargetPolicy.key policy destination = TargetPolicy.key policy target
                ->
                loader.Mod.Version.Value.Entries
                |> List.tryFind (fun entry -> entry.Path = source)
            | _ -> None)
        |> Option.map (fun entry ->
            let root =
                (WorkspaceRows.find database.Connection null workspace).Value.Receipt.Workspace

            let library = (LibraryRows.library database.Connection null workspace).Value
            use parent = HeldDirectory.Open(root.Path, root.Identity)
            use held = parent.Directory(library.Name, library.Identity)
            let payload = (LibraryRows.payload database.Connection null entry.Payload.Id).Value
            LibraryFiles.verify held payload

            let stream, _ =
                held.Read(LibraryFiles.payloadName entry.Payload.Id, Some payload.Identity)

            use stream = stream
            use reader = new StreamReader(stream)
            reader.ReadToEnd())

    let orderedFiles (database: StateDatabase) workspace definition client gameRoot components =
        match client.Loader.Mechanism with
        | UnrealModMechanism.CookedPlugins _ -> []
        | UnrealModMechanism.UE4SS layout ->
            let target =
                { Root = gameRoot
                  Path =
                    WorkingPaths.logical (
                        WorkingPaths.binary definition
                        @ WorkingPaths.parts layout.Mods
                        @ [ "mods.txt" ]
                    ) }

            let loaders, regular =
                components
                |> List.sortBy _.Mod.Priority
                |> List.partition (fun reviewed ->
                    let metadata =
                        (LibraryRows.find database.Connection null reviewed.Mod.ModId)
                            .Value.Entry.Metadata

                    LoaderSource.matches client.Loader metadata.Source)

            let defaults =
                loaders
                |> List.tryLast
                |> Option.bind (
                    loaderControls database workspace definition.TargetPolicy target.Path
                )

            let controls =
                LuaOrder.create
                    (PackageRoutes.luaNames definition layout loaders)
                    defaults
                    (PackageRoutes.luaNames definition layout regular)

            [ target, System.Text.Encoding.UTF8.GetBytes controls ]
