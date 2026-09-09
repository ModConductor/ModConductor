namespace ModConductor.ProtonContexts

open System
open System.IO
open System.Globalization
open System.Threading
open ModConductor.Platform
open ModConductor.GameContexts
open ModConductor.SteamDiscovery

module Validation =
    let private source (file: SteamSourceFile) : ContextFileEvidence =
        { Path = file.Path
          Identity = file.Identity
          Sha256 = file.Sha256 }

    let private association
        (game: InstallationEvidence)
        (selection: ProtonSelection)
        : ContextFileEvidence list =
        if selection.AppId <> Skyrim.definition.SteamAppId then
            raise (IOException "The Proton selection belongs to another Steam app.")

        let roots =
            match selection.Association with
            | ProtonAssociation.Manual -> []
            | ProtonAssociation.Steam(root, _) ->
                [ { Path = root
                    Origin = "Selected Steam root" } ]

        match selection.Association with
        | ProtonAssociation.Manual ->
            let directory = DirectoryInfo(fst (PrefixFiles.directory selection.CompatData))

            if not (isNull directory.Parent) && directory.Parent.Name = "compatdata" then
                match
                    UInt32.TryParse(directory.Name, NumberStyles.None, CultureInfo.InvariantCulture)
                with
                | true, app when app <> selection.AppId ->
                    let steamapps = directory.Parent.Parent

                    if not (isNull steamapps) && steamapps.Name = "steamapps" then
                        match
                            ContextSources.gameManifest
                                app
                                steamapps.Parent.FullName
                                CancellationToken.None
                        with
                        | Ok _ ->
                            raise (
                                IOException
                                    "The selected Proton data folder belongs to another Steam app."
                            )
                        | Error _ -> ()
                | _ -> ()

            []
        | ProtonAssociation.Steam(_, library) ->
            let libraryPath, libraryId = PrefixFiles.directory library

            let expected =
                Path.Combine(
                    libraryPath,
                    "steamapps",
                    "compatdata",
                    selection.AppId.ToString(CultureInfo.InvariantCulture)
                )

            let _, expectedId = PrefixFiles.directory expected
            let _, actualId = PrefixFiles.directory selection.CompatData

            if actualId <> expectedId then
                raise (
                    IOException
                        "The Proton data folder does not match the selected Steam app and library."
                )

            let report = Discovery.scan selection.AppId roots CancellationToken.None

            let origins =
                report.Candidates
                |> List.filter (fun c -> c.Directory.Identity = game.RootIdentity)
                |> List.collect _.Origins

            let valid = origins |> List.filter (fun o -> o.Library.Identity = Some libraryId)

            if valid.IsEmpty then
                raise (
                    IOException
                        "The Steam app manifest no longer identifies the selected game folder."
                )

            valid
            |> List.map (fun o ->
                { Path = o.Manifest.Path
                  Identity = o.Manifest.Identity
                  Sha256 = o.Manifest.Sha256 })

    let inspect (game: InstallationEvidence) (selection: ProtonSelection) =
        let mutable checking = selection.CompatData
        let mutable context = "The Proton data folder could not be checked."

        try
            if not (OperatingSystem.IsLinux()) then
                raise (
                    IOException
                        "Proton contexts are supported only on Linux. Use the native Windows game context."
                )

            let associationFiles = association game selection
            let compatdata, compatdataId = PrefixFiles.directory selection.CompatData
            let prefix, prefixId = PrefixFiles.directory (Path.Combine(compatdata, "pfx"))
            checking <- selection.RuntimeDirectory
            context <- "The selected Proton installation could not be checked."
            let runtime, runtimeId = PrefixFiles.directory selection.RuntimeDirectory

            let toolName, toolId, toolFiles, installationDirectory =
                if File.Exists(Path.Combine(runtime, "compatibilitytool.vdf")) then
                    match ContextSources.tools runtime CancellationToken.None with
                    | Error e -> raise (IOException e)
                    | Ok tools ->
                        let matching =
                            tools
                            |> List.filter (fun t ->
                                (selection.ToolId = "" || t.Id = selection.ToolId)
                                && (snd (PrefixFiles.directory t.Directory)) = runtimeId)

                        match matching with
                        | [ tool ] ->
                            Some tool.Name,
                            tool.Id,
                            [ source tool.Source ],
                            tool.InstallationDirectory
                        | _ ->
                            raise (
                                IOException
                                    "Select one installed Proton tool; its manifest is missing or ambiguous."
                            )
                elif selection.ToolId <> "" then
                    raise (
                        IOException
                            "The selected Proton tool ID is not declared by this installation."
                    )
                else
                    None, "", [], runtime

            let version, versionFile =
                PrefixFiles.text 4096 (Path.Combine(installationDirectory, "version"))

            let runtimeVersion = version.Trim()

            if runtimeVersion = "" then
                raise (IOException "The Proton version file is empty.")

            let _, launcher =
                PrefixFiles.read (4 * 1024 * 1024) (Path.Combine(installationDirectory, "proton"))

            let wine =
                [ "files"; "dist" ]
                |> List.tryFind (fun dir ->
                    File.Exists(Path.Combine(installationDirectory, dir, "bin", "wine")))

            if wine.IsNone then
                raise (IOException "The selected Proton folder has no Wine runtime.")

            checking <- Path.Combine(prefix, "user.reg")
            context <- "The Proton user folders could not be checked."

            let registryText, registryFile =
                PrefixFiles.text (4 * 1024 * 1024) (Path.Combine(prefix, "user.reg"))

            let registry = WineRegistry.read registryText
            let paths = PrefixPaths.locations Skyrim.definition prefix prefixId registry

            checking <- compatdata
            context <- "The Proton prefix metadata could not be checked."

            let prefixVersion, prefixFiles =
                if File.Exists(Path.Combine(compatdata, "version")) then
                    let value, file = PrefixFiles.text 4096 (Path.Combine(compatdata, "version"))
                    Some(value.Trim()), [ file ]
                else
                    None, []

            let mapping, mappingProblem =
                match selection.Association with
                | ProtonAssociation.Manual ->
                    None,
                    Some "The association was selected manually; no Steam mapping was checked."
                | ProtonAssociation.Steam(root, _) ->
                    match ContextSources.mappings selection.AppId root CancellationToken.None with
                    | Ok value -> Some value, None
                    | Error e -> None, Some e

            for declared, expected in
                [ selection.CompatData, compatdataId
                  Path.Combine(compatdata, "pfx"), prefixId
                  selection.RuntimeDirectory, runtimeId ] do
                if snd (PrefixFiles.directory declared) <> expected then
                    raise (IOException "A selected Proton folder changed during the check.")

            let launch, launchFiles =
                LaunchDiscovery.inspect selection installationDirectory launcher.Path

            let evidence =
                { Selection = { selection with ToolId = toolId }
                  PrefixPath = prefix
                  PrefixIdentity = prefixId
                  CompatDataIdentity = compatdataId
                  RuntimeIdentity = runtimeId
                  RuntimeName = defaultArg toolName runtimeVersion
                  RuntimeVersion = runtimeVersion
                  PrefixVersion = prefixVersion
                  Launcher = launcher
                  Launch = launch
                  Metadata =
                    associationFiles
                    @ [ registryFile; versionFile ]
                    @ toolFiles
                    @ launchFiles
                    @ prefixFiles
                    @ (mapping
                       |> Option.map (fun m -> [ source m.Source ])
                       |> Option.defaultValue [])
                  PerGameTool = mapping |> Option.bind _.PerGame
                  GlobalTool = mapping |> Option.bind _.GlobalDefault
                  MappingProblem = mappingProblem
                  Paths = paths }

            let locate name =
                paths |> List.find (fun p -> p.Name = name) |> _.HostLocation

            let result =
                { game with
                    Proton = Some evidence
                    Locations =
                        { Documents = locate "Documents"
                          Saves = locate "Saves"
                          LocalAppData = locate "Local AppData" } }

            { result with
                Fingerprint = ContextIdentity.fingerprint result }
        with (:? IOException | :? UnauthorizedAccessException | :? ArgumentException) as e ->
            let result =
                { game with
                    Problems =
                        game.Problems
                        @ [ { Path = checking
                              Detail = context + " " + e.Message } ] }

            { result with
                Fingerprint = ContextIdentity.fingerprint result }
