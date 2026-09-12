enum ModKind { regular, separator, backup, unmanaged, generatedOutput }

enum InventoryStatus { ready, detached, changed, unproved, publishing }

enum ModAction { editMetadata, publish, readVersion }

enum PublicationPhase { intent, observed, complete, interrupted, cancelled }

enum LibraryFault {
  notFound,
  staleRevision,
  identityConflict,
  invalidMetadata,
  invalidSource,
  unprovedOwnership,
  sourceChanged,
  unsupportedAction,
  busy,
  limitExceeded,
  fileUnavailable,
  cancelled,
}

class LibraryException implements Exception {
  const LibraryException(this.fault, this.detail);
  final LibraryFault fault;
  final String detail;
}

class CategoryReference {
  const CategoryReference(this.id, this.label, {this.missing = false});
  final String id, label;
  final bool missing;
}

class ModMetadata {
  const ModMetadata({
    required this.name,
    this.notes = '',
    this.comment = '',
    this.version = '',
    this.source = '',
    this.categories = const [],
  });
  final String name, notes, comment, version, source;
  final List<CategoryReference> categories;
}

class ModVersionOrigin {
  const ModVersionOrigin({this.outputActionId, this.archiveArtifactId});
  final String? outputActionId, archiveArtifactId;
}

class ModEntry {
  const ModEntry({
    required this.id,
    required this.workspaceId,
    required this.kind,
    required this.metadata,
    required this.revision,
    required this.status,
    required this.actions,
    this.sourcePath,
    this.currentVersionId,
    this.versionOrigin,
  });
  final String id, workspaceId;
  final ModKind kind;
  final ModMetadata metadata;
  final int revision;
  final InventoryStatus status;
  final List<ModAction> actions;
  // Original components, not a host path. Backslashes on Linux are ordinary characters.
  final List<String>? sourcePath;
  final String? currentVersionId;
  final ModVersionOrigin? versionOrigin;
}

sealed class ModRegistration {
  const ModRegistration();
}

class DirectoryMod extends ModRegistration {
  const DirectoryMod(this.kind, this.path);
  final ModKind kind;
  final List<String> path;
}

class NativeDirectoryMod extends ModRegistration {
  const NativeDirectoryMod(this.kind, this.path);
  final ModKind kind;
  final String path;
}

class SeparatorMod extends ModRegistration {
  const SeparatorMod();
}

class BackupMod extends ModRegistration {
  const BackupMod(this.versionId);
  final String versionId;
}

class UnmanagedModPath {
  const UnmanagedModPath(this.path, this.directory, this.unsupported);
  final List<String> path;
  final bool directory, unsupported;
}

class InventoryScan {
  const InventoryScan(this.entries, this.unmanaged, this.limited);
  final List<ModEntry> entries;
  final List<UnmanagedModPath> unmanaged;
  final bool limited;
}

class ModPayload {
  const ModPayload(this.id, this.length, this.sha256);
  final String id, sha256;
  final int length;
}

class ManifestEntry {
  const ManifestEntry(this.path, this.payload);
  final List<String> path;
  final ModPayload payload;
}

class ModVersionPage {
  const ModVersionPage(
    this.id,
    this.modId,
    this.entries,
    this.nextOffset, {
    this.origin = const ModVersionOrigin(),
  });
  final String id, modId;
  final List<ManifestEntry> entries;
  final ModVersionOrigin origin;
  final int? nextOffset;
}

class PublicationReceipt {
  const PublicationReceipt(
    this.versionId,
    this.modId,
    this.expectedRevision,
    this.phase,
  );
  final String versionId, modId;
  final int expectedRevision;
  final PublicationPhase phase;
}
