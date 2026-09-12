namespace ModConductor.Engine

open Grpc.Core
open ModConductor.ArtifactLibrary
open ModConductor.Protocol.V1

module private ArtifactWire =
    let result value =
        value
        |> Result.defaultWith (fun problem ->
            let code, message =
                match problem with
                | ArtifactError.NotFound ->
                    StatusCode.NotFound, "The archive is not in this workspace."
                | ArtifactError.Stale ->
                    StatusCode.Aborted, "The archive changed. Refresh the list."
                | ArtifactError.Busy ->
                    StatusCode.ResourceExhausted, "An archive operation is in progress."
                | ArtifactError.Conflict ->
                    StatusCode.FailedPrecondition,
                    "The archive operation does not match the saved state."
                | ArtifactError.InvalidLink ->
                    StatusCode.InvalidArgument,
                    "Choose an installed mod and saved version from this workspace."
                | ArtifactError.Linked ->
                    StatusCode.FailedPrecondition,
                    "The archive stays in this list while it has mod links."
                | ArtifactError.Unavailable ->
                    StatusCode.FailedPrecondition,
                    "The archive file is unavailable. Refresh the list for details."
                | ArtifactError.Cancelled ->
                    StatusCode.Cancelled, "The archive operation stopped. Refresh the list."

            raise (RpcException(Status(code, message))))

    let reference (value: ArtifactReference) : ArtifactRef =
        if isNull value then
            ModLibraryWire.reject "Select an archive."

        { WorkspaceId = ModLibraryWire.id value.WorkspaceId
          Id = ModLibraryWire.id value.Id
          Revision = ModLibraryWire.number value.Revision }

    let artifact (value: Artifact) =
        let wire =
            ArchiveArtifact(
                Id = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                Revision = uint64 value.Revision,
                OriginalName = value.OriginalName,
                OriginalPath = value.OriginalPath,
                Path = value.Path,
                CanRetry = value.CanRetry,
                CanLocate = value.CanLocate,
                CanDeleteCopy = value.CanDeleteCopy,
                CanRemove = value.CanRemove,
                Storage =
                    (match value.Storage with
                     | ArtifactStorage.Reference -> ArchiveStorage.Reference
                     | ArtifactStorage.Copy -> ArchiveStorage.Copy),
                State =
                    (match value.State with
                     | ArtifactState.Incomplete -> ArchiveState.Incomplete
                     | ArtifactState.Ready -> ArchiveState.Ready
                     | ArtifactState.Detached -> ArchiveState.Detached
                     | ArtifactState.Installed -> ArchiveState.Installed)
            )

        value.Length |> Option.iter (fun n -> wire.Length <- uint64 n)
        value.Sha256 |> Option.iter (fun text -> wire.Sha256 <- text)
        value.Problem |> Option.iter (fun text -> wire.Problem <- text)

        for link in value.Links do
            wire.Links.Add(
                ArtifactProvenance(
                    ModId = link.ModId.ToString("N"),
                    VersionId = link.VersionId.ToString("N"),
                    ModName = link.ModName,
                    VersionLabel = link.VersionLabel
                )
            )

        wire

    let reply pending =
        task {
            let! value = pending
            return value |> result |> artifact
        }

type ArtifactService(library: IArtifactLibrary) =
    inherit ArtifactLibrary.ArtifactLibraryBase()

    override _.ListArtifacts(request, context) =
        task {
            let! result =
                library.List(
                    ModLibraryWire.id request.WorkspaceId,
                    (if request.HasAfter then
                         Some(ModLibraryWire.id request.After)
                     else
                         None),
                    request.Refresh,
                    context.CancellationToken
                )

            let page = ArtifactWire.result result
            let reply = ModConductor.Protocol.V1.ArtifactPage()
            reply.Entries.AddRange(page.Entries |> List.map ArtifactWire.artifact)
            page.Next |> Option.iter (fun id -> reply.Next <- id.ToString("N"))
            return reply
        }

    override _.ListArtifactLinkOptions(request, _) =
        task {
            let! result =
                library.LinkOptions(
                    ModLibraryWire.id request.WorkspaceId,
                    (if request.HasAfter then
                         Some(ModLibraryWire.id request.After)
                     else
                         None)
                )

            let page = ArtifactWire.result result
            let reply = ModConductor.Protocol.V1.ArtifactLinkPage()

            for link in page.Entries do
                reply.Entries.Add(
                    ArtifactProvenance(
                        ModId = link.ModId.ToString("N"),
                        VersionId = link.VersionId.ToString("N"),
                        ModName = link.ModName,
                        VersionLabel = link.VersionLabel
                    )
                )

            page.Next |> Option.iter (fun id -> reply.Next <- id.ToString("N"))
            return reply
        }

    override _.ReadArtifact(request, _) =
        library.Read(ModLibraryWire.id request.WorkspaceId, ModLibraryWire.id request.Id)
        |> ArtifactWire.reply

    override _.AddArtifact(request, context) =
        let storage =
            match request.Storage with
            | ArchiveStorage.Reference -> ArtifactStorage.Reference
            | ArchiveStorage.Copy -> ArtifactStorage.Copy
            | _ -> ModLibraryWire.reject "Choose where to keep the archive."

        library.Add(
            { Id = ModLibraryWire.id request.Id
              WorkspaceId = ModLibraryWire.id request.WorkspaceId
              Path = request.Path
              Storage = storage },
            context.CancellationToken
        )
        |> ArtifactWire.reply

    override _.RetryArtifact(request, context) =
        library.Retry(ArtifactWire.reference request, context.CancellationToken)
        |> ArtifactWire.reply

    override _.LocateArtifact(request, context) =
        library.Locate(
            ArtifactWire.reference request.Expected,
            request.Path,
            context.CancellationToken
        )
        |> ArtifactWire.reply

    override _.LinkArtifact(request, _) =
        library.Link(
            ArtifactWire.reference request.Expected,
            ModLibraryWire.id request.ModId,
            ModLibraryWire.id request.VersionId,
            request.Remove
        )
        |> ArtifactWire.reply

    override _.DeleteArtifactCopy(request, _) =
        library.DeleteCopy(ArtifactWire.reference request) |> ArtifactWire.reply

    override _.RemoveArtifact(request, _) =
        task {
            let! result = library.Remove(ArtifactWire.reference request)
            ArtifactWire.result result
            return ArtifactRemoved()
        }
