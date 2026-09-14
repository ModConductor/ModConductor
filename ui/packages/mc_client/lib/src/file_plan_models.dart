import 'dart:typed_data';

class ManagedFileCopy {
  ManagedFileCopy(this.modId, this.versionId, List<String> path)
    : path = List.unmodifiable(path);
  final String modId, versionId;
  final List<String> path;
  @override
  bool operator ==(Object other) =>
      other is ManagedFileCopy &&
      modId == other.modId &&
      versionId == other.versionId &&
      path.length == other.path.length &&
      Iterable<int>.generate(path.length)
          .every((index) => path[index] == other.path[index]);
  @override
  int get hashCode => Object.hash(modId, versionId, Object.hashAll(path));
}

enum FileSourceStanding { winner, alternative, selected, previous, unavailable }

enum FilePreviewRepresentation { text, image, hex }

enum FilePreviewStatus { ready, unsupported, tooLarge, changed }

enum TextDocumentEncoding { utf8, utf8Bom, utf16Little, utf16Big }

enum TextDocumentNewline { noLineBreaks, lf, crlf }

class TextDocument {
  const TextDocument({
    required this.content,
    required this.encoding,
    required this.newline,
    required this.finalTerminator,
    required this.lines,
  });
  final String content;
  final TextDocumentEncoding encoding;
  final TextDocumentNewline newline;
  final bool finalTerminator;
  final int lines;
}

class ManagedTextDocument {
  const ManagedTextDocument(this.source, this.document);
  final ManagedPreviewSource source;
  final TextDocument document;
}

class ManagedTextEdit {
  const ManagedTextEdit(this.id, this.versionId, this.source);
  final String id, versionId;
  final ManagedPreviewSource source;
}

sealed class FilePreviewSource {
  const FilePreviewSource({
    required this.target,
    required this.sourcePath,
    required this.length,
  });
  final List<String> target, sourcePath;
  final int length;
  Object get id;
  String get kindLabel;
}

class ManagedPreviewSource extends FilePreviewSource {
  ManagedPreviewSource({
    required this.copy,
    required super.sourcePath,
    required super.target,
    required super.length,
    required this.sha256,
    required this.payloadId,
    required this.modRevision,
  });
  final ManagedFileCopy copy;
  final String sha256, payloadId;
  final int modRevision;
  @override
  Object get id => copy;
  @override
  String get kindLabel => 'Managed copy';
}

class CheckedGamePreviewSource extends FilePreviewSource {
  CheckedGamePreviewSource({
    required this.snapshotId,
    required this.generation,
    required this.kind,
    required super.sourcePath,
    required super.target,
    required super.length,
    required this.sha256,
  });
  final String snapshotId, generation, sha256;
  final int kind;
  @override
  Object get id => 'game:$snapshotId:$generation:${sourcePath.join('/')}';
  @override
  String get kindLabel => 'Game file';
}

class QualifiedArchiveEntryPreviewSource extends FilePreviewSource {
  QualifiedArchiveEntryPreviewSource({
    required this.workspaceId,
    required this.artifactId,
    required this.artifactRevision,
    required this.archiveSha256,
    required this.format,
    required this.index,
    required super.sourcePath,
    required super.length,
  }) : super(target: sourcePath);
  final String workspaceId, artifactId, archiveSha256, format;
  final int artifactRevision, index;
  @override
  Object get id =>
      'archive:$workspaceId:$artifactId:$artifactRevision:$archiveSha256:$index';
  @override
  String get kindLabel => '$format archive entry';
}

sealed class FilePreviewContent {
  const FilePreviewContent();
}

class FilePreviewText extends FilePreviewContent {
  const FilePreviewText(this.content, this.encoding, this.lines);
  final String content, encoding;
  final int lines;
}

class FilePreviewImage extends FilePreviewContent {
  const FilePreviewImage(this.content, this.format, this.width, this.height);
  final Uint8List content;
  final String format;
  final int width, height;
}

class FilePreviewHex extends FilePreviewContent {
  const FilePreviewHex(this.content, this.totalLength, this.truncated);
  final Uint8List content;
  final int totalLength;
  final bool truncated;
}

class FilePreviewResult {
  const FilePreviewResult({
    required this.source,
    required this.standing,
    required this.target,
    required this.status,
    this.detail,
    this.content,
  });
  final FilePreviewSource source;
  final FileSourceStanding standing;
  final List<String> target;
  final FilePreviewStatus status;
  final String? detail;
  final FilePreviewContent? content;
}

