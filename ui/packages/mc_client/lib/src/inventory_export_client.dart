import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import 'generated/modconductor/v1/inventory_export.pbgrpc.dart' as wire;
import 'inventory_export_models.dart';
import 'mod_organization_wire.dart' as organization;
export 'inventory_export_models.dart';

abstract interface class InventoryExportClient {
  Future<PreparedInventoryExport> prepare(InventoryExportCapture capture);
  Future<InventoryExportDestination> inspect(
    String exportId,
    String destinationPath,
  );
  Stream<InventoryExportEvent> write(
    String exportId,
    String destinationId, {
    required bool replaceExisting,
  });
  Future<bool> discard(String exportId);
}

class GrpcInventoryExportClient implements InventoryExportClient {
  GrpcInventoryExportClient(ClientChannel channel, CallOptions options)
    : _options = CallOptions(metadata: options.metadata),
      _client = wire.InventoryExportOperationsClient(
        channel,
        options: CallOptions(metadata: options.metadata),
      );

  final wire.InventoryExportOperationsClient _client;
  final CallOptions _options;

  @override
  Future<PreparedInventoryExport> prepare(
    InventoryExportCapture capture,
  ) async {
    final reply = await _client.prepareInventoryExport(
      wire.PrepareInventoryExportRequest(
        workspaceId: capture.workspaceId,
        workspaceRevision: Int64(capture.workspaceRevision),
        profileId: capture.profileId,
        scope: _scope(capture.scope),
        selectedModIds: capture.selectedModIds,
        query: organization.query(capture.query),
        queryIdentity: capture.queryIdentity,
        catalogueRevision: Int64(capture.catalogueRevision),
        selectionRevision: Int64(capture.selectionRevision),
        fields: capture.fields.map(_field),
      ),
      options: _options.mergedWith(
        CallOptions(timeout: const Duration(seconds: 30)),
      ),
    );
    return switch (reply.whichOutcome()) {
      wire.PrepareInventoryExportReply_Outcome.prepared =>
        PreparedInventoryExport(
          reply.prepared.exportId,
          reply.prepared.rowCount,
          List.unmodifiable(reply.prepared.fields.map(_decodeField)),
        ),
      wire.PrepareInventoryExportReply_Outcome.fault => _reject(reply.fault),
      wire.PrepareInventoryExportReply_Outcome.notSet =>
        throw const FormatException('Missing export preparation.'),
    };
  }

  @override
  Future<InventoryExportDestination> inspect(
    String exportId,
    String destinationPath,
  ) async {
    final reply = await _client.inspectInventoryExportDestination(
      wire.InspectInventoryExportDestinationRequest(
        exportId: exportId,
        destinationPath: destinationPath,
      ),
      options: _options,
    );
    return switch (reply.whichOutcome()) {
      wire.InspectInventoryExportDestinationReply_Outcome.destination =>
        InventoryExportDestination(
          reply.destination.destinationId,
          reply.destination.fileName,
          reply.destination.exists,
        ),
      wire.InspectInventoryExportDestinationReply_Outcome.fault => _reject(
        reply.fault,
      ),
      wire.InspectInventoryExportDestinationReply_Outcome.notSet =>
        throw const FormatException('Missing export destination.'),
    };
  }

  @override
  Stream<InventoryExportEvent> write(
    String exportId,
    String destinationId, {
    required bool replaceExisting,
  }) => _client
      .writeInventoryExport(
        wire.WriteInventoryExportRequest(
          exportId: exportId,
          destinationId: destinationId,
          replaceExisting: replaceExisting,
        ),
        options: _options,
      )
      .map(
        (event) => switch (event.whichOutcome()) {
          wire.InventoryExportEvent_Outcome.progress => InventoryExportProgress(
            event.progress.writtenRows,
            event.progress.totalRows,
          ),
          wire.InventoryExportEvent_Outcome.completed =>
            InventoryExportCompleted(
              event.completed.fileName,
              event.completed.rowCount,
              event.completed.byteCount.toInt(),
            ),
          wire.InventoryExportEvent_Outcome.fault => _reject(event.fault),
          wire.InventoryExportEvent_Outcome.notSet =>
            throw const FormatException('Missing export event.'),
        },
      );

