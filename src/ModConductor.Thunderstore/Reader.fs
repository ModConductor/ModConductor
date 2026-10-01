namespace ModConductor.Thunderstore

open System
open System.Net.Http
open System.Text.Json
open System.Threading

[<Sealed>]
type PackageReader(?api: Uri, ?http: HttpClient) =
    let api = defaultArg api (Uri "https://thunderstore.io/api/cyberstorm/")
    let client = match http with Some client -> client | None -> new HttpClient()
    let transport = Transport client
    let listing reference = "listing/" + PackageReference.key reference + "/"
    let get (path: string) label read token = task {
        let! result = transport.Get(Uri(api, path), label, token)
        match result with
        | Error error -> return Error error
        | Ok document ->
            use document = document
            return read document.RootElement
    }
    let page community current value =
        let entries = Json.array "results" value |> List.map (Json.preview community)
        let count, next = Json.number "count" value, Json.next value
        if count < 0L || count > int64 Int32.MaxValue || (Json.property "results" value).ValueKind <> JsonValueKind.Array
           || entries |> List.exists (fun entry -> not (PackageReference.valid entry.Package))
           || next.IsNone || next.Value |> Option.exists (fun page -> page <= current) then Error Problem.InvalidResponse
        else Ok { Entries = entries; Count = int count; Next = next.Value }
    let dependencies (reference: VersionReference) count token = task {
        let path = "package/" + reference.Package.Namespace + "/" + reference.Package.Name + "/v/" + reference.Version + "/dependencies/"
        let mutable next, found, problem = Some 1, [], None
        while next.IsSome && problem.IsNone do
            let current = next.Value
            let! response = get (path + "?page=" + string current) (VersionReference.label reference) (fun value ->
                let next = Json.next value
                if next.IsNone || next.Value |> Option.exists (fun page -> page <= current) then Error Problem.InvalidResponse
                else Ok(Json.array "results" value |> List.map (Json.dependency reference.Package.Community), next.Value)) token
            match response with
            | Error error -> problem <- Some error
            | Ok(entries, following) -> found <- found @ entries; next <- following
        match problem with
        | Some error -> return Error error
        | None when found.Length <> count -> return Error Problem.InvalidResponse
        | None -> return Ok found
    }
    interface IPackageReader with
        member _.Search(community, query, ordering, current, token) =
            let validOrder = ["last-updated"; "most-downloaded"; "newest"; "top-rated"] |> List.contains ordering
            if current < 1 || not validOrder || not (PackageReference.valid { Community = community; Namespace = "x"; Name = "x" }) then
                System.Threading.Tasks.Task.FromResult(Error Problem.InvalidRequest)
            else
                let path = "listing/" + community + "/?deprecated=true&q=" + Uri.EscapeDataString query + "&ordering=" + ordering + "&page=" + string current
                get path community (page community current) token
        member _.Details(reference, version, token) = task {
            if not (PackageReference.valid reference) || version |> Option.exists (fun v -> not (VersionReference.valid { Package = reference; Version = v })) then
                return Error Problem.InvalidRequest
            else
                let path = listing reference + (version |> Option.map (fun value -> "v/" + value + "/") |> Option.defaultValue "")
                let! result = get path (PackageReference.label reference) (Json.details reference.Community version) token
                match result with
                | Error error -> return Error error
                | Ok value when value.Reference.Package <> reference || version |> Option.exists ((<>) value.Reference.Version) -> return Error Problem.InvalidResponse
                | Ok value when value.Dependencies.Length = value.DependencyCount -> return Ok value
                | Ok value ->
                    let! all = dependencies value.Reference value.DependencyCount token
                    return all |> Result.map (fun all -> { value with Dependencies = all })
        }
        member _.Versions(reference, token) =
            if not (PackageReference.valid reference) then System.Threading.Tasks.Task.FromResult(Error Problem.InvalidRequest)
            else get ("package/" + reference.Namespace + "/" + reference.Name + "/versions/") (PackageReference.label reference) (fun value ->
                if value.ValueKind <> JsonValueKind.Array then Error Problem.InvalidResponse
                else
                    let versions = value.EnumerateArray() |> Seq.map (Json.text "version_number") |> Seq.toList
                    if versions |> List.exists (fun version -> not (VersionReference.valid { Package = reference; Version = version })) then Error Problem.InvalidResponse
                    else Ok versions) token
    interface IDisposable with
        member _.Dispose() = if http.IsNone then client.Dispose()
