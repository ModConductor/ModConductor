namespace ModConductor.Persistence

open System
open ModConductor.GameContexts

module internal GameRootExclusions =
    let private same left right =
        String.Equals(left, right, StringComparison.OrdinalIgnoreCase)

    let private inFolder folder files relative =
        folder
        |> Option.exists (fun folder ->
            files
            |> List.exists (fun file ->
                same relative (if folder = "" then file else folder + "/" + file)))

    let reserved (definition: GameDefinition) prefix name =
        let relative = String.concat "/" (prefix @ [ name ])

        let configuration =
            GameCatalog.tryRules definition.Id
            |> Option.exists (fun rules ->
                inFolder rules.GameSettings definition.IniFiles relative
                || inFolder rules.GamePlugins [ "plugins.txt"; "loadorder.txt" ] relative
                || (rules.GameSaves |> Option.exists (same relative))
                || (prefix.IsEmpty && (rules.CreationFile |> Option.exists (same name))))

        configuration
        || same relative (definition.Data.Replace('\\', '/'))
        || (prefix.IsEmpty
            && name.StartsWith(".modconductor-originals-", StringComparison.OrdinalIgnoreCase))
        || (GameClient.independentExecutable definition
            && same relative (GameClient.executable (OperatingSystem.IsLinux()) definition))
