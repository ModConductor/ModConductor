namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Platform

module internal Descriptor =
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

    let create (state: GameContextState) (loader: ComponentLoader option) =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence
            let app = string Skyrim.definition.SteamAppId
            let environment = [ "SteamAppId", Some app; "SteamGameId", Some app ]

            let selected =
                match loader with
                | None -> Ok evidence.Executable.Value.Path
                | Some loader when loader.GameSha256 <> evidence.Executable.Value.Sha256 ->
                    Error "Skyrim changed after SKSE was installed. Check SKSE before Play."
                | Some loader -> loaderPath evidence.RootPath loader

            match selected, evidence.Platform, evidence.Proton with
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
