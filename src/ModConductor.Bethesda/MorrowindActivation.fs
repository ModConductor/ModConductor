namespace ModConductor.Bethesda

open System
open System.Text

module MorrowindActivation =
    let private isSection (line: string) = line.Trim().StartsWith('[')

    let private isGameFiles (line: string) =
        line.Trim().Equals("[Game Files]", StringComparison.OrdinalIgnoreCase)

    let private entry (line: string) =
        let split = line.IndexOf('=')

        if split < 0 then
            None
        else
            let key = line.Substring(0, split).Trim()

            if not (key.StartsWith("GameFile", StringComparison.OrdinalIgnoreCase)) then
                None
            else
                match Int32.TryParse(key.Substring(8)) with
                | true, index when index >= 0 -> Some(index, line.Substring(split + 1).Trim())
                | _ -> None

    let names bytes =
        let mutable selected = false

        PluginText.decode bytes
        |> fun text -> text.Split('\n')
        |> Array.choose (fun line ->
            if isSection line then
                selected <- isGameFiles line
                None
            elif selected then
                entry line
            else
                None)
        |> Array.sortBy fst
        |> Array.map snd
        |> Array.toList

    let write (names: string list) bytes =
        let text = PluginText.decode bytes
        let newline = if text.Contains("\r\n") then "\r\n" else "\n"
        let rows = text.Split('\n') |> Array.toList
        let output = ResizeArray<string>()
        let mutable selected, found = false, false

        for row in rows do
            let line = row.TrimEnd('\r')

            if isSection line then
                selected <- isGameFiles line
                output.Add line

                if selected then
                    found <- true

                    names
                    |> List.iteri (fun index name ->
                        output.Add("GameFile" + string index + "=" + name))
            elif not selected || (entry line).IsNone then
                output.Add line

        if not found then
            if output.Count > 0 && output[output.Count - 1] <> "" then
                output.Add ""

            output.Add "[Game Files]"

            names
            |> List.iteri (fun index name -> output.Add("GameFile" + string index + "=" + name))

        String.Join(newline, output) |> PluginText.encode |> Option.get
