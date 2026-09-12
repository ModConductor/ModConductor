namespace ModConductor.Fomod

open System
open ModConductor.ArchiveInstallation

module Conditions =
    let private version (text: string) =
        let parts = text.Split('.')

        if parts.Length < 1 || parts.Length > 4 then
            None
        else
            let values = parts |> Array.map Int32.TryParse

            if values |> Array.forall (fun (parsed, value) -> parsed && value >= 0) then
                Some(
                    Array.append (values |> Array.map snd) (Array.zeroCreate (4 - values.Length))
                    |> Array.toList
                )
            else
                None

    let private minimum required observed =
        match version required, observed with
        | None, _ ->
            Fact.Unknown
                "The installer requires an unsupported version value. Use the manual layout."
        | _, Fact.Unknown why -> Fact.Unknown why
        | Some required, Fact.Known observed ->
            match version observed with
            | Some actual -> Fact.Known(actual >= required)
            | None ->
                Fact.Unknown
                    "The game version cannot be compared. Refresh the game context or use the manual layout."

    let rec evaluate (facts: Facts) flags condition =
        let combine wanted values =
            let rec loop unknown values =
                match values with
                | [] ->
                    unknown
                    |> Option.map Fact.Unknown
                    |> Option.defaultValue (Fact.Known(not wanted))
                | head :: rest ->
                    match evaluate facts flags head with
                    | Fact.Known value when value = wanted -> Fact.Known wanted
                    | Fact.Known _ -> loop unknown rest
                    | Fact.Unknown why -> loop (Some(defaultArg unknown why)) rest

            loop None values

        match condition with
        | Condition.All values -> combine false values
        | Condition.Any values -> combine true values
        | Condition.Flag(name, value) -> Fact.Known(Map.tryFind name flags = Some value)
        | Condition.File(path, state) ->
            match facts.Files |> Map.tryFind (Destinations.key path) with
            | Some(Fact.Known value) -> Fact.Known(value = state)
            | Some(Fact.Unknown why) -> Fact.Unknown why
            | None ->
                Fact.Unknown
                    "This installer file requirement was not checked. Reload the installer."
        | Condition.GameVersion value -> minimum value facts.GameVersion
        | Condition.FommVersion value -> minimum value facts.FommVersion
        | Condition.ExtenderVersion value -> minimum value facts.ExtenderVersion

    let optionType facts flags descriptor =
        match descriptor with
        | TypeDescriptor.Fixed kind -> Fact.Known kind
        | TypeDescriptor.Dependent(fallback, patterns) ->
            let rec first values =
                match values with
                | [] -> Fact.Known fallback
                | (condition, kind) :: tail ->
                    match evaluate facts flags condition with
                    | Fact.Known true -> Fact.Known kind
                    | Fact.Known false -> first tail
                    | Fact.Unknown why ->
                        match first tail with
                        | Fact.Known following when following = kind -> Fact.Known kind
                        | _ -> Fact.Unknown why

            first patterns

    let filePaths (definition: Definition) =
        let rec paths condition =
            match condition with
            | Condition.All values
            | Condition.Any values -> List.collect paths values
            | Condition.File(path, _) -> [ path ]
            | _ -> []

        let typePaths descriptor =
            match descriptor with
            | TypeDescriptor.Fixed _ -> []
            | TypeDescriptor.Dependent(_, patterns) -> patterns |> List.collect (fst >> paths)

        [ yield! paths definition.Dependency
          for step in definition.Steps do
              yield! paths step.Visible

              for group in step.Groups do
                  for option in group.Options do
                      yield! typePaths option.Type
          for condition, _ in definition.Conditional do
              yield! paths condition ]
        |> List.distinctBy Destinations.key
