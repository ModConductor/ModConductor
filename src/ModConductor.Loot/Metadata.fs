namespace ModConductor.Loot

open System
open System.IO
open System.Net.Http
open System.Security.Cryptography
open System.Threading

type internal MetadataCache(root: string) =
    let cache = Path.Combine(root, "loot-metadata", "skyrim-se-steam")
    let revisions = Path.Combine(cache, "revisions")
    let current = Path.Combine(cache, "current.json")

    let contained (path: string) =
        let comparison =
            if OperatingSystem.IsWindows() then
                StringComparison.OrdinalIgnoreCase
            else
                StringComparison.Ordinal

        let prefix = Path.GetFullPath(revisions) + string Path.DirectorySeparatorChar
        Path.GetFullPath(path).StartsWith(prefix, comparison)

    let sha (path: string) =
        use stream = File.OpenRead path
        SHA256.HashData stream |> Convert.ToHexStringLower

    let validate (value: LootMetadata) =
        contained value.MasterlistPath
        && contained value.PreludePath
        && File.Exists value.MasterlistPath
        && File.Exists value.PreludePath
        && sha value.MasterlistPath = value.MasterlistSha256
        && sha value.PreludePath = value.PreludeSha256

    member _.Current() =
        try
            if File.Exists current then
                let value = LootJson.readMetadataManifest current
                if validate value then Some value else None
            else
                None
        with
        | :? IOException
        | :? UnauthorizedAccessException
        | :? InvalidDataException
        | :? System.Text.Json.JsonException -> None

    member _.Install(masterlistCommit, preludeCommit, masterlist: byte array, prelude: byte array) =
        if masterlist.Length > 64 * 1024 * 1024 || prelude.Length > 16 * 1024 * 1024 then
            invalidArg "metadata" "The LOOT metadata exceeds its download limit."

        let masterSha = SHA256.HashData masterlist |> Convert.ToHexStringLower
        let preludeSha = SHA256.HashData prelude |> Convert.ToHexStringLower
        let revision = masterlistCommit + ":" + preludeCommit
        let directory = Path.Combine(cache, "revisions", masterSha + "-" + preludeSha)
        Directory.CreateDirectory directory |> ignore
        let masterPath = Path.Combine(directory, "masterlist.yaml")
        let preludePath = Path.Combine(directory, "prelude.yaml")
        File.WriteAllBytes(masterPath, masterlist)
        File.WriteAllBytes(preludePath, prelude)

        let value =
            { Revision = revision
              MasterlistCommit = masterlistCommit
              PreludeCommit = preludeCommit
              MasterlistSha256 = masterSha
              PreludeSha256 = preludeSha
              MasterlistPath = masterPath
              PreludePath = preludePath
              FetchedAt = DateTimeOffset.UtcNow }

        Directory.CreateDirectory cache |> ignore
        let pending = Path.Combine(cache, ".current-" + Guid.NewGuid().ToString("N"))
        File.WriteAllBytes(pending, LootJson.metadataManifest value)
        File.Move(pending, current, true)
        value

    member this.ValidateAndInstall
        (
            masterlistCommit,
            preludeCommit,
            masterlist: byte array,
            prelude: byte array,
            validateMetadata: LootMetadata -> Async<Result<unit, LootError>>
        ) =
        async {
            if masterlist.Length > 64 * 1024 * 1024 || prelude.Length > 16 * 1024 * 1024 then
                return
                    Error(
                        LootError.MetadataUnavailable
                            "The LOOT metadata response exceeds its limit."
                    )
            else
                let stage =
                    Directory.CreateDirectory(
                        Path.Combine(cache, ".stage-" + Guid.NewGuid().ToString("N"))
                    )
                    |> _.FullName

                try
                    let masterPath = Path.Combine(stage, "masterlist.yaml")
                    let preludePath = Path.Combine(stage, "prelude.yaml")
                    File.WriteAllBytes(masterPath, masterlist)
                    File.WriteAllBytes(preludePath, prelude)

                    let candidate =
                        { Revision = masterlistCommit + ":" + preludeCommit
                          MasterlistCommit = masterlistCommit
                          PreludeCommit = preludeCommit
                          MasterlistSha256 = SHA256.HashData masterlist |> Convert.ToHexStringLower
                          PreludeSha256 = SHA256.HashData prelude |> Convert.ToHexStringLower
                          MasterlistPath = masterPath
                          PreludePath = preludePath
                          FetchedAt = DateTimeOffset.UtcNow }

                    let! validated = validateMetadata candidate

                    match validated with
                    | Error error -> return Error error
                    | Ok() ->
                        return
                            Ok(this.Install(masterlistCommit, preludeCommit, masterlist, prelude))
                finally
                    try
                        Directory.Delete(stage, true)
                    with _ ->
                        ()
        }

    member this.Refresh
        (token: CancellationToken, validateMetadata: LootMetadata -> Async<Result<unit, LootError>>)
        =
        async {
            try
                use client = new HttpClient()
                client.DefaultRequestHeaders.UserAgent.ParseAdd("ModConductor-MC046/1")

                let get (url: string) (limit: int) =
                    async {
                        use! response =
                            client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, token)
                            |> Async.AwaitTask

                        response.EnsureSuccessStatusCode() |> ignore

                        if
                            response.Content.Headers.ContentLength.HasValue
                            && response.Content.Headers.ContentLength.Value > int64 limit
                        then
                            raise (
                                InvalidDataException "The LOOT metadata response exceeds its limit."
                            )

                        use! input = response.Content.ReadAsStreamAsync(token) |> Async.AwaitTask
                        use output = new MemoryStream()
                        let buffer = Array.zeroCreate<byte> (64 * 1024)
                        let mutable reading = true

                        while reading do
                            let! count = input.ReadAsync(buffer, token).AsTask() |> Async.AwaitTask

                            if count = 0 then
                                reading <- false
                            else
                                if output.Length + int64 count > int64 limit then
                                    raise (
                                        InvalidDataException
                                            "The LOOT metadata response exceeds its limit."
                                    )

                                output.Write(buffer, 0, count)

                        return output.ToArray()
                    }

                let! masterHead =
                    get "https://api.github.com/repos/loot/skyrimse/commits/v0.29" (1024 * 1024)

                let! preludeHead =
                    get "https://api.github.com/repos/loot/prelude/commits/v0.29" (1024 * 1024)

                let masterCommit = LootJson.commit masterHead
                let preludeCommit = LootJson.commit preludeHead

                let! master =
                    get
                        ("https://raw.githubusercontent.com/loot/skyrimse/"
                         + masterCommit
                         + "/masterlist.yaml")
                        (64 * 1024 * 1024)

                let! prelude =
                    get
                        ("https://raw.githubusercontent.com/loot/prelude/"
                         + preludeCommit
                         + "/prelude.yaml")
                        (16 * 1024 * 1024)

                return!
                    this.ValidateAndInstall(
                        masterCommit,
                        preludeCommit,
                        master,
                        prelude,
                        validateMetadata
                    )
            with
            | :? OperationCanceledException -> return Error LootError.Cancelled
            | error ->
                return
                    Error(
                        LootError.MetadataUnavailable(
                            "LOOT metadata could not be refreshed: " + error.Message
                        )
                    )
        }
