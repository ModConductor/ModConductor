namespace ModConductor.Thunderstore

open System
open System.Text.Json

module internal Json =
    let property (name: string) (value: JsonElement) =
        if value.ValueKind <> JsonValueKind.Object then Unchecked.defaultof<JsonElement>
        else match value.TryGetProperty name with true, found -> found | _ -> Unchecked.defaultof<JsonElement>
    let text name value =
        let found = property name value
        if found.ValueKind = JsonValueKind.String then found.GetString() else ""
    let number name value =
        let found = property name value
        if found.ValueKind <> JsonValueKind.Number then -1L
        else match found.TryGetInt64() with true, value -> value | _ -> -1L
    let flag name value = (property name value).ValueKind = JsonValueKind.True
    let array name value =
        let found = property name value
        if found.ValueKind = JsonValueKind.Array then found.EnumerateArray() |> Seq.toList else []
    let uri name value =
        match Uri.TryCreate(text name value, UriKind.Absolute) with
        | true, uri when uri.Scheme = "http" || uri.Scheme = "https" -> Some uri
        | _ -> None
    let package community value =
        { Community = match text "community_identifier" value with "" -> community | found -> found
          Namespace = text "namespace" value; Name = text "name" value }
    let preview community value =
        { Package = package community value; Description = text "description" value
          Icon = uri "icon_url" value; Deprecated = flag "is_deprecated" value }
    let dependency community value =
        { Reference = { Package = package community value; Version = text "version_number" value }
          Available = flag "is_active" value && not (flag "is_removed" value || flag "is_unavailable" value)
          Icon = uri "icon_url" value }
    let details community version value =
        // Exact listing routes keep latest_version_number as package metadata.
        let reference = { Package = package community value; Version = defaultArg version (text "latest_version_number" value) }
        let count = number "dependency_count" value
        let dependencies = array "dependencies" value |> List.map (dependency community)
        match uri "download_url" value with
        | Some download when VersionReference.valid reference && number "size" value >= 0L
                             && count >= 0L && count <= int64 Int32.MaxValue
                             && dependencies |> List.forall (fun dependency -> VersionReference.valid dependency.Reference) ->
            Ok { Reference = reference; Description = text "description" value; Icon = uri "icon_url" value
                 Deprecated = flag "is_deprecated" value; Download = download; Bytes = number "size" value
                 Categories = array "categories" value |> List.map (text "name")
                 Dependencies = dependencies
                 DependencyCount = int count }
        | _ -> Error Problem.InvalidResponse
    let next value =
        if (property "next" value).ValueKind = JsonValueKind.Null then Some None
        else
            uri "next" value
            |> Option.bind (fun uri ->
                uri.Query.TrimStart('?').Split('&')
                |> Array.tryPick (fun part ->
                    let parts = part.Split('=', 2)
                    if parts.Length <> 2 || parts[0] <> "page" then None
                    else match Int32.TryParse parts[1] with true, page -> Some(Some page) | _ -> None))
