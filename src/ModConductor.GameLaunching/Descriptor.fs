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

    let private toolPath root (relative: string) =
        let normalized =
            relative.Replace('/', IO.Path.DirectorySeparatorChar).Replace('\\', IO.Path.DirectorySeparatorChar)

        let candidate =
            if IO.Path.IsPathFullyQualified normalized then
                IO.Path.GetFullPath normalized
            else
                IO.Path.GetFullPath(IO.Path.Combine(root, normalized))

        if not (inside (IO.Path.GetFullPath root) candidate) then
            Error "The registered tool path is outside the selected game installation."
        else
            Ok candidate

    let private loaderPath root (loader: ComponentLoader) =
        let candidate = IO.Path.GetFullPath loader.Executable
        let directory = IO.Path.GetDirectoryName candidate

        if
            String.Equals(directory, IO.Path.GetFullPath root, StringComparison.OrdinalIgnoreCase)
            && String.Equals(
                IO.Path.GetFileName candidate,
                "skse64_loader.exe",
                StringComparison.OrdinalIgnoreCase
            )
        then
            Ok candidate
        else
            Error "The installed SKSE loader path is invalid. Check SKSE before Play."

    let createWith
        (state: GameContextState)
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
                | None -> Ok evidence.Executable.Value.Path
                | Some loader when loader.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error "Skyrim changed after SKSE was installed. Check SKSE before Play."
                | Some loader -> loaderPath evidence.RootPath loader

            let configured =
                match configuration with
                | Some value when value.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error "Skyrim changed after ENB was installed. Check ENB before Play."
                | _ -> selected

            match configured, evidence.Platform, evidence.Proton with
            | Error problem, _, _ -> Error problem
            | Ok executable, ContextPlatform.Windows, _ when OperatingSystem.IsWindows() ->
                Ok(
                    binding.Id,
                    "Windows",
                    { Executable = executable
                      Arguments = []
                      WorkingDirectory = evidence.RootPath
                      Environment = environment }
                )
            | Ok executable, ContextPlatform.Proton, Some proton when OperatingSystem.IsLinux() ->
                proton.Launch
                |> Result.map (fun launch ->
                    binding.Id,
                    proton.RuntimeName,
                    { Executable = launch.Executable
                      Arguments = launch.Arguments @ [ executable ]
                      WorkingDirectory = evidence.RootPath
                      Environment =
                        environment
                        @ [ "STEAM_COMPAT_APP_ID", Some app
                            "STEAM_COMPAT_DATA_PATH", Some proton.Selection.CompatData
                            "STEAM_COMPAT_CLIENT_INSTALL_PATH", Some launch.SteamRoot
                            "STEAM_COMPAT_INSTALL_PATH", Some evidence.RootPath
                            "STEAM_COMPAT_LIBRARY_PATHS",
                            Some(String.concat (string IO.Path.PathSeparator) launch.Libraries)
                            "STEAM_COMPAT_TOOL_PATHS", Some proton.Selection.RuntimeDirectory ] })
            | Ok _, ContextPlatform.Windows, _ ->
                Error "This game uses Proton on Linux. Select and refresh its Proton context."
            | Ok _, ContextPlatform.Proton, _ ->
                Error "Select a checked Proton launch context on Linux."
        | _ -> Error "Select and refresh the installation before playing."

    let create state loader = createWith state loader None

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

    let createToolWith state loader configuration generation executable arguments =
        match createWith state loader configuration, state.Binding with
        | Ok(context, runtime, launch), Some binding ->
            match toolPath binding.Evidence.RootPath executable with
            | Error problem -> Error problem
            | Ok tool ->
                let projected = projectTool binding.Evidence.Platform tool arguments launch

                Ok
                    { ContextId = context
                      Runtime = runtime
                      GenerationId = generation
                      Launch = projected }
        | Error problem, _ -> Error problem
        | _, None -> Error "Select and refresh the installation before running FNIS."
