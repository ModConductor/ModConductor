namespace ModConductor.ProfileGameData

open System
open System.IO
open ModConductor.ProfileGameData.IniDocument

module internal IniArchives =
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
            if text.Contains("\r\n") || not (text.Contains '\n') then
                "\r\n"
            else
                "\n"

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

        if patch.AbsentFile && result.Length = 0 then
            None
        else
            Some result
