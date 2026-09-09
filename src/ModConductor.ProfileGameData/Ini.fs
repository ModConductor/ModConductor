namespace ModConductor.ProfileGameData

open System
open System.IO
open System.Text

[<RequireQualifiedAccess>]
type internal IniEncoding =
    | Utf8
    | Utf8Bom
    | Utf16Little
    | Utf16Big

type internal SavePathOverride =
    { Value: string
      PreviousLine: string option
      AddedSection: bool
      AddedSeparator: bool
      AbsentFile: bool }

module internal Ini =
    let private encoding =
        function
        | IniEncoding.Utf8 -> UTF8Encoding(false, true) :> Encoding
        | IniEncoding.Utf8Bom -> UTF8Encoding(true, true) :> Encoding
        | IniEncoding.Utf16Little -> UnicodeEncoding(false, true, true) :> Encoding
        | IniEncoding.Utf16Big -> UnicodeEncoding(true, true, true) :> Encoding

    let private decode (bytes: byte array) =
        let starts (prefix: byte array) =
            bytes.AsSpan().StartsWith(prefix.AsSpan())

        let kind, skip =
            if starts [| 0xEFuy; 0xBBuy; 0xBFuy |] then
                IniEncoding.Utf8Bom, 3
            elif starts [| 0xFFuy; 0xFEuy |] then
                IniEncoding.Utf16Little, 2
            elif starts [| 0xFEuy; 0xFFuy |] then
                IniEncoding.Utf16Big, 2
            else
                IniEncoding.Utf8, 0

        try
            let text = (encoding kind).GetString(bytes, skip, bytes.Length - skip)

            if text.Contains('\000') then
                raise (IOException "The settings file encoding is unavailable.")

            kind, text
        with :? DecoderFallbackException ->
            raise (
                IOException
                    "The settings file encoding is unavailable. Use UTF-8 or UTF-16 settings."
            )

    let private encode kind text =
        let codec = encoding kind
        Array.append (codec.GetPreamble()) (codec.GetBytes(text: string))

    let private lines (text: string) =
        let result = ResizeArray<string>()
        let mutable start = 0

        for index in 0 .. text.Length - 1 do
            if text[index] = '\n' then
                result.Add(text.Substring(start, index - start + 1))
                start <- index + 1

        if start < text.Length then
            result.Add(text.Substring start)

        result

    let private section (line: string) =
        let value = line.Trim()

        if value.StartsWith('[') && value.EndsWith(']') then
            Some(value.Substring(1, value.Length - 2).Trim())
        else
            None

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
