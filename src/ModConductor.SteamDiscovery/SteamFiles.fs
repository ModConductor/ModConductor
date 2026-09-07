namespace ModConductor.SteamDiscovery

open System
open System.Globalization
open System.IO
open System.Security.Cryptography
open System.Threading
open ModConductor.Platform

module internal SteamFiles =
    type ReadFailure =
        | Unreadable of string
        | Malformed of string

    let directory path =
        HostPath.create path
        |> Result.bind (fun host ->
            RootSelection.select host
            |> Result.mapError (fun _ -> "The folder is unavailable.")
            |> Result.map (fun root ->
                { DeclaredPath = path
                  CanonicalPath = RootSelection.path root |> HostPath.value
                  Identity =
                    match (RootSelection.facts root).File with
                    | Known id -> Some id
                    | Unknown _ -> None }))

    let directoryKey (value: ObservedDirectory) =
        match value.Identity with
        | Some id -> "native:" + NativeIdentity.value id
        | None -> "path:" + value.CanonicalPath

    let read (cancellation: CancellationToken) path =
        cancellation.ThrowIfCancellationRequested()

        try
            match directory (Path.GetDirectoryName(path: string)) with
            | Error error -> Error(Unreadable error)
            | Ok parent ->
                match parent.Identity with
                | None -> Error(Unreadable "The Steam folder identity is unavailable.")
                | Some identity ->
                    use held =
                        HeldDirectory.Open(
                            HostPath.create parent.CanonicalPath |> Result.defaultWith invalidOp,
                            identity
                        )

                    let stream, fileId = held.Read(Path.GetFileName path, None)
                    use input = stream
                    let length = input.Length
                    let initialWrite = File.GetLastWriteTimeUtc path

                    if length > 1024L * 1024L then
                        Error(Unreadable "The Steam file exceeds the read limit.")
                    else
                        let bytes = Array.zeroCreate<byte> (int length)
                        let mutable offset = 0

                        while offset < bytes.Length do
                            cancellation.ThrowIfCancellationRequested()
                            let count = input.Read(bytes, offset, min 16384 (bytes.Length - offset))

                            if count = 0 then
                                raise (IOException())

                            offset <- offset + count

                        use currentParent =
                            HeldDirectory.Open(
                                HostPath.create parent.CanonicalPath |> Result.defaultWith invalidOp,
                                identity
                            )

                        let currentStream, _ =
                            currentParent.Read(Path.GetFileName path, Some fileId)

                        use current = currentStream

                        if
                            input.Length <> length
                            || current.Length <> length
                            || File.GetLastWriteTimeUtc path <> initialWrite
                        then
                            Error(Unreadable "The Steam file changed during the search.")
                        else
                            KeyValues.parse bytes
                            |> Result.mapError Malformed
                            |> Result.map (fun values ->
                                values,
                                fileId,
                                Convert.ToHexStringLower(SHA256.HashData bytes),
                                Path.Combine(parent.CanonicalPath, Path.GetFileName path))
        with
        | :? IOException ->
            Error(Unreadable "The Steam file is unavailable or changed during the search.")
        | :? UnauthorizedAccessException -> Error(Unreadable "The Steam file cannot be read.")
        | :? ArgumentException -> Error(Unreadable "The Steam path is invalid.")

    let manifest appId values fileId hash path =
        let result =
            KeyValues.body "AppState" values
            |> Result.mapError (fun e -> DiagnosticKind.ManifestMalformed, e)

        result
        |> Result.bind (fun body ->
            let required key =
                KeyValues.text key body
                |> Result.bind (function
                    | Some v when v.Length > 0 -> Ok v
                    | _ -> Error "A required game manifest field is missing.")

            match
                required "appid",
                required "installdir",
                KeyValues.text "name" body,
                KeyValues.text "buildid" body,
                KeyValues.text "StateFlags" body
            with
            | Ok app, Ok install, Ok name, Ok build, Ok flags ->
                match UInt32.TryParse(app, NumberStyles.None, CultureInfo.InvariantCulture) with
                | true, observed when observed = appId ->
                    let state =
                        match flags with
                        | None -> Ok None
                        | Some value ->
                            match
                                UInt64.TryParse(
                                    value,
                                    NumberStyles.None,
                                    CultureInfo.InvariantCulture
                                )
                            with
                            | true, value -> Ok(Some value)
                            | _ -> Error "The manifest state is invalid."

                    if
                        install.Length > 4096
                        || (name |> Option.exists (fun v -> v.Length > 1024))
                        || (build |> Option.exists (fun v -> v.Length > 64))
                    then
                        Error(
                            DiagnosticKind.ManifestMalformed,
                            "A game manifest field exceeds the read limit."
                        )
                    else
                        state
                        |> Result.mapError (fun e -> DiagnosticKind.ManifestMalformed, e)
                        |> Result.map (fun flags ->
                            { Path = path
                              Identity = fileId
                              Sha256 = hash
                              AppId = observed
                              InstallDirectory = install
                              Name = name
                              BuildId = build
                              StateFlags = flags })
                | true, _ ->
                    Error(
                        DiagnosticKind.AppIdMismatch,
                        "The manifest belongs to another Steam app."
                    )
                | _ -> Error(DiagnosticKind.ManifestMalformed, "The manifest AppID is invalid.")
            | _ ->
                Error(
                    DiagnosticKind.ManifestMalformed,
                    "The game manifest has missing or ambiguous fields."
                ))

    let installationPath common (install: string) =
        let portable = install.Split([| '/'; '\\' |], StringSplitOptions.None)

        if
            String.IsNullOrEmpty install
            || install.Contains('\000')
            || Path.IsPathRooted install
            || install.StartsWith('\\')
            || (install.Length >= 2 && Char.IsAsciiLetter(install[0]) && install[1] = ':')
            || (portable |> Array.exists (fun part -> part = "." || part = ".."))
        then
            Error "The manifest installation folder is absolute or contains traversal."
        else
            let components =
                if OperatingSystem.IsWindows() then
                    portable
                else
                    install.Split('/')

            LogicalPath.create (List.ofArray components)
            |> Result.mapError (fun _ -> "The manifest installation folder is invalid.")
            |> Result.map (fun relative ->
                Path.Combine(Array.ofList (common :: LogicalPath.components relative)))
