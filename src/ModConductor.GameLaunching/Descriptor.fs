namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Platform

module internal Descriptor =
    let private inside root candidate =
        String.Equals(root, candidate, StringComparison.OrdinalIgnoreCase)
        || candidate.StartsWith(
            (if IO.Path.EndsInDirectorySeparator root then
                 root
             else
                 root + string IO.Path.DirectorySeparatorChar),
            StringComparison.OrdinalIgnoreCase
        )

    let private toolPath sourceRoot runnableRoot (relative: string) =
        let normalized =
            relative
                .Replace('/', IO.Path.DirectorySeparatorChar)
                .Replace('\\', IO.Path.DirectorySeparatorChar)

        let candidate =
            if IO.Path.IsPathFullyQualified normalized then
                IO.Path.GetFullPath normalized
            else
                IO.Path.GetFullPath(IO.Path.Combine(sourceRoot, normalized))

        if not (inside (IO.Path.GetFullPath sourceRoot) candidate) then
            Error "The registered tool path is outside the selected game installation."
        else
            Ok(IO.Path.Combine(runnableRoot, IO.Path.GetRelativePath(sourceRoot, candidate)))

    let private loaderPath expected sourceRoot runnableRoot (loader: ComponentLoader) =
        let candidate = IO.Path.GetFullPath loader.Executable
        let installed = IO.Path.GetFullPath(IO.Path.Combine(sourceRoot, expected))

        if String.Equals(candidate, installed, StringComparison.OrdinalIgnoreCase) then
            Ok(IO.Path.Combine(runnableRoot, expected))
        else
            Error "The installed script extender path is invalid. Check it before Play."

    let private gamePath game (evidence: InstallationEvidence) runnableRoot =
        if game <> GameId.OblivionRemasteredSteam then
            Ok(
                IO.Path.Combine(
                    runnableRoot,
                    IO.Path.GetRelativePath(evidence.RootPath, evidence.Executable.Value.Path)
                )
            )
        else
            let resolve parent expected =
                parent
                |> Result.bind (fun path ->
                    match
                        IO.Directory.EnumerateFileSystemEntries path
                        |> Seq.filter (fun entry ->
                            IO.Path
                                .GetFileName(entry)
                                .Equals(expected, StringComparison.OrdinalIgnoreCase))
                        |> Seq.toList
                    with
                    | [ actual ] -> Ok actual
                    | _ ->
                        Error "The selected game executable is unavailable or has ambiguous names.")

            try
                (Ok runnableRoot, (GameCatalog.launchExecutable game).Split('/'))
                ||> Array.fold resolve
            with
            | :? IO.IOException
            | :? UnauthorizedAccessException -> Error "The selected game executable is unavailable."

    let internal createDeclaredWithHost
        hostWindows
        hostLinux
        (definition: GameDefinition)
        (state: GameContextState)
        runnableRoot
        (loader: ComponentLoader option)
        (configuration: ComponentLaunchConfiguration option)
        =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence

            let app =
                string (
                    binding.Proton
                    |> Option.map _.AppId
                    |> Option.defaultValue definition.SteamAppId
                )

            let arguments = GameCatalog.arguments binding.GameId

            let unreal = GameClient.unreal definition

            let arguments =
                arguments
                @ (unreal
                   |> Option.map (fun client ->
                       ModConductor.Unreal.Launch.arguments
                           definition
                           client
                           runnableRoot
                           (evidence.Platform = ContextPlatform.Windows))
                   |> Option.defaultValue [])

            let environment =
                (if definition.SteamAppId <> 0u then
                     [ "SteamAppId", Some app; "SteamGameId", Some app ]
                 else
                     [ "SteamAppId"
                       "SteamGameId"
                       "STEAM_COMPAT_APP_ID"
                       "STEAM_COMPAT_DATA_PATH"
                       "STEAM_COMPAT_CLIENT_INSTALL_PATH"
                       "STEAM_COMPAT_INSTALL_PATH"
                       "STEAM_COMPAT_LIBRARY_PATHS"
                       "STEAM_COMPAT_TOOL_PATHS"
                       "WINEPREFIX" ]
                     |> List.map (fun name -> name, None))
                @ (configuration |> Option.map _.Environment |> Option.defaultValue [])

            let environment =
                environment
                @ (unreal
                   |> Option.map (fun client ->
                       ModConductor.Unreal.Launch.environment
                           client
                           (configuration |> Option.exists _.LoaderEnabled)
                           evidence.Platform
                           (Environment.GetEnvironmentVariable "WINEDLLOVERRIDES"))
                   |> Option.defaultValue [])

            if (GameClient.mono definition).IsSome then
                match configuration with
                | Some selected when selected.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error
                        "The game changed after its loader selection was read. Refresh the installation before Play."
                | _ ->
                    MonoDescriptor.create
                        hostWindows
                        hostLinux
                        binding
                        runnableRoot
                        (configuration |> Option.exists _.LoaderEnabled)
                        environment

            else
                let selected =
                    match loader with
                    | None -> gamePath binding.GameId evidence runnableRoot
                    | Some loader when loader.GameSha256 <> evidence.Executable.Value.Sha256 ->
                        Error
                            "The game changed after the script extender was installed. Check it before Play."
                    | Some loader ->
                        match
                            GameCatalog.tryRules binding.GameId |> Option.bind _.ExtenderLoader
                        with
                        | Some expected -> loaderPath expected evidence.RootPath runnableRoot loader
                        | None ->
                            Error "This installation does not support the selected script extender."

                let configured =
                    match configuration with
                    | Some value when value.GameSha256 <> evidence.Executable.Value.Sha256 ->
                        Error
                            "The game changed after the graphics component was installed. Check it before Play."
                    | _ -> selected

                match configured, evidence.Platform, evidence.Proton with
                | Error problem, _, _ -> Error problem
                | Ok executable, ContextPlatform.Windows, _ when hostWindows ->
                    Ok(
                        binding.Id,
                        "Windows",
                        { Executable = executable
                          Arguments = arguments
                          WorkingDirectory = runnableRoot
                          Environment = environment }
                    )
                | Ok executable, ContextPlatform.Proton, Some proton when hostLinux ->
                    proton.Launch
                    |> Result.map (fun launch ->
                        binding.Id,
                        proton.RuntimeName,
                        { Executable = launch.Executable
                          Arguments = launch.Arguments @ [ executable ] @ arguments
                          WorkingDirectory = runnableRoot
                          Environment =
                            environment
                            @ [ "STEAM_COMPAT_APP_ID", Some app
                                "STEAM_COMPAT_DATA_PATH", Some proton.Selection.CompatData
                                "STEAM_COMPAT_CLIENT_INSTALL_PATH", Some launch.SteamRoot
                                "STEAM_COMPAT_INSTALL_PATH", Some runnableRoot
                                "STEAM_COMPAT_LIBRARY_PATHS",
                                Some(
                                    String.concat
                                        (string IO.Path.PathSeparator)
                                        (launch.Libraries @ [ evidence.RootPath; runnableRoot ]
                                         |> List.distinct)
                                )
                                "STEAM_COMPAT_TOOL_PATHS", Some proton.Selection.RuntimeDirectory ] })
                | Ok executable, ContextPlatform.Wine, _ when hostLinux && evidence.Wine.IsSome ->
                    let wine = evidence.Wine.Value

                    Ok(
                        binding.Id,
                        "Wine",
                        { Executable = wine.Selection.Executable
                          Arguments = executable :: arguments
                          WorkingDirectory = runnableRoot
                          Environment = environment @ [ "WINEPREFIX", Some wine.Selection.Prefix ] }
                    )
                | Ok _, ContextPlatform.Wine, _ ->
                    Error "Select a checked Wine executable and existing prefix on Linux."
                | Ok _, ContextPlatform.Windows, _ ->
                    Error "This game uses Proton on Linux. Select and refresh its Proton context."
                | Ok _, ContextPlatform.Proton, _ ->
                    Error "Select a checked Proton launch context on Linux."
                | Ok _, ContextPlatform.NativeLinux, _ ->
                    Error "This game does not declare a native Linux workflow."
        | _ -> Error "Select and refresh the installation before playing."

    let createWithHost hostWindows hostLinux state runnableRoot loader configuration =
        match state.Binding with
        | None -> Error "Select and refresh the installation before playing."
        | Some binding ->
            createDeclaredWithHost
                hostWindows
                hostLinux
                (GameCatalog.forGame binding.GameId)
                state
                runnableRoot
                loader
                configuration

    let createWith state runnableRoot loader configuration =
        createWithHost
            (OperatingSystem.IsWindows())
            (OperatingSystem.IsLinux())
            state
            runnableRoot
            loader
            configuration

    let create state runnableRoot loader =
        createWith state runnableRoot loader None

    let projectTool platform (tool: string) (arguments: string list) (launch: NativeLaunch) =
        match platform with
        | ContextPlatform.Windows
        | ContextPlatform.NativeLinux ->
            { launch with
                Executable = tool
                Arguments = arguments }
        | ContextPlatform.Proton
        | ContextPlatform.Wine ->
            { launch with
                Arguments =
                    match List.rev launch.Arguments with
                    | _ :: prefix -> List.rev prefix @ (tool :: arguments)
                    | [] -> tool :: arguments }

    let createToolWithHost
        hostWindows
        hostLinux
        state
        runnableRoot
        loader
        configuration
        generation
        executable
        arguments
        =
        match
            createWithHost hostWindows hostLinux state runnableRoot loader configuration,
            state.Binding
        with
        | Ok(context, runtime, launch), Some binding ->
            match toolPath binding.Evidence.RootPath runnableRoot executable with
            | Error problem -> Error problem
            | Ok tool ->
                let projection =
                    if binding.Evidence.Platform = ContextPlatform.NativeLinux then
                        ModConductor.BepInEx.Bootstrap.linux
                            runnableRoot
                            tool
                            arguments
                            launch.Environment
                            None
                        |> Result.map snd
                    else
                        Ok(projectTool binding.Evidence.Platform tool arguments launch)

                projection
                |> Result.map (fun projected ->
                    { ContextId = context
                      Runtime = runtime
                      GenerationId = generation
                      ToolExecutable = tool
                      Launch = projected })
        | Error problem, _ -> Error problem
        | _, None -> Error "Select and refresh the installation before running FNIS."

    let createToolWith state runnableRoot loader configuration generation executable arguments =
        createToolWithHost
            (OperatingSystem.IsWindows())
            (OperatingSystem.IsLinux())
            state
            runnableRoot
            loader
            configuration
            generation
            executable
            arguments
