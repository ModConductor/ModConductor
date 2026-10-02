namespace ModConductor.GameLaunching

open ModConductor.BepInEx
open ModConductor.GameContexts

module internal UnityDescriptor =
    let create
        hostWindows
        hostLinux
        (definition: GameDefinition)
        (binding: GameBinding)
        root
        enabled
        environment
        =
        let client =
            GameClient.unity (binding.Evidence.Platform = ContextPlatform.NativeLinux) definition
            |> Option.get

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
                (if enabled then Some client.LinuxWrapper else None)
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
        | _ -> Error "Select the declared native Unity client for this operating system."
