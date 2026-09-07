namespace ModConductor.SteamDiscovery

open System
open System.IO
open System.Globalization
open System.Threading
open ModConductor.Platform

type SteamSourceFile =
    { Path: string
      Identity: FileIdentity
      Sha256: string }

type SteamToolMapping =
    { PerGame: string option
      GlobalDefault: string option
      Source: SteamSourceFile }

type InstalledCompatibilityTool =
    { Id: string
      Name: string
      Directory: string
      InstallationDirectory: string
      Source: SteamSourceFile }

module ContextSources =
    let private read token path =
        SteamFiles.read token path
        |> Result.mapError (function
            | SteamFiles.Unreadable e
            | SteamFiles.Malformed e -> e)

    let gameManifest (appId: uint32) library token =
        let path =
            Path.Combine(
                library,
                "steamapps",
                "appmanifest_" + appId.ToString(CultureInfo.InvariantCulture) + ".acf"
            )

        read token path
        |> Result.bind (fun (values, identity, hash, canonical) ->
            SteamFiles.manifest appId values identity hash canonical |> Result.mapError snd)

    let mappings (appId: uint32) steamRoot token =
        read token (Path.Combine(steamRoot, "config", "config.vdf"))
        |> Result.bind (fun (values, identity, hash, path) ->
            let body =
                [ "InstallConfigStore"; "Software"; "Valve"; "Steam"; "CompatToolMapping" ]
                |> List.fold
                    (fun state key -> state |> Result.bind (KeyValues.body key))
                    (Ok values)

            body
            |> Result.bind (fun mappings ->
                let name key =
                    match KeyValues.field key mappings with
                    | Ok None -> Ok None
                    | Ok(Some(KeyValues.Object fields)) -> KeyValues.text "name" fields
                    | _ -> Error "The Steam compatibility-tool mapping is ambiguous."

                match name (appId.ToString(CultureInfo.InvariantCulture)), name "0" with
                | Ok perGame, Ok globalDefault ->
                    if
                        [ perGame; globalDefault ]
                        |> List.exists (Option.exists (fun v -> v.Length > 1024))
                    then
                        Error "The Steam compatibility-tool name exceeds the read limit."
                    else
                        Ok
                            { PerGame = perGame
                              GlobalDefault = globalDefault
                              Source =
                                { Path = path
                                  Identity = identity
                                  Sha256 = hash } }
                | Error e, _
                | _, Error e -> Error e))

    let tools directory token =
        read token (Path.Combine(directory, "compatibilitytool.vdf"))
        |> Result.bind (fun (values, identity, hash, path) ->
            KeyValues.body "compatibilitytools" values
            |> Result.bind (KeyValues.body "compat_tools")
            |> Result.bind (fun entries ->
                if entries.Length > 32 then
                    Error "The tool manifest contains too many tools."
                else
                    let parsed =
                        entries
                        |> List.map (fun (id, value) ->
                            match value with
                            | KeyValues.Text _ ->
                                Error "The compatibility-tool entry is invalid."
                            | KeyValues.Object fields ->
                                match
                                    KeyValues.text "display_name" fields,
                                    KeyValues.text "install_path" fields,
                                    KeyValues.text "from_oslist" fields,
                                    KeyValues.text "to_oslist" fields
                                with
                                | Ok name, Ok(Some install), Ok(Some "windows"), Ok(Some "linux") when
                                    id.Length <= 1024
                                    && (name |> Option.forall (fun n -> n.Length <= 1024))
                                    ->
                                    let destination =
                                        if install = "." then
                                            Ok directory
                                        else
                                            SteamFiles.installationPath directory install

                                    destination
                                    |> Result.bind SteamFiles.directory
                                    |> Result.map (fun target ->
                                        { Id = id
                                          Name = defaultArg name id
                                          Directory = directory
                                          InstallationDirectory = target.CanonicalPath
                                          Source =
                                            { Path = path
                                              Identity = identity
                                              Sha256 = hash } })
                                | _ ->
                                    Error
                                        "The tool does not declare a Windows-to-Linux installation.")

                    match
                        parsed
                        |> List.tryPick (function
                            | Error e -> Some e
                            | Ok _ -> None)
                    with
                    | Some e -> Error e
                    | None ->
                        Ok(
                            parsed
                            |> List.choose (function
                                | Ok v -> Some v
                                | Error _ -> None)
                        )))

    let installedTools steamRoot (token: CancellationToken) =
        let scan parent =
            if Directory.Exists parent then
                let directories =
                    Directory.EnumerateDirectories(parent) |> Seq.truncate 129 |> Seq.toList

                if directories.Length > 128 then
                    Error "The installed-tool search reached its limit."
                else
                    directories
                    |> List.sort
                    |> List.collect (fun directory ->
                        token.ThrowIfCancellationRequested()

                        if File.Exists(Path.Combine(directory, "compatibilitytool.vdf")) then
                            match tools directory token with
                            | Ok values -> values
                            | Error _ -> []
                        else
                            [])
                    |> Ok
            else
                Ok []

        try
            match
                scan (Path.Combine(steamRoot, "compatibilitytools.d")),
                scan (Path.Combine(steamRoot, "steamapps", "common"))
            with
            | Ok a, Ok b -> Ok(a @ b |> List.distinct)
            | Error e, _
            | _, Error e -> Error e
        with
        | :? IOException
        | :? UnauthorizedAccessException -> Error "The installed Proton folders cannot be read."