  @override
  Future<bool> discard(String exportId) async =>
      (await _client.discardInventoryExport(
        wire.DiscardInventoryExportRequest(exportId: exportId),
        options: _options,
      )).discarded;
}

wire.InventoryExportScope _scope(InventoryExportScope value) => switch (value) {
  InventoryExportScope.selected =>
    wire.InventoryExportScope.INVENTORY_EXPORT_SCOPE_SELECTED,
  InventoryExportScope.enabled =>
    wire.InventoryExportScope.INVENTORY_EXPORT_SCOPE_ENABLED,
  InventoryExportScope.currentQuery =>
    wire.InventoryExportScope.INVENTORY_EXPORT_SCOPE_CURRENT_QUERY,
  InventoryExportScope.all =>
    wire.InventoryExportScope.INVENTORY_EXPORT_SCOPE_ALL,
};

wire.InventoryExportField _field(InventoryExportField value) => switch (value) {
  InventoryExportField.modId =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_MOD_ID,
  InventoryExportField.name =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_NAME,
  InventoryExportField.kind =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_KIND,
  InventoryExportField.status =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_STATUS,
  InventoryExportField.priority =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_PRIORITY,
  InventoryExportField.enabled =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_ENABLED,
  InventoryExportField.version =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_VERSION,
  InventoryExportField.source =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_SOURCE,
  InventoryExportField.sourcePath =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_SOURCE_PATH,
  InventoryExportField.notes =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_NOTES,
  InventoryExportField.comment =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_COMMENT,
  InventoryExportField.categories =>
    wire.InventoryExportField.INVENTORY_EXPORT_FIELD_CATEGORIES,
};

InventoryExportField _decodeField(wire.InventoryExportField value) =>
    switch (value) {
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_MOD_ID =>
        InventoryExportField.modId,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_NAME =>
        InventoryExportField.name,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_KIND =>
        InventoryExportField.kind,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_STATUS =>
        InventoryExportField.status,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_PRIORITY =>
        InventoryExportField.priority,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_ENABLED =>
        InventoryExportField.enabled,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_VERSION =>
        InventoryExportField.version,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_SOURCE =>
        InventoryExportField.source,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_SOURCE_PATH =>
        InventoryExportField.sourcePath,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_NOTES =>
        InventoryExportField.notes,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_COMMENT =>
        InventoryExportField.comment,
      wire.InventoryExportField.INVENTORY_EXPORT_FIELD_CATEGORIES =>
        InventoryExportField.categories,
      _ => throw const FormatException('Unsupported export field.'),
    };

Never _reject(
  wire.InventoryExportFault fault,
) => throw InventoryExportException(switch (fault.code) {
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_INVALID_REQUEST =>
    InventoryExportFault.invalidRequest,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_NOT_FOUND =>
    InventoryExportFault.notFound,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_STALE =>
    InventoryExportFault.stale,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_BUSY =>
    InventoryExportFault.busy,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_LIMIT_EXCEEDED =>
    InventoryExportFault.limitExceeded,
  wire
      .InventoryExportFaultCode
      .INVENTORY_EXPORT_FAULT_CODE_DESTINATION_UNAVAILABLE =>
    InventoryExportFault.destinationUnavailable,
  wire
      .InventoryExportFaultCode
      .INVENTORY_EXPORT_FAULT_CODE_DESTINATION_CHANGED =>
    InventoryExportFault.destinationChanged,
  wire
      .InventoryExportFaultCode
      .INVENTORY_EXPORT_FAULT_CODE_REPLACEMENT_REQUIRED =>
    InventoryExportFault.replacementRequired,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_CANCELLED =>
    InventoryExportFault.cancelled,
  wire.InventoryExportFaultCode.INVENTORY_EXPORT_FAULT_CODE_WRITE_FAILED =>
    InventoryExportFault.writeFailed,
  _ => throw const FormatException('Unsupported export fault.'),
}, fault.detail);
