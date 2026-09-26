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

type internal ArchiveListReceipt =
    { Profile: ArchiveListOverride
      Documents: ArchiveListOverride option }

module internal IniDocument =
    let private encoding =
        function
        | IniEncoding.Utf8 -> UTF8Encoding(false, true) :> Encoding
        | IniEncoding.Utf8Bom -> UTF8Encoding(true, true) :> Encoding
        | IniEncoding.Utf16Little -> UnicodeEncoding(false, true, true) :> Encoding
        | IniEncoding.Utf16Big -> UnicodeEncoding(true, true, true) :> Encoding

    let decode (bytes: byte array) =
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

    let encode kind text =
        let codec = encoding kind
        Array.append (codec.GetPreamble()) (codec.GetBytes(text: string))

    let lines (text: string) =
        let result = ResizeArray<string>()
        let mutable start = 0

        for index in 0 .. text.Length - 1 do
            if text[index] = '\n' then
                result.Add(text.Substring(start, index - start + 1))
                start <- index + 1

        if start < text.Length then
            result.Add(text.Substring start)

        result

    let section (line: string) =
        let value = line.Trim()

        if value.StartsWith('[') && value.EndsWith(']') then
            Some(value.Substring(1, value.Length - 2).Trim())
        else
            None

    let setting (wanted: string list) (line: string) =
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

    let locateSettings sectionName wanted (content: ResizeArray<string>) =
        let mutable inside = false
        let mutable header = None
        let found = ResizeArray<string * int * string>()

        for index in 0 .. content.Count - 1 do
            match section content[index] with
            | Some name ->
                inside <- name.Equals(sectionName, StringComparison.OrdinalIgnoreCase)

                if inside then
                    if header.IsSome then
                        raise (
                            IOException(
                                "The settings file has more than one " + sectionName + " section."
                            )
                        )

                    header <- Some index
            | None when inside ->
                match setting wanted content[index] with
                | Some(key, value) ->
                    if found |> Seq.exists (fun (other, _, _) -> other = key) then
                        raise (
                            IOException("The settings file has more than one " + key + " value.")
                        )

                    found.Add(key, index, value)
                | None -> ()
            | None -> ()

        header, List.ofSeq found

    let ending (line: string) =
        if line.EndsWith("\r\n") then "\r\n"
        elif line.EndsWith('\n') then "\n"
        else ""
