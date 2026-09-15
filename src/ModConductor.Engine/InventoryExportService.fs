namespace ModConductor.Engine

open System
open System.Threading.Tasks
open Grpc.Core
open ModConductor.ModOrganization
open ModConductor.Platform
open ModConductor.Protocol.V1

type InventoryExportService(exports: InventoryExportSession) =
    inherit InventoryExportOperations.InventoryExportOperationsBase()

    let id value = ModLibraryWire.id value

    override _.PrepareInventoryExport(request, _) =
        task {
            let capture =
                { WorkspaceId = id request.WorkspaceId
                  WorkspaceRevision = ModLibraryWire.number request.WorkspaceRevision
                  ProfileId = id request.ProfileId
                  Scope = InventoryExportWire.scope request.Scope
                  SelectedModIds = request.SelectedModIds |> Seq.map id |> Seq.toList
                  Query = OrganizationWire.query request.Query
                  QueryIdentity = request.QueryIdentity
                  CatalogueRevision = ModLibraryWire.number request.CatalogueRevision
                  SelectionRevision = ModLibraryWire.number request.SelectionRevision
                  Fields = request.Fields |> Seq.map InventoryExportWire.field |> Seq.toList }

            match! exports.Prepare capture with
            | Error error ->
                return PrepareInventoryExportReply(Fault = InventoryExportWire.fault error)
            | Ok value ->
                let prepared =
                    PreparedInventoryExport(
                        ExportId = value.Id.ToString("N"),
                        RowCount = uint32 value.RowCount
                    )

                prepared.Fields.AddRange(value.Fields |> Seq.map InventoryExportWire.encodeField)
                return PrepareInventoryExportReply(Prepared = prepared)
        }

    override _.InspectInventoryExportDestination(request, _) =
        task {
            match HostPath.create request.DestinationPath with
            | Error _ ->
                return
                    InspectInventoryExportDestinationReply(
                        Fault =
                            InventoryExportWire.fault InventoryExportError.DestinationUnavailable
                    )
            | Ok path ->
                match! exports.Inspect(id request.ExportId, path) with
                | Error error ->
                    return
                        InspectInventoryExportDestinationReply(
                            Fault = InventoryExportWire.fault error
                        )
                | Ok value ->
                    return
                        InspectInventoryExportDestinationReply(
                            Destination =
                                ModConductor.Protocol.V1.InventoryExportDestination(
                                    DestinationId = value.Id.ToString("N"),
                                    FileName = value.FileName,
                                    Exists = value.Exists
                                )
                        )
        }

    override _.WriteInventoryExport(request, output, context) =
        task {
            let progress value =
                output.WriteAsync(
                    InventoryExportEvent(
                        Progress =
                            InventoryExportWriteProgress(
                                WrittenRows = uint32 value.Written,
                                TotalRows = uint32 value.Total
                            )
                    ),
                    context.CancellationToken
                )

            let! result =
                exports.Write(
                    id request.ExportId,
                    id request.DestinationId,
                    request.ReplaceExisting,
                    progress,
                    context.CancellationToken
                )

            match result with
            | Error error ->
                do!
                    output.WriteAsync(
                        InventoryExportEvent(Fault = InventoryExportWire.fault error),
                        context.CancellationToken
                    )
            | Ok value ->
                do!
                    output.WriteAsync(
                        InventoryExportEvent(
                            Completed =
                                CompletedInventoryExport(
                                    FileName = value.FileName,
                                    RowCount = uint32 value.RowCount,
                                    ByteCount = uint64 value.Length
                                )
                        ),
                        context.CancellationToken
                    )
        }
        :> Task

    override _.CancelInventoryExport(request, _) =
        Task.FromResult(CancelInventoryExportReply(Requested = exports.Cancel(id request.ExportId)))

    override _.DiscardInventoryExport(request, _) =
        Task.FromResult(
            DiscardInventoryExportReply(Discarded = exports.Discard(id request.ExportId))
        )
