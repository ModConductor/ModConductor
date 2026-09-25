namespace ModConductor.GeneratedOutputs

open System
open System.IO
open System.Security.Cryptography
open System.Text

module internal OutputPaging =
    let query (filter: string) =
        if not (OutputPolicy.text 1024 filter) then
            Error(OutputError.Invalid "The filter is too long.")
        else
            Ok(filter.Trim())

    let private identity (snapshot: Guid) (query: string) =
        snapshot.ToString("N")
        + ":"
        + Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes query))

    let private encode snapshot query (offset: int) =
        Convert.ToBase64String(
            Encoding.UTF8.GetBytes(identity snapshot query + ":" + string offset)
        )

    let private offset snapshot query (cursor: string option) =
        match cursor with
        | None -> Ok 0
        | Some value when value.Length <= 256 ->
            try
                let parts = Encoding.UTF8.GetString(Convert.FromBase64String value).Split ':'

                match parts with
                | [| id; hash; number |] when id + ":" + hash = identity snapshot query ->
                    match Int32.TryParse number with
                    | true, value when value >= 0 -> Ok value
                    | _ -> Error OutputError.Stale
                | _ -> Error OutputError.Stale
            with :? FormatException ->
                Error OutputError.Stale
        | Some _ -> Error OutputError.Stale

    let private entries (matching: OutputObservation array) start =
        let count = min OutputLimits.pageRows (matching.Length - start)

        let rec gather index remaining found =
            if index = count then
                Ok(List.rev found)
            else
                let file = matching[start + index].File
                let bytes = OutputPolicy.fileSize file

                if bytes > OutputLimits.pageBytes then
                    Error OutputError.LimitExceeded
                elif bytes > remaining then
                    Ok(List.rev found)
                else
                    gather (index + 1) (remaining - bytes) (file :: found)

        gather 0 OutputLimits.pageBytes []

    let page
        (snapshot: OutputSnapshot)
        (matching: OutputObservation array)
        query
        present
        unreviewed
        cursor
        =
        match offset snapshot.Id query cursor with
        | Error error -> Error error
        | Ok start when start > matching.Length -> Error OutputError.Stale
        | Ok start ->
            entries matching start
            |> Result.map (fun values ->
                { Snapshot = snapshot
                  Entries = values
                  MatchedEntries = matching.Length
                  Files = present
                  Unreviewed = unreviewed
                  NextCursor =
                    if start + values.Length < matching.Length then
                        Some(encode snapshot.Id query (start + values.Length))
                    else
                        None })
