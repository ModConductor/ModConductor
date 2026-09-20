namespace ModConductor.Enb

open System

module EnbSetupPlanning =
    let private ownedDlls = set [ "d3d11.dll"; "d3dcompiler_46e.dll" ]

    let reviewOwnership profile generation existing =
        match existing with
        | None -> Ok()
        | Some current when current.ProfileId = profile && current.GenerationId = generation -> Ok()
        | Some current ->
            Error(
                EnbProblem.ProfileConflict(
                    current.Renderer
                    + " with "
                    + current.Preset
                    + " already owns this profile's renderer targets. Remove it before selecting Lean ENB."
                )
            )

    let reviewForeignFiles (foreign: string list) =
        foreign
        |> List.tryFind (fun value -> ownedDlls.Contains(value.ToLowerInvariant()))
        |> function
            | Some conflict -> Error(EnbProblem.ForeignDllConflict conflict)
            | None -> Ok()

    let runtime
        generation
        gameSha256
        selectedRuntime
        dllOverrides
        (previous: Map<string * string * string, string>)
        =
        let values =
            [ "SkyrimPrefs.ini", "Display", "bSAOEnable", "0"
              "SkyrimPrefs.ini", "Display", "bEnableImprovedSnow", "0" ]

        { GenerationId = generation
          GameSha256 = gameSha256
          Environment = [ "WINEDLLOVERRIDES", Some dllOverrides ]
          Configuration =
            values
            |> List.map (fun (file, section, key, required) ->
                { File = file
                  Section = section
                  Key = key
                  RequiredValue = required
                  PreviousValue = previous.TryFind(file, section, key) })
          PreservedRuntime = selectedRuntime
          SteamOptionsChanged = false
          ExternalTools = [] }

    let validate plan =
        if plan.SteamOptionsChanged then
            Error(
                EnbProblem.IncompatibleRuntime
                    "The ENB setup plan must not edit Steam launch options."
            )
        elif not plan.ExternalTools.IsEmpty then
            Error(
                EnbProblem.IncompatibleRuntime
                    "The ENB setup plan must not invoke protontricks or winecfg."
            )
        elif String.IsNullOrWhiteSpace plan.PreservedRuntime then
            Error(
                EnbProblem.IncompatibleRuntime
                    "Select a checked Windows or Proton runtime before ENB setup."
            )
        else
            Ok plan
