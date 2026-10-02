namespace ModConductor.Native.Fixtures

open System
open System.Net
open System.Net.Http
open System.Text.Json
open System.Threading
open ModConductor.Persistence
open ModConductor.Thunderstore

module ThunderstoreReaderFixtures =
    let private wait = StorageWorker.wait
    let private result = StorageWorker.result
    let private token = CancellationToken.None
    let observe (check: string -> bool -> unit) =
        let requests = ResizeArray<string>()
        use handler = new ThunderstoreHttpFixture(fun request ->
            let path = request.RequestUri.PathAndQuery
            requests.Add path
            if path.Contains("q=invalid") then
                ThunderstoreSamples.response HttpStatusCode.OK (ThunderstoreSamples.search "\"not-a-page\"" "One")
            elif path.Contains("page=2") then
                ThunderstoreSamples.response HttpStatusCode.OK (ThunderstoreSamples.search "null" "Two")
            else ThunderstoreSamples.response HttpStatusCode.OK (ThunderstoreSamples.search "\"http://fixture/listing/valheim/?page=2\"" "One"))
        use http = new HttpClient(handler)
        use reader = new PackageReader(api = Uri "http://fixture/", http = http)
        let api = reader :> IPackageReader
        let first = api.Search("valheim", "with space", "newest", 1, token) |> wait |> result
        let second = api.Search("valheim", "with space", "newest", first.Next.Value, token) |> wait |> result
        check "PagedQueryKeepsProviderOrderAndCursor" (first.Entries.Head.Package.Name = "One" && second.Entries.Head.Package.Name = "Two" && second.Next.IsNone && requests[0].Contains("q=with%20space&ordering=newest"))
        check "MalformedNextPageIsNotFalseCompletion" (api.Search("valheim", "invalid", "newest", 1, token) |> wait = Error Problem.InvalidResponse)
        let mutable calls = 0
        use throttle = new ThunderstoreHttpFixture(fun _ ->
            calls <- calls + 1
            let value = ThunderstoreSamples.response HttpStatusCode.TooManyRequests "{}"
            value.Headers.RetryAfter <- System.Net.Http.Headers.RetryConditionHeaderValue(TimeSpan.FromSeconds 20.)
            value)
        use throttledHttp = new HttpClient(throttle)
        use throttled = new PackageReader(api = Uri "http://fixture/", http = throttledHttp)
        let request () = (throttled :> IPackageReader).Search("valheim", "", "newest", 1, token) |> wait
        let isLimited = function Error(Problem.RateLimited(Some _)) -> true | _ -> false
        check "RetryAfterStopsImmediateProviderRequests" (isLimited(request()) && isLimited(request()) && calls = 1)

        let exactBody = """{"namespace":"denikson","name":"BepInExPack_Valheim","latest_version_number":"5.4.2351","download_url":"https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/","size":739197,"dependency_count":0,"dependencies":[]}"""
        use exactHandler = new ThunderstoreHttpFixture(fun _ -> ThunderstoreSamples.response HttpStatusCode.OK exactBody)
        use exactHttp = new HttpClient(exactHandler)
        use exact = new PackageReader(api = Uri "http://fixture/", http = exactHttp)
        let selected = (exact :> IPackageReader).Details(ThunderstoreSamples.bep.Package, Some "5.4.2333", token) |> wait |> result
        check "ExactListingKeepsRequestedVersionNotPackageLatest" (selected.Reference = ThunderstoreSamples.bep && selected.Download.AbsolutePath.EndsWith("/5.4.2333/"))

        use missingHandler = new ThunderstoreHttpFixture(fun _ -> ThunderstoreSamples.response HttpStatusCode.NotFound "{}")
        use missingHttp = new HttpClient(missingHandler)
        use missing = new PackageReader(api = Uri "http://fixture/", http = missingHttp)
        let unavailable = (missing :> IPackageReader).Details(ThunderstoreSamples.bep.Package, Some "5.4.2333", token) |> wait
        check "MissingExactVersionReportsAffectedPackage" (unavailable = Error(Problem.NotFound "denikson-BepInExPack_Valheim"))
        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()
        check "CancelledMetadataRequestIsAnOrdinaryRefusal" ((missing :> IPackageReader).Details(ThunderstoreSamples.bep.Package, Some "5.4.2333", cancelled.Token) |> wait = Error Problem.Cancelled)

    let requirements (check: string -> bool -> unit) =
        let ref = ThunderstoreSamples.reference
        let dep = ThunderstoreSamples.dependency
        let package reference dependencies = ThunderstoreSamples.package reference "http://fixture/archive" 1L dependencies
        let root, left, right, shared = ref "Root" "1.0.0", ref "Left" "1.0.0", ref "Right" "1.0.0", ref "Shared" "1.0.0"
        let packages = [package root [dep left; dep right]; package left [dep shared]; package right [dep shared]; package shared []]
        let resolved = Dependencies.resolve (ThunderstoreSamples.reader packages) root token |> wait |> result
        check "ExactDiamondRequirementsAreAddedOnceBeforeRoot" (resolved |> List.map _.Reference = [shared; left; right; root])
        let conflict = package right [dep {shared with Version = "2.0.0"}]
        let conflicted = Dependencies.resolve (ThunderstoreSamples.reader (conflict :: (packages |> List.filter (fun p -> p.Reference <> right)))) root token |> wait
        check "ConflictingExactRequirementsAreRefused" (match conflicted with Error(Problem.Requirements _) -> true | _ -> false)
        let unavailable = package root [{dep shared with Available = false}]
        check "UnavailableRequirementsAreRefused" (match Dependencies.resolve (ThunderstoreSamples.reader [unavailable]) root token |> wait with Error(Problem.Requirements _) -> true | _ -> false)
        let cyclic = [package root [dep left]; package left [dep root]]
        check "DependencyCyclesAreRefused" (match Dependencies.resolve (ThunderstoreSamples.reader cyclic) root token |> wait with Error(Problem.Requirements _) -> true | _ -> false)

    let portable (check: string -> bool -> unit) =
        let modItem source : PortableMod =
            { Kind = "regular"; Name = "Package"; Version = "1"; Notes = ""; Comment = ""; Categories = []
              Source = Some source; Base = None; Priority = 0; Enabled = Some false; Files = []; Deleted = []; Hidden = [] }
        let profile : PortableProfile =
            { Name = "Portable"; Game = "skyrim-se-steam"
              GameDefinition = None
              Mods = [modItem (PortableSource.Thunderstore ThunderstoreSamples.jotunn)
                      modItem (PortableSource.Nexus {Game = "skyrimspecialedition"; ModId = 1L; FileId = 2L; FileVersion = "1"})]
              PluginOrder = []; SettingsEnabled = false; SavesEnabled = false; Settings = []; Saves = []; Artwork = None }
        let reopened = profile |> ProfileTransportJson.write |> ProfileTransportJson.read
        let reexported = reopened |> ProfileTransportJson.write |> ProfileTransportJson.read
        check "PortableSourceRoundtripKeepsProvidersDistinct" (reexported.Mods |> List.map _.Source = (profile.Mods |> List.map _.Source))
