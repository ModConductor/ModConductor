namespace ModConductor.Nexus

open System
open System.IO
open System.Text.Json

module internal NexusJson =
    let fail () =
        raise (NexusException NexusProblem.InvalidResponse)

    let field name (value: JsonElement) =
        match value.TryGetProperty(name: string) with
        | true, field -> Some field
        | _ -> None

    let text name value =
        match field name value with
        | Some item when item.ValueKind = JsonValueKind.String -> item.GetString()
        | _ -> fail ()

    let optionalText name value =
        field name value
        |> Option.bind (fun item ->
            if item.ValueKind = JsonValueKind.String then
                Some(item.GetString())
            else
                None)

    let number name value =
        match field name value with
        | Some item ->
            match item.TryGetInt64() with
            | true, value -> value
            | _ -> fail ()
        | _ -> fail ()

    let optionalNumber name value =
        field name value
        |> Option.bind (fun item ->
            match item.TryGetInt64() with
            | true, n -> Some n
            | _ -> None)

    type Tokens =
        { Access: string
          Refresh: string
          Expires: DateTimeOffset }

    type Saved =
        { Issuer: string
          Client: string
          Subject: string
          Refresh: string }

    let tokens fallback value =
        if
            not (
                String.Equals(text "token_type" value, "Bearer", StringComparison.OrdinalIgnoreCase)
            )
        then
            fail ()

        let access = text "access_token" value

        let refresh =
            optionalText "refresh_token" value
            |> Option.orElse fallback
            |> Option.defaultWith fail

        let seconds = number "expires_in" value

        if
            String.IsNullOrWhiteSpace access
            || String.IsNullOrWhiteSpace refresh
            || seconds <= 0L
            || seconds > 31536000L
        then
            fail ()

        { Access = access
          Refresh = refresh
          Expires = DateTimeOffset.UtcNow.AddSeconds(float seconds) }

    let account value =
        let subject = text "sub" value
        let name = text "name" value

        if String.IsNullOrWhiteSpace subject || String.IsNullOrWhiteSpace name then
            fail ()

        let premium =
            field "membership_roles" value
            |> Option.bind (fun roles ->
                if roles.ValueKind <> JsonValueKind.Array then
                    None
                else
                    Some(
                        roles.EnumerateArray()
                        |> Seq.exists (fun role ->
                            role.ValueKind = JsonValueKind.String
                            && (role.GetString() = "premium"
                                || role.GetString() = "lifetime_premium"))
                    ))

        { Subject = subject
          Name = name
          Premium = premium }

    let saved value =
        if number "version" value <> 1L then
            fail ()

        { Issuer = text "issuer" value
          Client = text "client" value
          Subject = text "subject" value
          Refresh = text "refresh" value }

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

    let file value =
        { Id = number "file_id" value
          Name = text "file_name" value
          Version = optionalText "version" value |> Option.defaultValue ""
          Category = optionalText "category_name" value |> Option.defaultValue ""
          Description = optionalText "description" value |> Option.defaultValue ""
          Bytes = optionalNumber "size_in_bytes" value }
