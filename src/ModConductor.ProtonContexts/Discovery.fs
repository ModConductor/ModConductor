namespace ModConductor.ProtonContexts

open System
open System.IO
open System.Globalization
open System.Threading
open System.Text
open ModConductor.GameContexts
open ModConductor.SteamDiscovery

type PrefixCandidate =
    { Id: string
      CompatData: string
      PrefixPath: string
      Origins: InstallationOrigin list }

type ProtonSearch =
    { Prefixes: PrefixCandidate list
      Tools: InstalledCompatibilityTool list
      Mappings: SteamToolMapping list
      Problems: ValidationProblem list
      Complete: bool }

module Search =
    let discover gamePath roots (token: CancellationToken) =
        if not (OperatingSystem.IsLinux()) then
            { Prefixes = []
              Tools = []
              Mappings = []
              Problems =
                [ { Path = gamePath
                    Detail = "Proton contexts are supported only on Linux." } ]
              Complete = true }
        else
            let problems = ResizeArray<ValidationProblem>()
            let gameId = PrefixFiles.directory gamePath |> snd
            let report = Discovery.scan Skyrim.definition.SteamAppId roots token

            for d in report.Diagnostics do
                problems.Add { Path = d.Path; Detail = d.Detail }

            let origins =
                report.Candidates
                |> List.filter (fun c -> c.Directory.Identity = Some gameId)
                |> List.collect _.Origins

            let prefixes =
                origins
                |> List.choose (fun origin ->
                    token.ThrowIfCancellationRequested()

                    let compatdata =
                        Path.Combine(
                            origin.Library.CanonicalPath,
                            "steamapps",
                            "compatdata",
                            Skyrim.definition.SteamAppId.ToString(CultureInfo.InvariantCulture)
                        )

                    try
                        let prefix, identity =
                            PrefixFiles.directory (Path.Combine(compatdata, "pfx"))

                        Some
                            { Id = NativeIdentity.value identity
                              CompatData = compatdata
                              PrefixPath = prefix
                              Origins = [ origin ] }
                    with :? IOException as e ->
                        problems.Add
                            { Path = compatdata
                              Detail = e.Message }

                        None)
                |> List.groupBy _.Id
                |> List.map (fun (_, entries) ->
                    { entries.Head with
                        Origins = entries |> List.collect _.Origins |> List.distinct })
                |> List.sortBy _.Id

            let steamRoots =
                origins |> List.map _.SteamRoot.CanonicalPath |> List.distinct |> List.sort

            let tools = ResizeArray<InstalledCompatibilityTool>()
            let mappings = ResizeArray<SteamToolMapping>()

            for root in steamRoots do
                token.ThrowIfCancellationRequested()

                match ContextSources.mappings Skyrim.definition.SteamAppId root token with
                | Ok m -> mappings.Add m
                | Error e -> problems.Add { Path = root; Detail = e }

            let toolRoots =
                steamRoots @ (origins |> List.map _.Library.CanonicalPath)
                |> List.distinct
                |> List.sort

            for root in toolRoots do
                match ContextSources.installedTools root token with
                | Ok values -> tools.AddRange values
                | Error e -> problems.Add { Path = root; Detail = e }

            let mutable remaining = 240000
            let mutable complete = report.Complete

            let text values =
                values |> List.sumBy (fun (s: string) -> Encoding.UTF8.GetByteCount s + 32)

            let retain size items =
                items
                |> List.filter (fun item ->
                    let cost = size item

                    if cost > remaining then
                        complete <- false
                        false
                    else
                        remaining <- remaining - cost
                        true)

            let prefixes =
                prefixes
                |> retain (fun p ->
                    text [ p.Id; p.CompatData; p.PrefixPath ]
                    + (p.Origins
                       |> List.sumBy (fun o ->
                           text
                               [ o.Root.Path
                                 o.Root.Origin
                                 o.SteamRoot.DeclaredPath
                                 o.SteamRoot.CanonicalPath
                                 o.Library.DeclaredPath
                                 o.Library.CanonicalPath
                                 defaultArg o.LibraryEntry ""
                                 o.Manifest.Path
                                 o.Manifest.InstallDirectory
                                 defaultArg o.Manifest.Name ""
                                 defaultArg o.Manifest.BuildId "" ]
                           + 512)))

            let tools =
                tools
                |> Seq.distinct
                |> Seq.sortBy (fun t -> t.Id, t.Directory)
                |> Seq.toList
                |> retain (fun t ->
                    text [ t.Id; t.Name; t.Directory; t.Source.Path; t.Source.Sha256 ] + 128)

            let mappings =
                mappings
                |> Seq.toList
                |> retain (fun m ->
                    text
                        [ defaultArg m.PerGame ""
                          defaultArg m.GlobalDefault ""
                          m.Source.Path
                          m.Source.Sha256 ]
                    + 128)

            let issues = problems |> Seq.toList |> retain (fun p -> text [ p.Path; p.Detail ])

            { Prefixes = prefixes
              Tools = tools
              Mappings = mappings
              Problems =
                issues
                @ (if complete then
                       []
                   else
                       [ { Path = gamePath
                           Detail =
                             "The Proton search reached its limit. Select an existing folder directly." } ])
              Complete = complete }
