namespace ModConductor.Native.Fixtures

open System
open System.IO
open System.Security.Cryptography
open System.Text.Json
open System.Threading
open ModConductor.SteamDiscovery

module SteamDiscoveryFixtures =
    let private quote (value: string) =
        "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\""

    let private write (path: string) (text: string) =
        Directory.CreateDirectory(Path.GetDirectoryName(path: string)) |> ignore
        File.WriteAllText(path, text)

    let private manifest (library: string) (appId: string) (install: string) (build: string) =
        write
            (Path.Combine(library, "steamapps", "appmanifest_489830.acf"))
            (("// owned fixture\nAppState { appid "
              + (appId)
              + " installdir "
              + (quote install)
              + " name \"Skyrim Special Edition\" buildid "
              + (build)
              + " StateFlags 4 }"))

    let private root path =
        { Path = path
          Origin = "Selected Steam folder" }

    let private scan paths =
        Discovery.scan 489830u (List.map root paths) CancellationToken.None

    let create primary =
        let steam = Path.Combine(primary, "Steam")
        let library = Path.Combine(primary, "Second library")
        let game = Path.Combine(library, "steamapps", "common", "Skyrim Special Edition")
        GameContextFixtures.create game 104
        manifest library "489830" "Skyrim Special Edition" "24914197"
        let unavailable = Path.Combine(primary, "Unavailable library")

        write
            (Path.Combine(steam, "steamapps", "libraryfolders.vdf"))
            (("libraryfolders { 0 { path "
              + (quote library)
              + " apps { 999 \"1\" } } 1 { path "
              + (quote unavailable)
              + " } }"))

        steam, library, game

    let observe (writer: Utf8JsonWriter) primary =
        let directory = Path.Combine(primary, "steam-discovery")
        let steam, library, game = create directory
        let manifestPath = Path.Combine(library, "steamapps", "appmanifest_489830.acf")
        let initial = File.ReadAllBytes manifestPath
        let gameBytes = File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe"))
        let original = scan [ steam ]
        let candidate = original.Candidates |> List.exactlyOne
        writer.WriteStartObject("steamDiscovery")

        writer.WriteBoolean(
            "uncachedAppFound",
            candidate.Directory.CanonicalPath = game
            && candidate.Origins.Head.Manifest.BuildId = Some "24914197"
        )

        writer.WriteBoolean(
            "unavailableLibraryIsolated",
            original.Complete
            && original.Diagnostics
               |> List.exists (fun d -> d.Kind = DiagnosticKind.RootUnavailable)
        )

        let alias = Path.Combine(directory, "Steam alias")
        Directory.CreateSymbolicLink(alias, steam) |> ignore
        let libraryAlias = Path.Combine(directory, "Library alias")
        Directory.CreateSymbolicLink(libraryAlias, library) |> ignore
        let oldSteam = Path.Combine(directory, "Old Steam")

        write
            (Path.Combine(oldSteam, "steamapps", "libraryfolders.vdf"))
            (("\"LibraryFolders\" { \"0\" " + (quote libraryAlias) + " }"))

        let linkedLibrary = Path.Combine(directory, "Linked game library")
        let linkedGame = Path.Combine(linkedLibrary, "steamapps", "common", "Linked game")
        Directory.CreateDirectory(Path.GetDirectoryName linkedGame) |> ignore
        Directory.CreateSymbolicLink(linkedGame, game) |> ignore
        manifest linkedLibrary "489830" "Linked game" "older-build"
        let combined = scan [ steam; alias; oldSteam; linkedLibrary ]
        let reversed = scan [ linkedLibrary; oldSteam; alias; steam ]
        let shared = combined.Candidates |> List.exactlyOne

        writer.WriteBoolean(
            "linksDeduplicateWithOrigins",
            shared.Id = candidate.Id
            && shared.Origins.Length = 4
            && shared.Origins |> List.exists (fun o -> o.Library.DeclaredPath = libraryAlias)
        )

        writer.WriteBoolean(
            "originEvidenceRetained",
            (shared.Origins |> List.map _.Manifest.BuildId |> Set.ofList) =
                Set.ofList [ Some "24914197"; Some "older-build" ]
        )

        writer.WriteBoolean("deterministicSearch", (combined = reversed))

        let bad = Path.Combine(directory, "Bad library")
        let stale = Path.Combine(directory, "Stale library")
        Directory.CreateDirectory stale |> ignore

        write
            (Path.Combine(bad, "steamapps", "appmanifest_489830.acf"))
            "AppState { appid \"unterminated"

        let mixed = Path.Combine(directory, "Mixed Steam")

        write
            (Path.Combine(mixed, "steamapps", "libraryfolders.vdf"))
            (("libraryfolders { 0 "
              + (quote library)
              + " 1 "
              + (quote bad)
              + " 2 { path "
              + (quote stale)
              + " apps { 489830 1 } } }"))

        let isolated = scan [ mixed ]

        writer.WriteBoolean(
            "badManifestAndStaleCacheIsolated",
            isolated.Candidates.Length = 1
            && isolated.Diagnostics.Length = 2
            && isolated.Diagnostics
               |> List.exists (fun d -> d.Kind = DiagnosticKind.StaleEntry)
        )

        manifest bad "999" "Skyrim Special Edition" "1"

        writer.WriteBoolean(
            "foreignAppRefused",
            (scan [ bad ]).Diagnostics
            |> List.exists (fun d -> d.Kind = DiagnosticKind.AppIdMismatch)
        )

        let unsafeNames =
            [ "../escape"
              "..\\escape"
              "/outside"
              "C:\\outside"
              "\\\\server\\share"
              "safe/../escape" ]

        let refused =
            unsafeNames
            |> List.forall (fun name ->
                manifest bad "489830" name "1"
                let result = scan [ bad ]

                result.Candidates.IsEmpty
                && result.Diagnostics
                   |> List.exists (fun d -> d.Kind = DiagnosticKind.UnsafeInstallDirectory))

        writer.WriteBoolean("unsafeInstallDirectoriesRefused", refused)
        write (Path.Combine(bad, "steamapps", "appmanifest_489830.acf")) "#include \"outside.acf\""
        writer.WriteBoolean("metadataDoesNotLoadIncludes", (scan [ bad ]).Candidates.IsEmpty)
        write (Path.Combine(bad, "steamapps", "appmanifest_489830.acf")) (String('x', 1100000))
        let oversized = scan [ bad; library ]

        writer.WriteBoolean(
            "oversizedMetadataIsolated",
            oversized.Candidates.Length = 1 && not oversized.Diagnostics.IsEmpty
        )

        let many = Path.Combine(directory, "Many libraries")

        let entries =
            [ 0..300 ]
            |> List.map (fun n ->
                ((n.ToString(System.Globalization.CultureInfo.InvariantCulture))
                 + " "
                 + (quote library)))
            |> String.concat " "

        write
            (Path.Combine(many, "steamapps", "libraryfolders.vdf"))
            (("libraryfolders { " + (entries) + " }"))

        let limited = scan [ many ]

        writer.WriteBoolean(
            "partialSearchDeclared",
            not limited.Complete
            && not limited.Candidates.IsEmpty
            && limited.Diagnostics
               |> List.exists (fun d -> d.Kind = DiagnosticKind.LimitReached)
        )

        use cancelled = new CancellationTokenSource()
        cancelled.Cancel()

        let wasCancelled =
            try
                Discovery.scan 489830u [ root steam ] cancelled.Token |> ignore
                false
            with :? OperationCanceledException ->
                true

        writer.WriteBoolean("cancelledSearchStops", wasCancelled)

        writer.WriteBoolean(
            "readOnlySearch",
            File.ReadAllBytes manifestPath = initial
            && File.ReadAllBytes(Path.Combine(game, "SkyrimSE.exe")) = gameBytes
        )

        writer.WriteString("manifestSha256", Convert.ToHexStringLower(SHA256.HashData initial))
        writer.WriteEndObject()
