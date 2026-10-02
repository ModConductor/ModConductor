namespace ModConductor.SteamDiscovery

open System
open System.IO
open System.Threading

module InstalledGames =
    let private libraries root token =
        let index = Path.Combine(root, "steamapps", "libraryfolders.vdf")

        if not (File.Exists index) then
            [ root ]
        else
            match SteamFiles.read token index with
            | Error _ -> [ root ]
            | Ok(values, _, _, _) ->
                match KeyValues.body "libraryfolders" values with
                | Error _ -> [ root ]
                | Ok entries ->
                    root
                    :: (entries
                        |> List.choose (fun (_, value) ->
                            match value with
                            | KeyValues.Text path when Path.IsPathFullyQualified path -> Some path
                            | KeyValues.Object fields ->
                                KeyValues.text "path" fields
                                |> Result.toOption
                                |> Option.flatten
                                |> Option.filter Path.IsPathFullyQualified
                            | KeyValues.Text _ -> None))

    let private appId (path: string) =
        let name = Path.GetFileNameWithoutExtension path

        match UInt32.TryParse(name.Substring("appmanifest_".Length)) with
        | true, id when id <> 0u -> Some id
        | _ -> None

    let scan (roots: SearchRoot list) (token: CancellationToken) =
        let manifests = ResizeArray<uint32>()
        let diagnostics = ResizeArray<DiscoveryDiagnostic>()

        for root in roots do
            token.ThrowIfCancellationRequested()

            try
                for library in libraries root.Path token do
                    let steamapps = Path.Combine(library, "steamapps")

                    if Directory.Exists steamapps then
                        Directory.EnumerateFiles(
                            steamapps,
                            "appmanifest_*.acf",
                            SearchOption.TopDirectoryOnly
                        )
                        |> Seq.choose appId
                        |> Seq.iter manifests.Add
            with
            | :? IOException
            | :? UnauthorizedAccessException ->
                diagnostics.Add
                    { RootPath = root.Path
                      Path = root.Path
                      Kind = DiagnosticKind.RootUnavailable
                      Detail = "The Steam library could not be read." }

        let reports =
            manifests
            |> Seq.distinct
            |> Seq.map (fun id -> Discovery.scan id roots token)
            |> Seq.toList

        { AppId = 0u
          Roots = roots
          Candidates = reports |> List.collect _.Candidates |> List.distinctBy _.Id
          Diagnostics =
            List.ofSeq diagnostics @ (reports |> List.collect _.Diagnostics)
            |> List.distinct
          Complete = diagnostics.Count = 0 && reports |> List.forall _.Complete }
