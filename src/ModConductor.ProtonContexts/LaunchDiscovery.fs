namespace ModConductor.ProtonContexts

open System
open System.IO
open System.Threading
open ModConductor.GameContexts
open ModConductor.SteamDiscovery

module internal LaunchDiscovery =
    let private fail detail = raise (IOException detail)

    let private manifest directory =
        let manifest =
            ContextSources.launchManifest directory CancellationToken.None
            |> Result.defaultWith fail

        manifest.Command,
        manifest.RequiredApp,
        ({ Path = manifest.Source.Path
           Identity = manifest.Source.Identity
           Sha256 = manifest.Source.Sha256 }
        : ContextFileEvidence)

    let private host executable arguments =
        if File.Exists "/etc/NIXOS" then
            let paths =
                Environment.GetEnvironmentVariable "PATH"
                |> Option.ofObj
                |> Option.defaultValue ""

            let wrapper =
                paths.Split(Path.PathSeparator)
                |> Array.filter Path.IsPathFullyQualified
                |> Array.map (fun path -> Path.Combine(path, "steam-run"))
                |> Array.tryFind File.Exists
                |> Option.defaultWith (fun () ->
                    fail "The Nix host needs steam-run to start the selected Proton runtime.")

            wrapper, executable :: arguments
        else
            executable, arguments

    let inspect (selection: ProtonSelection) installationDirectory launcher =
        try
            let command, required, toolFile = manifest installationDirectory

            if command <> "/proton %verb%" then
                fail "The selected Proton launch command is not supported."

            let roots =
                match selection.Association with
                | ProtonAssociation.Steam(root, _) ->
                    [ { Path = root
                        Origin = "Selected Steam root" } ]
                | ProtonAssociation.Manual -> DefaultRoots.read ()

            let clientRoots =
                roots
                |> List.choose (fun root ->
                    try
                        if Directory.Exists(Path.Combine(root.Path, "config")) then
                            Some(PrefixFiles.directory root.Path)
                        else
                            None
                    with :? IOException ->
                        None)
                |> List.distinctBy snd

            let steamRoot =
                match clientRoots with
                | [ path, _ ] -> path
                | _ -> fail "Select one Steam installation before launching this Proton context."

            let libraries =
                match selection.Association with
                | ProtonAssociation.Steam(_, library) ->
                    [ fst (PrefixFiles.directory library); steamRoot ]
                | ProtonAssociation.Manual -> [ steamRoot ]

            let executable, arguments, files =
                match required with
                | None -> launcher, [ "waitforexitandrun" ], [ toolFile ]
                | Some required ->
                    let report = Discovery.scan required roots CancellationToken.None

                    let directory =
                        match report.Candidates with
                        | [ candidate ] when report.Complete -> candidate.Directory.CanonicalPath
                        | _ ->
                            fail (
                                "Install the required Steam Linux Runtime (AppID "
                                + string required
                                + ") or select its Steam library, then refresh the installation."
                            )

                    let command, nested, runtimeFile = manifest directory

                    if command <> "/_v2-entry-point --verb=%verb% --" || nested.IsSome then
                        fail "The required Steam runtime launch command is not supported."

                    let entry = Path.Combine(directory, "_v2-entry-point")

                    if not (File.Exists entry) then
                        fail "The required Steam runtime entry point is missing."

                    entry,
                    [ "--verb=waitforexitandrun"; "--"; launcher; "waitforexitandrun" ],
                    [ toolFile; runtimeFile ]

            let executable, arguments = host executable arguments

            Ok
                { Executable = executable
                  Arguments = arguments
                  SteamRoot = steamRoot
                  Libraries = List.distinct libraries },
            files
        with
        | :? IOException as error -> Error error.Message, []
        | :? UnauthorizedAccessException -> Error "The Proton launch files cannot be read.", []
        | :? ArgumentException -> Error "A Proton launch path is invalid.", []
