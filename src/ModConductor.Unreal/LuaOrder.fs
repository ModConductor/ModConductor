namespace ModConductor.Unreal

open System

module LuaOrder =
    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private controls (text: string) =
        text.Split('\n')
        |> Array.choose (fun line ->
            if line.Contains ';' then
                None
            else
                match line.Replace(" ", "").Trim().Split(':', 2) with
                | [| name; value |] when name <> "" -> Some(name, value.StartsWith '1')
                | _ -> None)
        |> Array.toList

    let create bundled defaults regular =
        let defaults =
            defaults
            |> Option.map controls
            |> Option.defaultWith (fun () -> bundled |> List.map (fun name -> name, true))

        // UE4SS's bundled Keybinds control follows mods that register their bindings.
        let trailing =
            defaults
            |> List.tryLast
            |> Option.filter (fun (name, _) -> same name "Keybinds")
            |> Option.map (fun (name, enabled) ->
                name, enabled || (regular |> List.exists (same name)))

        let regular =
            regular
            |> List.filter (fun name ->
                trailing |> Option.forall (fun (last, _) -> not (same name last)))

        let defaults =
            defaults
            |> List.filter (fun (name, _) ->
                not (regular |> List.exists (same name))
                && (trailing |> Option.forall (fun (last, _) -> not (same name last))))

        let rows =
            defaults
            @ (regular |> List.map (fun name -> name, true))
            @ Option.toList trailing

        rows
        |> List.map (fun (name, enabled) -> name + " : " + (if enabled then "1" else "0"))
        |> String.concat "\n"
        |> fun text -> text + "\n"
