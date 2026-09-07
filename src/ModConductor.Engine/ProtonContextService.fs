namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open ModConductor.GameContexts
open ModConductor.SteamDiscovery
open ModConductor.ProtonContexts
open ModConductor.Protocol.V1

type ProtonContextService() =
    inherit ProtonContextOperations.ProtonContextOperationsBase()
    let slots = new SemaphoreSlim(2, 2)

    override _.SearchProtonContexts(request, context) =
        task {
            let invalidPath (p: string) =
                p.Length > 4096 || not (IO.Path.IsPathFullyQualified p)

            if
                request.DefinitionId <> Skyrim.definition.Id
                || invalidPath request.GamePath
                || request.AdditionalRoots.Count > 16
                || (request.AdditionalRoots |> Seq.exists invalidPath)
            then
                ModLibraryWire.reject
                    "Select a known game and absolute installation and Steam folders."

            if not (slots.Wait 0) then
                raise (
                    RpcException(
                        Status(
                            StatusCode.ResourceExhausted,
                            "A Proton search is already running. Try again shortly."
                        )
                    )
                )

            try
                try
                    let roots =
                        DefaultRoots.read ()
                        @ [ for path in request.AdditionalRoots ->
                                { Path = path
                                  Origin = "Selected Steam folder" } ]

                    let! report =
                        Task.Run(
                            (fun () ->
                                Search.discover request.GamePath roots context.CancellationToken),
                            context.CancellationToken
                        )

                    let result = ProtonSearchResult(Limited = not report.Complete)

                    result.Prefixes.AddRange(
                        report.Prefixes
                        |> Seq.map (fun p ->
                            let item =
                                ProtonPrefixCandidate(
                                    CandidateId = p.Id,
                                    CompatData = p.CompatData,
                                    PrefixPath = p.PrefixPath
                                )

                            item.Origins.AddRange(p.Origins |> Seq.map SteamWire.origin)
                            item)
                    )

                    result.Tools.AddRange(
                        report.Tools
                        |> Seq.map (fun t ->
                            ProtonInstalledTool(
                                ToolId = t.Id,
                                Name = t.Name,
                                Directory = t.Directory,
                                Source = ProtonWire.source t.Source
                            ))
                    )

                    result.Mappings.AddRange(
                        report.Mappings
                        |> Seq.map (fun m ->
                            let item = ProtonToolMapping(Source = ProtonWire.source m.Source)
                            m.PerGame |> Option.iter (fun v -> item.PerGame <- v)
                            m.GlobalDefault |> Option.iter (fun v -> item.GlobalDefault <- v)
                            item)
                    )

                    result.Problems.AddRange(
                        report.Problems
                        |> Seq.map (fun p -> ProtonSearchProblem(Path = p.Path, Detail = p.Detail))
                    )

                    return result
                with :? IO.IOException as e ->
                    return raise (RpcException(Status(StatusCode.FailedPrecondition, e.Message)))
            finally
                slots.Release() |> ignore
        }

    interface IDisposable with
        member _.Dispose() = slots.Dispose()
