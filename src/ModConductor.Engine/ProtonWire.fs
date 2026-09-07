namespace ModConductor.Engine

open System
open ModConductor.GameContexts
open ModConductor.SteamDiscovery
open ModConductor.Protocol.V1

module internal ProtonWire =
    let selection (value: ProtonSelection) =
        let result =
            ProtonSelectionInfo(
                AppId = value.AppId,
                CompatData = value.CompatData,
                RuntimeDirectory = value.RuntimeDirectory,
                ToolId = value.ToolId
            )

        match value.Association with
        | ProtonAssociation.Manual -> result.Manual <- true
        | ProtonAssociation.Steam(root, library) ->
            result.Steam <- ProtonSteamAssociation(SteamRoot = root, Library = library)

        result

    let readSelection (value: ProtonSelectionInfo) =
        if isNull value then
            None
        else
            let path value =
                if
                    String.IsNullOrWhiteSpace value
                    || value.Length > 4096
                    || not (IO.Path.IsPathFullyQualified value)
                then
                    ModLibraryWire.reject "Select an absolute Proton folder."

                value

            if value.AppId <> Skyrim.definition.SteamAppId || value.ToolId.Length > 1024 then
                ModLibraryWire.reject "The Proton app or tool selection is invalid."

            let association =
                match value.AssociationCase with
                | ProtonSelectionInfo.AssociationOneofCase.Manual when value.Manual ->
                    ProtonAssociation.Manual
                | ProtonSelectionInfo.AssociationOneofCase.Steam ->
                    ProtonAssociation.Steam(path value.Steam.SteamRoot, path value.Steam.Library)
                | _ -> ModLibraryWire.reject "Select the Proton association."

            Some
                { AppId = value.AppId
                  Association = association
                  CompatData = path value.CompatData
                  RuntimeDirectory = path value.RuntimeDirectory
                  ToolId = value.ToolId }

    let file (value: ContextFileEvidence) =
        ProtonContextFile(
            Path = value.Path,
            NativeIdentity = NativeIdentity.value value.Identity,
            Sha256 = value.Sha256
        )

    let source (value: SteamSourceFile) =
        ProtonContextFile(
            Path = value.Path,
            NativeIdentity = NativeIdentity.value value.Identity,
            Sha256 = value.Sha256
        )

    let evidence (value: ProtonEvidence) =
        let result =
            ProtonContextEvidence(
                Selection = selection value.Selection,
                PrefixPath = value.PrefixPath,
                PrefixIdentity = NativeIdentity.value value.PrefixIdentity,
                CompatDataIdentity = NativeIdentity.value value.CompatDataIdentity,
                RuntimeIdentity = NativeIdentity.value value.RuntimeIdentity,
                RuntimeName = value.RuntimeName,
                RuntimeVersion = value.RuntimeVersion,
                Launcher = file value.Launcher
            )

        value.PrefixVersion |> Option.iter (fun v -> result.PrefixVersion <- v)
        value.PerGameTool |> Option.iter (fun v -> result.PerGameTool <- v)
        value.GlobalTool |> Option.iter (fun v -> result.GlobalTool <- v)
        value.MappingProblem |> Option.iter (fun v -> result.MappingProblem <- v)
        result.Metadata.AddRange(value.Metadata |> Seq.map file)

        result.Paths.AddRange(
            value.Paths
            |> Seq.map (fun p ->
                let item = ProtonUserPath(Name = p.Name)
                p.WindowsPath |> Option.iter (fun v -> item.WindowsPath <- v)

                match p.HostLocation with
                | Location.Located(path, exists) ->
                    item.Located <- ProtonLocatedPath(Path = path, Exists = exists)
                | Location.Unavailable reason -> item.UnavailableReason <- reason

                item)
        )

        result
