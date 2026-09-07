namespace ModConductor.SteamDiscovery

open System
open System.Collections.Generic
open System.Globalization
open System.IO
open System.Security.Cryptography
open System.Text
open System.Threading

module Discovery =
    let scan appId (roots: SearchRoot list) (cancellation: CancellationToken) =
        if
            appId = 0u
            || roots.Length > 24
            || (roots |> List.exists (fun r -> r.Origin.Length > 128))
        then
            invalidArg (nameof roots) "The Steam search request exceeds its limits."

        let oversized, roots = roots |> List.partition (fun r -> r.Path.Length > 4096)

        let roots =
            roots |> List.distinct |> List.sortBy (fun root -> root.Path, root.Origin)

        let diagnostics = ResizeArray<DiscoveryDiagnostic>()
        let candidates = Dictionary<string, InstallationCandidate>(StringComparer.Ordinal)
        let libraries = HashSet<string>(StringComparer.Ordinal)
        let mutable complete = true
        let mutable origins = 0
        let mutable visits = 0
        let mutable textBudget = 0

        let limited root path =
            if complete then
                complete <- false

                diagnostics.Add
                    { RootPath = root
                      Path = path
                      Kind = DiagnosticKind.LimitReached
                      Detail = "The Steam search reached its limit." }

        let diagnostic (root: string) (path: string) kind (detail: string) =
            let cost = root.Length + path.Length + detail.Length + 128

            if complete then
                if diagnostics.Count >= 255 || textBudget + cost > 190000 then
                    limited "" ""
                else
                    textBudget <- textBudget + cost

                    diagnostics.Add
                        { RootPath = root
                          Path = path
                          Kind = kind
                          Detail = detail }

        for root in oversized |> List.distinct |> List.sortBy (fun r -> r.Path, r.Origin) do
            let shownPath = root.Path.Substring(0, 256) + "…"

            diagnostic
                shownPath
                shownPath
                DiagnosticKind.RootUnavailable
                (root.Origin + ": The Steam folder path exceeds the search limit.")

        let scanLibrary (root: SearchRoot) steamRoot entry claimed libraryPath =
            cancellation.ThrowIfCancellationRequested()
            visits <- visits + 1

            if visits > 256 then
                limited "" ""

            if complete then
                match SteamFiles.directory libraryPath with
                | Error _ ->
                    diagnostic
                        root.Path
                        libraryPath
                        DiagnosticKind.RootUnavailable
                        "The Steam library folder is unavailable."
                | Ok library ->
                    let key = SteamFiles.directoryKey library

                    if libraries.Count >= 64 && not (libraries.Contains key) then
                        limited root.Path libraryPath
                    else
                        libraries.Add key |> ignore

                        let manifestPath =
                            Path.Combine(
                                library.CanonicalPath,
                                "steamapps",
                                "appmanifest_"
                                + appId.ToString(CultureInfo.InvariantCulture)
                                + ".acf"
                            )

                        if not (File.Exists manifestPath) then
                            if claimed then
                                diagnostic
                                    root.Path
                                    manifestPath
                                    DiagnosticKind.StaleEntry
                                    "Steam lists this app, but its game manifest is missing."
                        else
                            match SteamFiles.read cancellation manifestPath with
                            | Error(SteamFiles.Unreadable detail) ->
                                diagnostic
                                    root.Path
                                    manifestPath
                                    DiagnosticKind.ManifestUnreadable
                                    detail
                            | Error(SteamFiles.Malformed detail) ->
                                diagnostic
                                    root.Path
                                    manifestPath
                                    DiagnosticKind.ManifestMalformed
                                    detail
                            | Ok(values, identity, hash, canonicalManifest) ->
                                match
                                    SteamFiles.manifest appId values identity hash canonicalManifest
                                with
                                | Error(kind, detail) ->
                                    diagnostic root.Path manifestPath kind detail
                                | Ok manifest ->
                                    match
                                        SteamFiles.installationPath
                                            (Path.Combine(
                                                library.DeclaredPath,
                                                "steamapps",
                                                "common"
                                            ))
                                            manifest.InstallDirectory
                                    with
                                    | Error detail ->
                                        diagnostic
                                            root.Path
                                            manifestPath
                                            DiagnosticKind.UnsafeInstallDirectory
                                            detail
                                    | Ok path ->
                                        match SteamFiles.directory path with
                                        | Error _ ->
                                            diagnostic
                                                root.Path
                                                path
                                                DiagnosticKind.InstallationUnavailable
                                                "The installation folder recorded by Steam is unavailable."
                                        | Ok directory ->
                                            let origin =
                                                { Root = root
                                                  SteamRoot = steamRoot
                                                  Library = library
                                                  LibraryEntry = entry
                                                  Manifest = manifest }

                                            let key = SteamFiles.directoryKey directory

                                            let cost =
                                                root.Path.Length
                                                + root.Origin.Length
                                                + steamRoot.DeclaredPath.Length
                                                + steamRoot.CanonicalPath.Length
                                                + library.DeclaredPath.Length
                                                + library.CanonicalPath.Length
                                                + directory.DeclaredPath.Length
                                                + directory.CanonicalPath.Length
                                                + manifest.Path.Length
                                                + manifest.InstallDirectory.Length
                                                + (manifest.Name
                                                   |> Option.map _.Length
                                                   |> Option.defaultValue 0)
                                                + 512

                                            let duplicate =
                                                match candidates.TryGetValue key with
                                                | true, old -> List.contains origin old.Origins
                                                | _ -> false

                                            if not duplicate then
                                                if origins >= 256 || textBudget + cost > 200000 then
                                                    limited root.Path libraryPath
                                                else
                                                    origins <- origins + 1
                                                    textBudget <- textBudget + cost

                                                    match candidates.TryGetValue key with
                                                    | true, old ->
                                                        candidates[key] <-
                                                            { old with
                                                                Origins = origin :: old.Origins }
                                                    | _ ->
                                                        let id =
                                                            Convert.ToHexStringLower(
                                                                SHA256.HashData(
                                                                    Encoding.UTF8.GetBytes key
                                                                )
                                                            )

                                                        candidates.Add(
                                                            key,
                                                            { Id = id
                                                              Directory = directory
                                                              Origins = [ origin ] }
                                                        )

        for root in roots do
            cancellation.ThrowIfCancellationRequested()

            if complete then
                match SteamFiles.directory root.Path with
                | Error _ ->
                    diagnostic
                        root.Path
                        root.Path
                        DiagnosticKind.RootUnavailable
                        "The Steam folder is unavailable."
                | Ok steamRoot ->
                    scanLibrary root steamRoot None false root.Path

                    let index =
                        Path.Combine(steamRoot.CanonicalPath, "steamapps", "libraryfolders.vdf")

                    if File.Exists index then
                        match SteamFiles.read cancellation index with
                        | Error(SteamFiles.Unreadable detail) ->
                            diagnostic root.Path index DiagnosticKind.LibrariesUnreadable detail
                        | Error(SteamFiles.Malformed detail) ->
                            diagnostic root.Path index DiagnosticKind.LibrariesMalformed detail
                        | Ok(values, _, _, _) ->
                            match KeyValues.body "libraryfolders" values with
                            | Error detail ->
                                diagnostic root.Path index DiagnosticKind.LibrariesMalformed detail
                            | Ok entries ->
                                for number, value in entries |> List.sortBy fst do
                                    match
                                        UInt32.TryParse(
                                            number,
                                            NumberStyles.None,
                                            CultureInfo.InvariantCulture
                                        )
                                    with
                                    | false, _ -> ()
                                    | true, _ ->
                                        let path, claimed =
                                            match value with
                                            | KeyValues.Text path -> Ok(Some path), false
                                            | KeyValues.Object fields ->
                                                let claimed =
                                                    match KeyValues.field "apps" fields with
                                                    | Ok(Some(KeyValues.Object apps)) ->
                                                        apps
                                                        |> List.exists (fun (id, _) ->
                                                            id = string appId)
                                                    | _ -> false

                                                KeyValues.text "path" fields, claimed

                                        match path with
                                        | Ok(Some path) when
                                            path.Length <= 4096 && Path.IsPathFullyQualified path
                                            ->
                                            scanLibrary root steamRoot (Some number) claimed path
                                        | _ ->
                                            diagnostic
                                                root.Path
                                                index
                                                DiagnosticKind.LibraryPathInvalid
                                                "A Steam library entry has no valid absolute folder path."

        { AppId = appId
          Roots = roots
          Candidates =
            candidates.Values
            |> Seq.map (fun c ->
                { c with
                    Origins =
                        c.Origins
                        |> List.sortBy (fun o ->
                            o.Root.Path,
                            o.Root.Origin,
                            o.Library.DeclaredPath,
                            o.LibraryEntry,
                            o.Manifest.Path) })
            |> Seq.sortBy (fun c -> c.Directory.CanonicalPath, c.Id)
            |> Seq.toList
          Diagnostics =
            diagnostics
            |> Seq.distinct
            |> Seq.sortBy (fun d -> d.RootPath, d.Path, d.Kind, d.Detail)
            |> Seq.toList
          Complete = complete }
