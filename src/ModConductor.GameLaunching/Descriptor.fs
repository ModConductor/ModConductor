namespace ModConductor.GameLaunching

open System
open ModConductor.GameContexts
open ModConductor.Platform

module internal Descriptor =
    let create (state: GameContextState) =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence
            let executable = evidence.Executable.Value.Path
            let app = string Skyrim.definition.SteamAppId
            let environment = [ "SteamAppId", Some app; "SteamGameId", Some app ]

            match evidence.Platform, evidence.Proton with
            | ContextPlatform.Windows, _ when OperatingSystem.IsWindows() ->
                Ok(
                    binding.Id,
                    "Windows",
                    { Executable = executable
                      Arguments = []
                      WorkingDirectory = evidence.RootPath
                      Environment = environment }
                )
            | ContextPlatform.Proton, Some proton when OperatingSystem.IsLinux() ->
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
            | ContextPlatform.Windows, _ ->
                Error "This game uses Proton on Linux. Select and refresh its Proton context."
            | ContextPlatform.Proton, _ -> Error "Select a checked Proton launch context on Linux."
        | _ -> Error "Select and refresh the installation before playing."
