namespace ModConductor.Bethesda

open System

module internal PluginText =
    let private high =
        "\u20ac\u0081\u201a\u0192\u201e\u2026\u2020\u2021\u02c6\u2030\u0160\u2039\u0152\u008d\u017d\u008f\u0090\u2018\u2019\u201c\u201d\u2022\u2013\u2014\u02dc\u2122\u0161\u203a\u0153\u009d\u017e\u0178"

    let decode (bytes: byte array) =
        bytes
        |> Array.map (fun value ->
            if value >= 0x80uy && value <= 0x9fuy then
                high[int value - 0x80]
            else
                char value)
        |> String

    let encode (text: string) =
        let bytes = Array.zeroCreate<byte> text.Length
        let mutable valid = true

        for index in 0 .. text.Length - 1 do
            let character = text[index]

            if character < '\u0080' || (character >= '\u00a0' && character <= '\u00ff') then
                bytes[index] <- byte character
            else
                let found = high.IndexOf character

                if found < 0 then
                    valid <- false
                else
                    bytes[index] <- byte (found + 0x80)

        if valid then Some bytes else None
