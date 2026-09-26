namespace ModConductor.Nexus

open System.IO
open System.Text.Json

module internal InteractionJson =
    let endorsement value =
        match value with
        | "Undecided" -> NexusEndorsement.Undecided
        | "Abstained" -> NexusEndorsement.Abstained
        | "Endorsed" -> NexusEndorsement.Endorsed
        | _ -> NexusJson.fail ()

    let matching (identity: NexusIdentity) value =
        NexusJson.text "domain_name" value = identity.Game
        && NexusJson.number "mod_id" value = identity.Mod

    let tracking identity value =
        NexusJson.array 10000 value |> List.exists (matching identity)

    let endorsements identity value =
        NexusJson.array 10000 value
        |> List.tryFind (matching identity)
        |> Option.map (fun item -> endorsement (NexusJson.text "status" item))
        |> Option.defaultValue NexusEndorsement.Undecided

    let write (fields: (string * Choice<string, int64>) list) =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream)
        writer.WriteStartObject()

        for name, value in fields do
            match value with
            | Choice1Of2(value: string) -> writer.WriteString(name, value)
            | Choice2Of2(value: int64) -> writer.WriteNumber(name, value)

        writer.WriteEndObject()
        writer.Flush()
        stream.ToArray()
