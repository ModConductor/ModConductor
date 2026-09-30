namespace ModConductor.GameLaunching

open System
open System.IO
open ModConductor.Executables
open ModConductor.GameContexts

module internal ToolArguments =
    let private contained root path =
        let relative = Path.GetRelativePath(root, path)

        not (
            Path.IsPathFullyQualified relative
            || relative = ".."
            || relative.StartsWith(".." + string Path.DirectorySeparatorChar)
        )

    let private windowsPath prefix path =
        try
            let drives = Path.Combine(prefix, "dosdevices")

            if not (Directory.Exists drives) then
                Error "The selected runtime has no Windows drive mappings."
            else
                let mapping =
                    Directory.EnumerateDirectories(drives)
                    |> Seq.choose (fun drive ->
                        let name = Path.GetFileName drive

                        if
                            name.Length <> 2 || name[1] <> ':' || not (Char.IsAsciiLetter name[0])
                        then
                            None
                        else
                            let info = DirectoryInfo drive
                            let target = info.ResolveLinkTarget(true)
                            let root = if isNull target then info.FullName else target.FullName
                            if contained root path then Some(name, root) else None)
                    |> Seq.sortByDescending (snd >> String.length)
                    |> Seq.tryHead

                match mapping with
                | None -> Error "The selected runtime cannot address the configured profile path."
                | Some(drive, root) ->
                    let relative = Path.GetRelativePath(root, path)

                    Ok(
                        drive.ToUpperInvariant()
                        + "\\"
                        + (if relative = "." then "" else relative.Replace('/', '\\'))
                    )

        with
        | :? IOException -> Error "The selected runtime drive mappings could not be read."
        | :? UnauthorizedAccessException ->
            Error "The selected runtime drive mappings could not be read."

    let substitute runtime (evidence: InstallationEvidence) game output arguments =
        let convert path =
            match runtime with
            | ExecutableRuntime.Native -> Ok path
            | _ ->
                match ContextRuntime.prefix evidence with
                | None -> Error "Select and check the tool runtime for this profile."
                | Some prefix -> windowsPath prefix path

        let resolve (token: string) path =
            if arguments |> List.exists (fun (argument: string) -> argument.Contains token) then
                path
                |> Option.map convert
                |> Option.defaultValue (Error("Configure a path before using " + token + "."))
            else
                Ok ""

        match resolve "{game}" game, resolve "{output}" output with
        | Ok game, Ok output ->
            Ok(
                arguments
                |> List.map (fun argument ->
                    System.Text.RegularExpressions.Regex.Replace(
                        argument,
                        @"\{game\}|\{output\}",
                        System.Text.RegularExpressions.MatchEvaluator(fun token ->
                            if token.Value = "{game}" then game else output)
                    ))
            )
        | Error error, _
        | _, Error error -> Error error
