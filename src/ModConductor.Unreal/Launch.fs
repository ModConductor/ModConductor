namespace ModConductor.Unreal

open System
open System.IO
open ModConductor.GameContexts

module Launch =
    let arguments (definition: GameDefinition) (client: UnrealClient) root windows =
        let file = Path.Combine(root, client.LogDirectory, "game.log")

        client.Arguments
        @ [ "-ABSLOG=" + (if windows then file else "Z:" + file.Replace('/', '\\')) ]

    let environment client enabled platform existing =
        match client.Loader.Mechanism, enabled, platform with
        | UnrealModMechanism.UE4SS layout, true, ContextPlatform.Proton
        | UnrealModMechanism.UE4SS layout, true, ContextPlatform.Wine ->
            [ "WINEDLLOVERRIDES",
              Some(ModConductor.Platform.WineDllOverrides.withNative existing layout.Proxy) ]
        | _ -> []
