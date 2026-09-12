namespace ModConductor.Engine

open Grpc.Core
open ModConductor.ArchiveInspection
open ModConductor.Platform
open ModConductor.Protocol.V1

type ArchiveInspectionService(inspection: Inspection) =
    inherit ArchiveInspection.ArchiveInspectionBase()

    override _.InspectArchive(request, context) =
        task {
            try
                let! result =
                    inspection.Inspect(ArtifactWire.reference request, context.CancellationToken)

                let manifest = ArtifactWire.result result

                let reply =
                    InspectedArchive(
                        Sha256 = manifest.Sha256,
                        Format = manifest.Format,
                        TotalSize = uint64 manifest.TotalSize
                    )

                for entry in manifest.Entries do
                    let value =
                        InspectedArchiveEntry(
                            Index = uint32 entry.Index,
                            Directory = entry.Directory,
                            Size = uint64 entry.Size
                        )

                    value.Components.AddRange(LogicalPath.components entry.Path)

                    entry.CompressedSize
                    |> Option.iter (fun size -> value.CompressedSize <- uint64 size)

                    reply.Entries.Add value

                return reply
            with error ->
                match ArchiveFailure.message error with
                | Some message ->
                    return raise (RpcException(Status(StatusCode.FailedPrecondition, message)))
                | None -> return raise error
        }
