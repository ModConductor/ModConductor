namespace ModConductor.Unreal

open System
open System.IO
open System.Text.Json
open ModConductor.GameContexts
open ModConductor.Platform
open ModConductor.ModLibrary
open ModConductor.DeploymentPlanning

module PluginDescriptor =
    let gameFeature (field: string) (bytes: byte array) =
        try
            use document = JsonDocument.Parse(ReadOnlyMemory bytes)
            let mutable value = Unchecked.defaultof<JsonElement>

            if document.RootElement.ValueKind <> JsonValueKind.Object then
                Error "The Unreal plugin descriptor must contain an object."
            else
                Ok(
                    document.RootElement.TryGetProperty(field, &value)
                    && value.ValueKind = JsonValueKind.True
                )
        with :? JsonException ->
            Error "The Unreal plugin descriptor cannot be read."

module PackageRoutes =
    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private starts prefix value =
        List.length value >= List.length prefix
        && List.forall2 same prefix (List.take prefix.Length value)

    let private cooked (layout: CookedPluginLayout) descriptors parts =
        let declared =
            [ layout.Mods; layout.GameFeatures; layout.Configs ]
            |> List.map WorkingPaths.parts

        match declared |> List.tryFind (fun prefix -> starts prefix parts) with
        | Some _ -> Ok parts
        | None ->
            match parts with
            | first :: rest when same first "Configs" ->
                Ok(WorkingPaths.parts layout.Configs @ rest)
            | first :: rest when same first "GameFeatures" ->
                Ok(WorkingPaths.parts layout.GameFeatures @ rest)
            | _ ->
                descriptors
                |> List.filter (fun (prefix, _, _) -> starts prefix parts)
                |> List.sortByDescending (fun (prefix, _, _) -> prefix.Length)
                |> List.tryHead
                |> Option.map (fun (prefix, name, feature) ->
                    Ok(
                        WorkingPaths.parts (if feature then layout.GameFeatures else layout.Mods)
                        @ [ name ]
                        @ List.skip prefix.Length parts
                    ))
                |> Option.defaultValue (
                    Error
                        "Select a cooked Unreal plugin archive with its .uplugin descriptor and companion files."
                )

    let private lua (definition: GameDefinition) (layout: LuaLoaderLayout) loader parts =
        let binary = WorkingPaths.binary definition
        let mods = WorkingPaths.parts layout.Mods

        if starts binary parts then
            Ok parts
        elif loader then
            match parts with
            | [ first; name ] when same first "ue4ss" && same name "UE4SS-settings.ini" ->
                Ok(binary @ WorkingPaths.parts layout.SettingsFile)
            | first :: modsName :: rest when same first "ue4ss" && same modsName "Mods" ->
                Ok(binary @ mods @ rest)
            | first :: rest when same first "ue4ss" ->
                Ok(binary @ WorkingPaths.parts layout.Core @ rest)
            | _ -> Ok(binary @ parts)
        elif starts mods parts then
            Ok(binary @ parts)
        else
            match parts with
            | first :: rest when same first "Mods" -> Ok(binary @ mods @ rest)
            | first :: rest when same first "ue4ss" ->
                let tail =
                    match rest with
                    | next :: tail when same next "Mods" -> tail
                    | _ -> rest

                Ok(binary @ mods @ tail)
            | _ -> Ok(binary @ mods @ parts)

    let review
        (definition: GameDefinition)
        (client: UnrealClient)
        dataRoot
        gameRoot
        loader
        descriptors
        (selected: SelectedMod)
        =
        match selected.Version with
        | None -> Error "The selected Unreal package version is unavailable."
        | Some version ->
            let files =
                version.Entries
                |> List.fold
                    (fun state entry ->
                        state
                        |> Result.bind (fun rows ->
                            let parts = LogicalPath.components entry.Path

                            let target =
                                match client.Loader.Mechanism with
                                | UnrealModMechanism.CookedPlugins layout ->
                                    cooked layout descriptors parts
                                | UnrealModMechanism.UE4SS layout ->
                                    lua definition layout loader parts

                            target
                            |> Result.bind (fun target ->
                                LogicalPath.create target
                                |> Result.mapError (fun _ ->
                                    "The Unreal package destination is invalid."))
                            |> Result.map (fun target ->
                                { Source = entry.Path
                                  Root = ComponentRoot.GameRoot
                                  Destination = target
                                  Use = ComponentFileUse.Immutable }
                                :: rows)))
                    (Ok [])

            files
            |> Result.bind (fun files ->
                ComponentManifests.review
                    dataRoot
                    gameRoot
                    definition.TargetPolicy
                    { ModId = selected.ModId
                      Version = version
                      Priority = selected.Priority
                      Files = List.rev files }
                |> Result.mapError (fun _ ->
                    "The Unreal package routes conflict with their declared locations.")
                |> Result.map (fun reviewed ->
                    if loader then
                        { reviewed with
                            Writable = WorkingPaths.declarations definition client gameRoot }
                    else
                        reviewed))

    let luaNames
        (definition: GameDefinition)
        (layout: LuaLoaderLayout)
        (components: ReviewedComponent list)
        =
        let prefix = WorkingPaths.binary definition @ WorkingPaths.parts layout.Mods

        components
        |> List.sortBy _.Mod.Priority
        |> List.collect (fun reviewed ->
            reviewed.Mod.Mappings
            |> List.choose (fun route ->
                match route.TargetPrefix with
                | PlanPath.At path ->
                    let parts = LogicalPath.components path

                    if starts prefix parts then
                        match List.skip prefix.Length parts with
                        | name :: scripts :: file :: [] when
                            same scripts "scripts" && same file "main.lua"
                            ->
                            Some name
                        | _ -> None
                    else
                        None
                | PlanPath.Root -> None))
        |> List.distinct
