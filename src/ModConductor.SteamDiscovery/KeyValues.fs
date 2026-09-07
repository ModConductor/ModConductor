namespace ModConductor.SteamDiscovery

open System
open System.Text

module internal KeyValues =
    type Value =
        | Text of string
        | Object of (string * Value) list

    exception Invalid of int * string

    let parse (bytes: byte array) =
        try
            let text = UTF8Encoding(false, true).GetString(bytes).TrimStart('\uFEFF')
            let mutable at = 0
            let mutable tokens = 0
            let fail reason = raise (Invalid(at, reason))

            let has offset character =
                at + offset < text.Length && text[at + offset] = character

            let rec space () =
                if at < text.Length && Char.IsWhiteSpace(text[at]) then
                    at <- at + 1
                    space ()
                elif has 0 '/' && has 1 '/' then
                    while at < text.Length && text[at] <> '\n' do
                        at <- at + 1

                    space ()
                elif has 0 '/' && has 1 '*' then
                    at <- at + 2

                    while at < text.Length && not (has 0 '*' && has 1 '/') do
                        at <- at + 1

                    if at = text.Length then
                        fail "A comment was not closed."

                    at <- at + 2
                    space ()

            let token () =
                space ()
                tokens <- tokens + 1

                if tokens > 32768 then
                    fail "The Steam file contains too many values."

                if at >= text.Length then
                    fail "A value is missing."

                let value = StringBuilder()

                let quoted = text[at] = '"'

                if quoted then
                    at <- at + 1

                    while at < text.Length && text[at] <> '"' do
                        if has 0 '\\' && (has 1 '\\' || has 1 '"') then
                            at <- at + 1

                        value.Append(text[at]) |> ignore
                        at <- at + 1

                        if value.Length > 65536 then
                            fail "A value is too long."

                    if at = text.Length then
                        fail "A quoted value was not closed."

                    at <- at + 1
                else
                    while at < text.Length
                          && not (Char.IsWhiteSpace(text[at]))
                          && text[at] <> '{'
                          && text[at] <> '}' do
                        value.Append(text[at]) |> ignore
                        at <- at + 1

                        if value.Length > 65536 then
                            fail "A value is too long."

                if value.Length = 0 && not quoted then
                    fail "A value is missing."

                value.ToString()

            let rec entries depth nested =
                if depth > 32 then
                    fail "The Steam file is nested too deeply."

                let values = ResizeArray<string * Value>()
                space ()

                while at < text.Length && text[at] <> '}' do
                    let key = token ()

                    if key.Length = 0 then
                        fail "A key is missing."

                    if key.StartsWith('#') then
                        fail "Steam file includes are not supported."

                    space ()

                    let value =
                        if has 0 '{' then
                            at <- at + 1
                            Object(entries (depth + 1) true)
                        else
                            Text(token ())

                    values.Add(key, value)
                    space ()

                if nested then
                    if not (has 0 '}') then
                        fail "An object was not closed."

                    at <- at + 1
                elif at < text.Length then
                    fail "An object has an unexpected closing brace."

                List.ofSeq values

            Ok(entries 0 false)
        with
        | Invalid(offset, detail) ->
            Error(
                detail
                + " Position: "
                + offset.ToString(System.Globalization.CultureInfo.InvariantCulture)
                + "."
            )
        | :? DecoderFallbackException -> Error "The Steam file is not valid UTF-8."

    let field key values =
        match
            values
            |> List.filter (fun (name, _) ->
                String.Equals(name, key, StringComparison.OrdinalIgnoreCase))
        with
        | [] -> Ok None
        | [ _, value ] -> Ok(Some value)
        | _ -> Error "A required Steam field occurs more than once."

    let text key values =
        match field key values with
        | Ok None -> Ok None
        | Ok(Some(Text value)) -> Ok(Some value)
        | Ok(Some(Object _)) -> Error "A Steam text field contains an object."
        | Error error -> Error error

    let body key values =
        match field key values with
        | Ok(Some(Object value)) -> Ok value
        | Ok _ -> Error "The required Steam object was not found."
        | Error error -> Error error
