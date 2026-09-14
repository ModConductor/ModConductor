namespace ModConductor.FilePlanning

open System
open System.Text

type internal DecodedText =
    { Content: string
      Encoding: TextDocumentEncoding
      EncodingName: string
      Lines: int
      Newline: TextDocumentNewline option
      FinalTerminator: bool
      MixedNewlines: bool
      LoneCarriageReturn: bool }

module internal TextDocuments =
    let bytesLimit = 1024 * 1024
    let linesLimit = 20000

    let private codec =
        function
        | TextDocumentEncoding.Utf8 -> UTF8Encoding(false, true) :> Encoding
        | TextDocumentEncoding.Utf8Bom -> UTF8Encoding(true, true) :> Encoding
        | TextDocumentEncoding.Utf16Little -> UnicodeEncoding(false, true, true) :> Encoding
        | TextDocumentEncoding.Utf16Big -> UnicodeEncoding(true, true, true) :> Encoding

    let private analyze (content: string) =
        let mutable lf = false
        let mutable crlf = false
        let mutable lone = false
        let mutable index = 0

        while index < content.Length do
            match content[index] with
            | '\r' when index + 1 < content.Length && content[index + 1] = '\n' ->
                crlf <- true
                index <- index + 2
            | '\r' ->
                lone <- true
                index <- index + 1
            | '\n' ->
                lf <- true
                index <- index + 1
            | _ -> index <- index + 1

        let newline =
            match lf, crlf with
            | false, false -> Some TextDocumentNewline.NoLineBreaks
            | true, false -> Some TextDocumentNewline.Lf
            | false, true -> Some TextDocumentNewline.CrLf
            | true, true -> None

        newline, lf && crlf, lone

    let decode (bytes: byte array) =
        let starts (prefix: byte array) =
            bytes.AsSpan().StartsWith(prefix.AsSpan())

        let kind, offset, name =
            if starts [| 0xEFuy; 0xBBuy; 0xBFuy |] then
                TextDocumentEncoding.Utf8Bom, 3, "UTF-8 with BOM"
            elif starts [| 0xFFuy; 0xFEuy |] then
                TextDocumentEncoding.Utf16Little, 2, "UTF-16 LE with BOM"
            elif starts [| 0xFEuy; 0xFFuy |] then
                TextDocumentEncoding.Utf16Big, 2, "UTF-16 BE with BOM"
            else
                TextDocumentEncoding.Utf8, 0, "UTF-8"

        try
            let content = (codec kind).GetString(bytes, offset, bytes.Length - offset)
            let mutable invalid = false
            let mutable lines = if content.Length = 0 then 0 else 1

            for value in content do
                if value = '\n' then
                    lines <- lines + 1

                if Char.IsControl value && value <> '\r' && value <> '\n' && value <> '\t' then
                    invalid <- true

            if invalid then
                Error "This file does not contain supported text."
            elif lines > linesLimit then
                Error "This text file has too many lines."
            else
                let newline, mixed, lone = analyze content

                Ok
                    { Content = content
                      Encoding = kind
                      EncodingName = name
                      Lines = lines
                      Newline = newline
                      FinalTerminator = content.EndsWith('\n')
                      MixedNewlines = mixed
                      LoneCarriageReturn = lone }
        with :? DecoderFallbackException ->
            Error "This file does not contain supported text."

    let editable bytes =
        decode bytes
        |> Result.bind (fun decoded ->
            if decoded.MixedNewlines then
                Error "This file uses mixed line endings. It can be previewed but not edited."
            elif decoded.LoneCarriageReturn then
                Error
                    "This file uses unsupported line endings. It can be previewed but not edited."
            else
                let newline = decoded.Newline.Value

                Ok
                    { Content =
                        if newline = TextDocumentNewline.CrLf then
                            decoded.Content.Replace("\r\n", "\n")
                        else
                            decoded.Content
                      Encoding = decoded.Encoding
                      Newline = newline
                      FinalTerminator = decoded.FinalTerminator
                      Lines = decoded.Lines })

    let encode (original: TextDocument) (content: string) =
        if content.Contains('\r') then
            Error "The draft contains unsupported line endings."
        else
            let lines =
                if content.Length = 0 then
                    0
                else
                    1 + (content |> Seq.filter ((=) '\n') |> Seq.length)

            if lines > linesLimit then
                Error "This text file has too many lines."
            else
                let normalized =
                    match original.Newline with
                    | TextDocumentNewline.CrLf -> content.Replace("\n", "\r\n")
                    | TextDocumentNewline.Lf
                    | TextDocumentNewline.NoLineBreaks -> content

                try
                    let encoding = codec original.Encoding
                    let bytes = Array.append (encoding.GetPreamble()) (encoding.GetBytes normalized)

                    if bytes.Length > bytesLimit then
                        Error "This text file is too large to save."
                    else
                        Ok bytes
                with :? EncoderFallbackException ->
                    Error "The draft contains unsupported text."
