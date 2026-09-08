namespace ModConductor.GeneratedOutputs

open System
open System.IO
open System.Security.Cryptography
open System.Text

module internal OutputPaging =
    let query (filter: string) =
        if not (OutputPolicy.text 1024 filter) then
            raise (OutputException(OutputError.Invalid "The filter is too long."))

        filter.Trim()

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
        | None -> 0
        | Some value when value.Length <= 256 ->
            try
                let parts = Encoding.UTF8.GetString(Convert.FromBase64String value).Split ':'

                match parts with
                | [| id; hash; number |] when id + ":" + hash = identity snapshot query ->
                    match Int32.TryParse number with
                    | true, value when value >= 0 -> value
                    | _ -> raise (OutputException OutputError.Stale)
                | _ -> raise (OutputException OutputError.Stale)
            with :? FormatException ->
                raise (OutputException OutputError.Stale)
        | Some _ -> raise (OutputException OutputError.Stale)

    let page
        (snapshot: OutputSnapshot)
        (matching: OutputObservation array)
        query
        present
        unreviewed
        cursor
        =
        let offset = offset snapshot.Id query cursor

        if offset > matching.Length then
            raise (OutputException OutputError.Stale)

        let mutable remaining = OutputLimits.pageBytes

        let values =
            matching
            |> fun files ->
                Array.sub files offset (min OutputLimits.pageRows (files.Length - offset))
            |> Array.takeWhile (fun value ->
                let bytes = OutputPolicy.fileSize value.File

                if bytes > OutputLimits.pageBytes then
                    raise (OutputException OutputError.LimitExceeded)

                remaining <- remaining - bytes
                remaining >= 0)

        { Snapshot = snapshot
          Entries = values |> Array.map _.File |> Array.toList
          MatchedEntries = matching.Length
          Files = present
          Unreviewed = unreviewed
          NextCursor =
            if offset + values.Length < matching.Length then
                Some(encode snapshot.Id query (offset + values.Length))
            else
                None }
