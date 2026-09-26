namespace ModConductor.Migration

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Text

module internal ModOrganizerSettings =
    open ModOrganizerInput

    let private unescape (value: string) =
        let result = StringBuilder(value.Length)
        let mutable index = 0

        while index < value.Length do
            if value[index] <> '\\' || index + 1 >= value.Length then
                result.Append(value[index]) |> ignore
                index <- index + 1
            else
                let next = value[index + 1]

                match next with
                | '\\' ->
                    result.Append('\\') |> ignore
                    index <- index + 2
                | 'n' ->
                    result.Append('\n') |> ignore
                    index <- index + 2
                | 'r' ->
                    result.Append('\r') |> ignore
                    index <- index + 2
                | 't' ->
                    result.Append('\t') |> ignore
                    index <- index + 2
                | 'x' when index + 3 < value.Length ->
                    let mutable finish = index + 2

                    while finish < value.Length
                          && finish < index + 6
                          && Uri.IsHexDigit value[finish] do
                        finish <- finish + 1

                    if finish = index + 2 then
                        result.Append('x') |> ignore
                        index <- index + 2
                    else
                        let number =
                            Int32.Parse(
                                value.Substring(index + 2, finish - index - 2),
                                NumberStyles.HexNumber
                            )

                        result.Append(char number) |> ignore
                        index <- finish
                | other ->
                    result.Append(other) |> ignore
                    index <- index + 2

        result.ToString()

    let private settingValue (value: string) =
        let trimmed = value.Trim()

        if
            trimmed.StartsWith("@ByteArray(", StringComparison.Ordinal)
            && trimmed.EndsWith(')')
        then
            unescape (trimmed.Substring(11, trimmed.Length - 12))
        else
            unescape trimmed

    let ini (content: string) =
        let values = Dictionary<string * string, string>()
        let mutable section = ""

        for raw in content.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n') do
            let line = raw.Trim()

            if line.StartsWith('[') && line.EndsWith(']') && line.Length > 2 then
                section <- line.Substring(1, line.Length - 2)
            elif line <> "" && not (line.StartsWith(';')) && not (line.StartsWith('#')) then
                let split = line.IndexOf('=')

                if split > 0 then
                    values[(section, line.Substring(0, split).Trim())] <-
                        settingValue (line.Substring(split + 1))

        values

    let qsettingsArray section (values: Dictionary<string * string, string>) =
        let size =
            match values.TryGetValue((section, "size")) with
            | false, _ -> 0
            | true, value ->
                match Int32.TryParse value with
                | true, count when count >= 0 && count <= maxEntries -> count
                | _ ->
                    refuse (
                        Error.InvalidSource("A Mod Organizer metadata array has an invalid size.")
                    )

        [ for index in 1..size do
              let prefix = string index + "\\"

              yield
                  values
                  |> Seq.choose (fun item ->
                      let itemSection, key = item.Key

                      if
                          itemSection = section && key.StartsWith(prefix, StringComparison.Ordinal)
                      then
                          Some(key.Substring(prefix.Length), item.Value)
                      else
                          None)
                  |> Map.ofSeq ]

    let private trySetting section name (values: Dictionary<string * string, string>) =
        match values.TryGetValue((section, name)) with
        | true, value -> Some value
        | _ when section = "General" ->
            match values.TryGetValue(("", name)) with
            | true, value -> Some value
            | _ -> None
        | _ -> None

    let setting section name fallback values =
        trySetting section name values |> Option.defaultValue fallback

    let path basePath fallback key values =
        let value = setting "Settings" key fallback values

        let expanded =
            value.Replace("%BASE_DIR%", basePath, StringComparison.OrdinalIgnoreCase)

        let normalized = expanded.Replace('/', Path.DirectorySeparatorChar)

        if Path.IsPathFullyQualified normalized then
            Path.GetFullPath normalized
        else
            Path.GetFullPath(Path.Combine(basePath, normalized))

    let boolSetting name values =
        trySetting "General" name values
        |> Option.exists (fun value ->
            value = "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase))

    let meaningfulLines (content: string) =
        content.Replace("\r\n", "\n").Split('\n')
        |> Array.exists (fun line ->
            let value = line.Trim()
            value <> "" && not (value.StartsWith('#')) && not (value.StartsWith(';')))

    let private categoryPaths (sourceFolder: string) (basePath: string) =
        [ Path.Combine(sourceFolder, "categories.dat")
          Path.Combine(basePath, "categories.dat") ]
        |> List.distinct

    let readCategories (sourceFolder: string) (basePath: string) =
        let candidates = categoryPaths sourceFolder basePath

        match candidates |> List.tryFind File.Exists with
        | None -> [], [], candidates
        | Some path ->
            let categoryStamp = directFile path
            let mutable categories = []
            let ids = HashSet<int>()

            for raw in (text categoryStamp).Replace("\r\n", "\n").Split('\n') do
                let line = raw.Trim()

                if line <> "" && not (line.StartsWith('#')) then
                    let cells = line.Split('|')

                    if cells.Length <> 3 && cells.Length <> 4 then
                        refuse (Error.InvalidSource "categories.dat contains an invalid row.")

                    let mutable id = 0
                    let parentCell = cells[if cells.Length = 3 then 2 else 3]
                    let mutable parent = 0

                    if not (Int32.TryParse(cells[0], &id)) || id <= 0 || not (ids.Add id) then
                        refuse (
                            Error.InvalidSource "categories.dat contains an invalid category ID."
                        )

                    let parentId =
                        if parentCell = "" || parentCell = "0" then
                            None
                        elif Int32.TryParse(parentCell, &parent) && parent > 0 then
                            Some parent
                        else
                            refuse (
                                Error.InvalidSource
                                    "categories.dat contains an invalid parent category."
                            )

                    categories <-
                        { SourceId = id
                          Label = cells[1].Trim()
                          ParentSourceId = parentId }
                        :: categories

            let mapping = Path.Combine(Path.GetDirectoryName path, "nexuscatmap.dat")
            let stamps = ResizeArray<Stamp>()
            stamps.Add categoryStamp

            let absent =
                candidates
                |> List.filter (fun candidate -> not (pathExists candidate))
                |> fun values -> if pathExists mapping then values else mapping :: values

            if File.Exists mapping then
                let mappingStamp = directFile mapping
                stamps.Add mappingStamp

                for raw in (text mappingStamp).Replace("\r\n", "\n").Split('\n') do
                    let line = raw.Trim()

                    if line <> "" && not (line.StartsWith('#')) then
                        let cells = line.Split('|')
                        let mutable category = 0
                        let mutable provider = 0

                        if
                            cells.Length <> 3
                            || not (Int32.TryParse(cells[0], &category))
                            || not (Int32.TryParse(cells[2], &provider))
                        then
                            refuse (Error.InvalidSource "nexuscatmap.dat contains an invalid row.")

            List.rev categories, List.ofSeq stamps, absent

    let categoryIds (value: string) =
        value.Split(',', StringSplitOptions.RemoveEmptyEntries ||| StringSplitOptions.TrimEntries)
        |> Array.choose (fun item ->
            let mutable id = 0

            if Int32.TryParse(item, &id) && id > 0 then
                Some id
            else
                None)
        |> Array.distinct
        |> Array.toList
