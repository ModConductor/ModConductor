namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Platform

module internal Descriptor =
    let private inside root candidate =
        String.Equals(root, candidate, StringComparison.OrdinalIgnoreCase)
        || candidate.StartsWith(
            (if IO.Path.EndsInDirectorySeparator root then root else root + string IO.Path.DirectorySeparatorChar),
            StringComparison.OrdinalIgnoreCase
        )

    let private toolPath sourceRoot runnableRoot (relative: string) =
        let normalized =
            relative.Replace('/', IO.Path.DirectorySeparatorChar).Replace('\\', IO.Path.DirectorySeparatorChar)

        let candidate =
            if IO.Path.IsPathFullyQualified normalized then
                IO.Path.GetFullPath normalized
            else
                IO.Path.GetFullPath(IO.Path.Combine(sourceRoot, normalized))

        if not (inside (IO.Path.GetFullPath sourceRoot) candidate) then
            Error "The registered tool path is outside the selected game installation."
        else
            Ok(IO.Path.Combine(runnableRoot, IO.Path.GetRelativePath(sourceRoot, candidate)))

    let private loaderPath sourceRoot runnableRoot (loader: ComponentLoader) =
        let candidate = IO.Path.GetFullPath loader.Executable
        let directory = IO.Path.GetDirectoryName candidate

        if
            String.Equals(directory, IO.Path.GetFullPath sourceRoot, StringComparison.OrdinalIgnoreCase)
            && String.Equals(
                IO.Path.GetFileName candidate,
                "skse64_loader.exe",
                StringComparison.OrdinalIgnoreCase
            )
        then
            Ok(IO.Path.Combine(runnableRoot, "skse64_loader.exe"))
        else
            Error "The installed SKSE loader path is invalid. Check SKSE before Play."

    let private createWithHost
        hostWindows
        hostLinux
        (state: GameContextState)
        runnableRoot
        (loader: ComponentLoader option)
        (configuration: ComponentLaunchConfiguration option)
        =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence
            let app = string Skyrim.definition.SteamAppId

            let environment =
                [ "SteamAppId", Some app; "SteamGameId", Some app ]
                @ (configuration |> Option.map _.Environment |> Option.defaultValue [])

            let selected =
                match loader with
                | None -> Ok(IO.Path.Combine(runnableRoot, IO.Path.GetFileName evidence.Executable.Value.Path))
                | Some loader when loader.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error "Skyrim changed after SKSE was installed. Check SKSE before Play."
                | Some loader -> loaderPath evidence.RootPath runnableRoot loader

            let configured =
                match configuration with
                | Some value when value.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error "Skyrim changed after ENB was installed. Check ENB before Play."
                | _ -> selected

            match configured, evidence.Platform, evidence.Proton with
            | Error problem, _, _ -> Error problem
            | Ok executable, ContextPlatform.Windows, _ when hostWindows ->
                Ok(
                    binding.Id,
                    "Windows",
                    { Executable = executable
                      Arguments = []
                      WorkingDirectory = runnableRoot
                      Environment = environment }
                )
            | Ok executable, ContextPlatform.Proton, Some proton when hostLinux ->
                proton.Launch
                |> Result.map (fun launch ->
                    binding.Id,
                    proton.RuntimeName,
                    { Executable = launch.Executable
                      Arguments = launch.Arguments @ [ executable ]
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
                                    (launch.Libraries @ [ runnableRoot ])
                            )
                            "STEAM_COMPAT_TOOL_PATHS", Some proton.Selection.RuntimeDirectory ] })
            | Ok _, ContextPlatform.Windows, _ ->
                Error "This game uses Proton on Linux. Select and refresh its Proton context."
            | Ok _, ContextPlatform.Proton, _ ->
                Error "Select a checked Proton launch context on Linux."
        | _ -> Error "Select and refresh the installation before playing."

    let createWith state runnableRoot loader configuration =
        createWithHost
            (OperatingSystem.IsWindows())
            (OperatingSystem.IsLinux())
            state
            runnableRoot
            loader
            configuration

    let create state runnableRoot loader = createWith state runnableRoot loader None

    let projectTool platform (tool: string) (arguments: string list) (launch: NativeLaunch) =
        match platform with
        | ContextPlatform.Windows ->
            { launch with
                Executable = tool
                Arguments = arguments }
        | ContextPlatform.Proton ->
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
        match createWithHost hostWindows hostLinux state runnableRoot loader configuration, state.Binding with
        | Ok(context, runtime, launch), Some binding ->
            match toolPath binding.Evidence.RootPath runnableRoot executable with
            | Error problem -> Error problem
            | Ok tool ->
                let projected = projectTool binding.Evidence.Platform tool arguments launch

                Ok
                    { ContextId = context
                      Runtime = runtime
                      GenerationId = generation
                      ToolExecutable = tool
                      Launch = projected }
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
