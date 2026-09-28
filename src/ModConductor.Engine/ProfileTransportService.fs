namespace ModConductor.Engine

open System
open System.IO
open System.Security.Cryptography
open System.Threading
open System.Threading.Tasks
open Grpc.Core
open ModConductor.ArtifactLibrary
open ModConductor.HttpDownloads
open ModConductor.Nexus
open ModConductor.Persistence
open ModConductor.Protocol.V1

type ProfileTransportService
    (
        store: ProfileTransportStore,
        artifacts: IArtifactLibrary,
        downloads: DownloadSession,
        nexus: NexusSession
    ) =
    inherit ProfileTransportOperations.ProfileTransportOperationsBase()

    let exact
        (requirement: ModConductor.Persistence.ProfileSourceRequirement)
        (artifact: Artifact)
        =
        artifact.Sha256 = Some requirement.Sha256
        && artifact.Length = Some requirement.Length
        && (artifact.State = ArtifactState.Ready || artifact.State = ArtifactState.Installed)

    let existing
        workspace
        (requirement: ModConductor.Persistence.ProfileSourceRequirement)
        (token: CancellationToken)
        =
        task {
            let mutable cursor = None
            let mutable found = None
            let mutable more = true

            while more && found.IsNone do
                let! page = artifacts.List(workspace, cursor, false, token)

                match page with
                | Error _ -> more <- false
                | Ok page ->
                    found <- page.Entries |> List.tryFind (exact requirement)
                    cursor <- page.Next
                    more <- cursor.IsSome

            return found
        }

    let manual
        workspace
        (requirement: ModConductor.Persistence.ProfileSourceRequirement)
        (path: string)
        (token: CancellationToken)
        =
        task {
            use file = File.OpenRead path

            if file.Length <> requirement.Length then
                raise (
                    InvalidDataException(
                        "The selected archive for " + requirement.ModName + " has a different size."
                    )
                )

            let sha = SHA256.HashData file |> Convert.ToHexStringLower

            if not (String.Equals(sha, requirement.Sha256, StringComparison.OrdinalIgnoreCase)) then
                raise (
                    InvalidDataException(
                        "The selected archive for "
                        + requirement.ModName
                        + " is not the exact source."
                    )
                )

            let! added =
                artifacts.Add(
                    { Id = Guid.NewGuid()
                      WorkspaceId = workspace
                      Path = path
                      Storage = ArtifactStorage.Copy },
                    token
                )

            match added with
            | Ok value when exact requirement value -> return Some value
            | _ ->
                return
                    raise (
                        InvalidDataException(
                            "The exact archive for " + requirement.ModName + " could not be saved."
                        )
                    )
        }

    let provider
        workspace
        (requirement: ModConductor.Persistence.ProfileSourceRequirement)
        (token: CancellationToken)
        =
        task {
            match
                requirement.ProviderGame,
                requirement.ProviderMod,
                requirement.ProviderFile,
                requirement.ProviderVersion
            with
            | Some game, Some modId, Some fileId, Some version ->
                do! nexus.SavedConnection.WaitAsync token

                match nexus.Status.Account with
                | None -> return None
                | Some account ->
                    let! upstream = nexus.ReadFile(game, modId, fileId).WaitAsync token

                    match upstream with
                    | Ok(file: NexusFile) when
                        file.Version = version
                        && (file.Bytes.IsNone || file.Bytes = Some requirement.Length)
                        ->
                        let source =
                            DownloadSource.Nexus
                                { Account = account.Subject
                                  Game = game
                                  ModId = modId
                                  FileId = fileId
                                  Keyed = false
                                  Version = Some version }

                        let! started =
                            downloads.Start
                                { Id = Guid.NewGuid()
                                  WorkspaceId = workspace
                                  Name = file.Name
                                  Sources = [ source ]
                                  ExpectedLength = Some requirement.Length
                                  ExpectedSha256 = Some requirement.Sha256 }

                        match started with
                        | Error _ -> return None
                        | Ok initial ->
                            let mutable current: Artifact = initial
                            let mutable running = true

                            while running do
                                token.ThrowIfCancellationRequested()

                                if exact requirement current then
                                    running <- false
                                elif
                                    current.Download
                                    |> Option.exists (fun value ->
                                        value.State = DownloadState.Failed
                                        || value.State = DownloadState.Paused)
                                then
                                    running <- false
                                else
                                    do!
                                        downloads.WaitForChange(
                                            workspace,
                                            [ current.Id, current.Revision ],
                                            token
                                        )

                                    let! changed = artifacts.Read(workspace, current.Id)

                                    match changed with
                                    | Ok value -> current <- value
                                    | Error _ -> running <- false

                            return if exact requirement current then Some current else None
                    | _ -> return None
            | _ -> return None
        }

    let resolve
        workspace
        (requirement: ModConductor.Persistence.ProfileSourceRequirement)
        (manualPath: string option)
        (token: CancellationToken)
        =
        task {
            let! found = existing workspace requirement token

            match found with
            | Some value -> return value.Id
            | None ->
                let! supplied =
                    match manualPath with
                    | Some path -> manual workspace requirement path token
                    | None -> provider workspace requirement token

                match supplied with
                | Some value -> return value.Id
                | None ->
                    return
                        raise (
                            InvalidDataException(
                                "The exact archive "
                                + requirement.ArchiveName
                                + " for "
                                + requirement.ModName
                                + " is required. Choose the original file ("
                                + requirement.Sha256
                                + ")."
                            )
                        )
        }

    let reply (value: ModConductor.Persistence.ProfileTransportPreview) =
        let result =
            ProfileTransportPreview(
                Name = value.Name,
                Game = value.Game,
                ModCount = uint32 value.Mods,
                ModFileCount = uint32 value.ModFiles,
                SaveFileCount = uint32 value.SaveFiles,
                SaveBytes = uint64 value.SaveBytes
            )

        for source in value.Sources do
            let item =
                ModConductor.Protocol.V1.ProfileSourceRequirement(
                    ModIndex = uint32 source.ModIndex,
                    ModName = source.ModName,
                    ArchiveName = source.ArchiveName,
                    Sha256 = source.Sha256,
                    Length = uint64 source.Length
                )

            source.ProviderGame |> Option.iter (fun value -> item.ProviderGame <- value)
            source.ProviderMod |> Option.iter (fun value -> item.ProviderMod <- value)
            source.ProviderFile |> Option.iter (fun value -> item.ProviderFile <- value)

            source.ProviderVersion
            |> Option.iter (fun value -> item.ProviderVersion <- value)

            result.Sources.Add item

        result

    override _.InspectProfileTransport(request, _) =
        task {
            let value =
                try
                    store.Inspect request.Path
                with
                | :? InvalidDataException as error ->
                    raise (RpcException(Status(StatusCode.InvalidArgument, error.Message)))
                | :? IOException ->
                    raise (
                        RpcException(
                            Status(
                                StatusCode.InvalidArgument,
                                "The profile file could not be read."
                            )
                        )
                    )

            return reply value
        }

    override _.PreviewExportProfileTransport(request, context) =
        task {
            try
                let workspace = ModLibraryWire.id request.WorkspaceId
                let profile = ModLibraryWire.id request.ProfileId
                let! value = store.PreviewExport(workspace, profile, context.CancellationToken)

                return
                    match value with
                    | Ok value -> reply value
                    | Error problem ->
                        raise (RpcException(Status(StatusCode.FailedPrecondition, problem)))
            with
            | :? InvalidDataException as error ->
                return raise (RpcException(Status(StatusCode.FailedPrecondition, error.Message)))
            | :? IOException ->
                return
                    raise (
                        RpcException(
                            Status(
                                StatusCode.FailedPrecondition,
                                "The profile files could not be read."
                            )
                        )
                    )
        }

    override _.ExportProfileTransport(request, context) =
        task {
            try
                let workspace = ModLibraryWire.id request.WorkspaceId
                let profile = ModLibraryWire.id request.ProfileId

                let! written =
                    store.Export(
                        workspace,
                        profile,
                        request.Destination,
                        request.IncludeSaves,
                        context.CancellationToken
                    )

                return
                    match written with
                    | Ok() -> ProfileTransportResult()
                    | Error problem -> ProfileTransportResult(Problem = problem)
            with
            | :? InvalidDataException as error ->
                return ProfileTransportResult(Problem = error.Message)
            | :? IOException ->
                return
                    ProfileTransportResult(
                        Problem = "The profile could not be saved at that location."
                    )
        }

    override _.ImportProfileTransport(request, context) =
        task {
            try
                let preview = store.Inspect request.Path
                let workspace = ModLibraryWire.id request.WorkspaceId
                let target = ModLibraryWire.id request.GameProfileId

                let supplied =
                    request.ManualSources
                    |> Seq.map (fun value -> int value.ModIndex, value.Path)
                    |> Map.ofSeq

                let mutable sourceMap = Map.empty

                for requirement in preview.Sources do
                    let path = supplied |> Map.tryFind requirement.ModIndex
                    let! artifact = resolve workspace requirement path context.CancellationToken
                    sourceMap <- sourceMap |> Map.add requirement.ModIndex artifact

                let! result =
                    store.Import(
                        request.Path,
                        workspace,
                        Some target,
                        request.ProfileName,
                        sourceMap,
                        context.CancellationToken
                    )

                return
                    match result with
                    | Ok profile -> ProfileTransportResult(ProfileId = profile.ToString("N"))
                    | Error problem -> ProfileTransportResult(Problem = problem)
            with
            | :? InvalidDataException as error ->
                return ProfileTransportResult(Problem = error.Message)
            | :? IOException ->
                return
                    ProfileTransportResult(
                        Problem = "The profile or selected source file could not be read."
                    )
            | :? OperationCanceledException ->
                return ProfileTransportResult(Problem = "Profile import was cancelled.")
        }
