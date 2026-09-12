namespace ModConductor.Engine

open System.Threading.Tasks
open Grpc.Core
open ModConductor.ArchiveInstallation
open ModConductor.ArchiveInspection
open ModConductor.Platform
open ModConductor.Protocol.V1

module internal InstallationWire =
    let guard (action: unit -> Task<'a>) =
        task {
            try
                return! action ()
            with error ->
                let message =
                    match error with
                    | :? InstallationException -> Some error.Message
                    | _ -> ArchiveFailure.message error

                match message with
                | Some message ->
                    return raise (RpcException(Status(StatusCode.FailedPrecondition, message)))
                | None -> return raise error
        }

    let reference (reference: InstallationDraftReference) =
        if isNull reference then
            ModLibraryWire.reject "Open an installation preview."

        ModLibraryWire.id reference.WorkspaceId,
        ModLibraryWire.id reference.Id,
        ModLibraryWire.number reference.Revision

    let draft (value: InstallationDraft) =
        let result =
            ArchiveInstallationDraft(
                Reference =
                    InstallationDraftReference(
                        WorkspaceId = value.Artifact.WorkspaceId.ToString("N"),
                        Id = value.Id.ToString("N"),
                        Revision = uint64 value.Revision
                    ),
                Artifact =
                    ArtifactReference(
                        WorkspaceId = value.Artifact.WorkspaceId.ToString("N"),
                        Id = value.Artifact.Id.ToString("N"),
                        Revision = uint64 value.Artifact.Revision
                    ),
                ArchiveName = value.ArchiveName,
                Manifest = ArchiveInspectionWire.manifest value.Manifest,
                Name = value.Name,
                Version = value.Version,
                Bytes = uint64 (value.Plan |> Option.map _.Bytes |> Option.defaultValue 0L),
                CanInstall = value.Plan.IsSome
            )

        result.Root.AddRange value.Root

        for file in value.Files do
            let entry = ModConductor.Protocol.V1.InstallationFile(Index = uint32 file.Index)
            entry.Destination.AddRange(LogicalPath.components file.Destination)
            result.Files.Add entry

        result

    let status (value: Installation) =
        let phase =
            match value.State with
            | InstallationState.Running -> InstallationPhase.Running
            | InstallationState.Stopped -> InstallationPhase.Stopped
            | InstallationState.Complete -> InstallationPhase.Complete
            | InstallationState.Discarded -> InstallationPhase.Discarded

        let result =
            ArchiveInstallationStatus(
                Id = value.Id.ToString("N"),
                WorkspaceId = value.WorkspaceId.ToString("N"),
                ArtifactId = value.ArtifactId.ToString("N"),
                ArchiveName = value.ArchiveName,
                IsUpdate = value.IsUpdate,
                Name = value.Name,
                Version = value.Version,
                Phase = phase,
                Files = uint32 value.Files,
                TotalFiles = uint32 value.TotalFiles,
                Bytes = uint64 value.Bytes,
                TotalBytes = uint64 value.TotalBytes
            )

        value.TemporaryBytes
        |> Option.iter (fun bytes -> result.TemporaryBytes <- uint64 bytes)

        value.Problem |> Option.iter (fun text -> result.Problem <- text)
        value.ModId |> Option.iter (fun id -> result.ModId <- id.ToString("N"))
        value.VersionId |> Option.iter (fun id -> result.VersionId <- id.ToString("N"))
        result
