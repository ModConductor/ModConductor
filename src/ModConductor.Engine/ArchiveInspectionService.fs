namespace ModConductor.Engine

open Grpc.Core
open System.IO
open ModConductor.ArchiveInspection
open ModConductor.ArtifactLibrary
open ModConductor.Platform
open ModConductor.FilePlanning
open ModConductor.Protocol.V1

module internal ArchiveInspectionWire =
    let manifest (manifest: ArchiveManifest) =
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

        reply

type ArchiveInspectionService(inspection: Inspection) =
    inherit ArchiveInspection.ArchiveInspectionBase()

    override _.PreviewArchiveEntry(request, context) =
        task {
            try
                if isNull request.Artifact || isNull request.Entry then
                    ModLibraryWire.reject "Select an archive entry."

                let value = request.Entry

                if
                    request.Sha256.Length <> 64
                    || request.Sha256 |> Seq.exists (fun c -> not (System.Uri.IsHexDigit c))
                    || request.Format.Length = 0
                    || request.Format.Length > 32
                then
                    ModLibraryWire.reject "The archive identity is invalid."

                if value.Directory then
                    ModLibraryWire.reject "Select a file from this archive."

                let entry =
                    { Index = ModLibraryWire.count value.Index
                      Path =
                        LogicalPath.create (List.ofSeq value.Components)
                        |> Result.defaultWith (fun _ ->
                            ModLibraryWire.reject "The archive entry path is invalid.")
                      Directory = value.Directory
                      Size =
                        if value.Size > uint64 System.Int64.MaxValue then
                            ModLibraryWire.reject "The archive entry size is invalid."

                        int64 value.Size
                      CompressedSize =
                        if value.HasCompressedSize then
                            if value.CompressedSize > uint64 System.Int64.MaxValue then
                                ModLibraryWire.reject "The archive entry size is invalid."

                            Some(int64 value.CompressedSize)
                        else
                            None }

                let reference = ArtifactWire.reference request.Artifact
                let representation = FilePlanWire.readRepresentation request.Representation

                let! preview =
                    inspection.WithContents(
                        reference,
                        context.CancellationToken,
                        fun contents ->
                            let manifest = contents.Manifest

                            let source =
                                FilePreviewSource.QualifiedArchiveEntry
                                    { WorkspaceId = reference.WorkspaceId
                                      ArtifactId = reference.Id
                                      ArtifactRevision = reference.Revision
                                      ArchiveSha256 = request.Sha256
                                      Format = request.Format
                                      Index = entry.Index
                                      Path = entry.Path
                                      Length = entry.Size }

                            let changed detail =
                                { Source = source
                                  Standing = ModConductor.FilePlanning.FileSourceStanding.Selected
                                  Target = entry.Path
                                  Outcome = FilePreviewOutcome.Changed detail }

                            if
                                manifest.Sha256 <> request.Sha256
                                || manifest.Format <> request.Format
                            then
                                changed "The archive changed. Read its contents again."
                            else
                                match
                                    manifest.Entries
                                    |> List.tryFind (fun current -> current.Index = entry.Index)
                                with
                                | None ->
                                    changed "The archive entry changed. Read its contents again."
                                | Some current when current <> entry || current.Directory ->
                                    changed "The archive entry changed. Read its contents again."
                                | Some current ->
                                    if FilePreviewRendering.exceedsLimit source representation then
                                        FilePreviewRendering.render
                                            source
                                            ModConductor.FilePlanning.FileSourceStanding.Selected
                                            representation
                                            Stream.Null
                                            context.CancellationToken
                                    else
                                        let mutable value =
                                            Unchecked.defaultof<
                                                ModConductor.FilePlanning.FilePreview
                                             >

                                        contents.ReadEntry(
                                            current.Index,
                                            fun stream ->
                                                value <-
                                                    ModConductor.FilePlanning.FilePreviewRendering.render
                                                        source
                                                        ModConductor.FilePlanning.FileSourceStanding.Selected
                                                        representation
                                                        stream
                                                        context.CancellationToken
                                        )

                                        value
                    )

                return
                    preview
                    |> Result.mapError (function
                        | ArtifactError.Cancelled -> FilePlanError.Cancelled
                        | ArtifactError.Busy -> FilePlanError.Busy
                        | ArtifactError.Unavailable -> FilePlanError.Stale
                        | _ -> FilePlanError.Stale)
                    |> FilePlanWire.preview
            with error ->
                match ArchiveFailure.message error with
                | Some message ->
                    return raise (RpcException(Status(StatusCode.FailedPrecondition, message)))
                | None -> return raise error
        }


    override _.InspectArchive(request, context) =
        task {
            try
                let! result =
                    inspection.Inspect(ArtifactWire.reference request, context.CancellationToken)

                let manifest = ArtifactWire.result result

                return ArchiveInspectionWire.manifest manifest
            with error ->
                match ArchiveFailure.message error with
                | Some message ->
                    return raise (RpcException(Status(StatusCode.FailedPrecondition, message)))
                | None -> return raise error
        }
