namespace ModConductor.Nexus

open System
open System.IO
open System.Text.Json

module internal CredentialJson =
    type Saved =
        { Issuer: string
          Client: string
          Subject: string
          Refresh: string }

    type SavedCredential =
        | OAuth of Saved
        | PersonalApiKey of subject: string * key: string

    let saved value =
        match NexusJson.number "version" value with
        | 1L ->
            OAuth
                { Issuer = NexusJson.text "issuer" value
                  Client = NexusJson.text "client" value
                  Subject = NexusJson.text "subject" value
                  Refresh = NexusJson.text "refresh" value }
        | 2L when NexusJson.text "kind" value = "personal_api_key" ->
            let subject = NexusJson.text "subject" value
            let key = NexusJson.text "key" value

            if String.IsNullOrWhiteSpace subject || String.IsNullOrWhiteSpace key then
                NexusJson.fail ()

            PersonalApiKey(subject, key)
        | _ -> NexusJson.fail ()

    let writeSaved (value: Saved) =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream)
        writer.WriteStartObject()
        writer.WriteNumber("version", 1)
        writer.WriteString("issuer", value.Issuer)
        writer.WriteString("client", value.Client)
        writer.WriteString("subject", value.Subject)
        writer.WriteString("refresh", value.Refresh)
        writer.WriteEndObject()
        writer.Flush()
        stream.ToArray()

    let writeSavedApiKey (subject: string) (key: string) =
        use stream = new MemoryStream()
        use writer = new Utf8JsonWriter(stream)
        writer.WriteStartObject()
        writer.WriteNumber("version", 2)
        writer.WriteString("kind", "personal_api_key")
        writer.WriteString("subject", subject)
        writer.WriteString("key", key)
        writer.WriteEndObject()
        writer.Flush()
        stream.ToArray()
