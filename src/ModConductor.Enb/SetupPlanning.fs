namespace ModConductor.Enb

open System
open System.Text

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

    let configureSkyrimPrefs (content: string) =
        let required = [ "bSAOEnable", "0"; "bEnableImprovedSnow", "0" ]

        let lines = content.Replace("\r\n", "\n").Split('\n') |> ResizeArray
        let section = "Display"
        let mutable current = ""

        let found =
            Collections.Generic.Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)

        let previous =
            Collections.Generic.Dictionary<string, string option>(StringComparer.OrdinalIgnoreCase)

        let mutable displayEnd = -1

        for index in 0 .. lines.Count - 1 do
            let trimmed = lines[index].Trim()

            if trimmed.StartsWith("[") && trimmed.EndsWith("]") then
                if String.Equals(current, section, StringComparison.OrdinalIgnoreCase) then
                    displayEnd <- index

                current <- trimmed.Substring(1, trimmed.Length - 2).Trim()
            elif String.Equals(current, section, StringComparison.OrdinalIgnoreCase) then
                let split = lines[index].IndexOf('=')

                if split > 0 then
                    let key = lines[index].Substring(0, split).Trim()

                    required
                    |> List.tryFind (fun (wanted, _) ->
                        String.Equals(key, wanted, StringComparison.OrdinalIgnoreCase))
                    |> Option.iter (fun (wanted, value) ->
                        if found.ContainsKey wanted then
                            invalidOp (wanted + " occurs more than once in SkyrimPrefs.ini.")

                        found.Add(wanted, index)
                        previous.Add(wanted, Some(lines[index].Substring(split + 1).Trim()))
                        lines[index] <- key + "=" + value)

        if String.Equals(current, section, StringComparison.OrdinalIgnoreCase) then
            displayEnd <- lines.Count

        if displayEnd < 0 then
            if lines.Count > 0 && lines[lines.Count - 1] <> "" then
                lines.Add ""

            lines.Add("[" + section + "]")
            displayEnd <- lines.Count

        for key, value in required |> List.rev do
            if not (found.ContainsKey key) then
                lines.Insert(displayEnd, key + "=" + value)
                previous.Add(key, None)

        let result = String.Join("\n", lines)

        let prior =
            required
            |> List.map (fun (key, _) -> ("SkyrimPrefs.ini", section, key), previous[key])
            |> Map.ofList

        result, prior

    let restoreSkyrimPrefs (content: string) (owned: Map<string, string * string option>) =
        let lines = content.Replace("\r\n", "\n").Split('\n') |> ResizeArray
        let mutable current = ""
        let remove = ResizeArray<int>()
        let conflicts = ResizeArray<string>()
        let found = Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase)

        for index in 0 .. lines.Count - 1 do
            let trimmed = lines[index].Trim()

            if trimmed.StartsWith("[") && trimmed.EndsWith("]") then
                current <- trimmed.Substring(1, trimmed.Length - 2).Trim()
            elif String.Equals(current, "Display", StringComparison.OrdinalIgnoreCase) then
                let split = lines[index].IndexOf('=')

                if split > 0 then
                    let key = lines[index].Substring(0, split).Trim()

                    owned.TryFind key
                    |> Option.iter (fun (applied, prior) ->
                        found.Add key |> ignore
                        let currentValue = lines[index].Substring(split + 1).Trim()

                        if String.Equals(currentValue, applied, StringComparison.Ordinal) then
                            match prior with
                            | Some value -> lines[index] <- key + "=" + value
                            | None -> remove.Add index
                        elif
                            prior
                            |> Option.exists (fun value ->
                                String.Equals(currentValue, value, StringComparison.Ordinal))
                        then
                            ()
                        else
                            conflicts.Add key)

        for KeyValue(key, (_, prior)) in owned do
            if not (found.Contains key) then
                match prior with
                | None -> ()
                | Some _ -> conflicts.Add key

        for index in remove |> Seq.sortDescending do
            lines.RemoveAt index

        String.Join("\n", lines), List.ofSeq conflicts
