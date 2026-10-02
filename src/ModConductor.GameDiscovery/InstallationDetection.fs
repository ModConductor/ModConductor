namespace ModConductor.GameDiscovery

open System
open System.IO
open ModConductor.GameCatalogue.Serialization

module InstallationDetection =
    let private files path pattern =
        if
            Directory.Exists path
            && not (File.GetAttributes(path).HasFlag FileAttributes.ReparsePoint)
        then
            Directory.EnumerateFiles(path, pattern, SearchOption.TopDirectoryOnly)
            |> Seq.toList
        else
            []

    let private directories path =
        if Directory.Exists path then
            Directory.EnumerateDirectories(path, "*", SearchOption.TopDirectoryOnly)
            |> Seq.filter (fun path ->
                not (File.GetAttributes(path).HasFlag FileAttributes.ReparsePoint))
            |> Seq.toList
        else
            []

    let private exists root (relative: string) =
        relative <> ""
        && not (Path.IsPathRooted relative)
        && not (relative.Split([| '/'; '\\' |]) |> Array.contains "..")
        && File.Exists(Path.Combine(root, relative))

    let private relative root paths =
        paths
        |> List.map (fun path -> Path.GetRelativePath(root, path).Replace('\\', '/'))

    let private choose root suggested paths =
        if exists root suggested then
            suggested
        else
            match paths with
            | [ one ] -> one
            | _ -> ""

    let private unityBackend root (d: GameDocument) =
        let metadata =
            Path.Combine(root, d.Content, "il2cpp_data", "Metadata", "global-metadata.dat")

        let managed = Path.Combine(root, d.Content, "Managed", "Assembly-CSharp.dll")

        if
            File.Exists metadata
            && (exists root "GameAssembly.dll" || exists root "GameAssembly.so")
        then
            "unity-il2cpp"
        elif File.Exists managed then
            "unity-mono"
        else
            ""

    let private fillUnity (d: GameDocument) backend =
        if backend <> "" then
            d.Mechanism <- backend
            let mono = backend = "unity-mono"

            d.Metadata <-
                if mono then
                    "Managed/Assembly-CSharp.dll"
                else
                    "il2cpp_data/Metadata/global-metadata.dat"

            d.WindowsRuntime <-
                if mono then
                    "MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll"
                else
                    "GameAssembly.dll"

            d.LinuxRuntime <-
                if mono then
                    "MonoBleedingEdge/x86_64/libmonobdwgc-2.0.so"
                else
                    "GameAssembly.so"

    let inspect root (d: GameDocument) =
        try
            let children = directories root

            let data =
                children
                |> List.filter (fun path ->
                    path.EndsWith("_Data", StringComparison.OrdinalIgnoreCase))
                |> relative root

            if d.Content = "" then
                d.Content <-
                    match data with
                    | [ one ] -> one
                    | _ -> ""

            let executables = files root "*.exe" |> relative root
            let unity = d.Content.EndsWith("_Data", StringComparison.OrdinalIgnoreCase)

            let unreal =
                children
                |> List.filter (fun path ->
                    Directory.Exists(Path.Combine(path, "Content"))
                    && Directory.Exists(Path.Combine(path, "Binaries", "Win64")))

            let unrealExecutables =
                unreal
                |> List.collect (fun project ->
                    files (Path.Combine(project, "Binaries", "Win64")) "*.exe")
                |> relative root

            let choices = if unity then executables else unrealExecutables
            d.Executable <- choose root d.Executable choices
            let linux = files root "*.x86_64" |> relative root
            d.LinuxExecutable <- choose root d.LinuxExecutable linux

            if d.Executable = "" && executables.IsEmpty && d.LinuxExecutable <> "" then
                d.Executable <- d.LinuxExecutable

            let backend = if unity then unityBackend root d else ""
            fillUnity d backend

            if not unity && d.Content = "" then
                d.Content <-
                    match unreal with
                    | [ one ] ->
                        Path.GetRelativePath(root, Path.Combine(one, "Content")).Replace('\\', '/')
                    | _ -> ""

            let engine =
                if unity then backend
                elif not unreal.IsEmpty then "unreal"
                else ""

            Ok(d, choices, engine)
        with
        | :? IOException
        | :? UnauthorizedAccessException -> Error "The selected game folder could not be read."
