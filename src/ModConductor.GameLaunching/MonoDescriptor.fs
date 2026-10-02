namespace ModConductor.GameLaunching

open ModConductor.BepInEx
open ModConductor.GameContexts

module internal MonoDescriptor =
    let create hostWindows hostLinux (binding: GameBinding) root enabled environment =
        let definition = GameCatalog.forGame binding.GameId
        let client = GameClient.mono definition |> Option.get

        let executable =
            System.IO.Path.Combine(
                root,
                System.IO.Path.GetRelativePath(
                    binding.Evidence.RootPath,
                    binding.Evidence.Executable.Value.Path
                )
            )

        match binding.Evidence.Platform with
        | ContextPlatform.NativeLinux when hostLinux ->
            Bootstrap.linux
                root
                executable
                (GameCatalog.arguments binding.GameId)
                environment
                (if enabled then Some client.Loader.LinuxWrapper else None)
            |> Result.map (fun (runtime, launch) -> binding.Id, runtime, launch)
        | ContextPlatform.Windows when hostWindows ->
            Ok(
                binding.Id,
                "Windows",
                { Executable = executable
                  Arguments = GameCatalog.arguments binding.GameId
                  WorkingDirectory = root
                  Environment = environment }
            )
        | _ -> Error "This Unity Mono workflow requires its native client on Linux or Windows."