class FilePreviewRead {
  const FilePreviewRead(this.result, this.cancel);
  final Future<FilePreviewResult> result;
  final Future<void> Function() cancel;
}

class FilePlanCursor {
  const FilePlanCursor(this.identity, this.offset);
  final String identity;
  final int offset;
}

class FilePlanState {
  const FilePlanState({
    required this.id,
    required this.workspaceId,
    required this.profileId,
    required this.fingerprint,
    required this.loaded,
    required this.stale,
    required this.plannedFiles,
    required this.absentTargets,
    required this.inspectedFiles,
    required this.problems,
    required this.problemCount,
    this.observedAt,
  });
  final String id, workspaceId, profileId, fingerprint;
  final bool loaded, stale;
  final int plannedFiles, absentTargets, inspectedFiles, problemCount;
  final List<String> problems;
  final DateTime? observedAt;
}

enum PlannedFileDisposition { planned, absent, unresolved, writable }

class PlannedFileNode {
  const PlannedFileNode({
    required this.path,
    required this.directory,
    required this.disposition,
    required this.sourceName,
    required this.copies,
  });
  final List<String> path;
  final bool directory;
  final PlannedFileDisposition disposition;
  final String sourceName;
  final int copies;
}

class FilePlanPage {
  const FilePlanPage(this.state, this.nodes, this.next);
  final FilePlanState state;
  final List<PlannedFileNode> nodes;
  final FilePlanCursor? next;
}

class InspectedFileCopy {
  const InspectedFileCopy({
    this.copy,
    required this.sourcePath,
    required this.name,
    required this.versionLabel,
    this.priority,
    required this.enabled,
    required this.hidden,
    required this.winner,
    required this.historical,
    required this.length,
    required this.sha256,
    required this.canHide,
    required this.canUnhide,
    required this.source,
    required this.standing,
  });
  final ManagedFileCopy? copy;
  final FilePreviewSource source;
  final FileSourceStanding standing;
  final List<String> sourcePath;
  final String name, versionLabel, sha256;
  final int? priority;
  final int length;
  final bool enabled, hidden, winner, historical, canHide, canUnhide;
}

class FilePlanInspection {
  const FilePlanInspection(
    this.state,
    this.target,
    this.copies,
    this.next, {
    this.focusedCopy,
    this.writable = false,
  });
  final FilePlanState state;
  final List<String> target;
  final List<InspectedFileCopy> copies;
  final InspectedFileCopy? focusedCopy;
  final bool writable;
  final FilePlanCursor? next;
}

class FileVisibilityChange {
  const FileVisibilityChange(this.state, this.changed);
  final FilePlanState state;
  final PlannedFileNode? changed;
}

class FileVisibilityAudit {
  const FileVisibilityAudit({
    required this.id,
    required this.copy,
    required this.hidden,
    required this.beforeHidden,
    required this.profileId,
    required this.beforeFingerprint,
    required this.afterFingerprint,
    required this.recordedAt,
  });
  final int id;
  final ManagedFileCopy copy;
  final bool hidden, beforeHidden;
  final String profileId, beforeFingerprint, afterFingerprint;
  final DateTime recordedAt;
}

class FileVisibilityHistory {
  const FileVisibilityHistory(this.changes, this.nextBeforeId);
  final List<FileVisibilityAudit> changes;
  final int? nextBeforeId;
}

class FilePlanProblems {
  const FilePlanProblems(this.problems, this.next);
  final List<String> problems;
  final FilePlanCursor? next;
}

sealed class FilePlanLoadEvent {
  const FilePlanLoadEvent();
}

class FilePlanProgress extends FilePlanLoadEvent {
  const FilePlanProgress(
    this.files,
    this.totalFiles,
    this.bytes,
    this.totalBytes,
  );
  final int files, totalFiles, bytes, totalBytes;
}

class FilePlanLoaded extends FilePlanLoadEvent {
  const FilePlanLoaded(this.state);
  final FilePlanState state;
}

enum FilePlanFailure {
  notFound,
  busy,
  expired,
  stale,
  contextUnavailable,
  fileUnavailable,
  limitExceeded,
  cancelled,
  invalidCopy,
  blocked,
  unsupported,
  invalidEdit,
}

class FilePlanException implements Exception {
  const FilePlanException(this.failure, this.detail);
  final FilePlanFailure failure;
  final String detail;
}
