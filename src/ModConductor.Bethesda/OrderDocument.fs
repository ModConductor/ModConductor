namespace ModConductor.Bethesda

open System
open System.Collections.Generic
open System.IO
open System.Text

module OrderDocument =
    let maxBytes = 1024 * 1024

    let private lines (bytes: byte array) =
        if bytes.Length > maxBytes then
            raise (InvalidDataException "The plugin list exceeds the 1 MiB read limit.")

        let text = PluginText.decode bytes
        let result = ResizeArray<string * string>()
        let mutable offset = 0

        while offset < text.Length do
            let finish = text.IndexOf('\n', offset)

            if finish < 0 then
                result.Add(text.Substring offset, "")
                offset <- text.Length
            else
                let ending =
                    if finish > offset && text[finish - 1] = '\r' then
                        "\r\n"
                    else
                        "\n"

                result.Add(text.Substring(offset, finish - offset - (ending.Length - 1)), ending)
                offset <- finish + 1

        List.ofSeq result

    let private entry (text: string) =
        let text = text.Trim()

        if text = "" || text.StartsWith('#') then
            None
        elif text.StartsWith('*') then
            Some(text.Substring(1).Trim(), true)
        else
            Some(text, false)

    let names bytes =
        lines bytes |> List.choose (fst >> entry)

    let canWriteName (name: string) =
        not (String.IsNullOrWhiteSpace name)
        && name = name.Trim()
        && name.IndexOfAny([| '\r'; '\n'; '\000'; '/'; '\\' |]) < 0
        && not (name.StartsWith('#') || name.StartsWith('*'))
        && PluginText.encode name |> Option.isSome

    let write (early: string list) (order: PluginOrder) =
        let implicit = HashSet<string>(early, StringComparer.OrdinalIgnoreCase)

        let known =
            HashSet<string>(order.Entries |> Seq.map _.Name, StringComparer.OrdinalIgnoreCase)

        let pending =
            Queue<PluginSetting>(
                order.Entries |> Seq.filter (fun row -> not (implicit.Contains row.Name))
            )

        let output = StringBuilder()

        if order.Document.Length = 0 then
            output
                .Append("# This file is used by Skyrim to keep track of your downloaded content.\n")
                .Append("# Please do not modify this file.\n")
            |> ignore

        let append () =
            let row = pending.Dequeue()

            if not (canWriteName row.Name) || row.Enabled.IsNone then
                raise (InvalidDataException("Choose a valid active state for " + row.Name + "."))

            if row.Enabled = Some true then
                output.Append('*') |> ignore

            output.Append(row.Name).Append("\n") |> ignore

        for text, ending in lines order.Document do
            match entry text with
            | Some(name, _) when known.Contains name || implicit.Contains name ->
                if pending.Count > 0 then
                    append ()
            | _ -> output.Append(text).Append(ending) |> ignore

        if pending.Count > 0 && output.Length > 0 && output[output.Length - 1] <> '\n' then
            output.Append("\n") |> ignore

        while pending.Count > 0 do
            append ()

        let bytes = PluginText.encode (output.ToString()) |> Option.get

        if bytes.Length > maxBytes then
            raise (InvalidDataException "The plugin list exceeds the 1 MiB write limit.")

        bytes
