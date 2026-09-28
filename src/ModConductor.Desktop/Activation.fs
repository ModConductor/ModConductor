namespace ModConductor.Desktop

open System
open System.IO
open ModConductor.Platform

type Activation =
    | Show
    | WorkspacePath of HostPath
    | ArchivePath of HostPath
    | ProfilePath of HostPath
    | Workspace of Guid
    | Archives of Guid

module Activation =
    let private path make value =
        HostPath.create value |> Result.map make

    let parse (arguments: string array) =
        let invalid = Error "This request is not supported."

        if
            arguments.Length > 8
            || arguments
               |> Array.exists (fun s ->
                   isNull s || s.Length > 4096 || s |> Seq.exists Char.IsControl)
        then
            invalid
        else
            match arguments with
            | [||] -> Ok Show
            | [| "--workspace"; value |] -> path WorkspacePath value
            | [| "--archive"; value |] -> path ArchivePath value
            | [| "--profile"; value |] -> path ProfilePath value
            | [| value |] when value.StartsWith("file:", StringComparison.OrdinalIgnoreCase) ->
                match Uri.TryCreate(value, UriKind.Absolute) with
                | true, uri when uri.IsFile && uri.Query = "" && uri.Fragment = "" ->
                    path ProfilePath uri.LocalPath
                | _ -> invalid
            | [| "--uri"; value |] ->
                match Uri.TryCreate(value, UriKind.Absolute) with
                | true, uri when
                    uri.Scheme = "modconductor"
                    && uri.UserInfo = ""
                    && uri.Query = ""
                    && uri.Fragment = ""
                    && uri.IsDefaultPort
                    ->
                    let text = uri.AbsolutePath.TrimStart('/')

                    match Guid.TryParseExact(text, "N") with
                    | true, id when value = "modconductor://" + uri.Host + "/" + text ->
                        match uri.Host with
                        | "workspace" -> Ok(Workspace id)
                        | "archives" -> Ok(Archives id)
                        | _ -> invalid
                    | _ -> invalid
                | _ -> invalid
            | _ -> invalid

    let directory path =
        RootSelection.select path
        |> Result.map (RootSelection.path >> HostPath.value)
        |> Result.mapError (fun _ -> "The workspace folder is unavailable.")

    let archive path =
        let text = HostPath.value path

        let parent =
            Path.GetDirectoryName text
            |> HostPath.create
            |> Result.bind (fun p ->
                RootSelection.select p
                |> Result.mapError (fun _ -> "The archive folder is unavailable."))

        match parent with
        | Error detail -> Error detail
        | Ok root ->
            match (RootSelection.facts root).File with
            | Unknown _ -> Error "The archive folder could not be checked."
            | Known identity ->
                try
                    use directory = HeldDirectory.Open(RootSelection.path root, identity)
                    let file, _ = directory.Read(Path.GetFileName text, None)
                    use file = file

                    Ok(
                        Path.Combine(
                            HostPath.value (RootSelection.path root),
                            Path.GetFileName text
                        ),
                        file.Length
                    )
                with
                | :? IOException ->
                    Error
                        "The archive file is unavailable. Choose the archive again from its current folder."
                | :? UnauthorizedAccessException ->
                    Error "The archive file cannot be read. Check access to the file."

    let profile path =
        if
            not (
                String.Equals(
                    Path.GetExtension(HostPath.value path),
                    ".mcprof",
                    StringComparison.OrdinalIgnoreCase
                )
            )
        then
            Error "Choose a .mcprof profile file."
        else
            archive path
            |> Result.mapError (fun _ -> "The profile file is unavailable. Choose it again.")
