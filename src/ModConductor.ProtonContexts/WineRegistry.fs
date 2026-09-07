namespace ModConductor.ProtonContexts

open System
open System.IO
open System.Text

module internal WineRegistry =
    type StringValue = { Text: string; Expand: bool }

    let private unquote (text: string) =
        if text.Length < 2 || text[0] <> '"' || text[text.Length - 1] <> '"' then
            raise (IOException "A required prefix registry value is not a string.")

        let result = StringBuilder()
        let mutable at = 1

        while at < text.Length - 1 do
            if text[at] = '\\' then
                at <- at + 1

                if at >= text.Length - 1 then
                    raise (IOException "A prefix registry escape is incomplete.")

                match text[at] with
                | '\\'
                | '"' -> result.Append(text[at]) |> ignore
                | _ ->
                    raise (
                        IOException "A required prefix registry string uses an unsupported escape."
                    )
            else
                result.Append(text[at]) |> ignore

            at <- at + 1

        result.ToString()

    let read (text: string) =
        let sections =
            [ "Volatile Environment"
              "Environment"
              "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders"
              "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders" ]

        let names =
            [ "USERPROFILE"
              "HOMEDRIVE"
              "HOMEPATH"
              "Personal"
              "AppData"
              "Local AppData" ]

        let result = ResizeArray<string * string * StringValue>()
        let mutable section = ""
        use lines = new StringReader(text)
        let mutable line = lines.ReadLine()

        while not (isNull line) do
            if line.Length > 65536 then
                raise (IOException "A prefix registry line exceeds the read limit.")

            if line.StartsWith('[') then
                let finish = line.IndexOf(']')

                section <-
                    if finish < 0 then
                        ""
                    else
                        line.Substring(1, finish - 1).Replace("\\\\", "\\")
            elif
                sections
                |> List.exists (fun s ->
                    String.Equals(s, section, StringComparison.OrdinalIgnoreCase))
            then
                let separator = line.IndexOf('=')

                if separator > 1 && line.StartsWith('"') then
                    let name = unquote (line.Substring(0, separator))

                    if
                        names
                        |> List.exists (fun n ->
                            String.Equals(n, name, StringComparison.OrdinalIgnoreCase))
                    then
                        let raw = line.Substring(separator + 1)

                        let value =
                            if raw.StartsWith("str(2):", StringComparison.Ordinal) then
                                raw.Substring(7)
                            else
                                raw

                        result.Add(
                            section,
                            name,
                            { Text = unquote value
                              Expand = raw.StartsWith("str(2):", StringComparison.Ordinal) }
                        )

            line <- lines.ReadLine()

        let values = List.ofSeq result

        fun section name ->
            match
                values
                |> List.filter (fun (s, n, _) ->
                    String.Equals(s, section, StringComparison.OrdinalIgnoreCase)
                    && String.Equals(n, name, StringComparison.OrdinalIgnoreCase))
            with
            | [] -> None
            | [ _, _, value ] -> Some value
            | _ -> raise (IOException "A required prefix registry value is ambiguous.")
