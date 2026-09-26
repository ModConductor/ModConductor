namespace ModConductor.ProfileGameData

open System
open System.IO
open ModConductor.ProfileGameData.IniDocument

module internal IniSavePaths =
    let private key (line: string) =
        let value = line.Trim()
        let split = value.IndexOf('=')

        if split < 0 || value.StartsWith(';') || value.StartsWith('#') then
            None
        elif
            value
                .Substring(0, split)
                .Trim()
                .Equals("sLocalSavePath", StringComparison.OrdinalIgnoreCase)
        then
            Some(value.Substring(split + 1).Trim())
        else
            None

    let private locate (content: ResizeArray<string>) =
        let mutable general = false
        let mutable header = None
        let mutable found = None

        for index in 0 .. content.Count - 1 do
            match section content[index] with
            | Some name ->
                general <- name.Equals("General", StringComparison.OrdinalIgnoreCase)

                if general then
                    if header.IsSome then
                        raise (IOException "The settings file has more than one General section.")

                    header <- Some index
            | None when general ->
                match key content[index] with
                | Some value ->
                    if found.IsSome then
                        raise (IOException "The settings file has more than one save path.")

                    found <- Some(index, value)
                | None -> ()
            | None -> ()

        header, found

    let testFiles bytes =
        let _, text = decode bytes
        let mutable general = false

        [ for line in lines text do
              match section line with
              | Some name -> general <- name.Equals("General", StringComparison.OrdinalIgnoreCase)
              | None when general ->
                  let value = line.Trim()
                  let split = value.IndexOf('=')

                  if split > 0 && not (value.StartsWith(';') || value.StartsWith('#')) then
                      let key = value.Substring(0, split).Trim()

                      if key.StartsWith("sTestFile", StringComparison.OrdinalIgnoreCase) then
                          match Int32.TryParse(key.Substring(9)) with
                          | true, index when index >= 1 && index <= 10 ->
                              let name = value.Substring(split + 1).Trim()

                              if name <> "" then
                                  yield name
                          | _ -> ()
              | None -> () ]

    let apply value (original: byte array option) =
        let bytes = original |> Option.defaultValue [||]

        if
            String.IsNullOrWhiteSpace value
            || value.IndexOfAny([| '\r'; '\n'; '\000' |]) >= 0
        then
            invalidArg (nameof value) "Select a save directory."

        let kind, text = decode bytes
        let content = lines text

        let newline =
            if text.Contains("\r\n") || not (text.Contains '\n') then
                "\r\n"
            else
                "\n"

        let header, found = locate content
        let previous = found |> Option.map (fun (index, _) -> content[index])
        let mutable separator = false

        match found with
        | Some(index, _) ->
            let line = content[index]

            let ending =
                if line.EndsWith("\r\n") then "\r\n"
                elif line.EndsWith('\n') then "\n"
                else ""

            content[index] <- "sLocalSavePath=" + value + ending
        | None ->
            match header with
            | Some index ->
                if not (content[index].EndsWith '\n') then
                    content[index] <- content[index] + newline
                    separator <- true

                content.Insert(index + 1, "sLocalSavePath=" + value + newline)
            | None ->
                if content.Count > 0 && not (content[content.Count - 1].EndsWith '\n') then
                    content[content.Count - 1] <- content[content.Count - 1] + newline
                    separator <- true

                content.Add("[General]" + newline)
                content.Add("sLocalSavePath=" + value + newline)

        encode kind (String.Concat content),
        { Value = value
          PreviousLine = previous
          AddedSection = header.IsNone
          AddedSeparator = separator
          AbsentFile = original.IsNone }

    let remove (patch: SavePathOverride) bytes =
        let kind, text = decode bytes
        let content = lines text
        let header, found = locate content

        match found with
        | Some(index, value) when value = patch.Value ->
            match patch.PreviousLine with
            | Some previous -> content[index] <- previous
            | None -> content.RemoveAt index

            match header with
            | Some index when patch.AddedSection ->
                let hasValues =
                    content
                    |> Seq.skip (index + 1)
                    |> Seq.takeWhile (section >> Option.isNone)
                    |> Seq.exists (String.IsNullOrWhiteSpace >> not)

                if not hasValues then
                    content.RemoveAt index
            | _ -> ()

            if patch.AddedSeparator then
                let index =
                    if patch.AddedSection then
                        defaultArg header 0 - 1
                    else
                        defaultArg header -1

                if index >= 0 && index = content.Count - 1 then
                    content[index] <- content[index].TrimEnd('\r', '\n')

            let bytes = encode kind (String.Concat content)

            if patch.AbsentFile && bytes.Length = 0 then
                None
            else
                Some bytes
        | _ ->
            raise (
                IOException
                    "The active save path changed. Read the settings again before restoration."
            )
