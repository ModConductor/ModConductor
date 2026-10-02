namespace ModConductor.BepInEx

open System
open System.IO
open ModConductor.Platform
open ModConductor.SteamDiscovery

/// Doorstop is loaded by the selected wrapper inside the runtime child, never by a host helper.
module Bootstrap =
    let environment unity enabled platform existing =
        match unity, enabled, platform with
        | true, true, ModConductor.GameContexts.ContextPlatform.Proton
        | true, true, ModConductor.GameContexts.ContextPlatform.Wine ->
            [ "WINEDLLOVERRIDES", Some(WineDllOverrides.withNative existing "winhttp.dll") ]
        | _ -> []

    let private steamRuntime () =
        DefaultRoots.read ()
        |> List.map (fun root -> Path.Combine(root.Path, "ubuntu12_32", "steam-runtime", "run.sh"))
        |> List.tryFind File.Exists

    let private linuxHost executable arguments =
        if not (File.Exists "/etc/NIXOS") then
            Ok(executable, arguments, "Native Linux")
        elif File.Exists "/run/current-system/sw/bin/steam-run" then
            Ok(
                "/run/current-system/sw/bin/steam-run",
                executable :: arguments,
                "Native Linux (steam-run)"
            )
        else
            steamRuntime ()
            |> Option.map (fun runtime ->
                Ok(runtime, executable :: arguments, "Native Linux (Steam runtime)"))
            |> Option.defaultValue (
                Error
                    "The NixOS host has no usable Steam runtime helper. Install the Steam runtime through your host configuration."
            )

    let linux root executable arguments environment wrapper =
        let command, arguments =
            match wrapper with
            | Some relative -> "/bin/sh", Path.Combine(root, relative) :: executable :: arguments
            | None -> executable, arguments

        linuxHost command arguments
        |> Result.map (fun (command, arguments, runtime) ->
            runtime,
            { Executable = command
              Arguments = arguments
              WorkingDirectory = root
              Environment = environment }
            : string * NativeLaunch)
