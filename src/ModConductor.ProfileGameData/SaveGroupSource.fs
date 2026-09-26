namespace ModConductor.ProfileGameData

open System
open ModConductor.Bethesda
open ModConductor.GameContexts
open ModConductor.Platform

module internal SaveGroupSource =
    let private result = ProfileDataResultFlow.result

    let same (left: string) (right: string) =
        left.Equals(right, StringComparison.OrdinalIgnoreCase)

    let title (scope: ProfileDataScope) =
        match scope.Game.Binding with
        | Some binding when
            not binding.NeedsCheck
            && binding.Evidence.Valid
            && binding.Evidence.DefinitionId = Skyrim.definition.Id
            && binding.Evidence.DefinitionRevision = Skyrim.definition.Revision
            && (match binding.Evidence.Platform, binding.Evidence.Proton, binding.Proton with
                | ContextPlatform.Windows, None, None -> true
                | ContextPlatform.Proton, Some evidence, Some selection ->
                    selection.AppId = Skyrim.definition.SteamAppId && evidence.Selection = selection
                | _ -> false)
            ->
            Ok binding
        | _ ->
            Error(
                ProfileDataError.Unavailable
                    "Select and refresh the Skyrim Special Edition Steam context first."
            )

    let profileRoot scope =
        match scope.Profile with
        | Some profile when profile.SavesInitialized && profile.Saves.IsSome ->
            Ok profile.Saves.Value
        | _ ->
            Error(
                ProfileDataError.Invalid "Enable and initialize local saves for this profile first."
            )

    let private locatedRoot (binding: GameBinding) =
        match binding.Evidence.Locations.Saves with
        | Location.Located(path, true) -> Ok(Some(DataLocations.root path))
        | Location.Located(_, false) -> Ok None
        | Location.Unavailable reason -> Error(ProfileDataError.Unavailable reason)

    let private windowsPath (binding: GameBinding) =
        binding.Evidence.Proton
        |> Option.bind (fun proton ->
            proton.Paths
            |> List.tryFind (fun path ->
                path.Name.Equals("Saves", StringComparison.OrdinalIgnoreCase))
            |> Option.bind _.WindowsPath)

    let source scope source =
        result {
            let! binding = title scope

            match source with
            | ProfileSaveSource.Profile ->
                let! root = profileRoot scope

                return
                    Some root,
                    { HostPath = HostPath.value root.Path
                      WindowsPath = None }
            | ProfileSaveSource.Global ->
                let! root = locatedRoot binding

                return
                    root,
                    { HostPath =
                        match binding.Evidence.Locations.Saves with
                        | Location.Located(path, _) -> path
                        | Location.Unavailable _ -> ""
                      WindowsPath = windowsPath binding }
        }
