namespace ModConductor.Engine

open System
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open ModConductor.GameContexts
open ModConductor.SteamDiscovery
open ModConductor.Protocol.V1

module internal SteamWire =
    let root (r: SearchRoot) =
        SteamSearchRoot(Path = r.Path, Origin = r.Origin)

    let directory (d: ObservedDirectory) =
        let result =
            SteamDirectory(DeclaredPath = d.DeclaredPath, CanonicalPath = d.CanonicalPath)

        d.Identity
        |> Option.iter (fun id -> result.NativeIdentity <- NativeIdentity.value id)

        result

    let origin (o: InstallationOrigin) =
        let m = o.Manifest

        let manifest =
            SteamManifestEvidence(
                Path = m.Path,
                NativeIdentity = NativeIdentity.value m.Identity,
                Sha256 = m.Sha256,
                AppId = m.AppId,
                InstallDirectory = m.InstallDirectory
            )

        m.Name |> Option.iter (fun value -> manifest.Name <- value)
        m.BuildId |> Option.iter (fun value -> manifest.BuildId <- value)
        m.StateFlags |> Option.iter (fun value -> manifest.StateFlags <- value)

        let result =
            SteamInstallationOrigin(
                Root = root o.Root,
                SteamRoot = directory o.SteamRoot,
                Library = directory o.Library,
                Manifest = manifest
            )

        o.LibraryEntry |> Option.iter (fun value -> result.LibraryEntry <- value)
        result

    let problem =
        function
        | DiagnosticKind.RootUnavailable -> SteamDiscoveryProblem.RootUnavailable
        | DiagnosticKind.LibrariesUnreadable -> SteamDiscoveryProblem.LibrariesUnreadable
        | DiagnosticKind.LibrariesMalformed -> SteamDiscoveryProblem.LibrariesMalformed
        | DiagnosticKind.LibraryPathInvalid -> SteamDiscoveryProblem.LibraryPathInvalid
        | DiagnosticKind.ManifestUnreadable -> SteamDiscoveryProblem.ManifestUnreadable
        | DiagnosticKind.ManifestMalformed -> SteamDiscoveryProblem.ManifestMalformed
        | DiagnosticKind.StaleEntry -> SteamDiscoveryProblem.StaleEntry
        | DiagnosticKind.AppIdMismatch -> SteamDiscoveryProblem.AppIdMismatch
        | DiagnosticKind.UnsafeInstallDirectory -> SteamDiscoveryProblem.UnsafeInstallDirectory
        | DiagnosticKind.InstallationUnavailable -> SteamDiscoveryProblem.InstallationUnavailable
        | DiagnosticKind.LimitReached -> SteamDiscoveryProblem.LimitReached

    let report (r: DiscoveryReport) =
        let result = SteamSearchResult(AppId = r.AppId, Limited = not r.Complete)
        result.Roots.AddRange(r.Roots |> Seq.map root)

        result.Candidates.AddRange(
            r.Candidates
            |> Seq.map (fun c ->
                let candidate =
                    SteamInstallationCandidate(
                        CandidateId = c.Id,
                        Directory = directory c.Directory
                    )

                candidate.Origins.AddRange(c.Origins |> Seq.map origin)
                candidate)
        )

        result.Diagnostics.AddRange(
            r.Diagnostics
            |> Seq.map (fun d ->
                SteamSearchDiagnostic(
                    RootPath = d.RootPath,
                    Path = d.Path,
                    Kind = problem d.Kind,
                    Detail = d.Detail
                ))
        )

        result

type SteamDiscoveryService() =
    inherit SteamDiscoveryOperations.SteamDiscoveryOperationsBase()
    let slots = new SemaphoreSlim(2, 2)

    override _.SearchInstallations(request, context) =
        task {
            if
                request.DefinitionId <> GameId.value Skyrim.definition.Id
                || request.AdditionalRoots.Count > 16
                || (request.AdditionalRoots
                    |> Seq.exists (fun path ->
                        path.Length > 4096 || not (IO.Path.IsPathFullyQualified path)))
            then
                raise (
                    RpcException(
                        Status(
                            StatusCode.InvalidArgument,
                            "Select a known game and absolute Steam folders."
                        )
                    )
                )

            if not (slots.Wait 0) then
                raise (
                    RpcException(
                        Status(
                            StatusCode.ResourceExhausted,
                            "A Steam search is already running. Try again shortly."
                        )
                    )
                )

            try
                let roots =
                    DefaultRoots.read ()
                    @ (request.AdditionalRoots
                       |> Seq.map (fun path ->
                           { Path = path
                             Origin = "Selected Steam folder" })
                       |> Seq.toList)

                let! result =
                    Task.Run(
                        (fun () ->
                            Discovery.scan
                                Skyrim.definition.SteamAppId
                                roots
                                context.CancellationToken),
                        context.CancellationToken
                    )

                return SteamWire.report result
            finally
                slots.Release() |> ignore
        }

    interface IDisposable with
        member _.Dispose() = slots.Dispose()
