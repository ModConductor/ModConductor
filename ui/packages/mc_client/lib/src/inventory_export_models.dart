import 'mod_organization_models.dart';

enum InventoryExportScope { selected, enabled, currentQuery, all }

enum InventoryExportField {
  modId,
  name,
  kind,
  status,
  priority,
  enabled,
  version,
  source,
  sourcePath,
  notes,
  comment,
  categories,
}

class InventoryExportCapture {
  const InventoryExportCapture({
    required this.workspaceId,
    required this.workspaceRevision,
    required this.profileId,
    required this.scope,
    required this.selectedModIds,
    required this.query,
    required this.queryIdentity,
    required this.catalogueRevision,
    required this.selectionRevision,
    required this.fields,
  });

  final String workspaceId, profileId, queryIdentity;
  final int workspaceRevision, catalogueRevision, selectionRevision;
  final InventoryExportScope scope;
  final List<String> selectedModIds;
  final ModQuery query;
  final List<InventoryExportField> fields;
}

class PreparedInventoryExport {
  const PreparedInventoryExport(this.id, this.rowCount, this.fields);
  final String id;
  final int rowCount;
  final List<InventoryExportField> fields;
}

class InventoryExportDestination {
  const InventoryExportDestination(this.id, this.fileName, this.exists);
  final String id, fileName;
  final bool exists;
}

sealed class InventoryExportEvent {
  const InventoryExportEvent();
}

class InventoryExportProgress extends InventoryExportEvent {
  const InventoryExportProgress(this.writtenRows, this.totalRows);
  final int writtenRows, totalRows;
}

class InventoryExportCompleted extends InventoryExportEvent {
  const InventoryExportCompleted(this.fileName, this.rowCount, this.byteCount);
  final String fileName;
  final int rowCount, byteCount;
}

enum InventoryExportFault {
  invalidRequest,
  notFound,
  stale,
  busy,
  limitExceeded,
  destinationUnavailable,
  destinationChanged,
  replacementRequired,
  cancelled,
  writeFailed,
}

class InventoryExportException implements Exception {
  const InventoryExportException(this.fault, this.detail);
  final InventoryExportFault fault;
  final String detail;

  @override
  String toString() => detail;
}
