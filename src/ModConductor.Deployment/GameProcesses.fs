namespace ModConductor.Deployment

open System
open System.IO
open ModConductor.Platform
open ModConductor.GameContexts

module internal GameProcesses =
    let private same (left: string) (right: string) =
        String.Equals(
            Path.TrimEndingDirectorySeparator(Path.GetFullPath left),
            Path.TrimEndingDirectorySeparator(Path.GetFullPath right),
            if OperatingSystem.IsWindows() then
                StringComparison.OrdinalIgnoreCase
            else
                StringComparison.Ordinal
        )

    let private resolve
        (evidence: InstallationEvidence)
        (prefix: string option)
        (argument: string)
        =
        let value = argument.Trim('"')

        if Path.IsPathRooted value then
            Some(Path.GetFullPath value)
        elif value.Length > 3 && value[1] = ':' && (value[2] = '\\' || value[2] = '/') then
            match evidence.Proton, prefix with
            | Some proton, Some prefix when same prefix proton.PrefixPath ->
                let drive =
                    Path.Combine(
                        prefix,
                        "dosdevices",
                        string (Char.ToLowerInvariant value[0]) + ":"
                    )

                let info = DirectoryInfo drive

                let target =
                    if isNull info.LinkTarget then
                        info.FullName
                    else
                        info.ResolveLinkTarget(true).FullName

                let parts =
                    value
                        .Substring(3)
                        .Replace('\\', '/')
                        .Split('/', StringSplitOptions.RemoveEmptyEntries)

                if parts |> Array.exists (fun part -> part = "..") then
                    None
                else
                    Some(Array.fold (fun parent part -> Path.Combine(parent, part)) target parts)
            | _ -> None
        else
            None

    let checkWithRoot (evidence: InstallationEvidence) (runnableRoot: string option) =
        let names =
            [ Skyrim.definition.Executable
              Skyrim.definition.Launcher
              "skse64_loader.exe" ]

        let targets =
            (evidence.Executable |> Option.map _.Path |> Option.toList)
            @ (evidence.LauncherPath |> Option.toList)
            @ (runnableRoot
               |> Option.map (fun root ->
                   [ Skyrim.definition.Executable; Skyrim.definition.Launcher; "skse64_loader.exe" ]
                   |> List.map (fun name -> Path.Combine(root, name)))
               |> Option.defaultValue [])

        for running in GameProcessObservation.read names do
            let paths =
                (running.Executable |> Option.toList)
                @ (running.Arguments |> List.choose (resolve evidence running.Prefix))

            if paths |> List.exists (fun path -> targets |> List.exists (same path)) then
                raise (IOException "Stop the selected game and launcher before deployment.")

            let named =
                names
                |> List.exists (fun name ->
                    running.ProcessName.Equals(name, StringComparison.OrdinalIgnoreCase)
                    || running.ProcessName.Equals(
                        Path.GetFileNameWithoutExtension name,
                        StringComparison.OrdinalIgnoreCase
                    )
                    || running.ProcessName.Equals(
                        name.Substring(0, min 15 name.Length),
                        StringComparison.OrdinalIgnoreCase
                    ))

            let selectedPrefix =
                match evidence.Proton, running.Prefix with
                | Some proton, Some prefix -> same prefix proton.PrefixPath
                | _ -> false

            if named && (running.Incomplete || selectedPrefix || paths.IsEmpty) then
                raise (
                    IOException
                        "A game process could not be excluded from this installation. Stop it before deployment."
                )

    let check evidence = checkWithRoot evidence None

    let validateContext (state: GameContextState) =
        match state.Binding with
        | Some binding when not binding.NeedsCheck && binding.Evidence.Valid ->
            let evidence = binding.Evidence

            if evidence.Platform = ContextPlatform.Proton && evidence.Proton.IsNone then
                raise (IOException "Select a checked Proton context before deployment.")

            evidence
        | _ -> raise (IOException "Select and refresh the game context before deployment.")

    let validate state =
        let evidence = validateContext state
        check evidence
        evidence
