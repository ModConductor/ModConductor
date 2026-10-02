namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.IO.Compression
open System.Text.Json
open System.Threading
open ModConductor.GameCatalogue
open ModConductor.GameCatalogue.Serialization
open ModConductor.GameContexts
open ModConductor.GameDiscovery
open ModConductor.GameLaunching
open ModConductor.Persistence
open ModConductor.Workspaces
open ModConductor.ModSelection
open ModConductor.SteamDiscovery
open ModConductor.Thunderstore

module GameDiscoveryFixtures =
    let private token = CancellationToken.None

    let private check (writer: Utf8JsonWriter) (name: string) passed =
        writer.WriteBoolean(name, passed)

        if not passed then
            invalidOp ("Game discovery fixture failed: " + name)

    let private schema =
        """{"games":{"fixture":{"meta":{"displayName":"Fixture"},"distributions":[{"platform":"steam","identifier":"990001"}],"r2modman":[{"meta":{"displayName":"Fixture"},"distributions":[{"platform":"steam","identifier":"990001"}],"exeNames":["Fixture.exe"],"dataFolderName":"Fixture_Data","packageLoader":"bepinex","packageIndex":"https://thunderstore.io/c/fixture/api/v1/package-listing-index/","installRules":[{"route":"BepInEx/plugins","trackingMethod":"subdir","isDefaultLocation":true}],"additionalSearchStrings":["example"]}]},"site-only":{"meta":{"displayName":"Community only"},"thunderstore":{"displayName":"Community only"}}},"modloaderPackages":[]}"""

    let observe writer game =
        use document = JsonDocument.Parse schema
        let games = Ecosystem.read document.RootElement |> StorageWorker.result
        let matching = games |> List.filter (Ecosystem.matchesSteam 990001u)
        let site = Ecosystem.search "Community" games |> List.exactlyOne

        check
            writer
            "exactMetadataAndSiteOnly"
            (matching.Length = 1
             && matching.Head.Executables.IsEmpty = false
             && site.Executables.IsEmpty
             && not (Ecosystem.matchesSteam 990002u matching.Head))

        let draft =
            GameDocument(
                Name = "Fixture",
                Content = matching.Head.Content,
                Executable = matching.Head.Executables.Head
            )

        let detected, _, _ =
            InstallationDetection.inspect game draft |> StorageWorker.result

        check
            writer
            "selectedFolderDetectsMono"
            (detected.Mechanism = "unity-mono" && detected.LinuxExecutable = "Fixture.x86_64")

        use server = new DownloadServer(System.Text.Encoding.UTF8.GetBytes schema)
        use reader = new EcosystemReader(address = Uri(server.Url + "/good"))
        let service = Discovery(reader, ThunderstoreSamples.reader [])

        let matched =
            service.Inspect(game, "Fixture", 990001u, "", token) |> StorageWorker.wait

        let unrelated =
            service.Inspect(game, "Fixture", 990009u, "", token) |> StorageWorker.wait

        let community =
            service.Inspect(game, "Fixture", 0u, "site-only:0", token) |> StorageWorker.wait

        check
            writer
            "metadataOrchestratesOnlyExactSupportedSetup"
            (matched.Draft.Mechanism = "unity-mono"
             && unrelated.Draft.Mechanism = ""
             && community.Draft.Mechanism = ""
             && community.DetectedEngine = "unity-mono")

        use unavailable = new EcosystemReader(address = Uri(server.Url + "/mirror-fail"))

        let offline =
            Discovery(unavailable, ThunderstoreSamples.reader [])
                .Inspect(game, "Fixture", 990001u, "", token)
            |> StorageWorker.wait

        check
            writer
            "unavailableMetadataRetainsManualDetection"
            (offline.Draft.Mechanism = ""
             && offline.DetectedEngine = "unity-mono"
             && offline.Draft.Executable <> "")

        let steam = Directory.CreateDirectory(Path.Combine(game, "..", "Steam")).FullName
        let library = Path.Combine(steam, "steamapps")

        Directory.CreateDirectory(Path.Combine(library, "common", "Unknown title"))
        |> ignore

        File.WriteAllText(
            Path.Combine(library, "appmanifest_999987.acf"),
            "AppState { appid 999987 name \"Unknown title\" installdir \"Unknown title\" }"
        )

        let report = InstalledGames.scan [ { Path = steam; Origin = "Fixture" } ] token

        check
            writer
            "unknownSteamAppEnumerated"
            (report.Candidates
             |> List.exists (fun row ->
                 row.Origins |> List.exists (fun origin -> origin.Manifest.AppId = 999987u)))
