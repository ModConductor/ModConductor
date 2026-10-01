namespace ModConductor.ProfileGameData

open System
open ModConductor.ProfileGameData.IniDocument

module internal IniArchiveRestoration =
    let private sectionFor keys =
        if
            keys
            |> List.exists (fun (key: string) ->
                key.StartsWith("Archive ", StringComparison.OrdinalIgnoreCase))
        then
            "Archives"
        else
            "Archive"

    let private restoreLine archiveKeys (content: ResizeArray<string>) patchLine =
        let _, found = locateSettings (sectionFor archiveKeys) archiveKeys content

        match found |> List.tryFind (fun (name, _, _) -> name = patchLine.Key) with
        | Some(_, index, value) when value = patchLine.Value ->
            match patchLine.PreviousLine with
            | Some previous -> content[index] <- previous
            | None -> content.RemoveAt index

            Ok()
        | _ ->
            Error(
                ProfileDataError.Unavailable
                    "The active game archive list changed. Read it again before restoration."
            )

    let private restoreSeparator archiveKeys (content: ResizeArray<string>) separator =
        match separator with
        | IniSeparatorOverride.None -> Ok()
        | IniSeparatorOverride.SectionHeader previous ->
            let currentHeader, _ = locateSettings (sectionFor archiveKeys) archiveKeys content

            match currentHeader with
            | Some index when content[index] = previous + ending content[index] ->
                content[index] <- previous
                Ok()
            | Some index when content[index].TrimEnd('\r', '\n') = previous ->
                content[index] <- previous
                Ok()
            | _ ->
                Error(
                    ProfileDataError.Unavailable
                        "The active game archive section changed. Read it again before restoration."
                )
        | IniSeparatorOverride.FileTail previous ->
            if content.Count > 0 && content[content.Count - 1].TrimEnd('\r', '\n') = previous then
                content[content.Count - 1] <- previous
                Ok()
            elif content.Count <> 0 then
                Error(
                    ProfileDataError.Unavailable
                        "The active game settings changed. Read them again before restoration."
                )
            else
                Ok()

    let removeArchives (patch: ArchiveListOverride) bytes =
        let archiveKeys = patch.Lines |> List.map _.Key
        let kind, text = decode bytes
        let content = lines text
        let header, _ = locateSettings (sectionFor archiveKeys) archiveKeys content

        let restored =
            patch.Lines
            |> List.rev
            |> List.fold
                (fun state line ->
                    state |> Result.bind (fun () -> restoreLine archiveKeys content line))
                (Ok())

        restored
        |> Result.bind (fun () ->
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

            restoreSeparator archiveKeys content patch.Separator)
        |> Result.map (fun () ->
            let result = encode kind (String.Concat content)

            if patch.AbsentFile && result.Length = 0 then
                None
            else
                Some result)
