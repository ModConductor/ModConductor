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

[<RequireQualifiedAccess>]
type internal IniSeparatorOverride =
    | None
    | SectionHeader of string
    | FileTail of string

type internal ArchiveLineOverride =
    { Key: string
      Value: string
      PreviousLine: string option }

type internal ArchiveListOverride =
    { Lines: ArchiveLineOverride list
      AddedSection: bool
      Separator: IniSeparatorOverride
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

    let private setting (wanted: string list) (line: string) =
        let value = line.Trim()
        let split = value.IndexOf('=')

        if split < 0 || value.StartsWith(';') || value.StartsWith('#') then
            None
        else
            let name = value.Substring(0, split).Trim()

            wanted
            |> List.tryFind (fun candidate ->
                name.Equals(candidate, StringComparison.OrdinalIgnoreCase))
            |> Option.map (fun canonical -> canonical, value.Substring(split + 1).Trim())

    let private locateSettings sectionName wanted (content: ResizeArray<string>) =
        let mutable inside = false
        let mutable header = None
        let found = ResizeArray<string * int * string>()

        for index in 0 .. content.Count - 1 do
            match section content[index] with
            | Some name ->
                inside <- name.Equals(sectionName, StringComparison.OrdinalIgnoreCase)

                if inside then
                    if header.IsSome then
                        raise (IOException("The settings file has more than one " + sectionName + " section."))

                    header <- Some index
            | None when inside ->
                match setting wanted content[index] with
                | Some(key, value) ->
                    if found |> Seq.exists (fun (other, _, _) -> other = key) then
                        raise (IOException("The settings file has more than one " + key + " value."))

                    found.Add(key, index, value)
                | None -> ()
            | None -> ()

        header, List.ofSeq found

    let private ending (line: string) =
        if line.EndsWith("\r\n") then "\r\n"
        elif line.EndsWith('\n') then "\n"
        else ""

    let private archiveKeys = [ "SResourceArchiveList"; "SResourceArchiveList2" ]

    let archiveEntries bytes =
        let _, text = decode bytes
        let _, found = locateSettings "Archive" archiveKeys (lines text)

        [ for key in archiveKeys do
              match found |> List.tryFind (fun (name, _, _) -> name = key) with
              | None -> ()
              | Some(_, _, value) ->
                  let mutable position = 0

                  for name in value.Split(',') do
                      let name = name.Trim()

                      if name <> "" then
                          yield
                              ({ Name = name
                                 Key = key
                                 Position = position }
                               : ModConductor.Bethesda.ExplicitArchive)

                          position <- position + 1 ]

    let private archiveValues names =
        let joined = String.concat ", " names

        if joined.Length <= 255 then
            joined, None
        else
            let search = min 256 (joined.Length - 1)
            let split = joined.LastIndexOf(',', search)

            if split < 0 then
                raise (IOException "The Skyrim archive list cannot be split between its two keys.")

            let first = joined.Substring(0, split)
            let second = joined.Substring(split + 1).TrimStart()

            if first.Length > 256 || second.Length > 255 then
                raise (IOException "The Skyrim archive list does not fit its two keys.")

            first, Some second

    let applyArchives names (original: byte array option) =
        let bytes = original |> Option.defaultValue [||]

        if
            List.isEmpty names
            || names
               |> List.exists (fun name ->
                   String.IsNullOrWhiteSpace name
                   || name <> name.Trim()
                   || name.IndexOfAny([| ','; '\r'; '\n'; '\000'; '/'; '\\' |]) >= 0)
        then
            invalidArg (nameof names) "Choose valid Skyrim archive filenames."

        let first, second = archiveValues names
        let kind, text = decode bytes
        let content = lines text

        let newline =
            if text.Contains("\r\n") || not (text.Contains '\n') then "\r\n" else "\n"

        let header, found = locateSettings "Archive" archiveKeys content
        let mutable separator = IniSeparatorOverride.None
        let mutable addedSection = false

        let header =
            match header with
            | Some index ->
                if not (content[index].EndsWith '\n') then
                    let previous = content[index]
                    content[index] <- previous + newline
                    separator <- IniSeparatorOverride.SectionHeader previous

                index
            | None ->
                if content.Count > 0 && not (content[content.Count - 1].EndsWith '\n') then
                    let previous = content[content.Count - 1]
                    content[content.Count - 1] <- previous + newline
                    separator <- IniSeparatorOverride.FileTail previous

                content.Add("[Archive]" + newline)
                addedSection <- true
                content.Count - 1

        let patches = ResizeArray<ArchiveLineOverride>()

        let write key value insert =
            let _, current = locateSettings "Archive" archiveKeys content

            match current |> List.tryFind (fun (name, _, _) -> name = key) with
            | Some(_, index, _) ->
                let previous = content[index]
                content[index] <- key + "=" + value + ending previous

                patches.Add
                    { Key = key
                      Value = value
                      PreviousLine = Some previous }
            | None when insert ->
                let previousKeys = patches.Count
                content.Insert(header + 1 + previousKeys, key + "=" + value + newline)

                patches.Add
                    { Key = key
                      Value = value
                      PreviousLine = None }
            | None -> ()

        write "SResourceArchiveList" first true
        write "SResourceArchiveList2" (defaultArg second "") second.IsSome

        encode kind (String.Concat content),
        { Lines = List.ofSeq patches
          AddedSection = addedSection
          Separator = separator
          AbsentFile = original.IsNone }

    let removeArchives (patch: ArchiveListOverride) bytes =
        let kind, text = decode bytes
        let content = lines text
        let header, _ = locateSettings "Archive" archiveKeys content

        for patchLine in patch.Lines |> List.rev do
            let _, found = locateSettings "Archive" archiveKeys content

            match found |> List.tryFind (fun (name, _, _) -> name = patchLine.Key) with
            | Some(_, index, value) when value = patchLine.Value ->
                match patchLine.PreviousLine with
                | Some previous -> content[index] <- previous
                | None -> content.RemoveAt index
            | _ ->
                raise (
                    IOException
                        "The active Skyrim archive list changed. Read it again before restoration."
                )

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

        match patch.Separator with
        | IniSeparatorOverride.None -> ()
        | IniSeparatorOverride.SectionHeader previous ->
            let currentHeader, _ = locateSettings "Archive" archiveKeys content

            match currentHeader with
            | Some index when content[index] = previous + ending content[index] ->
                content[index] <- previous
            | Some index when content[index].TrimEnd('\r', '\n') = previous ->
                content[index] <- previous
            | _ ->
                raise (
                    IOException
                        "The active Skyrim archive section changed. Read it again before restoration."
                )
        | IniSeparatorOverride.FileTail previous ->
            if content.Count > 0 && content[content.Count - 1].TrimEnd('\r', '\n') = previous then
                content[content.Count - 1] <- previous
            elif content.Count <> 0 then
                raise (
                    IOException
                        "The active Skyrim settings changed. Read them again before restoration."
                )

        let result = encode kind (String.Concat content)

        if patch.AbsentFile && result.Length = 0 then None else Some result

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
